# tests/testthat/test-BinanceFutures.R
# Integration-style tests for BinanceFutures R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://fapi.binance.com"

new_futures <- function() {
  return(BinanceFutures$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("BinanceFutures inherits from BinanceBase", {
  f <- new_futures()
  expect_s3_class(f, "BinanceFutures")
  expect_s3_class(f, "BinanceBase")
  expect_false(f$is_async)
})

test_that("BinanceFutures async mode sets is_async = TRUE", {
  f <- BinanceFutures$new(keys = KEYS, base_url = BASE, async = TRUE)
  expect_true(f$is_async)
})

# -- add_order --

test_that("add_order returns data.table with order details", {
  resp <- mock_binance_response(data = mock_futures_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$add_order(
    symbol = "BTCUSDT",
    side = "BUY",
    type = "LIMIT",
    quantity = 0.001,
    price = 50000,
    timeInForce = "GTC"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$status, "NEW")
  expect_equal(dt$side, "BUY")
  expect_true("update_time" %in% names(dt))
  expect_s3_class(dt$update_time, "POSIXct")
})

test_that("add_order hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures()$add_order(symbol = "BTCUSDT", side = "BUY", type = "MARKET", quantity = 0.001)
  expect_true(grepl("/fapi/v1/order", captured_url))
  expect_false(grepl("/test", captured_url))
})

test_that("add_order rejects invalid side", {
  expect_error(new_futures()$add_order("BTCUSDT", side = "INVALID", type = "MARKET"), "side")
})

test_that("add_order rejects invalid type", {
  expect_error(new_futures()$add_order("BTCUSDT", side = "BUY", type = "INVALID"), "type")
})

# -- add_order_test --

test_that("add_order_test returns confirmation dt on success", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$add_order_test(
    symbol = "BTCUSDT",
    side = "BUY",
    type = "LIMIT",
    quantity = 0.001,
    price = 50000,
    timeInForce = "GTC"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$side, "BUY")
  expect_equal(dt$type, "LIMIT")
  expect_equal(dt$status, "validated")
})

test_that("add_order_test hits /fapi/v1/order/test", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures()$add_order_test(symbol = "BTCUSDT", side = "SELL", type = "MARKET", quantity = 0.001)
  expect_true(grepl("/fapi/v1/order/test", captured_url))
})

# -- cancel_order --

test_that("cancel_order returns data.table", {
  resp <- mock_binance_response(data = mock_futures_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$cancel_order("BTCUSDT", orderId = 283194212)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

test_that("cancel_order requires orderId or origClientOrderId", {
  expect_error(new_futures()$cancel_order("BTCUSDT"), "orderId.*origClientOrderId")
})

# -- cancel_all_orders --

test_that("cancel_all_orders returns data.table", {
  resp <- mock_binance_response(data = mock_futures_cancel_all_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$cancel_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$code, 200L)
})

test_that("cancel_all_orders hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_cancel_all_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures()$cancel_all_orders("BTCUSDT")
  expect_true(grepl("/fapi/v1/allOpenOrders", captured_url))
})

# -- get_order --

test_that("get_order returns data.table with datetime columns", {
  data <- mock_futures_order_response()
  data$time <- 1661493146000
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_order("BTCUSDT", orderId = 283194212)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_s3_class(dt$update_time, "POSIXct")
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_order requires orderId or origClientOrderId", {
  expect_error(new_futures()$get_order("BTCUSDT"), "orderId.*origClientOrderId")
})

# -- get_open_orders --

test_that("get_open_orders returns data.table", {
  data <- list(mock_futures_order_response())
  data[[1]]$time <- 1661493146000
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

test_that("get_open_orders returns empty data.table when none", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_all_orders --

test_that("get_all_orders returns data.table", {
  data <- list(mock_futures_order_response())
  data[[1]]$time <- 1661493146000
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_all_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

# -- get_account --

test_that("get_account returns data.table with assets expanded to long format", {
  resp <- mock_binance_response(data = mock_futures_account_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_account()
  expect_s3_class(dt, "data.table")
  # 1 asset in mock data => 1 row
  expect_equal(nrow(dt), 1L)
  expect_true("can_trade" %in% names(dt))
  expect_true("total_wallet_balance" %in% names(dt))
  # No list-column 'assets' - expanded with prefix
  expect_false("assets" %in% names(dt))
  # `positions` is intentionally dropped — see get_account @return note.
  expect_false("positions" %in% names(dt))
  expect_false(any(grepl("^position_", names(dt))))
  # Asset columns present with prefix
  expect_true("asset_asset" %in% names(dt))
  expect_true("asset_wallet_balance" %in% names(dt))
  expect_equal(dt$asset_asset, "USDT")
  expect_equal(dt$asset_wallet_balance, "1000.00000000")
})

test_that("get_account preserves all assets when account has multiple assets + positions", {
  # Regression: a prior bug `dt[rep(1L, nrow(positions_dt))]` was
  # collapsing the assets dt back to one row before cross-joining with
  # positions, so 2 assets + 3 positions returned 3 rows ALL for asset 1.
  # Fix: positions are dropped from this method (use get_positions()
  # for those). Verify that 2 assets returns 2 rows with both assets
  # preserved.
  data <- mock_futures_account_data()
  data$assets <- list(
    list(
      asset = "USDT",
      walletBalance = "1000.00",
      unrealizedProfit = "0",
      marginBalance = "1000.00",
      maintMargin = "0",
      initialMargin = "0",
      positionInitialMargin = "0",
      openOrderInitialMargin = "0",
      crossWalletBalance = "1000.00",
      crossUnPnl = "0",
      availableBalance = "1000.00",
      maxWithdrawAmount = "1000.00",
      marginAvailable = TRUE,
      updateTime = 0L
    ),
    list(
      asset = "BNB",
      walletBalance = "10.00",
      unrealizedProfit = "0",
      marginBalance = "10.00",
      maintMargin = "0",
      initialMargin = "0",
      positionInitialMargin = "0",
      openOrderInitialMargin = "0",
      crossWalletBalance = "10.00",
      crossUnPnl = "0",
      availableBalance = "10.00",
      maxWithdrawAmount = "10.00",
      marginAvailable = TRUE,
      updateTime = 0L
    )
  )
  # Three open positions on different symbols — should NOT contaminate
  # the asset rows.
  data$positions <- list(
    list(symbol = "BTCUSDT", positionAmt = "0.1"),
    list(symbol = "ETHUSDT", positionAmt = "1.0"),
    list(symbol = "BNBUSDT", positionAmt = "5.0")
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_account()
  expect_equal(nrow(dt), 2L)
  expect_setequal(dt$asset_asset, c("USDT", "BNB"))
  # No position_* columns leak through.
  expect_false(any(grepl("^position_", names(dt))))
  # Account-level fields replicated on both rows.
  expect_equal(unique(dt$total_wallet_balance), "1000.00000000")
  # No list columns anywhere.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

# -- get_balances --

test_that("get_balances returns data.table with update_time", {
  resp <- mock_binance_response(data = mock_futures_balances_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_balances()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("asset" %in% names(dt))
  expect_true("balance" %in% names(dt))
  expect_true("update_time" %in% names(dt))
  expect_s3_class(dt$update_time, "POSIXct")
})

# -- get_positions --

test_that("get_positions returns data.table with update_time", {
  resp <- mock_binance_response(data = mock_futures_positions_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_positions("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("position_amt" %in% names(dt))
  expect_true("leverage" %in% names(dt))
  expect_true("update_time" %in% names(dt))
  expect_s3_class(dt$update_time, "POSIXct")
})

# -- set_leverage --

test_that("set_leverage returns data.table", {
  resp <- mock_binance_response(data = mock_futures_leverage_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$set_leverage("BTCUSDT", 20)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$leverage, 20L)
  expect_equal(dt$symbol, "BTCUSDT")
})

# -- set_margin_type --

test_that("set_margin_type returns data.table", {
  resp <- mock_binance_response(data = mock_futures_margin_type_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$set_margin_type("BTCUSDT", "ISOLATED")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$code, 200L)
})

test_that("set_margin_type rejects invalid margin type", {
  expect_error(new_futures()$set_margin_type("BTCUSDT", "INVALID"), "marginType")
})

# -- get_trades --

test_that("get_trades returns data.table with time", {
  resp <- mock_binance_response(data = mock_futures_trades_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_trades("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
})

# -- get_income_history --

test_that("get_income_history returns data.table with time", {
  resp <- mock_binance_response(data = mock_futures_income_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_income_history(symbol = "BTCUSDT", incomeType = "FUNDING_FEE")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("income_type" %in% names(dt))
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_income_history rejects invalid incomeType", {
  expect_error(new_futures()$get_income_history(incomeType = "INVALID"), "incomeType")
})

# -- set_position_mode --

test_that("set_position_mode returns data.table", {
  resp <- mock_binance_response(data = mock_futures_margin_type_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$set_position_mode(TRUE)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

# -- get_position_mode --

test_that("get_position_mode returns data.table", {
  resp <- mock_binance_response(data = mock_futures_position_mode_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures()$get_position_mode()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("dual_side_position" %in% names(dt))
})

# -- Error handling --

test_that("Binance API error is raised correctly for futures trading", {
  resp <- mock_binance_error(code = -1013, msg = "Filter failure: LOT_SIZE")
  httr2::local_mocked_responses(function(req) resp)

  expect_error(
    new_futures()$get_account(),
    "Binance API error -1013"
  )
})
