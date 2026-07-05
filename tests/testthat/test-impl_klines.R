# tests/testthat/test-impl_klines.R
# Tests for the shared klines fetching implementation.

# -- binance_timeframe_map --

test_that("binance_timeframe_map contains all expected timeframes", {
  expected <- c(
    "1s",
    "1m",
    "3m",
    "5m",
    "15m",
    "30m",
    "1h",
    "2h",
    "4h",
    "6h",
    "8h",
    "12h",
    "1d",
    "3d",
    "1w",
    "1M"
  )
  expect_equal(sort(names(binance_timeframe_map)), sort(expected))
})

test_that("binance_timeframe_map values are correct durations in seconds", {
  expect_equal(binance_timeframe_map[["1m"]], 60L)
  expect_equal(binance_timeframe_map[["15m"]], 900L)
  expect_equal(binance_timeframe_map[["1h"]], 3600L)
  expect_equal(binance_timeframe_map[["1d"]], 86400L)
  expect_equal(binance_timeframe_map[["1w"]], 604800L)
})

# -- binance_fetch_klines validation --

test_that("binance_fetch_klines rejects invalid timeframe", {
  fake_fn <- function(...) stop("Should not be called")
  expect_error(
    binance_fetch_klines(
      symbol = "BTCUSDT",
      timeframe = "2m",
      from = 1729100000,
      to = 1729200000,
      .req_fn = fake_fn
    ),
    "Invalid timeframe.*2m"
  )
})

test_that("binance_fetch_klines returns the typed zero-row OHLCV schema for an empty range", {
  fake_fn <- function(...) stop("Should not be called")
  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "15m",
    from = 1729100000,
    to = 1729100000,
    .req_fn = fake_fn
  )
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
  # The empty range must still carry the full typed OHLCV schema (not a
  # column-less data.table), so it satisfies get_klines()'s strict @return
  # contract instead of aborting on assert_has_columns.
  expect_identical(result, empty_dt_ohlcv())
  expect_silent(assert_return_BinanceMarketData__get_klines(result))
})

# -- binance_fetch_klines with mock .req_fn --

test_that("binance_fetch_klines fetches single segment correctly", {
  call_count <- 0L
  captured_queries <- list()

  # 2 candles at 1h = 7200 seconds, well within 1000-candle limit
  from_ts <- 1729100000
  to_ts <- from_ts + 7200

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    captured_queries[[call_count]] <<- query
    # Return mock klines in Binance array format
    data <- list(
      list(
        from_ts * 1000,
        "67000.00",
        "67100.00",
        "66900.00",
        "67050.00",
        "100.00",
        (from_ts + 3600) * 1000 - 1,
        "6700000.00",
        500L,
        "50.00",
        "3350000.00",
        "0"
      ),
      list(
        (from_ts + 3600) * 1000,
        "67050.00",
        "67200.00",
        "67000.00",
        "67150.00",
        "120.00",
        (from_ts + 7200) * 1000 - 1,
        "8058000.00",
        600L,
        "60.00",
        "4029000.00",
        "0"
      )
    )
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_equal(call_count, 1L)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2L)
  expect_true(all(c("datetime", "open", "high", "low", "close", "volume") %in% names(result)))

  # Verify query params
  q <- captured_queries[[1]]
  expect_equal(q$symbol, "BTCUSDT")
  expect_equal(q$interval, "1h")
})

test_that("binance_fetch_klines pages forward through large ranges (multiple calls)", {
  call_count <- 0L

  # 2000 hours of 1h candles -> more than one 1000-candle page.
  from_ts <- 1729100000
  to_ts <- from_ts + 2000 * 3600

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    start_ms <- as.numeric(query$startTime)
    end_ms <- as.numeric(query$endTime)
    interval_ms <- 3600000
    n <- max(1L, min(1000L, floor((end_ms - start_ms) / interval_ms)))
    data <- lapply(seq_len(n), function(i) {
      ts <- start_ms + (i - 1) * interval_ms
      return(list(
        ts,
        "67000",
        "67100",
        "66900",
        "67050",
        "100",
        ts + interval_ms - 1,
        "6700000",
        500L,
        "50",
        "3350000",
        "0"
      ))
    })
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_gt(call_count, 1L)
  expect_s3_class(result, "data.table")
  expect_gt(nrow(result), 1000L)
})

test_that("binance_fetch_klines deduplicates by datetime", {
  from_ts <- 1729100000
  to_ts <- from_ts + 7200

  call_count <- 0L
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    # Always return the same 2 candles
    data <- list(
      list(
        from_ts * 1000,
        "67000.00",
        "67100.00",
        "66900.00",
        "67050.00",
        "100.00",
        (from_ts + 3600) * 1000 - 1,
        "6700000.00",
        500L,
        "50.00",
        "3350000.00",
        "0"
      ),
      list(
        (from_ts + 3600) * 1000,
        "67050.00",
        "67200.00",
        "67000.00",
        "67150.00",
        "120.00",
        (from_ts + 7200) * 1000 - 1,
        "8058000.00",
        600L,
        "60.00",
        "4029000.00",
        "0"
      )
    )
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  # Should be deduplicated
  expect_equal(nrow(result), length(unique(result$datetime)))
})

test_that("binance_fetch_klines sorts by datetime ascending", {
  from_ts <- 1729100000
  to_ts <- from_ts + 10800 # 3 candles at 1h

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    # Return in reverse order
    data <- list(
      list(
        (from_ts + 7200) * 1000,
        "67200.00",
        "67300.00",
        "67100.00",
        "67250.00",
        "130.00",
        (from_ts + 10800) * 1000 - 1,
        "8742500.00",
        700L,
        "65.00",
        "4371250.00",
        "0"
      ),
      list(
        (from_ts + 3600) * 1000,
        "67050.00",
        "67200.00",
        "67000.00",
        "67150.00",
        "120.00",
        (from_ts + 7200) * 1000 - 1,
        "8058000.00",
        600L,
        "60.00",
        "4029000.00",
        "0"
      ),
      list(
        from_ts * 1000,
        "67000.00",
        "67100.00",
        "66900.00",
        "67050.00",
        "100.00",
        (from_ts + 3600) * 1000 - 1,
        "6700000.00",
        500L,
        "50.00",
        "3350000.00",
        "0"
      )
    )
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  timestamps <- as.numeric(result$datetime)
  expect_true(all(diff(timestamps) >= 0))
})

test_that("binance_fetch_klines uses correct endpoint", {
  captured_endpoint <- NULL

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    captured_endpoint <<- endpoint
    return(.parser(list()))
  }

  binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1d",
    from = 1729100000,
    to = 1729200000,
    .req_fn = fake_req_fn
  )

  expect_equal(captured_endpoint, "/api/v3/klines")
})

test_that("binance_fetch_klines sets auth = FALSE", {
  captured_auth <- NULL

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    captured_auth <<- auth
    return(.parser(list()))
  }

  binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1d",
    from = 1729100000,
    to = 1729200000,
    .req_fn = fake_req_fn
  )

  expect_false(captured_auth)
})

test_that("binance_fetch_klines handles empty API responses", {
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    return(.parser(list()))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "15m",
    from = 1729100000,
    to = 1729200000,
    .req_fn = fake_req_fn
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
})

# -- Forward-follow: stop at empty, and on_page streaming --

test_that("binance_fetch_klines stops after one empty page (no slice-by-slice probing)", {
  call_count <- 0L
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    return(.parser(list())) # empty
  }

  # A wide range entirely before any data — pre-fix this was probed slice by slice.
  result <- binance_fetch_klines(
    symbol = "NEWCOIN",
    timeframe = "1m",
    from = 1500000000,
    to = 1500000000 + 1e7,
    .req_fn = fake_req_fn
  )

  expect_equal(call_count, 1L)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
})

test_that("binance_fetch_klines streams pages to on_page and returns invisibly", {
  call_count <- 0L
  from_ts <- 1729100000
  to_ts <- from_ts + 2000 * 3600

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    start_ms <- as.numeric(query$startTime)
    end_ms <- as.numeric(query$endTime)
    interval_ms <- 3600000
    n <- max(1L, min(1000L, floor((end_ms - start_ms) / interval_ms)))
    data <- lapply(seq_len(n), function(i) {
      ts <- start_ms + (i - 1) * interval_ms
      return(list(
        ts,
        "67000",
        "67100",
        "66900",
        "67050",
        "100",
        ts + interval_ms - 1,
        "6700000",
        500L,
        "50",
        "3350000",
        "0"
      ))
    })
    return(.parser(data))
  }

  pages_seen <- 0L
  rows_seen <- 0L
  res <- binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn,
    on_page = function(page) {
      pages_seen <<- pages_seen + 1L
      rows_seen <<- rows_seen + nrow(page)
      return(invisible(NULL))
    }
  )

  expect_null(res) # streaming -> returns invisibly (NULL)
  expect_equal(pages_seen, call_count) # one on_page call per fetched page
  expect_gt(rows_seen, 1000L)
})
