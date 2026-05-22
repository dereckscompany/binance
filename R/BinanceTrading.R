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
#' [Binance Spot Trading](https://binance-docs.github.io/apidocs/spot/en/#spot-account-trade)
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
    #' [Binance New Order](https://binance-docs.github.io/apidocs/spot/en/#new-order-trade)
    #' Verified: 2026-03-10
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
    #' @param type Character; `"LIMIT"` or `"MARKET"` (and stop/take-profit variants).
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param side Character; `"BUY"` or `"SELL"`.
    #' @param quantity Numeric or NULL; base asset quantity.
    #' @param quoteOrderQty Numeric or NULL; quote asset quantity (market orders only).
    #' @param price Numeric or NULL; price for limit orders.
    #' @param timeInForce Character or NULL; `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param newClientOrderId Character or NULL; unique client order ID.
    #' @param stopPrice Numeric or NULL; trigger price for stop orders.
    #' @param icebergQty Numeric or NULL; iceberg quantity.
    #' @param newOrderRespType Character or NULL; `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param selfTradePreventionMode Character or NULL.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `symbol` (character): Trading pair (e.g., `"BTCUSDT"`).
    #' - `order_id` (integer): Unique order identifier assigned by Binance.
    #' - `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `cummulative_quote_qty` (character): Cumulative quote asset transacted.
    #' - `status` (character): Order status (`"NEW"`, `"FILLED"`, `"CANCELED"`, etc.).
    #' - `time_in_force` (character): Time-in-force policy (`"GTC"`, `"IOC"`, `"FOK"`).
    #' - `type` (character): Order type (`"LIMIT"`, `"MARKET"`, etc.).
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `working_time` (numeric): Timestamp when the order started working.
    #' - `self_trade_prevention_mode` (character): STP mode applied.
    #' - `transact_time` (POSIXct): Transaction time converted from `transactTime`.
    #' - `fill_index` (integer): 1-indexed fill position (`NA` when the order
    #'   had no fills).
    #' - `fill_price` (character): Fill execution price (`NA` when no fills).
    #' - `fill_qty` (character): Fill quantity (`NA` when no fills).
    #' - `fill_commission` (character): Commission charged for this fill
    #'   (`NA` when no fills).
    #' - `fill_commission_asset` (character): Asset used for commission
    #'   (e.g., `"BNB"`; `NA` when no fills).
    #' - `fill_trade_id` (integer): Fill trade ID (`NA` when no fills).
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

      return(private$.request(
        endpoint = "/api/v3/order",
        method = "POST",
        body = body,
        .parser = function(data) {
          fills <- data$fills
          data$fills <- NULL
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "transact_time" %in% names(dt)) {
            dt[, transact_time := ms_to_datetime(transact_time)]
          }
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
    #' [Binance Test New Order](https://binance-docs.github.io/apidocs/spot/en/#test-new-order-trade)
    #' Verified: 2026-03-10
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
    #' @param type Character; `"LIMIT"` or `"MARKET"` (and stop/take-profit variants).
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param side Character; `"BUY"` or `"SELL"`.
    #' @param quantity Numeric or NULL; base asset quantity.
    #' @param quoteOrderQty Numeric or NULL; quote asset quantity (market orders only).
    #' @param price Numeric or NULL; price for limit orders.
    #' @param timeInForce Character or NULL; `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param newClientOrderId Character or NULL; unique client order ID.
    #' @param stopPrice Numeric or NULL; trigger price for stop orders.
    #' @param icebergQty Numeric or NULL; iceberg quantity.
    #' @param newOrderRespType Character or NULL; `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param selfTradePreventionMode Character or NULL.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`), single row with columns:
    #'   - `symbol` (character): The validated trading pair.
    #'   - `side` (character): `"BUY"` or `"SELL"`.
    #'   - `type` (character): Order type.
    #'   - `status` (character): `"validated"`.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' test <- trading$add_order_test(
    #'   type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
    #'   price = 50000, quantity = 0.0001
    #' )
    #' print(test)
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

      return(private$.request(
        endpoint = "/api/v3/order/test",
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
    #' Cancel an Order
    #'
    #' Cancels an active order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.binance.com/api/v3/order`
    #'
    #' ### Official Documentation
    #' [Binance Cancel Order](https://binance-docs.github.io/apidocs/spot/en/#cancel-order-trade)
    #' Verified: 2026-03-10
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
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; the order ID to cancel.
    #' @param origClientOrderId Character or NULL; the client order ID to cancel.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `orig_client_order_id` (character): Original client order ID.
    #' - `order_id` (integer): Unique order identifier.
    #' - `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.
    #' - `client_order_id` (character): New client order ID after cancellation.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled before cancellation.
    #' - `cummulative_quote_qty` (character): Cumulative quote asset transacted.
    #' - `status` (character): Order status (typically `"CANCELED"`).
    #' - `time_in_force` (character): Time-in-force policy.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `self_trade_prevention_mode` (character): STP mode applied.
    #' - `transact_time` (POSIXct): Cancellation time converted from `transactTime`.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' cancelled <- trading$cancel_order("BTCUSDT", orderId = 12345)
    #' print(cancelled)
    #' }
    cancel_order = function(symbol, orderId = NULL, origClientOrderId = NULL, recvWindow = NULL) {
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      return(private$.request(
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
          if (nrow(dt) > 0 && "transact_time" %in% names(dt)) {
            dt[, transact_time := ms_to_datetime(transact_time)]
          }
          return(dt[])
        }
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
    #' [Binance Cancel All Open Orders](https://binance-docs.github.io/apidocs/spot/en/#cancel-all-open-orders-on-a-symbol-trade)
    #' Verified: 2026-03-10
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
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`).
    #'   When orders are cancelled, one row per order with columns:
    #'   - `symbol` (character): Trading pair.
    #'   - `orig_client_order_id` (character): Original client order ID.
    #'   - `order_id` (integer): Unique order identifier.
    #'   - `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.
    #'   - `client_order_id` (character): New client order ID after cancellation.
    #'   - `price` (character): Order price.
    #'   - `orig_qty` (character): Original requested quantity.
    #'   - `executed_qty` (character): Quantity filled before cancellation.
    #'   - `cummulative_quote_qty` (character): Cumulative quote asset transacted.
    #'   - `status` (character): Order status (typically `"CANCELED"`).
    #'   - `time_in_force` (character): Time-in-force policy.
    #'   - `type` (character): Order type.
    #'   - `side` (character): `"BUY"` or `"SELL"`.
    #'   - `self_trade_prevention_mode` (character): STP mode applied.
    #'   - `transact_time` (POSIXct): Cancellation time.
    #'
    #'   When no open orders exist, a single confirmation row with columns:
    #'   - `symbol` (character): The requested trading pair.
    #'   - `status` (character): `"cancelled"`.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' cancelled <- trading$cancel_all_orders("BTCUSDT")
    #' print(cancelled)
    #' }
    cancel_all_orders = function(symbol, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/api/v3/openOrders",
        method = "DELETE",
        query = list(symbol = symbol, recvWindow = recvWindow),
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
    #' Query Order
    #'
    #' Retrieves details for a specific order by order ID or client order ID.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/order`
    #'
    #' ### Official Documentation
    #' [Binance Query Order](https://binance-docs.github.io/apidocs/spot/en/#query-order-user_data)
    #' Verified: 2026-03-10
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
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; the order ID.
    #' @param origClientOrderId Character or NULL; the client order ID.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `cummulative_quote_qty` (character): Cumulative quote asset transacted.
    #' - `status` (character): Order status (`"NEW"`, `"FILLED"`, `"CANCELED"`, etc.).
    #' - `time_in_force` (character): Time-in-force policy.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `stop_price` (character): Trigger price for stop orders.
    #' - `iceberg_qty` (character): Iceberg quantity.
    #' - `is_working` (logical): Whether the order is on the order book.
    #' - `orig_quote_order_qty` (character): Original quote order quantity.
    #' - `working_time` (numeric): Timestamp when the order started working.
    #' - `self_trade_prevention_mode` (character): STP mode applied.
    #' - `time` (POSIXct): Order creation time converted from `time`.
    #' - `update_time` (POSIXct): Last update time converted from `updateTime`.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' order <- trading$get_order("BTCUSDT", orderId = 12345)
    #' print(order)
    #' }
    get_order = function(symbol, orderId = NULL, origClientOrderId = NULL, recvWindow = NULL) {
      if (is.null(orderId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderId' or 'origClientOrderId' must be provided.")
      }

      return(private$.request(
        endpoint = "/api/v3/order",
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
    #' Get Open Orders
    #'
    #' Retrieves all currently open orders, optionally filtered by symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/openOrders`
    #'
    #' ### Official Documentation
    #' [Binance Current Open Orders](https://binance-docs.github.io/apidocs/spot/en/#current-open-orders-user_data)
    #' Verified: 2026-03-10
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
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns open orders for all symbols (weight 80).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per open order and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `cummulative_quote_qty` (character): Cumulative quote asset transacted.
    #' - `status` (character): Order status (typically `"NEW"` or `"PARTIALLY_FILLED"`).
    #' - `time_in_force` (character): Time-in-force policy.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `stop_price` (character): Trigger price for stop orders.
    #' - `iceberg_qty` (character): Iceberg quantity.
    #' - `is_working` (logical): Whether the order is on the order book.
    #' - `orig_quote_order_qty` (character): Original quote order quantity.
    #' - `working_time` (numeric): Timestamp when the order started working.
    #' - `self_trade_prevention_mode` (character): STP mode applied.
    #' - `time` (POSIXct): Order creation time converted from `time`.
    #' - `update_time` (POSIXct): Last update time converted from `updateTime`.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' open <- trading$get_open_orders("BTCUSDT")
    #' print(open)
    #' }
    get_open_orders = function(symbol = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/api/v3/openOrders",
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
    #' [Binance All Orders](https://binance-docs.github.io/apidocs/spot/en/#all-orders-user_data)
    #' Verified: 2026-03-10
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
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; pagination cursor.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param limit Integer or NULL; max results (default 500, max 1000).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per order and the following columns:
    #' - `symbol` (character): Trading pair.
    #' - `order_id` (integer): Unique order identifier.
    #' - `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.
    #' - `client_order_id` (character): Client-assigned order ID.
    #' - `price` (character): Order price.
    #' - `orig_qty` (character): Original requested quantity.
    #' - `executed_qty` (character): Quantity filled so far.
    #' - `cummulative_quote_qty` (character): Cumulative quote asset transacted.
    #' - `status` (character): Order status (`"NEW"`, `"FILLED"`, `"CANCELED"`, etc.).
    #' - `time_in_force` (character): Time-in-force policy.
    #' - `type` (character): Order type.
    #' - `side` (character): `"BUY"` or `"SELL"`.
    #' - `stop_price` (character): Trigger price for stop orders.
    #' - `iceberg_qty` (character): Iceberg quantity.
    #' - `is_working` (logical): Whether the order is on the order book.
    #' - `orig_quote_order_qty` (character): Original quote order quantity.
    #' - `working_time` (numeric): Timestamp when the order started working.
    #' - `self_trade_prevention_mode` (character): STP mode applied.
    #' - `time` (POSIXct): Order creation time converted from `time`.
    #' - `update_time` (POSIXct): Last update time converted from `updateTime`.
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
      return(private$.request(
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
    }
  )
)
