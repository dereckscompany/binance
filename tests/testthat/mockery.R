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
        # New field Binance now returns alongside `permissions` — array
        # of arrays where each inner array is an alternative permission
        # set the user can satisfy. Live API often returns
        # `permissions = []` on newer symbols and the meaningful data
        # lives here. Inner groupings carry semantic meaning, so the
        # parser serialises the whole field as a JSON string column
        # (recover with `jsonlite::fromJSON`) rather than `;`-joining
        # which would erase the boundaries.
        permissionSets = list(list("SPOT", "MARGIN", "TRD_GRP_004")),
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
        # ETH symbol intentionally omits `permissionSets` to exercise
        # the missing-field branch (helper should set it to NA).
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

#' All-symbol 24hr stats — array form returned by /api/v3/ticker/24hr
#' when no `symbol` query param is supplied. Two-symbol fixture is
#' enough to exercise the row-binding and timestamp-conversion paths.
#' @export
mock_all_24hr_stats_data <- function() {
  return(list(
    mock_24hr_stats_data(),
    list(
      symbol = "ETHUSDT",
      priceChange = "-25.10",
      priceChangePercent = "-0.800",
      weightedAvgPrice = "3120.50",
      prevClosePrice = "3155.00",
      lastPrice = "3130.40",
      lastQty = "0.01000000",
      bidPrice = "3130.30",
      bidQty = "0.50000000",
      askPrice = "3130.40",
      askQty = "0.75000000",
      openPrice = "3155.50",
      highPrice = "3160.00",
      lowPrice = "3100.00",
      volume = "12345.67",
      quoteVolume = "38567890.12",
      openTime = 1729073059033,
      closeTime = 1729159459033,
      firstId = 5000L,
      lastId = 6000L,
      count = 1001L
    )
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

# ---------------------------------------------------------------------------
# Transfer fixtures
# ---------------------------------------------------------------------------

#' Transfer response
#' @export
mock_transfer_response <- function() {
  return(list(tranId = 13526853623))
}

#' Transfer history — 2 transfers
#' @export
mock_transfer_history_data <- function() {
  return(list(
    total = 2L,
    rows = list(
      list(
        asset = "USDT",
        amount = "100.00000000",
        type = "MAIN_UMFUTURE",
        status = "CONFIRMED",
        tranId = 13526853623,
        timestamp = 1661493146000
      ),
      list(
        asset = "BTC",
        amount = "0.01000000",
        type = "MAIN_MARGIN",
        status = "CONFIRMED",
        tranId = 13526853624,
        timestamp = 1661493246000
      )
    )
  ))
}

# ---------------------------------------------------------------------------
# OCO Order fixtures
# ---------------------------------------------------------------------------

#' OCO order response
#' @export
mock_oco_order_response <- function() {
  return(list(
    orderListId = 0L,
    contingencyType = "OCO",
    listStatusType = "EXEC_STARTED",
    listOrderStatus = "EXECUTING",
    listClientOrderId = "JYVpp3F0f5CAG15DhtrqLp",
    transactTime = 1563417480525,
    symbol = "BTCUSDT",
    orders = list(
      list(symbol = "BTCUSDT", orderId = 12L, clientOrderId = "bX5wROblo6YeDwa9iTLeyY"),
      list(symbol = "BTCUSDT", orderId = 13L, clientOrderId = "Tnu2IP0J5Y4mxw3IATBfmW")
    ),
    orderReports = list(
      list(
        symbol = "BTCUSDT",
        orderId = 12L,
        orderListId = 0L,
        clientOrderId = "bX5wROblo6YeDwa9iTLeyY",
        transactTime = 1563417480525,
        price = "50000.00000000",
        origQty = "0.00010000",
        executedQty = "0.00000000",
        cummulativeQuoteQty = "0.00000000",
        status = "NEW",
        timeInForce = "GTC",
        type = "STOP_LOSS_LIMIT",
        side = "SELL",
        stopPrice = "49000.00000000",
        selfTradePreventionMode = "NONE"
      ),
      list(
        symbol = "BTCUSDT",
        orderId = 13L,
        orderListId = 0L,
        clientOrderId = "Tnu2IP0J5Y4mxw3IATBfmW",
        transactTime = 1563417480525,
        price = "55000.00000000",
        origQty = "0.00010000",
        executedQty = "0.00000000",
        cummulativeQuoteQty = "0.00000000",
        status = "NEW",
        timeInForce = "GTC",
        type = "LIMIT_MAKER",
        side = "SELL",
        selfTradePreventionMode = "NONE"
      )
    )
  ))
}

#' OCO query response
#' @export
mock_oco_query_data <- function() {
  return(list(
    orderListId = 0L,
    contingencyType = "OCO",
    listStatusType = "ALL_DONE",
    listOrderStatus = "ALL_DONE",
    listClientOrderId = "JYVpp3F0f5CAG15DhtrqLp",
    transactionTime = 1563417480525,
    symbol = "BTCUSDT",
    orders = list(
      list(symbol = "BTCUSDT", orderId = 12L, clientOrderId = "bX5wROblo6YeDwa9iTLeyY"),
      list(symbol = "BTCUSDT", orderId = 13L, clientOrderId = "Tnu2IP0J5Y4mxw3IATBfmW")
    )
  ))
}

# ---------------------------------------------------------------------------
# Margin Data fixtures
# ---------------------------------------------------------------------------

#' Cross margin pairs
#' @export
mock_margin_all_pairs_data <- function() {
  return(list(
    list(
      base = "BTC",
      id = 351637150L,
      isBuyAllowed = TRUE,
      isMarginTrade = TRUE,
      isSellAllowed = TRUE,
      quote = "USDT",
      symbol = "BTCUSDT"
    ),
    list(
      base = "ETH",
      id = 351637151L,
      isBuyAllowed = TRUE,
      isMarginTrade = TRUE,
      isSellAllowed = TRUE,
      quote = "USDT",
      symbol = "ETHUSDT"
    )
  ))
}

#' Isolated margin pairs
#' @export
mock_margin_isolated_pairs_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      base = "BTC",
      quote = "USDT",
      isMarginTrade = TRUE,
      isBuyAllowed = TRUE,
      isSellAllowed = TRUE
    ),
    list(
      symbol = "ETHUSDT",
      base = "ETH",
      quote = "USDT",
      isMarginTrade = TRUE,
      isBuyAllowed = TRUE,
      isSellAllowed = TRUE
    )
  ))
}

#' Margin price index
#' @export
mock_margin_price_index_data <- function() {
  return(list(calcTime = 1562046418000, price = "67232.90000000", symbol = "BTCUSDT"))
}

#' Interest rate history
#' @export
mock_interest_rate_history_data <- function() {
  return(list(
    list(asset = "BTC", dailyInterestRate = "0.00015000", timestamp = 1661493146000, vipLevel = 0L),
    list(asset = "BTC", dailyInterestRate = "0.00012000", timestamp = 1661493246000, vipLevel = 0L)
  ))
}

#' Cross margin data
#' @export
mock_cross_margin_data <- function() {
  return(list(
    list(
      vipLevel = 0L,
      coin = "BTC",
      transferIn = TRUE,
      transferOut = TRUE,
      borrowable = TRUE,
      dailyInterest = "0.00015000",
      yearlyInterest = "0.05475000",
      marginablePairs = list("BTCUSDT", "BTCBUSD")
    )
  ))
}

#' Isolated margin data
#' @export
mock_isolated_margin_data <- function() {
  return(list(
    list(
      vipLevel = 0L,
      symbol = "BTCUSDT",
      leverage = "10",
      data = list(list(coin = "BTC", dailyInterest = "0.00015000", borrowLimit = "100.00000000"))
    )
  ))
}

# ---------------------------------------------------------------------------
# Sub-Account fixtures
# ---------------------------------------------------------------------------

#' Create sub-account response
#' @export
mock_sub_account_create_response <- function() {
  return(list(email = "testsub01@virtual.com"))
}

#' Sub-account list
#' @export
mock_sub_account_list_data <- function() {
  return(list(
    subAccounts = list(
      list(
        email = "testsub01@virtual.com",
        isFreeze = FALSE,
        createTime = 1661493146000,
        isManagedSubAccount = FALSE,
        isAssetManagementSubAccount = FALSE
      ),
      list(
        email = "testsub02@virtual.com",
        isFreeze = TRUE,
        createTime = 1661493246000,
        isManagedSubAccount = FALSE,
        isAssetManagementSubAccount = FALSE
      )
    )
  ))
}

#' Sub-account balances
#' @export
mock_sub_account_balances_data <- function() {
  return(list(
    balances = list(
      list(asset = "BTC", free = 0.1, locked = 0.0),
      list(asset = "USDT", free = 1000.0, locked = 50.0)
    )
  ))
}

#' Sub-account universal transfer response
#' @export
mock_sub_account_transfer_response <- function() {
  return(list(tranId = 11945860693, clientTranId = "test_transfer_001"))
}

#' Sub-account transfer history
#' @export
mock_sub_account_transfer_history_data <- function() {
  return(list(
    result = list(
      list(
        tranId = 11945860693,
        fromEmail = "master@test.com",
        toEmail = "testsub01@virtual.com",
        asset = "USDT",
        amount = "100.00000000",
        createTimeStamp = 1661493146000,
        fromAccountType = "SPOT",
        toAccountType = "SPOT",
        status = "SUCCESS",
        clientTranId = "test_001"
      )
    )
  ))
}

#' Sub-account status
#' @export
mock_sub_account_status_data <- function() {
  return(list(
    list(
      email = "testsub01@virtual.com",
      isSubUserEnabled = TRUE,
      isUserActive = TRUE,
      insertTime = 1661493146000,
      isMarginEnabled = FALSE,
      isFutureEnabled = FALSE,
      mobile = 0L
    )
  ))
}

# ---------------------------------------------------------------------------
# Earn fixtures
# ---------------------------------------------------------------------------

#' Flexible products
#' @export
mock_flexible_products_data <- function() {
  # Shape verified 2026-05-22 against the live docs; includes
  # `tierAnnualPercentageRate` — a nested object with DYNAMIC keys
  # (per-product size tiers). Parser serialises it as a JSON string
  # so the structure is preserved.
  return(list(
    total = 1L,
    rows = list(
      list(
        asset = "USDT",
        latestAnnualPercentageRate = "0.03250000",
        tierAnnualPercentageRate = list(
          "0-5BTC" = 0.05,
          "5-10BTC" = 0.03
        ),
        canPurchase = TRUE,
        canRedeem = TRUE,
        isSoldOut = FALSE,
        hot = TRUE,
        minPurchaseAmount = "0.10000000",
        productId = "USDT001",
        subscriptionStartTime = 1661493146000,
        status = "PURCHASING"
      )
    )
  ))
}

#' Locked products
#' Shape captured 2026-05-22 from
#' https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Simple-Earn-Locked-Product-List
#' — `detail.apr` (not `apy`), plus `isSoldOut`, `status`,
#' `subscriptionStartTime`, and the extra-reward / boost fields.
#' @export
mock_locked_products_data <- function() {
  return(list(
    total = 1L,
    rows = list(
      list(
        projectId = "BTC30d001",
        detail = list(
          asset = "BTC",
          rewardAsset = "BTC",
          duration = 30L,
          renewable = TRUE,
          isSoldOut = FALSE,
          apr = "0.05000000",
          status = "CREATED",
          subscriptionStartTime = 1646182276000,
          extraRewardAsset = "BNB",
          extraRewardAPR = "0.01000000",
          boostRewardAsset = "BTC",
          boostApr = "0.00100000",
          boostEndTime = 1646182276000
        ),
        quota = list(totalPersonalQuota = "10.00000000", minimum = "0.001")
      )
    )
  ))
}

#' Flexible subscription response
#' @export
mock_flexible_subscribe_response <- function() {
  return(list(purchaseId = 40607L, success = TRUE))
}

#' Locked subscription response
#' @export
mock_locked_subscribe_response <- function() {
  return(list(purchaseId = 40608L, positionId = "12345", success = TRUE))
}

#' Flexible redemption response
#' @export
mock_flexible_redeem_response <- function() {
  return(list(redeemId = 40609L, success = TRUE))
}

#' Locked redemption response
#' @export
mock_locked_redeem_response <- function() {
  return(list(redeemId = 40610L, success = TRUE))
}

#' Flexible position
#' @export
mock_flexible_position_data <- function() {
  return(list(
    total = 1L,
    rows = list(
      list(
        totalAmount = "100.00000000",
        tierAnnualPercentageRate = list(),
        latestAnnualPercentageRate = "0.03250000",
        yesterdayAirdropPercentageRate = "0.00008000",
        asset = "USDT",
        airDropAsset = "USDT",
        canRedeem = TRUE,
        collateralAmount = "0.00000000",
        productId = "USDT001",
        yesterdayRealTimeRewards = "0.00800000",
        cumulativeBonusRewards = "0.15000000",
        cumulativeRealTimeRewards = "0.08000000",
        cumulativeTotalRewards = "0.23000000",
        autoSubscribe = TRUE
      )
    )
  ))
}

#' Flexible subscription history
#' @export
mock_flexible_subscription_history_data <- function() {
  return(list(
    total = 1L,
    rows = list(
      list(
        amount = "100.00000000",
        asset = "USDT",
        time = 1661493146000,
        purchaseId = 40607L,
        type = "AUTO",
        sourceAccount = "SPOT",
        amountFromSpot = "100.00000000",
        amountFromFunding = "0.00000000",
        status = "SUCCESS"
      )
    )
  ))
}

# ---------------------------------------------------------------------------
# Margin fixtures
# ---------------------------------------------------------------------------

#' Margin borrow response
#' @export
mock_margin_borrow_response <- function() {
  return(list(tranId = 100000001L, clientTag = ""))
}

#' Margin order response
#' @export
mock_margin_order_response <- function() {
  return(list(
    symbol = "BTCUSDT",
    orderId = 28L,
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
    isIsolated = FALSE,
    selfTradePreventionMode = "NONE"
  ))
}

#' Margin cancel order response
#' @export
mock_margin_cancel_order_data <- function() {
  return(list(
    symbol = "BTCUSDT",
    origClientOrderId = "6gCrw2kRUAF9CvJDGP16IP",
    orderId = 28L,
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
    isIsolated = FALSE,
    selfTradePreventionMode = "NONE"
  ))
}

#' Margin query order response
#' @export
mock_margin_query_order_data <- function() {
  return(list(
    symbol = "BTCUSDT",
    orderId = 28L,
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
    isIsolated = FALSE,
    selfTradePreventionMode = "NONE"
  ))
}

#' Margin account response
#' @export
mock_margin_account_data <- function() {
  return(list(
    borrowEnabled = TRUE,
    marginLevel = "11.64405625",
    totalAssetOfBtc = "6.82000000",
    totalLiabilityOfBtc = "0.58633215",
    totalNetAssetOfBtc = "6.23366785",
    tradeEnabled = TRUE,
    transferEnabled = TRUE,
    accountType = "MARGIN",
    userAssets = list(
      list(
        asset = "BTC",
        borrowed = "0.00000000",
        free = "0.00499500",
        interest = "0.00000000",
        locked = "0.00000000",
        netAsset = "0.00499500"
      ),
      list(
        asset = "USDT",
        borrowed = "100.00000000",
        free = "200.00000000",
        interest = "0.01000000",
        locked = "0.00000000",
        netAsset = "99.99000000"
      )
    )
  ))
}

#' Max borrowable response
#' @export
mock_max_borrowable_data <- function() {
  return(list(amount = "1.69248805", borrowLimit = "60"))
}

#' Margin interest history
#' @export
mock_margin_interest_history_data <- function() {
  return(list(
    total = 1L,
    rows = list(
      list(
        txId = 1352286576452864727,
        interestAccuredTime = 1672160400000,
        asset = "USDT",
        rawAsset = "USDT",
        principal = "100.00000000",
        interest = "0.01000000",
        interestRate = "0.00010000",
        type = "ON_BORROW",
        isolatedSymbol = ""
      )
    )
  ))
}

#' Margin force liquidation history
#' @export
mock_margin_force_liquidation_data <- function() {
  return(list(
    total = 1L,
    rows = list(
      list(
        avgPrice = "67232.90000000",
        executedQty = "0.001",
        orderId = 12345L,
        price = "67000.00000000",
        qty = "0.001",
        side = "SELL",
        symbol = "BTCUSDT",
        timeInForce = "GTC",
        time = 1661493146000,
        updatedTime = 1661493146000,
        isIsolated = FALSE
      )
    )
  ))
}

#' Margin trades
#' @export
mock_margin_trades_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      id = 28457L,
      orderId = 100234L,
      price = "67232.90000000",
      qty = "0.00100000",
      quoteQty = "67.23290000",
      commission = "0.00000100",
      commissionAsset = "BTC",
      time = 1499865549590,
      isBuyer = TRUE,
      isMaker = FALSE,
      isBestMatch = TRUE,
      isIsolated = FALSE
    )
  ))
}

#' Isolated margin account
#' @export
mock_isolated_margin_account_data <- function() {
  return(list(
    totalAssetOfBtc = "0.00000000",
    totalLiabilityOfBtc = "0.00000000",
    totalNetAssetOfBtc = "0.00000000",
    assets = list(
      list(
        baseAsset = list(
          asset = "BTC",
          borrowEnabled = TRUE,
          borrowed = "0.00000000",
          free = "0.00000000",
          interest = "0.00000000",
          locked = "0.00000000",
          netAsset = "0.00000000",
          netAssetOfBtc = "0.00000000",
          repayEnabled = TRUE,
          totalAsset = "0.00000000"
        ),
        quoteAsset = list(
          asset = "USDT",
          borrowEnabled = TRUE,
          borrowed = "0.00000000",
          free = "0.00000000",
          interest = "0.00000000",
          locked = "0.00000000",
          netAsset = "0.00000000",
          netAssetOfBtc = "0.00000000",
          repayEnabled = TRUE,
          totalAsset = "0.00000000"
        ),
        symbol = "BTCUSDT",
        isolatedCreated = TRUE,
        enabled = TRUE,
        marginLevel = "0.00000000",
        marginLevelStatus = "EXCESSIVE",
        marginRatio = "0.00000000",
        indexPrice = "67232.90000000",
        liquidatePrice = "0.00000000",
        liquidateRate = "0.00000000",
        tradeEnabled = TRUE
      )
    )
  ))
}

#' Isolated transfer response
#' @export
mock_isolated_transfer_response <- function() {
  return(list(tranId = 100000001L))
}

# ---------------------------------------------------------------------------
# Futures Data fixtures
# ---------------------------------------------------------------------------

#' Futures exchange info
#' @export
mock_futures_exchange_info_data <- function() {
  return(list(
    timezone = "UTC",
    serverTime = 1499827319559,
    symbols = list(
      list(
        symbol = "BTCUSDT",
        pair = "BTCUSDT",
        contractType = "PERPETUAL",
        deliveryDate = 4133404800000,
        onboardDate = 1569398400000,
        status = "TRADING",
        baseAsset = "BTC",
        quoteAsset = "USDT",
        marginAsset = "USDT",
        pricePrecision = 2L,
        quantityPrecision = 3L,
        baseAssetPrecision = 8L,
        quotePrecision = 8L,
        underlyingType = "COIN",
        underlyingSubType = list("PoW"),
        settlePlan = 0L,
        triggerProtect = "0.0500",
        filters = list(list(filterType = "PRICE_FILTER", minPrice = "556.72", maxPrice = "4529764", tickSize = "0.01")),
        orderTypes = list(
          "LIMIT",
          "MARKET",
          "STOP",
          "STOP_MARKET",
          "TAKE_PROFIT",
          "TAKE_PROFIT_MARKET",
          "TRAILING_STOP_MARKET"
        ),
        timeInForce = list("GTC", "IOC", "FOK", "GTX", "GTD")
      )
    )
  ))
}

#' Futures mark price
#' @export
mock_futures_mark_price_data <- function() {
  return(list(
    symbol = "BTCUSDT",
    markPrice = "67232.90000000",
    indexPrice = "67230.50000000",
    estimatedSettlePrice = "67231.70000000",
    lastFundingRate = "0.00010000",
    nextFundingTime = 1661493600000,
    interestRate = "0.00010000",
    time = 1661493146000
  ))
}

#' Futures funding rate history
#' @export
mock_futures_funding_rate_data <- function() {
  return(list(
    list(symbol = "BTCUSDT", fundingRate = "0.00010000", fundingTime = 1661493600000, markPrice = "67232.90000000"),
    list(symbol = "BTCUSDT", fundingRate = "0.00012000", fundingTime = 1661522400000, markPrice = "67500.00000000")
  ))
}

#' Futures open interest
#' @export
mock_futures_open_interest_data <- function() {
  return(list(symbol = "BTCUSDT", openInterest = "12345.678", time = 1661493146000))
}

#' Futures ticker
#' @export
mock_futures_ticker_data <- function() {
  return(list(symbol = "BTCUSDT", price = "67232.90000000", time = 1661493146000))
}

# ---------------------------------------------------------------------------
# Futures Trading fixtures
# ---------------------------------------------------------------------------

#' Futures order response
#' @export
mock_futures_order_response <- function() {
  return(list(
    orderId = 283194212L,
    symbol = "BTCUSDT",
    status = "NEW",
    clientOrderId = "test_futures_order",
    price = "50000.00",
    avgPrice = "0.00",
    origQty = "0.001",
    executedQty = "0.000",
    cumQuote = "0.00",
    timeInForce = "GTC",
    type = "LIMIT",
    reduceOnly = FALSE,
    closePosition = FALSE,
    side = "BUY",
    positionSide = "BOTH",
    stopPrice = "0.00",
    workingType = "CONTRACT_PRICE",
    origType = "LIMIT",
    priceMatch = "NONE",
    selfTradePreventionMode = "NONE",
    goodTillDate = 0L,
    updateTime = 1661493146000
  ))
}

#' Futures cancel all response
#' @export
mock_futures_cancel_all_response <- function() {
  return(list(code = 200L, msg = "The operation of cancel all open order is done."))
}

#' Futures account
#' @export
mock_futures_account_data <- function() {
  return(list(
    feeTier = 0L,
    canTrade = TRUE,
    canDeposit = TRUE,
    canWithdraw = TRUE,
    updateTime = 0L,
    multiAssetsMargin = FALSE,
    totalInitialMargin = "0.00000000",
    totalMaintMargin = "0.00000000",
    totalWalletBalance = "1000.00000000",
    totalUnrealizedProfit = "0.00000000",
    totalMarginBalance = "1000.00000000",
    totalPositionInitialMargin = "0.00000000",
    totalOpenOrderInitialMargin = "0.00000000",
    totalCrossWalletBalance = "1000.00000000",
    totalCrossUnPnl = "0.00000000",
    availableBalance = "1000.00000000",
    maxWithdrawAmount = "1000.00000000",
    assets = list(
      list(
        asset = "USDT",
        walletBalance = "1000.00000000",
        unrealizedProfit = "0.00000000",
        marginBalance = "1000.00000000",
        maintMargin = "0.00000000",
        initialMargin = "0.00000000",
        positionInitialMargin = "0.00000000",
        openOrderInitialMargin = "0.00000000",
        crossWalletBalance = "1000.00000000",
        crossUnPnl = "0.00000000",
        availableBalance = "1000.00000000",
        maxWithdrawAmount = "1000.00000000",
        marginAvailable = TRUE,
        updateTime = 0L
      )
    ),
    positions = list(
      list(
        symbol = "BTCUSDT",
        initialMargin = "0",
        maintMargin = "0",
        unrealizedProfit = "0.00000000",
        positionInitialMargin = "0",
        openOrderInitialMargin = "0",
        leverage = "20",
        isolated = FALSE,
        entryPrice = "0.0",
        breakEvenPrice = "0.0",
        maxNotional = "25000000",
        positionSide = "BOTH",
        positionAmt = "0.000",
        notional = "0",
        isolatedWallet = "0",
        updateTime = 0L,
        bidNotional = "0",
        askNotional = "0"
      )
    )
  ))
}

#' Futures balances
#' @export
mock_futures_balances_data <- function() {
  return(list(
    list(
      accountAlias = "SgsR",
      asset = "USDT",
      balance = "1000.00000000",
      crossWalletBalance = "1000.00000000",
      crossUnPnl = "0.00000000",
      availableBalance = "1000.00000000",
      maxWithdrawAmount = "1000.00000000",
      marginAvailable = TRUE,
      updateTime = 1661493146000
    )
  ))
}

#' Futures positions
#' @export
mock_futures_positions_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      positionAmt = "0.001",
      entryPrice = "50000.00",
      breakEvenPrice = "50025.00",
      markPrice = "67232.90",
      unRealizedProfit = "17.23290000",
      liquidationPrice = "0",
      leverage = "20",
      maxNotionalValue = "25000000",
      marginType = "cross",
      isolatedMargin = "0.00000000",
      isAutoAddMargin = "false",
      positionSide = "BOTH",
      notional = "67.23290000",
      isolatedWallet = "0",
      updateTime = 1661493146000
    )
  ))
}

#' Futures leverage response
#' @export
mock_futures_leverage_response <- function() {
  return(list(leverage = 20L, maxNotionalValue = "25000000", symbol = "BTCUSDT"))
}

#' Futures margin type response
#' @export
mock_futures_margin_type_response <- function() {
  return(list(code = 200L, msg = "success"))
}

#' Futures trades
#' @export
mock_futures_trades_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      id = 100001L,
      orderId = 283194212L,
      side = "BUY",
      price = "50000.00",
      qty = "0.001",
      realizedPnl = "0.00000000",
      marginAsset = "USDT",
      quoteQty = "50.00000000",
      commission = "0.02000000",
      commissionAsset = "USDT",
      time = 1661493146000,
      positionSide = "BOTH",
      buyer = TRUE,
      maker = FALSE
    )
  ))
}

#' Futures income history
#' @export
mock_futures_income_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      incomeType = "FUNDING_FEE",
      income = "-0.01200000",
      asset = "USDT",
      info = "",
      time = 1661493146000,
      tranId = 100000001L,
      tradeId = ""
    )
  ))
}

#' Futures position mode
#' @export
mock_futures_position_mode_data <- function() {
  return(list(dualSidePosition = FALSE))
}

# ---- Mocks added to close 8 untested-method gaps in TRADE-20 ----

#' Margin max transferable response
#' Shape from https://developers.binance.com/docs/margin_trading/transfer/Query-Max-Transfer-Out-Amount
#' @export
mock_margin_max_transferable_data <- function() {
  return(list(amount = "3.59498107", borrowLimit = "10000"))
}

#' Futures position-margin modify response
#' Shape from https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Modify-Isolated-Position-Margin
#' @export
mock_futures_modify_position_margin_response <- function() {
  return(list(
    amount = 100.0,
    code = 200L,
    msg = "Successfully modify position margin.",
    type = 1L
  ))
}

#' Futures position-margin history response
#' Shape from https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Get-Position-Margin-Change-History
#' @export
mock_futures_position_margin_history_data <- function() {
  return(list(
    list(
      symbol = "BTCUSDT",
      type = 1L,
      deltaType = "INCREASE_MARGIN",
      amount = "100.00000000",
      asset = "USDT",
      time = 1710000000000,
      positionSide = "BOTH"
    )
  ))
}
