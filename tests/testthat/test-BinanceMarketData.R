# tests/testthat/test-BinanceMarketData.R
# Integration-style tests for BinanceMarketData R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_market <- function() {
  BinanceMarketData$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceMarketData inherits from BinanceBase", {
  market <- new_market()
  expect_s3_class(market, "BinanceMarketData")
  expect_s3_class(market, "BinanceBase")
  expect_false(market$is_async)
})

test_that("BinanceMarketData async mode sets is_async = TRUE", {
  market <- BinanceMarketData$new(keys = KEYS, base_url = BASE, async = TRUE)
  expect_true(market$is_async)
})

# -- get_server_time --

test_that("get_server_time returns data.table with datetime", {
  resp <- mock_binance_response(data = mock_server_time_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_server_time()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("server_time" %in% names(dt))
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
  expect_equal(dt$server_time, 1499827319559)
})

# -- get_exchange_info --

test_that("get_exchange_info returns data.table with symbol metadata", {
  resp <- mock_binance_response(data = mock_exchange_info_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_exchange_info()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_true("base_asset" %in% names(dt))
  expect_true("quote_asset" %in% names(dt))
  expect_equal(sort(dt$symbol), c("BTCUSDT", "ETHUSDT"))
  expect_equal(dt[symbol == "BTCUSDT"]$base_asset, "BTC")
})

test_that("get_exchange_info filters by symbol", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_exchange_info_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_market()$get_exchange_info(symbol = "BTCUSDT")
  expect_true(grepl("symbol=BTCUSDT", captured_url))
})

# -- get_ticker --

test_that("get_ticker returns data.table with symbol and price", {
  resp <- mock_binance_response(data = mock_ticker_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$price, "67232.90000000")
})

# -- get_all_tickers --

test_that("get_all_tickers returns multi-row data.table", {
  resp <- mock_binance_response(data = mock_all_tickers_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_all_tickers()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_equal(sort(dt$symbol), c("BTCUSDT", "ETHUSDT"))
})

# -- get_book_ticker --

test_that("get_book_ticker returns bid/ask data", {
  resp <- mock_binance_response(data = mock_book_ticker_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_book_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("bid_price" %in% names(dt))
  expect_true("ask_price" %in% names(dt))
  expect_true("bid_qty" %in% names(dt))
  expect_true("ask_qty" %in% names(dt))
})

# -- get_24hr_stats --

test_that("get_24hr_stats returns stats with datetime columns", {
  resp <- mock_binance_response(data = mock_24hr_stats_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_24hr_stats("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("last_price" %in% names(dt))
  expect_true("volume" %in% names(dt))
  expect_true("datetime_open" %in% names(dt))
  expect_true("datetime_close" %in% names(dt))
  expect_s3_class(dt$datetime_open, "POSIXct")
  expect_s3_class(dt$datetime_close, "POSIXct")

  # Raw time columns should be removed
  expect_false("open_time" %in% names(dt))
  expect_false("close_time" %in% names(dt))
})

# -- get_avg_price --

test_that("get_avg_price returns price with datetime", {
  resp <- mock_binance_response(data = mock_avg_price_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_avg_price("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$mins, 5L)
  expect_true("price" %in% names(dt))
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")

  # Raw close_time should be removed
  expect_false("close_time" %in% names(dt))
})

# -- get_depth --

test_that("get_depth returns orderbook with bids and asks", {
  resp <- mock_binance_response(data = mock_orderbook_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_depth("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 6L)
  expect_true("side" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("quantity" %in% names(dt))
  expect_equal(sum(dt$side == "bid"), 3L)
  expect_equal(sum(dt$side == "ask"), 3L)
})

# -- get_trades --

test_that("get_trades returns data.table with datetime", {
  resp <- mock_binance_response(data = mock_trades_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_trades("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("id" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("qty" %in% names(dt))
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")

  # Raw time column should be removed
  expect_false("time" %in% names(dt))
})

# -- get_klines --

test_that("get_klines returns OHLCV data.table", {
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_klines("BTCUSDT", "1h")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("datetime" %in% names(dt))
  expect_true("open" %in% names(dt))
  expect_true("high" %in% names(dt))
  expect_true("low" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_true("volume" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
  expect_type(dt$open, "double")
  expect_type(dt$volume, "double")
})

test_that("get_klines rejects invalid interval", {
  expect_error(
    new_market()$get_klines("BTCUSDT", "2m"),
    "interval"
  )
})

test_that("get_klines passes limit parameter", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_market()$get_klines("BTCUSDT", "1h", limit = 100)
  expect_true(grepl("limit=100", captured_url))
})

# -- Error handling --

test_that("Binance API error is raised correctly", {
  resp <- mock_binance_error(code = -1013, msg = "Filter failure: LOT_SIZE")
  httr2::local_mocked_responses(function(req) resp)

  expect_error(
    new_market()$get_ticker("BTCUSDT"),
    "Binance API error -1013"
  )
})

test_that("HTTP error is raised correctly", {
  resp <- mock_http_error(status_code = 500L, body_text = "Internal Server Error")
  httr2::local_mocked_responses(function(req) resp)

  expect_error(
    new_market()$get_ticker("BTCUSDT"),
    "500"
  )
})
