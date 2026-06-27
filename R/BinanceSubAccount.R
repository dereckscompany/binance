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
    #' Verified: 2026-05-22
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
    #' @param subAccountString (scalar<character>) the sub-account name/string identifier.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - email (character) The email of the newly created sub-account.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' result <- sub$add_sub_account(subAccountString = "mysubaccount")
    #' print(result$email)
    #' }
    add_sub_account = function(subAccountString, recvWindow = NULL) {
      assert_args_BinanceSubAccount__add_sub_account(subAccountString, recvWindow)
      assert::assert_nonempty_strings(subAccountString)
      res <- private$.request(
        endpoint = "/sapi/v1/sub-account/virtualSubAccount",
        method = "POST",
        body = list(
          subAccountString = subAccountString,
          recvWindow = recvWindow
        ),
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__add_sub_account,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/sub-account/list?timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
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
    #' @param email (scalar<character>?) filter by sub-account email.
    #' @param isFreeze (scalar<logical>?) filter by freeze status.
    #' @param page (scalar<count>?) page number (default 1).
    #' @param limit (scalar<count>?) results per page (default 1, max 200).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per sub-account
    #'   (empty when there are none):
    #' - email (character) Sub-account email.
    #' - is_freeze (logical) Whether the sub-account is frozen.
    #' - create_time (POSIXct) Account creation time converted from `createTime`.
    #' - is_managed_sub_account (logical) Whether it is a managed sub-account.
    #' - is_asset_management_sub_account (logical) Whether it is an asset management sub-account.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' accounts <- sub$get_sub_accounts()
    #' print(accounts[, .(email, is_freeze, create_time)])
    #' }
    get_sub_accounts = function(email = NULL, isFreeze = NULL, page = NULL, limit = NULL, recvWindow = NULL) {
      assert_args_BinanceSubAccount__get_sub_accounts(email, isFreeze, page, limit, recvWindow)
      assert::assert_nonempty_strings(email, null_ok = TRUE)
      res <- private$.request(
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
            return(empty_dt_sub_accounts())
          }
          dt <- as_dt_list(items)
          coerce_cols(dt, "create_time", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__get_sub_accounts,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v3/sub-account/assets?email=sub%40virtual.com&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
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
    #' @param email (scalar<character>) the sub-account email.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per asset
    #'   (empty when there are none):
    #' - asset (character) Asset symbol (e.g., `"BTC"`).
    #' - free (numeric) Available balance.
    #' - locked (numeric) Locked balance.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' balances <- sub$get_balances(email = "sub@virtual.com")
    #' print(balances)
    #' }
    get_balances = function(email, recvWindow = NULL) {
      assert_args_BinanceSubAccount__get_balances(email, recvWindow)
      assert::assert_nonempty_strings(email)
      res <- private$.request(
        endpoint = "/sapi/v3/sub-account/assets",
        query = list(
          email = email,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          items <- data$balances
          if (is.null(items) || length(items) == 0) {
            return(empty_dt_sub_balances())
          }
          dt <- as_dt_list(items)
          # `free` / `locked` are JSON numbers; an all-whole-number column
          # parses as integer, so coerce to numeric for a stable double schema.
          coerce_cols(dt, c("free", "locked"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__get_balances,
        is_async = private$.is_async
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
    #' [Binance Sub-Account Spot Summary](https://developers.binance.com/docs/sub_account/asset-management/Query-Sub-account-Spot-Assets-Summary)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/sub-account/spotSummary?timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "totalCount": 2,
    #'   "masterAccountTotalAsset": "0.23456789",
    #'   "spotSubUserAssetBtcVoList": [
    #'     {
    #'       "email": "testsub01@virtual.com",
    #'       "totalAsset": "0.12345678"
    #'     },
    #'     {
    #'       "email": "testsub02@virtual.com",
    #'       "totalAsset": "0.11111111"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param email (scalar<character>?) filter by sub-account email.
    #' @param page (scalar<count>?) page number (default 1).
    #' @param size (scalar<count>?) results per page (default 10, max 20).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per sub-account
    #'   (empty when there are none); the master-level summary fields are
    #'   replicated on each row:
    #' - total_count (integer) Total number of sub-accounts (repeated per row).
    #' - master_account_total_asset (character) Master account total
    #'   asset value in BTC (repeated per row).
    #' - sub_user_email (character) Sub-account email.
    #' - sub_user_total_asset (character) Sub-account total asset value in BTC.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' summary <- sub$get_spot_summary()
    #' print(summary)
    #' }
    get_spot_summary = function(email = NULL, page = NULL, size = NULL, recvWindow = NULL) {
      assert_args_BinanceSubAccount__get_spot_summary(email, page, size, recvWindow)
      assert::assert_nonempty_strings(email, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/sub-account/spotSummary",
        query = list(
          email = email,
          page = page,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_sub_spot_summary())
          }
          sub_users <- data$spotSubUserAssetBtcVoList
          data$spotSubUserAssetBtcVoList <- NULL
          # If there are no sub-accounts return the typed empty data.table.
          # The `@return` says "one row per sub-account", so zero
          # sub-accounts is zero rows — fabricating a 1-row table of
          # just master-level fields would violate the cross-package
          # "no stub rows" convention (the master-level scalars are
          # also available without calling this method).
          if (is.null(sub_users) || length(sub_users) == 0) {
            return(empty_dt_sub_spot_summary())
          }
          dt <- as_dt_row(data)
          sub_dt <- as_dt_list(sub_users)
          sub_names <- names(sub_dt)
          data.table::setnames(sub_dt, sub_names, paste0("sub_user_", sub_names))
          dt <- dt[rep(1L, nrow(sub_dt))]
          dt <- cbind(dt, sub_dt)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__get_spot_summary,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/sub-account/universalTransfer' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'toEmail=sub%40virtual.com&fromAccountType=SPOT&toAccountType=SPOT&asset=USDT&amount=100&timestamp=...&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "fromEmail": "master@test.com",
    #'   "toEmail": "sub@virtual.com",
    #'   "fromAccountType": "SPOT",
    #'   "toAccountType": "SPOT",
    #'   "asset": "USDT",
    #'   "amount": "100",
    #'   "clientTranId": "test_transfer_001"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "tranId": 11945860693,
    #'   "clientTranId": "test_transfer_001"
    #' }
    #' ```
    #'
    #' @param fromEmail (scalar<character>?) sender sub-account email.
    #' @param toEmail (scalar<character>?) recipient sub-account email.
    #' @param fromAccountType (scalar<character>) source account type. One of
    #'   `"SPOT"`, `"USDT_FUTURE"`, `"COIN_FUTURE"`, `"MARGIN"`, `"ISOLATED_MARGIN"`.
    #' @param toAccountType (scalar<character>) destination account type. One of
    #'   `"SPOT"`, `"USDT_FUTURE"`, `"COIN_FUTURE"`, `"MARGIN"`, `"ISOLATED_MARGIN"`.
    #' @param asset (scalar<character>) asset to transfer (e.g., `"USDT"`).
    #' @param amount (scalar<numeric>) amount to transfer.
    #' @param clientTranId (scalar<character>?) client-defined transfer ID.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row:
    #' - tran_id (numeric) Binance-assigned transfer ID (a large integer that
    #'   overflows R's 32-bit `integer`, so it arrives as a double).
    #' - client_tran_id (character) Client-defined transfer ID.
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
      assert_args_BinanceSubAccount__add_transfer(
        fromEmail,
        toEmail,
        fromAccountType,
        toAccountType,
        asset,
        amount,
        clientTranId,
        recvWindow
      )
      assert::assert_nonempty_strings(fromEmail, null_ok = TRUE)
      assert::assert_nonempty_strings(toEmail, null_ok = TRUE)
      assert::assert_nonempty_strings(asset)
      valid_types <- c("SPOT", "USDT_FUTURE", "COIN_FUTURE", "MARGIN", "ISOLATED_MARGIN")
      if (!fromAccountType %in% valid_types) {
        rlang::abort(paste0(
          "'fromAccountType' must be one of: ",
          paste(valid_types, collapse = ", "),
          ". Got: '",
          fromAccountType,
          "'."
        ))
      }
      if (!toAccountType %in% valid_types) {
        rlang::abort(paste0(
          "'toAccountType' must be one of: ",
          paste(valid_types, collapse = ", "),
          ". Got: '",
          toAccountType,
          "'."
        ))
      }

      res <- private$.request(
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
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "tran_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__add_transfer,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/sub-account/universalTransfer?timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
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
    #' @param fromEmail (scalar<character>?) filter by sender email.
    #' @param toEmail (scalar<character>?) filter by recipient email.
    #' @param clientTranId (scalar<character>?) filter by client transfer ID.
    #' @param startTime (scalar<count>?) start timestamp in milliseconds.
    #' @param endTime (scalar<count>?) end timestamp in milliseconds.
    #' @param page (scalar<count>?) page number (default 1).
    #' @param limit (scalar<count>?) results per page (default 500, max 500).
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per transfer
    #'   (empty when there are none):
    #' - tran_id (numeric) Binance-assigned transfer ID (a large integer that
    #'   overflows R's 32-bit `integer`, so it arrives as a double).
    #' - from_email (character) Sender email.
    #' - to_email (character) Recipient email.
    #' - asset (character) Transferred asset.
    #' - amount (character) Transfer amount.
    #' - create_time_stamp (POSIXct) Transfer time converted from `createTimeStamp`.
    #' - from_account_type (character) Source account type.
    #' - to_account_type (character) Destination account type.
    #' - status (character) Transfer status.
    #' - client_tran_id (character) Client-defined transfer ID.
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
      assert_args_BinanceSubAccount__get_transfer_history(
        fromEmail,
        toEmail,
        clientTranId,
        startTime,
        endTime,
        page,
        limit,
        recvWindow
      )
      assert::assert_nonempty_strings(fromEmail, null_ok = TRUE)
      assert::assert_nonempty_strings(toEmail, null_ok = TRUE)
      res <- private$.request(
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
            return(empty_dt_sub_transfer_history())
          }
          dt <- as_dt_list(items)
          coerce_cols(dt, "create_time_stamp", ms_to_datetime)
          coerce_cols(dt, "tran_id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__get_transfer_history,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v2/sub-account/futures/account?email=sub%40virtual.com&futuresType=1&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "futureAccountResp": {
    #'     "email": "sub@virtual.com",
    #'     "asset": "USDT",
    #'     "assets": [
    #'       {
    #'         "asset": "USDT",
    #'         "initialMargin": "0.00000000",
    #'         "maintenanceMargin": "0.00000000",
    #'         "marginBalance": "1500.00000000",
    #'         "maxWithdrawAmount": "1500.00000000",
    #'         "openOrderInitialMargin": "0.00000000",
    #'         "positionInitialMargin": "0.00000000",
    #'         "unrealizedProfit": "0.00000000",
    #'         "walletBalance": "1500.00000000"
    #'       }
    #'     ],
    #'     "canDeposit": true,
    #'     "canTrade": true,
    #'     "canWithdraw": true,
    #'     "feeTier": 0,
    #'     "maxWithdrawAmount": "1500.00000000",
    #'     "totalInitialMargin": "0.00000000",
    #'     "totalMarginBalance": "1500.00000000",
    #'     "totalWalletBalance": "1500.00000000",
    #'     "totalUnrealizedProfit": "0.00000000",
    #'     "updateTime": 1661493146000
    #'   }
    #' }
    #' ```
    #'
    #' @param email (scalar<character>) the sub-account email.
    #' @param futuresType (scalar<count>) `1` for USDT-margined futures, `2` for COIN-margined futures.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per asset (long
    #'   format). Account-level fields (`email`, `asset`, `can_deposit`,
    #'   `can_trade`, `can_withdraw`, `fee_tier`, `max_withdraw_amount`,
    #'   `total_initial_margin`, `total_margin_balance`, `total_wallet_balance`,
    #'   `total_unrealized_profit`, `update_time`) are whichever Binance returns,
    #'   replicated per asset row; the per-asset fields are wide-prefixed
    #'   `asset_*` (e.g. `asset_asset`, `asset_wallet_balance`,
    #'   `asset_margin_balance`). The exact column set follows the payload, so
    #'   the return is typed only as a `data.table` (no fixed-column contract).
    #'   When the response contains an `assets` list, it is expanded to long
    #'   format with parent account fields repeated; when there are no assets, a
    #'   single row without asset-level columns is returned.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' futures <- sub$get_futures_account(email = "sub@virtual.com", futuresType = 1)
    #' print(futures)
    #' }
    get_futures_account = function(email, futuresType, recvWindow = NULL) {
      assert_args_BinanceSubAccount__get_futures_account(email, futuresType, recvWindow)
      assert::assert_nonempty_strings(email)
      res <- private$.request(
        endpoint = "/sapi/v2/sub-account/futures/account",
        query = list(
          email = email,
          futuresType = futuresType,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_sub_futures_account())
          }
          # The response may be wrapped in futureAccountResp
          inner <- data
          if (!is.null(data$futureAccountResp)) {
            inner <- data$futureAccountResp
          }
          assets <- inner$assets
          inner$assets <- NULL
          dt <- as_dt_row(inner)
          # Expand assets to long format: one row per asset
          if (!is.null(assets) && length(assets) > 0) {
            assets_dt <- as_dt_list(assets)
            asset_names <- names(assets_dt)
            data.table::setnames(assets_dt, asset_names, paste0("asset_", asset_names))
            dt <- dt[rep(1L, nrow(assets_dt))]
            dt <- cbind(dt, assets_dt)
          }
          coerce_cols(dt, "update_time", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__get_futures_account,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/sub-account/margin/account?email=sub%40virtual.com&timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "email": "sub@virtual.com",
    #'   "marginLevel": "11.64405625",
    #'   "totalAssetOfBtc": "6.82728457",
    #'   "totalLiabilityOfBtc": "0.58633215",
    #'   "totalNetAssetOfBtc": "6.24095242",
    #'   "marginTradeCoeffVo": {
    #'     "forceLiquidationBar": "1.1",
    #'     "marginCallBar": "1.3",
    #'     "normalBar": "1.5"
    #'   }
    #' }
    #' ```
    #'
    #' @param email (scalar<character>) the sub-account email.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row, whichever margin
    #'   account fields Binance returns (`email`, `margin_level`,
    #'   `total_asset_of_btc`, `total_liability_of_btc`,
    #'   `total_net_asset_of_btc`, and a `margin_trade_coeff_vo` list-column of
    #'   nested coefficients). The exact column set follows the payload, so the
    #'   return is typed only as a `data.table` (no fixed-column contract).
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' margin <- sub$get_margin_account(email = "sub@virtual.com")
    #' print(margin)
    #' }
    get_margin_account = function(email, recvWindow = NULL) {
      assert_args_BinanceSubAccount__get_margin_account(email, recvWindow)
      assert::assert_nonempty_strings(email)
      res <- private$.request(
        endpoint = "/sapi/v1/sub-account/margin/account",
        query = list(
          email = email,
          recvWindow = recvWindow
        ),
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__get_margin_account,
        is_async = private$.is_async
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
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/sub-account/status?timestamp=...&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
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
    #' @param email (scalar<character>?) filter by sub-account email.
    #' @param recvWindow (scalar<count>?) max 60000.
    #' @return (data.table | promise<data.table>) one row per sub-account
    #'   (empty when there are none):
    #' - email (character) Sub-account email.
    #' - is_sub_user_enabled (logical) Whether the sub-user is enabled.
    #' - is_user_active (logical) Whether the user is active.
    #' - insert_time (POSIXct) Time the sub-account was inserted.
    #' - is_margin_enabled (logical) Whether margin trading is enabled.
    #' - is_future_enabled (logical) Whether futures trading is enabled.
    #' - mobile (integer) Mobile verification status.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- BinanceSubAccount$new()
    #' status <- sub$get_status()
    #' print(status)
    #' }
    get_status = function(email = NULL, recvWindow = NULL) {
      assert_args_BinanceSubAccount__get_status(email, recvWindow)
      assert::assert_nonempty_strings(email, null_ok = TRUE)
      res <- private$.request(
        endpoint = "/sapi/v1/sub-account/status",
        query = list(
          email = email,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_sub_status())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "insert_time", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceSubAccount__get_status,
        is_async = private$.is_async
      ))
    }
  )
)
