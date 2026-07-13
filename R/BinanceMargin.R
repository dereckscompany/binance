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

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param asset (scalar<character>) asset to borrow (e.g., `"USDT"`).
    #' @param amount (scalar<numeric>) amount to borrow.
    #' @param is_isolated (scalar<character>) `"TRUE"` or `"FALSE"` for isolated margin. Default `"FALSE"`.
    #' @param symbol (scalar<character>?) required when `is_isolated = "TRUE"`.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - tran_id (numeric) Transaction identifier (a large integer that overflows
    #'   R's 32-bit `integer`, so it is coerced to a double).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' result <- margin$add_borrow(asset = "USDT", amount = 100)
    #' print(result)
    #' }
    # nolint end
    add_borrow = function(asset, amount, is_isolated = "FALSE", symbol = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__add_borrow(asset, amount, is_isolated, symbol, recv_window)
      assert::assert_nonempty_strings(asset)
      assert::assert_nonempty_strings(symbol, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/borrow-repay",
        method = "POST",
        query = list(
          asset = asset,
          amount = as.character(amount),
          type = "BORROW",
          isIsolated = is_isolated,
          symbol = symbol,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "tran_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__add_borrow,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param asset (scalar<character>) asset to repay (e.g., `"USDT"`).
    #' @param amount (scalar<numeric>) amount to repay.
    #' @param is_isolated (scalar<character>) `"TRUE"` or `"FALSE"` for isolated margin. Default `"FALSE"`.
    #' @param symbol (scalar<character>?) required when `is_isolated = "TRUE"`.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - tran_id (numeric) Transaction identifier (a large integer that overflows
    #'   R's 32-bit `integer`, so it is coerced to a double).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' result <- margin$add_repay(asset = "USDT", amount = 100)
    #' print(result)
    #' }
    # nolint end
    add_repay = function(asset, amount, is_isolated = "FALSE", symbol = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__add_repay(asset, amount, is_isolated, symbol, recv_window)
      assert::assert_nonempty_strings(asset)
      assert::assert_nonempty_strings(symbol, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/borrow-repay",
        method = "POST",
        query = list(
          asset = asset,
          amount = as.character(amount),
          type = "REPAY",
          isIsolated = is_isolated,
          symbol = symbol,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "tran_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__add_repay,
        is_async = private$.is_async
      ))
    },

    # ---- Order Management ----

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param side (scalar<character>) `"BUY"` or `"SELL"`.
    #' @param type (scalar<character>) order type: `"LIMIT"`, `"MARKET"`, `"STOP_LOSS"`,
    #'   `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`, `"TAKE_PROFIT_LIMIT"`, `"LIMIT_MAKER"`.
    #' @param quantity (scalar<numeric>?) base asset quantity.
    #' @param quote_order_qty (scalar<numeric>?) quote asset quantity (market orders only).
    #' @param price (scalar<numeric>?) price for limit orders.
    #' @param stop_price (scalar<numeric>?) trigger price for stop orders.
    #' @param time_in_force (scalar<character>?) `"GTC"`, `"IOC"`, `"FOK"`.
    #' @param new_client_order_id (scalar<character>?) unique client order ID.
    #' @param new_order_resp_type (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
    #' @param side_effect_type (scalar<character>?) `"NO_SIDE_EFFECT"`, `"MARGIN_BUY"`, `"AUTO_REPAY"`.
    #' @param is_isolated (scalar<character>?) `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - symbol (character) Trading pair.
    #' - order_id (numeric) Unique order identifier.
    #' - client_order_id (character) Client-assigned order ID.
    #' - transact_time (POSIXct) Transaction time.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled so far.
    #' - status (character) Order status.
    #' - type (character) Order type.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - is_isolated (logical) Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' order <- margin$add_order(
    #'   symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
    #'   price = 50000, quantity = 0.0001, time_in_force = "GTC"
    #' )
    #' print(order)
    #' }
    # nolint end
    add_order = function(
      symbol,
      side,
      type,
      quantity = NULL,
      quote_order_qty = NULL,
      price = NULL,
      stop_price = NULL,
      time_in_force = NULL,
      new_client_order_id = NULL,
      new_order_resp_type = NULL,
      side_effect_type = NULL,
      is_isolated = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceMargin__add_order(
        symbol,
        side,
        type,
        quantity,
        quote_order_qty,
        price,
        stop_price,
        time_in_force,
        new_client_order_id,
        new_order_resp_type,
        side_effect_type,
        is_isolated,
        recv_window
      )
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(new_client_order_id, null_ok = TRUE)
      side <- toupper(side)
      type <- toupper(type)
      rlang::arg_match0(side, c("BUY", "SELL"))
      rlang::arg_match0(
        type,
        c("LIMIT", "MARKET", "STOP_LOSS", "STOP_LOSS_LIMIT", "TAKE_PROFIT", "TAKE_PROFIT_LIMIT", "LIMIT_MAKER")
      )

      if (!is.null(side_effect_type)) {
        side_effect_type <- toupper(side_effect_type)
        rlang::arg_match0(side_effect_type, c("NO_SIDE_EFFECT", "MARGIN_BUY", "AUTO_REPAY"))
      }

      # Convert numeric values to character for precision
      if (!is.null(price)) {
        price <- as.character(price)
      }
      if (!is.null(quantity)) {
        quantity <- as.character(quantity)
      }
      if (!is.null(quote_order_qty)) {
        quote_order_qty <- as.character(quote_order_qty)
      }
      if (!is.null(stop_price)) {
        stop_price <- as.character(stop_price)
      }

      res <- private$.request(
        endpoint = "/sapi/v1/margin/order",
        method = "POST",
        query = list(
          symbol = symbol,
          side = side,
          type = type,
          quantity = quantity,
          quoteOrderQty = quote_order_qty,
          price = price,
          stopPrice = stop_price,
          timeInForce = time_in_force,
          newClientOrderId = new_client_order_id,
          newOrderRespType = new_order_resp_type,
          sideEffectType = side_effect_type,
          isIsolated = is_isolated,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          # 64-bit order id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "order_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__add_order,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param order_id (scalar<count>?) the order ID to cancel.
    #' @param orig_client_order_id (scalar<character>?) the client order ID to cancel.
    #' @param is_isolated (scalar<character>?) `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - symbol (character) Trading pair.
    #' - order_id (numeric) Unique order identifier.
    #' - orig_client_order_id (character) Original client order ID.
    #' - status (character) Order status (typically `"CANCELED"`).
    #' - transact_time (POSIXct) Cancellation time.
    #' - is_isolated (logical) Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' cancelled <- margin$cancel_order("BTCUSDT", order_id = 28)
    #' print(cancelled)
    #' }
    # nolint end
    cancel_order = function(
      symbol,
      order_id = NULL,
      orig_client_order_id = NULL,
      is_isolated = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceMargin__cancel_order(symbol, order_id, orig_client_order_id, is_isolated, recv_window)
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(orig_client_order_id, null_ok = TRUE)
      if (is.null(order_id) && is.null(orig_client_order_id)) {
        abort_binance_validation_error("Either 'order_id' or 'orig_client_order_id' must be provided.")
      }

      res <- private$.request(
        endpoint = "/sapi/v1/margin/order",
        method = "DELETE",
        query = list(
          symbol = symbol,
          orderId = order_id,
          origClientOrderId = orig_client_order_id,
          isIsolated = is_isolated,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          # 64-bit order id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "order_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__cancel_order,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param is_isolated (scalar<character>?) `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per cancelled order
    #'   (empty when there were no open orders to cancel, per the cross-package
    #'   "no stub rows" convention — the absence of an error is the success
    #'   signal):
    #'   - symbol (character) Trading pair.
    #'   - order_id (numeric) Unique order identifier.
    #'   - orig_client_order_id (character) Original client order ID.
    #'   - status (character) Order status (typically `"CANCELED"`).
    #'   - transact_time (POSIXct) Cancellation time.
    #'   - is_isolated (logical) Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' cancelled <- margin$cancel_all_orders("BTCUSDT")
    #' print(cancelled)
    #' }
    # nolint end
    cancel_all_orders = function(symbol, is_isolated = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__cancel_all_orders(symbol, is_isolated, recv_window)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/openOrders",
        method = "DELETE",
        query = list(
          symbol = symbol,
          isIsolated = is_isolated,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          # Per the cross-package "empty response → empty data.table,
          # no stub rows" convention: no orders to cancel ⇒ empty table.
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_margin_cancel())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "transact_time", ms_to_datetime)
          # 64-bit order id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "order_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__cancel_all_orders,
        is_async = private$.is_async
      ))
    },

    # ---- Order Queries ----

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param order_id (scalar<count>?) the order ID.
    #' @param orig_client_order_id (scalar<character>?) the client order ID.
    #' @param is_isolated (scalar<character>?) `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - symbol (character) Trading pair.
    #' - order_id (numeric) Unique order identifier.
    #' - client_order_id (character) Client-assigned order ID.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled so far.
    #' - status (character) Order status.
    #' - type (character) Order type.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - time (POSIXct) Order creation time.
    #' - update_time (POSIXct) Last update time.
    #' - is_isolated (logical) Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' order <- margin$get_order("BTCUSDT", order_id = 28)
    #' print(order)
    #' }
    # nolint end
    get_order = function(symbol, order_id = NULL, orig_client_order_id = NULL, is_isolated = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__get_order(symbol, order_id, orig_client_order_id, is_isolated, recv_window)
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(orig_client_order_id, null_ok = TRUE)
      if (is.null(order_id) && is.null(orig_client_order_id)) {
        abort_binance_validation_error("Either 'order_id' or 'orig_client_order_id' must be provided.")
      }

      res <- private$.request(
        endpoint = "/sapi/v1/margin/order",
        query = list(
          symbol = symbol,
          orderId = order_id,
          origClientOrderId = orig_client_order_id,
          isIsolated = is_isolated,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, c("time", "update_time"), ms_to_datetime)
          # 64-bit order id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "order_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_order,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>?) trading pair (e.g., `"BTCUSDT"`).
    #' @param is_isolated (scalar<character>?) `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per open order
    #'   (empty when there are none):
    #' - symbol (character) Trading pair.
    #' - order_id (numeric) Unique order identifier.
    #' - client_order_id (character) Client-assigned order ID.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled so far.
    #' - status (character) Order status.
    #' - type (character) Order type.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - time (POSIXct) Order creation time.
    #' - update_time (POSIXct) Last update time.
    #' - is_isolated (logical) Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' open <- margin$get_open_orders("BTCUSDT")
    #' print(open)
    #' }
    # nolint end
    get_open_orders = function(symbol = NULL, is_isolated = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__get_open_orders(symbol, is_isolated, recv_window)
      assert::assert_nonempty_strings(symbol, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/openOrders",
        query = list(
          symbol = symbol,
          isIsolated = is_isolated,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_margin_order_query())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, c("time", "update_time"), ms_to_datetime)
          # 64-bit order id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "order_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_open_orders,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param order_id (scalar<count>?) pagination cursor.
    #' @param start_time (scalar<count>?) start timestamp in milliseconds.
    #' @param end_time (scalar<count>?) end timestamp in milliseconds.
    #' @param limit (scalar<count>?) max results (default 500, max 500).
    #' @param is_isolated (scalar<character>?) `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per order
    #'   (empty when there are no matching orders):
    #' - symbol (character) Trading pair.
    #' - order_id (numeric) Unique order identifier.
    #' - client_order_id (character) Client-assigned order ID.
    #' - price (character) Order price.
    #' - orig_qty (character) Original requested quantity.
    #' - executed_qty (character) Quantity filled so far.
    #' - status (character) Order status.
    #' - type (character) Order type.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - time (POSIXct) Order creation time.
    #' - update_time (POSIXct) Last update time.
    #' - is_isolated (logical) Whether this is an isolated margin order.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' all <- margin$get_all_orders("BTCUSDT", limit = 50)
    #' print(all)
    #' }
    # nolint end
    get_all_orders = function(
      symbol,
      order_id = NULL,
      start_time = NULL,
      end_time = NULL,
      limit = NULL,
      is_isolated = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceMargin__get_all_orders(symbol, order_id, start_time, end_time, limit, is_isolated, recv_window)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/allOrders",
        query = list(
          symbol = symbol,
          orderId = order_id,
          startTime = start_time,
          endTime = end_time,
          limit = limit,
          isIsolated = is_isolated,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_margin_order_query())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, c("time", "update_time"), ms_to_datetime)
          # 64-bit order id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "order_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_all_orders,
        is_async = private$.is_async
      ))
    },

    # ---- Account Queries ----

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per user asset:
    #' - borrow_enabled (logical) Whether borrowing is enabled.
    #' - margin_level (character) Current margin level.
    #' - total_asset_of_btc (character) Total asset value in BTC.
    #' - total_liability_of_btc (character) Total liability in BTC.
    #' - total_net_asset_of_btc (character) Net asset value in BTC.
    #' - trade_enabled (logical) Whether trading is enabled.
    #' - transfer_enabled (logical) Whether transfers are enabled.
    #' - account_type (character) Account type (`"MARGIN"`).
    #'
    #' Per-asset fields are prefixed with `user_asset_`, one row per asset.
    #' When the account has multiple assets, account-level fields are repeated on each row.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' account <- margin$get_account()
    #' print(account)
    #' }
    # nolint end
    get_account = function(recv_window = NULL) {
      assert_args_BinanceMargin__get_account(recv_window)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/account",
        query = list(recvWindow = recv_window),
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
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_account,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
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
    #' @param asset (scalar<character>) asset to query (e.g., `"USDT"`).
    #' @param isolated_symbol (scalar<character>?) isolated margin pair (e.g., `"BTCUSDT"`).
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - amount (character) Maximum borrowable amount.
    #' - borrow_limit (character) Borrow limit.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' max_borrow <- margin$get_max_borrowable(asset = "USDT")
    #' print(max_borrow)
    #' }
    get_max_borrowable = function(asset, isolated_symbol = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__get_max_borrowable(asset, isolated_symbol, recv_window)
      assert::assert_nonempty_strings(asset)
      assert::assert_nonempty_strings(isolated_symbol, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/maxBorrowable",
        query = list(
          asset = asset,
          isolatedSymbol = isolated_symbol,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_max_borrowable,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param asset (scalar<character>) asset to query (e.g., `"USDT"`).
    #' @param isolated_symbol (scalar<character>?) isolated margin pair (e.g., `"BTCUSDT"`).
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - amount (character) Maximum transferable-out amount.
    #' - borrow_limit (character) Remaining borrow limit for the
    #'   account, in the same asset units as `amount`.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' max_transfer <- margin$get_max_transferable(asset = "USDT")
    #' print(max_transfer)
    #' }
    # nolint end
    get_max_transferable = function(asset, isolated_symbol = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__get_max_transferable(asset, isolated_symbol, recv_window)
      assert::assert_nonempty_strings(asset)
      assert::assert_nonempty_strings(isolated_symbol, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/maxTransferable",
        query = list(
          asset = asset,
          isolatedSymbol = isolated_symbol,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_max_transferable,
        is_async = private$.is_async
      ))
    },

    # ---- History ----

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param asset (scalar<character>?) filter by asset (e.g., `"USDT"`).
    #' @param start_time (scalar<count>?) start timestamp in milliseconds.
    #' @param end_time (scalar<count>?) end timestamp in milliseconds.
    #' @param current (scalar<count>?) current page (default 1).
    #' @param size (scalar<count>?) page size (default 10, max 100).
    #' @param archived (scalar<character>?) `"true"` to query 6-month archived data.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per interest record
    #'   (empty when there are none):
    #' - asset (character) Asset charged interest.
    #' - interest (character) Interest amount accrued.
    #' - interest_accured_time (POSIXct) Time of interest accrual.
    #' - interest_rate (character) Applied interest rate.
    #' - principal (character) Principal amount borrowed.
    #' - type (character) Margin type (`"ON_BORROW"`, `"PERIODIC"`, etc.).
    #' - isolated_symbol (character) Isolated margin pair (if applicable).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' history <- margin$get_interest_history(asset = "USDT")
    #' print(history)
    #' }
    # nolint end
    get_interest_history = function(
      asset = NULL,
      start_time = NULL,
      end_time = NULL,
      current = NULL,
      size = NULL,
      archived = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceMargin__get_interest_history(asset, start_time, end_time, current, size, archived, recv_window)
      assert::assert_nonempty_strings(asset, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/interestHistory",
        query = list(
          asset = asset,
          startTime = start_time,
          endTime = end_time,
          current = current,
          size = size,
          archived = archived,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- parse_paginated(data, time_cols = "interest_accured_time")
          if (nrow(dt) == 0L) {
            return(empty_dt_margin_interest_history())
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_interest_history,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param start_time (scalar<count>?) start timestamp in milliseconds.
    #' @param end_time (scalar<count>?) end timestamp in milliseconds.
    #' @param isolated_symbol (scalar<character>?) isolated margin pair.
    #' @param current (scalar<count>?) current page (default 1).
    #' @param size (scalar<count>?) page size (default 10, max 100).
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per liquidation record
    #'   (empty when there are none):
    #' - avg_price (character) Average liquidation price.
    #' - executed_qty (character) Liquidated quantity.
    #' - order_id (numeric) Liquidation order identifier.
    #' - price (character) Liquidation price.
    #' - qty (character) Total quantity.
    #' - side (character) `"BUY"` or `"SELL"`.
    #' - symbol (character) Trading pair.
    #' - time (POSIXct) Liquidation time.
    #' - is_isolated (logical) Whether this was an isolated margin liquidation.
    #' - updated_time (POSIXct) Last update time.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' liquidations <- margin$get_force_liquidation_history()
    #' print(liquidations)
    #' }
    # nolint end
    get_force_liquidation_history = function(
      start_time = NULL,
      end_time = NULL,
      isolated_symbol = NULL,
      current = NULL,
      size = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceMargin__get_force_liquidation_history(
        start_time,
        end_time,
        isolated_symbol,
        current,
        size,
        recv_window
      )
      assert::assert_nonempty_strings(isolated_symbol, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/forceLiquidationRec",
        query = list(
          startTime = start_time,
          endTime = end_time,
          isolatedSymbol = isolated_symbol,
          current = current,
          size = size,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- parse_paginated(data, time_cols = c("time", "updated_time"))
          if (nrow(dt) == 0L) {
            return(empty_dt_margin_force_liquidation())
          }
          # 64-bit order id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "order_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_force_liquidation_history,
        is_async = private$.is_async
      ))
    },

    # ---- Trades ----

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param order_id (scalar<count>?) filter by order ID.
    #' @param start_time (scalar<count>?) start timestamp in milliseconds.
    #' @param end_time (scalar<count>?) end timestamp in milliseconds.
    #' @param from_id (scalar<count>?) trade ID to fetch from.
    #' @param limit (scalar<count>?) max results (default 500, max 1000).
    #' @param is_isolated (scalar<character>?) `"TRUE"` or `"FALSE"` for isolated margin.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per trade
    #'   (empty when there are none):
    #' - symbol (character) Trading pair.
    #' - id (numeric) Trade ID.
    #' - order_id (numeric) Order ID.
    #' - price (character) Trade price.
    #' - qty (character) Trade quantity.
    #' - commission (character) Commission paid.
    #' - commission_asset (character) Commission asset.
    #' - time (POSIXct) Trade execution time.
    #' - is_buyer (logical) Whether the trade was a buy.
    #' - is_maker (logical) Whether the trade was a maker.
    #' - is_isolated (logical) Whether this is an isolated margin trade.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' trades <- margin$get_trades("BTCUSDT")
    #' print(trades)
    #' }
    # nolint end
    get_trades = function(
      symbol,
      order_id = NULL,
      start_time = NULL,
      end_time = NULL,
      from_id = NULL,
      limit = NULL,
      is_isolated = NULL,
      recv_window = NULL
    ) {
      assert_args_BinanceMargin__get_trades(
        symbol,
        order_id,
        start_time,
        end_time,
        from_id,
        limit,
        is_isolated,
        recv_window
      )
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/myTrades",
        query = list(
          symbol = symbol,
          orderId = order_id,
          startTime = start_time,
          endTime = end_time,
          fromId = from_id,
          limit = limit,
          isIsolated = is_isolated,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_margin_trade())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "time", ms_to_datetime)
          # 64-bit ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("id", "order_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_trades,
        is_async = private$.is_async
      ))
    },

    # ---- Isolated Margin ----

    # nolint start: line_length_linter.
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
    #' Verified: 2026-05-22
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
    #' @param symbols (scalar<character>?) comma-separated symbols (max 5, e.g., `"BTCUSDT,ETHUSDT"`).
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per isolated margin
    #'   pair (long format):
    #' - total_asset_of_btc (character) Total asset value in BTC (repeated per pair).
    #' - total_liability_of_btc (character) Total liability in BTC (repeated per pair).
    #' - total_net_asset_of_btc (character) Net asset value in BTC (repeated per pair).
    #' - base_asset (list) Base asset details (nested object kept as list-column).
    #' - quote_asset (list) Quote asset details (nested object kept as list-column).
    #' - symbol (character) Isolated margin pair symbol.
    #' - isolated_created (logical) Whether the isolated pair has been created.
    #' - enabled (logical) Whether the pair is enabled.
    #' - margin_level (character) Current margin level.
    #' - trade_enabled (logical) Whether trading is enabled.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' isolated <- margin$get_isolated_account()
    #' print(isolated)
    #' }
    # nolint end
    get_isolated_account = function(symbols = NULL, recv_window = NULL) {
      assert_args_BinanceMargin__get_isolated_account(symbols, recv_window)
      assert::assert_nonempty_strings(symbols, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/margin/isolated/account",
        query = list(
          symbols = symbols,
          recvWindow = recv_window
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_margin_isolated_account())
          }
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
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__get_isolated_account,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
    #' @description
    #' Isolated Margin Transfer
    #'
    #' Transfers assets between spot and isolated margin accounts.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/margin/isolated/transfer`
    #'
    #' ### Official Documentation
    #' [Binance Universal Transfer](https://developers.binance.com/docs/wallet/asset/user-universal-transfer)
    #' (Binance retired the dedicated isolated-margin-transfer doc
    #' page; the universal-transfer endpoint subsumes it. The
    #' `sapi/v1/margin/isolated/transfer` REST endpoint this wrapper
    #' calls still works at the time of writing.)
    #'
    #' Verified: 2026-05-22
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
    #' @param asset (scalar<character>) asset to transfer (e.g., `"USDT"`).
    #' @param symbol (scalar<character>) isolated margin pair (e.g., `"BTCUSDT"`).
    #' @param trans_from (scalar<character>) source account: `"SPOT"` or `"ISOLATED_MARGIN"`.
    #' @param trans_to (scalar<character>) destination account: `"SPOT"` or `"ISOLATED_MARGIN"`.
    #' @param amount (scalar<numeric>) amount to transfer.
    #' @param recv_window (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - tran_id (numeric) Transaction identifier (a large integer that overflows
    #'   R's 32-bit `integer`, so it is coerced to a double).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMargin$new()
    #' result <- margin$add_isolated_transfer(
    #'   asset = "USDT", symbol = "BTCUSDT",
    #'   trans_from = "SPOT", trans_to = "ISOLATED_MARGIN",
    #'   amount = 100
    #' )
    #' print(result)
    #' }
    # nolint end
    add_isolated_transfer = function(asset, symbol, trans_from, trans_to, amount, recv_window = NULL) {
      assert_args_BinanceMargin__add_isolated_transfer(asset, symbol, trans_from, trans_to, amount, recv_window)
      assert::assert_nonempty_strings(asset)
      assert::assert_nonempty_strings(symbol)
      trans_from <- toupper(trans_from)
      trans_to <- toupper(trans_to)
      rlang::arg_match0(trans_from, c("SPOT", "ISOLATED_MARGIN"))
      rlang::arg_match0(trans_to, c("SPOT", "ISOLATED_MARGIN"))

      res <- private$.request(
        endpoint = "/sapi/v1/margin/isolated/transfer",
        method = "POST",
        query = list(
          asset = asset,
          symbol = symbol,
          transFrom = trans_from,
          transTo = trans_to,
          amount = as.character(amount),
          recvWindow = recv_window
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "tran_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMargin__add_isolated_transfer,
        is_async = private$.is_async
      ))
    }
  )
)
