# tests/testthat/test-BinanceTrading.R
# Tests for BinanceTrading R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_trading <- function() {
  return(BinanceTrading$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("BinanceTrading inherits from BinanceBase", {
  t <- new_trading()
  expect_s3_class(t, "BinanceTrading")
  expect_s3_class(t, "BinanceBase")
})

# -- add_order --

test_that("add_order returns order data.table with correct columns", {
  # The shared order_response fixture is a FILLED order carrying `fills` (the
  # data-shapes vignette showcases the fills expansion). This test covers the
  # fills-free ACK shape — one plain row, no expansion — so strip the fixture
  # back to a resting NEW order before serving it.
  order_data <- mock_order_response()
  order_data$fills <- NULL
  order_data$status <- "NEW"
  order_data$executedQty <- "0.00000000"
  order_data$cummulativeQuoteQty <- "0.00000000"
  resp <- mock_binance_response(data = order_data)
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

  # transact_time should be converted to POSIXct in-place
  expect_true("transact_time" %in% names(dt))
  expect_s3_class(dt$transact_time, "POSIXct")

  # working_time should also be POSIXct (regression — was numeric ms in 0.1.0).
  expect_true("working_time" %in% names(dt))
  expect_s3_class(dt$working_time, "POSIXct")
})

test_that("add_order expands fills to long format when present", {
  order_data <- mock_order_response()
  order_data$fills <- list(
    list(price = "50000.00", qty = "0.00005000", commission = "0.00000005", commissionAsset = "BTC", tradeId = 1L),
    list(price = "50001.00", qty = "0.00005000", commission = "0.00000005", commissionAsset = "BTC", tradeId = 2L)
  )
  resp <- mock_binance_response(data = order_data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order(
    type = "MARKET",
    symbol = "BTCUSDT",
    side = "BUY",
    quantity = 0.0001,
    new_order_resp_type = "FULL"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  # Parent order fields are repeated

  expect_equal(dt$symbol, c("BTCUSDT", "BTCUSDT"))
  expect_equal(dt$order_id, c(28L, 28L))
  # Fill columns are present with prefix + 1-indexed fill_index.
  expect_true("fill_price" %in% names(dt))
  expect_true("fill_qty" %in% names(dt))
  expect_true("fill_commission" %in% names(dt))
  expect_true("fill_commission_asset" %in% names(dt))
  expect_true("fill_index" %in% names(dt))
  expect_equal(dt$fill_price, c("50000.00", "50001.00"))
  expect_equal(dt$fill_index, c(1L, 2L))
  # No list-column 'fills' should exist.
  expect_false("fills" %in% names(dt))
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("add_order parser returns empty data.table on NULL data (no crash)", {
  # Regression: parser used to do `fills <- data$fills` without
  # guarding NULL, crashing with "$ operator applied to NULL" if
  # upstream returned NULL (empty body / JSON-parse failure).
  resp <- mock_binance_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order(
    type = "LIMIT",
    symbol = "BTCUSDT",
    side = "BUY",
    price = 50000,
    quantity = 0.0001
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("add_order with no fills still emits NA-filled fill_* columns (schema-stable)", {
  # Default newOrderRespType for non-MARKET/LIMIT IOC/FOK is ACK or RESULT,
  # neither of which includes `fills`. The returned table should still
  # carry the fill_* columns as NA so downstream code that always reads
  # `dt$fill_price` doesn't break on order types that omit fills.
  order_data <- mock_order_response()
  order_data$fills <- NULL
  resp <- mock_binance_response(data = order_data)
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
  for (col in c("fill_index", "fill_price", "fill_qty", "fill_commission", "fill_commission_asset", "fill_trade_id")) {
    expect_true(col %in% names(dt), info = paste("missing column:", col))
    expect_true(is.na(dt[[col]]), info = paste("expected NA in column:", col))
  }
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("add_order sends correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
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

test_that("add_order_test hits test endpoint and returns confirmation dt", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
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
  # `{}` on success is now reported as `validated = TRUE` — a single
  # logical column rather than a synthetic stub row echoing the
  # request (symbol/side/type). The absence of an error is the
  # validation signal.
  expect_equal(nrow(dt), 1L)
  expect_true("validated" %in% names(dt))
  expect_true(dt$validated)
  # No echoed request fields in the success row — those weren't
  # returned by Binance.
  expect_false("symbol" %in% names(dt))
  expect_false("status" %in% names(dt))
})

# -- cancel_order --

test_that("cancel_order returns cancelled order details with datetime", {
  resp <- mock_binance_response(data = mock_cancel_order_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order("BTCUSDT", order_id = 28)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "CANCELED")
  expect_equal(dt$order_id, 28L)
  expect_equal(dt$symbol, "BTCUSDT")

  # transact_time should be converted to POSIXct in-place
  expect_true("transact_time" %in% names(dt))
  expect_s3_class(dt$transact_time, "POSIXct")
})

test_that("cancel_order requires order_id or orig_client_order_id", {
  expect_error(
    new_trading()$cancel_order("BTCUSDT"),
    "order_id.*orig_client_order_id"
  )
})

test_that("cancel_order sends DELETE method", {
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_cancel_order_data())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    return(resp)
  })

  new_trading()$cancel_order("BTCUSDT", order_id = 28)
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

  # transact_time should be converted to POSIXct in-place
  expect_true("transact_time" %in% names(dt))
  expect_s3_class(dt$transact_time, "POSIXct")
})

test_that("cancel_all_orders returns empty data.table when there are no open orders (no stub row)", {
  # Per the cross-package "no stub rows" convention, the previously-
  # synthetic `(symbol, status = "cancelled")` row is replaced by an
  # empty data.table. The absence of an error is the success signal.
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("cancel_all_orders sends DELETE to openOrders endpoint", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = list(mock_cancel_order_data()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_trading()$cancel_all_orders("BTCUSDT")
  expect_true(grepl("openOrders", captured_url))
  expect_equal(captured_method, "DELETE")
})

# -- get_order --

test_that("get_order returns order with datetime columns", {
  resp <- mock_binance_response(data = mock_query_order_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_order("BTCUSDT", order_id = 28)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$status, "FILLED")

  # time should be converted to POSIXct in-place
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")

  # update_time should be converted to POSIXct in-place
  expect_true("update_time" %in% names(dt))
  expect_s3_class(dt$update_time, "POSIXct")

  # working_time should be POSIXct (regression — was numeric ms in 0.1.0).
  expect_true("working_time" %in% names(dt))
  expect_s3_class(dt$working_time, "POSIXct")
})

test_that("get_order requires order_id or orig_client_order_id", {
  expect_error(
    new_trading()$get_order("BTCUSDT"),
    "order_id.*orig_client_order_id"
  )
})

# -- get_open_orders --

test_that("get_open_orders returns data.table with time", {
  resp <- mock_binance_response(data = mock_open_orders_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "NEW")
  expect_true("time" %in% names(dt))
  # working_time should be POSIXct (regression — was numeric ms in 0.1.0).
  expect_true("working_time" %in% names(dt))
  expect_s3_class(dt$working_time, "POSIXct")
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
  expect_true("time" %in% names(dt))
  # working_time should be POSIXct (regression — was numeric ms in 0.1.0).
  expect_true("working_time" %in% names(dt))
  expect_s3_class(dt$working_time, "POSIXct")
})

test_that("get_all_orders passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_open_orders_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
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
