# tests/testthat/test-BinanceFuturesData.R
# Integration-style tests for BinanceFuturesData R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://fapi.binance.com"

new_futures_data <- function() {
  BinanceFuturesData$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceFuturesData inherits from BinanceBase", {
  fd <- new_futures_data()
  expect_s3_class(fd, "BinanceFuturesData")
  expect_s3_class(fd, "BinanceBase")
  expect_false(fd$is_async)
})

test_that("BinanceFuturesData async mode sets is_async = TRUE", {
  fd <- BinanceFuturesData$new(keys = KEYS, base_url = BASE, async = TRUE)
  expect_true(fd$is_async)
})

# -- get_exchange_info --

test_that("get_exchange_info returns data.table with futures symbol metadata", {
  resp <- mock_binance_response(data = mock_futures_exchange_info_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_exchange_info()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("symbol" %in% names(dt))
  expect_true("pair" %in% names(dt))
  expect_true("contract_type" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_true("base_asset" %in% names(dt))
  expect_true("quote_asset" %in% names(dt))
  expect_true("margin_asset" %in% names(dt))
  expect_true("order_types" %in% names(dt))
  expect_true("filters" %in% names(dt))
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$contract_type, "PERPETUAL")
  expect_equal(dt$base_asset, "BTC")
})

test_that("get_exchange_info hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_exchange_info_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_exchange_info()
  expect_true(grepl("/fapi/v1/exchangeInfo", captured_url))
})

# -- get_klines --

test_that("get_klines returns OHLCV data.table", {
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_klines("BTCUSDT", "1h")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("open_time" %in% names(dt))
  expect_true("open" %in% names(dt))
  expect_true("high" %in% names(dt))
  expect_true("low" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_true("volume" %in% names(dt))
  expect_true("close_time" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
  expect_s3_class(dt$close_time, "POSIXct")
  expect_type(dt$open, "double")
  expect_type(dt$volume, "double")
})

test_that("get_klines rejects invalid interval", {
  expect_error(
    new_futures_data()$get_klines("BTCUSDT", "2m"),
    "interval"
  )
})

test_that("get_klines passes limit and hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_klines("BTCUSDT", "1h", limit = 100)
  expect_true(grepl("/fapi/v1/klines", captured_url))
  expect_true(grepl("limit=100", captured_url))
})

# -- get_mark_price --

test_that("get_mark_price returns data.table with datetime columns", {
  resp <- mock_binance_response(data = mock_futures_mark_price_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_mark_price("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("mark_price" %in% names(dt))
  expect_true("index_price" %in% names(dt))
  expect_true("last_funding_rate" %in% names(dt))
  expect_true("next_funding_time" %in% names(dt))
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$next_funding_time, "POSIXct")
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_mark_price hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_mark_price_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_mark_price("BTCUSDT")
  expect_true(grepl("/fapi/v1/premiumIndex", captured_url))
  expect_true(grepl("symbol=BTCUSDT", captured_url))
})

# -- get_funding_rate --

test_that("get_funding_rate returns data.table with datetime", {
  resp <- mock_binance_response(data = mock_futures_funding_rate_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_funding_rate("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("funding_rate" %in% names(dt))
  expect_true("funding_time" %in% names(dt))
  expect_true("mark_price" %in% names(dt))
  expect_s3_class(dt$funding_time, "POSIXct")
})

test_that("get_funding_rate hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_funding_rate_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_funding_rate("BTCUSDT")
  expect_true(grepl("/fapi/v1/fundingRate", captured_url))
})

# -- get_24hr_stats --

test_that("get_24hr_stats returns stats with datetime columns", {
  resp <- mock_binance_response(data = mock_24hr_stats_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_24hr_stats("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("last_price" %in% names(dt))
  expect_true("volume" %in% names(dt))
  expect_true("open_time" %in% names(dt))
  expect_true("close_time" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
  expect_s3_class(dt$close_time, "POSIXct")
})

test_that("get_24hr_stats hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_24hr_stats_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_24hr_stats("BTCUSDT")
  expect_true(grepl("/fapi/v1/ticker/24hr", captured_url))
})

# -- get_ticker --

test_that("get_ticker returns data.table with symbol, price, and time", {
  resp <- mock_binance_response(data = mock_futures_ticker_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$price, "67232.90000000")
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_ticker hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_ticker_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_ticker("BTCUSDT")
  expect_true(grepl("/fapi/v1/ticker/price", captured_url))
})

# -- get_book_ticker --

test_that("get_book_ticker returns bid/ask data", {
  resp <- mock_binance_response(data = mock_book_ticker_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_book_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("bid_price" %in% names(dt))
  expect_true("ask_price" %in% names(dt))
  expect_true("bid_qty" %in% names(dt))
  expect_true("ask_qty" %in% names(dt))
})

test_that("get_book_ticker hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_book_ticker_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_book_ticker("BTCUSDT")
  expect_true(grepl("/fapi/v1/ticker/bookTicker", captured_url))
})

# -- get_open_interest --

test_that("get_open_interest returns data.table with time", {
  resp <- mock_binance_response(data = mock_futures_open_interest_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_open_interest("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("open_interest" %in% names(dt))
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_open_interest hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_open_interest_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_open_interest("BTCUSDT")
  expect_true(grepl("/fapi/v1/openInterest", captured_url))
})

# -- get_depth --

test_that("get_depth returns orderbook with bids and asks", {
  resp <- mock_binance_response(data = mock_orderbook_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_depth("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 6L)
  expect_true("side" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("quantity" %in% names(dt))
  expect_equal(sum(dt$side == "bid"), 3L)
  expect_equal(sum(dt$side == "ask"), 3L)
})

test_that("get_depth hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_orderbook_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_depth("BTCUSDT", limit = 20)
  expect_true(grepl("/fapi/v1/depth", captured_url))
  expect_true(grepl("limit=20", captured_url))
})

# -- get_trades --

test_that("get_trades returns data.table with datetime", {
  resp <- mock_binance_response(data = mock_trades_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_trades("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("id" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("qty" %in% names(dt))
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_trades hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_trades_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_trades("BTCUSDT", limit = 10)
  expect_true(grepl("/fapi/v1/trades", captured_url))
  expect_true(grepl("limit=10", captured_url))
})

# -- get_index_price_klines --

test_that("get_index_price_klines returns OHLCV data.table", {
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_index_price_klines("BTCUSDT", "1h")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("open_time" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
})

test_that("get_index_price_klines hits correct endpoint with pair param", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_index_price_klines("BTCUSDT", "1h", limit = 50)
  expect_true(grepl("/fapi/v1/indexPriceKlines", captured_url))
  expect_true(grepl("pair=BTCUSDT", captured_url))
  expect_true(grepl("limit=50", captured_url))
})

# -- get_mark_price_klines --

test_that("get_mark_price_klines returns OHLCV data.table", {
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_mark_price_klines("BTCUSDT", "1h")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("open_time" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
})

test_that("get_mark_price_klines hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_futures_data()$get_mark_price_klines("BTCUSDT", "4h")
  expect_true(grepl("/fapi/v1/markPriceKlines", captured_url))
  expect_true(grepl("symbol=BTCUSDT", captured_url))
})

# -- Error handling --

test_that("Binance API error is raised correctly for futures", {
  resp <- mock_binance_error(code = -1121, msg = "Invalid symbol.")
  httr2::local_mocked_responses(function(req) resp)

  expect_error(
    new_futures_data()$get_ticker("INVALID"),
    "Binance API error -1121"
  )
})

test_that("HTTP error is raised correctly for futures", {
  resp <- mock_http_error(status_code = 500L, body_text = "Internal Server Error")
  httr2::local_mocked_responses(function(req) resp)

  expect_error(
    new_futures_data()$get_ticker("BTCUSDT"),
    "500"
  )
})
