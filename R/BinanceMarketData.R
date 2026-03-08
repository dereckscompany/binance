# File: R/BinanceMarketData.R
# R6 class for Binance Spot market data retrieval.

#' BinanceMarketData: Spot Market Data Retrieval
#'
#' Provides methods for retrieving market data from Binance's Spot trading API,
#' including exchange info, klines, tickers, orderbooks, trade history, and
#' 24-hour statistics.
#'
#' Inherits from [BinanceBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Exchange Info**: Retrieve trading pair metadata including precision, filters, and trading status.
#' - **Tickers**: Access real-time price data for individual symbols or all pairs.
#' - **Order Books**: Get order book depth snapshots.
#' - **Trade History**: Retrieve recent trades for any symbol.
#' - **24hr Statistics**: Get rolling 24-hour market statistics.
#' - **Klines**: Fetch historical candlestick data.
#' - **Server Time**: Get exchange server time for clock synchronisation.
#'
#' ### Usage
#' All methods are public endpoints requiring no authentication.
#'
#' ### Official Documentation
#' [Binance Spot Market Data](https://binance-docs.github.io/apidocs/spot/en/#market-data-endpoints)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Auth |
#' |--------|----------|------|
#' | get_server_time | GET /api/v3/time | No |
#' | get_exchange_info | GET /api/v3/exchangeInfo | No |
#' | get_ticker | GET /api/v3/ticker/price | No |
#' | get_all_tickers | GET /api/v3/ticker/price | No |
#' | get_book_ticker | GET /api/v3/ticker/bookTicker | No |
#' | get_24hr_stats | GET /api/v3/ticker/24hr | No |
#' | get_avg_price | GET /api/v3/avgPrice | No |
#' | get_depth | GET /api/v3/depth | No |
#' | get_trades | GET /api/v3/trades | No |
#' | get_klines | GET /api/v3/klines | No |
#'
#' @examples
#' \dontrun{
#' # Synchronous usage
#' market <- BinanceMarketData$new()
#' ticker <- market$get_ticker("BTCUSDT")
#' print(ticker)
#'
#' # Asynchronous usage
#' market_async <- BinanceMarketData$new(async = TRUE)
#' main <- coro::async(function() {
#'   ticker <- await(market_async$get_ticker("BTCUSDT"))
#'   print(ticker)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom lubridate as_datetime now dhours
#' @export
BinanceMarketData <- R6::R6Class(
  "BinanceMarketData",
  inherit = BinanceBase,
  public = list(
    # ---- Server Time ----

    #' @description
    #' Get Server Time
    #'
    #' Retrieves the current server timestamp from Binance in milliseconds.
    #' Useful for detecting clock drift and ensuring HMAC signatures are valid.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/time`
    #'
    #' ### Official Documentation
    #' [Binance Check Server Time](https://binance-docs.github.io/apidocs/spot/en/#check-server-time)
    #'
    #' ### Automated Trading Usage
    #' - **Clock Drift Detection**: Compare server time against local clock to detect drift.
    #' - **Auth Debugging**: Binance tolerates `recvWindow` (default 5s); verify timestamps are in range.
    #' - **Heartbeat**: Lightweight endpoint (weight 1) suitable for connectivity health checks.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/time'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' { "serverTime": 1499827319559 }
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `server_time` (numeric): Server epoch timestamp in milliseconds.
    #'   - `datetime` (POSIXct): Server time converted to UTC datetime.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' st <- market$get_server_time()
    #' drift <- as.numeric(Sys.time()) * 1000 - st$server_time
    #' cat("Clock drift:", round(drift), "ms\n")
    #' }
    get_server_time = function() {
      return(private$.request(
        endpoint = "/api/v3/time",
        auth = FALSE,
        .parser = function(data) {
          ts <- as.numeric(data$serverTime)
          return(data.table::data.table(
            server_time = ts,
            datetime = ms_to_datetime(ts)
          ))
        }
      ))
    },

    # ---- Exchange Info ----

    #' @description
    #' Get Exchange Info
    #'
    #' Retrieves exchange trading rules and symbol information. Includes
    #' precision, order types, filters, and trading status for each symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/exchangeInfo`
    #'
    #' ### Official Documentation
    #' [Binance Exchange Info](https://binance-docs.github.io/apidocs/spot/en/#exchange-information)
    #'
    #' ### Automated Trading Usage
    #' - **Symbol Discovery**: Find available trading pairs and their status.
    #' - **Precision Lookup**: Get `base_asset_precision` and `quote_asset_precision` for order formatting.
    #' - **Filter Validation**: Check LOT_SIZE, PRICE_FILTER, MIN_NOTIONAL before placing orders.
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/exchangeInfo?symbol=BTCUSDT'
    #' ```
    #'
    #' @param symbol Character or NULL; specific symbol (e.g., `"BTCUSDT"`).
    #' @param symbols Character vector or NULL; multiple symbols.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier (e.g., `"BTCUSDT"`).
    #'   - `status` (character): Trading status (`"TRADING"`, `"HALT"`, `"BREAK"`).
    #'   - `base_asset` (character): Base asset code (e.g., `"BTC"`).
    #'   - `base_asset_precision` (integer): Decimal precision for base asset quantities.
    #'   - `quote_asset` (character): Quote asset code (e.g., `"USDT"`).
    #'   - `quote_asset_precision` (integer): Decimal precision for quote asset quantities.
    #'   - `quote_precision` (integer): Decimal precision for quote asset prices.
    #'   - `is_spot_trading_allowed` (logical): Whether spot trading is enabled.
    #'   - `is_margin_trading_allowed` (logical): Whether margin trading is enabled.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' info <- market$get_exchange_info("BTCUSDT")
    #' print(info[, .(symbol, status, base_asset, quote_asset)])
    #' }
    get_exchange_info = function(symbol = NULL, symbols = NULL) {
      query <- list()
      if (!is.null(symbol)) {
        query$symbol <- symbol
      } else if (!is.null(symbols)) {
        query$symbols <- jsonlite::toJSON(symbols, auto_unbox = FALSE)
      }

      return(private$.request(
        endpoint = "/api/v3/exchangeInfo",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          syms <- data$symbols
          if (is.null(syms) || length(syms) == 0) {
            return(data.table::data.table())
          }
          dt <- data.table::rbindlist(
            lapply(syms, function(s) {
              data.table::data.table(
                symbol = s$symbol %||% NA_character_,
                status = s$status %||% NA_character_,
                base_asset = s$baseAsset %||% NA_character_,
                base_asset_precision = s$baseAssetPrecision %||% NA_integer_,
                quote_asset = s$quoteAsset %||% NA_character_,
                quote_asset_precision = s$quoteAssetPrecision %||% NA_integer_,
                quote_precision = s$quotePrecision %||% NA_integer_,
                is_spot_trading_allowed = s$isSpotTradingAllowed %||% NA,
                is_margin_trading_allowed = s$isMarginTradingAllowed %||% NA
              )
            }),
            fill = TRUE
          )
          return(dt)
        }
      ))
    },

    # ---- Tickers ----

    #' @description
    #' Get Symbol Price Ticker
    #'
    #' Retrieves the latest price for a specific symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/ticker/price`
    #'
    #' ### Official Documentation
    #' [Binance Symbol Price Ticker](https://binance-docs.github.io/apidocs/spot/en/#symbol-price-ticker)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' { "symbol": "BTCUSDT", "price": "67232.90000000" }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `price` (character): Latest traded price as string.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' ticker <- market$get_ticker("BTCUSDT")
    #' print(ticker)
    #' }
    get_ticker = function(symbol) {
      return(private$.request(
        endpoint = "/api/v3/ticker/price",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get All Symbol Price Tickers
    #'
    #' Retrieves the latest price for all trading pairs in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/ticker/price`
    #'
    #' ### Official Documentation
    #' [Binance Symbol Price Ticker](https://binance-docs.github.io/apidocs/spot/en/#symbol-price-ticker)
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `price` (character): Latest traded price as string.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' all_tickers <- market$get_all_tickers()
    #' print(all_tickers[1:5])
    #' }
    get_all_tickers = function() {
      return(private$.request(
        endpoint = "/api/v3/ticker/price",
        auth = FALSE,
        .parser = as_dt_list
      ))
    },

    #' @description
    #' Get Best Bid/Ask (Book Ticker)
    #'
    #' Retrieves the best bid and ask price and quantity for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/ticker/bookTicker`
    #'
    #' ### Official Documentation
    #' [Binance Symbol Order Book Ticker](https://binance-docs.github.io/apidocs/spot/en/#symbol-order-book-ticker)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/ticker/bookTicker?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "bidPrice": "67232.00000000",
    #'   "bidQty": "0.41861839",
    #'   "askPrice": "67232.90000000",
    #'   "askQty": "1.24808993"
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `bid_price` (character): Best bid price.
    #'   - `bid_qty` (character): Quantity available at best bid.
    #'   - `ask_price` (character): Best ask price.
    #'   - `ask_qty` (character): Quantity available at best ask.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' book <- market$get_book_ticker("BTCUSDT")
    #' print(book)
    #' }
    get_book_ticker = function(symbol) {
      return(private$.request(
        endpoint = "/api/v3/ticker/bookTicker",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = as_dt_row
      ))
    },

    # ---- 24hr Stats ----

    #' @description
    #' Get 24hr Ticker Statistics
    #'
    #' Retrieves rolling 24-hour price change statistics for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/ticker/24hr`
    #'
    #' ### Official Documentation
    #' [Binance 24hr Ticker Price Change Statistics](https://binance-docs.github.io/apidocs/spot/en/#24hr-ticker-price-change-statistics)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair identifier.
    #'   - `price_change` (character): Absolute price change over 24h.
    #'   - `price_change_percent` (character): Percentage price change over 24h.
    #'   - `weighted_avg_price` (character): Volume-weighted average price over 24h.
    #'   - `prev_close_price` (character): Previous day's closing price.
    #'   - `last_price` (character): Most recent trade price.
    #'   - `last_qty` (character): Most recent trade quantity.
    #'   - `bid_price` (character): Current best bid price.
    #'   - `bid_qty` (character): Current best bid quantity.
    #'   - `ask_price` (character): Current best ask price.
    #'   - `ask_qty` (character): Current best ask quantity.
    #'   - `open_price` (character): Price at 24h window open.
    #'   - `high_price` (character): Highest price in 24h.
    #'   - `low_price` (character): Lowest price in 24h.
    #'   - `volume` (character): Total base asset volume in 24h.
    #'   - `quote_volume` (character): Total quote asset volume in 24h.
    #'   - `datetime_open` (POSIXct): Start of the 24h window.
    #'   - `datetime_close` (POSIXct): End of the 24h window.
    #'   - `first_id` (integer): First trade ID in the window.
    #'   - `last_id` (integer): Last trade ID in the window.
    #'   - `count` (integer): Total number of trades in 24h.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' stats <- market$get_24hr_stats("BTCUSDT")
    #' print(stats[, .(symbol, last_price, price_change_percent, volume)])
    #' }
    get_24hr_stats = function(symbol) {
      return(private$.request(
        endpoint = "/api/v3/ticker/24hr",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0) {
            for (col in c("open_time", "close_time")) {
              if (col %in% names(dt)) {
                dt[, paste0("datetime_", sub("_time$", "", col)) := ms_to_datetime(get(col))]
                dt[, (col) := NULL]
              }
            }
          }
          return(dt)
        }
      ))
    },

    # ---- Average Price ----

    #' @description
    #' Get Average Price
    #'
    #' Retrieves the current average price for a symbol (5-minute weighted average).
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/avgPrice`
    #'
    #' ### Official Documentation
    #' [Binance Current Average Price](https://binance-docs.github.io/apidocs/spot/en/#current-average-price)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/avgPrice?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' { "mins": 5, "price": "67232.45000000", "closeTime": 1694061154503 }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `mins` (integer): Number of minutes in the averaging window.
    #'   - `price` (character): Weighted average price over the window.
    #'   - `datetime` (POSIXct): End of the averaging window.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' avg <- market$get_avg_price("BTCUSDT")
    #' print(avg)
    #' }
    get_avg_price = function(symbol) {
      return(private$.request(
        endpoint = "/api/v3/avgPrice",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "close_time" %in% names(dt)) {
            dt[, datetime := ms_to_datetime(close_time)]
            dt[, close_time := NULL]
          }
          return(dt)
        }
      ))
    },

    # ---- Order Book ----

    #' @description
    #' Get Order Book Depth
    #'
    #' Retrieves the order book (bids and asks) for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/depth`
    #'
    #' ### Official Documentation
    #' [Binance Order Book](https://binance-docs.github.io/apidocs/spot/en/#order-book)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/depth?symbol=BTCUSDT&limit=20'
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param limit Integer or NULL; depth limit. Valid values: 5, 10, 20, 50, 100,
    #'   500, 1000, 5000. Default 100.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `last_update_id` (character): Sequence ID for orderbook synchronisation.
    #'   - `side` (character): `"bid"` or `"ask"`.
    #'   - `price` (numeric): Price level.
    #'   - `quantity` (numeric): Available quantity at this price level.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' depth <- market$get_depth("BTCUSDT", limit = 20)
    #' print(depth)
    #' }
    get_depth = function(symbol, limit = NULL) {
      return(private$.request(
        endpoint = "/api/v3/depth",
        query = list(symbol = symbol, limit = limit),
        auth = FALSE,
        .parser = parse_orderbook
      ))
    },

    # ---- Recent Trades ----

    #' @description
    #' Get Recent Trades
    #'
    #' Retrieves the most recent trades for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/trades`
    #'
    #' ### Official Documentation
    #' [Binance Recent Trades List](https://binance-docs.github.io/apidocs/spot/en/#recent-trades-list)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/trades?symbol=BTCUSDT&limit=10'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": 28457,
    #'     "price": "4.00000100",
    #'     "qty": "12.00000000",
    #'     "quoteQty": "48.000012",
    #'     "time": 1499865549590,
    #'     "isBuyerMaker": true,
    #'     "isBestMatch": true
    #'   }
    #' ]
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param limit Integer or NULL; max results (default 500, max 1000).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (integer): Unique trade identifier.
    #'   - `price` (character): Trade execution price.
    #'   - `qty` (character): Base asset quantity traded.
    #'   - `quote_qty` (character): Quote asset quantity traded.
    #'   - `datetime` (POSIXct): Trade execution time.
    #'   - `is_buyer_maker` (logical): `TRUE` if the buyer was the maker (passive side).
    #'   - `is_best_match` (logical): `TRUE` if this trade was at the best available price.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' trades <- market$get_trades("BTCUSDT", limit = 10)
    #' print(trades)
    #' }
    get_trades = function(symbol, limit = NULL) {
      return(private$.request(
        endpoint = "/api/v3/trades",
        query = list(symbol = symbol, limit = limit),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, datetime := ms_to_datetime(time)]
            dt[, time := NULL]
          }
          return(dt)
        }
      ))
    },

    # ---- Klines ----

    #' @description
    #' Get Klines (Candlestick Data)
    #'
    #' Retrieves historical kline/candlestick data for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/klines`
    #'
    #' ### Official Documentation
    #' [Binance Kline/Candlestick Data](https://binance-docs.github.io/apidocs/spot/en/#kline-candlestick-data)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' ### Automated Trading Usage
    #' - **Technical Analysis**: Feed OHLCV data into indicator calculations (RSI, MACD, etc.).
    #' - **Backtesting**: Download historical candles for strategy evaluation.
    #' - **Volume Analysis**: Use `volume` and `quote_volume` for liquidity assessment.
    #'
    #' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
    #' @param interval Character; candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime POSIXct or numeric or NULL; start time (ms or POSIXct).
    #' @param endTime POSIXct or numeric or NULL; end time (ms or POSIXct).
    #' @param limit Integer or NULL; max results (default 500, max 1000).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `datetime` (POSIXct): Candle open time.
    #'   - `open` (numeric): Opening price.
    #'   - `high` (numeric): Highest price during the interval.
    #'   - `low` (numeric): Lowest price during the interval.
    #'   - `close` (numeric): Closing price.
    #'   - `volume` (numeric): Base asset volume traded.
    #'   - `quote_volume` (numeric): Quote asset volume traded.
    #'   - `trades` (integer): Number of trades during the interval.
    #'   - `taker_buy_base_volume` (numeric): Base asset volume bought by takers.
    #'   - `taker_buy_quote_volume` (numeric): Quote asset volume bought by takers.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' klines <- market$get_klines("BTCUSDT", "1h", limit = 24)
    #' print(klines)
    #' }
    get_klines = function(
      symbol,
      interval = "1h",
      startTime = NULL,
      endTime = NULL,
      limit = NULL
    ) {
      valid_intervals <- c(
        "1s", "1m", "3m", "5m", "15m", "30m",
        "1h", "2h", "4h", "6h", "8h", "12h",
        "1d", "3d", "1w", "1M"
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
        endpoint = "/api/v3/klines",
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
