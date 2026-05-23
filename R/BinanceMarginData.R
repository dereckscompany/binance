# File: R/BinanceMarginData.R
# R6 class for Binance Margin-specific market data retrieval.

#' BinanceMarginData: Margin Market Data Retrieval
#'
#' Provides methods for retrieving margin-specific market data from Binance,
#' including cross/isolated margin pairs, price indices, interest rate history,
#' and margin data summaries.
#'
#' Inherits from [BinanceBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Margin Pairs**: Retrieve available cross and isolated margin trading pairs.
#' - **Price Index**: Access margin price index for a symbol.
#' - **Interest Rates**: Get historical interest rate data for margin borrowing.
#' - **Margin Data**: Retrieve cross and isolated margin data including borrowing limits and interest rates.
#'
#' ### Usage
#' Most methods require authentication (valid API key and secret).
#' `get_price_index` is a public endpoint requiring no authentication.
#'
#' ### Official Documentation
#' [Binance Margin Account/Trade](https://developers.binance.com/docs/margin_trading/trade)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Auth |
#' |--------|----------|------|
#' | get_all_pairs | GET /sapi/v1/margin/allPairs | Yes |
#' | get_isolated_pairs | GET /sapi/v1/margin/isolated/allPairs | Yes |
#' | get_price_index | GET /sapi/v1/margin/priceIndex | No |
#' | get_interest_rate_history | GET /sapi/v1/margin/interestRateHistory | Yes |
#' | get_cross_margin_data | GET /sapi/v1/margin/crossMarginData | Yes |
#' | get_isolated_margin_data | GET /sapi/v1/margin/isolatedMarginData | Yes |
#'
#' @examples
#' \dontrun{
#' # Synchronous usage
#' margin <- BinanceMarginData$new()
#' pairs <- margin$get_all_pairs()
#' print(pairs)
#'
#' # Public endpoint (no auth needed)
#' margin_pub <- BinanceMarginData$new()
#' idx <- margin_pub$get_price_index("BTCUSDT")
#' print(idx)
#'
#' # Asynchronous usage
#' margin_async <- BinanceMarginData$new(async = TRUE)
#' main <- coro::async(function() {
#'   pairs <- await(margin_async$get_all_pairs())
#'   print(pairs)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceMarginData <- R6::R6Class(
  "BinanceMarginData",
  inherit = BinanceBase,
  public = list(
    # ---- All Cross Margin Pairs ----

    #' @description
    #' Get All Cross Margin Pairs
    #'
    #' Retrieves a list of all cross margin trading pairs available on Binance.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/allPairs`
    #'
    #' ### Official Documentation
    #' [Binance Get All Cross Margin Pairs](https://developers.binance.com/docs/margin_trading/market-data/Get-All-Cross-Margin-Pairs)
    #'
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/allPairs' \
    #'   -H 'X-MBX-APIKEY: <key>'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "base": "BTC",
    #'     "id": 351637150,
    #'     "isBuyAllowed": true,
    #'     "isMarginTrade": true,
    #'     "isSellAllowed": true,
    #'     "quote": "USDT",
    #'     "symbol": "BTCUSDT"
    #'   },
    #'   {
    #'     "base": "ETH",
    #'     "id": 351637155,
    #'     "isBuyAllowed": true,
    #'     "isMarginTrade": true,
    #'     "isSellAllowed": true,
    #'     "quote": "USDT",
    #'     "symbol": "ETHUSDT"
    #'   }
    #' ]
    #' ```
    #'
    #' @param recvWindow Integer or NULL; request validity window in milliseconds.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `base` (character): Base asset code (e.g., `"BTC"`).
    #'   - `id` (integer): Pair identifier.
    #'   - `is_buy_allowed` (logical): Whether buying is allowed.
    #'   - `is_margin_trade` (logical): Whether margin trading is enabled.
    #'   - `is_sell_allowed` (logical): Whether selling is allowed.
    #'   - `quote` (character): Quote asset code (e.g., `"USDT"`).
    #'   - `symbol` (character): Trading pair identifier (e.g., `"BTCUSDT"`).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMarginData$new()
    #' pairs <- margin$get_all_pairs()
    #' print(pairs)
    #' }
    get_all_pairs = function(recvWindow = NULL) {
      query <- list(recvWindow = recvWindow)
      return(private$.request(
        endpoint = "/sapi/v1/margin/allPairs",
        query = query,
        auth = TRUE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(data)[])
        }
      ))
    },

    # ---- All Isolated Margin Pairs ----

    #' @description
    #' Get All Isolated Margin Pairs
    #'
    #' Retrieves a list of all isolated margin trading pairs available on Binance.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/isolated/allPairs`
    #'
    #' ### Official Documentation
    #' [Binance Get All Isolated Margin Symbol](https://developers.binance.com/docs/margin_trading/market-data/Get-All-Isolated-Margin-Symbol)
    #'
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/isolated/allPairs' \
    #'   -H 'X-MBX-APIKEY: <key>'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "base": "BTC",
    #'     "quote": "USDT",
    #'     "isMarginTrade": true,
    #'     "isBuyAllowed": true,
    #'     "isSellAllowed": true
    #'   },
    #'   {
    #'     "symbol": "ETHUSDT",
    #'     "base": "ETH",
    #'     "quote": "USDT",
    #'     "isMarginTrade": true,
    #'     "isBuyAllowed": true,
    #'     "isSellAllowed": true
    #'   }
    #' ]
    #' ```
    #'
    #' @param recvWindow Integer or NULL; request validity window in milliseconds.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier (e.g., `"BTCUSDT"`).
    #'   - `base` (character): Base asset code (e.g., `"BTC"`).
    #'   - `quote` (character): Quote asset code (e.g., `"USDT"`).
    #'   - `is_margin_trade` (logical): Whether margin trading is enabled.
    #'   - `is_buy_allowed` (logical): Whether buying is allowed.
    #'   - `is_sell_allowed` (logical): Whether selling is allowed.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMarginData$new()
    #' pairs <- margin$get_isolated_pairs()
    #' print(pairs)
    #' }
    get_isolated_pairs = function(recvWindow = NULL) {
      query <- list(recvWindow = recvWindow)
      return(private$.request(
        endpoint = "/sapi/v1/margin/isolated/allPairs",
        query = query,
        auth = TRUE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(data)[])
        }
      ))
    },

    # ---- Price Index ----

    #' @description
    #' Get Margin Price Index
    #'
    #' Retrieves the margin price index for a given symbol. This is a public
    #' endpoint that does not require authentication.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/priceIndex`
    #'
    #' ### Official Documentation
    #' [Binance Query Margin PriceIndex](https://developers.binance.com/docs/margin_trading/market-data/Query-Margin-PriceIndex)
    #'
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/priceIndex?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' { "calcTime": 1562046418000, "price": "67232.90000000", "symbol": "BTCUSDT" }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `calc_time` (POSIXct): Calculation time as UTC datetime.
    #'   - `price` (character): Margin price index value.
    #'   - `symbol` (character): Trading pair identifier.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMarginData$new()
    #' idx <- margin$get_price_index("BTCUSDT")
    #' print(idx)
    #' }
    get_price_index = function(symbol) {
      return(private$.request(
        endpoint = "/sapi/v1/margin/priceIndex",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "calc_time", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Interest Rate History ----

    #' @description
    #' Get Interest Rate History
    #'
    #' Retrieves historical interest rate data for a given asset.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/interestRateHistory`
    #'
    #' ### Official Documentation
    #' [Binance Query Margin Interest Rate History](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Query-Margin-Interest-Rate-History)
    #'
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/interestRateHistory?asset=BTC' \
    #'   -H 'X-MBX-APIKEY: <key>'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "asset": "BTC",
    #'     "dailyInterestRate": "0.00025000",
    #'     "timestamp": 1611544731000,
    #'     "vipLevel": 0
    #'   },
    #'   {
    #'     "asset": "BTC",
    #'     "dailyInterestRate": "0.00020000",
    #'     "timestamp": 1611458331000,
    #'     "vipLevel": 0
    #'   }
    #' ]
    #' ```
    #'
    #' @param asset Character; asset code (e.g., `"BTC"`).
    #' @param vipLevel Integer or NULL; VIP level to query. Defaults to user's VIP level.
    #' @param startTime Numeric or NULL; start time in milliseconds.
    #' @param endTime Numeric or NULL; end time in milliseconds.
    #' @param recvWindow Integer or NULL; request validity window in milliseconds.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `asset` (character): Asset code (e.g., `"BTC"`).
    #'   - `daily_interest_rate` (character): Daily interest rate as string.
    #'   - `timestamp` (POSIXct): Record timestamp as UTC datetime.
    #'   - `vip_level` (integer): VIP level for this rate.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMarginData$new()
    #' history <- margin$get_interest_rate_history("BTC")
    #' print(history)
    #' }
    get_interest_rate_history = function(asset, vipLevel = NULL, startTime = NULL, endTime = NULL, recvWindow = NULL) {
      query <- list(
        asset = asset,
        vipLevel = vipLevel,
        startTime = startTime,
        endTime = endTime,
        recvWindow = recvWindow
      )
      return(private$.request(
        endpoint = "/sapi/v1/margin/interestRateHistory",
        query = query,
        auth = TRUE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "timestamp", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Cross Margin Data ----

    #' @description
    #' Get Cross Margin Data
    #'
    #' Retrieves cross margin data including borrowing limits and interest rates.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/crossMarginData`
    #'
    #' ### Official Documentation
    #' [Binance Query Cross Margin Fee Data](https://developers.binance.com/docs/margin_trading/account/Query-Cross-Margin-Fee-Data)
    #'
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/crossMarginData' \
    #'   -H 'X-MBX-APIKEY: <key>'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "vipLevel": 0,
    #'     "coin": "BTC",
    #'     "transferIn": true,
    #'     "transferOut": true,
    #'     "borrowable": true,
    #'     "dailyInterest": "0.00026125",
    #'     "yearlyInterest": "0.0953",
    #'     "marginablePairs": ["BTCUSDT", "BTCBUSD"]
    #'   },
    #'   {
    #'     "vipLevel": 0,
    #'     "coin": "ETH",
    #'     "transferIn": true,
    #'     "transferOut": true,
    #'     "borrowable": true,
    #'     "dailyInterest": "0.00027400",
    #'     "yearlyInterest": "0.1000",
    #'     "marginablePairs": ["ETHUSDT", "ETHBUSD", "ETHBTC"]
    #'   }
    #' ]
    #' ```
    #'
    #' @param vipLevel Integer or NULL; VIP level to query. Defaults to user's VIP level.
    #' @param coin Character or NULL; specific coin to query (e.g., `"BTC"`).
    #' @param recvWindow Integer or NULL; request validity window in milliseconds.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `vip_level` (integer): VIP level tier.
    #'   - `coin` (character): Coin code (e.g., `"BTC"`).
    #'   - `transfer_in` (logical): Whether transfer in is allowed.
    #'   - `transfer_out` (logical): Whether transfer out is allowed.
    #'   - `borrowable` (logical): Whether borrowing is allowed.
    #'   - `daily_interest` (character): Daily interest rate as string.
    #'   - `yearly_interest` (character): Yearly interest rate as string.
    #'   - `marginable_pair` (character): Marginable trading pair (one row per coin-pair combination).
    #'
    #' When a coin has multiple marginable pairs, coin-level fields are repeated on each row.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMarginData$new()
    #' data <- margin$get_cross_margin_data()
    #' print(data)
    #' }
    get_cross_margin_data = function(vipLevel = NULL, coin = NULL, recvWindow = NULL) {
      query <- list(
        vipLevel = vipLevel,
        coin = coin,
        recvWindow = recvWindow
      )
      return(private$.request(
        endpoint = "/sapi/v1/margin/crossMarginData",
        query = query,
        auth = TRUE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          # Expand marginablePairs to long format before building rows
          rows <- lapply(data, function(item) {
            pairs <- item$marginablePairs
            item$marginablePairs <- NULL
            dt <- as_dt_row(item)
            if (!is.null(pairs) && length(pairs) > 0) {
              pair_vals <- unlist(pairs)
              dt <- dt[rep(1L, length(pair_vals))]
              dt[, marginable_pair := pair_vals]
            }
            return(dt)
          })
          return(data.table::rbindlist(rows, fill = TRUE)[])
        }
      ))
    },

    # ---- Isolated Margin Data ----

    #' @description
    #' Get Isolated Margin Data
    #'
    #' Retrieves isolated margin data including leverage and borrowing limits.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/margin/isolatedMarginData`
    #'
    #' ### Official Documentation
    #' [Binance Query Isolated Margin Fee Data](https://developers.binance.com/docs/margin_trading/account/Query-Isolated-Margin-Fee-Data)
    #'
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/isolatedMarginData' \
    #'   -H 'X-MBX-APIKEY: <key>'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "vipLevel": 0,
    #'     "symbol": "BTCUSDT",
    #'     "leverage": "10",
    #'     "data": [
    #'       {
    #'         "coin": "BTC",
    #'         "dailyInterest": "0.00026125",
    #'         "borrowLimit": "9.00000000"
    #'       },
    #'       {
    #'         "coin": "USDT",
    #'         "dailyInterest": "0.000475",
    #'         "borrowLimit": "270000.00000000"
    #'       }
    #'     ]
    #'   },
    #'   {
    #'     "vipLevel": 0,
    #'     "symbol": "ETHUSDT",
    #'     "leverage": "10",
    #'     "data": [
    #'       {
    #'         "coin": "ETH",
    #'         "dailyInterest": "0.00027400",
    #'         "borrowLimit": "90.00000000"
    #'       },
    #'       {
    #'         "coin": "USDT",
    #'         "dailyInterest": "0.000475",
    #'         "borrowLimit": "270000.00000000"
    #'       }
    #'     ]
    #'   }
    #' ]
    #' ```
    #'
    #' @param vipLevel Integer or NULL; VIP level to query. Defaults to user's VIP level.
    #' @param symbol Character or NULL; specific symbol to query (e.g., `"BTCUSDT"`).
    #' @param recvWindow Integer or NULL; request validity window in milliseconds.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `vip_level` (integer): VIP level tier.
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `leverage` (character): Maximum leverage available.
    #'   - `data` (list): Nested list of coin-level margin details.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- BinanceMarginData$new()
    #' data <- margin$get_isolated_margin_data()
    #' print(data)
    #' }
    get_isolated_margin_data = function(vipLevel = NULL, symbol = NULL, recvWindow = NULL) {
      query <- list(
        vipLevel = vipLevel,
        symbol = symbol,
        recvWindow = recvWindow
      )
      return(private$.request(
        endpoint = "/sapi/v1/margin/isolatedMarginData",
        query = query,
        auth = TRUE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(data)[])
        }
      ))
    }
  )
)
