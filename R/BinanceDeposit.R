# File: R/BinanceDeposit.R
# R6 class for Binance deposit operations.

#' BinanceDeposit: Deposit Management
#'
#' Provides methods for retrieving deposit addresses and deposit history
#' on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Deposit Address**: Retrieve deposit addresses for any supported coin and network.
#' - **Deposit History**: Query deposit transaction records with status tracking,
#'   timestamps, and on-chain transaction IDs.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#' These are wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.
#'
#' ### Official Documentation
#' [Binance Deposit Endpoints](https://developers.binance.com/docs/wallet/capital)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_deposit_address | GET /sapi/v1/capital/deposit/address | GET |
#' | get_deposit_history | GET /sapi/v1/capital/deposit/hisrec | GET |
#'
#' @section Deposit Status Codes:
#' - `0`: Pending
#' - `1`: Success (confirmed and credited)
#' - `6`: Credited but cannot withdraw
#' - `7`: Wrong deposit
#' - `8`: Waiting user confirm
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' deposit <- BinanceDeposit$new()
#' addr <- deposit$get_deposit_address(coin = "BTC")
#' print(addr)
#'
#' # Asynchronous
#' deposit_async <- BinanceDeposit$new(async = TRUE)
#' main <- coro::async(function() {
#'   addr <- await(deposit_async$get_deposit_address(coin = "BTC"))
#'   print(addr)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceDeposit <- R6::R6Class(
  "BinanceDeposit",
  inherit = BinanceBase,
  public = list(
    #' @description
    #' Get Deposit Address
    #'
    #' Retrieves the deposit address for a specific coin. If `network` is not
    #' specified, returns the address for the coin's default network.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/capital/deposit/address`
    #'
    #' ### Official Documentation
    #' [Binance Deposit Address](https://developers.binance.com/docs/wallet/capital/deposite-address)
    #' Verified: 2026-03-10
    #'
    #' ### Automated Trading Usage
    #' - **Address Lookup**: Retrieve deposit addresses to share with external systems or users.
    #' - **Multi-Network Support**: Specify `network` (e.g., `"ETH"`, `"TRX"`, `"BSC"`) to get
    #'   the address on the correct chain.
    #' - **Pre-Flight Check**: Verify the deposit address exists before initiating an external transfer.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/capital/deposit/address?coin=BTC&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "address": "1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv",
    #'   "coin": "BTC",
    #'   "tag": "",
    #'   "url": "https://btc.com/1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv"
    #' }
    #' ```
    #'
    #' @param coin Character; coin symbol (e.g., `"BTC"`, `"ETH"`, `"USDT"`).
    #' @param network Character or NULL; blockchain network (e.g., `"ETH"`, `"TRX"`, `"BSC"`).
    #'   If NULL, uses the coin's default network.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `address` (character): The deposit wallet address.
    #' - `coin` (character): Coin symbol (e.g., `"BTC"`).
    #' - `tag` (character): Address tag/memo (empty string if not applicable).
    #' - `url` (character): Blockchain explorer URL for the address.
    #'
    #' @examples
    #' \dontrun{
    #' deposit <- BinanceDeposit$new()
    #'
    #' # Get BTC deposit address (default network)
    #' btc <- deposit$get_deposit_address(coin = "BTC")
    #' print(btc$address)
    #'
    #' # Get USDT deposit address on TRC20
    #' usdt <- deposit$get_deposit_address(coin = "USDT", network = "TRX")
    #' print(usdt[, .(address, coin, tag)])
    #' }
    get_deposit_address = function(coin, network = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/capital/deposit/address",
        query = list(
          coin = coin,
          network = network,
          recvWindow = recvWindow
        ),
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Deposit History
    #'
    #' Retrieves deposit transaction history with optional filtering by coin,
    #' status, and time range. Converts `insertTime` timestamps to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/capital/deposit/hisrec`
    #'
    #' ### Official Documentation
    #' [Binance Deposit History](https://developers.binance.com/docs/wallet/capital/deposite-history)
    #' Verified: 2026-03-10
    #'
    #' ### Automated Trading Usage
    #' - **Deposit Monitoring**: Poll for status `1` (success) deposits to trigger trading logic
    #'   when funds arrive.
    #' - **Reconciliation**: Match `tx_id` against on-chain transaction hashes for audit.
    #' - **Time-Windowed Queries**: Use `startTime`/`endTime` to retrieve deposits within a
    #'   specific period. Max range is 90 days.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/capital/deposit/hisrec?coin=BTC&status=1&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": "769800519366885376",
    #'     "amount": "0.001",
    #'     "coin": "BNB",
    #'     "network": "BNB",
    #'     "status": 1,
    #'     "address": "bnb136ns6lfw4zs5hg4n85vdthaad7hq5m4gtkgf23",
    #'     "addressTag": "101764890",
    #'     "txId": "98A3EA560C6B3336D348B6C83F0F95ECE4F1F5919E94BD006E5BF3BF264FACFC",
    #'     "insertTime": 1661493146000,
    #'     "completeTime": 1661493146000,
    #'     "transferType": 0,
    #'     "confirmTimes": "1/1",
    #'     "unlockConfirm": 0,
    #'     "walletType": 0
    #'   }
    #' ]
    #' ```
    #'
    #' @param coin Character or NULL; filter by coin (e.g., `"BTC"`, `"USDT"`).
    #' @param status Integer or NULL; filter by status:
    #'   `0` (pending), `1` (success), `6` (credited), `7` (wrong), `8` (waiting confirm).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param offset Integer or NULL; pagination offset (default 0).
    #' @param limit Integer or NULL; max results (default 1000, max 1000).
    #' @param txId Character or NULL; filter by transaction ID.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `id` (character): Unique deposit identifier.
    #' - `amount` (character): Deposit amount.
    #' - `coin` (character): Deposited coin symbol.
    #' - `network` (character): Blockchain network used.
    #' - `status` (integer): Deposit status code (0=pending, 1=success, 6=credited).
    #' - `address` (character): Deposit address.
    #' - `address_tag` (character): Address tag/memo.
    #' - `tx_id` (character): On-chain transaction hash.
    #' - `transfer_type` (integer): 0=external, 1=internal.
    #' - `confirm_times` (character): Confirmation progress (e.g., `"1/1"`).
    #' - `unlock_confirm` (integer): Confirmations needed to unlock.
    #' - `wallet_type` (integer): 0=spot, 1=funding.
    #' - `insert_time` (POSIXct): Deposit time converted from `insertTime`.
    #' - `complete_time` (POSIXct): Completion time converted from `completeTime`.
    #'
    #' @examples
    #' \dontrun{
    #' deposit <- BinanceDeposit$new()
    #'
    #' # Get all successful BTC deposits
    #' history <- deposit$get_deposit_history(coin = "BTC", status = 1)
    #' print(history[, .(amount, coin, status, insert_time)])
    #'
    #' # Get deposits from the last 24 hours
    #' now_ms <- as.integer(as.numeric(Sys.time()) * 1000)
    #' recent <- deposit$get_deposit_history(
    #'   startTime = now_ms - 86400000L,
    #'   endTime = now_ms
    #' )
    #' }
    get_deposit_history = function(
      coin = NULL,
      status = NULL,
      startTime = NULL,
      endTime = NULL,
      offset = NULL,
      limit = NULL,
      txId = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/capital/deposit/hisrec",
        query = list(
          coin = coin,
          status = status,
          startTime = startTime,
          endTime = endTime,
          offset = offset,
          limit = limit,
          txId = txId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "insert_time" %in% names(dt)) {
            dt[, insert_time := ms_to_datetime(insert_time)]
          }
          if (nrow(dt) > 0 && "complete_time" %in% names(dt)) {
            dt[, complete_time := ms_to_datetime(complete_time)]
          }
          return(dt[])
        }
      ))
    }
  )
)
