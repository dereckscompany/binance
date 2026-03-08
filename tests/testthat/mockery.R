# Shared mock response builders and data fixtures for Binance API.
#
# Provides realistic mock data matching Binance API response shapes.
# Used by tests, README, and vignettes via box::use() relative imports.

# This file is used in two ways:
# 1. As a box module via box::use() from README.Rmd and vignettes
# 2. Via source() from helper-mock.R (testthat context)
# We use :: notation so it works in both contexts.

# ---------------------------------------------------------------------------
# Response builder
# ---------------------------------------------------------------------------

#' Build a fake httr2 response with Binance JSON body
#'
#' Binance returns raw JSON (no envelope wrapper like KuCoin).
#' @export
mock_response <- function(data, status_code = 200L) {
  body <- jsonlite::toJSON(
    data,
    auto_unbox = TRUE,
    null = "null"
  )
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  ))
}

# ---------------------------------------------------------------------------
# Market Data fixtures
# ---------------------------------------------------------------------------

#' Server time response
#' @export
mock_server_time_data <- function() {
  return(list(serverTime = 1499827319559))
}

#' Exchange info — BTCUSDT + ETHUSDT
#' @export
mock_exchange_info_data <- function() {
  return(list(
    timezone = "UTC",
    serverTime = 1499827319559,
    symbols = list(
      list(
        symbol = "BTCUSDT",
        status = "TRADING",
        baseAsset = "BTC",
        baseAssetPrecision = 8L,
        quoteAsset = "USDT",
        quoteAssetPrecision = 8L,
        quotePrecision = 8L,
        isSpotTradingAllowed = TRUE,
        isMarginTradingAllowed = TRUE
      ),
      list(
        symbol = "ETHUSDT",
        status = "TRADING",
        baseAsset = "ETH",
        baseAssetPrecision = 8L,
        quoteAsset = "USDT",
        quoteAssetPrecision = 8L,
        quotePrecision = 8L,
        isSpotTradingAllowed = TRUE,
        isMarginTradingAllowed = FALSE
      )
    )
  ))
}

#' Symbol price ticker — BTCUSDT
#' @export
mock_ticker_data <- function() {
  return(list(symbol = "BTCUSDT", price = "67232.90000000"))
}

#' All tickers — BTCUSDT + ETHUSDT
#' @export
mock_all_tickers_data <- function() {
  return(list(
    list(symbol = "BTCUSDT", price = "67232.90000000"),
    list(symbol = "ETHUSDT", price = "2530.60000000")
  ))
}

#' Book ticker — BTCUSDT
#' @export
mock_book_ticker_data <- function() {
  return(list(
    symbol = "BTCUSDT",
    bidPrice = "67232.00000000",
    bidQty = "0.41861839",
    askPrice = "67232.90000000",
    askQty = "1.24808993"
  ))
}

#' 24hr statistics — BTCUSDT
#' @export
mock_24hr_stats_data <- function() {
  return(list(
    symbol = "BTCUSDT",
    priceChange = "-772.10000000",
    priceChangePercent = "-1.140",
    weightedAvgPrice = "67450.50000000",
    prevClosePrice = "68005.00000000",
    lastPrice = "67232.90000000",
    lastQty = "0.00100000",
    bidPrice = "67232.80000000",
    bidQty = "0.41861839",
    askPrice = "67232.90000000",
    askQty = "1.24808993",
    openPrice = "68005.00000000",
    highPrice = "68100.00000000",
    lowPrice = "66800.00000000",
    volume = "3456.78901234",
    quoteVolume = "232456789.12000000",
    openTime = 1729073059033,
    closeTime = 1729159459033,
    firstId = 1000L,
    lastId = 2000L,
    count = 1001L
  ))
}

#' Average price — BTCUSDT
#' @export
mock_avg_price_data <- function() {
  return(list(
    mins = 5L,
    price = "67232.45000000",
    closeTime = 1694061154503
  ))
}

#' Order book depth — BTCUSDT
#' @export
mock_orderbook_data <- function() {
  return(list(
    lastUpdateId = 1027024,
    bids = list(
      list("67232.80000000", "0.41861839"),
      list("67232.50000000", "1.50000000"),
      list("67230.00000000", "0.80000000")
    ),
    asks = list(
      list("67232.90000000", "1.24808993"),
      list("67233.50000000", "0.50000000"),
      list("67235.00000000", "2.10000000")
    )
  ))
}

#' Recent trades — 3 trades
#' @export
mock_trades_data <- function() {
  return(list(
    list(
      id = 28457L,
      price = "67232.90000000",
      qty = "0.00007682",
      quoteQty = "5.16527540",
      time = 1499865549590,
      isBuyerMaker = TRUE,
      isBestMatch = TRUE
    ),
    list(
      id = 28458L,
      price = "67231.50000000",
      qty = "0.01234000",
      quoteQty = "829.63251000",
      time = 1499865550150,
      isBuyerMaker = FALSE,
      isBestMatch = TRUE
    ),
    list(
      id = 28459L,
      price = "67233.00000000",
      qty = "0.00500000",
      quoteQty = "336.16500000",
      time = 1499865551200,
      isBuyerMaker = TRUE,
      isBestMatch = TRUE
    )
  ))
}

#' Klines — 3 candles (Binance array-of-arrays format)
#' @export
mock_klines_data <- function() {
  return(list(
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
    ),
    list(
      1499644800000,
      "0.01577100",
      "0.01580000",
      "0.01573000",
      "0.01578800",
      "95432.00000000",
      1500249599999,
      "1505.25000000",
      205L,
      "876.12345678",
      "13.82000000",
      "0"
    ),
    list(
      1500249600000,
      "0.01578800",
      "0.01590000",
      "0.01570000",
      "0.01585000",
      "120000.00000000",
      1500854399999,
      "1899.60000000",
      250L,
      "950.00000000",
      "15.06750000",
      "0"
    )
  ))
}

# ---------------------------------------------------------------------------
# Trading fixtures
# ---------------------------------------------------------------------------

#' Order placement response (RESULT type)
#' @export
mock_order_response <- function() {
  return(list(
    symbol = "BTCUSDT",
    orderId = 28L,
    orderListId = -1L,
    clientOrderId = "6gCrw2kRUAF9CvJDGP16IP",
    transactTime = 1507725176595,
    price = "50000.00000000",
    origQty = "0.00010000",
    executedQty = "0.00000000",
    cummulativeQuoteQty = "0.00000000",
    status = "NEW",
    timeInForce = "GTC",
    type = "LIMIT",
    side = "BUY",
    workingTime = 1507725176595,
    selfTradePreventionMode = "NONE"
  ))
}

#' Cancel order response
#' @export
mock_cancel_order_data <- function() {
  return(list(
    symbol = "BTCUSDT",
    origClientOrderId = "6gCrw2kRUAF9CvJDGP16IP",
    orderId = 28L,
    orderListId = -1L,
    clientOrderId = "cancelMyOrder1",
    transactTime = 1507725176595,
    price = "50000.00000000",
    origQty = "0.00010000",
    executedQty = "0.00000000",
    cummulativeQuoteQty = "0.00000000",
    status = "CANCELED",
    timeInForce = "GTC",
    type = "LIMIT",
    side = "BUY",
    selfTradePreventionMode = "NONE"
  ))
}

#' Query order response
#' @export
mock_query_order_data <- function() {
  return(list(
    symbol = "BTCUSDT",
    orderId = 28L,
    orderListId = -1L,
    clientOrderId = "6gCrw2kRUAF9CvJDGP16IP",
    price = "50000.00000000",
    origQty = "0.00010000",
    executedQty = "0.00010000",
    cummulativeQuoteQty = "5.00000000",
    status = "FILLED",
    timeInForce = "GTC",
    type = "LIMIT",
    side = "BUY",
    stopPrice = "0.00000000",
    icebergQty = "0.00000000",
    time = 1507725176595,
    updateTime = 1507725176700,
    isWorking = TRUE,
    origQuoteOrderQty = "0.00000000",
    workingTime = 1507725176595,
    selfTradePreventionMode = "NONE"
  ))
}

#' Open orders — 1 order
#' @export
mock_open_orders_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      orderId = 28L,
      orderListId = -1L,
      clientOrderId = "6gCrw2kRUAF9CvJDGP16IP",
      price = "50000.00000000",
      origQty = "0.00010000",
      executedQty = "0.00000000",
      cummulativeQuoteQty = "0.00000000",
      status = "NEW",
      timeInForce = "GTC",
      type = "LIMIT",
      side = "BUY",
      stopPrice = "0.00000000",
      icebergQty = "0.00000000",
      time = 1507725176595,
      isWorking = TRUE,
      origQuoteOrderQty = "0.00000000",
      workingTime = 1507725176595,
      selfTradePreventionMode = "NONE"
    )
  ))
}

# ---------------------------------------------------------------------------
# Account fixtures
# ---------------------------------------------------------------------------

#' Account information
#' @export
mock_account_data <- function() {
  return(list(
    makerCommission = 15L,
    takerCommission = 15L,
    buyerCommission = 0L,
    sellerCommission = 0L,
    commissionRates = list(
      maker = "0.00150000",
      taker = "0.00150000",
      buyer = "0.00000000",
      seller = "0.00000000"
    ),
    canTrade = TRUE,
    canWithdraw = TRUE,
    canDeposit = TRUE,
    brokered = FALSE,
    requireSelfTradePrevention = FALSE,
    preventSor = FALSE,
    updateTime = 123456789,
    accountType = "SPOT",
    balances = list(
      list(asset = "BTC", free = "4723846.89208129", locked = "0.00000000"),
      list(asset = "LTC", free = "4763368.68006011", locked = "0.00000000"),
      list(asset = "ETH", free = "0.00000000", locked = "0.00000000")
    ),
    permissions = list("SPOT"),
    uid = 354937868L
  ))
}

#' Account trade list — 2 trades
#' @export
mock_my_trades_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      id = 28457L,
      orderId = 100234L,
      orderListId = -1L,
      price = "67232.90000000",
      qty = "0.00100000",
      quoteQty = "67.23290000",
      commission = "0.00000100",
      commissionAsset = "BTC",
      time = 1499865549590,
      isBuyer = TRUE,
      isMaker = FALSE,
      isBestMatch = TRUE
    ),
    list(
      symbol = "BTCUSDT",
      id = 28458L,
      orderId = 100235L,
      orderListId = -1L,
      price = "67200.00000000",
      qty = "0.00050000",
      quoteQty = "33.60000000",
      commission = "0.00000050",
      commissionAsset = "BTC",
      time = 1499865550150,
      isBuyer = FALSE,
      isMaker = TRUE,
      isBestMatch = TRUE
    )
  ))
}
