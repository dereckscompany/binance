# File: R/BinanceAccount.R
# R6 class for Binance account and funding operations.

#' BinanceAccount: Account and Funding Management
#'
#' Provides methods for querying account information, balances, and trade
#' history on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Account Info**: Retrieve balances, commission rates, and account permissions.
#' - **Trade History**: Paginated trade history for any symbol with datetime conversion.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret set via
#' environment variables or passed to the constructor).
#'
#' ### Official Documentation
#' [Binance Account Endpoints](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_account_info | GET /api/v3/account | GET |
#' | get_balances | GET /api/v3/account | GET |
#' | get_trades | GET /api/v3/myTrades | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' account <- BinanceAccount$new()
#' info <- account$get_account_info()
#' print(info)
#' balances <- account$get_balances()
#' print(balances)
#'
#' # Asynchronous
#' account_async <- BinanceAccount$new(async = TRUE)
#' main <- coro::async(function() {
#'   info <- await(account_async$get_account_info())
#'   print(info)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceAccount <- R6::R6Class(
  "BinanceAccount",
  inherit = BinanceBase,
  public = list(
    #' @description
    #' Get Account Information
    #'
    #' Retrieves account metadata including commission rates, trading permissions,
    #' and account type. For balances, use `get_balances()`.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/account`
    #'
    #' ### Official Documentation
    #' [Binance Account Information](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#account-information-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### Automated Trading Usage
    #' - **Commission Rates**: Access maker/taker commission rates for cost analysis.
    #' - **Permission Check**: Confirm `can_trade` is TRUE before placing orders.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/account' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'timestamp=1729176273859&signature=...'
    #' ```
    #'
    #' ### JSON Response
    #' Shape captured 2026-05-22 from the live docs.
    #' ```json
    #' {
    #'   "makerCommission": 15,
    #'   "takerCommission": 15,
    #'   "buyerCommission": 0,
    #'   "sellerCommission": 0,
    #'   "commissionRates": {
    #'     "maker": "0.00150000",
    #'     "taker": "0.00150000",
    #'     "buyer": "0.00000000",
    #'     "seller": "0.00000000"
    #'   },
    #'   "canTrade": true,
    #'   "canWithdraw": true,
    #'   "canDeposit": true,
    #'   "brokered": false,
    #'   "requireSelfTradePrevention": false,
    #'   "preventSor": false,
    #'   "updateTime": 123456789,
    #'   "accountType": "SPOT",
    #'   "balances": [
    #'     { "asset": "BTC", "free": "4723846.89208129", "locked": "0.00000000" }
    #'   ],
    #'   "permissions": ["SPOT", "MARGIN"],
    #'   "uid": 354937868
    #' }
    #' ```
    #'
    #' Note: this parser drops the `balances` array — call `get_balances()`
    #' for the per-asset shape. `commissionRates` is flattened to wide
    #' `commission_rates_*` columns and `permissions` is `;`-collapsed
    #' so the return is always one row per account.
    #'
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `maker_commission` (integer): Maker commission rate (basis points).
    #' - `taker_commission` (integer): Taker commission rate (basis points).
    #' - `buyer_commission` (integer): Buyer commission rate (basis points).
    #' - `seller_commission` (integer): Seller commission rate (basis points).
    #' - `commission_rates_maker` (character): Maker commission rate as decimal string.
    #' - `commission_rates_taker` (character): Taker commission rate as decimal string.
    #' - `commission_rates_buyer` (character): Buyer commission rate as decimal string.
    #' - `commission_rates_seller` (character): Seller commission rate as decimal string.
    #' - `can_trade` (logical): Whether the account can place trades.
    #' - `can_withdraw` (logical): Whether the account can withdraw.
    #' - `can_deposit` (logical): Whether the account can deposit.
    #' - `brokered` (logical): Whether this is a brokered account.
    #' - `require_self_trade_prevention` (logical): Whether STP is required.
    #' - `prevent_sor` (logical): Whether smart order routing is prevented.
    #' - `update_time` (POSIXct): Last account update time.
    #' - `account_type` (character): Account type (e.g., `"SPOT"`).
    #' - `permissions` (character): `;`-separated account permissions
    #'   (e.g., `"SPOT;MARGIN"`). Recover the vector with
    #'   `strsplit(dt$permissions[1], ";", fixed = TRUE)[[1]]`. Single
    #'   row per account — collapsed via the shared
    #'   `collapse_string_array_fields()` helper for cross-package
    #'   consistency.
    #' - `uid` (integer): Unique account identifier.
    #'
    #' @examples
    #' \dontrun{
    #' account <- BinanceAccount$new()
    #' info <- account$get_account_info()
    #' print(info[, .(maker_commission, taker_commission, can_trade, account_type)])
    #' }
    get_account_info = function(recvWindow = NULL) {
      return(private$.request(
        endpoint = "/api/v3/account",
        query = list(recvWindow = recvWindow),
        .parser = function(data) {
          data$balances <- NULL
          # Flatten `commissionRates` nested object into wide columns
          # (Treatment B — fixed-schema object).
          cr <- data$commissionRates
          if (!is.null(cr)) {
            for (nm in names(cr)) {
              data[[paste0("commissionRates_", nm)]] <- cr[[nm]]
            }
            data$commissionRates <- NULL
          }
          # `permissions` is an array of plain strings — collapse to a
          # `;`-joined character column via the shared helper. This
          # matches the cross-package convention and keeps the account
          # info shape stable at exactly one row (the README's contract).
          data <- collapse_string_array_fields(data, "permissions")
          dt <- as_dt_row(data)
          coerce_cols(dt, "update_time", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Account Balances
    #'
    #' Retrieves asset balances for the account.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/account`
    #'
    #' ### Official Documentation
    #' [Binance Account Information](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#account-information-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### Automated Trading Usage
    #' - **Balance Check**: Verify available funds before placing orders.
    #' - **Portfolio Overview**: Get all asset balances in a single call.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/account?omitZeroBalances=true' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'timestamp=1729176273859&signature=...'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "asset": "BTC",
    #'     "free": "0.00100000",
    #'     "locked": "0.00000000"
    #'   },
    #'   {
    #'     "asset": "USDT",
    #'     "free": "500.00000000",
    #'     "locked": "50.00000000"
    #'   }
    #' ]
    #' ```
    #'
    #' @param omitZeroBalances Logical or NULL; if TRUE, omit assets with zero balance.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `asset` (character): Asset ticker (e.g., `"BTC"`, `"USDT"`).
    #' - `free` (character): Available balance for trading.
    #' - `locked` (character): Balance locked in open orders.
    #'
    #' @examples
    #' \dontrun{
    #' account <- BinanceAccount$new()
    #' balances <- account$get_balances()
    #' print(balances[free != "0.00000000"])
    #' }
    get_balances = function(omitZeroBalances = NULL, recvWindow = NULL) {
      query <- list(recvWindow = recvWindow)
      if (isTRUE(omitZeroBalances)) {
        query$omitZeroBalances <- "true"
      }

      return(private$.request(
        endpoint = "/api/v3/account",
        query = query,
        .parser = function(data) {
          balances <- data$balances
          if (is.null(balances) || length(balances) == 0) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(balances)[])
        }
      ))
    },

    #' @description
    #' Get Account Trade List
    #'
    #' Retrieves trades for a specific symbol. Requires authentication.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/myTrades`
    #'
    #' ### Official Documentation
    #' [Binance Account Trade List](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#account-trade-list-user_data)
    #' Verified: 2026-05-22
    #'
    #' ### Automated Trading Usage
    #' - **Trade History**: Build trade logs for P&L calculations.
    #' - **Fill Analysis**: Analyse execution quality across trades.
    #' - **Tax Reporting**: Export trade history for tax calculations.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/myTrades?symbol=BTCUSDT' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'timestamp=1729176273859&signature=...'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BNBBTC",
    #'     "id": 28457,
    #'     "orderId": 100234,
    #'     "price": "4.00000100",
    #'     "qty": "12.00000000",
    #'     "quoteQty": "48.000012",
    #'     "commission": "10.10000000",
    #'     "commissionAsset": "BNB",
    #'     "time": 1499865549590,
    #'     "isBuyer": true,
    #'     "isMaker": false,
    #'     "isBestMatch": true
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param orderId Integer or NULL; filter by order ID.
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param fromId Integer or NULL; trade ID to fetch from.
    #' @param limit Integer or NULL; max results (default 500, max 1000).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per trade and the following columns:
    #' - `symbol` (character): Trading pair (e.g., `"BTCUSDT"`).
    #' - `id` (integer): Unique trade identifier.
    #' - `order_id` (integer): Order that generated this trade.
    #' - `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.
    #' - `price` (character): Execution price.
    #' - `qty` (character): Quantity traded.
    #' - `quote_qty` (character): Quote asset amount transacted.
    #' - `commission` (character): Commission charged.
    #' - `commission_asset` (character): Asset used for commission (e.g., `"BNB"`).
    #' - `is_buyer` (logical): `TRUE` if you were the buyer.
    #' - `is_maker` (logical): `TRUE` if you were the maker.
    #' - `is_best_match` (logical): `TRUE` if this was the best price match.
    #' - `time` (POSIXct): Trade execution time converted from `time`.
    #'
    #' @examples
    #' \dontrun{
    #' account <- BinanceAccount$new()
    #' trades <- account$get_trades("BTCUSDT", limit = 50)
    #' print(trades[, .(id, price, qty, commission, time)])
    #' }
    get_trades = function(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      fromId = NULL,
      limit = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/api/v3/myTrades",
        query = list(
          symbol = symbol,
          orderId = orderId,
          startTime = startTime,
          endTime = endTime,
          fromId = fromId,
          limit = limit,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "time", ms_to_datetime)
          return(dt[])
        }
      ))
    }
  )
)
