# tests/testthat/test-BinanceMarginData.R
# Integration-style tests for BinanceMarginData R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_margin <- function() {
  return(BinanceMarginData$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("BinanceMarginData inherits from BinanceBase", {
  margin <- new_margin()
  expect_s3_class(margin, "BinanceMarginData")
  expect_s3_class(margin, "BinanceBase")
  expect_false(margin$is_async)
})

test_that("BinanceMarginData async mode sets is_async = TRUE", {
  margin <- BinanceMarginData$new(keys = KEYS, base_url = BASE, async = TRUE)
  expect_true(margin$is_async)
})

# -- get_all_pairs --

test_that("get_all_pairs returns data.table with correct columns", {
  resp <- mock_binance_response(data = mock_margin_all_pairs_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_all_pairs()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("base" %in% names(dt))
  expect_true("id" %in% names(dt))
  expect_true("is_buy_allowed" %in% names(dt))
  expect_true("is_margin_trade" %in% names(dt))
  expect_true("is_sell_allowed" %in% names(dt))
  expect_true("quote" %in% names(dt))
  expect_true("symbol" %in% names(dt))
  expect_equal(sort(dt$symbol), c("BTCUSDT", "ETHUSDT"))
})

test_that("get_all_pairs hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_all_pairs_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_all_pairs()
  expect_true(grepl("sapi/v1/margin/allPairs", captured_url))
})

test_that("get_all_pairs returns empty data.table on empty response", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_all_pairs()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_all_pairs passes recvWindow parameter", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_all_pairs_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_all_pairs(recvWindow = 5000)
  expect_true(grepl("recvWindow=5000", captured_url))
})

# -- get_isolated_pairs --

test_that("get_isolated_pairs returns data.table with correct columns", {
  resp <- mock_binance_response(data = mock_margin_isolated_pairs_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_isolated_pairs()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("base" %in% names(dt))
  expect_true("quote" %in% names(dt))
  expect_true("is_margin_trade" %in% names(dt))
  expect_true("is_buy_allowed" %in% names(dt))
  expect_true("is_sell_allowed" %in% names(dt))
  expect_equal(sort(dt$symbol), c("BTCUSDT", "ETHUSDT"))
})

test_that("get_isolated_pairs hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_isolated_pairs_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_isolated_pairs()
  expect_true(grepl("sapi/v1/margin/isolated/allPairs", captured_url))
})

test_that("get_isolated_pairs returns empty data.table on empty response", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_isolated_pairs()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_price_index --

test_that("get_price_index returns data.table with datetime", {
  resp <- mock_binance_response(data = mock_margin_price_index_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_price_index("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("calc_time" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("symbol" %in% names(dt))
  expect_s3_class(dt$calc_time, "POSIXct")
  expect_equal(dt$symbol, "BTCUSDT")
})

test_that("get_price_index hits correct endpoint with symbol", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_margin_price_index_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_price_index("BTCUSDT")
  expect_true(grepl("sapi/v1/margin/priceIndex", captured_url))
  expect_true(grepl("symbol=BTCUSDT", captured_url))
})

# -- get_interest_rate_history --

test_that("get_interest_rate_history returns data.table with datetime", {
  resp <- mock_binance_response(data = mock_interest_rate_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_interest_rate_history("BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("asset" %in% names(dt))
  expect_true("daily_interest_rate" %in% names(dt))
  expect_true("timestamp" %in% names(dt))
  expect_true("vip_level" %in% names(dt))
  expect_s3_class(dt$timestamp, "POSIXct")
})

test_that("get_interest_rate_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_interest_rate_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_interest_rate_history("BTC")
  expect_true(grepl("sapi/v1/margin/interestRateHistory", captured_url))
  expect_true(grepl("asset=BTC", captured_url))
})

test_that("get_interest_rate_history passes optional parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_interest_rate_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_interest_rate_history("BTC", vipLevel = 1, startTime = 1000, endTime = 2000)
  expect_true(grepl("vipLevel=1", captured_url))
  expect_true(grepl("startTime=1000", captured_url))
  expect_true(grepl("endTime=2000", captured_url))
})

test_that("get_interest_rate_history returns empty data.table on empty response", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_interest_rate_history("BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_cross_margin_data --

test_that("get_cross_margin_data returns data.table with correct columns", {
  resp <- mock_binance_response(data = mock_cross_margin_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_cross_margin_data()
  expect_s3_class(dt, "data.table")
  # marginable_pairs expanded to long format: 2 pairs in mock => 2 rows
  expect_equal(nrow(dt), 2L)
  expect_true("vip_level" %in% names(dt))
  expect_true("coin" %in% names(dt))
  expect_true("transfer_in" %in% names(dt))
  expect_true("transfer_out" %in% names(dt))
  expect_true("borrowable" %in% names(dt))
  expect_true("daily_interest" %in% names(dt))
  expect_true("yearly_interest" %in% names(dt))
  # marginable_pairs is now expanded to long format as marginable_pair (singular)
  expect_false("marginable_pairs" %in% names(dt))
  expect_true("marginable_pair" %in% names(dt))
  expect_equal(dt$marginable_pair, c("BTCUSDT", "BTCBUSD"))
  expect_equal(unique(dt$coin), "BTC")
})

test_that("get_cross_margin_data hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_cross_margin_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_cross_margin_data()
  expect_true(grepl("sapi/v1/margin/crossMarginData", captured_url))
})

test_that("get_cross_margin_data passes optional parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_cross_margin_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_cross_margin_data(vipLevel = 0, coin = "BTC")
  expect_true(grepl("vipLevel=0", captured_url))
  expect_true(grepl("coin=BTC", captured_url))
})

test_that("get_cross_margin_data returns empty data.table on empty response", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_cross_margin_data()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_isolated_margin_data --

test_that("get_isolated_margin_data returns data.table with correct columns", {
  resp <- mock_binance_response(data = mock_isolated_margin_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_isolated_margin_data()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("vip_level" %in% names(dt))
  expect_true("symbol" %in% names(dt))
  expect_true("leverage" %in% names(dt))
  expect_true("data" %in% names(dt))
  expect_equal(dt$symbol, "BTCUSDT")
})

test_that("get_isolated_margin_data hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_isolated_margin_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_isolated_margin_data()
  expect_true(grepl("sapi/v1/margin/isolatedMarginData", captured_url))
})

test_that("get_isolated_margin_data passes optional parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_isolated_margin_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_margin()$get_isolated_margin_data(vipLevel = 0, symbol = "BTCUSDT")
  expect_true(grepl("vipLevel=0", captured_url))
  expect_true(grepl("symbol=BTCUSDT", captured_url))
})

test_that("get_isolated_margin_data returns empty data.table on empty response", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_isolated_margin_data()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
