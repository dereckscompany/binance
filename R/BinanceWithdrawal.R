# File: R/BinanceWithdrawal.R
# R6 class for Binance withdrawal operations.

#' BinanceWithdrawal: Withdrawal Management
#'
#' Provides methods for submitting withdrawals and querying withdrawal history
#' on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Withdrawal Submission**: Initiate withdrawals to external addresses.
#' - **Withdrawal History**: Retrieve paginated withdrawal records with status tracking.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#' The API key must have **Withdrawal** permission for `add_withdrawal()`.
#' These are wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.
#'
#' ### Official Documentation
#' [Binance Withdrawal Endpoints](https://developers.binance.com/docs/wallet/capital)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_withdrawal | POST /sapi/v1/capital/withdraw/apply | POST |
#' | get_withdrawal_history | GET /sapi/v1/capital/withdraw/history | GET |
#'
#' @section Withdrawal Status Codes:
#' - `0`: Email Sent
#' - `1`: Cancelled
#' - `2`: Awaiting Approval
#' - `3`: Rejected
#' - `4`: Processing
#' - `5`: Failure
#' - `6`: Completed
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' withdrawal <- BinanceWithdrawal$new()
#' history <- withdrawal$get_withdrawal_history(coin = "USDT")
#' print(history)
#'
#' # Asynchronous
#' withdrawal_async <- BinanceWithdrawal$new(async = TRUE)
#' main <- coro::async(function() {
#'   history <- await(withdrawal_async$get_withdrawal_history(coin = "BTC"))
#'   print(history)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceWithdrawal <- R6::R6Class(
  "BinanceWithdrawal",
  inherit = BinanceBase,
  public = list(
    #' @description
    #' Submit Withdrawal
    #'
    #' Initiates a withdrawal request. The API key must have Withdrawal permission
    #' enabled. Returns a withdrawal ID on success.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/capital/withdraw/apply`
    #'
    #' ### Official Documentation
    #' [Binance Withdraw](https://developers.binance.com/docs/wallet/capital/withdraw)
    #' Verified: 2026-05-22
    #'
    #' ### Automated Trading Usage
    #' - **Profit Extraction**: Withdraw profits to a cold wallet at regular intervals.
    #' - **Multi-Network Support**: Specify `network` (e.g., `"ETH"`, `"TRX"`, `"BSC"`)
    #'   to select the cheapest or fastest network.
    #' - **Wallet Selection**: Use `walletType` to withdraw from spot (0) or funding (1) wallet.
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/capital/withdraw/apply' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'coin=USDT&address=TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8&amount=10&network=TRX&timestamp=...&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "coin": "USDT",
    #'   "address": "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    #'   "amount": "10",
    #'   "network": "TRX",
    #'   "timestamp": 1661493146000,
    #'   "signature": "..."
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' { "id": "7213fea8e94b4a5593d507237e5a555b" }
    #' ```
    #'
    #' @param coin Character; coin symbol (e.g., `"BTC"`, `"USDT"`).
    #' @param address Character; destination wallet address.
    #' @param amount Numeric or character; withdrawal amount.
    #' @param network Character or NULL; blockchain network (e.g., `"ETH"`, `"TRX"`, `"BSC"`).
    #'   If NULL, uses the coin's default network.
    #' @param withdrawOrderId Character or NULL; client-side withdrawal ID for tracking.
    #' @param addressTag Character or NULL; secondary address identifier (required for
    #'   coins like XRP, XMR, XLM).
    #' @param transactionFeeFlag Logical or NULL; for internal transfers: `TRUE` returns
    #'   fee to destination, `FALSE` to origin.
    #' @param name Character or NULL; description for the address (max 200 entries in address book).
    #' @param walletType Integer or NULL; `0` for spot wallet, `1` for funding wallet.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `id` (character): Unique withdrawal identifier assigned by Binance.
    #'
    #' @examples
    #' \dontrun{
    #' withdrawal <- BinanceWithdrawal$new()
    #'
    #' # Withdraw USDT via TRC20
    #' result <- withdrawal$add_withdrawal(
    #'   coin = "USDT",
    #'   address = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    #'   amount = 10,
    #'   network = "TRX"
    #' )
    #' print(result$id)
    #' }
    add_withdrawal = function(
      coin,
      address,
      amount,
      network = NULL,
      withdrawOrderId = NULL,
      addressTag = NULL,
      transactionFeeFlag = NULL,
      name = NULL,
      walletType = NULL,
      recvWindow = NULL
    ) {
      if (!is.character(coin) || !nzchar(coin)) {
        rlang::abort("Parameter 'coin' must be a non-empty string.")
      }
      if (!is.character(address) || !nzchar(address)) {
        rlang::abort("Parameter 'address' must be a non-empty string.")
      }

      body <- list(
        coin = coin,
        address = address,
        amount = as.character(amount)
      )
      if (!is.null(network)) {
        body$network <- network
      }
      if (!is.null(withdrawOrderId)) {
        body$withdrawOrderId <- withdrawOrderId
      }
      if (!is.null(addressTag)) {
        body$addressTag <- addressTag
      }
      if (!is.null(transactionFeeFlag)) {
        body$transactionFeeFlag <- tolower(as.character(transactionFeeFlag))
      }
      if (!is.null(name)) {
        body$name <- name
      }
      if (!is.null(walletType)) {
        body$walletType <- as.character(walletType)
      }
      if (!is.null(recvWindow)) {
        body$recvWindow <- as.character(recvWindow)
      }

      return(private$.request(
        endpoint = "/sapi/v1/capital/withdraw/apply",
        method = "POST",
        body = body,
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Withdrawal History
    #'
    #' Retrieves withdrawal transaction history with optional filtering by coin,
    #' status, and time range. Max time range is 90 days.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/capital/withdraw/history`
    #'
    #' ### Official Documentation
    #' [Binance Withdraw History](https://developers.binance.com/docs/wallet/capital/withdraw-history)
    #' Verified: 2026-05-22
    #'
    #' ### Automated Trading Usage
    #' - **Withdrawal Monitoring**: Poll for status `6` (completed) to confirm funds have
    #'   left the exchange.
    #' - **Reconciliation**: Match `tx_id` against on-chain transaction hashes for audit.
    #' - **Failure Diagnosis**: Check `info` field for error details on failed withdrawals.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/capital/withdraw/history?coin=USDT&status=6&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": "b6ae22b3aa844210a7041aee7589627c",
    #'     "amount": "8.91000000",
    #'     "transactionFee": "0.004",
    #'     "coin": "USDT",
    #'     "status": 6,
    #'     "address": "0x94df8b352de7f46f64b01d3666bf6e936e44ce60",
    #'     "txId": "0xb5ef8c13b968a406cc62a93a8bd80f9e9a906ef1b3fcf20a2e48573c17659268",
    #'     "applyTime": "2019-10-12 11:12:02",
    #'     "network": "ETH",
    #'     "transferType": 0,
    #'     "withdrawOrderId": "WITHDRAWtest123",
    #'     "info": "",
    #'     "confirmNo": 3,
    #'     "walletType": 1,
    #'     "txKey": "",
    #'     "completeTime": "2023-03-23 16:52:41"
    #'   }
    #' ]
    #' ```
    #'
    #' @param coin Character or NULL; filter by coin (e.g., `"BTC"`, `"USDT"`).
    #' @param withdrawOrderId Character or NULL; filter by client-side withdrawal ID.
    #' @param status Integer or NULL; filter by status:
    #'   `0` (email sent), `1` (cancelled), `2` (awaiting approval),
    #'   `3` (rejected), `4` (processing), `5` (failure), `6` (completed).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param offset Integer or NULL; pagination offset (default 0).
    #' @param limit Integer or NULL; max results (default 1000, max 1000).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `id` (character): Unique withdrawal identifier.
    #' - `amount` (character): Withdrawal amount.
    #' - `transaction_fee` (character): Fee charged for the withdrawal.
    #' - `coin` (character): Withdrawn coin symbol.
    #' - `status` (integer): Withdrawal status code (0-6).
    #' - `address` (character): Destination address.
    #' - `tx_id` (character): On-chain transaction hash.
    #' - `apply_time` (POSIXct): Time the withdrawal was submitted (parsed from the UTC string Binance returns).
    #' - `network` (character): Blockchain network used.
    #' - `transfer_type` (integer): 0=external, 1=internal.
    #' - `withdraw_order_id` (character): Client-side withdrawal ID.
    #' - `info` (character): Additional info or error message.
    #' - `confirm_no` (integer): Number of on-chain confirmations.
    #' - `wallet_type` (integer): 0=spot, 1=funding.
    #' - `tx_key` (character): Transaction key.
    #' - `complete_time` (POSIXct): Completion time (parsed from the UTC string Binance returns).
    #'
    #' @examples
    #' \dontrun{
    #' withdrawal <- BinanceWithdrawal$new()
    #'
    #' # Get all completed USDT withdrawals
    #' history <- withdrawal$get_withdrawal_history(coin = "USDT", status = 6)
    #' print(history[, .(amount, coin, status, address, apply_time)])
    #'
    #' # Get withdrawals from the last 7 days
    #' now_ms <- as.integer(as.numeric(Sys.time()) * 1000)
    #' recent <- withdrawal$get_withdrawal_history(
    #'   startTime = now_ms - 7 * 86400000L,
    #'   endTime = now_ms
    #' )
    #' }
    get_withdrawal_history = function(
      coin = NULL,
      withdrawOrderId = NULL,
      status = NULL,
      startTime = NULL,
      endTime = NULL,
      offset = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/capital/withdraw/history",
        query = list(
          coin = coin,
          withdrawOrderId = withdrawOrderId,
          status = status,
          startTime = startTime,
          endTime = endTime,
          offset = offset,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          # `apply_time` and `complete_time` come back as UTC datetime
          # strings (e.g. "2019-10-12 11:12:02") rather than ms — parse
          # via `lubridate::ymd_hms()` so the column type matches the
          # POSIXct convention everywhere else in the package. Binance
          # returns `""` for pending withdrawals, which ymd_hms would
          # warn on; replace those with `NA` first.
          for (col in c("apply_time", "complete_time")) {
            if (col %in% names(dt)) {
              vals <- dt[[col]]
              vals[!nzchar(vals)] <- NA_character_
              dt[, (col) := lubridate::ymd_hms(vals, tz = "UTC")]
            }
          }
          return(dt[])
        }
      ))
    }
  )
)
