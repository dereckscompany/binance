# File: R/BinanceFuturesData.R
# R6 class for Binance USD-M Futures market data retrieval.

#' BinanceFuturesData: USD-M Futures Market Data Retrieval
#'
#' Provides methods for retrieving market data from Binance's USD-M Futures API,
#' including exchange info, klines, mark prices, funding rates, tickers,
#' order books, open interest, and trade history.
#'
#' Inherits from [BinanceBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Exchange Info**: Retrieve futures trading pair metadata including precision, filters, and contract type.
#' - **Klines**: Fetch historical candlestick data for futures contracts.
#' - **Mark Price**: Access mark prices and funding rate information.
#' - **Funding Rates**: Get historical funding rate data.
#' - **Tickers**: Access real-time price data for individual symbols or all pairs.
#' - **Order Books**: Get order book depth snapshots.
#' - **Open Interest**: Retrieve open interest data for futures contracts.
#' - **Trade History**: Retrieve recent trades for any symbol.
#' - **Index/Mark Price Klines**: Fetch historical index price and mark price candlestick data.
#'
#' ### Usage
#' All methods are public endpoints requiring no authentication.
#' The base URL defaults to `https://fapi.binance.com` via [get_futures_base_url()].
#'
#' ### Official Documentation
#' [Binance USD-M Futures Market Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Auth |
#' |--------|----------|------|
#' | get_exchange_info | GET /fapi/v1/exchangeInfo | No |
#' | get_rate_limits | GET /fapi/v1/exchangeInfo | No |
#' | get_exchange_filters | GET /fapi/v1/exchangeInfo | No |
#' | get_futures_assets | GET /fapi/v1/exchangeInfo | No |
#' | get_klines | GET /fapi/v1/klines | No |
#' | get_mark_price | GET /fapi/v1/premiumIndex | No |
#' | get_funding_rate | GET /fapi/v1/fundingRate | No |
#' | get_24hr_stats | GET /fapi/v1/ticker/24hr | No |
#' | get_ticker | GET /fapi/v1/ticker/price | No |
#' | get_book_ticker | GET /fapi/v1/ticker/bookTicker | No |
#' | get_open_interest | GET /fapi/v1/openInterest | No |
#' | get_depth | GET /fapi/v1/depth | No |
#' | get_trades | GET /fapi/v1/trades | No |
#' | get_index_price_klines | GET /fapi/v1/indexPriceKlines | No |
#' | get_mark_price_klines | GET /fapi/v1/markPriceKlines | No |
#'
#' @examples
#' \dontrun{
#' # Synchronous usage
#' futures <- BinanceFuturesData$new()
#' mark <- futures$get_mark_price("BTCUSDT")
#' print(mark)
#'
#' # Asynchronous usage
#' futures_async <- BinanceFuturesData$new(async = TRUE)
#' main <- coro::async(function() {
#'   mark <- await(futures_async$get_mark_price("BTCUSDT"))
#'   print(mark)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom lubridate as_datetime now dhours
#' @export
BinanceFuturesData <- R6::R6Class(
  "BinanceFuturesData",
  inherit = BinanceBase,
  public = list(
    #' @description
    #' Initialise a BinanceFuturesData Object
    #'
    #' Overrides the default base URL to use the Futures API endpoint and
    #' configures the server time endpoint for futures when `time_source = "server"`.
    #'
    #' @param keys (list) API credentials from [get_api_keys()].
    #'   Defaults to `get_api_keys()`.
    #' @param base_url (scalar<character>) API base URL. Defaults to `get_futures_base_url()`.
    #' @param async (scalar<logical>) if `TRUE`, methods return promises. Default `FALSE`.
    #' @param time_source (scalar<character>) clock source for HMAC request signing.
    #'   `"local"` (default) uses `Sys.time()`. `"server"` fetches the Binance
    #'   Futures server time before each authenticated request.
    #' @return (class<BinanceFuturesData>) invisibly, self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      time_source <- match.arg(time_source)
      assert_args_BinanceFuturesData__initialize(keys, base_url, async, time_source)
      super$initialize(keys = keys, base_url = base_url, async = async, time_source = time_source)

      if (time_source == "server") {
        url <- base_url
        private$.get_timestamp_ms <- function() fetch_server_time_ms(url, "/fapi/v1/time")
      }

      return(invisible(assert_return_BinanceFuturesData__initialize(self)))
    },

    # ---- Exchange Info ----

    #' @description
    #' Get Futures Exchange Info
    #'
    #' Retrieves exchange trading rules and symbol information for USD-M futures.
    #' Includes precision, order types, filters, contract type, and trading status.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/exchangeInfo`
    #'
    #' ### Official Documentation
    #' [Binance Futures Exchange Info](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Exchange-Information)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/exchangeInfo'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "timezone": "UTC",
    #'   "serverTime": 1710028800000,
    #'   "symbols": [
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "pair": "BTCUSDT",
    #'       "contractType": "PERPETUAL",
    #'       "deliveryDate": 4133404800000,
    #'       "onboardDate": 1569398400000,
    #'       "status": "TRADING",
    #'       "baseAsset": "BTC",
    #'       "quoteAsset": "USDT",
    #'       "marginAsset": "USDT",
    #'       "pricePrecision": 2,
    #'       "quantityPrecision": 3,
    #'       "baseAssetPrecision": 8,
    #'       "quotePrecision": 8,
    #'       "underlyingType": "COIN",
    #'       "settlePlan": 0,
    #'       "triggerProtect": "0.0500",
    #'       "orderTypes": ["LIMIT", "MARKET", "STOP", "STOP_MARKET", "TAKE_PROFIT", "TAKE_PROFIT_MARKET", "TRAILING_STOP_MARKET"],
    #'       "timeInForce": ["GTC", "IOC", "FOK", "GTX", "GTD"],
    #'       "filters": [
    #'         {"filterType": "PRICE_FILTER", "minPrice": "556.80", "maxPrice": "4529764", "tickSize": "0.10"},
    #'         {"filterType": "LOT_SIZE", "minQty": "0.001", "maxQty": "1000", "stepSize": "0.001"},
    #'         {"filterType": "MIN_NOTIONAL", "notional": "5"}
    #'       ]
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @return (promise<data.table>) with all symbol
    #'   fields returned by the API, converted to snake_case. Key columns include:
    #'   - symbol (character) Trading pair identifier (e.g., `"BTCUSDT"`).
    #'   - pair (character) Underlying pair.
    #'   - contract_type (character) Contract type (e.g., `"PERPETUAL"`).
    #'   - status (character) Trading status (`"TRADING"`, etc.).
    #'   - base_asset (character) Base asset code (e.g., `"BTC"`).
    #'   - quote_asset (character) Quote asset code (e.g., `"USDT"`).
    #'   - margin_asset (character) Margin asset code (e.g., `"USDT"`).
    #'   - price_precision (integer) Decimal precision for prices.
    #'   - quantity_precision (integer) Decimal precision for quantities.
    #'   - order_types (character) Semicolon-separated allowed order types.
    #'     Recover via `strsplit(dt$order_types[1], ";", fixed = TRUE)[[1]]`.
    #'   - time_in_force (character) Semicolon-separated allowed
    #'     time-in-force values.
    #'   - underlying_sub_type (character) Semicolon-separated underlying
    #'     sub-types.
    #'   - permission_sets (character) Semicolon-separated permission sets.
    #'   - lot_min_qty (numeric) Minimum order quantity (from LOT_SIZE filter).
    #'   - lot_max_qty (numeric) Maximum order quantity (from LOT_SIZE filter).
    #'   - lot_step_size (numeric) Quantity step size (from LOT_SIZE filter).
    #'   - price_min (numeric) Minimum price (from PRICE_FILTER).
    #'   - price_max (numeric) Maximum price (from PRICE_FILTER).
    #'   - price_tick_size (numeric) Price tick size (from PRICE_FILTER).
    #'   - min_notional (numeric) Minimum notional value (from MIN_NOTIONAL filter).
    #'   - filters_raw (character) JSON-encoded copy of the full per-symbol
    #'     `filters` array. Preserves filter types not pulled into curated
    #'     columns (`PERCENT_PRICE`, `MARKET_LOT_SIZE`, `MAX_NUM_ORDERS`,
    #'     `MAX_NUM_ALGO_ORDERS`, `MIN_NOTIONAL`'s extra fields, ...).
    #'     Recover with `jsonlite::fromJSON(dt$filters_raw[1])`. `NA` if
    #'     Binance returned no filters for the symbol.
    #'
    #' Exchange-wide metadata returned by the same endpoint is exposed
    #' via sibling methods: `get_rate_limits()`, `get_exchange_filters()`,
    #' `get_futures_assets()`. Server time is available via
    #' `BinanceMarketData$get_server_time()`.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' info <- futures$get_exchange_info()
    #' print(info[, .(symbol, contract_type, status, base_asset)])
    #'
    #' # Recover filter types not in curated columns
    #' jsonlite::fromJSON(info$filters_raw[1])
    #'
    #' # Exchange-wide metadata via sibling methods
    #' futures$get_rate_limits()
    #' futures$get_futures_assets()
    #' }
    get_exchange_info = function() {
      return(private$.request(
        endpoint = "/fapi/v1/exchangeInfo",
        auth = FALSE,
        .parser = function(data) {
          syms <- data$symbols
          if (is.null(syms) || length(syms) == 0) {
            return(data.table::data.table()[])
          }

          .extract_filter <- function(filters, filter_type, field) {
            if (is.null(filters) || length(filters) == 0) {
              return(NA_real_)
            }
            for (f in filters) {
              if (!is.null(f$filterType) && f$filterType == filter_type) {
                val <- f[[field]]
                if (!is.null(val)) return(as.numeric(val))
              }
            }
            return(NA_real_)
          }

          syms <- lapply(syms, function(s) {
            # Collapse string arrays with `;` (cross-package convention;
            # see `collapse_string_array_fields()` in helpers_parse.R).
            s <- collapse_string_array_fields(
              s,
              c("orderTypes", "timeInForce", "underlyingSubType", "permissionSets")
            )
            # Extract filter values as flat numeric fields
            raw_filters <- s$filters
            s$lot_min_qty <- .extract_filter(raw_filters, "LOT_SIZE", "minQty")
            s$lot_max_qty <- .extract_filter(raw_filters, "LOT_SIZE", "maxQty")
            s$lot_step_size <- .extract_filter(raw_filters, "LOT_SIZE", "stepSize")
            s$price_min <- .extract_filter(raw_filters, "PRICE_FILTER", "minPrice")
            s$price_max <- .extract_filter(raw_filters, "PRICE_FILTER", "maxPrice")
            s$price_tick_size <- .extract_filter(raw_filters, "PRICE_FILTER", "tickSize")
            s$min_notional <- .extract_filter(raw_filters, "MIN_NOTIONAL", "notional")
            # Preserve the full filters array as a JSON string so filter
            # types we don't pull into curated columns (PERCENT_PRICE,
            # MARKET_LOT_SIZE, MAX_NUM_ORDERS, MAX_NUM_ALGO_ORDERS, etc.)
            # are still reachable. Recover with
            # `jsonlite::fromJSON(dt$filters_raw[1])`.
            if (is.null(raw_filters) || length(raw_filters) == 0L) {
              s$filters_raw <- NA_character_
            } else {
              s$filters_raw <- as.character(
                jsonlite::toJSON(raw_filters, auto_unbox = TRUE)
              )
            }
            s$filters <- NULL
            return(s)
          })
          dt <- data.table::rbindlist(
            lapply(syms, as_dt_row),
            fill = TRUE
          )
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Futures Exchange Rate Limits
    #'
    #' Retrieves the USDⓈ-M futures API rate-limit rules. Same sibling
    #' pattern as `BinanceMarketData$get_rate_limits()`.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/exchangeInfo`
    #'
    #' @return (promise<data.table>)
    #'   with one row per rate-limit rule. Columns: `rate_limit_type`,
    #'   `interval`, `interval_num`, `limit`. Empty `data.table` if
    #'   Binance returned no `rateLimits` block.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' futures$get_rate_limits()
    #' }
    get_rate_limits = function() {
      return(private$.request(
        endpoint = "/fapi/v1/exchangeInfo",
        auth = FALSE,
        .parser = function(data) {
          rl <- data$rateLimits
          if (is.null(rl) || length(rl) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(rl)[])
        }
      ))
    },

    #' @description
    #' Get Futures Exchange-Wide Filters
    #'
    #' Retrieves the exchange-wide filter rules. Almost always empty.
    #' Sibling to `get_exchange_info()`.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/exchangeInfo`
    #'
    #' @return (promise<data.table>)
    #'   with one row per exchange-wide filter rule. Empty when none.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' futures$get_exchange_filters()
    #' }
    get_exchange_filters = function() {
      return(private$.request(
        endpoint = "/fapi/v1/exchangeInfo",
        auth = FALSE,
        .parser = function(data) {
          ef <- data$exchangeFilters
          if (is.null(ef) || length(ef) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(ef)[])
        }
      ))
    },

    #' @description
    #' Get Futures Margin Assets
    #'
    #' Retrieves the margin-asset configuration returned at the top
    #' level of futures `/fapi/v1/exchangeInfo` (one row per asset
    #' usable as margin — USDT, BNFCR, etc.).
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/exchangeInfo`
    #'
    #' @return (promise<data.table>)
    #'   with one row per margin asset. Typical columns:
    #'   - asset (character) Asset symbol (e.g., `"USDT"`).
    #'   - margin_available (logical) Whether the asset can be used as margin.
    #'   - auto_asset_exchange (character) Auto-exchange threshold.
    #'
    #'   Empty `data.table` if Binance returned no `assets` block.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' futures$get_futures_assets()
    #' }
    get_futures_assets = function() {
      return(private$.request(
        endpoint = "/fapi/v1/exchangeInfo",
        auth = FALSE,
        .parser = function(data) {
          assets <- data$assets
          if (is.null(assets) || length(assets) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(assets)[])
        }
      ))
    },

    # ---- Klines ----

    #' @description
    #' Get Klines (Candlestick Data)
    #'
    #' Retrieves historical kline/candlestick data for a futures symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/klines`
    #'
    #' ### Official Documentation
    #' [Binance Futures Kline/Candlestick Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Kline-Candlestick-Data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/klines?symbol=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   [
    #'     1710028800000,
    #'     "67521.30",
    #'     "67845.90",
    #'     "67310.50",
    #'     "67632.40",
    #'     "12534.812",
    #'     1710032399999,
    #'     "847293156.23",
    #'     48921,
    #'     "6231.405",
    #'     "421234567.89",
    #'     "0"
    #'   ]
    #' ]
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param interval (scalar<character>) candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime (scalar<POSIXct> | scalar<numeric>?) start time (ms or POSIXct).
    #' @param endTime (scalar<POSIXct> | scalar<numeric>?) end time (ms or POSIXct).
    #' @param limit (scalar<count>?) max results (default 500, max 1500).
    #' @param fetch_all (scalar<logical>) if `TRUE`, automatically pages forward through the
    #'   time range — following the data and stopping at the first empty or short
    #'   page — and returns the combined result sorted by `open_time`. Both
    #'   `startTime` and `endTime` are required when enabled. **Warning**: large
    #'   date ranges will consume multiple API requests and may impact your
    #'   rate-limit quota. Default `FALSE`.
    #' @param sleep (scalar<numeric>) seconds to wait between consecutive API calls when
    #'   `fetch_all = TRUE`. Use this to avoid hitting Binance rate limits. Only
    #'   applies in synchronous mode; async mode chains requests sequentially via
    #'   promises. Default `0.2`.
    #' @param on_page (function?) optional `function(page)` called with each page (a
    #'   `data.table`) as it is fetched, when `fetch_all = TRUE`. When supplied,
    #'   pages are streamed to the callback and **not** accumulated — the method
    #'   returns invisibly, so the callback owns the data (e.g. writes it to disk).
    #'   Use it to process arbitrarily large ranges without holding everything in
    #'   memory. Ignored in single-call mode (`fetch_all = FALSE`). Default `NULL`.
    #' @return (promise<data.table>) with columns:
    #'   - open_time (POSIXct) Candle open time.
    #'   - open (numeric) Opening price.
    #'   - high (numeric) Highest price during the interval.
    #'   - low (numeric) Lowest price during the interval.
    #'   - close (numeric) Closing price.
    #'   - volume (numeric) Base asset volume traded.
    #'   - close_time (POSIXct) Candle close time.
    #'   - quote_volume (numeric) Quote asset volume traded.
    #'   - trades (integer) Number of trades during the interval.
    #'   - taker_buy_base_volume (numeric) Base asset volume bought by takers.
    #'   - taker_buy_quote_volume (numeric) Quote asset volume bought by takers.
    #'   - ignore (character) Unused field from Binance API.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' klines <- futures$get_klines("BTCUSDT", "1h", limit = 24)
    #'
    #' # Fetch all candles across a large date range (multiple API calls)
    #' all_klines <- futures$get_klines(
    #'   "BTCUSDT", "1h",
    #'   startTime = as.POSIXct("2024-01-01", tz = "UTC"),
    #'   endTime = as.POSIXct("2024-06-01", tz = "UTC"),
    #'   fetch_all = TRUE, sleep = 0.5
    #' )
    #' }
    get_klines = function(
      symbol,
      interval = "1h",
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      fetch_all = FALSE,
      sleep = 0.2,
      on_page = NULL
    ) {
      assert_args_BinanceFuturesData__get_klines(symbol, interval, startTime, endTime, limit, fetch_all, sleep, on_page)
      valid_intervals <- c(
        "1s",
        "1m",
        "3m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "4h",
        "6h",
        "8h",
        "12h",
        "1d",
        "3d",
        "1w",
        "1M"
      )
      interval <- rlang::arg_match0(interval, valid_intervals)

      # fetch_all mode: segment the time range into multiple API calls
      if (isTRUE(fetch_all)) {
        if (is.null(startTime) || is.null(endTime)) {
          rlang::abort("Both `startTime` and `endTime` are required when `fetch_all = TRUE`.")
        }
        from <- startTime
        if (!inherits(startTime, "POSIXct")) {
          from <- as.POSIXct(as.numeric(startTime) / 1000, origin = "1970-01-01", tz = "UTC")
        }
        to <- endTime
        if (!inherits(endTime, "POSIXct")) {
          to <- as.POSIXct(as.numeric(endTime) / 1000, origin = "1970-01-01", tz = "UTC")
        }
        return(binance_fetch_klines(
          symbol = symbol,
          timeframe = interval,
          from = from,
          to = to,
          .req_fn = private$.request,
          is_async = private$.is_async,
          endpoint = "/fapi/v1/klines",
          max_candles = 1500L,
          sleep = sleep,
          on_page = on_page
        ))
      }

      # Single-call mode (default)
      if (inherits(startTime, "POSIXct")) {
        startTime <- format(floor(as.numeric(startTime) * 1000), scientific = FALSE)
      }
      if (inherits(endTime, "POSIXct")) {
        endTime <- format(floor(as.numeric(endTime) * 1000), scientific = FALSE)
      }

      return(private$.request(
        endpoint = "/fapi/v1/klines",
        query = list(
          symbol = symbol,
          interval = interval,
          startTime = startTime,
          endTime = endTime,
          limit = limit
        ),
        auth = FALSE,
        .parser = parse_klines
      ))
    },

    # ---- Mark Price ----

    #' @description
    #' Get Mark Price
    #'
    #' Retrieves the mark price, index price, and funding rate information
    #' for a specific symbol or all symbols.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/premiumIndex`
    #'
    #' ### Official Documentation
    #' [Binance Futures Mark Price](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Mark-Price)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/premiumIndex?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "markPrice": "67582.35000000",
    #'   "indexPrice": "67575.12345678",
    #'   "estimatedSettlePrice": "67579.88654321",
    #'   "lastFundingRate": "0.00010000",
    #'   "nextFundingTime": 1710057600000,
    #'   "interestRate": "0.00010000",
    #'   "time": 1710028800000
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>?) trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return (promise<data.table>) with columns:
    #'   - symbol (character) Trading pair identifier.
    #'   - mark_price (character) Current mark price.
    #'   - index_price (character) Current index price.
    #'   - estimated_settle_price (character) Estimated settlement price.
    #'   - last_funding_rate (character) Last funding rate.
    #'   - next_funding_time (POSIXct) Next funding time.
    #'   - interest_rate (character) Interest rate.
    #'   - time (POSIXct) Data timestamp.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' mark <- futures$get_mark_price("BTCUSDT")
    #' print(mark)
    #'
    #' # All symbols
    #' all_marks <- futures$get_mark_price()
    #' print(all_marks)
    #' }
    get_mark_price = function(symbol = NULL) {
      assert_args_BinanceFuturesData__get_mark_price(symbol)
      query <- list()
      if (!is.null(symbol)) {
        query$symbol <- symbol
      }

      return(private$.request(
        endpoint = "/fapi/v1/premiumIndex",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          if (is.null(symbol)) {
            dt <- as_dt_list(data)
          } else {
            dt <- as_dt_row(data)
          }
          coerce_cols(dt, c("next_funding_time", "time"), ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Funding Rate ----

    #' @description
    #' Get Funding Rate History
    #'
    #' Retrieves historical funding rate data for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/fundingRate`
    #'
    #' ### Official Documentation
    #' [Binance Futures Funding Rate History](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Get-Funding-Rate-History)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/fundingRate?symbol=BTCUSDT&limit=100'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "fundingRate": "0.00010000",
    #'     "fundingTime": 1710028800000,
    #'     "markPrice": "67582.35000000"
    #'   },
    #'   {
    #'     "symbol": "BTCUSDT",
    #'     "fundingRate": "0.00012500",
    #'     "fundingTime": 1710000000000,
    #'     "markPrice": "67245.10000000"
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param startTime (scalar<POSIXct> | scalar<numeric>?) start time (ms or POSIXct).
    #' @param endTime (scalar<POSIXct> | scalar<numeric>?) end time (ms or POSIXct).
    #' @param limit (scalar<count>?) max results (default 100, max 1000).
    #' @return (promise<data.table>) with columns:
    #'   - symbol (character) Trading pair identifier.
    #'   - funding_rate (character) Funding rate value.
    #'   - funding_time (POSIXct) Funding timestamp.
    #'   - mark_price (character) Mark price at funding time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' rates <- futures$get_funding_rate("BTCUSDT", limit = 10)
    #' print(rates)
    #' }
    get_funding_rate = function(symbol, startTime = NULL, endTime = NULL, limit = NULL) {
      assert_args_BinanceFuturesData__get_funding_rate(symbol, startTime, endTime, limit)
      # Convert POSIXct to milliseconds
      if (inherits(startTime, "POSIXct")) {
        startTime <- format(floor(as.numeric(startTime) * 1000), scientific = FALSE)
      }
      if (inherits(endTime, "POSIXct")) {
        endTime <- format(floor(as.numeric(endTime) * 1000), scientific = FALSE)
      }

      return(private$.request(
        endpoint = "/fapi/v1/fundingRate",
        query = list(
          symbol = symbol,
          startTime = startTime,
          endTime = endTime,
          limit = limit
        ),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "funding_time", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- 24hr Stats ----

    #' @description
    #' Get 24hr Ticker Statistics
    #'
    #' Retrieves rolling 24-hour price change statistics for a futures symbol
    #' or all symbols.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/ticker/24hr`
    #'
    #' ### Official Documentation
    #' [Binance Futures 24hr Ticker](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/24hr-Ticker-Price-Change-Statistics)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/24hr?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "priceChange": "1250.30",
    #'   "priceChangePercent": "1.882",
    #'   "weightedAvgPrice": "67123.45",
    #'   "lastPrice": "67632.40",
    #'   "lastQty": "0.012",
    #'   "openPrice": "66382.10",
    #'   "highPrice": "67845.90",
    #'   "lowPrice": "65980.00",
    #'   "volume": "285431.234",
    #'   "quoteVolume": "19187654321.56",
    #'   "openTime": 1709942400000,
    #'   "closeTime": 1710028799999,
    #'   "firstId": 4123456789,
    #'   "lastId": 4123987654,
    #'   "count": 530865
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>?) trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return (promise<data.table>) with columns:
    #'   - symbol (character) Trading pair identifier.
    #'   - price_change (character) Absolute price change over 24h.
    #'   - price_change_percent (character) Percentage price change over 24h.
    #'   - weighted_avg_price (character) Volume-weighted average price over 24h.
    #'   - last_price (character) Most recent trade price.
    #'   - volume (character) Total base asset volume in 24h.
    #'   - quote_volume (character) Total quote asset volume in 24h.
    #'   - open_time (POSIXct) Start of the 24h window.
    #'   - close_time (POSIXct) End of the 24h window.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' stats <- futures$get_24hr_stats("BTCUSDT")
    #' print(stats[, .(symbol, last_price, price_change_percent, volume)])
    #' }
    get_24hr_stats = function(symbol = NULL) {
      assert_args_BinanceFuturesData__get_24hr_stats(symbol)
      query <- list()
      if (!is.null(symbol)) {
        query$symbol <- symbol
      }

      return(private$.request(
        endpoint = "/fapi/v1/ticker/24hr",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          if (!is.null(symbol)) {
            dt <- as_dt_row(data)
          } else {
            dt <- as_dt_list(data)
          }
          coerce_cols(dt, c("open_time", "close_time"), ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Ticker ----

    #' @description
    #' Get Symbol Price Ticker
    #'
    #' Retrieves the latest price for a specific futures symbol or all symbols.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/ticker/price`
    #'
    #' ### Official Documentation
    #' [Binance Futures Symbol Price Ticker](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Symbol-Price-Ticker)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/price?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "price": "67632.40",
    #'   "time": 1710028800000
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>?) trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return (promise<data.table>) with columns:
    #'   - symbol (character) Trading pair identifier.
    #'   - price (character) Latest traded price as string.
    #'   - time (POSIXct) Timestamp (if present in response).
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' ticker <- futures$get_ticker("BTCUSDT")
    #' print(ticker)
    #' }
    get_ticker = function(symbol = NULL) {
      assert_args_BinanceFuturesData__get_ticker(symbol)
      query <- list()
      if (!is.null(symbol)) {
        query$symbol <- symbol
      }

      return(private$.request(
        endpoint = "/fapi/v1/ticker/price",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          if (!is.null(symbol)) {
            dt <- as_dt_row(data)
          } else {
            dt <- as_dt_list(data)
          }
          coerce_cols(dt, "time", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Book Ticker ----

    #' @description
    #' Get Best Bid/Ask (Book Ticker)
    #'
    #' Retrieves the best bid and ask price and quantity for a futures symbol
    #' or all symbols.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/ticker/bookTicker`
    #'
    #' ### Official Documentation
    #' [Binance Futures Symbol Order Book Ticker](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Symbol-Order-Book-Ticker)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/bookTicker?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "bidPrice": "67630.20",
    #'   "bidQty": "5.432",
    #'   "askPrice": "67632.40",
    #'   "askQty": "3.218",
    #'   "time": 1710028800000
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>?) trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return (promise<data.table>) with columns:
    #'   - symbol (character) Trading pair identifier.
    #'   - bid_price (character) Best bid price.
    #'   - bid_qty (character) Quantity available at best bid.
    #'   - ask_price (character) Best ask price.
    #'   - ask_qty (character) Quantity available at best ask.
    #'   - time (POSIXct) Timestamp (if present in response).
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' book <- futures$get_book_ticker("BTCUSDT")
    #' print(book)
    #' }
    get_book_ticker = function(symbol = NULL) {
      assert_args_BinanceFuturesData__get_book_ticker(symbol)
      query <- list()
      if (!is.null(symbol)) {
        query$symbol <- symbol
      }

      return(private$.request(
        endpoint = "/fapi/v1/ticker/bookTicker",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          if (!is.null(symbol)) {
            dt <- as_dt_row(data)
          } else {
            dt <- as_dt_list(data)
          }
          coerce_cols(dt, "time", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Open Interest ----

    #' @description
    #' Get Open Interest
    #'
    #' Retrieves the current open interest for a futures symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/openInterest`
    #'
    #' ### Official Documentation
    #' [Binance Futures Open Interest](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Open-Interest)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/openInterest?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "openInterest": "72381.532",
    #'   "time": 1710028800000
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @return (promise<data.table>) with columns:
    #'   - symbol (character) Trading pair identifier.
    #'   - open_interest (character) Current open interest.
    #'   - time (POSIXct) Timestamp (if present in response).
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' oi <- futures$get_open_interest("BTCUSDT")
    #' print(oi)
    #' }
    get_open_interest = function(symbol) {
      assert_args_BinanceFuturesData__get_open_interest(symbol)
      return(private$.request(
        endpoint = "/fapi/v1/openInterest",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "time", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Order Book ----

    #' @description
    #' Get Order Book Depth
    #'
    #' Retrieves the order book (bids and asks) for a futures symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/depth`
    #'
    #' ### Official Documentation
    #' [Binance Futures Order Book](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Order-Book)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/depth?symbol=BTCUSDT&limit=20'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "lastUpdateId": 2731879654321,
    #'   "E": 1710028800000,
    #'   "T": 1710028800000,
    #'   "bids": [
    #'     ["67630.20", "5.432"],
    #'     ["67629.90", "2.100"],
    #'     ["67629.50", "8.750"]
    #'   ],
    #'   "asks": [
    #'     ["67632.40", "3.218"],
    #'     ["67632.80", "1.500"],
    #'     ["67633.10", "6.340"]
    #'   ]
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param limit (scalar<count>?) depth limit. Valid values: 5, 10, 20, 50,
    #'   100, 500, 1000. Default 500.
    #' @return (promise<data.table>) with columns:
    #'   - last_update_id (character) Sequence ID for orderbook synchronisation.
    #'   - side (character) `"bid"` or `"ask"`.
    #'   - price (numeric) Price level.
    #'   - size (numeric) Available size at this price level.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' depth <- futures$get_depth("BTCUSDT", limit = 20)
    #' print(depth)
    #' }
    get_depth = function(symbol, limit = NULL) {
      assert_args_BinanceFuturesData__get_depth(symbol, limit)
      return(private$.request(
        endpoint = "/fapi/v1/depth",
        query = list(symbol = symbol, limit = limit),
        auth = FALSE,
        .parser = parse_orderbook
      ))
    },

    # ---- Recent Trades ----

    #' @description
    #' Get Recent Trades
    #'
    #' Retrieves the most recent trades for a futures symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/trades`
    #'
    #' ### Official Documentation
    #' [Binance Futures Recent Trades List](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Recent-Trades-List)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/trades?symbol=BTCUSDT&limit=10'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": 3456789012,
    #'     "price": "67632.40",
    #'     "qty": "0.015",
    #'     "quoteQty": "1014.49",
    #'     "time": 1710028800123,
    #'     "isBuyerMaker": false
    #'   },
    #'   {
    #'     "id": 3456789013,
    #'     "price": "67630.20",
    #'     "qty": "0.200",
    #'     "quoteQty": "13526.04",
    #'     "time": 1710028800456,
    #'     "isBuyerMaker": true
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param limit (scalar<count>?) max results (default 500, max 1000).
    #' @return (promise<data.table>) with columns:
    #'   - id (integer) Unique trade identifier.
    #'   - price (character) Trade execution price.
    #'   - qty (character) Base asset quantity traded.
    #'   - quote_qty (character) Quote asset quantity traded.
    #'   - time (POSIXct) Trade execution time.
    #'   - is_buyer_maker (logical) `TRUE` if the buyer was the maker.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' trades <- futures$get_trades("BTCUSDT", limit = 10)
    #' print(trades)
    #' }
    get_trades = function(symbol, limit = NULL) {
      assert_args_BinanceFuturesData__get_trades(symbol, limit)
      return(private$.request(
        endpoint = "/fapi/v1/trades",
        query = list(symbol = symbol, limit = limit),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "time", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- Index Price Klines ----

    #' @description
    #' Get Index Price Klines
    #'
    #' Retrieves historical index price kline/candlestick data for a pair.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/indexPriceKlines`
    #'
    #' ### Official Documentation
    #' [Binance Futures Index Price Kline/Candlestick Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Index-Price-Kline-Candlestick-Data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/indexPriceKlines?pair=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   [
    #'     1710028800000,
    #'     "67518.42",
    #'     "67840.15",
    #'     "67305.78",
    #'     "67625.33",
    #'     "0",
    #'     1710032399999,
    #'     "0",
    #'     0,
    #'     "0",
    #'     "0",
    #'     "0"
    #'   ]
    #' ]
    #' ```
    #'
    #' @param pair (scalar<character>) underlying pair (e.g., `"BTCUSDT"`).
    #' @param interval (scalar<character>) candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime (scalar<POSIXct> | scalar<numeric>?) start time (ms or POSIXct).
    #' @param endTime (scalar<POSIXct> | scalar<numeric>?) end time (ms or POSIXct).
    #' @param limit (scalar<count>?) max results (default 500, max 1500).
    #' @return (promise<data.table>) with columns:
    #' - open_time (POSIXct) Candle open time.
    #' - open (numeric) Opening price.
    #' - high (numeric) Highest price.
    #' - low (numeric) Lowest price.
    #' - close (numeric) Closing price.
    #' - volume (numeric) Trading volume.
    #' - close_time (POSIXct) Candle close time.
    #' - quote_volume (numeric) Quote asset volume.
    #' - trades (integer) Number of trades.
    #' - taker_buy_base_volume (numeric) Taker buy base asset volume.
    #' - taker_buy_quote_volume (numeric) Taker buy quote asset volume.
    #' - ignore (character) Unused field.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' klines <- futures$get_index_price_klines("BTCUSDT", "1h", limit = 24)
    #' print(klines)
    #' }
    get_index_price_klines = function(
      pair,
      interval = "1h",
      startTime = NULL,
      endTime = NULL,
      limit = NULL
    ) {
      assert_args_BinanceFuturesData__get_index_price_klines(pair, interval, startTime, endTime, limit)
      valid_intervals <- c(
        "1s",
        "1m",
        "3m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "4h",
        "6h",
        "8h",
        "12h",
        "1d",
        "3d",
        "1w",
        "1M"
      )
      interval <- rlang::arg_match0(interval, valid_intervals)

      # Convert POSIXct to milliseconds
      if (inherits(startTime, "POSIXct")) {
        startTime <- format(floor(as.numeric(startTime) * 1000), scientific = FALSE)
      }
      if (inherits(endTime, "POSIXct")) {
        endTime <- format(floor(as.numeric(endTime) * 1000), scientific = FALSE)
      }

      return(private$.request(
        endpoint = "/fapi/v1/indexPriceKlines",
        query = list(
          pair = pair,
          interval = interval,
          startTime = startTime,
          endTime = endTime,
          limit = limit
        ),
        auth = FALSE,
        .parser = parse_klines
      ))
    },

    # ---- Mark Price Klines ----

    #' @description
    #' Get Mark Price Klines
    #'
    #' Retrieves historical mark price kline/candlestick data for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://fapi.binance.com/fapi/v1/markPriceKlines`
    #'
    #' ### Official Documentation
    #' [Binance Futures Mark Price Kline/Candlestick Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Mark-Price-Kline-Candlestick-Data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/markPriceKlines?symbol=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   [
    #'     1710028800000,
    #'     "67525.10",
    #'     "67848.75",
    #'     "67312.40",
    #'     "67635.20",
    #'     "0",
    #'     1710032399999,
    #'     "0",
    #'     0,
    #'     "0",
    #'     "0",
    #'     "0"
    #'   ]
    #' ]
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param interval (scalar<character>) candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime (scalar<POSIXct> | scalar<numeric>?) start time (ms or POSIXct).
    #' @param endTime (scalar<POSIXct> | scalar<numeric>?) end time (ms or POSIXct).
    #' @param limit (scalar<count>?) max results (default 500, max 1500).
    #' @return (promise<data.table>) with columns:
    #' - open_time (POSIXct) Candle open time.
    #' - open (numeric) Opening price.
    #' - high (numeric) Highest price.
    #' - low (numeric) Lowest price.
    #' - close (numeric) Closing price.
    #' - volume (numeric) Trading volume.
    #' - close_time (POSIXct) Candle close time.
    #' - quote_volume (numeric) Quote asset volume.
    #' - trades (integer) Number of trades.
    #' - taker_buy_base_volume (numeric) Taker buy base asset volume.
    #' - taker_buy_quote_volume (numeric) Taker buy quote asset volume.
    #' - ignore (character) Unused field.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' klines <- futures$get_mark_price_klines("BTCUSDT", "1h", limit = 24)
    #' print(klines)
    #' }
    get_mark_price_klines = function(
      symbol,
      interval = "1h",
      startTime = NULL,
      endTime = NULL,
      limit = NULL
    ) {
      assert_args_BinanceFuturesData__get_mark_price_klines(symbol, interval, startTime, endTime, limit)
      valid_intervals <- c(
        "1s",
        "1m",
        "3m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "4h",
        "6h",
        "8h",
        "12h",
        "1d",
        "3d",
        "1w",
        "1M"
      )
      interval <- rlang::arg_match0(interval, valid_intervals)

      # Convert POSIXct to milliseconds
      if (inherits(startTime, "POSIXct")) {
        startTime <- format(floor(as.numeric(startTime) * 1000), scientific = FALSE)
      }
      if (inherits(endTime, "POSIXct")) {
        endTime <- format(floor(as.numeric(endTime) * 1000), scientific = FALSE)
      }

      return(private$.request(
        endpoint = "/fapi/v1/markPriceKlines",
        query = list(
          symbol = symbol,
          interval = interval,
          startTime = startTime,
          endTime = endTime,
          limit = limit
        ),
        auth = FALSE,
        .parser = parse_klines
      ))
    }
  )
)
