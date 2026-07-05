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

    # nolint start: line_length_linter.
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
    #' - **Response Type**: Use `new_order_resp_type = "FULL"` to get fill details in the response.
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
    #' @param quote_order_qty (scalar<numeric>?) quote asset quantity (market orders only).
    #' @param price (scalar<numeric>?) price for limit orders.
    #' @param time_in_force (scalar<character>?) `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param new_client_order_id (scalar<character>?) unique client order ID.
    #' @param stop_price (scalar<numeric>?) trigger price for stop orders.
    #' @param iceberg_qty (scalar<numeric>?) iceberg quantity.
    #' @param new_order_resp_type (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param self_trade_prevention_mode (scalar<character>?)
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per fill (one row with
    #'   `NA` `fill_*` columns when the order had no fills):
    #' - symbol (character) Trading pair (e.g., `"BTCUSDT"`).
    #' - order_id (numeric) Unique order identifier assigned by Binance.
    #' - order_list_id (numeric) OCO order list ID; `-1` if not an OCO.
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
    #' - fill_index (integer | NA) 1-indexed fill position (`NA` when the order
    #'   had no fills).
    #' - fill_price (character | NA) Fill execution price (`NA` when no fills).
    #' - fill_qty (character | NA) Fill quantity (`NA` when no fills).
    #' - fill_commission (character | NA) Commission charged for this fill
    #'   (`NA` when no fills).
    #' - fill_commission_asset (character | NA) Asset used for commission
    #'   (e.g., `"BNB"`; `NA` when no fills).
    #' - fill_trade_id (numeric | NA) Fill trade ID (a 64-bit id; `numeric` to
    #'   avoid 32-bit overflow; `NA` when no fills).
    #'
    #' When the order has N fills, the parent order fields are replicated on
    #' each of the N rows and `fill_index` runs `1..N`. When the order has
    #' no fills (e.g. a resting `LIMIT` order with `new_order_resp_type = "ACK"`
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
    # nolint end
    add_order = function(
      type,
      symbol,
      side,
      quantity = NULL,
      quote_order_qty = NULL,
      price = NULL,
      time_in_force = NULL,
      new_client_order_id = NULL,
      stop_price = NULL,
      iceberg_qty = NULL,
      new_order_resp_type = NULL,
      self_trade_prevention_mode = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceTrading__add_order(
        type,
        symbol,
        side,
        quantity,
        quote_order_qty,
        price,
        time_in_force,
        new_client_order_id,
        stop_price,
        iceberg_qty,
        new_order_resp_type,
        self_trade_prevention_mode,
        recv_window
      )
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(new_client_order_id, null_ok = TRUE)
      body <- validate_order_params(
        type = type,
        symbol = symbol,
        side = side,
        quantity = quantity,
        quote_order_qty = quote_order_qty,
        price = price,
        time_in_force = time_in_force,
        new_client_order_id = new_client_order_id,
        stop_price = stop_price,
        iceberg_qty = iceberg_qty,
        new_order_resp_type = new_order_resp_type,
        self_trade_prevention_mode = self_trade_prevention_mode,
        recv_window = recv_window
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
          # 64-bit ids: coerce to numeric so a large id never overflows the
          # 32-bit integer the small-id fixtures would otherwise yield.
          coerce_cols(dt, c("order_id", "order_list_id", "fill_trade_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__add_order,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' @param quote_order_qty (scalar<numeric>?) quote asset quantity (market orders only).
    #' @param price (scalar<numeric>?) price for limit orders.
    #' @param time_in_force (scalar<character>?) `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param new_client_order_id (scalar<character>?) unique client order ID.
    #' @param stop_price (scalar<numeric>?) trigger price for stop orders.
    #' @param iceberg_qty (scalar<numeric>?) iceberg quantity.
    #' @param new_order_resp_type (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param self_trade_prevention_mode (scalar<character>?)
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) a single row. Binance returns
    #'   `{}` on a successful test order — the absence of an error is the
    #'   validation signal, so we don't fabricate a stub row echoing the request
    #'   parameters (per the cross-package "no stub rows" convention).
    #'   - validated (logical) `TRUE` on a successful test order.
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
    # nolint end
    add_order_test = function(
      type,
      symbol,
      side,
      quantity = NULL,
      quote_order_qty = NULL,
      price = NULL,
      time_in_force = NULL,
      new_client_order_id = NULL,
      stop_price = NULL,
      iceberg_qty = NULL,
      new_order_resp_type = NULL,
      self_trade_prevention_mode = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceTrading__add_order_test(
        type,
        symbol,
        side,
        quantity,
        quote_order_qty,
        price,
        time_in_force,
        new_client_order_id,
        stop_price,
        iceberg_qty,
        new_order_resp_type,
        self_trade_prevention_mode,
        recv_window
      )
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(new_client_order_id, null_ok = TRUE)
      body <- validate_order_params(
        type = type,
        symbol = symbol,
        side = side,
        quantity = quantity,
        quote_order_qty = quote_order_qty,
        price = price,
        time_in_force = time_in_force,
        new_client_order_id = new_client_order_id,
        stop_price = stop_price,
        iceberg_qty = iceberg_qty,
        new_order_resp_type = new_order_resp_type,
        self_trade_prevention_mode = self_trade_prevention_mode,
        recv_window = recv_window
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

    # nolint start: line_length_linter.
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
    #' @param order_id (scalar<count>?) the order ID to cancel.
    #' @param orig_client_order_id (scalar<character>?) the client order ID to cancel.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - symbol (character) Trading pair.
    #' - orig_client_order_id (character) Original client order ID.
    #' - order_id (numeric) Unique order identifier.
    #' - order_list_id (numeric) OCO order list ID; `-1` if not an OCO.
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
    #' cancelled <- trading$cancel_order("BTCUSDT", order_id = 12345)
    #' print(cancelled)
    #' }
    # nolint end
    cancel_order = function(symbol, order_id = NULL, orig_client_order_id = NULL, recv_window = NULL) {
      assert_args_BinanceTrading__cancel_order(symbol, order_id, orig_client_order_id, recv_window)
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(orig_client_order_id, null_ok = TRUE)
      if (is.null(order_id) && is.null(orig_client_order_id)) {
        rlang::abort("Either 'order_id' or 'orig_client_order_id' must be provided.")
      }

      res <- private$.request(
        endpoint = "/api/v3/order",
        method = "DELETE",
        query = list(
          symbol = symbol,
          orderId = order_id,
          origClientOrderId = orig_client_order_id,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_id", "order_list_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__cancel_order,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per cancelled order
    #'   (empty when there were no open orders to cancel, per the cross-package
    #'   "no stub rows" convention — the absence of an error is the success
    #'   signal):
    #'   - symbol (character) Trading pair.
    #'   - orig_client_order_id (character) Original client order ID.
    #'   - order_id (numeric) Unique order identifier.
    #'   - order_list_id (numeric) OCO order list ID; `-1` if not an OCO.
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
    # nolint end
    cancel_all_orders = function(symbol, recv_window = NULL) {
      assert_args_BinanceTrading__cancel_all_orders(symbol, recv_window)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v3/openOrders",
        method = "DELETE",
        query = list(symbol = symbol, recvWindow = recv_window),
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
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_id", "order_list_id"), as.numeric)
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

    # nolint start: line_length_linter.
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
    #' @param order_id (scalar<count>?) the order ID.
    #' @param orig_client_order_id (scalar<character>?) the client order ID.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (SpotOrderQuery | promise<SpotOrderQuery>) one row, the order.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' order <- trading$get_order("BTCUSDT", order_id = 12345)
    #' print(order)
    #' }
    # nolint end
    get_order = function(symbol, order_id = NULL, orig_client_order_id = NULL, recv_window = NULL) {
      assert_args_BinanceTrading__get_order(symbol, order_id, orig_client_order_id, recv_window)
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(orig_client_order_id, null_ok = TRUE)
      if (is.null(order_id) && is.null(orig_client_order_id)) {
        rlang::abort("Either 'order_id' or 'orig_client_order_id' must be provided.")
      }

      res <- private$.request(
        endpoint = "/api/v3/order",
        query = list(
          symbol = symbol,
          orderId = order_id,
          origClientOrderId = orig_client_order_id,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, c("time", "update_time", "working_time"), ms_to_datetime)
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_id", "order_list_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__get_order,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per open order
    #'   (empty when there are none):
    #' - symbol (character) Trading pair.
    #' - order_id (numeric) Exchange-assigned order id.
    #' - order_list_id (numeric) OCO list id, or `-1` for a non-OCO order.
    #' - client_order_id (character) Client-assigned order id.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled so far.
    #' - cummulative_quote_qty (character) Cumulative quote quantity filled.
    #' - status (character) Order status.
    #' - time_in_force (character) Time-in-force policy.
    #' - type (character) Order type.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - stop_price (character) Stop trigger price.
    #' - iceberg_qty (character) Iceberg quantity.
    #' - time (POSIXct) Order creation time.
    #' - is_working (logical) Whether the order is on the book.
    #' - orig_quote_order_qty (character) Original quote order quantity.
    #' - working_time (POSIXct) Time the order started working.
    #' - self_trade_prevention_mode (character) Self-trade-prevention mode.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' open <- trading$get_open_orders("BTCUSDT")
    #' print(open)
    #' }
    # nolint end
    get_open_orders = function(symbol = NULL, recv_window = NULL) {
      assert_args_BinanceTrading__get_open_orders(symbol, recv_window)
      assert::assert_nonempty_strings(symbol, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/api/v3/openOrders",
        query = list(symbol = symbol, recvWindow = recv_window),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_spot_order_list())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, c("time", "update_time", "working_time"), ms_to_datetime)
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_id", "order_list_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTrading__get_open_orders,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' @param order_id (scalar<count>?) pagination cursor.
    #' @param start_time (scalar<count>?) start timestamp in milliseconds.
    #' @param end_time (scalar<count>?) end timestamp in milliseconds.
    #' @param limit (scalar<count>?) max results (default 500, max 1000).
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per order
    #'   (empty when there are no matching orders):
    #' - symbol (character) Trading pair.
    #' - order_id (numeric) Exchange-assigned order id.
    #' - order_list_id (numeric) OCO list id, or `-1` for a non-OCO order.
    #' - client_order_id (character) Client-assigned order id.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled so far.
    #' - cummulative_quote_qty (character) Cumulative quote quantity filled.
    #' - status (character) Order status.
    #' - time_in_force (character) Time-in-force policy.
    #' - type (character) Order type.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - stop_price (character) Stop trigger price.
    #' - iceberg_qty (character) Iceberg quantity.
    #' - time (POSIXct) Order creation time.
    #' - is_working (logical) Whether the order is on the book.
    #' - orig_quote_order_qty (character) Original quote order quantity.
    #' - working_time (POSIXct) Time the order started working.
    #' - self_trade_prevention_mode (character) Self-trade-prevention mode.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- BinanceTrading$new()
    #' all <- trading$get_all_orders("BTCUSDT", limit = 50)
    #' print(all[, .(order_id, side, price, status, time)])
    #' }
    # nolint end
    get_all_orders = function(
      symbol,
      order_id = NULL,
      start_time = NULL,
      end_time = NULL,
      limit = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceTrading__get_all_orders(symbol, order_id, start_time, end_time, limit, recv_window)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v3/allOrders",
        query = list(
          symbol = symbol,
          orderId = order_id,
          startTime = start_time,
          endTime = end_time,
          limit = limit,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_spot_order_list())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, c("time", "update_time", "working_time"), ms_to_datetime)
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_id", "order_list_id"), as.numeric)
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
