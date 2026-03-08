# tests/testthat/test-BinanceTrading.R
# Tests for BinanceTrading R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_trading <- function() {
  BinanceTrading$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceTrading inherits from BinanceBase", {
  t <- new_trading()
  expect_s3_class(t, "BinanceTrading")
  expect_s3_class(t, "BinanceBase")
})

# -- add_order --

test_that("add_order returns order data.table with correct columns", {
  resp <- mock_binance_response(data = mock_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order(
    type = "LIMIT",
    symbol = "BTCUSDT",
    side = "BUY",
    price = 50000,
    quantity = 0.0001
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$order_id, 28L)
  expect_equal(dt$status, "NEW")
  expect_equal(dt$side, "BUY")
  expect_equal(dt$type, "LIMIT")

  # transact_time should be converted to datetime
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
  expect_false("transact_time" %in% names(dt))
})

test_that("add_order sends correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_trading()$add_order(
    type = "LIMIT",
    symbol = "BTCUSDT",
    side = "BUY",
    price = 50000,
    quantity = 0.0001
  )
  expect_true(grepl("api/v3/order", captured_url))
  expect_false(grepl("order/test", captured_url))
})

# -- add_order_test --

test_that("add_order_test hits test endpoint and returns empty data.table", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  dt <- new_trading()$add_order_test(
    type = "LIMIT",
    symbol = "BTCUSDT",
    side = "BUY",
    price = 50000,
    quantity = 0.0001
  )
  expect_true(grepl("order/test", captured_url))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- cancel_order --

test_that("cancel_order returns cancelled order details with datetime", {
  resp <- mock_binance_response(data = mock_cancel_order_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order("BTCUSDT", orderId = 28)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "CANCELED")
  expect_equal(dt$order_id, 28L)
  expect_equal(dt$symbol, "BTCUSDT")

  # transact_time should be converted to datetime
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
  expect_false("transact_time" %in% names(dt))
})

test_that("cancel_order requires orderId or origClientOrderId", {
  expect_error(
    new_trading()$cancel_order("BTCUSDT"),
    "orderId.*origClientOrderId"
  )
})

test_that("cancel_order sends DELETE method", {
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_cancel_order_data())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    resp
  })

  new_trading()$cancel_order("BTCUSDT", orderId = 28)
  expect_equal(captured_method, "DELETE")
})

# -- cancel_all_orders --

test_that("cancel_all_orders returns data.table with datetime", {
  resp <- mock_binance_response(data = list(mock_cancel_order_data()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "CANCELED")

  # transact_time should be converted to datetime
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
  expect_false("transact_time" %in% names(dt))
})

test_that("cancel_all_orders sends DELETE to openOrders endpoint", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = list(mock_cancel_order_data()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    resp
  })

  new_trading()$cancel_all_orders("BTCUSDT")
  expect_true(grepl("openOrders", captured_url))
  expect_equal(captured_method, "DELETE")
})

# -- get_order --

test_that("get_order returns order with datetime columns", {
  resp <- mock_binance_response(data = mock_query_order_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_order("BTCUSDT", orderId = 28)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$status, "FILLED")

  # time → datetime_created
  expect_true("datetime_created" %in% names(dt))
  expect_s3_class(dt$datetime_created, "POSIXct")
  expect_false("time" %in% names(dt))

  # update_time → datetime_updated
  expect_true("datetime_updated" %in% names(dt))
  expect_s3_class(dt$datetime_updated, "POSIXct")
  expect_false("update_time" %in% names(dt))
})

test_that("get_order requires orderId or origClientOrderId", {
  expect_error(
    new_trading()$get_order("BTCUSDT"),
    "orderId.*origClientOrderId"
  )
})

# -- get_open_orders --

test_that("get_open_orders returns data.table with datetime_created", {
  resp <- mock_binance_response(data = mock_open_orders_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "NEW")
  expect_true("datetime_created" %in% names(dt))
  expect_false("time" %in% names(dt))
})

test_that("get_open_orders returns empty data.table when no orders", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_all_orders --

test_that("get_all_orders returns data.table with datetime columns", {
  resp <- mock_binance_response(data = mock_open_orders_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("datetime_created" %in% names(dt))
})

test_that("get_all_orders passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_open_orders_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_trading()$get_all_orders("BTCUSDT", limit = 50)
  expect_true(grepl("limit=50", captured_url))
  expect_true(grepl("symbol=BTCUSDT", captured_url))
})

test_that("get_all_orders returns empty data.table when no orders", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
