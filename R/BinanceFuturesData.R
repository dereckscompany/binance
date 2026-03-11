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
#' [Binance USD-M Futures Market Data](https://binance-docs.github.io/apidocs/futures/en/#market-data-endpoints)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Auth |
#' |--------|----------|------|
#' | get_exchange_info | GET /fapi/v1/exchangeInfo | No |
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
    #' @param keys List; API credentials from [get_api_keys()].
    #'   Defaults to `get_api_keys()`.
    #' @param base_url Character; API base URL. Defaults to `get_futures_base_url()`.
    #' @param async Logical; if `TRUE`, methods return promises. Default `FALSE`.
    #' @param time_source Character; clock source for HMAC request signing.
    #'   `"local"` (default) uses `Sys.time()`. `"server"` fetches the Binance
    #'   Futures server time before each authenticated request.
    #' @return Invisible self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      super$initialize(keys = keys, base_url = base_url, async = async, time_source = time_source)

      if (match.arg(time_source) == "server") {
        url <- base_url
        private$.get_timestamp_ms <- function() fetch_server_time_ms(url, "/fapi/v1/time")
      }

      return(invisible(self))
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
    #' [Binance Futures Exchange Info](https://binance-docs.github.io/apidocs/futures/en/#exchange-information)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/exchangeInfo'
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with all symbol
    #'   fields returned by the API, converted to snake_case. Key columns include:
    #'   - `symbol` (character): Trading pair identifier (e.g., `"BTCUSDT"`).
    #'   - `pair` (character): Underlying pair.
    #'   - `contract_type` (character): Contract type (e.g., `"PERPETUAL"`).
    #'   - `status` (character): Trading status (`"TRADING"`, etc.).
    #'   - `base_asset` (character): Base asset code (e.g., `"BTC"`).
    #'   - `quote_asset` (character): Quote asset code (e.g., `"USDT"`).
    #'   - `margin_asset` (character): Margin asset code (e.g., `"USDT"`).
    #'   - `price_precision` (integer): Decimal precision for prices.
    #'   - `quantity_precision` (integer): Decimal precision for quantities.
    #'   - `order_types` (list): Allowed order types for this symbol.
    #'   - `filters` (list): List of filter objects.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' info <- futures$get_exchange_info()
    #' print(info[, .(symbol, contract_type, status, base_asset)])
    #' }
    get_exchange_info = function() {
      return(private$.request(
        endpoint = "/fapi/v1/exchangeInfo",
        auth = FALSE,
        .parser = function(data) {
          syms <- data$symbols
          if (is.null(syms) || length(syms) == 0) {
            return(data.table::data.table())
          }
          dt <- data.table::rbindlist(
            lapply(syms, as_dt_row),
            fill = TRUE
          )
          return(dt)
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
    #' [Binance Futures Kline/Candlestick Data](https://binance-docs.github.io/apidocs/futures/en/#kline-candlestick-data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/klines?symbol=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param interval Character; candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime POSIXct or numeric or NULL; start time (ms or POSIXct).
    #' @param endTime POSIXct or numeric or NULL; end time (ms or POSIXct).
    #' @param limit Integer or NULL; max results (default 500, max 1500).
    #' @param fetch_all Logical; if `TRUE`, automatically segments the time range
    #'   into multiple API calls of up to 1500 candles each, fetches all segments,
    #'   deduplicates overlapping boundaries, and returns the combined result sorted
    #'   by `open_time`. Both `startTime` and `endTime` are required when enabled.
    #'   **Warning**: large date ranges will consume multiple API requests and may
    #'   impact your rate-limit quota. Default `FALSE`.
    #' @param sleep Numeric; seconds to wait between consecutive API calls when
    #'   `fetch_all = TRUE`. Use this to avoid hitting Binance rate limits. Only
    #'   applies in synchronous mode; async mode chains requests sequentially via
    #'   promises. Default `0.2`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `open_time` (POSIXct): Candle open time.
    #'   - `open` (numeric): Opening price.
    #'   - `high` (numeric): Highest price during the interval.
    #'   - `low` (numeric): Lowest price during the interval.
    #'   - `close` (numeric): Closing price.
    #'   - `volume` (numeric): Base asset volume traded.
    #'   - `close_time` (POSIXct): Candle close time.
    #'   - `quote_volume` (numeric): Quote asset volume traded.
    #'   - `trades` (integer): Number of trades during the interval.
    #'   - `taker_buy_base_volume` (numeric): Base asset volume bought by takers.
    #'   - `taker_buy_quote_volume` (numeric): Quote asset volume bought by takers.
    #'   - `ignore` (character): Unused field from Binance API.
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
      sleep = 0.2
    ) {
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
        from <- if (inherits(startTime, "POSIXct")) {
          startTime
        } else {
          as.POSIXct(as.numeric(startTime) / 1000, origin = "1970-01-01", tz = "UTC")
        }
        to <- if (inherits(endTime, "POSIXct")) {
          endTime
        } else {
          as.POSIXct(as.numeric(endTime) / 1000, origin = "1970-01-01", tz = "UTC")
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
          sleep = sleep
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
    #' [Binance Futures Mark Price](https://binance-docs.github.io/apidocs/futures/en/#mark-price)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/premiumIndex?symbol=BTCUSDT'
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `mark_price` (character): Current mark price.
    #'   - `index_price` (character): Current index price.
    #'   - `estimated_settle_price` (character): Estimated settlement price.
    #'   - `last_funding_rate` (character): Last funding rate.
    #'   - `next_funding_time` (POSIXct): Next funding time.
    #'   - `interest_rate` (character): Interest rate.
    #'   - `time` (POSIXct): Data timestamp.
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
          if (nrow(dt) > 0) {
            for (col in c("next_funding_time", "time")) {
              if (col %in% names(dt)) {
                dt[, (col) := ms_to_datetime(get(col))]
              }
            }
          }
          return(dt)
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
    #' [Binance Futures Funding Rate History](https://binance-docs.github.io/apidocs/futures/en/#get-funding-rate-history)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/fundingRate?symbol=BTCUSDT&limit=100'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param startTime POSIXct or numeric or NULL; start time (ms or POSIXct).
    #' @param endTime POSIXct or numeric or NULL; end time (ms or POSIXct).
    #' @param limit Integer or NULL; max results (default 100, max 1000).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `funding_rate` (character): Funding rate value.
    #'   - `funding_time` (POSIXct): Funding timestamp.
    #'   - `mark_price` (character): Mark price at funding time.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' rates <- futures$get_funding_rate("BTCUSDT", limit = 10)
    #' print(rates)
    #' }
    get_funding_rate = function(symbol, startTime = NULL, endTime = NULL, limit = NULL) {
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
            return(data.table::data.table())
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "funding_time" %in% names(dt)) {
            dt[, funding_time := ms_to_datetime(funding_time)]
          }
          return(dt)
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
    #' [Binance Futures 24hr Ticker](https://binance-docs.github.io/apidocs/futures/en/#24hr-ticker-price-change-statistics)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/24hr?symbol=BTCUSDT'
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `price_change` (character): Absolute price change over 24h.
    #'   - `price_change_percent` (character): Percentage price change over 24h.
    #'   - `weighted_avg_price` (character): Volume-weighted average price over 24h.
    #'   - `last_price` (character): Most recent trade price.
    #'   - `volume` (character): Total base asset volume in 24h.
    #'   - `quote_volume` (character): Total quote asset volume in 24h.
    #'   - `open_time` (POSIXct): Start of the 24h window.
    #'   - `close_time` (POSIXct): End of the 24h window.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' stats <- futures$get_24hr_stats("BTCUSDT")
    #' print(stats[, .(symbol, last_price, price_change_percent, volume)])
    #' }
    get_24hr_stats = function(symbol = NULL) {
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
          if (nrow(dt) > 0) {
            for (col in c("open_time", "close_time")) {
              if (col %in% names(dt)) {
                dt[, (col) := ms_to_datetime(get(col))]
              }
            }
          }
          return(dt)
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
    #' [Binance Futures Symbol Price Ticker](https://binance-docs.github.io/apidocs/futures/en/#symbol-price-ticker)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/price?symbol=BTCUSDT'
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `price` (character): Latest traded price as string.
    #'   - `time` (POSIXct): Timestamp (if present in response).
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' ticker <- futures$get_ticker("BTCUSDT")
    #' print(ticker)
    #' }
    get_ticker = function(symbol = NULL) {
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
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          return(dt)
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
    #' [Binance Futures Symbol Order Book Ticker](https://binance-docs.github.io/apidocs/futures/en/#symbol-order-book-ticker)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/bookTicker?symbol=BTCUSDT'
    #' ```
    #'
    #' @param symbol Character or NULL; trading pair (e.g., `"BTCUSDT"`).
    #'   If NULL, returns data for all symbols.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `bid_price` (character): Best bid price.
    #'   - `bid_qty` (character): Quantity available at best bid.
    #'   - `ask_price` (character): Best ask price.
    #'   - `ask_qty` (character): Quantity available at best ask.
    #'   - `time` (POSIXct): Timestamp (if present in response).
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' book <- futures$get_book_ticker("BTCUSDT")
    #' print(book)
    #' }
    get_book_ticker = function(symbol = NULL) {
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
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          return(dt)
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
    #' [Binance Futures Open Interest](https://binance-docs.github.io/apidocs/futures/en/#open-interest)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/openInterest?symbol=BTCUSDT'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `open_interest` (character): Current open interest.
    #'   - `time` (POSIXct): Timestamp (if present in response).
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' oi <- futures$get_open_interest("BTCUSDT")
    #' print(oi)
    #' }
    get_open_interest = function(symbol) {
      return(private$.request(
        endpoint = "/fapi/v1/openInterest",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          return(dt)
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
    #' [Binance Futures Order Book](https://binance-docs.github.io/apidocs/futures/en/#order-book)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/depth?symbol=BTCUSDT&limit=20'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param limit Integer or NULL; depth limit. Valid values: 5, 10, 20, 50,
    #'   100, 500, 1000. Default 500.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `last_update_id` (character): Sequence ID for orderbook synchronisation.
    #'   - `side` (character): `"bid"` or `"ask"`.
    #'   - `price` (numeric): Price level.
    #'   - `size` (numeric): Available size at this price level.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' depth <- futures$get_depth("BTCUSDT", limit = 20)
    #' print(depth)
    #' }
    get_depth = function(symbol, limit = NULL) {
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
    #' [Binance Futures Recent Trades List](https://binance-docs.github.io/apidocs/futures/en/#recent-trades-list)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/trades?symbol=BTCUSDT&limit=10'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param limit Integer or NULL; max results (default 500, max 1000).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (integer): Unique trade identifier.
    #'   - `price` (character): Trade execution price.
    #'   - `qty` (character): Base asset quantity traded.
    #'   - `quote_qty` (character): Quote asset quantity traded.
    #'   - `time` (POSIXct): Trade execution time.
    #'   - `is_buyer_maker` (logical): `TRUE` if the buyer was the maker.
    #'
    #' @examples
    #' \dontrun{
    #' futures <- BinanceFuturesData$new()
    #' trades <- futures$get_trades("BTCUSDT", limit = 10)
    #' print(trades)
    #' }
    get_trades = function(symbol, limit = NULL) {
      return(private$.request(
        endpoint = "/fapi/v1/trades",
        query = list(symbol = symbol, limit = limit),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table())
          }
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
          }
          return(dt)
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
    #' [Binance Futures Index Price Kline/Candlestick Data](https://binance-docs.github.io/apidocs/futures/en/#index-price-kline-candlestick-data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/indexPriceKlines?pair=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' @param pair Character; underlying pair (e.g., `"BTCUSDT"`).
    #' @param interval Character; candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime POSIXct or numeric or NULL; start time (ms or POSIXct).
    #' @param endTime POSIXct or numeric or NULL; end time (ms or POSIXct).
    #' @param limit Integer or NULL; max results (default 500, max 1500).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `open_time` (POSIXct): Candle open time.
    #' - `open` (numeric): Opening price.
    #' - `high` (numeric): Highest price.
    #' - `low` (numeric): Lowest price.
    #' - `close` (numeric): Closing price.
    #' - `volume` (numeric): Trading volume.
    #' - `close_time` (POSIXct): Candle close time.
    #' - `quote_volume` (numeric): Quote asset volume.
    #' - `trades` (integer): Number of trades.
    #' - `taker_buy_base_volume` (numeric): Taker buy base asset volume.
    #' - `taker_buy_quote_volume` (numeric): Taker buy quote asset volume.
    #' - `ignore` (character): Unused field.
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
    #' [Binance Futures Mark Price Kline/Candlestick Data](https://binance-docs.github.io/apidocs/futures/en/#mark-price-kline-candlestick-data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://fapi.binance.com/fapi/v1/markPriceKlines?symbol=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param interval Character; candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime POSIXct or numeric or NULL; start time (ms or POSIXct).
    #' @param endTime POSIXct or numeric or NULL; end time (ms or POSIXct).
    #' @param limit Integer or NULL; max results (default 500, max 1500).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #' - `open_time` (POSIXct): Candle open time.
    #' - `open` (numeric): Opening price.
    #' - `high` (numeric): Highest price.
    #' - `low` (numeric): Lowest price.
    #' - `close` (numeric): Closing price.
    #' - `volume` (numeric): Trading volume.
    #' - `close_time` (POSIXct): Candle close time.
    #' - `quote_volume` (numeric): Quote asset volume.
    #' - `trades` (integer): Number of trades.
    #' - `taker_buy_base_volume` (numeric): Taker buy base asset volume.
    #' - `taker_buy_quote_volume` (numeric): Taker buy quote asset volume.
    #' - `ignore` (character): Unused field.
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
