# File: R/BinanceOcoOrders.R
# R6 class for Binance OCO (One-Cancels-Other) order management.

#' BinanceOcoOrders: OCO Order Management
#'
#' Provides methods for placing, cancelling, and querying OCO (One-Cancels-Other)
#' orders on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **OCO Placement**: Place OCO orders combining a limit and a stop-loss.
#' - **OCO Cancellation**: Cancel an entire OCO order list by ID.
#' - **OCO Queries**: Retrieve a specific OCO, all open OCOs, or historical OCOs.
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
#' | add_oco_order | POST /api/v3/order/oco | POST |
#' | cancel_oco_order | DELETE /api/v3/orderList | DELETE |
#' | get_oco_order | GET /api/v3/orderList | GET |
#' | get_open_oco_orders | GET /api/v3/openOrderList | GET |
#' | get_all_oco_orders | GET /api/v3/allOrderList | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' oco <- BinanceOcoOrders$new()
#' result <- oco$add_oco_order(
#'   symbol = "BTCUSDT", side = "SELL",
#'   quantity = 0.0001, price = 55000, stopPrice = 49000,
#'   stopLimitPrice = 48500, stopLimitTimeInForce = "GTC"
#' )
#' print(result)
#'
#' # Asynchronous
#' oco_async <- BinanceOcoOrders$new(async = TRUE)
#' main <- coro::async(function() {
#'   result <- await(oco_async$get_open_oco_orders())
#'   print(result)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceOcoOrders <- R6::R6Class(
  "BinanceOcoOrders",
  inherit = BinanceBase,
  public = list(
    # ---- OCO Order Placement ----

    #' @description
    #' Place an OCO Order
    #'
    #' Places a new OCO (One-Cancels-Other) order on Binance. An OCO combines
    #' a limit order and a stop-loss (or stop-loss-limit) order.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/api/v3/order/oco`
    #'
    #' ### Official Documentation
    #' [Binance New OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#order-lists)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/api/v3/order/oco' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'symbol=BTCUSDT&side=SELL&quantity=0.0001&price=55000&stopPrice=49000&timestamp=...&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "side": "SELL",
    #'   "quantity": "0.0001",
    #'   "price": "55000",
    #'   "stopPrice": "49000",
    #'   "stopLimitPrice": "48500",
    #'   "stopLimitTimeInForce": "GTC",
    #'   "timestamp": 1563417480525,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "orderListId": 0,
    #'   "contingencyType": "OCO",
    #'   "listStatusType": "EXEC_STARTED",
    #'   "listOrderStatus": "EXECUTING",
    #'   "listClientOrderId": "JYVpp3F0f5CAG15DhtrqLp",
    #'   "transactTime": 1563417480525,
    #'   "symbol": "BTCUSDT",
    #'   "orders": [...],
    #'   "orderReports": [...]
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param side (scalar<character>) `"BUY"` or `"SELL"`.
    #' @param quantity (scalar<numeric>) base asset quantity.
    #' @param price (scalar<numeric>) price for the limit leg.
    #' @param stopPrice (scalar<numeric>) trigger price for the stop-loss leg.
    #' @param stopLimitPrice (scalar<numeric>?) limit price for the stop-loss-limit leg.
    #' @param stopLimitTimeInForce (scalar<character>?) time-in-force for the stop-limit leg
    #'   (`"GTC"`, `"IOC"`, `"FOK"`). Required if `stopLimitPrice` is provided.
    #' @param listClientOrderId (scalar<character>?) unique ID for the entire OCO list.
    #' @param limitClientOrderId (scalar<character>?) unique ID for the limit leg.
    #' @param stopClientOrderId (scalar<character>?) unique ID for the stop-loss leg.
    #' @param limitIcebergQty (scalar<numeric>?) iceberg quantity for the limit leg.
    #' @param stopIcebergQty (scalar<numeric>?) iceberg quantity for the stop-loss leg.
    #' @param newOrderRespType (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param selfTradePreventionMode (scalar<character>?)
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per child order report
    #'   (long format):
    #' - order_list_id (numeric) OCO order list identifier (repeated per child order).
    #' - contingency_type (character) Always `"OCO"`.
    #' - list_status_type (character) Status type (e.g., `"EXEC_STARTED"`).
    #' - list_order_status (character) Order status (e.g., `"EXECUTING"`).
    #' - list_client_order_id (character) Client-assigned list ID.
    #' - transact_time (POSIXct) Transaction time.
    #' - symbol (character) Trading pair from parent OCO.
    #' - order_report_symbol (character) Trading pair from child order report.
    #' - order_report_order_id (numeric) Child order ID.
    #' - order_report_order_list_id (numeric) Child order's OCO list ID.
    #' - order_report_client_order_id (character) Child order client ID.
    #' - order_report_transact_time (POSIXct) Child order transaction time.
    #' - order_report_price (character) Child order price.
    #' - order_report_orig_qty (character) Child order original quantity.
    #' - order_report_executed_qty (character) Child order executed quantity.
    #' - order_report_cummulative_quote_qty (character) Child order cumulative
    #'   quote quantity filled.
    #' - order_report_status (character) Child order status (e.g., `"NEW"`).
    #' - order_report_time_in_force (character) Child order time-in-force policy.
    #' - order_report_type (character) Child order type (e.g., `"STOP_LOSS_LIMIT"`, `"LIMIT_MAKER"`).
    #' - order_report_side (character) Child order side.
    #' - order_report_stop_price (character | NA) Stop price (`NA` for the
    #'   non-stop leg, e.g. the `LIMIT_MAKER` order).
    #' - order_report_self_trade_prevention_mode (character) Self-trade-prevention
    #'   mode.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- BinanceOcoOrders$new()
    #' result <- oco$add_oco_order(
    #'   symbol = "BTCUSDT", side = "SELL",
    #'   quantity = 0.0001, price = 55000, stopPrice = 49000,
    #'   stopLimitPrice = 48500, stopLimitTimeInForce = "GTC"
    #' )
    #' print(result)
    #' }
    add_oco_order = function(
      symbol,
      side,
      quantity,
      price,
      stopPrice,
      stopLimitPrice = NULL,
      stopLimitTimeInForce = NULL,
      listClientOrderId = NULL,
      limitClientOrderId = NULL,
      stopClientOrderId = NULL,
      limitIcebergQty = NULL,
      stopIcebergQty = NULL,
      newOrderRespType = NULL,
      selfTradePreventionMode = NULL,
      recvWindow = NULL
    ) {
      assert_args_BinanceOcoOrders__add_oco_order(
        symbol,
        side,
        quantity,
        price,
        stopPrice,
        stopLimitPrice,
        stopLimitTimeInForce,
        listClientOrderId,
        limitClientOrderId,
        stopClientOrderId,
        limitIcebergQty,
        stopIcebergQty,
        newOrderRespType,
        selfTradePreventionMode,
        recvWindow
      )
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(listClientOrderId, null_ok = TRUE)
      assert::assert_nonempty_strings(limitClientOrderId, null_ok = TRUE)
      assert::assert_nonempty_strings(stopClientOrderId, null_ok = TRUE)
      side <- rlang::arg_match0(side, c("BUY", "SELL"))

      body <- list(
        symbol = symbol,
        side = side,
        quantity = as.character(quantity),
        price = as.character(price),
        stopPrice = as.character(stopPrice),
        stopLimitPrice = if (!is.null(stopLimitPrice)) as.character(stopLimitPrice),
        stopLimitTimeInForce = stopLimitTimeInForce,
        listClientOrderId = listClientOrderId,
        limitClientOrderId = limitClientOrderId,
        stopClientOrderId = stopClientOrderId,
        limitIcebergQty = if (!is.null(limitIcebergQty)) as.character(limitIcebergQty),
        stopIcebergQty = if (!is.null(stopIcebergQty)) as.character(stopIcebergQty),
        newOrderRespType = newOrderRespType,
        selfTradePreventionMode = selfTradePreventionMode,
        recvWindow = recvWindow
      )

      res <- private$.request(
        endpoint = "/api/v3/order/oco",
        method = "POST",
        body = body,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_oco_add())
          }
          order_reports <- data$orderReports
          data$orderReports <- NULL
          data$orders <- NULL
          dt <- as_dt_row(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          # Expand orderReports to long format: one row per child order
          # orderReports is a superset of orders (includes price, qty, status, etc.)
          if (!is.null(order_reports) && length(order_reports) > 0) {
            reports_dt <- as_dt_list(order_reports)
            report_names <- names(reports_dt)
            data.table::setnames(reports_dt, report_names, paste0("order_report_", report_names))
            dt <- dt[rep(1L, nrow(reports_dt))]
            dt <- cbind(dt, reports_dt)
            coerce_cols(dt, "order_report_transact_time", ms_to_datetime)
          }
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(
            dt,
            c("order_list_id", "order_report_order_id", "order_report_order_list_id"),
            as.numeric
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceOcoOrders__add_oco_order,
        is_async = private$.is_async
      ))
    },

    # ---- OCO Order Cancellation ----

    #' @description
    #' Cancel an OCO Order
    #'
    #' Cancels an entire OCO order list by order list ID or client order ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.binance.com/api/v3/orderList`
    #'
    #' ### Official Documentation
    #' [Binance Cancel OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#order-lists)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE 'https://api.binance.com/api/v3/orderList?symbol=BTCUSDT&orderListId=0&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "orderListId": 0,
    #'   "contingencyType": "OCO",
    #'   "listStatusType": "ALL_DONE",
    #'   "listOrderStatus": "ALL_DONE",
    #'   "listClientOrderId": "C3wyj4WVEktd7u9aVBRXcN",
    #'   "transactTime": 1563417480525,
    #'   "symbol": "BTCUSDT",
    #'   "orders": [
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "orderId": 12569099453,
    #'       "clientOrderId": "bfYPSQdLoqAJeNrOr9adzq"
    #'     },
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "orderId": 12569099454,
    #'       "clientOrderId": "0NPFMfBo6cMGlwnSfzBrdg"
    #'     }
    #'   ],
    #'   "orderReports": [
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "orderId": 12569099453,
    #'       "orderListId": 0,
    #'       "clientOrderId": "bfYPSQdLoqAJeNrOr9adzq",
    #'       "transactTime": 1563417480525,
    #'       "price": "55000.00000000",
    #'       "origQty": "0.00010000",
    #'       "executedQty": "0.00000000",
    #'       "cummulativeQuoteQty": "0.00000000",
    #'       "status": "CANCELED",
    #'       "timeInForce": "GTC",
    #'       "type": "LIMIT_MAKER",
    #'       "side": "SELL"
    #'     },
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "orderId": 12569099454,
    #'       "orderListId": 0,
    #'       "clientOrderId": "0NPFMfBo6cMGlwnSfzBrdg",
    #'       "transactTime": 1563417480525,
    #'       "price": "48500.00000000",
    #'       "origQty": "0.00010000",
    #'       "executedQty": "0.00000000",
    #'       "cummulativeQuoteQty": "0.00000000",
    #'       "status": "CANCELED",
    #'       "timeInForce": "GTC",
    #'       "type": "STOP_LOSS_LIMIT",
    #'       "side": "SELL",
    #'       "stopPrice": "49000.00000000"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param orderListId (scalar<count>?) the OCO order list ID.
    #' @param listClientOrderId (scalar<character>?) the client order list ID.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per child order report
    #'   (long format), matching the shape returned by `add_oco_order()`. The
    #'   thinner `orders` array Binance returns is dropped in favour of
    #'   the richer `orderReports` payload, which includes the
    #'   cancellation status, prices, quantities, and stop price for
    #'   each child order:
    #' - order_list_id (numeric) OCO order list identifier (repeated per child order).
    #' - contingency_type (character) Always `"OCO"`.
    #' - list_status_type (character) Status type (e.g., `"ALL_DONE"`).
    #' - list_order_status (character) Order status (e.g., `"ALL_DONE"`).
    #' - list_client_order_id (character) Client-assigned list ID.
    #' - transact_time (POSIXct) Cancellation time (if present).
    #' - symbol (character) Trading pair from parent OCO.
    #' - order_report_symbol (character) Trading pair from child order.
    #' - order_report_order_id (numeric) Child order ID.
    #' - order_report_order_list_id (numeric) Child order's OCO list ID.
    #' - order_report_client_order_id (character) Child order client ID.
    #' - order_report_transact_time (POSIXct) Child order transaction time.
    #' - order_report_price (character) Child order price.
    #' - order_report_orig_qty (character) Child order original quantity.
    #' - order_report_executed_qty (character) Child order executed quantity.
    #' - order_report_cummulative_quote_qty (character) Child order cumulative
    #'   quote quantity filled.
    #' - order_report_status (character) Child order status (e.g., `"CANCELED"`).
    #' - order_report_time_in_force (character) Child order time-in-force policy.
    #' - order_report_type (character) Child order type.
    #' - order_report_side (character) Child order side.
    #' - order_report_stop_price (character | NA) Stop price (`NA` for the
    #'   non-stop leg).
    #' - order_report_self_trade_prevention_mode (character) Self-trade-prevention
    #'   mode.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- BinanceOcoOrders$new()
    #' cancelled <- oco$cancel_oco_order("BTCUSDT", orderListId = 0)
    #' print(cancelled)
    #' }
    cancel_oco_order = function(symbol, orderListId = NULL, listClientOrderId = NULL, recvWindow = NULL) {
      assert_args_BinanceOcoOrders__cancel_oco_order(symbol, orderListId, listClientOrderId, recvWindow)
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(listClientOrderId, null_ok = TRUE)
      if (is.null(orderListId) && is.null(listClientOrderId)) {
        rlang::abort("Either 'orderListId' or 'listClientOrderId' must be provided.")
      }

      res <- private$.request(
        endpoint = "/api/v3/orderList",
        method = "DELETE",
        query = list(
          symbol = symbol,
          orderListId = orderListId,
          listClientOrderId = listClientOrderId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_oco_cancel())
          }
          # Mirror `add_oco_order`: expand `orderReports` to long format
          # (it's the richer payload, including cancellation status,
          # prices, quantities, stop price). The thinner `orders`
          # array duplicates a subset and is dropped.
          order_reports <- data$orderReports
          data$orderReports <- NULL
          data$orders <- NULL
          dt <- as_dt_row(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          if (!is.null(order_reports) && length(order_reports) > 0) {
            reports_dt <- as_dt_list(order_reports)
            report_names <- names(reports_dt)
            data.table::setnames(reports_dt, report_names, paste0("order_report_", report_names))
            dt <- dt[rep(1L, nrow(reports_dt))]
            dt <- cbind(dt, reports_dt)
            coerce_cols(dt, "order_report_transact_time", ms_to_datetime)
          }
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(
            dt,
            c("order_list_id", "order_report_order_id", "order_report_order_list_id"),
            as.numeric
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceOcoOrders__cancel_oco_order,
        is_async = private$.is_async
      ))
    },

    # ---- OCO Order Queries ----

    #' @description
    #' Query an OCO Order
    #'
    #' Retrieves details for a specific OCO order by order list ID or
    #' original client order ID.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/orderList`
    #'
    #' ### Official Documentation
    #' [Binance Query OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-order-list-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/orderList?orderListId=0&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "orderListId": 0,
    #'   "contingencyType": "OCO",
    #'   "listStatusType": "ALL_DONE",
    #'   "listOrderStatus": "ALL_DONE",
    #'   "listClientOrderId": "C3wyj4WVEktd7u9aVBRXcN",
    #'   "transactionTime": 1563417480525,
    #'   "symbol": "BTCUSDT",
    #'   "orders": [
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "orderId": 12569099453,
    #'       "clientOrderId": "bfYPSQdLoqAJeNrOr9adzq"
    #'     },
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "orderId": 12569099454,
    #'       "clientOrderId": "0NPFMfBo6cMGlwnSfzBrdg"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param orderListId (scalar<count>?) the OCO order list ID.
    #' @param origClientOrderId (scalar<character>?) the original client order list ID.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per child order
    #'   (long format):
    #' - order_list_id (numeric) OCO order list identifier (repeated per child order).
    #' - contingency_type (character) Always `"OCO"`.
    #' - list_status_type (character) Status type (e.g., `"ALL_DONE"`).
    #' - list_order_status (character) Order status.
    #' - list_client_order_id (character) Client-assigned list ID.
    #' - transaction_time (POSIXct) Transaction time (if present).
    #' - symbol (character) Trading pair from parent OCO.
    #' - order_symbol (character) Trading pair from child order.
    #' - order_order_id (numeric) Child order ID.
    #' - order_client_order_id (character) Child order client ID.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- BinanceOcoOrders$new()
    #' order <- oco$get_oco_order(orderListId = 0)
    #' print(order)
    #' }
    get_oco_order = function(orderListId = NULL, origClientOrderId = NULL, recvWindow = NULL) {
      assert_args_BinanceOcoOrders__get_oco_order(orderListId, origClientOrderId, recvWindow)
      assert::assert_nonempty_strings(origClientOrderId, null_ok = TRUE)
      if (is.null(orderListId) && is.null(origClientOrderId)) {
        rlang::abort("Either 'orderListId' or 'origClientOrderId' must be provided.")
      }

      res <- private$.request(
        endpoint = "/api/v3/orderList",
        query = list(
          orderListId = orderListId,
          origClientOrderId = origClientOrderId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_oco_query())
          }
          orders <- data$orders
          data$orders <- NULL
          dt <- as_dt_row(data)
          coerce_cols(dt, "transaction_time", ms_to_datetime)
          # Expand orders to long format: one row per child order
          if (!is.null(orders) && length(orders) > 0) {
            orders_dt <- as_dt_list(orders)
            order_names <- names(orders_dt)
            data.table::setnames(orders_dt, order_names, paste0("order_", order_names))
            dt <- dt[rep(1L, nrow(orders_dt))]
            dt <- cbind(dt, orders_dt)
          }
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_list_id", "order_order_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceOcoOrders__get_oco_order,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Open OCO Orders
    #'
    #' Retrieves all currently open OCO order lists.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/openOrderList`
    #'
    #' ### Official Documentation
    #' [Binance Query Open OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-open-order-lists-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/openOrderList?timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "orderListId": 31,
    #'     "contingencyType": "OCO",
    #'     "listStatusType": "EXEC_STARTED",
    #'     "listOrderStatus": "EXECUTING",
    #'     "listClientOrderId": "wuB13fmulKj3YjdqWEcsnp",
    #'     "transactionTime": 1565246080644,
    #'     "symbol": "LTCBTC",
    #'     "orders": [
    #'       {
    #'         "symbol": "LTCBTC",
    #'         "orderId": 4,
    #'         "clientOrderId": "r3EH2N76dHfLoSZWIUw1bT"
    #'       },
    #'       {
    #'         "symbol": "LTCBTC",
    #'         "orderId": 5,
    #'         "clientOrderId": "Cv1SnyPD3qhqpbjpYEHbd2"
    #'       }
    #'     ]
    #'   }
    #' ]
    #' ```
    #'
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per child order across
    #'   all open OCOs (long format; empty when there are no open OCOs):
    #' - order_list_id (numeric) OCO order list identifier (repeated per child order).
    #' - contingency_type (character) Always `"OCO"`.
    #' - list_status_type (character) Status type.
    #' - list_order_status (character) Order status.
    #' - list_client_order_id (character) Client-assigned list ID.
    #' - transaction_time (POSIXct) Transaction time.
    #' - symbol (character) Trading pair from parent OCO.
    #' - order_symbol (character) Trading pair from child order.
    #' - order_order_id (numeric) Child order ID.
    #' - order_client_order_id (character) Child order client ID.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- BinanceOcoOrders$new()
    #' open <- oco$get_open_oco_orders()
    #' print(open)
    #' }
    get_open_oco_orders = function(recvWindow = NULL) {
      assert_args_BinanceOcoOrders__get_open_oco_orders(recvWindow)
      res <- private$.request(
        endpoint = "/api/v3/openOrderList",
        query = list(recvWindow = recvWindow),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_oco_query())
          }
          # Expand each OCO's orders to long format
          rows <- lapply(data, function(oco) {
            orders <- oco$orders
            oco$orders <- NULL
            parent_dt <- as_dt_row(oco)
            coerce_cols(parent_dt, "transaction_time", ms_to_datetime)
            if (!is.null(orders) && length(orders) > 0) {
              orders_dt <- as_dt_list(orders)
              order_names <- names(orders_dt)
              data.table::setnames(orders_dt, order_names, paste0("order_", order_names))
              parent_dt <- parent_dt[rep(1L, nrow(orders_dt))]
              parent_dt <- cbind(parent_dt, orders_dt)
            }
            return(parent_dt)
          })
          dt <- data.table::rbindlist(rows, fill = TRUE)
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_list_id", "order_order_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceOcoOrders__get_open_oco_orders,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get All OCO Orders
    #'
    #' Retrieves all OCO order lists (open, cancelled, done). If `fromId` is set,
    #' returns OCOs with order list ID >= that value. Otherwise returns the most
    #' recent OCOs.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/allOrderList`
    #'
    #' ### Official Documentation
    #' [Binance Query All OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-all-order-lists-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/allOrderList?limit=50&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "orderListId": 29,
    #'     "contingencyType": "OCO",
    #'     "listStatusType": "EXEC_STARTED",
    #'     "listOrderStatus": "EXECUTING",
    #'     "listClientOrderId": "amEEAXryFzFwYF1FeRpUoZ",
    #'     "transactionTime": 1565245913483,
    #'     "symbol": "LTCBTC",
    #'     "orders": [
    #'       {
    #'         "symbol": "LTCBTC",
    #'         "orderId": 4,
    #'         "clientOrderId": "oD7aesZqjEGlZrbtRpy5zB"
    #'       },
    #'       {
    #'         "symbol": "LTCBTC",
    #'         "orderId": 5,
    #'         "clientOrderId": "Jr1h6xirOxgeJOUuYQS7V3"
    #'       }
    #'     ]
    #'   },
    #'   {
    #'     "orderListId": 30,
    #'     "contingencyType": "OCO",
    #'     "listStatusType": "ALL_DONE",
    #'     "listOrderStatus": "ALL_DONE",
    #'     "listClientOrderId": "XbijSrMBk4cGLvoDYtU08w",
    #'     "transactionTime": 1565245913847,
    #'     "symbol": "BTCUSDT",
    #'     "orders": [
    #'       {
    #'         "symbol": "BTCUSDT",
    #'         "orderId": 8,
    #'         "clientOrderId": "pO9ufTiFGg3ndn3Kq7BuSA"
    #'       },
    #'       {
    #'         "symbol": "BTCUSDT",
    #'         "orderId": 9,
    #'         "clientOrderId": "TXOvglzXuaubXAaENpaRCB"
    #'       }
    #'     ]
    #'   }
    #' ]
    #' ```
    #'
    #' @param fromId (scalar<count>?) pagination cursor (orderListId).
    #' @param startTime (scalar<count>?) start timestamp in milliseconds.
    #' @param endTime (scalar<count>?) end timestamp in milliseconds.
    #' @param limit (scalar<count>?) max results (default 500, max 1000).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per child order across
    #'   all OCOs (long format; empty when there are no matching OCOs):
    #' - order_list_id (numeric) OCO order list identifier (repeated per child order).
    #' - contingency_type (character) Always `"OCO"`.
    #' - list_status_type (character) Status type.
    #' - list_order_status (character) Order status.
    #' - list_client_order_id (character) Client-assigned list ID.
    #' - transaction_time (POSIXct) Transaction time.
    #' - symbol (character) Trading pair from parent OCO.
    #' - order_symbol (character) Trading pair from child order.
    #' - order_order_id (numeric) Child order ID.
    #' - order_client_order_id (character) Child order client ID.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- BinanceOcoOrders$new()
    #' all <- oco$get_all_oco_orders(limit = 50)
    #' print(all)
    #' }
    get_all_oco_orders = function(
      fromId = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      assert_args_BinanceOcoOrders__get_all_oco_orders(fromId, startTime, endTime, limit, recvWindow)
      res <- private$.request(
        endpoint = "/api/v3/allOrderList",
        query = list(
          fromId = fromId,
          startTime = startTime,
          endTime = endTime,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_oco_query())
          }
          # Expand each OCO's orders to long format
          rows <- lapply(data, function(oco) {
            orders <- oco$orders
            oco$orders <- NULL
            parent_dt <- as_dt_row(oco)
            coerce_cols(parent_dt, "transaction_time", ms_to_datetime)
            if (!is.null(orders) && length(orders) > 0) {
              orders_dt <- as_dt_list(orders)
              order_names <- names(orders_dt)
              data.table::setnames(orders_dt, order_names, paste0("order_", order_names))
              parent_dt <- parent_dt[rep(1L, nrow(orders_dt))]
              parent_dt <- cbind(parent_dt, orders_dt)
            }
            return(parent_dt)
          })
          dt <- data.table::rbindlist(rows, fill = TRUE)
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("order_list_id", "order_order_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceOcoOrders__get_all_oco_orders,
        is_async = private$.is_async
      ))
    }
  )
)
