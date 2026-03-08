test_that("to_snake_case converts camelCase correctly", {
  expect_equal(binance:::to_snake_case("camelCase"), "camel_case")
  expect_equal(binance:::to_snake_case("priceChange"), "price_change")
  expect_equal(binance:::to_snake_case("isBuyerMaker"), "is_buyer_maker")
  expect_equal(binance:::to_snake_case("quoteOrderQty"), "quote_order_qty")
})

test_that("as_dt_row handles empty input", {
  expect_equal(nrow(binance:::as_dt_row(NULL)), 0)
  expect_equal(nrow(binance:::as_dt_row(list())), 0)
})

test_that("as_dt_row converts named list to data.table", {
  result <- binance:::as_dt_row(list(symbol = "BTCUSDT", price = "67000"))
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1)
  expect_equal(result$symbol, "BTCUSDT")
  expect_equal(result$price, "67000")
})

test_that("as_dt_list converts list of lists to data.table", {
  items <- list(
    list(symbol = "BTCUSDT", price = "67000"),
    list(symbol = "ETHUSDT", price = "3500")
  )
  result <- binance:::as_dt_list(items)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_equal(result$symbol, c("BTCUSDT", "ETHUSDT"))
})

test_that("ms_to_datetime converts milliseconds to POSIXct", {
  result <- binance:::ms_to_datetime(1499827319559)
  expect_s3_class(result, "POSIXct")
})

test_that("ms_to_datetime handles NULL and NA", {
  expect_true(is.na(binance:::ms_to_datetime(NULL)))
  expect_true(is.na(binance:::ms_to_datetime(NA)))
})

test_that("parse_klines returns proper OHLCV data.table", {
  kline_data <- list(
    list(
      1499040000000,
      "0.01634790",
      "0.80000000",
      "0.01575800",
      "0.01577100",
      "148976.11427815",
      1499644799999,
      "2434.19055334",
      308L,
      "1756.87402397",
      "28.46694368",
      "0"
    )
  )
  result <- binance:::parse_klines(kline_data)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1)
  expect_true("datetime_open" %in% names(result))
  expect_true("open" %in% names(result))
  expect_true("high" %in% names(result))
  expect_true("low" %in% names(result))
  expect_true("close" %in% names(result))
  expect_true("volume" %in% names(result))
})

test_that("parse_orderbook returns proper data.table", {
  ob_data <- list(
    lastUpdateId = 1027024,
    bids = list(list("4.00000000", "431.00000000")),
    asks = list(list("4.00000200", "12.00000000"))
  )
  result <- binance:::parse_orderbook(ob_data)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_true("side" %in% names(result))
  expect_true("price" %in% names(result))
  expect_true("quantity" %in% names(result))
  expect_equal(result$side, c("bid", "ask"))
})
