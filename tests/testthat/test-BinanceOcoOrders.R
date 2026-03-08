# tests/testthat/test-BinanceOcoOrders.R
# Tests for BinanceOcoOrders R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_oco <- function() {
  BinanceOcoOrders$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceOcoOrders inherits from BinanceBase", {
  o <- new_oco()
  expect_s3_class(o, "BinanceOcoOrders")
  expect_s3_class(o, "BinanceBase")
})

# -- add_oco_order --

test_that("add_oco_order returns data.table with correct columns", {
  resp <- mock_binance_response(data = mock_oco_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$add_oco_order(
    symbol = "BTCUSDT",
    side = "SELL",
    quantity = 0.0001,
    price = 55000,
    stopPrice = 49000
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$order_list_id, 0L)
  expect_equal(dt$contingency_type, "OCO")
  expect_equal(dt$list_status_type, "EXEC_STARTED")
  expect_equal(dt$list_order_status, "EXECUTING")

  # transact_time should be converted to POSIXct in-place
  expect_true("transact_time" %in% names(dt))
  expect_s3_class(dt$transact_time, "POSIXct")
})

test_that("add_oco_order sends POST to correct endpoint", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_oco_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    resp
  })

  new_oco()$add_oco_order(
    symbol = "BTCUSDT",
    side = "SELL",
    quantity = 0.0001,
    price = 55000,
    stopPrice = 49000
  )
  expect_true(grepl("api/v3/order/oco", captured_url))
  expect_equal(captured_method, "POST")
})

test_that("add_oco_order validates side parameter", {
  expect_error(
    new_oco()$add_oco_order(
      symbol = "BTCUSDT",
      side = "INVALID",
      quantity = 0.0001,
      price = 55000,
      stopPrice = 49000
    ),
    "INVALID"
  )
})

# -- cancel_oco_order --

test_that("cancel_oco_order returns data.table", {
  resp <- mock_binance_response(data = mock_oco_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$cancel_oco_order("BTCUSDT", orderListId = 0)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$order_list_id, 0L)
  expect_equal(dt$symbol, "BTCUSDT")

  # transact_time should be converted to POSIXct in-place
  expect_true("transact_time" %in% names(dt))
  expect_s3_class(dt$transact_time, "POSIXct")
})

test_that("cancel_oco_order requires orderListId or listClientOrderId", {
  expect_error(
    new_oco()$cancel_oco_order("BTCUSDT"),
    "orderListId.*listClientOrderId"
  )
})

test_that("cancel_oco_order sends DELETE method", {
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_oco_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    resp
  })

  new_oco()$cancel_oco_order("BTCUSDT", orderListId = 0)
  expect_equal(captured_method, "DELETE")
})

test_that("cancel_oco_order sends to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_oco_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_oco()$cancel_oco_order("BTCUSDT", orderListId = 0)
  expect_true(grepl("api/v3/orderList", captured_url))
})

# -- get_oco_order --

test_that("get_oco_order returns data.table with datetime columns", {
  resp <- mock_binance_response(data = mock_oco_query_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_oco_order(orderListId = 0)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$order_list_id, 0L)
  expect_equal(dt$list_status_type, "ALL_DONE")
  expect_equal(dt$symbol, "BTCUSDT")

  # transaction_time should be converted to POSIXct in-place
  expect_true("transaction_time" %in% names(dt))
  expect_s3_class(dt$transaction_time, "POSIXct")
})

test_that("get_oco_order requires orderListId or origClientOrderId", {
  expect_error(
    new_oco()$get_oco_order(),
    "orderListId.*origClientOrderId"
  )
})

test_that("get_oco_order sends GET to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_oco_query_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_oco()$get_oco_order(orderListId = 0)
  expect_true(grepl("api/v3/orderList", captured_url))
})

# -- get_open_oco_orders --

test_that("get_open_oco_orders returns data.table", {
  resp <- mock_binance_response(data = list(mock_oco_query_data()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_open_oco_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$order_list_id, 0L)
})

test_that("get_open_oco_orders returns empty data.table when no orders", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_open_oco_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_open_oco_orders sends to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_oco()$get_open_oco_orders()
  expect_true(grepl("api/v3/openOrderList", captured_url))
})

# -- get_all_oco_orders --

test_that("get_all_oco_orders returns data.table", {
  resp <- mock_binance_response(data = list(mock_oco_query_data()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_all_oco_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$order_list_id, 0L)
})

test_that("get_all_oco_orders passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(mock_oco_query_data()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_oco()$get_all_oco_orders(limit = 50, fromId = 10)
  expect_true(grepl("limit=50", captured_url))
  expect_true(grepl("fromId=10", captured_url))
})

test_that("get_all_oco_orders returns empty data.table when no orders", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_all_oco_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_all_oco_orders sends to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(mock_oco_query_data()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_oco()$get_all_oco_orders()
  expect_true(grepl("api/v3/allOrderList", captured_url))
})
