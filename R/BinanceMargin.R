# File: R/BinanceMargin.R
# R6 class for Binance Margin trading operations.

#' BinanceMargin: Margin Trading Operations
#'
#' Provides methods for margin borrowing, repaying, order management, and
#' account queries on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Borrowing / Repaying**: Borrow and repay assets on cross or isolated margin.
#' - **Order Management**: Place, cancel, and query margin orders.
#' - **Account Info**: Query margin account details, max borrowable/transferable amounts.
#' - **History**: Retrieve interest history, force liquidation records, and trade history.
#' - **Isolated Margin**: Query isolated margin accounts and initiate isolated transfers.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#' These are SAPI (`/sapi/`) endpoints.
#'
#' ### Official Documentation
#' [Binance Margin Trading](https://developers.binance.com/docs/margin_trading/Introduction)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_borrow | POST /sapi/v1/margin/borrow-repay (type=BORROW) | POST |
#' | add_repay | POST /sapi/v1/margin/borrow-repay (type=REPAY) | POST |
#' | add_order | POST /sapi/v1/margin/order | POST |
#' | cancel_order | DELETE /sapi/v1/margin/order | DELETE |
#' | cancel_all_orders | DELETE /sapi/v1/margin/openOrders | DELETE |
#' | get_order | GET /sapi/v1/margin/order | GET |
#' | get_open_orders | GET /sapi/v1/margin/openOrders | GET |
#' | get_all_orders | GET /sapi/v1/margin/allOrders | GET |
#' | get_account | GET /sapi/v1/margin/account | GET |
#' | get_max_borrowable | GET /sapi/v1/margin/maxBorrowable | GET |
#' | get_max_transferable | GET /sapi/v1/margin/maxTransferable | GET |
#' | get_interest_history | GET /sapi/v1/margin/interestHistory | GET |
#' | get_force_liquidation_history | GET /sapi/v1/margin/forceLiquidationRec | GET |
#' | get_trades | GET /sapi/v1/margin/myTrades | GET |
#' | get_isolated_account | GET /sapi/v1/margin/isolated/account | GET |
#' | add_isolated_transfer | POST /sapi/v1/margin/isolated/transfer | POST |
#'
#' @section Order Types:
#' - `"LIMIT"`: requires `price`, `quantity`, `timeInForce`.
#' - `"MARKET"`: requires either `quantity` or `quoteOrderQty`.
#' - `"STOP_LOSS"`, `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`, `"TAKE_PROFIT_LIMIT"`: conditional.
#' - `"LIMIT_MAKER"`: like LIMIT but rejected if it would immediately match.
#'
#' @section Side Effect Types:
#' - `"NO_SIDE_EFFECT"`: Normal trade order.
#' - `"MARGIN_BUY"`: Margin trade order with auto-borrow.
#' - `"AUTO_REPAY"`: Margin trade order with auto-repay.
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' margin <- BinanceMargin$new()
#' account <- margin$get_account()
#' print(account)
#'
#' # Asynchronous
#' margin_async <- BinanceMargin$new(async = TRUE)
#' main <- coro::async(function() {
#'   account <- await(margin_async$get_account())
#'   print(account)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom rlang arg_match0
#' @export
BinanceMargin <- R6::R6Class(
  "BinanceMargin",
  inherit = BinanceBase,
  public = list(
    # ---- Borrowing / Repaying ----

    #' @description
    #' Borrow on Margin
    #'
    #' Initiates a margin loan for the specified asset and amount.
    #' Uses the consolidated borrow-repay endpoint with `type = "BORROW"`.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/margin/borrow-repay`
    #'
    #' ### Official Documentation
    #' [Binance Margin Borrow-Repay](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Margin-Account-Borrow-Repay)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/margin/borrow-repay?asset=USDT&amount=100&type=BORROW&isIsolated=FALSE&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "asset": "USDT",
    #'   "amount": "100",
    #'   "type": "BORROW",
    #'   "isIsolated": "FALSE"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "tranId": 100000001
    #' }
    #' ```
    #'
    #' @param asset Character; asset to borrow (e.g., `"USDT"`).
    #' @param amount Numeric; amount to borrow.
    #' @param isIsolated Character; `"TRUE"` or `"FALSE"` for isolated margin. Default `"FALSE"`.
    #' @param symbol Character or NULL; required when `isIsolated = "TRUE"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `tran_id` (integer): Transaction identifier.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' result <- margin$add_borrow(asset = "USDT", amount = 100)
    #' print(result)
    #' }
    add_borrow = function(asset, amount, isIsolated = "FALSE", symbol = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/borrow-repay",
        method = "POST",
        query = list(
          asset = asset,
          amount = as.character(amount),
          type = "BORROW",
          isIsolated = isIsolated,
          symbol = symbol,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Repay Margin Loan
    #'
    #' Repays a margin loan for the specified asset and amount.
    #' Uses the consolidated borrow-repay endpoint with `type = "REPAY"`.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/margin/borrow-repay`
    #'
    #' ### Official Documentation
    #' [Binance Margin Borrow-Repay](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Margin-Account-Borrow-Repay)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/margin/borrow-repay?asset=USDT&amount=100&type=REPAY&isIsolated=FALSE&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "asset": "USDT",
    #'   "amount": "100",
    #'   "type": "REPAY",
    #'   "isIsolated": "FALSE"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "tranId": 100000002
    #' }
    #' ```
    #'
    #' @param asset Character; asset to repay (e.g., `"USDT"`).
    #' @param amount Numeric; amount to repay.
    #' @param isIsolated Character; `"TRUE"` or `"FALSE"` for isolated margin. Default `"FALSE"`.
    #' @param symbol Character or NULL; required when `isIsolated = "TRUE"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `tran_id` (integer): Transaction identifier.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' result <- margin$add_repay(asset = "USDT", amount = 100)
    #' print(result)
    #' }
    add_repay = function(asset, amount, isIsolated = "FALSE", symbol = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/borrow-repay",
        method = "POST",
        query = list(
          asset = asset,
          amount = as.character(amount),
          type = "REPAY",
          isIsolated = isIsolated,
          symbol = symbol,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    # ---- Order Management ----

    #' @description
    #' Place a Margin Order
    #'
    #' Places a new margin order on Binance.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/margin/order`
    #'
    #' ### Official Documentation
    #' [Binance Margin New Order](https://developers.binance.com/docs/margin_trading/trade/Margin-Account-New-Order)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/margin/order?symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=0.0001&price=50000&timeInForce=GTC&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "side": "BUY",
    #'   "type": "LIMIT",
    #'   "quantity": "0.0001",
    #'   "price": "50000",
    #'   "timeInForce": "GTC",
    #'   "sideEffectType": "NO_SIDE_EFFECT"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "orderId": 28,
    #'   "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
    #'   "transactTime": 1507725176595,
    #'   "price": "50000.00000000",
    #'   "origQty": "0.00010000",
    #'   "executedQty": "0.00000000",
    #'   "cummulativeQuoteQty": "0.00000000",
    #'   "status": "NEW",
    #'   "timeInForce": "GTC",
    #'   "type": "LIMIT",
    #'   "side": "BUY",
    #'   "isIsolated": false
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param side Character; `"BUY"` or `"SELL"`.
    #' @param type Character; order type: `"LIMIT"`, `"MARKET"`, `"STOP_LOSS"`,
    #'   `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`, `"TAKE_PROFIT_LIMIT"`, `"LIMIT_MAKER"`.
    #' @param quantity Numeric or NULL; base asset quantity.
    #' @param quoteOrderQty Numeric or NULL; quote asset quantity (market orders only).
    #' @param price Numeric or NULL; price for limit orders.
    #' @param stopPrice Numeric or NULL; trigger price for stop orders.
    #' @param timeInForce Character or NULL; `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param newClientOrderId Character or NULL; unique client order ID.
    #' @param newOrderRespType Character or NULL; `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param sideEffectType Character or NULL; `"NO_SIDE_EFFECT"`, `"MARGIN_BUY"`, `"AUTO_REPAY"`.
    #' @param isIsolated Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and columns including:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `transact_time` (POSIXct): Transaction time.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `status` (character): Order status.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `is_isolated` (logical): Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' order <- margin$add_order(
    #'   symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
    #'   price = 50000, quantity = 0.0001, timeInForce = "GTC"
    #' )
    #' print(order)
    #' }
    add_order = function(
      symbol,
      side,
      type,
      quantity = NULL,
      quoteOrderQty = NULL,
      price = NULL,
      stopPrice = NULL,
      timeInForce = NULL,
      newClientOrderId = NULL,
      newOrderRespType = NULL,
      sideEffectType = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    ) {
      side <- toupper(side)
      type <- toupper(type)
      rlang::arg_match0(side, c("BUY", "SELL"))
      rlang::arg_match0(
        type,
        c("LIMIT", "MARKET", "STOP_LOSS", "STOP_LOSS_LIMIT", "TAKE_PROFIT", "TAKE_PROFIT_LIMIT", "LIMIT_MAKER")
      )

      if (!is.null(sideEffectType)) {
        sideEffectType <- toupper(sideEffectType)
        rlang::arg_match0(sideEffectType, c("NO_SIDE_EFFECT", "MARGIN_BUY", "AUTO_REPAY"))
      }

      # Convert numeric values to character for precision
      if (!is.null(price)) {
        price <- as.character(price)
      }
      if (!is.null(quantity)) {
        quantity <- as.character(quantity)
      }
      if (!is.null(quoteOrderQty)) {
        quoteOrderQty <- as.character(quoteOrderQty)
      }
      if (!is.null(stopPrice)) {
        stopPrice <- as.character(stopPrice)
      }

      return(private$.request(
        endpoint = "/sapi/v1/margin/order",
        method = "POST",
        query = list(
          symbol = symbol,
          side = side,
          type = type,
          quantity = quantity,
          quoteOrderQty = quoteOrderQty,
          price = price,
          stopPrice = stopPrice,
          timeInForce = timeInForce,
          newClientOrderId = newClientOrderId,
          newOrderRespType = newOrderRespType,
          sideEffectType = sideEffectType,
          isIsolated = isIsolated,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "transact_time" %in% names(dt)) {
            dt[, transact_time := ms_to_datetime(transact_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Cancel a Margin Order
    #'
    #' Cancels an active margin order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.binance.com/sapi/v1/margin/order`
    #'
    #' ### Official Documentation
    #' [Binance Margin Cancel Order](https://developers.binance.com/docs/margin_trading/trade/Margin-Account-Cancel-Order)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE 'https://api.binance.com/sapi/v1/margin/order?symbol=BTCUSDT&orderId=28&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "orderId": 28
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "orderId": 28,
    #'   "origClientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
    #'   "clientOrderId": "cancelMyOrder1",
    #'   "transactTime": 1507725176595,
    #'   "price": "50000.00000000",
    #'   "origQty": "0.00010000",
    #'   "executedQty": "0.00000000",
    #'   "cummulativeQuoteQty": "0.00000000",
    #'   "status": "CANCELED",
    #'   "timeInForce": "GTC",
    #'   "type": "LIMIT",
    #'   "side": "BUY",
    #'   "isIsolated": false
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; the order ID to cancel.
    #' @param origClientOrderId Character or NULL; the client order ID to cancel.
    #' @param isIsolated Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and columns including:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `orig_client_order_id` (character): Original client order ID.
    #' - `status` (character): Order status (typically `"CANCELED"`).
    #' - `transact_time` (POSIXct): Cancellation time.
    #' - `is_isolated` (logical): Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' cancelled <- margin$cancel_order("BTCUSDT", orderId = 28)
    #' print(cancelled)
    #' }
    cancel_order = function(symbol, orderId = NULL, origClientOrderId = NULL, isIsolated = NULL, recvWindow = NULL) {
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      return(private$.request(
        endpoint = "/sapi/v1/margin/order",
        method = "DELETE",
        query = list(
          symbol = symbol,
          orderId = orderId,
          origClientOrderId = origClientOrderId,
          isIsolated = isIsolated,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "transact_time" %in% names(dt)) {
            dt[, transact_time := ms_to_datetime(transact_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Cancel All Open Margin Orders on a Symbol
    #'
    #' Cancels all active margin orders on a trading pair.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.binance.com/sapi/v1/margin/openOrders`
    #'
    #' ### Official Documentation
    #' [Binance Margin Cancel All Orders](https://developers.binance.com/docs/margin_trading/trade/Margin-Account-Cancel-All-Open-Orders)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE 'https://api.binance.com/sapi/v1/margin/openOrders?symbol=BTCUSDT&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "orderId": 28,
    #'     "origClientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
    #'     "clientOrderId": "cancelMyOrder1",
    #'     "transactTime": 1507725176595,
    #'     "price": "50000.00000000",
    #'     "origQty": "0.00010000",
    #'     "executedQty": "0.00000000",
    #'     "cummulativeQuoteQty": "0.00000000",
    #'     "status": "CANCELED",
    #'     "timeInForce": "GTC",
    #'     "type": "LIMIT",
    #'     "side": "BUY",
    #'     "isIsolated": false
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param isIsolated Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`).
    #'   When orders are cancelled, one row per order with columns:
    #'   - `symbol` (character): Trading pair.
    #'   - `order_id` (integer): Unique order identifier.
    #'   - `orig_client_order_id` (character): Original client order ID.
    #'   - `status` (character): Order status (typically `"CANCELED"`).
    #'   - `transact_time` (POSIXct): Cancellation time.
    #'   - `is_isolated` (logical): Whether this is an isolated margin order.
    #'
    #'   When no open orders exist, a single confirmation row with columns:
    #'   - `symbol` (character): The requested trading pair.
    #'   - `status` (character): `"cancelled"`.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' cancelled <- margin$cancel_all_orders("BTCUSDT")
    #' print(cancelled)
    #' }
    cancel_all_orders = function(symbol, isIsolated = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/openOrders",
        method = "DELETE",
        query = list(
          symbol = symbol,
          isIsolated = isIsolated,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table(symbol = symbol, status = "cancelled")[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "transact_time" %in% names(dt)) {
            dt[, transact_time := ms_to_datetime(transact_time)]
          }
          return(dt[])
        }
      ))
    },

    # ---- Order Queries ----

    #' @description
    #' Query a Margin Order
    #'
    #' Retrieves details for a specific margin order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/order`
    #'
    #' ### Official Documentation
    #' [Binance Margin Query Order](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-Order)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/order?symbol=BTCUSDT&orderId=28&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "orderId": 28,
    #'   "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
    #'   "price": "50000.00000000",
    #'   "origQty": "0.00010000",
    #'   "executedQty": "0.00010000",
    #'   "cummulativeQuoteQty": "5.00000000",
    #'   "status": "FILLED",
    #'   "timeInForce": "GTC",
    #'   "type": "LIMIT",
    #'   "side": "BUY",
    #'   "stopPrice": "0.00000000",
    #'   "icebergQty": "0.00000000",
    #'   "time": 1507725176595,
    #'   "updateTime": 1507725176595,
    #'   "isIsolated": false
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; the order ID.
    #' @param origClientOrderId Character or NULL; the client order ID.
    #' @param isIsolated Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and columns including:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `status` (character): Order status.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `time` (POSIXct): Order creation time.
    #' - `update_time` (POSIXct): Last update time.
    #' - `is_isolated` (logical): Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' order <- margin$get_order("BTCUSDT", orderId = 28)
    #' print(order)
    #' }
    get_order = function(symbol, orderId = NULL, origClientOrderId = NULL, isIsolated = NULL, recvWindow = NULL) {
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      return(private$.request(
        endpoint = "/sapi/v1/margin/order",
        query = list(
          symbol = symbol,
          orderId = orderId,
          origClientOrderId = origClientOrderId,
          isIsolated = isIsolated,
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
    #' Get Open Margin Orders
    #'
    #' Retrieves all currently open margin orders, optionally filtered by symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/openOrders`
    #'
    #' ### Official Documentation
    #' [Binance Margin Open Orders](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-Open-Orders)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/openOrders?symbol=BTCUSDT&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "orderId": 28,
    #'     "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
    #'     "price": "50000.00000000",
    #'     "origQty": "0.00010000",
    #'     "executedQty": "0.00000000",
    #'     "cummulativeQuoteQty": "0.00000000",
    #'     "status": "NEW",
    #'     "timeInForce": "GTC",
    #'     "type": "LIMIT",
    #'     "side": "BUY",
    #'     "stopPrice": "0.00000000",
    #'     "icebergQty": "0.00000000",
    #'     "time": 1507725176595,
    #'     "updateTime": 1507725176595,
    #'     "isIsolated": false
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #' @param isIsolated Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.
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
    #' - `time` (POSIXct): Order creation time.
    #' - `update_time` (POSIXct): Last update time.
    #' - `is_isolated` (logical): Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' open <- margin$get_open_orders("BTCUSDT")
    #' print(open)
    #' }
    get_open_orders = function(symbol = NULL, isIsolated = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/openOrders",
        query = list(
          symbol = symbol,
          isIsolated = isIsolated,
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

    #' @description
    #' Get All Margin Orders
    #'
    #' Retrieves all margin orders for a symbol (open, cancelled, filled).
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/allOrders`
    #'
    #' ### Official Documentation
    #' [Binance Margin All Orders](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-All-Orders)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/allOrders?symbol=BTCUSDT&limit=50&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "orderId": 28,
    #'     "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
    #'     "price": "50000.00000000",
    #'     "origQty": "0.00010000",
    #'     "executedQty": "0.00010000",
    #'     "cummulativeQuoteQty": "5.00000000",
    #'     "status": "FILLED",
    #'     "timeInForce": "GTC",
    #'     "type": "LIMIT",
    #'     "side": "BUY",
    #'     "stopPrice": "0.00000000",
    #'     "icebergQty": "0.00000000",
    #'     "time": 1507725176595,
    #'     "updateTime": 1507725176595,
    #'     "isIsolated": false
    #'   },
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "orderId": 29,
    #'     "clientOrderId": "x]]Xk3RFN1g2MjEDKWNq8t",
    #'     "price": "0.00000000",
    #'     "origQty": "0.00020000",
    #'     "executedQty": "0.00020000",
    #'     "cummulativeQuoteQty": "10.48000000",
    #'     "status": "FILLED",
    #'     "timeInForce": "GTC",
    #'     "type": "MARKET",
    #'     "side": "SELL",
    #'     "stopPrice": "0.00000000",
    #'     "icebergQty": "0.00000000",
    #'     "time": 1507725276595,
    #'     "updateTime": 1507725276595,
    #'     "isIsolated": false
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; pagination cursor.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param limit Integer or NULL; max results (default 500, max 500).
    #' @param isIsolated Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.
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
    #' - `time` (POSIXct): Order creation time.
    #' - `update_time` (POSIXct): Last update time.
    #' - `is_isolated` (logical): Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' all <- margin$get_all_orders("BTCUSDT", limit = 50)
    #' print(all)
    #' }
    get_all_orders = function(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/allOrders",
        query = list(
          symbol = symbol,
          orderId = orderId,
          startTime = startTime,
          endTime = endTime,
          limit = limit,
          isIsolated = isIsolated,
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

    # ---- Account Queries ----

    #' @description
    #' Get Margin Account Information
    #'
    #' Retrieves cross margin account details including balances and margin level.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/account`
    #'
    #' ### Official Documentation
    #' [Binance Margin Account](https://developers.binance.com/docs/margin_trading/account/Query-Cross-Margin-Account-Details)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/account?timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "borrowEnabled": true,
    #'   "marginLevel": "11.64405625",
    #'   "totalAssetOfBtc": "6.82728457",
    #'   "totalLiabilityOfBtc": "0.58633215",
    #'   "totalNetAssetOfBtc": "6.24095242",
    #'   "tradeEnabled": true,
    #'   "transferEnabled": true,
    #'   "accountType": "MARGIN",
    #'   "userAssets": [
    #'     {
    #'       "asset": "BTC",
    #'       "borrowed": "0.00000000",
    #'       "free": "0.00499500",
    #'       "interest": "0.00000000",
    #'       "locked": "0.00000000",
    #'       "netAsset": "0.00499500"
    #'     },
    #'     {
    #'       "asset": "USDT",
    #'       "borrowed": "200.00000000",
    #'       "free": "1500.50000000",
    #'       "interest": "0.01055556",
    #'       "locked": "0.00000000",
    #'       "netAsset": "1300.48944444"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and columns including:
    #' - `borrow_enabled` (logical): Whether borrowing is enabled.
    #' - `margin_level` (character): Current margin level.
    #' - `total_asset_of_btc` (character): Total asset value in BTC.
    #' - `total_liability_of_btc` (character): Total liability in BTC.
    #' - `total_net_asset_of_btc` (character): Net asset value in BTC.
    #' - `trade_enabled` (logical): Whether trading is enabled.
    #' - `transfer_enabled` (logical): Whether transfers are enabled.
    #' - `account_type` (character): Account type (`"MARGIN"`).
    #' - `user_asset_*`: Per-asset fields prefixed with `user_asset_` (one row per asset).
    #'
    #' When the account has multiple assets, account-level fields are repeated on each row.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' account <- margin$get_account()
    #' print(account)
    #' }
    get_account = function(recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/account",
        query = list(recvWindow = recvWindow),
        .parser = function(data) {
          user_assets <- data$userAssets
          data$userAssets <- NULL
          dt <- as_dt_row(data)
          # Expand userAssets to long format: one row per asset
          if (!is.null(user_assets) && length(user_assets) > 0) {
            assets_dt <- as_dt_list(user_assets)
            asset_names <- names(assets_dt)
            data.table::setnames(assets_dt, asset_names, paste0("user_asset_", asset_names))
            dt <- dt[rep(1L, nrow(assets_dt))]
            dt <- cbind(dt, assets_dt)
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Max Borrowable Amount
    #'
    #' Queries the maximum borrowable amount for an asset on margin.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/maxBorrowable`
    #'
    #' ### Official Documentation
    #' [Binance Max Borrowable](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Query-Max-Borrow)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/maxBorrowable?asset=USDT&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "amount": "1.69248805",
    #'   "borrowLimit": "60"
    #' }
    #' ```
    #'
    #' @param asset Character; asset to query (e.g., `"USDT"`).
    #' @param isolatedSymbol Character or NULL; isolated margin pair (e.g., `"BTCUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `amount` (character): Maximum borrowable amount.
    #' - `borrow_limit` (character): Borrow limit.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' max_borrow <- margin$get_max_borrowable(asset = "USDT")
    #' print(max_borrow)
    #' }
    get_max_borrowable = function(asset, isolatedSymbol = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/maxBorrowable",
        query = list(
          asset = asset,
          isolatedSymbol = isolatedSymbol,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Get Max Transferable Amount
    #'
    #' Queries the maximum transferable-out amount for an asset on margin.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/maxTransferable`
    #'
    #' ### Official Documentation
    #' [Binance Max Transferable](https://developers.binance.com/docs/margin_trading/transfer/Query-Max-Transfer-Out-Amount)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/maxTransferable?asset=USDT&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "amount": "3.59498107"
    #' }
    #' ```
    #'
    #' @param asset Character; asset to query (e.g., `"USDT"`).
    #' @param isolatedSymbol Character or NULL; isolated margin pair (e.g., `"BTCUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `amount` (character): Maximum transferable-out amount.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' max_transfer <- margin$get_max_transferable(asset = "USDT")
    #' print(max_transfer)
    #' }
    get_max_transferable = function(asset, isolatedSymbol = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/maxTransferable",
        query = list(
          asset = asset,
          isolatedSymbol = isolatedSymbol,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    # ---- History ----

    #' @description
    #' Get Margin Interest History
    #'
    #' Retrieves margin interest accrual history with pagination.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/interestHistory`
    #'
    #' ### Official Documentation
    #' [Binance Interest History](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Get-Interest-History)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/interestHistory?asset=USDT&current=1&size=10&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "rows": [
    #'     {
    #'       "isolatedSymbol": "",
    #'       "asset": "USDT",
    #'       "interest": "0.01055556",
    #'       "interestAccuredTime": 1672012800000,
    #'       "interestRate": "0.00019",
    #'       "principal": "200.00000000",
    #'       "type": "ON_BORROW"
    #'     },
    #'     {
    #'       "isolatedSymbol": "",
    #'       "asset": "USDT",
    #'       "interest": "0.01055556",
    #'       "interestAccuredTime": 1672099200000,
    #'       "interestRate": "0.00019",
    #'       "principal": "200.00000000",
    #'       "type": "PERIODIC"
    #'     }
    #'   ],
    #'   "total": 2
    #' }
    #' ```
    #'
    #' @param asset Character or NULL; filter by asset (e.g., `"USDT"`).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param current Integer or NULL; current page (default 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param archived Character or NULL; `"true"` to query 6-month archived data.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per interest record and the following columns:
    #' - `asset` (character): Asset charged interest.
    #' - `interest` (character): Interest amount accrued.
    #' - `interest_accured_time` (POSIXct): Time of interest accrual.
    #' - `interest_rate` (character): Applied interest rate.
    #' - `principal` (character): Principal amount borrowed.
    #' - `type` (character): Margin type (`"ON_BORROW"`, `"PERIODIC"`, etc.).
    #' - `isolated_symbol` (character): Isolated margin pair (if applicable).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' history <- margin$get_interest_history(asset = "USDT")
    #' print(history)
    #' }
    get_interest_history = function(
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      archived = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/interestHistory",
        query = list(
          asset = asset,
          startTime = startTime,
          endTime = endTime,
          current = current,
          size = size,
          archived = archived,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(parse_paginated(data, time_cols = "interest_accured_time")[])
        }
      ))
    },

    #' @description
    #' Get Force Liquidation History
    #'
    #' Retrieves margin force liquidation records with pagination.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/forceLiquidationRec`
    #'
    #' ### Official Documentation
    #' [Binance Force Liquidation](https://developers.binance.com/docs/margin_trading/trade/Get-Force-Liquidation-Record)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/forceLiquidationRec?current=1&size=10&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "rows": [
    #'     {
    #'       "avgPrice": "52341.12000000",
    #'       "executedQty": "0.00100000",
    #'       "orderId": 12345678,
    #'       "price": "52000.00000000",
    #'       "qty": "0.00100000",
    #'       "side": "SELL",
    #'       "symbol": "BTCUSDT",
    #'       "timeInForce": "GTC",
    #'       "isIsolated": false,
    #'       "updatedTime": 1672099200000,
    #'       "time": 1672099100000
    #'     }
    #'   ],
    #'   "total": 1
    #' }
    #' ```
    #'
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param isolatedSymbol Character or NULL; isolated margin pair.
    #' @param current Integer or NULL; current page (default 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per liquidation record and the following columns:
    #' - `avg_price` (character): Average liquidation price.
    #' - `executed_qty` (character): Liquidated quantity.
    #' - `order_id` (integer): Liquidation order identifier.
    #' - `price` (character): Liquidation price.
    #' - `qty` (character): Total quantity.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `symbol` (character): Trading pair.
    #' - `time` (POSIXct): Liquidation time.
    #' - `is_isolated` (logical): Whether this was an isolated margin liquidation.
    #' - `updated_time` (POSIXct): Last update time.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' liquidations <- margin$get_force_liquidation_history()
    #' print(liquidations)
    #' }
    get_force_liquidation_history = function(
      startTime = NULL,
      endTime = NULL,
      isolatedSymbol = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/forceLiquidationRec",
        query = list(
          startTime = startTime,
          endTime = endTime,
          isolatedSymbol = isolatedSymbol,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(parse_paginated(data, time_cols = "time")[])
        }
      ))
    },

    # ---- Trades ----

    #' @description
    #' Get Margin Trades
    #'
    #' Retrieves margin trade history for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/myTrades`
    #'
    #' ### Official Documentation
    #' [Binance Margin Trades](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-Trade-List)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/myTrades?symbol=BTCUSDT&limit=500&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "commission": "0.00000500",
    #'     "commissionAsset": "BTC",
    #'     "id": 6,
    #'     "isBestMatch": true,
    #'     "isBuyer": true,
    #'     "isMaker": false,
    #'     "orderId": 28,
    #'     "price": "52341.12000000",
    #'     "qty": "0.00010000",
    #'     "symbol": "BTCUSDT",
    #'     "isIsolated": false,
    #'     "time": 1507725176595
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
    #' @param isIsolated Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per trade and columns including:
    #' - `symbol` (character): Trading pair.
    #' - `id` (integer): Trade ID.
    #' - `order_id` (integer): Order ID.
    #' - `price` (character): Trade price.
    #' - `qty` (character): Trade quantity.
    #' - `commission` (character): Commission paid.
    #' - `commission_asset` (character): Commission asset.
    #' - `time` (POSIXct): Trade execution time.
    #' - `is_buyer` (logical): Whether the trade was a buy.
    #' - `is_maker` (logical): Whether the trade was a maker.
    #' - `is_isolated` (logical): Whether this is an isolated margin trade.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' trades <- margin$get_trades("BTCUSDT")
    #' print(trades)
    #' }
    get_trades = function(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      fromId = NULL,
      limit = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/myTrades",
        query = list(
          symbol = symbol,
          orderId = orderId,
          startTime = startTime,
          endTime = endTime,
          fromId = fromId,
          limit = limit,
          isIsolated = isIsolated,
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

    # ---- Isolated Margin ----

    #' @description
    #' Get Isolated Margin Account Info
    #'
    #' Retrieves isolated margin account details.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/isolated/account`
    #'
    #' ### Official Documentation
    #' [Binance Isolated Margin Account](https://developers.binance.com/docs/margin_trading/account/Query-Isolated-Margin-Account-Info)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/isolated/account?symbols=BTCUSDT,ETHUSDT&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "assets": [
    #'     {
    #'       "baseAsset": {
    #'         "asset": "BTC",
    #'         "borrowEnabled": true,
    #'         "borrowed": "0.00000000",
    #'         "free": "0.00100000",
    #'         "interest": "0.00000000",
    #'         "locked": "0.00000000",
    #'         "netAsset": "0.00100000",
    #'         "netAssetOfBtc": "0.00100000",
    #'         "repayEnabled": true,
    #'         "totalAsset": "0.00100000"
    #'       },
    #'       "quoteAsset": {
    #'         "asset": "USDT",
    #'         "borrowEnabled": true,
    #'         "borrowed": "0.00000000",
    #'         "free": "50.00000000",
    #'         "interest": "0.00000000",
    #'         "locked": "0.00000000",
    #'         "netAsset": "50.00000000",
    #'         "netAssetOfBtc": "0.00094750",
    #'         "repayEnabled": true,
    #'         "totalAsset": "50.00000000"
    #'       },
    #'       "symbol": "BTCUSDT",
    #'       "isolatedCreated": true,
    #'       "enabled": true,
    #'       "marginLevel": "999.00000000",
    #'       "marginRatio": "5.00000000",
    #'       "indexPrice": "52800.00000000",
    #'       "liquidatePrice": "0.00000000",
    #'       "liquidateRate": "0.00000000",
    #'       "tradeEnabled": true
    #'     }
    #'   ],
    #'   "totalAssetOfBtc": "0.00194750",
    #'   "totalLiabilityOfBtc": "0.00000000",
    #'   "totalNetAssetOfBtc": "0.00194750"
    #' }
    #' ```
    #'
    #' @param symbols Character or NULL; comma-separated symbols (max 5, e.g., `"BTCUSDT,ETHUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per isolated margin pair (long format) and columns including:
    #' - `total_asset_of_btc` (character): Total asset value in BTC (repeated per pair).
    #' - `total_liability_of_btc` (character): Total liability in BTC (repeated per pair).
    #' - `total_net_asset_of_btc` (character): Net asset value in BTC (repeated per pair).
    #' - `base_asset` (list): Base asset details (nested object kept as list-column).
    #' - `quote_asset` (list): Quote asset details (nested object kept as list-column).
    #' - `symbol` (character): Isolated margin pair symbol.
    #' - `isolated_created` (logical): Whether the isolated pair has been created.
    #' - `enabled` (logical): Whether the pair is enabled.
    #' - `margin_level` (character): Current margin level.
    #' - `trade_enabled` (logical): Whether trading is enabled.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' isolated <- margin$get_isolated_account()
    #' print(isolated)
    #' }
    get_isolated_account = function(symbols = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/isolated/account",
        query = list(
          symbols = symbols,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          assets <- data$assets
          data$assets <- NULL
          parent_dt <- as_dt_row(data)
          # Expand assets to long format: one row per isolated pair
          if (!is.null(assets) && length(assets) > 0) {
            assets_dt <- as_dt_list(assets)
            if (nrow(parent_dt) > 0 && nrow(assets_dt) > 0) {
              parent_dt <- parent_dt[rep(1L, nrow(assets_dt))]
              parent_dt <- cbind(parent_dt, assets_dt)
            } else if (nrow(assets_dt) > 0) {
              parent_dt <- assets_dt
            }
          }
          return(parent_dt[])
        }
      ))
    },

    #' @description
    #' Isolated Margin Transfer
    #'
    #' Transfers assets between spot and isolated margin accounts.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/margin/isolated/transfer`
    #'
    #' ### Official Documentation
    #' [Binance Isolated Margin Transfer](https://developers.binance.com/docs/margin_trading/transfer/Isolated-Margin-Account-Transfer)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/margin/isolated/transfer?asset=USDT&symbol=BTCUSDT&transFrom=SPOT&transTo=ISOLATED_MARGIN&amount=100&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "asset": "USDT",
    #'   "symbol": "BTCUSDT",
    #'   "transFrom": "SPOT",
    #'   "transTo": "ISOLATED_MARGIN",
    #'   "amount": "100"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "tranId": 100000003
    #' }
    #' ```
    #'
    #' @param asset Character; asset to transfer (e.g., `"USDT"`).
    #' @param symbol Character; isolated margin pair (e.g., `"BTCUSDT"`).
    #' @param transFrom Character; source account: `"SPOT"` or `"ISOLATED_MARGIN"`.
    #' @param transTo Character; destination account: `"SPOT"` or `"ISOLATED_MARGIN"`.
    #' @param amount Numeric; amount to transfer.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `tran_id` (integer): Transaction identifier.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' result <- margin$add_isolated_transfer(
    #'   asset = "USDT", symbol = "BTCUSDT",
    #'   transFrom = "SPOT", transTo = "ISOLATED_MARGIN",
    #'   amount = 100
    #' )
    #' print(result)
    #' }
    add_isolated_transfer = function(asset, symbol, transFrom, transTo, amount, recvWindow = NULL) {
      transFrom <- toupper(transFrom)
      transTo <- toupper(transTo)
      rlang::arg_match0(transFrom, c("SPOT", "ISOLATED_MARGIN"))
      rlang::arg_match0(transTo, c("SPOT", "ISOLATED_MARGIN"))

      return(private$.request(
        endpoint = "/sapi/v1/margin/isolated/transfer",
        method = "POST",
        query = list(
          asset = asset,
          symbol = symbol,
          transFrom = transFrom,
          transTo = transTo,
          amount = as.character(amount),
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    }
  )
)
