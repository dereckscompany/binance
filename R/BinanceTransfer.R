# File: R/BinanceTransfer.R
# R6 class for Binance universal transfer operations.

#' BinanceTransfer: Universal Transfer Management
#'
#' Provides methods for initiating and querying universal transfers between
#' wallet types on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Transfer Initiation**: Move assets between spot, margin, futures, and
#'   funding wallets using the universal transfer endpoint.
#' - **Transfer History**: Query transfer records with pagination support.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#' These are wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.
#'
#' ### Official Documentation
#' [Binance Universal Transfer](https://developers.binance.com/docs/wallet/asset/user-universal-transfer)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_transfer | POST /sapi/v1/asset/transfer | POST |
#' | get_transfer_history | GET /sapi/v1/asset/transfer | GET |
#'
#' ### Transfer Types
#' - `MAIN_UMFUTURE`: Spot to USDM Futures
#' - `MAIN_CMFUTURE`: Spot to COINM Futures
#' - `MAIN_MARGIN`: Spot to Cross Margin
#' - `UMFUTURE_MAIN`: USDM Futures to Spot
#' - `UMFUTURE_MARGIN`: USDM Futures to Cross Margin
#' - `CMFUTURE_MAIN`: COINM Futures to Spot
#' - `MARGIN_MAIN`: Cross Margin to Spot
#' - `MARGIN_UMFUTURE`: Cross Margin to USDM Futures
#' - `MAIN_FUNDING`: Spot to Funding
#' - `FUNDING_MAIN`: Funding to Spot
#' - `FUNDING_UMFUTURE`: Funding to USDM Futures
#' - `UMFUTURE_FUNDING`: USDM Futures to Funding
#' - `MARGIN_FUNDING`: Cross Margin to Funding
#' - `FUNDING_MARGIN`: Funding to Cross Margin
#' - `FUNDING_CMFUTURE`: Funding to COINM Futures
#' - `CMFUTURE_FUNDING`: COINM Futures to Funding
#' - `MAIN_ISOLATED_MARGIN`: Spot to Isolated Margin
#' - `ISOLATED_MARGIN_MAIN`: Isolated Margin to Spot
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' transfer <- BinanceTransfer$new()
#' result <- transfer$add_transfer(
#'   type = "MAIN_UMFUTURE", asset = "USDT", amount = 100
#' )
#' print(result)
#'
#' # Asynchronous
#' transfer_async <- BinanceTransfer$new(async = TRUE)
#' main <- coro::async(function() {
#'   result <- await(transfer_async$add_transfer(
#'     type = "MAIN_UMFUTURE", asset = "USDT", amount = 100
#'   ))
#'   print(result)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom rlang arg_match0
#' @export
BinanceTransfer <- R6::R6Class(
  "BinanceTransfer",
  inherit = BinanceBase,
  public = list(
    #' @description
    #' Initiate a Universal Transfer
    #'
    #' Transfers assets between wallet types (spot, margin, futures, funding).
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/asset/transfer`
    #'
    #' ### Official Documentation
    #' [Binance Universal Transfer](https://developers.binance.com/docs/wallet/asset/user-universal-transfer)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/asset/transfer' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'type=MAIN_UMFUTURE&asset=USDT&amount=100&timestamp=1661493146000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "type": "MAIN_UMFUTURE",
    #'   "asset": "USDT",
    #'   "amount": "100",
    #'   "timestamp": 1661493146000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "tranId": 13526853623
    #' }
    #' ```
    #'
    #' @param type (scalar<character>) transfer type. One of `"MAIN_UMFUTURE"`,
    #'   `"MAIN_CMFUTURE"`, `"MAIN_MARGIN"`, `"UMFUTURE_MAIN"`,
    #'   `"UMFUTURE_MARGIN"`, `"CMFUTURE_MAIN"`, `"MARGIN_MAIN"`,
    #'   `"MARGIN_UMFUTURE"`, `"MAIN_FUNDING"`, `"FUNDING_MAIN"`,
    #'   `"FUNDING_UMFUTURE"`, `"UMFUTURE_FUNDING"`, `"MARGIN_FUNDING"`,
    #'   `"FUNDING_MARGIN"`, `"FUNDING_CMFUTURE"`, `"CMFUTURE_FUNDING"`,
    #'   `"MAIN_ISOLATED_MARGIN"`, `"ISOLATED_MARGIN_MAIN"`.
    #' @param asset (scalar<character>) asset to transfer (e.g., `"USDT"`).
    #' @param amount (scalar<numeric>) amount to transfer.
    #' @param fromSymbol (scalar<character>?) mandatory when `type` involves
    #'   isolated margin (e.g., `"BNBUSDT"`).
    #' @param toSymbol (scalar<character>?) mandatory when `type` involves
    #'   isolated margin (e.g., `"BNBUSDT"`).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - tran_id (numeric) Unique transfer identifier assigned by Binance.
    #'
    #' @examples
    #' \dontrun{
    #' transfer <- BinanceTransfer$new()
    #' result <- transfer$add_transfer(
    #'   type = "MAIN_UMFUTURE", asset = "USDT", amount = 100
    #' )
    #' print(result)
    #' }
    add_transfer = function(
      type,
      asset,
      amount,
      fromSymbol = NULL,
      toSymbol = NULL,
      recvWindow = NULL
    ) {
      assert_args_BinanceTransfer__add_transfer(type, asset, amount, fromSymbol, toSymbol, recvWindow)
      rlang::arg_match0(
        type,
        c(
          "MAIN_UMFUTURE",
          "MAIN_CMFUTURE",
          "MAIN_MARGIN",
          "UMFUTURE_MAIN",
          "UMFUTURE_MARGIN",
          "CMFUTURE_MAIN",
          "MARGIN_MAIN",
          "MARGIN_UMFUTURE",
          "MAIN_FUNDING",
          "FUNDING_MAIN",
          "FUNDING_UMFUTURE",
          "UMFUTURE_FUNDING",
          "MARGIN_FUNDING",
          "FUNDING_MARGIN",
          "FUNDING_CMFUTURE",
          "CMFUTURE_FUNDING",
          "MAIN_ISOLATED_MARGIN",
          "ISOLATED_MARGIN_MAIN"
        )
      )

      res <- private$.request(
        endpoint = "/sapi/v1/asset/transfer",
        method = "POST",
        query = list(
          type = type,
          asset = asset,
          amount = as.character(amount),
          fromSymbol = fromSymbol,
          toSymbol = toSymbol,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- as_dt_row(data)
          # Binance's `tranId` is an integer in JSON, but large ids overflow
          # R's 32-bit integer and arrive as a double; coerce to numeric so
          # the column type is stable regardless of id magnitude.
          coerce_cols(dt, "tran_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTransfer__add_transfer,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Query Universal Transfer History
    #'
    #' Retrieves transfer history for a given transfer type, with optional
    #' time range and pagination.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/asset/transfer`
    #'
    #' ### Official Documentation
    #' [Binance Universal Transfer](https://developers.binance.com/docs/wallet/asset/query-user-universal-transfer)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/asset/transfer?type=MAIN_UMFUTURE&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "total": 2,
    #'   "rows": [
    #'     {
    #'       "asset": "USDT",
    #'       "amount": "100.00000000",
    #'       "type": "MAIN_UMFUTURE",
    #'       "status": "CONFIRMED",
    #'       "tranId": 13526853623,
    #'       "timestamp": 1661493146000
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param type (scalar<character>) transfer type. Same options as `add_transfer()`.
    #' @param startTime (scalar<count>?) start timestamp in milliseconds.
    #' @param endTime (scalar<count>?) end timestamp in milliseconds.
    #' @param current (scalar<count>?) current page (default 1, starting from 1).
    #' @param size (scalar<count>?) page size (default 10, max 100).
    #' @param fromSymbol (scalar<character>?) must be sent when `type` involves
    #'   isolated margin.
    #' @param toSymbol (scalar<character>?) must be sent when `type` involves
    #'   isolated margin.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per transfer
    #'   (empty when there are no matching transfers):
    #' - asset (character) Transferred asset (e.g., `"USDT"`).
    #' - amount (character) Amount transferred.
    #' - type (character) Transfer type (e.g., `"MAIN_UMFUTURE"`).
    #' - status (character) Transfer status (`"CONFIRMED"`, `"FAILED"`, `"PENDING"`).
    #' - tran_id (numeric) Unique transfer identifier.
    #' - timestamp (POSIXct) Transfer time converted from milliseconds.
    #'
    #' @examples
    #' \dontrun{
    #' transfer <- BinanceTransfer$new()
    #' history <- transfer$get_transfer_history(type = "MAIN_UMFUTURE")
    #' print(history)
    #' }
    get_transfer_history = function(
      type,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      fromSymbol = NULL,
      toSymbol = NULL,
      recvWindow = NULL
    ) {
      assert_args_BinanceTransfer__get_transfer_history(
        type,
        startTime,
        endTime,
        current,
        size,
        fromSymbol,
        toSymbol,
        recvWindow
      )
      rlang::arg_match0(
        type,
        c(
          "MAIN_UMFUTURE",
          "MAIN_CMFUTURE",
          "MAIN_MARGIN",
          "UMFUTURE_MAIN",
          "UMFUTURE_MARGIN",
          "CMFUTURE_MAIN",
          "MARGIN_MAIN",
          "MARGIN_UMFUTURE",
          "MAIN_FUNDING",
          "FUNDING_MAIN",
          "FUNDING_UMFUTURE",
          "UMFUTURE_FUNDING",
          "MARGIN_FUNDING",
          "FUNDING_MARGIN",
          "FUNDING_CMFUTURE",
          "CMFUTURE_FUNDING",
          "MAIN_ISOLATED_MARGIN",
          "ISOLATED_MARGIN_MAIN"
        )
      )

      res <- private$.request(
        endpoint = "/sapi/v1/asset/transfer",
        query = list(
          type = type,
          startTime = startTime,
          endTime = endTime,
          current = current,
          size = size,
          fromSymbol = fromSymbol,
          toSymbol = toSymbol,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          dt <- parse_paginated(data, time_cols = "timestamp")
          coerce_cols(dt, "tran_id", as.numeric)
          if (nrow(dt) == 0L) {
            return(empty_dt_transfer_history())
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceTransfer__get_transfer_history,
        is_async = private$.is_async
      ))
    }
  )
)
