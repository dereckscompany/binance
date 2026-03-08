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
        orderTypes = list("LIMIT", "LIMIT_MAKER", "MARKET", "STOP_LOSS_LIMIT", "TAKE_PROFIT_LIMIT"),
        icebergAllowed = TRUE,
        ocoAllowed = TRUE,
        otoAllowed = TRUE,
        quoteOrderQtyMarketAllowed = TRUE,
        allowTrailingStop = TRUE,
        cancelReplaceAllowed = TRUE,
        isSpotTradingAllowed = TRUE,
        isMarginTradingAllowed = TRUE,
        filters = list(
          list(filterType = "PRICE_FILTER", minPrice = "0.01000000", maxPrice = "1000000.00", tickSize = "0.01000000"),
          list(filterType = "LOT_SIZE", minQty = "0.00001000", maxQty = "9000.00000000", stepSize = "0.00001000")
        ),
        permissions = list("SPOT", "MARGIN"),
        defaultSelfTradePreventionMode = "EXPIRE_MAKER",
        allowedSelfTradePreventionModes = list("EXPIRE_TAKER", "EXPIRE_MAKER", "EXPIRE_BOTH")
      ),
      list(
        symbol = "ETHUSDT",
        status = "TRADING",
        baseAsset = "ETH",
        baseAssetPrecision = 8L,
        quoteAsset = "USDT",
        quoteAssetPrecision = 8L,
        quotePrecision = 8L,
        orderTypes = list("LIMIT", "MARKET"),
        icebergAllowed = FALSE,
        ocoAllowed = FALSE,
        otoAllowed = FALSE,
        quoteOrderQtyMarketAllowed = TRUE,
        allowTrailingStop = FALSE,
        cancelReplaceAllowed = FALSE,
        isSpotTradingAllowed = TRUE,
        isMarginTradingAllowed = FALSE,
        filters = list(
          list(filterType = "PRICE_FILTER", minPrice = "0.01000000", maxPrice = "100000.00", tickSize = "0.01000000")
        ),
        permissions = list("SPOT"),
        defaultSelfTradePreventionMode = "NONE",
        allowedSelfTradePreventionModes = list("NONE")
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

# ---------------------------------------------------------------------------
# Deposit fixtures
# ---------------------------------------------------------------------------

#' Deposit address response
#' @export
mock_deposit_address_data <- function() {
  return(list(
    address = "1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv",
    coin = "BTC",
    tag = "",
    url = "https://btc.com/1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv"
  ))
}

#' Deposit history — 2 deposits
#' @export
mock_deposit_history_data <- function() {
  return(list(
    list(
      id = "769800519366885376",
      amount = "0.001",
      coin = "BNB",
      network = "BNB",
      status = 1L,
      address = "bnb136ns6lfw4zs5hg4n85vdthaad7hq5m4gtkgf23",
      addressTag = "101764890",
      txId = "98A3EA560C6B3336D348B6C83F0F95ECE4F1F5919E94BD006E5BF3BF264FACFC",
      insertTime = 1661493146000,
      completeTime = 1661493246000,
      transferType = 0L,
      confirmTimes = "1/1",
      unlockConfirm = 0L,
      walletType = 0L
    ),
    list(
      id = "769800519366885377",
      amount = "0.50000000",
      coin = "ETH",
      network = "ETH",
      status = 0L,
      address = "0x94df8b352de7f46f64b01d3666bf6e936e44ce60",
      addressTag = "",
      txId = "0xabc123def456",
      insertTime = 1661493246000,
      completeTime = 0,
      transferType = 0L,
      confirmTimes = "5/12",
      unlockConfirm = 12L,
      walletType = 0L
    )
  ))
}

# ---------------------------------------------------------------------------
# Withdrawal fixtures
# ---------------------------------------------------------------------------

#' Withdrawal apply response
#' @export
mock_withdrawal_response <- function() {
  return(list(id = "7213fea8e94b4a5593d507237e5a555b"))
}

#' Withdrawal history — 2 withdrawals
#' @export
mock_withdrawal_history_data <- function() {
  return(list(
    list(
      id = "b6ae22b3aa844210a7041aee7589627c",
      amount = "8.91000000",
      transactionFee = "0.004",
      coin = "USDT",
      status = 6L,
      address = "0x94df8b352de7f46f64b01d3666bf6e936e44ce60",
      txId = "0xb5ef8c13b968a406cc62a93a8bd80f9e9a906ef1b3fcf20a2e48573c17659268",
      applyTime = "2019-10-12 11:12:02",
      network = "ETH",
      transferType = 0L,
      withdrawOrderId = "WITHDRAWtest123",
      info = "",
      confirmNo = 3L,
      walletType = 1L,
      txKey = "",
      completeTime = "2023-03-23 16:52:41"
    ),
    list(
      id = "c7bf33c4bb955321b8152618faa69738",
      amount = "0.10000000",
      transactionFee = "0.0005",
      coin = "BTC",
      status = 4L,
      address = "1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv",
      txId = "",
      applyTime = "2023-05-01 08:30:00",
      network = "BTC",
      transferType = 0L,
      withdrawOrderId = "",
      info = "",
      confirmNo = 0L,
      walletType = 0L,
      txKey = "",
      completeTime = ""
    )
  ))
}
