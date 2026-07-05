test_that("validate_order_params validates limit orders", {
  params <- binance:::validate_order_params(
    type = "LIMIT",
    symbol = "BTCUSDT",
    side = "BUY",
    price = 50000,
    quantity = 0.001
  )
  expect_equal(params$type, "LIMIT")
  expect_equal(params$symbol, "BTCUSDT")
  expect_equal(params$side, "BUY")
  expect_equal(params$price, "50000")
  expect_equal(params$quantity, "0.001")
  expect_equal(params$timeInForce, "GTC")
})

test_that("validate_order_params validates market orders with quantity", {
  params <- binance:::validate_order_params(
    type = "MARKET",
    symbol = "BTCUSDT",
    side = "SELL",
    quantity = 0.001
  )
  expect_equal(params$type, "MARKET")
  expect_equal(params$side, "SELL")
  expect_null(params$price)
})

test_that("validate_order_params validates market orders with quote_order_qty", {
  params <- binance:::validate_order_params(
    type = "MARKET",
    symbol = "BTCUSDT",
    side = "BUY",
    quote_order_qty = 100
  )
  expect_equal(params$quoteOrderQty, "100")
  expect_null(params$quantity)
})

test_that("validate_order_params rejects limit order without price", {
  expect_error(
    binance:::validate_order_params(
      type = "LIMIT",
      symbol = "BTCUSDT",
      side = "BUY",
      quantity = 0.001
    ),
    "price.*required"
  )
})

test_that("validate_order_params rejects market order with price", {
  expect_error(
    binance:::validate_order_params(
      type = "MARKET",
      symbol = "BTCUSDT",
      side = "BUY",
      price = 50000,
      quantity = 0.001
    ),
    "price.*not applicable"
  )
})

test_that("validate_order_params rejects market order without quantity or quoteOrderQty", {
  expect_error(
    binance:::validate_order_params(
      type = "MARKET",
      symbol = "BTCUSDT",
      side = "BUY"
    ),
    "quantity.*quote_order_qty"
  )
})

test_that("validate_order_params rejects invalid symbol", {
  expect_error(
    binance:::validate_order_params(
      type = "LIMIT",
      symbol = "BTC-USDT",
      side = "BUY",
      price = 50000,
      quantity = 0.001
    ),
    "symbol"
  )
})

test_that("validate_order_params rejects excessive recvWindow", {
  expect_error(
    binance:::validate_order_params(
      type = "LIMIT",
      symbol = "BTCUSDT",
      side = "BUY",
      price = 50000,
      quantity = 0.001,
      recv_window = 70000
    ),
    "recv_window"
  )
})
