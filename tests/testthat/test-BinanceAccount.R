# tests/testthat/test-BinanceAccount.R
# Tests for BinanceAccount R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_account <- function() {
  return(BinanceAccount$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("BinanceAccount inherits from BinanceBase", {
  a <- new_account()
  expect_s3_class(a, "BinanceAccount")
  expect_s3_class(a, "BinanceBase")
})

# -- get_account_info --

test_that("get_account_info returns a single-row data.table with permissions `;`-collapsed", {
  resp <- mock_binance_response(data = mock_account_data())
  httr2::local_mocked_responses(function(req) resp)

  info <- new_account()$get_account_info()
  expect_s3_class(info, "data.table")
  # mock_account_data has permissions = list("SPOT") — collapsed to a
  # scalar character. Schema is one row per account regardless of how
  # many permissions are present.
  expect_equal(nrow(info), 1L)
  expect_true("maker_commission" %in% names(info))
  expect_true("taker_commission" %in% names(info))
  expect_true("can_trade" %in% names(info))
  expect_true("can_withdraw" %in% names(info))
  expect_true("can_deposit" %in% names(info))
  expect_true("account_type" %in% names(info))
  expect_true("uid" %in% names(info))
  expect_equal(info$maker_commission[1], 15L)
  expect_equal(info$account_type[1], "SPOT")
  expect_equal(info$uid[1], 354937868L)
  expect_true(info$can_trade[1])

  # commission_rates flattened to wide columns.
  expect_true("commission_rates_maker" %in% names(info))
  expect_true("commission_rates_taker" %in% names(info))
  expect_true("commission_rates_buyer" %in% names(info))
  expect_true("commission_rates_seller" %in% names(info))
  expect_false("commission_rates" %in% names(info))

  # permissions is a single `;`-collapsed character column (cross-package
  # convention via collapse_string_array_fields).
  expect_true("permissions" %in% names(info))
  expect_type(info$permissions, "character")
  expect_equal(info$permissions, "SPOT")
})

test_that("get_account_info keeps one row even with multiple permissions (permissions `;`-joined)", {
  account_data <- mock_account_data()
  account_data$permissions <- list("SPOT", "MARGIN")
  resp <- mock_binance_response(data = account_data)
  httr2::local_mocked_responses(function(req) resp)

  info <- new_account()$get_account_info()
  expect_s3_class(info, "data.table")
  expect_equal(nrow(info), 1L)
  expect_equal(info$permissions, "SPOT;MARGIN")
  # Round-trip via strsplit recovers the original vector.
  expect_equal(
    strsplit(info$permissions, ";", fixed = TRUE)[[1]],
    c("SPOT", "MARGIN")
  )
  # No list columns anywhere.
  list_cols <- names(info)[vapply(info, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("get_account_info does not include balances", {
  resp <- mock_binance_response(data = mock_account_data())
  httr2::local_mocked_responses(function(req) resp)

  info <- new_account()$get_account_info()
  expect_false("balances" %in% names(info))
  expect_false("asset" %in% names(info))
})

test_that("get_account_info converts update_time to POSIXct (regression)", {
  # Was numeric ms in 0.1.0 despite the cross-package POSIXct convention.
  resp <- mock_binance_response(data = mock_account_data())
  httr2::local_mocked_responses(function(req) resp)

  info <- new_account()$get_account_info()
  expect_true("update_time" %in% names(info))
  expect_s3_class(info$update_time, "POSIXct")
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
    return(resp)
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
    return(resp)
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
