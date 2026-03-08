# tests/testthat/test-BinanceAccount.R
# Tests for BinanceAccount R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_account <- function() {
  BinanceAccount$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceAccount inherits from BinanceBase", {
  a <- new_account()
  expect_s3_class(a, "BinanceAccount")
  expect_s3_class(a, "BinanceBase")
})

# -- get_account_info --

test_that("get_account_info returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_account_data())
  httr2::local_mocked_responses(function(req) resp)

  info <- new_account()$get_account_info()
  expect_s3_class(info, "data.table")
  expect_equal(nrow(info), 1L)
  expect_true("maker_commission" %in% names(info))
  expect_true("taker_commission" %in% names(info))
  expect_true("can_trade" %in% names(info))
  expect_true("can_withdraw" %in% names(info))
  expect_true("can_deposit" %in% names(info))
  expect_true("account_type" %in% names(info))
  expect_true("uid" %in% names(info))
  expect_equal(info$maker_commission, 15L)
  expect_equal(info$account_type, "SPOT")
  expect_equal(info$uid, 354937868L)
  expect_true(info$can_trade)

  # commission_rates and permissions are preserved
  expect_true("commission_rates" %in% names(info))
  expect_true("permissions" %in% names(info))
})

test_that("get_account_info does not include balances", {
  resp <- mock_binance_response(data = mock_account_data())
  httr2::local_mocked_responses(function(req) resp)

  info <- new_account()$get_account_info()
  expect_false("balances" %in% names(info))
  expect_false("asset" %in% names(info))
})

# -- get_balances --

test_that("get_balances returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_account_data())
  httr2::local_mocked_responses(function(req) resp)

  balances <- new_account()$get_balances()
  expect_s3_class(balances, "data.table")
  expect_equal(nrow(balances), 3L)
  expect_true("asset" %in% names(balances))
  expect_true("free" %in% names(balances))
  expect_true("locked" %in% names(balances))
  expect_equal(sort(balances$asset), c("BTC", "ETH", "LTC"))
})

test_that("get_balances passes omitZeroBalances parameter", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_account_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_account()$get_balances(omitZeroBalances = TRUE)
  expect_true(grepl("omitZeroBalances=true", captured_url))
})

# -- get_trades --

test_that("get_trades returns data.table with datetime", {
  resp <- mock_binance_response(data = mock_my_trades_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_trades("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)

  # Expected columns
  expect_true("symbol" %in% names(dt))
  expect_true("id" %in% names(dt))
  expect_true("order_id" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("qty" %in% names(dt))
  expect_true("commission" %in% names(dt))
  expect_true("commission_asset" %in% names(dt))
  expect_true("is_buyer" %in% names(dt))
  expect_true("is_maker" %in% names(dt))

  # datetime conversion
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")

  # Values
  expect_equal(dt$symbol[1], "BTCUSDT")
  expect_equal(dt$id[1], 28457L)
  expect_true(dt$is_buyer[1])
  expect_false(dt$is_maker[1])
})

test_that("get_trades passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_my_trades_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_account()$get_trades("BTCUSDT", limit = 50)
  expect_true(grepl("symbol=BTCUSDT", captured_url))
  expect_true(grepl("limit=50", captured_url))
})

test_that("get_trades returns empty data.table when no trades", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_trades("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
