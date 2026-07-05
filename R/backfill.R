# File: R/backfill.R
# Batch backfill of kline (OHLCV) data across multiple symbols and timeframes,
# with CSV-based resume support.

#' Backfill Binance Kline Data to CSV
#'
#' Downloads historical OHLCV candlestick data for one or more trading pairs and
#' timeframes, writing results incrementally to a CSV file. Supports resuming
#' from a partially completed backfill by reading the existing file and skipping
#' symbol-timeframe combinations that are already up to date.
#'
#' Only **closed** candles are persisted: the candle still forming at the live
#' edge (one whose `close_time` is in the future) is dropped before writing, so
#' a half-built candle is never stored. Because resume advances past the last
#' stored candle, an unclosed candle written once would never be refreshed to
#' its final values — dropping it means the next run re-fetches and completes
#' it. Closed historical candles are unaffected.
#'
#' @param symbols (character) trading pair symbols (e.g.,
#'   `c("BTCUSDT", "ETHUSDT")`). Must not be NULL or empty.
#' @param timeframes (character) candle timeframes (e.g., `c("1d", "1h")`).
#'   Valid values: `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`, `"1h"`,
#'   `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.
#' @param from (scalar<POSIXct> | scalar<numeric>) start of the backfill window.
#'   Defaults to one year ago. Values before `"2017-07-01"` (or `-Inf`) are
#'   clamped to `"2017-07-01"` since Binance data does not exist before that date.
#' @param to (scalar<POSIXct> | scalar<numeric>) end of the backfill window.
#'   Defaults to current time. `Inf` is replaced with current time.
#' @param file (scalar<character>) path to the output CSV file. Data is appended
#'   incrementally so progress is saved even if the process is interrupted.
#' @param base_url (scalar<character>) Binance API base URL.
#' @param sleep (scalar<numeric in [0, Inf[>) seconds to sleep between each
#'   symbol-timeframe combination to respect rate limits.
#' @param verbose (scalar<logical>) if `TRUE`, prints progress messages via [rlang::inform()].
#' @param timeout (scalar<numeric in ]0, Inf[>) per-request timeout in seconds.
#'   A deep backfill issues hundreds of sequential page requests, so a single
#'   slow response should not abort the combo; this bounds each attempt before
#'   `max_tries` retries it. Default `30`.
#' @param max_tries (scalar<count in [1, Inf[>) retry each page request up to
#'   this many times with backoff on a transient failure (timeout, dropped
#'   connection, 5xx, 429). Without it, one timeout mid-history truncates the
#'   file. Backfill is an idempotent GET, so retrying is always safe. Default `5`.
#' @noassert symbols
#'
#' @return (scalar<character>) the file path (invisibly).
#'
#'   Per-combo failures are surfaced as warnings during the run (one
#'   `rlang::warn()` per failed `(symbol, timeframe)` pair, with the
#'   underlying error message). After the loop, if any combinations
#'   failed, a final summary warning lists the count and the affected
#'   pairs. No failure data is hidden on the return value.
#'
#' @importFrom httr2 req_perform
#' @importFrom lubridate as_datetime now
#' @importFrom rlang abort inform warn
#' @export
#'
#' @examples
#' \dontrun{
#' binance_backfill_klines(
#'   symbols = c("BTCUSDT", "ETHUSDT"),
#'   timeframes = c("1d", "1h"),
#'   from = lubridate::as_datetime("2020-01-01"),
#'   file = "my_klines.csv"
#' )
#' }
binance_backfill_klines <- function(
  symbols,
  timeframes = "1d",
  from = lubridate::now("UTC") - lubridate::ddays(365),
  to = lubridate::now("UTC"),
  file = "binance_klines.csv",
  base_url = "https://api.binance.com",
  sleep = 0.3,
  verbose = TRUE,
  timeout = 30,
  max_tries = 5L
) {
  # --- Input validation ---
  assert_args_binance_backfill_klines(
    timeframes,
    from,
    to,
    file,
    base_url,
    sleep,
    verbose,
    timeout,
    max_tries
  )
  if (is.null(symbols) || length(symbols) == 0L) {
    rlang::abort("`symbols` must be a non-empty character vector of trading pairs.")
  }

  # Clamp from / to
  binance_epoch <- lubridate::as_datetime("2017-07-01", tz = "UTC")

  if (is.infinite(from) && from < 0) {
    from <- binance_epoch
  } else {
    from <- lubridate::as_datetime(from, tz = "UTC")
    if (from < binance_epoch) {
      from <- binance_epoch
    }
  }

  if (is.infinite(to) && to > 0) {
    to <- lubridate::now("UTC")
  } else {
    to <- lubridate::as_datetime(to, tz = "UTC")
  }

  # --- Resume support: read existing file ---
  resume <- NULL
  if (file.exists(file)) {
    existing <- tryCatch(
      data.table::fread(file, select = c("symbol", "timeframe", "datetime")),
      error = function(e) NULL
    )
    if (!is.null(existing) && nrow(existing) > 0L) {
      existing[, datetime := lubridate::as_datetime(datetime, tz = "UTC")]
      resume <- existing[, .(last_dt = max(datetime)), by = .(symbol, timeframe)]
    }
  }

  # --- Sync request function closure ---
  # Retry each page with backoff so a single transient timeout (common on the
  # 500+ page 1m fetches, especially through a VPN) does not truncate the file.
  sync_req_fn <- function(endpoint, method = "GET", query = list(), auth = FALSE, .parser = identity, ...) {
    return(binance_build_request(
      base_url = base_url,
      endpoint = endpoint,
      method = method,
      query = query,
      body = NULL,
      keys = NULL,
      .perform = httr2::req_perform,
      .parser = .parser,
      is_async = FALSE,
      timeout = timeout,
      max_tries = max_tries
    ))
  }

  # --- Build combo grid ---
  combos <- expand.grid(
    symbol = symbols,
    timeframe = timeframes,
    stringsAsFactors = FALSE
  )
  total <- nrow(combos)

  failures <- list()
  file_exists <- file.exists(file)

  for (i in seq_len(total)) {
    sym <- combos$symbol[i]
    intv <- combos$timeframe[i]

    # Determine effective from for this combo
    combo_from <- from
    resumed_from <- NULL

    if (!is.null(resume)) {
      match_row <- resume[symbol == sym & timeframe == intv]
      if (nrow(match_row) > 0L) {
        last_dt <- match_row$last_dt[1L]
        if (last_dt >= to) {
          if (verbose) {
            rlang::inform(sprintf("[%d/%d] %s %s: skipped (already up to date)", i, total, sym, intv))
          }
          next
        }
        combo_from <- last_dt + 1 # Offset by 1 second to avoid re-fetching the last candle
        resumed_from <- last_dt
      }
    }

    # Write each page as it arrives, so a crash loses at most one page and never
    # re-requests a completed page. Drop the candle still forming at the live edge
    # (close_time in the future): persisting it would store a half-built candle
    # that resume then skips over (resume advances past the last stored
    # datetime), so it would never be refreshed to its final values. Keeping only
    # closed candles means the next run re-fetches and completes it. Closed
    # historical candles are unaffected — including ones that straddle a past `to`.
    combo_rows <- 0L
    write_page <- function(page) {
      page <- page[close_time <= lubridate::now("UTC")]
      if (nrow(page) == 0L) {
        return(invisible(NULL))
      }
      page[, symbol := sym]
      page[, timeframe := intv]
      if (!file_exists) {
        data.table::fwrite(page, file, append = FALSE)
        file_exists <<- TRUE
      } else {
        data.table::fwrite(page, file, append = TRUE)
      }
      combo_rows <<- combo_rows + nrow(page)
      return(invisible(NULL))
    }

    ok <- tryCatch(
      {
        binance_fetch_klines(
          symbol = sym,
          timeframe = intv,
          from = combo_from,
          to = to,
          .req_fn = sync_req_fn,
          is_async = FALSE,
          on_page = write_page
        )
        TRUE
      },
      error = function(e) {
        failures[[length(failures) + 1L]] <<- data.table::data.table(
          symbol = sym,
          timeframe = intv,
          error = conditionMessage(e)
        )
        rlang::warn(sprintf("[%d/%d] %s %s: FAILED - %s", i, total, sym, intv, conditionMessage(e)))
        return(FALSE)
      }
    )

    if (isTRUE(ok) && verbose) {
      msg <- sprintf("[%d/%d] %s %s: %d rows", i, total, sym, intv, combo_rows)
      if (!is.null(resumed_from)) {
        msg <- paste0(msg, sprintf(" (resumed from %s)", format(resumed_from, "%Y-%m-%d")))
      }
      rlang::inform(msg)
    }

    if (i < total) {
      Sys.sleep(sleep)
    }
  }

  # --- Final summary warning if anything failed ---
  if (length(failures) > 0L) {
    failed_dt <- data.table::rbindlist(failures)
    pairs <- paste(
      sprintf("%s/%s", failed_dt$symbol, failed_dt$timeframe),
      collapse = ", "
    )
    rlang::warn(sprintf(
      "binance_backfill_klines: %d of %d (symbol, timeframe) combinations failed: %s",
      nrow(failed_dt),
      total,
      pairs
    ))
  }

  return(invisible(assert_return_binance_backfill_klines(file)))
}
