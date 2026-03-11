# File: R/impl_klines.R
# Shared klines fetching implementation used by both BinanceMarketData and
# binance_backfill_klines(). Handles time-range segmentation, per-segment
# HTTP requests, deduplication, and sorting.

# Frequency Map for Binance Kline Timeframes
#
# Maps human-readable timeframe strings to their duration in seconds.
# Used by binance_fetch_klines() for time-range segmentation.
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
# Binance's REST API. Automatically segments the requested time range into
# chunks of up to 1000 candles (the per-request limit), fetches each segment
# via the supplied .req_fn, deduplicates, and sorts.
#
# This function is used internally by BinanceMarketData$get_klines() and
# by binance_backfill_klines(). It does not depend on any R6 class instance.
binance_fetch_klines <- function(
  symbol,
  timeframe = "1h",
  from = lubridate::now("UTC") - lubridate::dhours(24),
  to = lubridate::now("UTC"),
  .req_fn,
  is_async = FALSE,
  endpoint = "/api/v3/klines",
  max_candles = 1000L,
  sleep = 0
) {
  if (!timeframe %in% names(binance_timeframe_map)) {
    rlang::abort(paste0(
      "Invalid timeframe '",
      timeframe,
      "'. Valid: ",
      paste(names(binance_timeframe_map), collapse = ", ")
    ))
  }

  timeframe_seconds <- binance_timeframe_map[[timeframe]]
  from_ms <- as.numeric(from) * 1000
  to_ms <- as.numeric(to) * 1000

  # Split into segments of up to max_candles each, with 1-candle overlap
  # to prevent gaps at segment boundaries. Dedup handles the overlap.
  segments <- list()
  seg_start <- from_ms
  while (seg_start < to_ms) {
    seg_end <- min(seg_start + max_candles * timeframe_seconds * 1000, to_ms)
    segments[[length(segments) + 1L]] <- list(
      startTime = format(seg_start, scientific = FALSE),
      endTime = format(seg_end, scientific = FALSE)
    )
    # Overlap by 1 candle only when there are more segments to come.
    if (seg_end >= to_ms) {
      break
    }
    seg_start <- seg_end - timeframe_seconds * 1000
  }

  if (length(segments) == 0L) {
    return(data.table::data.table())
  }

  # Combiner: rbindlist, dedup by open_time, sort ascending
  combine_klines <- function(results_list) {
    dts <- Filter(function(x) nrow(x) > 0, results_list)
    if (length(dts) == 0L) {
      return(data.table::data.table())
    }
    dt <- data.table::rbindlist(dts)
    dt <- unique(dt, by = "open_time")
    data.table::setorder(dt, open_time)
    return(dt)
  }

  # Fetch function for one segment
  fetch_segment <- function(seg) {
    return(.req_fn(
      endpoint = endpoint,
      method = "GET",
      query = list(
        symbol = symbol,
        interval = timeframe,
        startTime = seg$startTime,
        endTime = seg$endTime,
        limit = max_candles
      ),
      auth = FALSE,
      .parser = parse_klines
    ))
  }

  # Async: sequential promise chain (one segment at a time to respect rate limits)
  if (is_async) {
    seed <- promises::promise_resolve(list())
    chain <- Reduce(
      function(acc_promise, seg) {
        acc_promise$then(function(acc) {
          fetch_segment(seg)$then(function(result) {
            c(acc, list(result))
          })
        })
      },
      segments,
      accumulate = FALSE,
      init = seed
    )
    return(chain$then(combine_klines))
  }

  # Sync: sequential with sleep between segments
  all_results <- vector("list", length(segments))
  for (i in seq_along(segments)) {
    all_results[[i]] <- fetch_segment(segments[[i]])
    if (i < length(segments) && sleep > 0) {
      Sys.sleep(sleep)
    }
  }
  return(combine_klines(all_results))
}
