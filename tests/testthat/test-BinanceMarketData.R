# tests/testthat/test-BinanceMarketData.R
# Integration-style tests for BinanceMarketData R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_market <- function() {
  return(BinanceMarketData$new(keys = KEYS, base_url = BASE))
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
  expect_s3_class(dt$server_time, "POSIXct")
})

# -- get_exchange_info --

test_that("get_exchange_info returns data.table with string arrays semicolon-joined", {
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

  # String array fields are `;`-collapsed character columns (cross-package
  # convention; see `collapse_string_array_fields()` in helpers_parse.R).
  expect_true("order_types" %in% names(dt))
  expect_type(dt$order_types, "character")
  expect_equal(
    dt[symbol == "BTCUSDT"]$order_types,
    "LIMIT;LIMIT_MAKER;MARKET;STOP_LOSS_LIMIT;TAKE_PROFIT_LIMIT"
  )
  expect_equal(dt[symbol == "ETHUSDT"]$order_types, "LIMIT;MARKET")

  expect_true("permissions" %in% names(dt))
  expect_type(dt$permissions, "character")
  expect_equal(dt[symbol == "BTCUSDT"]$permissions, "SPOT;MARGIN")
  expect_equal(dt[symbol == "ETHUSDT"]$permissions, "SPOT")

  expect_true("allowed_self_trade_prevention_modes" %in% names(dt))
  expect_type(dt$allowed_self_trade_prevention_modes, "character")
  expect_equal(
    dt[symbol == "BTCUSDT"]$allowed_self_trade_prevention_modes,
    "EXPIRE_TAKER;EXPIRE_MAKER;EXPIRE_BOTH"
  )

  # `permission_sets` is Binance's array-of-arrays field. We serialise
  # it as a JSON string so the inner groupings are preserved (a `;`-join
  # would erase the semantic boundaries between alternative permission
  # sets). Round-trip via jsonlite::fromJSON. ETH lacks it → NA.
  expect_true("permission_sets" %in% names(dt))
  expect_type(dt$permission_sets, "character")
  expect_equal(
    dt[symbol == "BTCUSDT"]$permission_sets,
    '[["SPOT","MARGIN","TRD_GRP_004"]]'
  )
  # Round-trip recovers the nested structure.
  recovered <- jsonlite::fromJSON(dt[symbol == "BTCUSDT"]$permission_sets, simplifyVector = FALSE)
  expect_equal(recovered, list(list("SPOT", "MARGIN", "TRD_GRP_004")))
  expect_true(is.na(dt[symbol == "ETHUSDT"]$permission_sets))

  # No list columns anywhere — regression for the cross-package policy.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)

  # filters are now extracted into flat numeric columns (no list-column)
  expect_false("filters" %in% names(dt))
  expect_true("lot_min_qty" %in% names(dt))
  expect_true("lot_max_qty" %in% names(dt))
  expect_true("lot_step_size" %in% names(dt))
  expect_true("price_min" %in% names(dt))
  expect_true("price_max" %in% names(dt))
  expect_true("price_tick_size" %in% names(dt))
  expect_true("min_notional" %in% names(dt))

  # Other fields still present
  expect_true("iceberg_allowed" %in% names(dt))
  expect_true("oco_allowed" %in% names(dt))
  expect_true("default_self_trade_prevention_mode" %in% names(dt))
  expect_true("allow_trailing_stop" %in% names(dt))
  expect_true("cancel_replace_allowed" %in% names(dt))

  # Scalar columns still work
  expect_true(dt[symbol == "BTCUSDT"]$iceberg_allowed)
  expect_false(dt[symbol == "ETHUSDT"]$iceberg_allowed)
})

test_that("get_exchange_info JSON-encodes multi-set permissionSets without flattening the grouping", {
  # The cross-package convention is that `permissionSets` array-of-arrays
  # is JSON-encoded so the inner groupings survive a round-trip. The
  # default fixture only has ONE outer-array element; this test pushes a
  # response with TWO alternative permission sets to confirm the
  # encoding preserves the boundary between them.
  data <- mock_exchange_info_data()
  data$symbols[[1]]$permissionSets <- list(
    list("SPOT", "MARGIN"),
    list("TRD_GRP_004", "TRD_GRP_005")
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_exchange_info()
  ps_btc <- dt[symbol == "BTCUSDT"]$permission_sets
  expect_type(ps_btc, "character")
  recovered <- jsonlite::fromJSON(ps_btc, simplifyVector = FALSE)
  expect_length(recovered, 2L)
  expect_equal(recovered[[1]], list("SPOT", "MARGIN"))
  expect_equal(recovered[[2]], list("TRD_GRP_004", "TRD_GRP_005"))
})

test_that("get_exchange_info preserves the full filters array in `filters_raw` (round-trips through JSON)", {
  # Regression for the silent-drop bug: the parser used to pull out
  # LOT_SIZE / PRICE_FILTER / NOTIONAL into curated columns and then
  # discard the entire `filters` list. Any filter type we don't
  # extract (PERCENT_PRICE, MARKET_LOT_SIZE, MAX_NUM_ORDERS,
  # ICEBERG_PARTS, TRAILING_DELTA, etc.) was lost. Now the whole
  # filters array survives as a JSON string column.
  data <- mock_exchange_info_data()
  data$symbols[[1]]$filters <- c(
    data$symbols[[1]]$filters,
    list(
      list(filterType = "PERCENT_PRICE", multiplierUp = "5", multiplierDown = "0.2", avgPriceMins = 5L),
      list(filterType = "MAX_NUM_ORDERS", maxNumOrders = 200L),
      list(filterType = "TRAILING_DELTA", minTrailingAboveDelta = 10L, maxTrailingAboveDelta = 2000L)
    )
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_exchange_info()
  expect_true("filters_raw" %in% names(dt))
  expect_type(dt$filters_raw, "character")

  # Round-trip the BTCUSDT row and check all filter types survived.
  recovered <- jsonlite::fromJSON(
    dt[symbol == "BTCUSDT"]$filters_raw,
    simplifyVector = FALSE
  )
  types <- vapply(recovered, function(f) f$filterType, character(1))
  expect_setequal(
    types,
    c("PRICE_FILTER", "LOT_SIZE", "PERCENT_PRICE", "MAX_NUM_ORDERS", "TRAILING_DELTA")
  )
  # Fields from the non-curated filter types survive round-trip.
  pp <- recovered[[which(types == "PERCENT_PRICE")]]
  expect_equal(pp$multiplierUp, "5")
  expect_equal(pp$avgPriceMins, 5L)
  td <- recovered[[which(types == "TRAILING_DELTA")]]
  expect_equal(td$maxTrailingAboveDelta, 2000L)

  # ETH symbol still has its single PRICE_FILTER.
  recovered_eth <- jsonlite::fromJSON(
    dt[symbol == "ETHUSDT"]$filters_raw,
    simplifyVector = FALSE
  )
  expect_length(recovered_eth, 1L)
  expect_equal(recovered_eth[[1]]$filterType, "PRICE_FILTER")
})

test_that("get_exchange_info attaches exchange-wide metadata as attributes", {
  # Regression: top-level fields `timezone`, `serverTime`, `rateLimits`,
  # `exchangeFilters`, `sors` are exchange-wide and don't fit on a
  # per-symbol row, but the parser used to silently discard them. They
  # are now attached as attributes so the data is reachable.
  data <- mock_exchange_info_data()
  data$rateLimits <- list(
    list(rateLimitType = "REQUEST_WEIGHT", interval = "MINUTE", intervalNum = 1L, limit = 6000L),
    list(rateLimitType = "ORDERS", interval = "SECOND", intervalNum = 10L, limit = 100L)
  )
  data$exchangeFilters <- list(
    list(filterType = "EXCHANGE_MAX_NUM_ORDERS", maxNumOrders = 1000L)
  )
  data$sors <- list(
    list(baseAsset = "BTC", symbols = list("BTCUSDT", "BTCUSDC"))
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_exchange_info()

  expect_equal(attr(dt, "timezone"), "UTC")
  expect_s3_class(attr(dt, "server_time"), "POSIXct")

  rl <- attr(dt, "rate_limits")
  expect_s3_class(rl, "data.table")
  expect_equal(nrow(rl), 2L)
  expect_true("rate_limit_type" %in% names(rl))
  expect_setequal(rl$rate_limit_type, c("REQUEST_WEIGHT", "ORDERS"))

  ef <- attr(dt, "exchange_filters")
  expect_s3_class(ef, "data.table")
  expect_equal(nrow(ef), 1L)
  expect_equal(ef$filter_type, "EXCHANGE_MAX_NUM_ORDERS")

  sors <- attr(dt, "sors")
  expect_s3_class(sors, "data.table")
  expect_equal(nrow(sors), 1L)
  expect_equal(sors$base_asset, "BTC")
})

test_that("get_exchange_info metadata attributes default to empty data.tables when fields are absent", {
  # Default mock has only timezone + serverTime. Other top-level fields
  # are absent — the attributes should still exist (empty data.tables),
  # so downstream code that always reads `attr(dt, "rate_limits")`
  # doesn't break.
  resp <- mock_binance_response(data = mock_exchange_info_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_exchange_info()
  expect_s3_class(attr(dt, "rate_limits"), "data.table")
  expect_equal(nrow(attr(dt, "rate_limits")), 0L)
  expect_s3_class(attr(dt, "exchange_filters"), "data.table")
  expect_equal(nrow(attr(dt, "exchange_filters")), 0L)
  expect_s3_class(attr(dt, "sors"), "data.table")
  expect_equal(nrow(attr(dt, "sors")), 0L)
})

test_that("get_exchange_info filters by symbol", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_exchange_info_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
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
  expect_true("open_time" %in% names(dt))
  expect_true("close_time" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
  expect_s3_class(dt$close_time, "POSIXct")
})

# -- get_all_24hr_stats --

test_that("get_all_24hr_stats returns one row per symbol with POSIXct times", {
  resp <- mock_binance_response(data = mock_all_24hr_stats_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_all_24hr_stats()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_setequal(dt$symbol, c("BTCUSDT", "ETHUSDT"))
  expect_true("open_time" %in% names(dt))
  expect_true("close_time" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
  expect_s3_class(dt$close_time, "POSIXct")
  # No list columns.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("get_all_24hr_stats hits /api/v3/ticker/24hr with no `symbol` param", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_all_24hr_stats_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_all_24hr_stats()
  expect_true(grepl("/api/v3/ticker/24hr", captured_url))
  # No symbol query param — that's what the "all" endpoint variant means.
  expect_false(grepl("symbol=", captured_url))
})

test_that("get_all_24hr_stats returns empty data.table when no symbols", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_all_24hr_stats()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
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
  expect_true("close_time" %in% names(dt))
  expect_s3_class(dt$close_time, "POSIXct")
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
  expect_true("size" %in% names(dt))
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
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
})

# -- get_klines --

test_that("get_klines returns OHLCV data.table", {
  resp <- mock_binance_response(data = mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_klines("BTCUSDT", "1h")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("open_time" %in% names(dt))
  expect_true("open" %in% names(dt))
  expect_true("high" %in% names(dt))
  expect_true("low" %in% names(dt))
  expect_true("close" %in% names(dt))
  expect_true("volume" %in% names(dt))
  expect_true("close_time" %in% names(dt))
  expect_true("quote_volume" %in% names(dt))
  expect_true("trades" %in% names(dt))
  expect_true("taker_buy_base_volume" %in% names(dt))
  expect_true("taker_buy_quote_volume" %in% names(dt))
  expect_true("ignore" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
  expect_s3_class(dt$close_time, "POSIXct")
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
    return(resp)
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
