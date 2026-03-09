# File: R/BinanceSubAccount.R
# R6 class for Binance sub-account management.

#' BinanceSubAccount: Sub-Account Management
#'
#' Provides methods for creating and managing Binance sub-accounts,
#' querying balances, performing universal transfers, and retrieving
#' futures/margin account details. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Sub-Account Creation**: Create virtual sub-accounts programmatically.
#' - **Balance Queries**: Retrieve asset balances for any sub-account.
#' - **Universal Transfers**: Move funds between master and sub-accounts across
#'   SPOT, USDT_FUTURE, COIN_FUTURE, MARGIN, and ISOLATED_MARGIN wallets.
#' - **Account Details**: Query futures and margin account information for sub-accounts.
#' - **Status**: Retrieve sub-account enablement and activity status.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#' These are wallet (`/sapi/`) endpoints.
#'
#' ### Official Documentation
#' [Binance Sub-Account Endpoints](https://developers.binance.com/docs/sub_account/Introduction)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_sub_account | POST /sapi/v1/sub-account/virtualSubAccount | POST |
#' | get_sub_accounts | GET /sapi/v1/sub-account/list | GET |
#' | get_balances | GET /sapi/v3/sub-account/assets | GET |
#' | get_spot_summary | GET /sapi/v1/sub-account/spotSummary | GET |
#' | add_transfer | POST /sapi/v1/sub-account/universalTransfer | POST |
#' | get_transfer_history | GET /sapi/v1/sub-account/universalTransfer | GET |
#' | get_futures_account | GET /sapi/v2/sub-account/futures/account | GET |
#' | get_margin_account | GET /sapi/v1/sub-account/margin/account | GET |
#' | get_status | GET /sapi/v1/sub-account/status | GET |
#'
#' @section Account Types for Transfers:
#' - `"SPOT"`: Spot wallet.
#' - `"USDT_FUTURE"`: USDT-margined futures wallet.
#' - `"COIN_FUTURE"`: Coin-margined futures wallet.
#' - `"MARGIN"`: Cross-margin wallet.
#' - `"ISOLATED_MARGIN"`: Isolated-margin wallet.
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' sub <- BinanceSubAccount$new()
#' accounts <- sub$get_sub_accounts()
#' print(accounts)
#'
#' # Asynchronous
#' sub_async <- BinanceSubAccount$new(async = TRUE)
#' main <- coro::async(function() {
#'   accounts <- await(sub_async$get_sub_accounts())
#'   print(accounts)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceSubAccount <- R6::R6Class(
  "BinanceSubAccount",
  inherit = BinanceBase,
  public = list(
    # ---- Sub-Account Creation ----

    #' @description
    #' Create a Virtual Sub-Account
    #'
    #' Creates a new virtual sub-account under the master account.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/sub-account/virtualSubAccount`
    #'
    #' ### Official Documentation
    #' [Binance Create Virtual Sub-Account](https://developers.binance.com/docs/sub_account/account-management/Create-a-Virtual-Sub-account)
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/sub-account/virtualSubAccount' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'subAccountString=testaccount&timestamp=...&signature=...'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "email": "testsub01@virtual.com"
    #' }
    #' ```
    #'
    #' @param subAccountString Character; the sub-account name/string identifier.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `email` (character): The email of the newly created sub-account.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' result <- sub$add_sub_account(subAccountString = "mysubaccount")
    #' print(result$email)
    #' }
    add_sub_account = function(subAccountString, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/sub-account/virtualSubAccount",
        method = "POST",
        body = list(
          subAccountString = subAccountString,
          recvWindow = recvWindow
        ),
        .parser = as_dt_row
      ))
    },

    # ---- Sub-Account Queries ----

    #' @description
    #' List Sub-Accounts
    #'
    #' Retrieves a list of sub-accounts under the master account, optionally
    #' filtered by email or freeze status.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/sub-account/list`
    #'
    #' ### Official Documentation
    #' [Binance Query Sub-Account List](https://developers.binance.com/docs/sub_account/account-management/Query-Sub-account-List)
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "subAccounts": [
    #'     {
    #'       "email": "testsub01@virtual.com",
    #'       "isFreeze": false,
    #'       "createTime": 1661493146000,
    #'       "isManagedSubAccount": false,
    #'       "isAssetManagementSubAccount": false
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param email Character or NULL; filter by sub-account email.
    #' @param isFreeze Logical or NULL; filter by freeze status.
    #' @param page Integer or NULL; page number (default 1).
    #' @param limit Integer or NULL; results per page (default 1, max 200).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per sub-account and the following columns:
    #' - `email` (character): Sub-account email.
    #' - `is_freeze` (logical): Whether the sub-account is frozen.
    #' - `create_time` (POSIXct): Account creation time converted from `createTime`.
    #' - `is_managed_sub_account` (logical): Whether it is a managed sub-account.
    #' - `is_asset_management_sub_account` (logical): Whether it is an asset management sub-account.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' accounts <- sub$get_sub_accounts()
    #' print(accounts[, .(email, is_freeze, create_time)])
    #' }
    get_sub_accounts = function(email = NULL, isFreeze = NULL, page = NULL, limit = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/sub-account/list",
        query = list(
          email = email,
          isFreeze = isFreeze,
          page = page,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          items <- data$subAccounts
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table())
          }
          dt <- as_dt_list(items)
          if (nrow(dt) > 0 && "create_time" %in% names(dt)) {
            dt[, create_time := ms_to_datetime(create_time)]
          }
          return(dt)
        }
      ))
    },

    #' @description
    #' Get Sub-Account Balances
    #'
    #' Retrieves asset balances for a specific sub-account.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v3/sub-account/assets`
    #'
    #' ### Official Documentation
    #' [Binance Sub-Account Assets](https://developers.binance.com/docs/sub_account/asset-management/Query-Sub-account-Assets-V3)
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "balances": [
    #'     {"asset": "BTC", "free": 0.1, "locked": 0.0},
    #'     {"asset": "USDT", "free": 1000.0, "locked": 50.0}
    #'   ]
    #' }
    #' ```
    #'
    #' @param email Character; the sub-account email.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per asset and the following columns:
    #' - `asset` (character): Asset symbol (e.g., `"BTC"`).
    #' - `free` (numeric): Available balance.
    #' - `locked` (numeric): Locked balance.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' balances <- sub$get_balances(email = "sub@virtual.com")
    #' print(balances)
    #' }
    get_balances = function(email, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v3/sub-account/assets",
        query = list(
          email = email,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          items <- data$balances
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table())
          }
          return(as_dt_list(items))
        }
      ))
    },

    #' @description
    #' Get Sub-Account Spot Summary
    #'
    #' Retrieves spot account summary for sub-accounts.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/sub-account/spotSummary`
    #'
    #' ### Official Documentation
    #' [Binance Sub-Account Spot Summary](https://developers.binance.com/docs/sub_account/asset-management/Sub-account-Spot-Assets-Summary)
    #'
    #' @param email Character or NULL; filter by sub-account email.
    #' @param page Integer or NULL; page number (default 1).
    #' @param size Integer or NULL; results per page (default 10, max 20).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `total_count` (integer): Total number of sub-accounts.
    #' - `master_account_total_asset` (character): Master account total asset value in BTC.
    #' - `spot_sub_user_asset_btc_vo_list` (list): Nested list of per-sub-account spot asset summaries.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' summary <- sub$get_spot_summary()
    #' print(summary)
    #' }
    get_spot_summary = function(email = NULL, page = NULL, size = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/sub-account/spotSummary",
        query = list(
          email = email,
          page = page,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table())
          }
          return(as_dt_row(data))
        }
      ))
    },

    # ---- Transfers ----

    #' @description
    #' Universal Transfer
    #'
    #' Transfers assets between master and sub-accounts or between sub-accounts,
    #' across different account types (SPOT, futures, margin).
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/sub-account/universalTransfer`
    #'
    #' ### Official Documentation
    #' [Binance Universal Transfer](https://developers.binance.com/docs/sub_account/asset-management/Universal-Transfer)
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "tranId": 11945860693,
    #'   "clientTranId": "test_transfer_001"
    #' }
    #' ```
    #'
    #' @param fromEmail Character or NULL; sender sub-account email.
    #' @param toEmail Character or NULL; recipient sub-account email.
    #' @param fromAccountType Character; source account type. One of
    #'   `"SPOT"`, `"USDT_FUTURE"`, `"COIN_FUTURE"`, `"MARGIN"`, `"ISOLATED_MARGIN"`.
    #' @param toAccountType Character; destination account type. One of
    #'   `"SPOT"`, `"USDT_FUTURE"`, `"COIN_FUTURE"`, `"MARGIN"`, `"ISOLATED_MARGIN"`.
    #' @param asset Character; asset to transfer (e.g., `"USDT"`).
    #' @param amount Numeric; amount to transfer.
    #' @param clientTranId Character or NULL; client-defined transfer ID.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `tran_id` (integer): Binance-assigned transfer ID.
    #' - `client_tran_id` (character): Client-defined transfer ID.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' result <- sub$add_transfer(
    #'   toEmail = "sub@virtual.com",
    #'   fromAccountType = "SPOT", toAccountType = "SPOT",
    #'   asset = "USDT", amount = 100
    #' )
    #' print(result$tran_id)
    #' }
    add_transfer = function(
      fromEmail = NULL,
      toEmail = NULL,
      fromAccountType,
      toAccountType,
      asset,
      amount,
      clientTranId = NULL,
      recvWindow = NULL
    ) {
      valid_types <- c("SPOT", "USDT_FUTURE", "COIN_FUTURE", "MARGIN", "ISOLATED_MARGIN")
      if (!fromAccountType %in% valid_types) {
        rlang::abort(paste0(
          "'fromAccountType' must be one of: ",
          paste(valid_types, collapse = ", "),
          ". Got: '", fromAccountType, "'."
        ))
      }
      if (!toAccountType %in% valid_types) {
        rlang::abort(paste0(
          "'toAccountType' must be one of: ",
          paste(valid_types, collapse = ", "),
          ". Got: '", toAccountType, "'."
        ))
      }

      return(private$.request(
        endpoint = "/sapi/v1/sub-account/universalTransfer",
        method = "POST",
        body = list(
          fromEmail = fromEmail,
          toEmail = toEmail,
          fromAccountType = fromAccountType,
          toAccountType = toAccountType,
          asset = asset,
          amount = as.character(amount),
          clientTranId = clientTranId,
          recvWindow = recvWindow
        ),
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Universal Transfer History
    #'
    #' Retrieves universal transfer history between master and sub-accounts.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/sub-account/universalTransfer`
    #'
    #' ### Official Documentation
    #' [Binance Universal Transfer History](https://developers.binance.com/docs/sub_account/asset-management/Query-Universal-Transfer-History)
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "result": [
    #'     {
    #'       "tranId": 11945860693,
    #'       "fromEmail": "master@test.com",
    #'       "toEmail": "sub@virtual.com",
    #'       "asset": "USDT",
    #'       "amount": "100.00000000",
    #'       "createTimeStamp": 1661493146000,
    #'       "fromAccountType": "SPOT",
    #'       "toAccountType": "SPOT",
    #'       "status": "SUCCESS",
    #'       "clientTranId": "test_001"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param fromEmail Character or NULL; filter by sender email.
    #' @param toEmail Character or NULL; filter by recipient email.
    #' @param clientTranId Character or NULL; filter by client transfer ID.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param page Integer or NULL; page number (default 1).
    #' @param limit Integer or NULL; results per page (default 500, max 500).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per transfer and the following columns:
    #' - `tran_id` (integer): Binance-assigned transfer ID.
    #' - `from_email` (character): Sender email.
    #' - `to_email` (character): Recipient email.
    #' - `asset` (character): Transferred asset.
    #' - `amount` (character): Transfer amount.
    #' - `create_time_stamp` (POSIXct): Transfer time converted from `createTimeStamp`.
    #' - `from_account_type` (character): Source account type.
    #' - `to_account_type` (character): Destination account type.
    #' - `status` (character): Transfer status.
    #' - `client_tran_id` (character): Client-defined transfer ID.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' history <- sub$get_transfer_history(toEmail = "sub@virtual.com")
    #' print(history)
    #' }
    get_transfer_history = function(
      fromEmail = NULL,
      toEmail = NULL,
      clientTranId = NULL,
      startTime = NULL,
      endTime = NULL,
      page = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/sub-account/universalTransfer",
        query = list(
          fromEmail = fromEmail,
          toEmail = toEmail,
          clientTranId = clientTranId,
          startTime = startTime,
          endTime = endTime,
          page = page,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          items <- data$result
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table())
          }
          dt <- as_dt_list(items)
          if (nrow(dt) > 0 && "create_time_stamp" %in% names(dt)) {
            dt[, create_time_stamp := ms_to_datetime(create_time_stamp)]
          }
          return(dt)
        }
      ))
    },

    # ---- Futures / Margin ----

    #' @description
    #' Get Sub-Account Futures Account
    #'
    #' Retrieves futures account details for a sub-account.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v2/sub-account/futures/account`
    #'
    #' ### Official Documentation
    #' [Binance Sub-Account Futures Account V2](https://developers.binance.com/docs/sub_account/asset-management/Get-Detail-on-Sub-accounts-Futures-Account-V2)
    #'
    #' @param email Character; the sub-account email.
    #' @param futuresType Integer; `1` for USDT-margined futures, `2` for COIN-margined futures.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `email` (character): Sub-account email.
    #' - `asset` (character): Margin asset (e.g., `"USDT"`).
    #' - `assets` (list): Nested list of per-asset balance details.
    #' - `can_deposit` (logical): Whether deposits are permitted.
    #' - `can_trade` (logical): Whether trading is permitted.
    #' - `can_withdraw` (logical): Whether withdrawals are permitted.
    #' - `fee_tier` (integer): Fee tier level.
    #' - `max_withdraw_amount` (character): Maximum withdrawable amount.
    #' - `total_initial_margin` (character): Total initial margin.
    #' - `total_margin_balance` (character): Total margin balance.
    #' - `total_wallet_balance` (character): Total wallet balance.
    #' - `total_unrealized_profit` (character): Total unrealised PnL.
    #' - `update_time` (numeric): Last update timestamp in ms.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' futures <- sub$get_futures_account(email = "sub@virtual.com", futuresType = 1)
    #' print(futures)
    #' }
    get_futures_account = function(email, futuresType, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v2/sub-account/futures/account",
        query = list(
          email = email,
          futuresType = futuresType,
          recvWindow = recvWindow
        ),
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Sub-Account Margin Account
    #'
    #' Retrieves margin account details for a sub-account.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/sub-account/margin/account`
    #'
    #' ### Official Documentation
    #' [Binance Sub-Account Margin Account](https://developers.binance.com/docs/sub_account/asset-management/Get-Detail-on-Sub-accounts-Margin-Account)
    #'
    #' @param email Character; the sub-account email.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `email` (character): Sub-account email.
    #' - `margin_level` (character): Current margin level.
    #' - `total_asset_of_btc` (character): Total asset value in BTC.
    #' - `total_liability_of_btc` (character): Total liability in BTC.
    #' - `total_net_asset_of_btc` (character): Net asset value in BTC.
    #' - `margin_trade_coeff_vo` (list): Nested margin trading coefficient details.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' margin <- sub$get_margin_account(email = "sub@virtual.com")
    #' print(margin)
    #' }
    get_margin_account = function(email, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/sub-account/margin/account",
        query = list(
          email = email,
          recvWindow = recvWindow
        ),
        .parser = as_dt_row
      ))
    },

    # ---- Status ----

    #' @description
    #' Get Sub-Account Status
    #'
    #' Retrieves the status of sub-accounts, including enablement flags and
    #' activity state.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/sub-account/status`
    #'
    #' ### Official Documentation
    #' [Binance Sub-Account Status](https://developers.binance.com/docs/sub_account/account-management/Get-Sub-accounts-Status-on-Margin-Or-Futures)
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "email": "testsub01@virtual.com",
    #'     "isSubUserEnabled": true,
    #'     "isUserActive": true,
    #'     "insertTime": 1661493146000,
    #'     "isMarginEnabled": false,
    #'     "isFutureEnabled": false,
    #'     "mobile": 0
    #'   }
    #' ]
    #' ```
    #'
    #' @param email Character or NULL; filter by sub-account email.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per sub-account and the following columns:
    #' - `email` (character): Sub-account email.
    #' - `is_sub_user_enabled` (logical): Whether the sub-user is enabled.
    #' - `is_user_active` (logical): Whether the user is active.
    #' - `insert_time` (integer): Account insert timestamp.
    #' - `is_margin_enabled` (logical): Whether margin trading is enabled.
    #' - `is_future_enabled` (logical): Whether futures trading is enabled.
    #' - `mobile` (integer): Mobile verification status.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' status <- sub$get_status()
    #' print(status)
    #' }
    get_status = function(email = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/sub-account/status",
        query = list(
          email = email,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table())
          }
          return(as_dt_list(data))
        }
      ))
    }
  )
)
