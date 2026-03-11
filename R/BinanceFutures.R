# File: R/BinanceFutures.R
# R6 class for Binance USD-M Futures trading.

#' BinanceFutures: USD-M Futures Trading
#'
#' Provides methods for placing, cancelling, and querying USD-M futures orders,
#' managing positions, leverage, and margin on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Order Management**: Place, cancel, and query futures orders.
#' - **Position Management**: View positions, set leverage, margin type, and position mode.
#' - **Account Queries**: Retrieve account info, balances, trades, and income history.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#' The base URL defaults to `https://fapi.binance.com` via [get_futures_base_url()].
#'
#' ### Official Documentation
#' [Binance Futures API](https://binance-docs.github.io/apidocs/futures/en/)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_order | POST /fapi/v1/order | POST |
#' | add_order_test | POST /fapi/v1/order/test | POST |
#' | cancel_order | DELETE /fapi/v1/order | DELETE |
#' | cancel_all_orders | DELETE /fapi/v1/allOpenOrders | DELETE |
#' | get_order | GET /fapi/v1/order | GET |
#' | get_open_orders | GET /fapi/v1/openOrders | GET |
#' | get_all_orders | GET /fapi/v1/allOrders | GET |
#' | get_account | GET /fapi/v2/account | GET |
#' | get_balances | GET /fapi/v2/balance | GET |
#' | get_positions | GET /fapi/v2/positionRisk | GET |
#' | set_leverage | POST /fapi/v1/leverage | POST |
#' | set_margin_type | POST /fapi/v1/marginType | POST |
#' | modify_position_margin | POST /fapi/v1/positionMargin | POST |
#' | get_position_margin_history | GET /fapi/v1/positionMargin/history | GET |
#' | get_trades | GET /fapi/v1/userTrades | GET |
#' | get_income_history | GET /fapi/v1/income | GET |
#' | set_position_mode | POST /fapi/v1/positionSide/dual | POST |
#' | get_position_mode | GET /fapi/v1/positionSide/dual | GET |
#'
#' @section Order Types:
#' - `"LIMIT"`: requires `price`, `quantity`, `timeInForce`.
#' - `"MARKET"`: requires `quantity`.
#' - `"STOP"`, `"STOP_MARKET"`: conditional stop orders.
#' - `"TAKE_PROFIT"`, `"TAKE_PROFIT_MARKET"`: conditional take-profit orders.
#' - `"TRAILING_STOP_MARKET"`: trailing stop order.
#'
#' @section Position Sides:
#' - `"BOTH"`: One-way mode (default).
#' - `"LONG"`, `"SHORT"`: Hedge mode.
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' futures <- BinanceFutures$new()
#' order <- futures$add_order(
#'   symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
#'   quantity = 0.001, price = 50000, timeInForce = "GTC"
#' )
#' print(order)
#'
#' # Asynchronous
#' futures_async <- BinanceFutures$new(async = TRUE)
#' main <- coro::async(function() {
#'   order <- await(futures_async$add_order(
#'     symbol = "BTCUSDT", side = "BUY", type = "MARKET",
#'     quantity = 0.001
#'   ))
#'   print(order)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceFutures <- R6::R6Class(
  "BinanceFutures",
  inherit = BinanceBase,
  public = list(
    #' @description
    #' Initialise a BinanceFutures Object
    #'
    #' Overrides the base constructor to use the futures base URL and
    #' the futures-specific server time endpoint (`/fapi/v1/time`).
    #'
    #' @param keys List; API credentials from [get_api_keys()].
    #' @param base_url Character; API base URL. Defaults to [get_futures_base_url()].
    #' @param async Logical; if `TRUE`, methods return promises. Default `FALSE`.
    #' @param time_source Character; clock source for HMAC request signing.
    #'   `"local"` (default) uses `Sys.time()`. `"server"` fetches the Binance
    #'   Futures server time before each authenticated request.
    #' @return Invisible self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      if (match.arg(time_source) == "server") {
        super$initialize(keys = keys, base_url = base_url, async = async, time_source = "local")
        url <- base_url
        private$.time_source <- "server"
        private$.get_timestamp_ms <- function() fetch_server_time_ms(url, "/fapi/v1/time")
      } else {
        super$initialize(keys = keys, base_url = base_url, async = async, time_source = time_source)
      }
    },

    # ---- Order Placement ----

    #' @description
    #' Place a Futures Order
    #'
    #' Places a new USD-M futures order on Binance.
    #'
    #' ### API Endpoint
    #' `POST https://fapi.binance.com/fapi/v1/order`
    #'
    #' ### Official Documentation
    #' [Binance Futures New Order](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/New-Order)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://fapi.binance.com/fapi/v1/order' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=0.001&price=50000&timeInForce=GTC&timestamp=1710000000000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "side": "BUY",
    #'   "type": "LIMIT",
    #'   "quantity": "0.001",
    #'   "price": "50000",
    #'   "timeInForce": "GTC",
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "orderId": 283194212,
    #'   "symbol": "BTCUSDT",
    #'   "status": "NEW",
    #'   "clientOrderId": "x-HNA2TXFJ1710000000",
    #'   "price": "50000.00",
    #'   "avgPrice": "0.00",
    #'   "origQty": "0.001",
    #'   "executedQty": "0.000",
    #'   "cumQty": "0.000",
    #'   "cumQuote": "0.00000",
    #'   "timeInForce": "GTC",
    #'   "type": "LIMIT",
    #'   "reduceOnly": false,
    #'   "closePosition": false,
    #'   "side": "BUY",
    #'   "positionSide": "BOTH",
    #'   "stopPrice": "0.00",
    #'   "workingType": "CONTRACT_PRICE",
    #'   "priceProtect": false,
    #'   "origType": "LIMIT",
    #'   "updateTime": 1710000000123
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param side Character; `"BUY"` or `"SELL"`.
    #' @param type Character; order type: `"LIMIT"`, `"MARKET"`, `"STOP"`,
    #'   `"STOP_MARKET"`, `"TAKE_PROFIT"`, `"TAKE_PROFIT_MARKET"`,
    #'   `"TRAILING_STOP_MARKET"`.
    #' @param quantity Numeric or NULL; order quantity.
    #' @param price Numeric or NULL; price for limit orders.
    #' @param stopPrice Numeric or NULL; trigger price for stop orders.
    #' @param timeInForce Character or NULL; `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param positionSide Character or NULL; `"BOTH"`, `"LONG"`, `"SHORT"`.
    #' @param reduceOnly Logical or NULL; reduce-only flag.
    #' @param newClientOrderId Character or NULL; unique client order ID.
    #' @param closePosition Logical or NULL; close all position flag.
    #' @param workingType Character or NULL; `"MARK_PRICE"` or `"CONTRACT_PRICE"`.
    #' @param newOrderRespType Character or NULL; `"ACK"`, `"RESULT"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `symbol` (character): Trading pair (e.g., `"BTCUSDT"`).
    #' - `order_id` (integer): Unique order identifier.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `cum_qty` (character): Cumulative filled quantity.
    #' - `cum_quote` (character): Cumulative quote asset transacted.
    #' - `status` (character): Order status (`"NEW"`, `"FILLED"`, `"CANCELED"`, etc.).
    #' - `time_in_force` (character): Time-in-force policy.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `position_side` (character): Position side (`"BOTH"`, `"LONG"`, `"SHORT"`).
    #' - `update_time` (POSIXct): Last update time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' order <- futures$add_order(
    #'   symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
    #'   quantity = 0.001, price = 50000, timeInForce = "GTC"
    #' )
    #' print(order)
    #' }
    add_order = function(
      symbol,
      side,
      type,
      quantity = NULL,
      price = NULL,
      stopPrice = NULL,
      timeInForce = NULL,
      positionSide = NULL,
      reduceOnly = NULL,
      newClientOrderId = NULL,
      closePosition = NULL,
      workingType = NULL,
      newOrderRespType = NULL,
      recvWindow = NULL
    ) {
      side <- toupper(side)
      type <- toupper(type)
      rlang::arg_match0(side, c("BUY", "SELL"))
      rlang::arg_match0(
        type,
        c("LIMIT", "MARKET", "STOP", "STOP_MARKET", "TAKE_PROFIT", "TAKE_PROFIT_MARKET", "TRAILING_STOP_MARKET")
      )

      if (!is.null(positionSide)) {
        positionSide <- toupper(positionSide)
        rlang::arg_match0(positionSide, c("BOTH", "LONG", "SHORT"))
      }
      if (!is.null(workingType)) {
        workingType <- toupper(workingType)
        rlang::arg_match0(workingType, c("MARK_PRICE", "CONTRACT_PRICE"))
      }

      if (!is.null(price)) {
        price <- as.character(price)
      }
      if (!is.null(quantity)) {
        quantity <- as.character(quantity)
      }
      if (!is.null(stopPrice)) {
        stopPrice <- as.character(stopPrice)
      }
      if (!is.null(reduceOnly)) {
        reduceOnly <- tolower(as.character(reduceOnly))
      }
      if (!is.null(closePosition)) {
        closePosition <- tolower(as.character(closePosition))
      }

      body <- list(
        symbol = symbol,
        side = side,
        type = type,
        quantity = quantity,
        price = price,
        stopPrice = stopPrice,
        timeInForce = timeInForce,
        positionSide = positionSide,
        reduceOnly = reduceOnly,
        newClientOrderId = newClientOrderId,
        closePosition = closePosition,
        workingType = workingType,
        newOrderRespType = newOrderRespType,
        recvWindow = recvWindow
      )
      body <- body[!vapply(body, is.null, logical(1))]

      return(private$.request(
        endpoint = "/fapi/v1/order",
        method = "POST",
        body = body,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "update_time" %in% names(dt)) {
            dt[, update_time := ms_to_datetime(update_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Test Futures Order Placement
    #'
    #' Simulates placing a futures order without execution. Validates all parameters
    #' and authentication exactly as `add_order()`, but no order is actually created.
    #'
    #' ### API Endpoint
    #' `POST https://fapi.binance.com/fapi/v1/order/test`
    #'
    #' ### Official Documentation
    #' [Binance Futures New Order Test](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/New-Order-Test)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://fapi.binance.com/fapi/v1/order/test' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=0.001&price=50000&timeInForce=GTC&timestamp=1710000000000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "side": "BUY",
    #'   "type": "LIMIT",
    #'   "quantity": "0.001",
    #'   "price": "50000",
    #'   "timeInForce": "GTC",
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {}
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param side Character; `"BUY"` or `"SELL"`.
    #' @param type Character; order type.
    #' @param quantity Numeric or NULL; order quantity.
    #' @param price Numeric or NULL; price for limit orders.
    #' @param stopPrice Numeric or NULL; trigger price for stop orders.
    #' @param timeInForce Character or NULL; `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param positionSide Character or NULL; `"BOTH"`, `"LONG"`, `"SHORT"`.
    #' @param reduceOnly Logical or NULL; reduce-only flag.
    #' @param newClientOrderId Character or NULL; unique client order ID.
    #' @param closePosition Logical or NULL; close all position flag.
    #' @param workingType Character or NULL; `"MARK_PRICE"` or `"CONTRACT_PRICE"`.
    #' @param newOrderRespType Character or NULL; `"ACK"`, `"RESULT"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`), single row with columns:
    #'   - `symbol` (character): The validated trading pair.
    #'   - `side` (character): `"BUY"` or `"SELL"`.
    #'   - `type` (character): Order type.
    #'   - `status` (character): `"validated"`.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' test <- futures$add_order_test(
    #'   symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
    #'   quantity = 0.001, price = 50000, timeInForce = "GTC"
    #' )
    #' print(test)
    #' }
    add_order_test = function(
      symbol,
      side,
      type,
      quantity = NULL,
      price = NULL,
      stopPrice = NULL,
      timeInForce = NULL,
      positionSide = NULL,
      reduceOnly = NULL,
      newClientOrderId = NULL,
      closePosition = NULL,
      workingType = NULL,
      newOrderRespType = NULL,
      recvWindow = NULL
    ) {
      side <- toupper(side)
      type <- toupper(type)
      rlang::arg_match0(side, c("BUY", "SELL"))
      rlang::arg_match0(
        type,
        c("LIMIT", "MARKET", "STOP", "STOP_MARKET", "TAKE_PROFIT", "TAKE_PROFIT_MARKET", "TRAILING_STOP_MARKET")
      )

      if (!is.null(positionSide)) {
        positionSide <- toupper(positionSide)
        rlang::arg_match0(positionSide, c("BOTH", "LONG", "SHORT"))
      }
      if (!is.null(workingType)) {
        workingType <- toupper(workingType)
        rlang::arg_match0(workingType, c("MARK_PRICE", "CONTRACT_PRICE"))
      }

      if (!is.null(price)) {
        price <- as.character(price)
      }
      if (!is.null(quantity)) {
        quantity <- as.character(quantity)
      }
      if (!is.null(stopPrice)) {
        stopPrice <- as.character(stopPrice)
      }
      if (!is.null(reduceOnly)) {
        reduceOnly <- tolower(as.character(reduceOnly))
      }
      if (!is.null(closePosition)) {
        closePosition <- tolower(as.character(closePosition))
      }

      body <- list(
        symbol = symbol,
        side = side,
        type = type,
        quantity = quantity,
        price = price,
        stopPrice = stopPrice,
        timeInForce = timeInForce,
        positionSide = positionSide,
        reduceOnly = reduceOnly,
        newClientOrderId = newClientOrderId,
        closePosition = closePosition,
        workingType = workingType,
        newOrderRespType = newOrderRespType,
        recvWindow = recvWindow
      )
      body <- body[!vapply(body, is.null, logical(1))]

      return(private$.request(
        endpoint = "/fapi/v1/order/test",
        method = "POST",
        body = body,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table(
              symbol = symbol,
              side = side,
              type = type,
              status = "validated"
            )[])
          }
          return(as_dt_row(data)[])
        }
      ))
    },

    # ---- Order Cancellation ----

    #' @description
    #' Cancel a Futures Order
    #'
    #' Cancels an active futures order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://fapi.binance.com/fapi/v1/order`
    #'
    #' ### Official Documentation
    #' [Binance Futures Cancel Order](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Cancel-Order)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE 'https://fapi.binance.com/fapi/v1/order?symbol=BTCUSDT&orderId=283194212&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "orderId": 283194212,
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "orderId": 283194212,
    #'   "symbol": "BTCUSDT",
    #'   "status": "CANCELED",
    #'   "clientOrderId": "x-HNA2TXFJ1710000000",
    #'   "price": "50000.00",
    #'   "origQty": "0.001",
    #'   "executedQty": "0.000",
    #'   "cumQty": "0.000",
    #'   "cumQuote": "0.00000",
    #'   "timeInForce": "GTC",
    #'   "type": "LIMIT",
    #'   "reduceOnly": false,
    #'   "closePosition": false,
    #'   "side": "BUY",
    #'   "positionSide": "BOTH",
    #'   "stopPrice": "0.00",
    #'   "workingType": "CONTRACT_PRICE",
    #'   "origType": "LIMIT",
    #'   "updateTime": 1710000005678
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; the order ID to cancel.
    #' @param origClientOrderId Character or NULL; the client order ID to cancel.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `status` (character): Order status (typically `"CANCELED"`).
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `update_time` (POSIXct): Cancellation time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' cancelled <- futures$cancel_order("BTCUSDT", orderId = 283194212)
    #' print(cancelled)
    #' }
    cancel_order = function(symbol, orderId = NULL, origClientOrderId = NULL, recvWindow = NULL) {
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      return(private$.request(
        endpoint = "/fapi/v1/order",
        method = "DELETE",
        query = list(
          symbol = symbol,
          orderId = orderId,
          origClientOrderId = origClientOrderId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "update_time" %in% names(dt)) {
            dt[, update_time := ms_to_datetime(update_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Cancel All Open Futures Orders
    #'
    #' Cancels all active futures orders on a trading pair.
    #'
    #' ### API Endpoint
    #' `DELETE https://fapi.binance.com/fapi/v1/allOpenOrders`
    #'
    #' ### Official Documentation
    #' [Binance Futures Cancel All Open Orders](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Cancel-All-Open-Orders)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE 'https://fapi.binance.com/fapi/v1/allOpenOrders?symbol=BTCUSDT&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": 200,
    #'   "msg": "The operation of cancel all open order is done."
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `code` (integer): Response code (`200` on success).
    #' - `msg` (character): Response message.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' result <- futures$cancel_all_orders("BTCUSDT")
    #' print(result)
    #' }
    cancel_all_orders = function(symbol, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/fapi/v1/allOpenOrders",
        method = "DELETE",
        query = list(symbol = symbol, recvWindow = recvWindow),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    # ---- Order Queries ----

    #' @description
    #' Query a Futures Order
    #'
    #' Retrieves details for a specific futures order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/order`
    #'
    #' ### Official Documentation
    #' [Binance Futures Query Order](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Query-Order)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/order?symbol=BTCUSDT&orderId=283194212&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "orderId": 283194212,
    #'   "symbol": "BTCUSDT",
    #'   "status": "NEW",
    #'   "clientOrderId": "x-HNA2TXFJ1710000000",
    #'   "price": "50000.00",
    #'   "avgPrice": "0.00",
    #'   "origQty": "0.001",
    #'   "executedQty": "0.000",
    #'   "cumQuote": "0.00000",
    #'   "timeInForce": "GTC",
    #'   "type": "LIMIT",
    #'   "reduceOnly": false,
    #'   "closePosition": false,
    #'   "side": "BUY",
    #'   "positionSide": "BOTH",
    #'   "stopPrice": "0.00",
    #'   "workingType": "CONTRACT_PRICE",
    #'   "origType": "LIMIT",
    #'   "time": 1710000000123,
    #'   "updateTime": 1710000000123
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; the order ID.
    #' @param origClientOrderId Character or NULL; the client order ID.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `cum_quote` (character): Cumulative quote asset transacted.
    #' - `status` (character): Order status.
    #' - `time_in_force` (character): Time-in-force policy.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `position_side` (character): Position side.
    #' - `time` (POSIXct): Order creation time.
    #' - `update_time` (POSIXct): Last update time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' order <- futures$get_order("BTCUSDT", orderId = 283194212)
    #' print(order)
    #' }
    get_order = function(symbol, orderId = NULL, origClientOrderId = NULL, recvWindow = NULL) {
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      return(private$.request(
        endpoint = "/fapi/v1/order",
        query = list(
          symbol = symbol,
          orderId = orderId,
          origClientOrderId = origClientOrderId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          if (nrow(dt) > 0 && "update_time" %in% names(dt)) {
            dt[, update_time := ms_to_datetime(update_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Open Futures Orders
    #'
    #' Retrieves all currently open futures orders, optionally filtered by symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/openOrders`
    #'
    #' ### Official Documentation
    #' [Binance Futures Current Open Orders](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Current-All-Open-Orders)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/openOrders?symbol=BTCUSDT&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "orderId": 283194212,
    #'     "symbol": "BTCUSDT",
    #'     "status": "NEW",
    #'     "clientOrderId": "x-HNA2TXFJ1710000000",
    #'     "price": "50000.00",
    #'     "avgPrice": "0.00",
    #'     "origQty": "0.001",
    #'     "executedQty": "0.000",
    #'     "cumQuote": "0.00000",
    #'     "timeInForce": "GTC",
    #'     "type": "LIMIT",
    #'     "reduceOnly": false,
    #'     "closePosition": false,
    #'     "side": "BUY",
    #'     "positionSide": "BOTH",
    #'     "stopPrice": "0.00",
    #'     "workingType": "CONTRACT_PRICE",
    #'     "origType": "LIMIT",
    #'     "time": 1710000000123,
    #'     "updateTime": 1710000000123
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per open order and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `status` (character): Order status.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `position_side` (character): Position side.
    #' - `time` (POSIXct): Order creation time.
    #' - `update_time` (POSIXct): Last update time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' open <- futures$get_open_orders("BTCUSDT")
    #' print(open)
    #' }
    get_open_orders = function(symbol = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/fapi/v1/openOrders",
        query = list(symbol = symbol, recvWindow = recvWindow),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          if (nrow(dt) > 0 && "update_time" %in% names(dt)) {
            dt[, update_time := ms_to_datetime(update_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get All Futures Orders
    #'
    #' Retrieves all futures orders for a symbol (open, cancelled, filled).
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/allOrders`
    #'
    #' ### Official Documentation
    #' [Binance Futures All Orders](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/All-Orders)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/allOrders?symbol=BTCUSDT&limit=50&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "orderId": 283194212,
    #'     "symbol": "BTCUSDT",
    #'     "status": "FILLED",
    #'     "clientOrderId": "x-HNA2TXFJ1710000000",
    #'     "price": "50000.00",
    #'     "avgPrice": "50000.00",
    #'     "origQty": "0.001",
    #'     "executedQty": "0.001",
    #'     "cumQuote": "50.00000",
    #'     "timeInForce": "GTC",
    #'     "type": "LIMIT",
    #'     "reduceOnly": false,
    #'     "closePosition": false,
    #'     "side": "BUY",
    #'     "positionSide": "BOTH",
    #'     "stopPrice": "0.00",
    #'     "workingType": "CONTRACT_PRICE",
    #'     "origType": "LIMIT",
    #'     "time": 1710000000123,
    #'     "updateTime": 1710000001234
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; pagination cursor.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param limit Integer or NULL; max results (default 500, max 1000).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per order and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `status` (character): Order status.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `position_side` (character): Position side.
    #' - `time` (POSIXct): Order creation time.
    #' - `update_time` (POSIXct): Last update time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' all <- futures$get_all_orders("BTCUSDT", limit = 50)
    #' print(all)
    #' }
    get_all_orders = function(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/fapi/v1/allOrders",
        query = list(
          symbol = symbol,
          orderId = orderId,
          startTime = startTime,
          endTime = endTime,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          if (nrow(dt) > 0 && "update_time" %in% names(dt)) {
            dt[, update_time := ms_to_datetime(update_time)]
          }
          return(dt[])
        }
      ))
    },

    # ---- Account ----

    #' @description
    #' Get Futures Account Information
    #'
    #' Retrieves comprehensive futures account information including balances
    #' and positions (kept as list columns).
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v2/account`
    #'
    #' ### Official Documentation
    #' [Binance Futures Account Information V2](https://developers.binance.com/docs/derivatives/usds-margined-futures/account/rest-api/Account-Information-V2)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v2/account?timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "feeTier": 0,
    #'   "canTrade": true,
    #'   "canDeposit": true,
    #'   "canWithdraw": true,
    #'   "updateTime": 0,
    #'   "multiAssetsMargin": false,
    #'   "totalInitialMargin": "0.00000000",
    #'   "totalMaintMargin": "0.00000000",
    #'   "totalWalletBalance": "1500.00000000",
    #'   "totalUnrealizedProfit": "23.45000000",
    #'   "totalMarginBalance": "1523.45000000",
    #'   "totalPositionInitialMargin": "0.00000000",
    #'   "totalOpenOrderInitialMargin": "0.00000000",
    #'   "totalCrossWalletBalance": "1500.00000000",
    #'   "totalCrossUnPnl": "23.45000000",
    #'   "availableBalance": "1500.00000000",
    #'   "maxWithdrawAmount": "1500.00000000",
    #'   "assets": [
    #'     {
    #'       "asset": "USDT",
    #'       "walletBalance": "1500.00000000",
    #'       "unrealizedProfit": "23.45000000",
    #'       "marginBalance": "1523.45000000",
    #'       "maintMargin": "0.00000000",
    #'       "initialMargin": "0.00000000",
    #'       "positionInitialMargin": "0.00000000",
    #'       "openOrderInitialMargin": "0.00000000",
    #'       "crossWalletBalance": "1500.00000000",
    #'       "crossUnPnl": "23.45000000",
    #'       "availableBalance": "1500.00000000",
    #'       "maxWithdrawAmount": "1500.00000000",
    #'       "marginAvailable": true,
    #'       "updateTime": 1710000000000
    #'     }
    #'   ],
    #'   "positions": [
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "initialMargin": "0",
    #'       "maintMargin": "0",
    #'       "unrealizedProfit": "0.00000000",
    #'       "positionInitialMargin": "0",
    #'       "openOrderInitialMargin": "0",
    #'       "leverage": "20",
    #'       "isolated": false,
    #'       "entryPrice": "0.0",
    #'       "maxNotional": "250000",
    #'       "positionSide": "BOTH",
    #'       "positionAmt": "0.000",
    #'       "notional": "0",
    #'       "isolatedWallet": "0",
    #'       "updateTime": 0
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `fee_tier` (integer): Commission fee tier.
    #' - `can_trade` (logical): Whether trading is permitted.
    #' - `can_deposit` (logical): Whether deposits are permitted.
    #' - `can_withdraw` (logical): Whether withdrawals are permitted.
    #' - `total_initial_margin` (character): Total initial margin required.
    #' - `total_maint_margin` (character): Total maintenance margin required.
    #' - `total_wallet_balance` (character): Total wallet balance.
    #' - `total_unrealized_profit` (character): Total unrealised PnL.
    #' - `total_margin_balance` (character): Total margin balance.
    #' - `total_cross_wallet_balance` (character): Total cross-wallet balance.
    #' - `available_balance` (character): Available balance for new positions.
    #' - `max_withdraw_amount` (character): Maximum withdrawable amount.
    #' - `asset_name` (character): Per-asset name (one row per asset, expanded from `assets`).
    #' - `asset_wallet_balance` (character): Per-asset wallet balance.
    #' - `asset_unrealized_profit` (character): Per-asset unrealised PnL.
    #' - `asset_margin_balance` (character): Per-asset margin balance.
    #' - `asset_available_balance` (character): Per-asset available balance.
    #' - `positions` (list): Nested list of per-symbol position details (kept as list-column).
    #'
    #' When the account has multiple assets, account-level fields are repeated on each row.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' account <- futures$get_account()
    #' print(account)
    #' }
    get_account = function(recvWindow = NULL) {
      return(private$.request(
        endpoint = "/fapi/v2/account",
        query = list(recvWindow = recvWindow),
        .parser = function(data) {
          assets <- data$assets
          data$assets <- NULL
          dt <- as_dt_row(data)
          # Expand assets to long format: one row per asset
          if (!is.null(assets) && length(assets) > 0) {
            assets_dt <- as_dt_list(assets)
            # Prefix asset columns to avoid collision with parent account columns
            asset_names <- names(assets_dt)
            data.table::setnames(assets_dt, asset_names, paste0("asset_", asset_names))
            dt <- dt[rep(1L, nrow(assets_dt))]
            dt <- cbind(dt, assets_dt)
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Futures Account Balances
    #'
    #' Retrieves all asset balances for the futures account.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v2/balance`
    #'
    #' ### Official Documentation
    #' [Binance Futures Account Balance V2](https://developers.binance.com/docs/derivatives/usds-margined-futures/account/rest-api/Futures-Account-Balance-V2)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v2/balance?timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "accountAlias": "SgsR",
    #'     "asset": "USDT",
    #'     "balance": "1500.00000000",
    #'     "crossWalletBalance": "1500.00000000",
    #'     "crossUnPnl": "23.45000000",
    #'     "availableBalance": "1476.55000000",
    #'     "maxWithdrawAmount": "1476.55000000",
    #'     "marginAvailable": true,
    #'     "updateTime": 1710000000000
    #'   },
    #'   {
    #'     "accountAlias": "SgsR",
    #'     "asset": "BNB",
    #'     "balance": "0.50000000",
    #'     "crossWalletBalance": "0.50000000",
    #'     "crossUnPnl": "0.00000000",
    #'     "availableBalance": "0.50000000",
    #'     "maxWithdrawAmount": "0.50000000",
    #'     "marginAvailable": true,
    #'     "updateTime": 1710000000000
    #'   }
    #' ]
    #' ```
    #'
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per asset and the following columns:
    #' - `account_alias` (character): Account alias (e.g., `"SgsR"`).
    #' - `asset` (character): Asset symbol (e.g., `"USDT"`).
    #' - `balance` (character): Wallet balance.
    #' - `cross_wallet_balance` (character): Cross-wallet balance.
    #' - `cross_un_pnl` (character): Unrealised PnL from cross positions.
    #' - `available_balance` (character): Available balance.
    #' - `max_withdraw_amount` (character): Maximum withdrawable amount.
    #' - `margin_available` (logical): Whether margin is available.
    #' - `update_time` (POSIXct): Last balance update time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' balances <- futures$get_balances()
    #' print(balances)
    #' }
    get_balances = function(recvWindow = NULL) {
      return(private$.request(
        endpoint = "/fapi/v2/balance",
        query = list(recvWindow = recvWindow),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "update_time" %in% names(dt)) {
            dt[, update_time := ms_to_datetime(update_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Futures Position Information
    #'
    #' Retrieves position risk information, optionally filtered by symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v2/positionRisk`
    #'
    #' ### Official Documentation
    #' [Binance Futures Position Information V2](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Position-Information-V2)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v2/positionRisk?symbol=BTCUSDT&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "positionAmt": "0.001",
    #'     "entryPrice": "50000.0",
    #'     "markPrice": "51234.56000000",
    #'     "unRealizedProfit": "1.23456000",
    #'     "liquidationPrice": "25123.45678901",
    #'     "leverage": "20",
    #'     "maxNotionalValue": "250000",
    #'     "marginType": "cross",
    #'     "isolatedMargin": "0.00000000",
    #'     "isAutoAddMargin": "false",
    #'     "positionSide": "BOTH",
    #'     "notional": "51.23456000",
    #'     "isolatedWallet": "0",
    #'     "updateTime": 1710000000123
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per position and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `position_side` (character): `"BOTH"`, `"LONG"`, or `"SHORT"`.
    #' - `position_amt` (character): Position quantity.
    #' - `entry_price` (character): Average entry price.
    #' - `mark_price` (character): Current mark price.
    #' - `un_realized_profit` (character): Unrealised PnL.
    #' - `liquidation_price` (character): Estimated liquidation price.
    #' - `leverage` (character): Current leverage.
    #' - `margin_type` (character): `"isolated"` or `"cross"`.
    #' - `isolated_margin` (character): Isolated margin amount.
    #' - `notional` (character): Position notional value.
    #' - `update_time` (POSIXct): Last position update time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' positions <- futures$get_positions("BTCUSDT")
    #' print(positions)
    #' }
    get_positions = function(symbol = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/fapi/v2/positionRisk",
        query = list(symbol = symbol, recvWindow = recvWindow),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "update_time" %in% names(dt)) {
            dt[, update_time := ms_to_datetime(update_time)]
          }
          return(dt[])
        }
      ))
    },

    # ---- Leverage & Margin ----

    #' @description
    #' Set Leverage
    #'
    #' Changes the initial leverage for a futures symbol.
    #'
    #' ### API Endpoint
    #' `POST https://fapi.binance.com/fapi/v1/leverage`
    #'
    #' ### Official Documentation
    #' [Binance Futures Change Initial Leverage](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Change-Initial-Leverage)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://fapi.binance.com/fapi/v1/leverage' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&leverage=20&timestamp=1710000000000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "leverage": 20,
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "leverage": 20,
    #'   "maxNotionalValue": "250000",
    #'   "symbol": "BTCUSDT"
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param leverage Integer; target leverage (1-125).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `leverage` (integer): New leverage setting.
    #' - `max_notional_value` (character): Maximum notional value for this leverage.
    #' - `symbol` (character): Trading pair.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' result <- futures$set_leverage("BTCUSDT", 20)
    #' print(result)
    #' }
    set_leverage = function(symbol, leverage, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/fapi/v1/leverage",
        method = "POST",
        body = list(
          symbol = symbol,
          leverage = leverage,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Set Margin Type
    #'
    #' Changes the margin type for a futures symbol.
    #'
    #' ### API Endpoint
    #' `POST https://fapi.binance.com/fapi/v1/marginType`
    #'
    #' ### Official Documentation
    #' [Binance Futures Change Margin Type](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Change-Margin-Type)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://fapi.binance.com/fapi/v1/marginType' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&marginType=ISOLATED&timestamp=1710000000000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "marginType": "ISOLATED",
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": 200,
    #'   "msg": "success"
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param marginType Character; `"ISOLATED"` or `"CROSSED"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `code` (integer): Response code (`200` on success).
    #' - `msg` (character): Response message.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' result <- futures$set_margin_type("BTCUSDT", "ISOLATED")
    #' print(result)
    #' }
    set_margin_type = function(symbol, marginType, recvWindow = NULL) {
      marginType <- toupper(marginType)
      rlang::arg_match0(marginType, c("ISOLATED", "CROSSED"))

      return(private$.request(
        endpoint = "/fapi/v1/marginType",
        method = "POST",
        body = list(
          symbol = symbol,
          marginType = marginType,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Modify Position Margin
    #'
    #' Adds or reduces the isolated margin for a position.
    #'
    #' ### API Endpoint
    #' `POST https://fapi.binance.com/fapi/v1/positionMargin`
    #'
    #' ### Official Documentation
    #' [Binance Futures Modify Isolated Position Margin](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Modify-Isolated-Position-Margin)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://fapi.binance.com/fapi/v1/positionMargin' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&amount=100&type=1&timestamp=1710000000000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "amount": "100",
    #'   "type": 1,
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "amount": 100.0,
    #'   "code": 200,
    #'   "msg": "Successfully modify position margin.",
    #'   "type": 1
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param amount Numeric; margin amount.
    #' @param type Integer; 1 = add margin, 2 = reduce margin.
    #' @param positionSide Character or NULL; `"BOTH"`, `"LONG"`, `"SHORT"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `code` (integer): Response code (`200` on success).
    #' - `msg` (character): Response message.
    #' - `amount` (numeric): Margin amount modified.
    #' - `type` (integer): Margin change type (1 = add, 2 = reduce).
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' result <- futures$modify_position_margin("BTCUSDT", amount = 100, type = 1)
    #' print(result)
    #' }
    modify_position_margin = function(symbol, amount, type, positionSide = NULL, recvWindow = NULL) {
      amount <- as.character(amount)

      body <- list(
        symbol = symbol,
        amount = amount,
        type = type,
        positionSide = positionSide,
        recvWindow = recvWindow
      )
      body <- body[!vapply(body, is.null, logical(1))]

      return(private$.request(
        endpoint = "/fapi/v1/positionMargin",
        method = "POST",
        body = body,
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Get Position Margin Change History
    #'
    #' Retrieves the history of position margin changes.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/positionMargin/history`
    #'
    #' ### Official Documentation
    #' [Binance Futures Get Position Margin Change History](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Get-Position-Margin-Change-History)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/positionMargin/history?symbol=BTCUSDT&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "type": 1,
    #'     "deltaType": "INCREASE_MARGIN",
    #'     "amount": "100.00000000",
    #'     "asset": "USDT",
    #'     "time": 1710000000000,
    #'     "positionSide": "BOTH"
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param type Integer or NULL; 1 = add margin, 2 = reduce margin.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param limit Integer or NULL; max results (default 500).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per margin change and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `type` (integer): Margin change type (1 = add, 2 = reduce).
    #' - `delta_type` (character): Type of margin change.
    #' - `amount` (character): Margin amount changed.
    #' - `asset` (character): Margin asset (e.g., `"USDT"`).
    #' - `time` (POSIXct): Time of the margin change.
    #' - `position_side` (character): Position side.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' history <- futures$get_position_margin_history("BTCUSDT")
    #' print(history)
    #' }
    get_position_margin_history = function(
      symbol,
      type = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/fapi/v1/positionMargin/history",
        query = list(
          symbol = symbol,
          type = type,
          startTime = startTime,
          endTime = endTime,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          return(dt[])
        }
      ))
    },

    # ---- Trades & Income ----

    #' @description
    #' Get Futures Account Trade List
    #'
    #' Retrieves the trade history for the futures account.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/userTrades`
    #'
    #' ### Official Documentation
    #' [Binance Futures Account Trade List](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Account-Trade-List)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/userTrades?symbol=BTCUSDT&limit=50&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "id": 698759,
    #'     "orderId": 283194212,
    #'     "side": "BUY",
    #'     "price": "50000.00",
    #'     "qty": "0.001",
    #'     "realizedPnl": "0",
    #'     "marginAsset": "USDT",
    #'     "quoteQty": "50.00000",
    #'     "commission": "0.02000000",
    #'     "commissionAsset": "USDT",
    #'     "time": 1710000000123,
    #'     "positionSide": "BOTH",
    #'     "buyer": true,
    #'     "maker": false
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; filter by order ID.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param fromId Integer or NULL; trade ID to fetch from.
    #' @param limit Integer or NULL; max results (default 500, max 1000).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per trade and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `id` (integer): Trade identifier.
    #' - `order_id` (integer): Order identifier.
    #' - `price` (character): Trade execution price.
    #' - `qty` (character): Trade quantity.
    #' - `quote_qty` (character): Quote asset quantity.
    #' - `commission` (character): Commission paid.
    #' - `commission_asset` (character): Commission asset (e.g., `"USDT"`).
    #' - `realized_pnl` (character): Realised profit/loss.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `position_side` (character): Position side.
    #' - `buyer` (logical): Whether the trade was a buy.
    #' - `maker` (logical): Whether the trade was a maker.
    #' - `time` (POSIXct): Trade execution time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' trades <- futures$get_trades("BTCUSDT", limit = 50)
    #' print(trades)
    #' }
    get_trades = function(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      fromId = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/fapi/v1/userTrades",
        query = list(
          symbol = symbol,
          orderId = orderId,
          startTime = startTime,
          endTime = endTime,
          fromId = fromId,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Income History
    #'
    #' Retrieves the income history for the futures account (funding fees,
    #' realized PnL, commissions, etc.).
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/income`
    #'
    #' ### Official Documentation
    #' [Binance Futures Get Income History](https://developers.binance.com/docs/derivatives/usds-margined-futures/account/rest-api/Get-Income-History)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/income?symbol=BTCUSDT&incomeType=FUNDING_FEE&timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "incomeType": "FUNDING_FEE",
    #'     "income": "-0.01234500",
    #'     "asset": "USDT",
    #'     "info": "",
    #'     "time": 1710000000000,
    #'     "tranId": 1567890123456,
    #'     "tradeId": ""
    #'   },
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "incomeType": "REALIZED_PNL",
    #'     "income": "15.67890000",
    #'     "asset": "USDT",
    #'     "info": "",
    #'     "time": 1710000001000,
    #'     "tranId": 1567890123457,
    #'     "tradeId": "698759"
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #' @param incomeType Character or NULL; income type filter. Valid values:
    #'   `"TRANSFER"`, `"WELCOME_BONUS"`, `"REALIZED_PNL"`, `"FUNDING_FEE"`,
    #'   `"COMMISSION"`, `"INSURANCE_CLEAR"`, `"REFERRAL_KICKBACK"`,
    #'   `"COMMISSION_REBATE"`, `"API_REBATE"`, `"CONTEST_REWARD"`,
    #'   `"CROSS_COLLATERAL_TRANSFER"`, `"OPTIONS_PREMIUM_FEE"`,
    #'   `"OPTIONS_SETTLE_PROFIT"`, `"INTERNAL_TRANSFER"`, `"AUTO_EXCHANGE"`,
    #'   `"DELIVERED_SETTELMENT"`, `"COIN_SWAP_DEPOSIT"`, `"COIN_SWAP_WITHDRAW"`,
    #'   `"POSITION_LIMIT_INCREASE_FEE"`.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param limit Integer or NULL; max results (default 100, max 1000).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per income entry and the following columns:
    #' - `symbol` (character): Trading pair (may be empty for some income types).
    #' - `income_type` (character): Type of income (e.g., `"FUNDING_FEE"`, `"REALIZED_PNL"`).
    #' - `income` (character): Income amount (negative for fees paid).
    #' - `asset` (character): Asset of the income (e.g., `"USDT"`).
    #' - `info` (character): Additional info about the income event.
    #' - `time` (POSIXct): Time of the income event.
    #' - `tran_id` (integer): Transaction identifier.
    #' - `trade_id` (character): Associated trade ID if applicable.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' income <- futures$get_income_history(symbol = "BTCUSDT", incomeType = "FUNDING_FEE")
    #' print(income)
    #' }
    get_income_history = function(
      symbol = NULL,
      incomeType = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      if (!is.null(incomeType)) {
        incomeType <- toupper(incomeType)
        rlang::arg_match0(
          incomeType,
          c(
            "TRANSFER",
            "WELCOME_BONUS",
            "REALIZED_PNL",
            "FUNDING_FEE",
            "COMMISSION",
            "INSURANCE_CLEAR",
            "REFERRAL_KICKBACK",
            "COMMISSION_REBATE",
            "API_REBATE",
            "CONTEST_REWARD",
            "CROSS_COLLATERAL_TRANSFER",
            "OPTIONS_PREMIUM_FEE",
            "OPTIONS_SETTLE_PROFIT",
            "INTERNAL_TRANSFER",
            "AUTO_EXCHANGE",
            "DELIVERED_SETTELMENT",
            "COIN_SWAP_DEPOSIT",
            "COIN_SWAP_WITHDRAW",
            "POSITION_LIMIT_INCREASE_FEE"
          )
        )
      }

      return(private$.request(
        endpoint = "/fapi/v1/income",
        query = list(
          symbol = symbol,
          incomeType = incomeType,
          startTime = startTime,
          endTime = endTime,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          return(dt[])
        }
      ))
    },

    # ---- Position Mode ----

    #' @description
    #' Set Position Mode
    #'
    #' Changes the position mode between one-way and hedge mode.
    #'
    #' ### API Endpoint
    #' `POST https://fapi.binance.com/fapi/v1/positionSide/dual`
    #'
    #' ### Official Documentation
    #' [Binance Futures Change Position Mode](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Change-Position-Mode)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://fapi.binance.com/fapi/v1/positionSide/dual' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'dualSidePosition=true&timestamp=1710000000000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "dualSidePosition": "true",
    #'   "timestamp": 1710000000000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": 200,
    #'   "msg": "success"
    #' }
    #' ```
    #'
    #' @param dualSidePosition Logical; `TRUE` for hedge mode, `FALSE` for one-way.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `code` (integer): Response code (`200` on success).
    #' - `msg` (character): Response message.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' result <- futures$set_position_mode(TRUE)
    #' print(result)
    #' }
    set_position_mode = function(dualSidePosition, recvWindow = NULL) {
      dualSidePosition <- tolower(as.character(dualSidePosition))

      return(private$.request(
        endpoint = "/fapi/v1/positionSide/dual",
        method = "POST",
        body = list(
          dualSidePosition = dualSidePosition,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Get Position Mode
    #'
    #' Retrieves the current position mode (one-way or hedge mode).
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/positionSide/dual`
    #'
    #' ### Official Documentation
    #' [Binance Futures Get Current Position Mode](https://developers.binance.com/docs/derivatives/usds-margined-futures/trade/rest-api/Get-Current-Position-Mode)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/positionSide/dual?timestamp=1710000000000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "dualSidePosition": true
    #' }
    #' ```
    #'
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `dual_side_position` (logical): `TRUE` if hedge mode, `FALSE` if one-way mode.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFutures$new()
    #' mode <- futures$get_position_mode()
    #' print(mode$dual_side_position)
    #' }
    get_position_mode = function(recvWindow = NULL) {
      return(private$.request(
        endpoint = "/fapi/v1/positionSide/dual",
        query = list(recvWindow = recvWindow),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    }
  )
)
