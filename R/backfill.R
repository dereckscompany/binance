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
#' @param symbols Character vector of trading pair symbols (e.g.,
#'   `c("BTCUSDT", "ETHUSDT")`). Must not be NULL or empty.
#' @param timeframes Character vector of candle timeframes (e.g., `c("1d", "1h")`).
#'   Valid values: `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`, `"1h"`,
#'   `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.
#' @param from POSIXct or numeric; start of the backfill window. Defaults to one
#'   year ago. Values before `"2017-07-01"` (or `-Inf`) are clamped to
#'   `"2017-07-01"` since Binance data does not exist before that date.
#' @param to POSIXct or numeric; end of the backfill window. Defaults to
#'   current time. `Inf` is replaced with current time.
#' @param file Character; path to the output CSV file. Data is appended
#'   incrementally so progress is saved even if the process is interrupted.
#' @param base_url Character; Binance API base URL.
#' @param sleep Numeric; seconds to sleep between each symbol-timeframe
#'   combination to respect rate limits.
#' @param verbose Logical; if `TRUE`, prints progress messages via [rlang::inform()].
#'
#' @return The file path (invisibly).
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
  verbose = TRUE
) {
  # --- Input validation ---
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
      data.table::fread(file, select = c("symbol", "timeframe", "open_time")),
      error = function(e) NULL
    )
    if (!is.null(existing) && nrow(existing) > 0L) {
      existing[, open_time := lubridate::as_datetime(open_time, tz = "UTC")]
      resume <- existing[, .(last_dt = max(open_time)), by = .(symbol, timeframe)]
    }
  }

  # --- Sync request function closure ---
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
      is_async = FALSE
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

    dt <- tryCatch(
      {
        result <- binance_fetch_klines(
          symbol = sym,
          timeframe = intv,
          from = combo_from,
          to = to,
          .req_fn = sync_req_fn,
          is_async = FALSE
        )
        result
      },
      error = function(e) {
        failures[[length(failures) + 1L]] <<- data.table::data.table(
          symbol = sym,
          timeframe = intv,
          error = conditionMessage(e)
        )
        rlang::warn(sprintf("[%d/%d] %s %s: FAILED - %s", i, total, sym, intv, conditionMessage(e)))
        return(NULL)
      }
    )

    # Drop the candle still forming at the live edge. A kline whose close_time
    # is in the future has not closed yet; persisting it would store a
    # half-built candle that resume then skips over (resume advances past the
    # last stored open_time), so it would never be refreshed to its final
    # values. Keeping only closed candles means the next run re-fetches and
    # completes it. Closed historical candles are unaffected — including ones
    # that straddle an explicit past `to`.
    if (!is.null(dt) && nrow(dt) > 0L) {
      dt <- dt[close_time <= lubridate::now("UTC")]
    }

    if (!is.null(dt) && nrow(dt) > 0L) {
      dt[, symbol := sym]
      dt[, timeframe := intv]

      if (!file_exists) {
        data.table::fwrite(dt, file, append = FALSE)
        file_exists <- TRUE
      } else {
        data.table::fwrite(dt, file, append = TRUE)
      }

      if (verbose) {
        msg <- sprintf("[%d/%d] %s %s: %d rows", i, total, sym, intv, nrow(dt))
        if (!is.null(resumed_from)) {
          msg <- paste0(msg, sprintf(" (resumed from %s)", format(resumed_from, "%Y-%m-%d")))
        }
        rlang::inform(msg)
      }
    } else if (is.null(dt)) {
      # Error already handled above
    } else {
      if (verbose) {
        rlang::inform(sprintf("[%d/%d] %s %s: 0 rows", i, total, sym, intv))
      }
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

  return(invisible(file))
}
