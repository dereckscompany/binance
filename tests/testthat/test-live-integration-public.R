# tests/testthat/test-live-integration-public.R
# Live integration tests for public (no auth) endpoints.
# These hit the real Binance API — no mocking.
#
# Run with:
#   BINANCE_LIVE_TESTS=true Rscript -e 'devtools::test(filter = "live")'

skip_if_not(
  identical(Sys.getenv("BINANCE_LIVE_TESTS"), "true"),
  "Live API tests skipped (set BINANCE_LIVE_TESTS=true to run)"
)

# Rate limit helper — be polite to Binance
throttle <- function() Sys.sleep(0.3)

# All public endpoints use no auth; construct once
market <- BinanceMarketData$new()
futures_data <- BinanceFuturesData$new()

# =============================================================================
# BinanceMarketData — Spot Public Endpoints
# =============================================================================

test_that("[LIVE] get_server_time returns data.table with valid datetime", {
  dt <- market$get_server_time()
  expect_s3_class(dt, "data.table")
  expect_true("server_time" %in% names(dt))
  expect_s3_class(dt$server_time, "POSIXct")
  # Server time should be within 60 seconds of our local time
  diff_secs <- abs(as.numeric(difftime(dt$server_time, Sys.time(), units = "secs")))
  expect_true(diff_secs < 60, info = paste("Clock drift:", diff_secs, "seconds"))
  throttle()
})

test_that("[LIVE] get_exchange_info returns data.table with many symbols", {
  dt <- market$get_exchange_info()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 100, info = "Expected 100+ trading pairs")
  expect_true("symbol" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_true("base_asset" %in% names(dt))
  expect_true("BTCUSDT" %in% dt$symbol)
  expect_true("ETHUSDT" %in% dt$symbol)
  throttle()
})

test_that("[LIVE] get_ticker returns data.table for BTCUSDT", {
  dt <- market$get_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("price" %in% names(dt))
  # BTC price should be a reasonable number (> $1000)
  expect_true(as.numeric(dt$price) > 1000)
  throttle()
})

test_that("[LIVE] get_all_tickers returns data.table with many tickers", {
  dt <- market$get_all_tickers()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 100, info = "Expected 100+ tickers")
  expect_true("symbol" %in% names(dt))
  expect_true("BTCUSDT" %in% dt$symbol)
  throttle()
})

test_that("[LIVE] get_book_ticker returns data.table for BTCUSDT", {
  dt <- market$get_book_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true(all(c("bid_price", "ask_price", "bid_qty", "ask_qty") %in% names(dt)))
  throttle()
})

test_that("[LIVE] get_24hr_stats returns data.table for BTCUSDT", {
  dt <- market$get_24hr_stats("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true(all(c("high_price", "low_price", "volume") %in% names(dt)))
  expect_true("open_time" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
  throttle()
})

test_that("[LIVE] get_avg_price returns data.table for BTCUSDT", {
  dt <- market$get_avg_price("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("price" %in% names(dt))
  expect_true(as.numeric(dt$price) > 1000)
  throttle()
})

test_that("[LIVE] get_orderbook returns data.table with bids and asks", {
  dt <- market$get_orderbook("BTCUSDT", limit = 20)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("side", "price", "size") %in% names(dt)))
  expect_true(all(dt$side %in% c("bid", "ask")))
  expect_true(sum(dt$side == "bid") > 0)
  expect_true(sum(dt$side == "ask") > 0)
  throttle()
})

test_that("[LIVE] get_trades returns data.table for BTCUSDT", {
  dt <- market$get_trades("BTCUSDT", limit = 10)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("id", "price", "qty", "time") %in% names(dt)))
  expect_s3_class(dt$time, "POSIXct")
  throttle()
})

test_that("[LIVE] get_klines returns data.table with OHLCV data", {
  dt <- market$get_klines(symbol = "BTCUSDT", interval = "1h", limit = 24)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("open_time", "open", "high", "low", "close", "volume") %in% names(dt)))
  expect_s3_class(dt$open_time, "POSIXct")
  expect_type(dt$open, "double")
  expect_type(dt$close, "double")
  throttle()
})

# =============================================================================
# BinanceFuturesData — Futures Public Endpoints
# =============================================================================

test_that("[LIVE] futures get_exchange_info returns data.table", {
  dt <- futures_data$get_exchange_info()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 50, info = "Expected 50+ futures pairs")
  expect_true("symbol" %in% names(dt))
  expect_true("contract_type" %in% names(dt))
  expect_true("BTCUSDT" %in% dt$symbol)
  throttle()
})

test_that("[LIVE] futures get_klines returns OHLCV data", {
  dt <- futures_data$get_klines("BTCUSDT", "1h", limit = 24)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("open_time", "open", "high", "low", "close", "volume") %in% names(dt)))
  expect_s3_class(dt$open_time, "POSIXct")
  throttle()
})

test_that("[LIVE] futures get_mark_price returns data.table for BTCUSDT", {
  dt <- futures_data$get_mark_price("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("mark_price" %in% names(dt))
  expect_true("next_funding_time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
  throttle()
})

test_that("[LIVE] futures get_funding_rate returns data.table", {
  dt <- futures_data$get_funding_rate("BTCUSDT", limit = 10)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true("funding_rate" %in% names(dt))
  expect_true("funding_time" %in% names(dt))
  expect_s3_class(dt$funding_time, "POSIXct")
  throttle()
})

test_that("[LIVE] futures get_24hr_stats returns stats for BTCUSDT", {
  dt <- futures_data$get_24hr_stats("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("volume" %in% names(dt))
  throttle()
})

test_that("[LIVE] futures get_ticker returns data.table", {
  dt <- futures_data$get_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTCUSDT")
  expect_true("price" %in% names(dt))
  expect_true(as.numeric(dt$price) > 1000)
  throttle()
})

test_that("[LIVE] futures get_book_ticker returns bid/ask data", {
  dt <- futures_data$get_book_ticker("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("bid_price", "ask_price") %in% names(dt)))
  throttle()
})

test_that("[LIVE] futures get_open_interest returns data.table", {
  dt <- futures_data$get_open_interest("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("open_interest" %in% names(dt))
  throttle()
})

test_that("[LIVE] futures get_depth returns orderbook", {
  dt <- futures_data$get_depth("BTCUSDT", limit = 20)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("side", "price", "size") %in% names(dt)))
  expect_true(all(dt$side %in% c("bid", "ask")))
  throttle()
})

test_that("[LIVE] futures get_trades returns recent trades", {
  dt <- futures_data$get_trades("BTCUSDT", limit = 10)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
  throttle()
})
