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
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/asset/transfer' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'type=MAIN_UMFUTURE&asset=USDT&amount=100&timestamp=1661493146000&signature=...'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "tranId": 13526853623
    #' }
    #' ```
    #'
    #' @param type Character; transfer type. One of `"MAIN_UMFUTURE"`,
    #'   `"MAIN_CMFUTURE"`, `"MAIN_MARGIN"`, `"UMFUTURE_MAIN"`,
    #'   `"UMFUTURE_MARGIN"`, `"CMFUTURE_MAIN"`, `"MARGIN_MAIN"`,
    #'   `"MARGIN_UMFUTURE"`, `"MAIN_FUNDING"`, `"FUNDING_MAIN"`,
    #'   `"FUNDING_UMFUTURE"`, `"UMFUTURE_FUNDING"`, `"MARGIN_FUNDING"`,
    #'   `"FUNDING_MARGIN"`, `"FUNDING_CMFUTURE"`, `"CMFUTURE_FUNDING"`,
    #'   `"MAIN_ISOLATED_MARGIN"`, `"ISOLATED_MARGIN_MAIN"`.
    #' @param asset Character; asset to transfer (e.g., `"USDT"`).
    #' @param amount Numeric; amount to transfer.
    #' @param fromSymbol Character or NULL; mandatory when `type` involves
    #'   isolated margin (e.g., `"BNBUSDT"`).
    #' @param toSymbol Character or NULL; mandatory when `type` involves
    #'   isolated margin (e.g., `"BNBUSDT"`).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `tran_id` (numeric): Unique transfer identifier assigned by Binance.
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

      return(private$.request(
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
          return(as_dt_row(data)[])
        }
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
    #' @param type Character; transfer type. Same options as `add_transfer()`.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param fromSymbol Character or NULL; must be sent when `type` involves
    #'   isolated margin.
    #' @param toSymbol Character or NULL; must be sent when `type` involves
    #'   isolated margin.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per transfer and the following columns:
    #' - `asset` (character): Transferred asset (e.g., `"USDT"`).
    #' - `amount` (character): Amount transferred.
    #' - `type` (character): Transfer type (e.g., `"MAIN_UMFUTURE"`).
    #' - `status` (character): Transfer status (`"CONFIRMED"`, `"FAILED"`, `"PENDING"`).
    #' - `tran_id` (numeric): Unique transfer identifier.
    #' - `timestamp` (POSIXct): Transfer time converted from milliseconds.
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

      return(private$.request(
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
          return(parse_paginated(data, time_cols = "timestamp")[])
        }
      ))
    }
  )
)
