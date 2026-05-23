# tests/testthat/test-BinanceMargin.R
# Tests for BinanceMargin R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_margin <- function() {
  return(BinanceMargin$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("BinanceMargin inherits from BinanceBase", {
  m <- new_margin()
  expect_s3_class(m, "BinanceMargin")
  expect_s3_class(m, "BinanceBase")
})

# -- add_borrow --

test_that("add_borrow returns data.table with tran_id", {
  resp <- mock_binance_response(data = mock_margin_borrow_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$add_borrow(asset = "USDT", amount = 100)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("tran_id" %in% names(dt))
  expect_equal(dt$tran_id, 100000001L)
})

test_that("add_borrow sends POST to correct endpoint", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_margin_borrow_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_margin()$add_borrow(asset = "USDT", amount = 100)
  expect_true(grepl("sapi/v1/margin/borrow-repay", captured_url))
  expect_equal(captured_method, "POST")
})

test_that("add_borrow converts amount to character in query", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_borrow_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$add_borrow(asset = "BTC", amount = 0.5)
  expect_true(grepl("amount=0.5", captured_url))
})

# -- add_order --

test_that("add_order returns order data.table with transact_time as POSIXct", {
  resp <- mock_binance_response(data = mock_margin_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$add_order(
    symbol = "BTCUSDT",
    side = "BUY",
    type = "LIMIT",
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
  expect_true("transact_time" %in% names(dt))
  expect_s3_class(dt$transact_time, "POSIXct")
})

test_that("add_order sends POST to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$add_order(
    symbol = "BTCUSDT",
    side = "BUY",
    type = "LIMIT",
    price = 50000,
    quantity = 0.0001
  )
  expect_true(grepl("sapi/v1/margin/order", captured_url))
})

test_that("add_order validates side and type", {
  expect_error(
    new_margin()$add_order(symbol = "BTCUSDT", side = "INVALID", type = "LIMIT"),
    "INVALID"
  )
  expect_error(
    new_margin()$add_order(symbol = "BTCUSDT", side = "BUY", type = "INVALID"),
    "INVALID"
  )
})

test_that("add_order validates sideEffectType when provided", {
  expect_error(
    new_margin()$add_order(
      symbol = "BTCUSDT",
      side = "BUY",
      type = "LIMIT",
      sideEffectType = "INVALID"
    ),
    "INVALID"
  )
})

# -- cancel_order --

test_that("cancel_order returns cancelled order with transact_time as POSIXct", {
  resp <- mock_binance_response(data = mock_margin_cancel_order_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$cancel_order("BTCUSDT", orderId = 28)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "CANCELED")
  expect_equal(dt$order_id, 28L)
  expect_true("transact_time" %in% names(dt))
  expect_s3_class(dt$transact_time, "POSIXct")
})

test_that("cancel_order requires orderId or origClientOrderId", {
  expect_error(
    new_margin()$cancel_order("BTCUSDT"),
    "orderId.*origClientOrderId"
  )
})

test_that("cancel_order sends DELETE method", {
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_margin_cancel_order_data())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    return(resp)
  })

  new_margin()$cancel_order("BTCUSDT", orderId = 28)
  expect_equal(captured_method, "DELETE")
})

# -- get_order --

test_that("get_order returns order with time and update_time as POSIXct", {
  resp <- mock_binance_response(data = mock_margin_query_order_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_order("BTCUSDT", orderId = 28)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$status, "FILLED")
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
  expect_true("update_time" %in% names(dt))
  expect_s3_class(dt$update_time, "POSIXct")
})

test_that("get_order requires orderId or origClientOrderId", {
  expect_error(
    new_margin()$get_order("BTCUSDT"),
    "orderId.*origClientOrderId"
  )
})

test_that("get_order sends GET to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_query_order_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_order("BTCUSDT", orderId = 28)
  expect_true(grepl("sapi/v1/margin/order", captured_url))
})

# -- get_account --

test_that("get_account returns data.table with margin account info", {
  resp <- mock_binance_response(data = mock_margin_account_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_account()
  expect_s3_class(dt, "data.table")
  # user_assets expanded to long format: 2 assets in mock => 2 rows
  expect_equal(nrow(dt), 2L)
  expect_true("borrow_enabled" %in% names(dt))
  expect_true("margin_level" %in% names(dt))
  # user_assets is no longer a list-column; expanded with user_asset_ prefix
  expect_false("user_assets" %in% names(dt))
  expect_true("user_asset_asset" %in% names(dt))
  expect_true("user_asset_free" %in% names(dt))
  expect_true("user_asset_borrowed" %in% names(dt))
  expect_equal(dt$account_type, c("MARGIN", "MARGIN"))
  expect_true(all(dt$borrow_enabled))
})

test_that("get_account sends GET to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_account_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_account()
  expect_true(grepl("sapi/v1/margin/account", captured_url))
})

# -- get_max_borrowable --

test_that("get_max_borrowable returns data.table with amount and borrow_limit", {
  resp <- mock_binance_response(data = mock_max_borrowable_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_max_borrowable(asset = "USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("amount" %in% names(dt))
  expect_true("borrow_limit" %in% names(dt))
  expect_equal(dt$amount, "1.69248805")
})

test_that("get_max_borrowable passes asset parameter", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_max_borrowable_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_max_borrowable(asset = "BTC")
  expect_true(grepl("asset=BTC", captured_url))
  expect_true(grepl("sapi/v1/margin/maxBorrowable", captured_url))
})

# -- get_interest_history --

test_that("get_interest_history returns data.table from paginated response", {
  resp <- mock_binance_response(data = mock_margin_interest_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_interest_history(asset = "USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("asset" %in% names(dt))
  expect_true("interest" %in% names(dt))
  expect_true("interest_accured_time" %in% names(dt))
  expect_s3_class(dt$interest_accured_time, "POSIXct")
})

test_that("get_interest_history returns empty data.table for empty response", {
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_interest_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_interest_history sends GET to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_interest_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_interest_history(asset = "USDT")
  expect_true(grepl("sapi/v1/margin/interestHistory", captured_url))
})

# -- get_trades --

test_that("get_trades returns data.table with time as POSIXct", {
  resp <- mock_binance_response(data = mock_margin_trades_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_trades("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("symbol" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
  expect_equal(dt$symbol, "BTCUSDT")
})

test_that("get_trades returns empty data.table when no trades", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_trades("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_trades sends GET to correct endpoint with symbol", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_trades_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_trades("BTCUSDT")
  expect_true(grepl("sapi/v1/margin/myTrades", captured_url))
  expect_true(grepl("symbol=BTCUSDT", captured_url))
})

# -- get_isolated_account --

test_that("get_isolated_account returns data.table with assets expanded to long format", {
  resp <- mock_binance_response(data = mock_isolated_margin_account_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_isolated_account()
  expect_s3_class(dt, "data.table")
  # 1 asset in mock data => 1 row
  expect_equal(nrow(dt), 1L)
  expect_true("total_asset_of_btc" %in% names(dt))
  # No list-column 'assets' - it's been expanded
  expect_false("assets" %in% names(dt))
  # Expanded asset columns are present
  expect_true("symbol" %in% names(dt))
  expect_true("enabled" %in% names(dt))
  expect_true("trade_enabled" %in% names(dt))
  expect_equal(dt$symbol, "BTCUSDT")
})

test_that("get_isolated_account sends GET to correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_isolated_margin_account_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_isolated_account()
  expect_true(grepl("sapi/v1/margin/isolated/account", captured_url))
})

# -- add_isolated_transfer --

test_that("add_isolated_transfer returns data.table with tran_id", {
  resp <- mock_binance_response(data = mock_isolated_transfer_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$add_isolated_transfer(
    asset = "USDT",
    symbol = "BTCUSDT",
    transFrom = "SPOT",
    transTo = "ISOLATED_MARGIN",
    amount = 100
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("tran_id" %in% names(dt))
  expect_equal(dt$tran_id, 100000001L)
})

test_that("add_isolated_transfer validates transFrom and transTo", {
  expect_error(
    new_margin()$add_isolated_transfer(
      asset = "USDT",
      symbol = "BTCUSDT",
      transFrom = "INVALID",
      transTo = "SPOT",
      amount = 100
    ),
    "INVALID"
  )
  expect_error(
    new_margin()$add_isolated_transfer(
      asset = "USDT",
      symbol = "BTCUSDT",
      transFrom = "SPOT",
      transTo = "INVALID",
      amount = 100
    ),
    "INVALID"
  )
})

test_that("add_isolated_transfer sends POST to correct endpoint", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_isolated_transfer_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_margin()$add_isolated_transfer(
    asset = "USDT",
    symbol = "BTCUSDT",
    transFrom = "SPOT",
    transTo = "ISOLATED_MARGIN",
    amount = 100
  )
  expect_true(grepl("sapi/v1/margin/isolated/transfer", captured_url))
  expect_equal(captured_method, "POST")
})

# ---- Tests added to close 6 untested-method gaps in TRADE-20 ----

# -- add_repay --

test_that("add_repay returns data.table with tran_id (POST /sapi/v1/margin/borrow-repay)", {
  resp <- mock_binance_response(data = mock_margin_borrow_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$add_repay(asset = "USDT", amount = 100)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("tran_id" %in% names(dt))
  expect_equal(dt$tran_id, 100000001L)
})

test_that("add_repay sends POST with amount coerced to character", {
  captured <- NULL
  resp <- mock_binance_response(data = mock_margin_borrow_response())
  httr2::local_mocked_responses(function(req) {
    captured <<- req
    return(resp)
  })

  new_margin()$add_repay(asset = "USDT", amount = 0.5)
  expect_equal(captured$method, "POST")
  expect_true(grepl("/sapi/v1/margin/borrow-repay", captured$url))
})

# -- cancel_all_orders --

test_that("cancel_all_orders returns one row per cancelled order with transact_time as POSIXct", {
  # Wrap a single cancel-order record in a list — endpoint returns an array.
  resp <- mock_binance_response(data = list(mock_margin_cancel_order_data()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$cancel_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$status, "CANCELED")
  expect_s3_class(dt$transact_time, "POSIXct")
})

test_that("cancel_all_orders sends DELETE to /sapi/v1/margin/openOrders", {
  captured <- NULL
  resp <- mock_binance_response(data = list(mock_margin_cancel_order_data()))
  httr2::local_mocked_responses(function(req) {
    captured <<- req
    return(resp)
  })

  new_margin()$cancel_all_orders("BTCUSDT")
  expect_equal(captured$method, "DELETE")
  expect_true(grepl("/sapi/v1/margin/openOrders", captured$url))
})

test_that("cancel_all_orders returns empty data.table when there are no open margin orders", {
  # Per the cross-package "no stub rows" convention, the previously-
  # synthetic `(symbol, status = "cancelled")` row is replaced by an
  # empty data.table.
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$cancel_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_open_orders --

test_that("get_open_orders returns one row per open order", {
  resp <- mock_binance_response(data = list(mock_margin_query_order_data()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$status, "FILLED")
})

test_that("get_open_orders returns empty data.table when no open orders", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_open_orders hits /sapi/v1/margin/openOrders", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_open_orders("BTCUSDT")
  expect_true(grepl("/sapi/v1/margin/openOrders", captured_url))
})

# -- get_all_orders --

test_that("get_all_orders returns one row per order", {
  resp <- mock_binance_response(data = list(mock_margin_query_order_data()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
})

test_that("get_all_orders hits /sapi/v1/margin/allOrders", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_all_orders("BTCUSDT")
  expect_true(grepl("/sapi/v1/margin/allOrders", captured_url))
})

# -- get_max_transferable --

test_that("get_max_transferable returns single-row data.table with amount + borrow_limit", {
  resp <- mock_binance_response(data = mock_margin_max_transferable_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_max_transferable(asset = "USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$amount, "3.59498107")
  expect_equal(dt$borrow_limit, "10000")
})

test_that("get_max_transferable hits /sapi/v1/margin/maxTransferable with asset param", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_max_transferable_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_max_transferable(asset = "BTC")
  expect_true(grepl("/sapi/v1/margin/maxTransferable", captured_url))
  expect_true(grepl("asset=BTC", captured_url))
})

# -- get_force_liquidation_history --

test_that("get_force_liquidation_history returns one row per liquidation with time as POSIXct", {
  resp <- mock_binance_response(data = mock_margin_force_liquidation_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_force_liquidation_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$side, "SELL")
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_force_liquidation_history hits /sapi/v1/margin/forceLiquidationRec", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_force_liquidation_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_force_liquidation_history()
  expect_true(grepl("/sapi/v1/margin/forceLiquidationRec", captured_url))
})
