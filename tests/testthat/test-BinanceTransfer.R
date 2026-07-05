# tests/testthat/test-BinanceTransfer.R
# Tests for BinanceTransfer R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_transfer <- function() {
  return(BinanceTransfer$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("BinanceTransfer inherits from BinanceBase", {
  t <- new_transfer()
  expect_s3_class(t, "BinanceTransfer")
  expect_s3_class(t, "BinanceBase")
})

# -- add_transfer --

test_that("add_transfer returns data.table with tran_id", {
  resp <- mock_binance_response(data = mock_transfer_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$add_transfer(
    type = "MAIN_UMFUTURE",
    asset = "USDT",
    amount = 100
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("tran_id" %in% names(dt))
  expect_equal(dt$tran_id, 13526853623)
})

test_that("add_transfer hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_transfer_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_transfer()$add_transfer(
    type = "MAIN_UMFUTURE",
    asset = "USDT",
    amount = 100
  )
  expect_true(grepl("sapi/v1/asset/transfer", captured_url))
  expect_equal(captured_method, "POST")
})

test_that("add_transfer passes parameters in query string", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_transfer_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_transfer()$add_transfer(
    type = "MAIN_UMFUTURE",
    asset = "USDT",
    amount = 100
  )
  expect_true(grepl("type=MAIN_UMFUTURE", captured_url))
  expect_true(grepl("asset=USDT", captured_url))
  expect_true(grepl("amount=100", captured_url))
})

test_that("add_transfer validates type parameter", {
  expect_error(
    new_transfer()$add_transfer(
      type = "INVALID_TYPE",
      asset = "USDT",
      amount = 100
    )
  )
})

test_that("add_transfer passes optional fromSymbol and toSymbol", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_transfer_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_transfer()$add_transfer(
    type = "MAIN_ISOLATED_MARGIN",
    asset = "USDT",
    amount = 50,
    from_symbol = "BNBUSDT",
    to_symbol = "BTCUSDT"
  )
  expect_true(grepl("fromSymbol=BNBUSDT", captured_url))
  expect_true(grepl("toSymbol=BTCUSDT", captured_url))
})

# -- get_transfer_history --

test_that("get_transfer_history returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_transfer_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$get_transfer_history(type = "MAIN_UMFUTURE")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)

  # Expected columns
  expect_true("asset" %in% names(dt))
  expect_true("amount" %in% names(dt))
  expect_true("type" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_true("tran_id" %in% names(dt))
  expect_true("timestamp" %in% names(dt))

  # Values
  expect_equal(dt$asset[1], "USDT")
  expect_equal(dt$asset[2], "BTC")
  expect_equal(dt$status[1], "CONFIRMED")
  expect_equal(dt$status[2], "CONFIRMED")
})

test_that("get_transfer_history converts timestamp to POSIXct", {
  resp <- mock_binance_response(data = mock_transfer_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$get_transfer_history(type = "MAIN_UMFUTURE")
  expect_true("timestamp" %in% names(dt))
  expect_s3_class(dt$timestamp, "POSIXct")
})

test_that("get_transfer_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_transfer_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_transfer()$get_transfer_history(type = "MAIN_UMFUTURE")
  expect_true(grepl("sapi/v1/asset/transfer", captured_url))
  expect_true(grepl("type=MAIN_UMFUTURE", captured_url))
})

test_that("get_transfer_history passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_transfer_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_transfer()$get_transfer_history(
    type = "MAIN_UMFUTURE",
    start_time = 1661493146000,
    end_time = 1661593146000,
    current = 1,
    size = 10
  )
  expect_true(grepl("startTime=1661493146000", captured_url))
  expect_true(grepl("endTime=1661593146000", captured_url))
  expect_true(grepl("current=1", captured_url))
  expect_true(grepl("size=10", captured_url))
})

test_that("get_transfer_history validates type parameter", {
  expect_error(
    new_transfer()$get_transfer_history(type = "INVALID_TYPE")
  )
})

test_that("get_transfer_history returns empty data.table when no transfers", {
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$get_transfer_history(type = "MAIN_UMFUTURE")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
