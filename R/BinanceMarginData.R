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
#' [Binance Margin Account/Trade](https://binance-docs.github.io/apidocs/spot/en/#margin-account-trade)
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
    #' [Binance Get All Cross Margin Pairs](https://binance-docs.github.io/apidocs/spot/en/#get-all-cross-margin-pairs-market_data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/allPairs' \
    #'   -H 'X-MBX-APIKEY: <key>'
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
    #' [Binance Get All Isolated Margin Symbol](https://binance-docs.github.io/apidocs/spot/en/#get-all-isolated-margin-symbol-user_data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/isolated/allPairs' \
    #'   -H 'X-MBX-APIKEY: <key>'
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
    #' [Binance Query Margin PriceIndex](https://binance-docs.github.io/apidocs/spot/en/#query-margin-priceindex-market_data)
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
          if (nrow(dt) > 0 && "calc_time" %in% names(dt)) {
            dt[, calc_time := ms_to_datetime(calc_time)]
          }
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
    #' [Binance Query Margin Interest Rate History](https://binance-docs.github.io/apidocs/spot/en/#query-margin-interest-rate-history-user_data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/interestRateHistory?asset=BTC' \
    #'   -H 'X-MBX-APIKEY: <key>'
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
          if (nrow(dt) > 0 && "timestamp" %in% names(dt)) {
            dt[, timestamp := ms_to_datetime(timestamp)]
          }
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
    #' [Binance Query Cross Margin Fee Data](https://binance-docs.github.io/apidocs/spot/en/#query-cross-margin-fee-data-user_data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/crossMarginData' \
    #'   -H 'X-MBX-APIKEY: <key>'
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
    #'   - `marginable_pairs` (list): List of marginable trading pairs.
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
          return(as_dt_list(data)[])
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
    #' [Binance Query Isolated Margin Fee Data](https://binance-docs.github.io/apidocs/spot/en/#query-isolated-margin-fee-data-user_data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/margin/isolatedMarginData' \
    #'   -H 'X-MBX-APIKEY: <key>'
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
