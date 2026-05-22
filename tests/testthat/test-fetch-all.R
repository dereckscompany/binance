# ===========================================================================
# Tests for fetch_all klines segmentation
# These tests are written as if the functionality already exists.
# Running against the current code should produce FAILURES.
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: generate N mock kline rows starting from a given timestamp
# ---------------------------------------------------------------------------
make_mock_klines <- function(n, start_ms = 1704067200000, interval_ms = 3600000) {
  return(lapply(seq_len(n), function(i) {
    ts <- start_ms + (i - 1) * interval_ms
    return(list(
      ts,
      "42000.00",
      "42100.00",
      "41900.00",
      "42050.00",
      "100.5",
      ts + interval_ms - 1,
      "4200000.00",
      150,
      "50.25",
      "2100000.00",
      "0"
    ))
  }))
}

# ---------------------------------------------------------------------------
# Binance Spot: get_klines with fetch_all = TRUE
# ---------------------------------------------------------------------------
test_that("get_klines with fetch_all = TRUE makes multiple API calls for large ranges", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)

  # 2000 hours of 1h candles requires >= 2 API calls (1000 max per call)
  call_count <- 0L
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    parsed <- httr2::url_parse(req$url)
    start_ms <- as.numeric(parsed$query$startTime)
    end_ms <- as.numeric(parsed$query$endTime)

    interval_ms <- 3600000 # 1h in ms
    n <- min(1000L, floor((end_ms - start_ms) / interval_ms))
    n <- max(n, 1L)
    return(mock_binance_response(data = make_mock_klines(n, start_ms = start_ms, interval_ms = interval_ms)))
  })

  dt <- market$get_klines(
    symbol = "BTCUSDT",
    interval = "1h",
    startTime = as.POSIXct("2024-01-01", tz = "UTC"),
    endTime = as.POSIXct("2024-03-25", tz = "UTC"),
    fetch_all = TRUE,
    sleep = 0
  )

  expect_s3_class(dt, "data.table")
  expect_true(call_count >= 2L, info = paste("Expected >= 2 API calls for 2000+ hours, got", call_count))
  expect_true(nrow(dt) > 1000L, info = paste("Expected > 1000 rows, got", nrow(dt)))
})

test_that("get_klines with fetch_all = TRUE deduplicates and sorts overlapping segments", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)

  # 2500 hours needs 3 segments with overlaps. Return full 1000 per call to
  # guarantee overlapping timestamps between segment boundaries.
  call_count <- 0L
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    parsed <- httr2::url_parse(req$url)
    start_ms <- as.numeric(parsed$query$startTime)
    return(mock_binance_response(data = make_mock_klines(1000, start_ms = start_ms, interval_ms = 3600000)))
  })

  dt <- market$get_klines(
    symbol = "BTCUSDT",
    interval = "1h",
    startTime = as.POSIXct("2024-01-01", tz = "UTC"),
    endTime = as.POSIXct("2024-04-15", tz = "UTC"),
    fetch_all = TRUE,
    sleep = 0
  )

  expect_s3_class(dt, "data.table")
  # Must have made multiple calls
  expect_true(call_count >= 2L, info = paste("Expected >= 2 API calls, got", call_count))
  # No duplicate open_time values after dedup
  expect_equal(nrow(dt), length(unique(dt$open_time)), info = "Segmented results should be deduplicated by open_time")
  # Sorted ascending
  expect_true(all(diff(as.numeric(dt$open_time)) >= 0), info = "Results should be sorted by open_time ascending")
})

test_that("get_klines with fetch_all = FALSE does NOT segment (default single call)", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)

  call_count <- 0L
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    return(mock_binance_response(data = make_mock_klines(1000)))
  })

  # Default (fetch_all = FALSE): single API call, truncation warning
  expect_warning(
    dt <- market$get_klines(
      symbol = "BTCUSDT",
      interval = "1h",
      startTime = as.POSIXct("2024-01-01", tz = "UTC"),
      endTime = as.POSIXct("2024-03-25", tz = "UTC")
    ),
    regexp = "truncat|1000"
  )

  expect_equal(call_count, 1L, info = "Default mode should make exactly 1 API call")
  expect_equal(nrow(dt), 1000L)
})

test_that("get_klines with fetch_all = TRUE suppresses truncation warning", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)

  httr2::local_mocked_responses(function(req) {
    parsed <- httr2::url_parse(req$url)
    start_ms <- as.numeric(parsed$query$startTime)
    end_ms <- as.numeric(parsed$query$endTime)
    interval_ms <- 3600000
    n <- min(1000L, floor((end_ms - start_ms) / interval_ms))
    n <- max(n, 1L)
    return(mock_binance_response(data = make_mock_klines(n, start_ms = start_ms, interval_ms = interval_ms)))
  })

  # When fetch_all = TRUE, no truncation warning should be emitted
  expect_no_warning(
    market$get_klines(
      symbol = "BTCUSDT",
      interval = "1h",
      startTime = as.POSIXct("2024-01-01", tz = "UTC"),
      endTime = as.POSIXct("2024-03-25", tz = "UTC"),
      fetch_all = TRUE,
      sleep = 0
    )
  )
})

# ---------------------------------------------------------------------------
# Binance Futures: get_klines with fetch_all = TRUE
# ---------------------------------------------------------------------------
test_that("BinanceFuturesData$get_klines with fetch_all segments large ranges", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://fapi.binance.com"
  futures <- BinanceFuturesData$new(keys = KEYS, base_url = BASE)

  call_count <- 0L
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    parsed <- httr2::url_parse(req$url)
    start_ms <- as.numeric(parsed$query$startTime)
    end_ms <- as.numeric(parsed$query$endTime)
    interval_ms <- 3600000
    n <- min(1500L, floor((end_ms - start_ms) / interval_ms))
    n <- max(n, 1L)
    return(mock_binance_response(data = make_mock_klines(n, start_ms = start_ms, interval_ms = interval_ms)))
  })

  dt <- futures$get_klines(
    symbol = "BTCUSDT",
    interval = "1h",
    startTime = as.POSIXct("2024-01-01", tz = "UTC"),
    endTime = as.POSIXct("2024-04-15", tz = "UTC"),
    fetch_all = TRUE,
    sleep = 0
  )

  expect_s3_class(dt, "data.table")
  # 2520 hours ~ needs at least 2 calls at 1500 max
  expect_true(call_count >= 2L, info = paste("Expected >= 2 API calls for futures, got", call_count))
  expect_true(nrow(dt) > 1500L, info = paste("Expected > 1500 rows for futures, got", nrow(dt)))
  # Deduplication
  expect_equal(nrow(dt), length(unique(dt$open_time)), info = "Futures segmented results should be deduplicated")
})

# ---------------------------------------------------------------------------
# Async mode: test binance_fetch_klines directly with is_async = TRUE
# (httr2::local_mocked_responses does not intercept req_perform_promise,
#  so we test the impl function directly with a .req_fn that returns promises)
# ---------------------------------------------------------------------------
test_that("binance_fetch_klines works in async mode (spot)", {
  skip_if_not_installed("promises")
  skip_if_not_installed("later")

  call_count <- 0L
  # Mock .req_fn that returns a promise resolving to a parsed data.table
  mock_req_fn <- function(endpoint, method, query, auth, .parser) {
    call_count <<- call_count + 1L
    start_ms <- as.numeric(query$startTime)
    end_ms <- as.numeric(query$endTime)
    interval_ms <- 3600000
    n <- min(1000L, floor((end_ms - start_ms) / interval_ms))
    n <- max(n, 1L)
    klines <- make_mock_klines(n, start_ms = start_ms, interval_ms = interval_ms)
    return(promises::promise_resolve(.parser(klines)))
  }

  result_promise <- binance:::binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1h",
    from = as.POSIXct("2024-01-01", tz = "UTC"),
    to = as.POSIXct("2024-03-25", tz = "UTC"),
    .req_fn = mock_req_fn,
    is_async = TRUE,
    endpoint = "/api/v3/klines",
    max_candles = 1000L,
    sleep = 0
  )

  expect_true(promises::is.promise(result_promise), info = "Async fetch_klines should return a promise")

  resolved <- NULL
  error_msg <- NULL
  promises::then(
    result_promise,
    onFulfilled = function(val) {
      return(resolved <<- val)
    },
    onRejected = function(err) {
      return(error_msg <<- conditionMessage(err))
    }
  )
  for (i in 1:20) {
    later::run_now(timeoutSecs = 0.5)
  }

  expect_null(error_msg, info = paste("Promise rejected with:", error_msg))
  expect_false(is.null(resolved), info = "Promise should have resolved")
  if (!is.null(resolved)) {
    expect_s3_class(resolved, "data.table")
    expect_true(nrow(resolved) > 1000L, info = paste("Async fetch_all should return > 1000 rows, got", nrow(resolved)))
    expect_true(call_count >= 2L, info = paste("Async fetch_all should make >= 2 API calls, got", call_count))
  }
})

test_that("binance_fetch_klines works in async mode (futures)", {
  skip_if_not_installed("promises")
  skip_if_not_installed("later")

  call_count <- 0L
  mock_req_fn <- function(endpoint, method, query, auth, .parser) {
    call_count <<- call_count + 1L
    start_ms <- as.numeric(query$startTime)
    end_ms <- as.numeric(query$endTime)
    interval_ms <- 3600000
    n <- min(1500L, floor((end_ms - start_ms) / interval_ms))
    n <- max(n, 1L)
    klines <- make_mock_klines(n, start_ms = start_ms, interval_ms = interval_ms)
    return(promises::promise_resolve(.parser(klines)))
  }

  result_promise <- binance:::binance_fetch_klines(
    symbol = "BTCUSDT",
    timeframe = "1h",
    from = as.POSIXct("2024-01-01", tz = "UTC"),
    to = as.POSIXct("2024-04-15", tz = "UTC"),
    .req_fn = mock_req_fn,
    is_async = TRUE,
    endpoint = "/fapi/v1/klines",
    max_candles = 1500L,
    sleep = 0
  )

  expect_true(promises::is.promise(result_promise))

  resolved <- NULL
  error_msg <- NULL
  promises::then(
    result_promise,
    onFulfilled = function(val) {
      return(resolved <<- val)
    },
    onRejected = function(err) {
      return(error_msg <<- conditionMessage(err))
    }
  )
  for (i in 1:20) {
    later::run_now(timeoutSecs = 0.5)
  }

  expect_null(error_msg, info = paste("Promise rejected with:", error_msg))
  expect_false(is.null(resolved), info = "Promise should have resolved")
  if (!is.null(resolved)) {
    expect_s3_class(resolved, "data.table")
    expect_true(nrow(resolved) > 1500L, info = paste("Async futures should return > 1500 rows, got", nrow(resolved)))
    expect_true(call_count >= 2L, info = paste("Async futures should make >= 2 calls, got", call_count))
  }
})
