# End-to-end tests: drive the public R6 client methods through the shared
# connectcore mock_router (the same `.mock_routes` + synthetic JSON fixtures the
# README and vignettes render against). The per-class tests mock single responses
# with httr2::local_mocked_responses to exercise parsers in isolation; these cover
# the wiring around them — endpoint strings, query/host/method selection, and the
# route table — which otherwise only runs during a docs render.

box::use(./mock_router[.mock_routes])

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"
FBASE <- "https://fapi.binance.com"

test_that("BinanceMarketData public methods round-trip through the router", {
  connectcore::local_mock_api(.mock_routes)
  market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)

  expect_equal(nrow(market$get_server_time()), 1L)
  expect_equal(nrow(market$get_exchange_info()), 2L)
  expect_equal(nrow(market$get_ticker("BTCUSDT")), 1L)
  expect_equal(nrow(market$get_24hr_stats("BTCUSDT")), 1L)
  expect_true(data.table::is.data.table(market$get_book_ticker("BTCUSDT")))
  expect_true(data.table::is.data.table(market$get_avg_price("BTCUSDT")))
  expect_true(data.table::is.data.table(market$get_depth("BTCUSDT")))
  expect_true(data.table::is.data.table(market$get_trades("BTCUSDT")))
  expect_equal(nrow(market$get_klines("BTCUSDT", "1d")), 3L)
})

test_that("BinanceAccount public methods round-trip through the router", {
  connectcore::local_mock_api(.mock_routes)
  account <- BinanceAccount$new(keys = KEYS, base_url = BASE)

  expect_equal(nrow(account$get_account_info()), 1L)
  expect_true(data.table::is.data.table(account$get_balances()))
  expect_true(data.table::is.data.table(account$get_trades("BTCUSDT")))
})

test_that("BinanceFuturesData public methods round-trip through the router", {
  connectcore::local_mock_api(.mock_routes)
  fdata <- BinanceFuturesData$new(keys = KEYS, base_url = FBASE)

  expect_equal(nrow(fdata$get_exchange_info()), 1L)
  expect_equal(nrow(fdata$get_mark_price("BTCUSDT")), 1L)
  expect_true(data.table::is.data.table(fdata$get_funding_rate("BTCUSDT")))
  expect_equal(nrow(fdata$get_open_interest("BTCUSDT")), 1L)
  expect_equal(nrow(fdata$get_klines("BTCUSDT", "1d")), 3L)
})

test_that("the route table also resolves through with_mock_api (block scope)", {
  out <- connectcore::with_mock_api(.mock_routes, {
    market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)
    market$get_ticker("BTCUSDT")
  })
  expect_equal(nrow(out), 1L)
})
