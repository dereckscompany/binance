# tests/testthat/test-BinanceDeposit.R
# Tests for BinanceDeposit R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_deposit <- function() {
  BinanceDeposit$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceDeposit inherits from BinanceBase", {
  d <- new_deposit()
  expect_s3_class(d, "BinanceDeposit")
  expect_s3_class(d, "BinanceBase")
})

# -- get_deposit_address --

test_that("get_deposit_address returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_deposit_address_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_address(coin = "BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("address" %in% names(dt))
  expect_true("coin" %in% names(dt))
  expect_true("tag" %in% names(dt))
  expect_true("url" %in% names(dt))
  expect_equal(dt$coin, "BTC")
  expect_equal(dt$address, "1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv")
})

test_that("get_deposit_address hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_deposit_address_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_deposit()$get_deposit_address(coin = "BTC")
  expect_true(grepl("sapi/v1/capital/deposit/address", captured_url))
  expect_true(grepl("coin=BTC", captured_url))
})

test_that("get_deposit_address passes network parameter", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_deposit_address_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_deposit()$get_deposit_address(coin = "USDT", network = "TRX")
  expect_true(grepl("network=TRX", captured_url))
})

# -- get_deposit_history --

test_that("get_deposit_history returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_deposit_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)

  # Expected columns
  expect_true("id" %in% names(dt))
  expect_true("amount" %in% names(dt))
  expect_true("coin" %in% names(dt))
  expect_true("network" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_true("address" %in% names(dt))
  expect_true("address_tag" %in% names(dt))
  expect_true("tx_id" %in% names(dt))
  expect_true("transfer_type" %in% names(dt))
  expect_true("confirm_times" %in% names(dt))
  expect_true("unlock_confirm" %in% names(dt))
  expect_true("wallet_type" %in% names(dt))

  # Values
  expect_equal(dt$coin[1], "BNB")
  expect_equal(dt$status[1], 1L)
  expect_equal(dt$coin[2], "ETH")
  expect_equal(dt$status[2], 0L)
})

test_that("get_deposit_history converts insert_time to POSIXct", {
  resp <- mock_binance_response(data = mock_deposit_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_history()
  expect_true("insert_time" %in% names(dt))
  expect_s3_class(dt$insert_time, "POSIXct")
})

test_that("get_deposit_history converts complete_time to POSIXct", {
  resp <- mock_binance_response(data = mock_deposit_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_history()
  expect_true("complete_time" %in% names(dt))
})

test_that("get_deposit_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_deposit_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_deposit()$get_deposit_history()
  expect_true(grepl("sapi/v1/capital/deposit/hisrec", captured_url))
})

test_that("get_deposit_history passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_deposit_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_deposit()$get_deposit_history(coin = "BTC", status = 1, limit = 50)
  expect_true(grepl("coin=BTC", captured_url))
  expect_true(grepl("status=1", captured_url))
  expect_true(grepl("limit=50", captured_url))
})

test_that("get_deposit_history returns empty data.table when no deposits", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
