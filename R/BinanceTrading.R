# File: R/BinanceTrading.R
# R6 class for Binance Spot order management (place, cancel, query).

#' BinanceTrading: Spot Order Management
#'
#' Provides methods for placing, cancelling, and querying spot orders on Binance.
#' Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Order Placement**: Place limit/market orders with full parameter control.
#' - **Order Testing**: Validate order parameters without execution via the test endpoint.
#' - **Order Cancellation**: Cancel by order ID, client order ID, or all open orders on a symbol.
#' - **Order Queries**: Retrieve order details, open orders, and all orders.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#'
#' ### Official Documentation
#' [Binance Spot Trading](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_order | POST /api/v3/order | POST |
#' | add_order_test | POST /api/v3/order/test | POST |
#' | cancel_order | DELETE /api/v3/order | DELETE |
#' | cancel_all_orders | DELETE /api/v3/openOrders | DELETE |
#' | get_order | GET /api/v3/order | GET |
#' | get_open_orders | GET /api/v3/openOrders | GET |
#' | get_all_orders | GET /api/v3/allOrders | GET |
#'
#' @section Order Types:
#' - `"LIMIT"`: requires `price`, `quantity`, `timeInForce`.
#' - `"MARKET"`: requires either `quantity` or `quoteOrderQty`.
#' - `"STOP_LOSS"`, `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`, `"TAKE_PROFIT_LIMIT"`: conditional.
#' - `"LIMIT_MAKER"`: like LIMIT but rejected if it would immediately match.
#'
#' @section Time-In-Force Options:
#' - `"GTC"` (Good Till Cancelled): Remains until filled or cancelled. Default.
#' - `"IOC"` (Immediate Or Cancel): Fill immediately or cancel remainder.
#' - `"FOK"` (Fill Or Kill): Fill entirely or cancel completely.
#'
#' @section Self-Trade Prevention:
#' - `"NONE"`, `"EXPIRE_TAKER"`, `"EXPIRE_MAKER"`, `"EXPIRE_BOTH"`.
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' trading <- BinanceTrading$new()
#' order <- trading$add_order_test(type = "LIMIT", symbol = "BTCUSDT",
#'                                  side = "BUY", price = 50000, quantity = 0.0001)
#' print(order)
#'
#' # Asynchronous
#' trading_async <- BinanceTrading$new(async = TRUE)
#' main <- coro::async(function() {
#'   order <- await(trading_async$add_order_test(
#'     type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
#'     price = 50000, quantity = 0.0001
#'   ))
#'   print(order)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceTrading <- R6::R6Class(
  "BinanceTrading",
  inherit = BinanceBase,
  public = list(
    # ---- Order Placement ----

    #' @description
    #' Place an Order
    #'
    #' Places a new spot order on Binance.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/api/v3/order`
    #'
    #' ### Official Documentation
    #' [Binance New Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#new-order-trade)
    #' Verified: 2026-05-22
    #'
    #' ### Automated Trading Usage
    #' - **Limit Orders**: Set specific entry/exit prices for strategy execution.
    #' - **Market Orders**: Execute immediately at best available price.
    #' - **Response Type**: Use `newOrderRespType = "FULL"` to get fill details in the response.
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/api/v3/order' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&side=BUY&type=LIMIT&timeInForce=GTC&quantity=0.0001&price=50000&timestamp=1729176273859&signature=...'
    #' ```
    #'
    #' ### JSON Response (FULL)
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "orderId": 28,
    #'   "orderListId": -1,
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
    #'   "fills": []
    #' }
    #' ```
    #'
    #' @param type (scalar<character>) `"LIMIT"` or `"MARKET"` (and stop/take-profit variants).
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param side (scalar<character>) `"BUY"` or `"SELL"`.
    #' @param quantity (scalar<numeric>?) base asset quantity.
    #' @param quoteOrderQty (scalar<numeric>?) quote asset quantity (market orders only).
    #' @param price (scalar<numeric>?) price for limit orders.
    #' @param timeInForce (scalar<character>?) `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param newClientOrderId (scalar<character>?) unique client order ID.
    #' @param stopPrice (scalar<numeric>?) trigger price for stop orders.
    #' @param icebergQty (scalar<numeric>?) iceberg quantity.
    #' @param newOrderRespType (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param selfTradePreventionMode (scalar<character>?)
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per fill (one row with
    #'   `NA` `fill_*` columns when the order had no fills):
    #' - symbol (character) Trading pair (e.g., `"BTCUSDT"`).
    #' - order_id (integer) Unique order identifier assigned by Binance.
    #' - order_list_id (integer) OCO order list ID; `-1` if not an OCO.
    #' - client_order_id (character) Client-assigned order ID.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled so far.
    #' - cummulative_quote_qty (character) Cumulative quote asset transacted.
    #' - status (character) Order status (`"NEW"`, `"FILLED"`, `"CANCELED"`, etc.).
    #' - time_in_force (character) Time-in-force policy (`"GTC"`, `"IOC"`, `"FOK"`).
    #' - type (character) Order type (`"LIMIT"`, `"MARKET"`, etc.).
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - working_time (POSIXct) Time when the order started working.
    #' - self_trade_prevention_mode (character) STP mode applied.
    #' - transact_time (POSIXct) Transaction time converted from `transactTime`.
    #' - fill_index (integer) 1-indexed fill position (`NA` when the order
    #'   had no fills).
    #' - fill_price (character) Fill execution price (`NA` when no fills).
    #' - fill_qty (character) Fill quantity (`NA` when no fills).
    #' - fill_commission (character) Commission charged for this fill
    #'   (`NA` when no fills).
    #' - fill_commission_asset (character) Asset used for commission
    #'   (e.g., `"BNB"`; `NA` when no fills).
    #' - fill_trade_id (integer) Fill trade ID (`NA` when no fills).
    #'
    #' When the order has N fills, the parent order fields are replicated on
    #' each of the N rows and `fill_index` runs `1..N`. When the order has
    #' no fills (e.g. a resting `LIMIT` order with `newOrderRespType = "ACK"`
    #' / `"RESULT"`), a single row is returned with the `fill_*` columns
    #' present as `NA` so the schema is stable across response types.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' order <- trading$add_order(
    #'   type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
    #'   price = 50000, quantity = 0.0001
    #' )
    #' print(order)
    #' }
    add_order = function(
      type,
      symbol,
      side,
      quantity = NULL,
      quoteOrderQty = NULL,
      price = NULL,
      timeInForce = NULL,
      newClientOrderId = NULL,
      stopPrice = NULL,
      icebergQty = NULL,
      newOrderRespType = NULL,
      selfTradePreventionMode = NULL,
      recvWindow = NULL
    ) {
      assert_args_BinanceTrading__add_order(
        type,
        symbol,
        side,
        quantity,
        quoteOrderQty,
        price,
        timeInForce,
        newClientOrderId,
        stopPrice,
        icebergQty,
        newOrderRespType,
        selfTradePreventionMode,
        recvWindow
      )
      body <- validate_order_params(
        type = type,
        symbol = symbol,
        side = side,
        quantity = quantity,
        quoteOrderQty = quoteOrderQty,
        price = price,
        timeInForce = timeInForce,
        newClientOrderId = newClientOrderId,
        stopPrice = stopPrice,
        icebergQty = icebergQty,
        newOrderRespType = newOrderRespType,
        selfTradePreventionMode = selfTradePreventionMode,
        recvWindow = recvWindow
      )

      res <- private$.request(
        endpoint = "/api/v3/order",
        method = "POST",
        body = body,
        .parser = function(data) {
          # Guard against `data = NULL` (empty body / JSON-parse failure).
          # Without this the `data$fills` access below would throw
          # "$ operator applied to NULL".
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_spot_order_ack_fills())
          }
          fills <- data$fills
          data$fills <- NULL
          dt <- as_dt_row(data)
          coerce_cols(dt, c("transact_time", "working_time"), ms_to_datetime)
          # Expand fills to long format: one row per fill with parent
          # fields repeated, plus a 1-indexed `fill_index`. To keep the
          # returned schema stable across orders with and without fills,
          # always emit the `fill_*` columns — empty when the order had
          # no fills, populated otherwise.
          if (!is.null(fills) && length(fills) > 0) {
            fills_dt <- as_dt_list(fills)
            fill_names <- names(fills_dt)
            data.table::setnames(fills_dt, fill_names, paste0("fill_", fill_names))
            fills_dt[, fill_index := seq_len(.N)]
            dt <- dt[rep(1L, nrow(fills_dt))]
            dt <- cbind(dt, fills_dt)
          } else {
            # No fills: one parent row with NA fill_* columns so the
            # schema matches the populated case.
            dt[, fill_index := NA_integer_]
            dt[, fill_price := NA_character_]
            dt[, fill_qty := NA_character_]
            dt[, fill_commission := NA_character_]
            dt[, fill_commission_asset := NA_character_]
            dt[, fill_trade_id := NA_integer_]
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__add_order,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Test Order Placement
    #'
    #' Simulates placing an order without execution. Validates all parameters
    #' and authentication exactly as `add_order()`, but no order is actually created.
    #' Returns `{}` on success.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/api/v3/order/test`
    #'
    #' ### Official Documentation
    #' [Binance Test New Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#test-new-order-trade)
    #' Verified: 2026-05-22
    #'
    #' ### Automated Trading Usage
    #' - **Parameter Validation**: Verify order parameters are correct before live submission.
    #' - **Auth Testing**: Confirm API credentials work for order placement.
    #' - **Integration Testing**: Test your trading pipeline end-to-end without risk.
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/api/v3/order/test' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&side=BUY&type=LIMIT&timeInForce=GTC&quantity=0.0001&price=50000.00&timestamp=1729176273859&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "side": "BUY",
    #'   "type": "LIMIT",
    #'   "timeInForce": "GTC",
    #'   "quantity": "0.00010000",
    #'   "price": "50000.00000000",
    #'   "timestamp": 1729176273859,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {}
    #' ```
    #'
    #' @param type (scalar<character>) `"LIMIT"` or `"MARKET"` (and stop/take-profit variants).
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param side (scalar<character>) `"BUY"` or `"SELL"`.
    #' @param quantity (scalar<numeric>?) base asset quantity.
    #' @param quoteOrderQty (scalar<numeric>?) quote asset quantity (market orders only).
    #' @param price (scalar<numeric>?) price for limit orders.
    #' @param timeInForce (scalar<character>?) `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param newClientOrderId (scalar<character>?) unique client order ID.
    #' @param stopPrice (scalar<numeric>?) trigger price for stop orders.
    #' @param icebergQty (scalar<numeric>?) iceberg quantity.
    #' @param newOrderRespType (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param selfTradePreventionMode (scalar<character>?)
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) a single row with a single
    #'   `validated` (logical) column,
    #'   set to `TRUE` on success. Binance returns `{}` on a successful
    #'   test order — the absence of an error is the validation
    #'   signal, so we don't fabricate a stub row echoing the request
    #'   parameters (per the cross-package "no stub rows" convention).
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' test <- trading$add_order_test(
    #'   type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
    #'   price = 50000, quantity = 0.0001
    #' )
    #' stopifnot(test$validated)
    #' }
    add_order_test = function(
      type,
      symbol,
      side,
      quantity = NULL,
      quoteOrderQty = NULL,
      price = NULL,
      timeInForce = NULL,
      newClientOrderId = NULL,
      stopPrice = NULL,
      icebergQty = NULL,
      newOrderRespType = NULL,
      selfTradePreventionMode = NULL,
      recvWindow = NULL
    ) {
      assert_args_BinanceTrading__add_order_test(
        type,
        symbol,
        side,
        quantity,
        quoteOrderQty,
        price,
        timeInForce,
        newClientOrderId,
        stopPrice,
        icebergQty,
        newOrderRespType,
        selfTradePreventionMode,
        recvWindow
      )
      body <- validate_order_params(
        type = type,
        symbol = symbol,
        side = side,
        quantity = quantity,
        quoteOrderQty = quoteOrderQty,
        price = price,
        timeInForce = timeInForce,
        newClientOrderId = newClientOrderId,
        stopPrice = stopPrice,
        icebergQty = icebergQty,
        newOrderRespType = newOrderRespType,
        selfTradePreventionMode = selfTradePreventionMode,
        recvWindow = recvWindow
      )

      res <- private$.request(
        endpoint = "/api/v3/order/test",
        method = "POST",
        body = body,
        .parser = function(data) {
          # `{}` on success — Binance's "request would have validated"
          # signal. Per the cross-package convention we don't fabricate
          # a stub row with the request parameters; the absence of an
          # error is the success signal. Return a single-row table with
          # one logical column so callers can write
          # `dt$validated` without checking nrow().
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table(validated = TRUE)[])
          }
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__add_order_test,
        is_async = private$.is_async
      ))
    },

    # ---- Order Cancellation ----

    #' @description
    #' Cancel an Order
    #'
    #' Cancels an active order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.binance.com/api/v3/order`
    #'
    #' ### Official Documentation
    #' [Binance Cancel Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#cancel-order-trade)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE 'https://api.binance.com/api/v3/order?symbol=BTCUSDT&orderId=4293153&timestamp=1729176273859&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "origClientOrderId": "msXkySR3u5uYwpvRMFsi3u",
    #'   "orderId": 4293153,
    #'   "orderListId": -1,
    #'   "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
    #'   "transactTime": 1507725176595,
    #'   "price": "50000.00000000",
    #'   "origQty": "0.00010000",
    #'   "executedQty": "0.00000000",
    #'   "cummulativeQuoteQty": "0.00000000",
    #'   "status": "CANCELED",
    #'   "timeInForce": "GTC",
    #'   "type": "LIMIT",
    #'   "side": "BUY",
    #'   "selfTradePreventionMode": "NONE"
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId (scalar<count>?) the order ID to cancel.
    #' @param origClientOrderId (scalar<character>?) the client order ID to cancel.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - symbol (character) Trading pair.
    #' - orig_client_order_id (character) Original client order ID.
    #' - order_id (integer) Unique order identifier.
    #' - order_list_id (integer) OCO order list ID; `-1` if not an OCO.
    #' - client_order_id (character) New client order ID after cancellation.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled before cancellation.
    #' - cummulative_quote_qty (character) Cumulative quote asset transacted.
    #' - status (character) Order status (typically `"CANCELED"`).
    #' - time_in_force (character) Time-in-force policy.
    #' - type (character) Order type.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - self_trade_prevention_mode (character) STP mode applied.
    #' - transact_time (POSIXct) Cancellation time converted from `transactTime`.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' cancelled <- trading$cancel_order("BTCUSDT", orderId = 12345)
    #' print(cancelled)
    #' }
    cancel_order = function(symbol, orderId = NULL, origClientOrderId = NULL, recvWindow = NULL) {
      assert_args_BinanceTrading__cancel_order(symbol, orderId, origClientOrderId, recvWindow)
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      res <- private$.request(
        endpoint = "/api/v3/order",
        method = "DELETE",
        query = list(
          symbol = symbol,
          orderId = orderId,
          origClientOrderId = origClientOrderId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__cancel_order,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Cancel All Open Orders on a Symbol
    #'
    #' Cancels all active orders on a trading pair.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.binance.com/api/v3/openOrders`
    #'
    #' ### Official Documentation
    #' [Binance Cancel All Open Orders](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#cancel-all-open-orders-on-a-symbol-trade)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE 'https://api.binance.com/api/v3/openOrders?symbol=BTCUSDT&timestamp=1729176273859&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "origClientOrderId": "E6APeyTJvkMvLMYMqu1KQ4",
    #'     "orderId": 11,
    #'     "orderListId": -1,
    #'     "clientOrderId": "pXLV6Hz6mprAcVYpVMTGgx",
    #'     "transactTime": 1684804350068,
    #'     "price": "50000.00000000",
    #'     "origQty": "0.00010000",
    #'     "executedQty": "0.00000000",
    #'     "cummulativeQuoteQty": "0.00000000",
    #'     "status": "CANCELED",
    #'     "timeInForce": "GTC",
    #'     "type": "LIMIT",
    #'     "side": "BUY",
    #'     "selfTradePreventionMode": "NONE"
    #'   },
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "origClientOrderId": "A3EF2HCwxgZPFMrfwbgrhv",
    #'     "orderId": 13,
    #'     "orderListId": -1,
    #'     "clientOrderId": "pXLV6Hz6mprAcVYpVMTGgx",
    #'     "transactTime": 1684804350068,
    #'     "price": "48000.00000000",
    #'     "origQty": "0.00020000",
    #'     "executedQty": "0.00000000",
    #'     "cummulativeQuoteQty": "0.00000000",
    #'     "status": "CANCELED",
    #'     "timeInForce": "GTC",
    #'     "type": "LIMIT",
    #'     "side": "BUY",
    #'     "selfTradePreventionMode": "NONE"
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per cancelled order
    #'   (empty when there were no open orders to cancel, per the cross-package
    #'   "no stub rows" convention — the absence of an error is the success
    #'   signal):
    #'   - symbol (character) Trading pair.
    #'   - orig_client_order_id (character) Original client order ID.
    #'   - order_id (integer) Unique order identifier.
    #'   - order_list_id (integer) OCO order list ID; `-1` if not an OCO.
    #'   - client_order_id (character) New client order ID after cancellation.
    #'   - price (character) Order price.
    #'   - orig_qty (character) Original requested quantity.
    #'   - executed_qty (character) Quantity filled before cancellation.
    #'   - cummulative_quote_qty (character) Cumulative quote asset transacted.
    #'   - status (character) Order status (typically `"CANCELED"`).
    #'   - time_in_force (character) Time-in-force policy.
    #'   - type (character) Order type.
    #'   - side (character) `"BUY"` or `"SELL"`.
    #'   - self_trade_prevention_mode (character) STP mode applied.
    #'   - transact_time (POSIXct) Cancellation time.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' cancelled <- trading$cancel_all_orders("BTCUSDT")
    #' print(cancelled)
    #' }
    cancel_all_orders = function(symbol, recvWindow = NULL) {
      assert_args_BinanceTrading__cancel_all_orders(symbol, recvWindow)
      res <- private$.request(
        endpoint = "/api/v3/openOrders",
        method = "DELETE",
        query = list(symbol = symbol, recvWindow = recvWindow),
        .parser = function(data) {
          # Per the cross-package "empty response → empty data.table,
          # no stub rows" convention: when there were no orders to
          # cancel, return the typed empty table rather than fabricate a
          # synthetic `(symbol, status = "cancelled")` row that pretends
          # to be a cancelled order. The absence of an error is the
          # success signal.
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_spot_cancel())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__cancel_all_orders,
        is_async = private$.is_async
      ))
    },

    # ---- Order Queries ----

    #' @description
    #' Query Order
    #'
    #' Retrieves details for a specific order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/order`
    #'
    #' ### Official Documentation
    #' [Binance Query Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-order-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/order?symbol=BTCUSDT&orderId=4293153&timestamp=1729176273859&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "orderId": 4293153,
    #'   "orderListId": -1,
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
    #'   "isWorking": true,
    #'   "workingTime": 1507725176595,
    #'   "origQuoteOrderQty": "0.00000000",
    #'   "selfTradePreventionMode": "NONE"
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId (scalar<count>?) the order ID.
    #' @param origClientOrderId (scalar<character>?) the client order ID.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (SpotOrderQuery | promise<SpotOrderQuery>) one row, the order.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' order <- trading$get_order("BTCUSDT", orderId = 12345)
    #' print(order)
    #' }
    get_order = function(symbol, orderId = NULL, origClientOrderId = NULL, recvWindow = NULL) {
      assert_args_BinanceTrading__get_order(symbol, orderId, origClientOrderId, recvWindow)
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      res <- private$.request(
        endpoint = "/api/v3/order",
        query = list(
          symbol = symbol,
          orderId = orderId,
          origClientOrderId = origClientOrderId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, c("time", "update_time", "working_time"), ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__get_order,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Open Orders
    #'
    #' Retrieves all currently open orders, optionally filtered by symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/openOrders`
    #'
    #' ### Official Documentation
    #' [Binance Current Open Orders](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#current-open-orders-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/openOrders?symbol=BTCUSDT&timestamp=1729176273859&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "orderId": 4293153,
    #'     "orderListId": -1,
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
    #'     "isWorking": true,
    #'     "workingTime": 1507725176595,
    #'     "origQuoteOrderQty": "0.00000000",
    #'     "selfTradePreventionMode": "NONE"
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol (scalar<character>?) trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns open orders for all symbols (weight 80).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (SpotOrderQuery | promise<SpotOrderQuery>) one row per open order
    #'   (empty when there are no open orders).
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' open <- trading$get_open_orders("BTCUSDT")
    #' print(open)
    #' }
    get_open_orders = function(symbol = NULL, recvWindow = NULL) {
      assert_args_BinanceTrading__get_open_orders(symbol, recvWindow)
      res <- private$.request(
        endpoint = "/api/v3/openOrders",
        query = list(symbol = symbol, recvWindow = recvWindow),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_spot_order_query())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, c("time", "update_time", "working_time"), ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__get_open_orders,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get All Orders
    #'
    #' Retrieves all orders for a symbol (open, cancelled, filled).
    #' If `orderId` is set, orders >= that ID are returned. Otherwise
    #' the most recent orders are returned.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/allOrders`
    #'
    #' ### Official Documentation
    #' [Binance All Orders](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#all-orders-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/allOrders?symbol=BTCUSDT&limit=50&timestamp=1729176273859&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "orderId": 4293153,
    #'     "orderListId": -1,
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
    #'     "isWorking": true,
    #'     "workingTime": 1507725176595,
    #'     "origQuoteOrderQty": "0.00000000",
    #'     "selfTradePreventionMode": "NONE"
    #'   },
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "orderId": 4293154,
    #'     "orderListId": -1,
    #'     "clientOrderId": "x]]C3kvs44T7fYqJ09VBfg",
    #'     "price": "0.00000000",
    #'     "origQty": "0.00010000",
    #'     "executedQty": "0.00010000",
    #'     "cummulativeQuoteQty": "5.10230000",
    #'     "status": "FILLED",
    #'     "timeInForce": "GTC",
    #'     "type": "MARKET",
    #'     "side": "SELL",
    #'     "stopPrice": "0.00000000",
    #'     "icebergQty": "0.00000000",
    #'     "time": 1507725276595,
    #'     "updateTime": 1507725276595,
    #'     "isWorking": true,
    #'     "workingTime": 1507725276595,
    #'     "origQuoteOrderQty": "0.00000000",
    #'     "selfTradePreventionMode": "NONE"
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId (scalar<count>?) pagination cursor.
    #' @param startTime (scalar<count>?) start timestamp in milliseconds.
    #' @param endTime (scalar<count>?) end timestamp in milliseconds.
    #' @param limit (scalar<count>?) max results (default 500, max 1000).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (SpotOrderQuery | promise<SpotOrderQuery>) one row per order
    #'   (empty when there are no matching orders).
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' all <- trading$get_all_orders("BTCUSDT", limit = 50)
    #' print(all[, .(order_id, side, price, status, time)])
    #' }
    get_all_orders = function(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      assert_args_BinanceTrading__get_all_orders(symbol, orderId, startTime, endTime, limit, recvWindow)
      res <- private$.request(
        endpoint = "/api/v3/allOrders",
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
            return(empty_dt_spot_order_query())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, c("time", "update_time", "working_time"), ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__get_all_orders,
        is_async = private$.is_async
      ))
    }
  )
)
