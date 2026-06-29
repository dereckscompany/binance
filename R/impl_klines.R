# File: R/impl_klines.R
# Shared klines fetching implementation used by both BinanceMarketData,
# BinanceFuturesData, and binance_backfill_klines(). Pages FORWARD through a time
# range by following the data: it requests up to `max_candles` candles starting
# at a cursor, advances the cursor past the last candle returned, and stops as
# soon as a page comes back empty or shorter than `max_candles`. Because Binance
# returns candles with open_time >= startTime, an empty leading stretch (e.g. a
# range before the symbol was listed) is skipped in a single request rather than
# probed slice by slice.

# Frequency Map for Binance Kline Timeframes
#
# Maps human-readable timeframe strings to their duration in seconds.
binance_timeframe_map <- list(
  "1s" = 1L,
  "1m" = 60L,
  "3m" = 180L,
  "5m" = 300L,
  "15m" = 900L,
  "30m" = 1800L,
  "1h" = 3600L,
  "2h" = 7200L,
  "4h" = 14400L,
  "6h" = 21600L,
  "8h" = 28800L,
  "12h" = 43200L,
  "1d" = 86400L,
  "3d" = 259200L,
  "1w" = 604800L,
  "1M" = 2592000L
)

# Fetch Klines from Binance
#
# Core implementation for fetching historical OHLCV candlestick data from
# Binance's REST API. Pages forward from `from` to `to` in requests of up to
# `max_candles` candles each, following the data and stopping when a page is
# empty or short.
#
# If `on_page` is supplied, each parsed page (a data.table) is passed to it as
# the page arrives and nothing is accumulated — streaming, memory-light — and the
# function returns invisibly. Otherwise every page is combined, de-duplicated by
# open_time, sorted ascending, and returned as one data.table (the historical
# behaviour).
#
# Used internally by BinanceMarketData$get_klines(), BinanceFuturesData$get_klines(),
# and binance_backfill_klines(). It does not depend on any R6 class instance.
binance_fetch_klines <- function(
  symbol,
  timeframe = "1h",
  from = lubridate::now("UTC") - lubridate::dhours(24),
  to = lubridate::now("UTC"),
  .req_fn,
  is_async = FALSE,
  endpoint = "/api/v3/klines",
  max_candles = 1000L,
  sleep = 0,
  on_page = NULL
) {
  if (!timeframe %in% names(binance_timeframe_map)) {
    rlang::abort(paste0(
      "Invalid timeframe '",
      timeframe,
      "'. Valid: ",
      paste(names(binance_timeframe_map), collapse = ", ")
    ))
  }

  from_ms <- floor(as.numeric(from) * 1000)
  to_ms <- floor(as.numeric(to) * 1000)
  streaming <- !is.null(on_page)

  # Nothing to fetch for a zero-width or inverted range.
  if (from_ms >= to_ms) {
    return(if (streaming) invisible(NULL) else empty_dt_ohlcv())
  }

  # Combine buffered pages: stack, de-dup by open_time, sort ascending.
  combine_klines <- function(results_list) {
    dts <- Filter(function(x) !is.null(x) && nrow(x) > 0L, results_list)
    if (length(dts) == 0L) {
      return(empty_dt_ohlcv())
    }
    dt <- data.table::rbindlist(dts)
    dt <- unique(dt, by = "open_time")
    data.table::setorder(dt, open_time)
    return(dt[])
  }

  # Fetch one page: candles with open_time in [start_ms, to_ms], up to max_candles.
  fetch_page <- function(start_ms) {
    return(.req_fn(
      endpoint = endpoint,
      method = "GET",
      query = list(
        symbol = symbol,
        interval = timeframe,
        startTime = format(start_ms, scientific = FALSE),
        endTime = format(to_ms, scientific = FALSE),
        limit = max_candles
      ),
      auth = FALSE,
      .parser = parse_klines
    ))
  }

  # The start cursor for the NEXT request given a just-fetched page, or NULL if
  # we are done (empty page, short page, or we've passed `to`).
  next_start <- function(page) {
    if (is.null(page) || nrow(page) == 0L || nrow(page) < max_candles) {
      return(NULL)
    }
    ns <- floor(as.numeric(max(page$open_time)) * 1000) + 1
    if (ns > to_ms) {
      return(NULL)
    }
    return(ns)
  }

  # --- Async: recursive promise chain, one page at a time ---
  if (is_async) {
    step <- function(start_ms, acc) {
      return(fetch_page(start_ms)$then(function(page) {
        has_rows <- !is.null(page) && nrow(page) > 0L
        if (has_rows && streaming) {
          on_page(page)
        } else if (has_rows) {
          acc <- c(acc, list(page))
        }
        ns <- next_start(page)
        if (is.null(ns)) {
          return(if (streaming) invisible(NULL) else combine_klines(acc))
        }
        return(step(ns, acc))
      }))
    }
    return(step(from_ms, list()))
  }

  # --- Sync: loop, one page at a time ---
  acc <- list()
  start_ms <- from_ms
  repeat {
    page <- fetch_page(start_ms)
    has_rows <- !is.null(page) && nrow(page) > 0L
    if (has_rows && streaming) {
      on_page(page)
    } else if (has_rows) {
      acc[[length(acc) + 1L]] <- page
    }
    ns <- next_start(page)
    if (is.null(ns)) {
      break
    }
    if (sleep > 0) {
      Sys.sleep(sleep)
    }
    start_ms <- ns
  }
  if (streaming) {
    return(invisible(NULL))
  }
  return(combine_klines(acc))
}
