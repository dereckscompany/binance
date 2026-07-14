# tests/testthat/test-BinanceFuturesData.R
# Integration-style tests for BinanceFuturesData R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://fapi.binance.com"

new_futures_data <- function() {
  return(BinanceFuturesData$new(keys = KEYS, base_url = BASE))
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
  # filters are extracted into flat numeric columns
  expect_false("filters" %in% names(dt))
  expect_true("lot_min_qty" %in% names(dt))
  expect_true("lot_max_qty" %in% names(dt))
  expect_true("lot_step_size" %in% names(dt))
  expect_true("price_min" %in% names(dt))
  expect_true("price_max" %in% names(dt))
  expect_true("price_tick_size" %in% names(dt))
  expect_true("min_notional" %in% names(dt))
  # String arrays are `;`-collapsed character (cross-package convention).
  expect_type(dt$order_types, "character")
  expect_false(grepl(",", dt$order_types, fixed = TRUE), info = "should be `;`-joined, not `,`-joined")
  expect_equal(dt$symbol, "BTCUSDT")
  expect_equal(dt$contract_type, "PERPETUAL")
  expect_equal(dt$base_asset, "BTC")
  # No list columns anywhere.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("get_exchange_info hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_exchange_info_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures_data()$get_exchange_info()
  expect_true(grepl("/fapi/v1/exchangeInfo", captured_url))
})

test_that("get_exchange_info preserves the full filters array in `filters_raw` (round-trips through JSON)", {
  # Same regression as spot: parser used to pull curated filter columns
  # and discard the rest. Futures-specific filter types include
  # PERCENT_PRICE, MARKET_LOT_SIZE, MAX_NUM_ORDERS, MAX_NUM_ALGO_ORDERS,
  # and the MIN_NOTIONAL field used to be silently dropped because
  # futures uses field name "notional" not "minNotional".
  data <- mock_futures_exchange_info_data()
  data$symbols[[1]]$filters <- c(
    data$symbols[[1]]$filters,
    list(
      list(filterType = "PERCENT_PRICE", multiplierUp = "1.05", multiplierDown = "0.95", multiplierDecimal = 4L),
      list(filterType = "MARKET_LOT_SIZE", minQty = "0.001", maxQty = "1000", stepSize = "0.001"),
      list(filterType = "MAX_NUM_ORDERS", limit = 200L),
      list(filterType = "MAX_NUM_ALGO_ORDERS", limit = 10L)
    )
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_exchange_info()
  expect_true("filters_raw" %in% names(dt))
  expect_type(dt$filters_raw, "character")

  recovered <- jsonlite::fromJSON(dt$filters_raw[1], simplifyVector = FALSE)
  types <- vapply(recovered, function(f) f$filterType, character(1))
  expect_setequal(
    types,
    c("PRICE_FILTER", "PERCENT_PRICE", "MARKET_LOT_SIZE", "MAX_NUM_ORDERS", "MAX_NUM_ALGO_ORDERS")
  )
  mls <- recovered[[which(types == "MARKET_LOT_SIZE")]]
  expect_equal(mls$minQty, "0.001")
  expect_equal(mls$stepSize, "0.001")
})

test_that("get_exchange_info tolerates a symbol with no filters (type-fidelity NA audit)", {
  # dereckscompany/.github discussion #2: `.extract_filter` yields NA_real_ when a
  # symbol carries no PRICE_FILTER, and `filters_raw` is NA when Binance sends no
  # filters at all. The `price_*` / `filters_raw` contracts must tolerate those
  # NAs, not abort -- before the audit they carried assert_no_missing_values.
  data <- mock_futures_exchange_info_data()
  data$symbols[[1]]$filters <- list()
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  # Returns without error => the `| NA` contract accepts the NA row.
  dt <- new_futures_data()$get_exchange_info()
  expect_s3_class(dt, "data.table")
  for (col in c("price_min", "price_max", "price_tick_size")) {
    expect_true(is.numeric(dt[[col]]), info = col)
    expect_true(is.na(dt[[col]]), info = col)
  }
  expect_true(is.character(dt$filters_raw))
  expect_true(is.na(dt$filters_raw))
})

test_that("get_rate_limits (futures) returns one row per rate-limit rule", {
  data <- mock_futures_exchange_info_data()
  data$rateLimits <- list(
    list(rateLimitType = "REQUEST_WEIGHT", interval = "MINUTE", intervalNum = 1L, limit = 2400L),
    list(rateLimitType = "ORDERS", interval = "MINUTE", intervalNum = 1L, limit = 1200L)
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_rate_limits()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_setequal(dt$rate_limit_type, c("REQUEST_WEIGHT", "ORDERS"))
})

test_that("get_rate_limits (futures) returns empty data.table when omitted", {
  resp <- mock_binance_response(data = mock_futures_exchange_info_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_rate_limits()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_exchange_filters (futures) returns empty when absent (common case)", {
  resp <- mock_binance_response(data = mock_futures_exchange_info_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_exchange_filters()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_futures_assets returns one row per margin asset", {
  data <- mock_futures_exchange_info_data()
  data$assets <- list(
    list(asset = "USDT", marginAvailable = TRUE, autoAssetExchange = "-1000"),
    list(asset = "BNFCR", marginAvailable = TRUE, autoAssetExchange = "0")
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_futures_assets()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_setequal(dt$asset, c("USDT", "BNFCR"))
  expect_true(all(dt$margin_available))
})

test_that("get_futures_assets returns empty data.table when absent", {
  resp <- mock_binance_response(data = mock_futures_exchange_info_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_futures_assets()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_klines --

test_that("get_klines returns OHLCV data.table", {
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_klines("BTCUSDT", "1h")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("datetime" %in% names(dt))
  expect_true("open" %in% names(dt))
  expect_true("high" %in% names(dt))
  expect_true("low" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_true("volume" %in% names(dt))
  expect_true("close_time" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
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
    return(resp)
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
    return(resp)
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
    return(resp)
  })

  new_futures_data()$get_funding_rate("BTCUSDT")
  expect_true(grepl("/fapi/v1/fundingRate", captured_url))
})

# -- get_funding_info --

test_that("get_funding_info returns the typed funding-interval declarations", {
  resp <- mock_binance_response(data = mock_futures_funding_info_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_funding_info()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_equal(
    names(dt),
    c(
      "symbol",
      "adjusted_funding_rate_cap",
      "adjusted_funding_rate_floor",
      "funding_interval_hours",
      "disclaimer",
      "update_time"
    )
  )
  # symbol structural (character); cap/floor measurements coerced to numeric;
  # interval a whole-hour integer; disclaimer a logical flag; update_time POSIXct.
  expect_type(dt$symbol, "character")
  expect_type(dt$adjusted_funding_rate_cap, "double")
  expect_type(dt$adjusted_funding_rate_floor, "double")
  expect_type(dt$funding_interval_hours, "integer")
  expect_type(dt$disclaimer, "logical")
  expect_s3_class(dt$update_time, "POSIXct")
  expect_equal(dt$funding_interval_hours, c(8L, 4L))
  expect_equal(dt$adjusted_funding_rate_cap, c(0.02, 0.03))
  expect_equal(dt$disclaimer, c(FALSE, TRUE))
  # No list columns anywhere.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("get_funding_info returns the typed empty on an empty declaration list", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_data()$get_funding_info()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
  expect_equal(
    names(dt),
    c(
      "symbol",
      "adjusted_funding_rate_cap",
      "adjusted_funding_rate_floor",
      "funding_interval_hours",
      "disclaimer",
      "update_time"
    )
  )
  expect_s3_class(dt$update_time, "POSIXct")
})

test_that("get_funding_info hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_futures_funding_info_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures_data()$get_funding_info()
  expect_true(grepl("/fapi/v1/fundingInfo", captured_url))
})

test_that("get_funding_info resolves the same typed table in async mode", {
  resp <- mock_binance_response(data = mock_futures_funding_info_data())
  httr2::local_mocked_responses(function(req) resp)

  fd <- BinanceFuturesData$new(keys = KEYS, base_url = BASE, async = TRUE)
  p <- fd$get_funding_info()
  expect_s3_class(p, "promise")

  resolved <- NULL
  promises::then(p, function(val) resolved <<- val)
  for (i in 1:20) {
    later::run_now(0.1)
  }

  expect_s3_class(resolved, "data.table")
  expect_equal(nrow(resolved), 2L)
  expect_equal(resolved$funding_interval_hours, c(8L, 4L))
  expect_s3_class(resolved$update_time, "POSIXct")
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
    return(resp)
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
    return(resp)
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
    return(resp)
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
    return(resp)
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
  expect_true("size" %in% names(dt))
  expect_equal(sum(dt$side == "bid"), 3L)
  expect_equal(sum(dt$side == "ask"), 3L)
})

test_that("get_depth hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_orderbook_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
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
    return(resp)
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
  expect_true("datetime" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
})

test_that("get_index_price_klines hits correct endpoint with pair param", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
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
  expect_true("datetime" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
})

test_that("get_mark_price_klines hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
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
