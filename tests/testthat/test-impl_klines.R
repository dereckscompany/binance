# tests/testthat/test-impl_klines.R
# Tests for the shared klines fetching implementation.

# -- binance_interval_map --

test_that("binance_interval_map contains all expected intervals", {
  expected <- c(
    "1s", "1m", "3m", "5m", "15m", "30m",
    "1h", "2h", "4h", "6h", "8h", "12h",
    "1d", "3d", "1w", "1M"
  )
  expect_equal(sort(names(binance_interval_map)), sort(expected))
})

test_that("binance_interval_map values are correct durations in seconds", {
  expect_equal(binance_interval_map[["1m"]], 60L)
  expect_equal(binance_interval_map[["15m"]], 900L)
  expect_equal(binance_interval_map[["1h"]], 3600L)
  expect_equal(binance_interval_map[["1d"]], 86400L)
  expect_equal(binance_interval_map[["1w"]], 604800L)
})

# -- binance_fetch_klines validation --

test_that("binance_fetch_klines rejects invalid interval", {
  fake_fn <- function(...) stop("Should not be called")
  expect_error(
    binance_fetch_klines(
      symbol = "BTCUSDT",
      interval = "2m",
      from = 1729100000,
      to = 1729200000,
      .req_fn = fake_fn
    ),
    "Invalid interval.*2m"
  )
})

test_that("binance_fetch_klines returns empty data.table for zero-width range", {
  fake_fn <- function(...) stop("Should not be called")
  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    interval = "15m",
    from = 1729100000,
    to = 1729100000,
    .req_fn = fake_fn
  )
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
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
        "67000.00", "67100.00", "66900.00", "67050.00",
        "100.00", (from_ts + 3600) * 1000 - 1,
        "6700000.00", 500L, "50.00", "3350000.00", "0"
      ),
      list(
        (from_ts + 3600) * 1000,
        "67050.00", "67200.00", "67000.00", "67150.00",
        "120.00", (from_ts + 7200) * 1000 - 1,
        "8058000.00", 600L, "60.00", "4029000.00", "0"
      )
    )
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    interval = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_equal(call_count, 1L)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2L)
  expect_true(all(c("open_time", "open", "high", "low", "close", "volume") %in% names(result)))

  # Verify query params
  q <- captured_queries[[1]]
  expect_equal(q$symbol, "BTCUSDT")
  expect_equal(q$interval, "1h")
})

test_that("binance_fetch_klines segments large time ranges", {
  call_count <- 0L

  # 1000 candles * 3600s = 3,600,000s per segment
  # Request 2000 candles worth = should be 2+ segments
  from_ts <- 1729100000
  to_ts <- from_ts + 2000 * 3600

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    # Return 1 candle per segment
    start_ms <- as.numeric(query$startTime)
    data <- list(
      list(
        start_ms, "67000.00", "67100.00", "66900.00", "67050.00",
        "100.00", start_ms + 3600000 - 1,
        "6700000.00", 500L, "50.00", "3350000.00", "0"
      )
    )
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    interval = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_gt(call_count, 1L)
  expect_s3_class(result, "data.table")
})

test_that("binance_fetch_klines deduplicates by open_time", {
  from_ts <- 1729100000
  to_ts <- from_ts + 7200

  call_count <- 0L
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    # Always return the same 2 candles
    data <- list(
      list(
        from_ts * 1000,
        "67000.00", "67100.00", "66900.00", "67050.00",
        "100.00", (from_ts + 3600) * 1000 - 1,
        "6700000.00", 500L, "50.00", "3350000.00", "0"
      ),
      list(
        (from_ts + 3600) * 1000,
        "67050.00", "67200.00", "67000.00", "67150.00",
        "120.00", (from_ts + 7200) * 1000 - 1,
        "8058000.00", 600L, "60.00", "4029000.00", "0"
      )
    )
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    interval = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  # Should be deduplicated
  expect_equal(nrow(result), length(unique(result$open_time)))
})

test_that("binance_fetch_klines sorts by open_time ascending", {
  from_ts <- 1729100000
  to_ts <- from_ts + 10800 # 3 candles at 1h

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    # Return in reverse order
    data <- list(
      list(
        (from_ts + 7200) * 1000,
        "67200.00", "67300.00", "67100.00", "67250.00",
        "130.00", (from_ts + 10800) * 1000 - 1,
        "8742500.00", 700L, "65.00", "4371250.00", "0"
      ),
      list(
        (from_ts + 3600) * 1000,
        "67050.00", "67200.00", "67000.00", "67150.00",
        "120.00", (from_ts + 7200) * 1000 - 1,
        "8058000.00", 600L, "60.00", "4029000.00", "0"
      ),
      list(
        from_ts * 1000,
        "67000.00", "67100.00", "66900.00", "67050.00",
        "100.00", (from_ts + 3600) * 1000 - 1,
        "6700000.00", 500L, "50.00", "3350000.00", "0"
      )
    )
    return(.parser(data))
  }

  result <- binance_fetch_klines(
    symbol = "BTCUSDT",
    interval = "1h",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  timestamps <- as.numeric(result$open_time)
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
    interval = "1d",
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
    interval = "1d",
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
    interval = "15m",
    from = 1729100000,
    to = 1729200000,
    .req_fn = fake_req_fn
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
})

# -- Segment overlap --

test_that("binance_fetch_klines segments overlap by 1 candle", {
  captured_queries <- list()
  call_count <- 0L

  # Force 2 segments: 1000 candles * 900s * 1000ms = 900,000,000ms per segment
  from_ts <- 1000000
  to_ts <- from_ts + 1000 * 900 + 900 # just over 1 segment at 15m

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    captured_queries[[call_count]] <<- query
    return(.parser(list()))
  }

  binance_fetch_klines(
    symbol = "BTCUSDT",
    interval = "15m",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_equal(call_count, 2L)

  # Second segment's startTime should be first segment's endTime minus interval_ms (900*1000)
  seg1_end <- as.numeric(captured_queries[[1]]$endTime)
  seg2_start <- as.numeric(captured_queries[[2]]$startTime)
  expect_equal(seg2_start, seg1_end - 900 * 1000)
})
