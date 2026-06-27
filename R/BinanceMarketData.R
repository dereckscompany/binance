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
#' [Binance Spot Market Data](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Auth |
#' |--------|----------|------|
#' | get_server_time | GET /api/v3/time | No |
#' | get_exchange_info | GET /api/v3/exchangeInfo | No |
#' | get_rate_limits | GET /api/v3/exchangeInfo | No |
#' | get_exchange_filters | GET /api/v3/exchangeInfo | No |
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
    #' [Binance Check Server Time](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/general-endpoints#check-server-time)
    #' Verified: 2026-05-22
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
    #' @return (data.table | promise<data.table>) one row:
    #'   - server_time (POSIXct) Server time as UTC datetime.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' st <- market$get_server_time()
    #' drift <- as.numeric(difftime(Sys.time(), st$server_time, units = "secs"))
    #' cat("Clock drift:", round(drift * 1000), "ms\n")
    #' }
    get_server_time = function() {
      res <- private$.request(
        endpoint = "/api/v3/time",
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "server_time", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_server_time,
        is_async = private$.is_async
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
    #' [Binance Exchange Info](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/general-endpoints#exchange-information)
    #' Verified: 2026-05-22
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
    #' ### JSON Response
    #' ```json
    #' {
    #'   "timezone": "UTC",
    #'   "serverTime": 1710072000000,
    #'   "symbols": [
    #'     {
    #'       "symbol": "BTCUSDT",
    #'       "status": "TRADING",
    #'       "baseAsset": "BTC",
    #'       "baseAssetPrecision": 8,
    #'       "quoteAsset": "USDT",
    #'       "quotePrecision": 8,
    #'       "quoteAssetPrecision": 8,
    #'       "orderTypes": ["LIMIT","LIMIT_MAKER","MARKET","STOP_LOSS_LIMIT","TAKE_PROFIT_LIMIT"],
    #'       "icebergAllowed": true,
    #'       "ocoAllowed": true,
    #'       "otoAllowed": true,
    #'       "quoteOrderQtyMarketAllowed": true,
    #'       "allowTrailingStop": true,
    #'       "cancelReplaceAllowed": true,
    #'       "isSpotTradingAllowed": true,
    #'       "isMarginTradingAllowed": true,
    #'       "filters": [
    #'         {"filterType":"PRICE_FILTER","minPrice":"0.01000000","maxPrice":"1000000.00","tickSize":"0.01000000"},
    #'         {"filterType":"LOT_SIZE","minQty":"0.00001000","maxQty":"9000.00000000","stepSize":"0.00001000"},
    #'         {"filterType":"MIN_NOTIONAL","minNotional":"5.00000000"}
    #'       ],
    #'       "permissions": ["SPOT","MARGIN"],
    #'       "defaultSelfTradePreventionMode": "EXPIRE_MAKER",
    #'       "allowedSelfTradePreventionModes": ["EXPIRE_TAKER","EXPIRE_MAKER","EXPIRE_BOTH"]
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>?) specific symbol (e.g., `"BTCUSDT"`).
    #' @param symbols (character?) multiple symbols.
    #' @return (data.table | promise<data.table>) one row per symbol, with all
    #'   symbol fields returned by the API, converted to snake_case (empty when
    #'   Binance returns no symbols). Key columns include:
    #'   - symbol (character) Trading pair identifier (e.g., `"BTCUSDT"`).
    #'   - status (character) Trading status (`"TRADING"`, `"HALT"`, `"BREAK"`).
    #'   - base_asset (character) Base asset code (e.g., `"BTC"`).
    #'   - base_asset_precision (integer) Decimal precision for base asset quantities.
    #'   - quote_asset (character) Quote asset code (e.g., `"USDT"`).
    #'   - quote_asset_precision (integer) Decimal precision for quote asset quantities.
    #'   - quote_precision (integer) Decimal precision for quote asset prices.
    #'   - order_types (character) Semicolon-separated allowed order types
    #'     (e.g., `"LIMIT;MARKET"`). Recover the vector via
    #'     `strsplit(dt$order_types[1], ";", fixed = TRUE)[[1]]`.
    #'   - iceberg_allowed (logical) Whether iceberg orders are allowed.
    #'   - oco_allowed (logical) Whether OCO orders are allowed.
    #'   - oto_allowed (logical) Whether OTO orders are allowed.
    #'   - quote_order_qty_market_allowed (logical) Whether quote quantity market orders are allowed.
    #'   - allow_trailing_stop (logical) Whether trailing stop orders are allowed.
    #'   - cancel_replace_allowed (logical) Whether cancel-replace is allowed.
    #'   - is_spot_trading_allowed (logical) Whether spot trading is enabled.
    #'   - is_margin_trading_allowed (logical) Whether margin trading is enabled.
    #'   - lot_min_qty (numeric | NA) Minimum order quantity from LOT_SIZE filter
    #'     (`NA` when the symbol carries no LOT_SIZE filter).
    #'   - lot_max_qty (numeric | NA) Maximum order quantity from LOT_SIZE filter.
    #'   - lot_step_size (numeric | NA) Quantity step size from LOT_SIZE filter.
    #'   - price_min (numeric) Minimum price from PRICE_FILTER.
    #'   - price_max (numeric) Maximum price from PRICE_FILTER.
    #'   - price_tick_size (numeric) Price tick size from PRICE_FILTER.
    #'   - min_notional (numeric | NA) Minimum notional value from MIN_NOTIONAL
    #'     filter (`NA` when the symbol carries no NOTIONAL filter).
    #'   - filters_raw (character) JSON-encoded copy of the full per-symbol
    #'     `filters` array. Preserves filter types not pulled into curated
    #'     columns (`PERCENT_PRICE`, `PERCENT_PRICE_BY_SIDE`, `MARKET_LOT_SIZE`,
    #'     `MAX_NUM_ORDERS`, `MAX_NUM_ALGO_ORDERS`, `MAX_NUM_ICEBERG_ORDERS`,
    #'     `ICEBERG_PARTS`, `MAX_POSITION`, `TRAILING_DELTA`, ...). Recover
    #'     with `jsonlite::fromJSON(dt$filters_raw[1])`. `NA` if Binance
    #'     returned no filters for the symbol.
    #'   - permissions (character) Semicolon-separated trading permissions
    #'     (e.g., `"SPOT;MARGIN"`). Recover via
    #'     `strsplit(dt$permissions[1], ";", fixed = TRUE)[[1]]`. **Note:**
    #'     on newer symbols Binance often returns `permissions = []` and
    #'     populates `permission_sets` instead. Prefer `permission_sets`
    #'     for new code.
    #'   - permission_sets (character | NA) JSON string preserving
    #'     Binance's array-of-arrays structure (e.g.
    #'     `'[["SPOT","MARGIN"],["TRD_GRP_004"]]'`). Inner groupings
    #'     carry semantic meaning — each inner array is an alternative
    #'     permission set — so we don't flatten with `;`. Recover with
    #'     `jsonlite::fromJSON(dt$permission_sets[1])`. `NA` when the
    #'     symbol omits the field.
    #'   - default_self_trade_prevention_mode (character) Default STP mode.
    #'   - allowed_self_trade_prevention_modes (character) Semicolon-separated
    #'     allowed STP modes.
    #'
    #' Exchange-wide metadata returned by the same endpoint
    #' (`rateLimits`, `exchangeFilters`, `sors`) is exposed via sibling
    #' methods — see [`get_rate_limits()`][BinanceMarketData] and
    #' [`get_exchange_filters()`][BinanceMarketData]. The scalar
    #' `serverTime` is available via the existing
    #' [`get_server_time()`][BinanceMarketData].
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' info <- market$get_exchange_info("BTCUSDT")
    #' print(info[, .(symbol, status, base_asset, quote_asset)])
    #'
    #' # Recover filter types not in curated columns
    #' jsonlite::fromJSON(info$filters_raw[1])
    #'
    #' # Exchange-wide metadata via sibling methods
    #' market$get_rate_limits()
    #' market$get_exchange_filters()
    #' }
    get_exchange_info = function(symbol = NULL, symbols = NULL) {
      assert_args_BinanceMarketData__get_exchange_info(symbol, symbols)
      query <- list()
      if (!is.null(symbol)) {
        query$symbol <- symbol
      } else if (!is.null(symbols)) {
        query$symbols <- jsonlite::toJSON(symbols, auto_unbox = FALSE)
      }

      res <- private$.request(
        endpoint = "/api/v3/exchangeInfo",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          syms <- data$symbols
          if (is.null(syms) || length(syms) == 0) {
            return(empty_dt_exchange_info())
          }

          # Helper to extract a specific filter field from the raw filters list
          .extract_filter <- function(filters, filter_type, field) {
            if (is.null(filters) || length(filters) == 0) {
              return(NA_real_)
            }
            for (f in filters) {
              if (!is.null(f$filterType) && f$filterType == filter_type) {
                val <- f[[field]]
                if (!is.null(val)) {
                  return(as.numeric(val))
                }
              }
            }
            return(NA_real_)
          }

          # Extract filter values into flat fields, semicolon-join string
          # arrays, and JSON-encode the raw filters list (so filter
          # types we don't pull out into curated columns — PERCENT_PRICE,
          # MARKET_LOT_SIZE, MAX_NUM_ORDERS, ICEBERG_PARTS,
          # TRAILING_DELTA, etc. — are still reachable).
          syms <- lapply(syms, function(s) {
            # Flat string arrays → `;`-collapse via the shared helper.
            s <- collapse_string_array_fields(
              s,
              c("orderTypes", "permissions", "allowedSelfTradePreventionModes")
            )
            # `permissionSets` is an ARRAY OF ARRAYS on Binance spot
            # (e.g. `[["SPOT","MARGIN"], ["TRD_GRP_004"]]`), and the
            # inner groupings carry semantic meaning — each inner array
            # is an alternative permission set the user can satisfy.
            # `;`-joining would flatten that information away, so we
            # serialise the whole field as a JSON string. Recover the
            # structure via `jsonlite::fromJSON(dt$permission_sets[1])`,
            # which gives back a list-of-character-vectors. `NA` when
            # the upstream field is absent.
            ps <- s[["permissionSets"]]
            if (is.null(ps) || length(ps) == 0L) {
              s[["permissionSets"]] <- NA_character_
            } else {
              # auto_unbox = TRUE so each scalar string stays a scalar
              # rather than being boxed into a length-1 array. The
              # list-of-list outer structure is preserved.
              s[["permissionSets"]] <- as.character(
                jsonlite::toJSON(ps, auto_unbox = TRUE)
              )
            }
            # Extract filter values as flat numeric fields
            raw_filters <- s$filters
            s$lot_min_qty <- .extract_filter(raw_filters, "LOT_SIZE", "minQty")
            s$lot_max_qty <- .extract_filter(raw_filters, "LOT_SIZE", "maxQty")
            s$lot_step_size <- .extract_filter(raw_filters, "LOT_SIZE", "stepSize")
            s$price_min <- .extract_filter(raw_filters, "PRICE_FILTER", "minPrice")
            s$price_max <- .extract_filter(raw_filters, "PRICE_FILTER", "maxPrice")
            s$price_tick_size <- .extract_filter(raw_filters, "PRICE_FILTER", "tickSize")
            # Current API uses NOTIONAL; legacy symbols may use MIN_NOTIONAL
            min_not <- .extract_filter(raw_filters, "NOTIONAL", "minNotional")
            if (is.na(min_not)) {
              min_not <- .extract_filter(raw_filters, "MIN_NOTIONAL", "minNotional")
            }
            s$min_notional <- min_not
            # Preserve the full filters array as a JSON string so filter
            # types we don't pull into curated columns are still
            # reachable. Recover with `jsonlite::fromJSON(dt$filters_raw[1])`.
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
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_exchange_info,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Exchange Rate Limits
    #'
    #' Retrieves the exchange-wide API rate-limit rules (request weight
    #' per minute, orders per second / per day, etc.). These rules apply
    #' to every method that hits the API, not to any single symbol —
    #' so they live on a dedicated sibling method rather than being
    #' replicated on each row of `get_exchange_info()`.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/exchangeInfo`
    #' (returns the same payload as [`get_exchange_info()`][BinanceMarketData];
    #' this method extracts the `rateLimits` slice.)
    #'
    #' ### Official Documentation
    #' [Binance Exchange Info](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/general-endpoints#exchange-information)
    #' Verified: 2026-05-22
    #'
    #' @return (data.table | promise<data.table>) one row per rate-limit rule
    #'   (empty when Binance returned no `rateLimits` block):
    #'   - rate_limit_type (character) `"REQUEST_WEIGHT"`, `"ORDERS"`,
    #'     `"RAW_REQUESTS"`.
    #'   - interval (character) `"SECOND"`, `"MINUTE"`, `"DAY"`.
    #'   - interval_num (integer) Multiplier for `interval`.
    #'   - limit (integer) Maximum requests / orders permitted in the
    #'     interval.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' market$get_rate_limits()
    #' }
    get_rate_limits = function() {
      res <- private$.request(
        endpoint = "/api/v3/exchangeInfo",
        auth = FALSE,
        .parser = function(data) {
          rl <- data$rateLimits
          if (is.null(rl) || length(rl) == 0L) {
            return(empty_dt_rate_limit())
          }
          return(as_dt_list(rl)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_rate_limits,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Exchange-Wide Filters
    #'
    #' Retrieves the exchange-wide filter rules (e.g. `EXCHANGE_MAX_NUM_ORDERS`,
    #' `EXCHANGE_MAX_NUM_ALGO_ORDERS`). These constrain the user across all
    #' symbols rather than per-symbol, so they're a sibling method to
    #' `get_exchange_info()`.
    #'
    #' Almost always empty in practice — Binance reserves the field
    #' for future use but currently leaves it as `[]` on most accounts.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/exchangeInfo`
    #' (returns the same payload as [`get_exchange_info()`][BinanceMarketData];
    #' this method extracts the `exchangeFilters` slice.)
    #'
    #' @return (data.table | promise<data.table>) one row per exchange-wide
    #'   filter rule. Empty when Binance returns no `exchangeFilters` (the
    #'   common case), so this return is schemaless (no fixed columns).
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' market$get_exchange_filters()
    #' }
    get_exchange_filters = function() {
      res <- private$.request(
        endpoint = "/api/v3/exchangeInfo",
        auth = FALSE,
        .parser = function(data) {
          ef <- data$exchangeFilters
          if (is.null(ef) || length(ef) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(ef)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_exchange_filters,
        is_async = private$.is_async
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
    #' [Binance Symbol Price Ticker](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#symbol-price-ticker)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @return (data.table | promise<data.table>) one row:
    #'   - symbol (character) Trading pair identifier.
    #'   - price (character) Latest traded price as string.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' ticker <- market$get_ticker("BTCUSDT")
    #' print(ticker)
    #' }
    get_ticker = function(symbol) {
      assert_args_BinanceMarketData__get_ticker(symbol)
      res <- private$.request(
        endpoint = "/api/v3/ticker/price",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_ticker,
        is_async = private$.is_async
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
    #' [Binance Symbol Price Ticker](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#symbol-price-ticker)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/ticker/price'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   { "symbol": "BTCUSDT", "price": "67232.90000000" },
    #'   { "symbol": "ETHUSDT", "price": "3456.78000000" },
    #'   { "symbol": "BNBUSDT", "price": "543.21000000" }
    #' ]
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per symbol:
    #'   - symbol (character) Trading pair identifier.
    #'   - price (character) Latest traded price as string.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' all_tickers <- market$get_all_tickers()
    #' print(all_tickers[1:5])
    #' }
    get_all_tickers = function() {
      res <- private$.request(
        endpoint = "/api/v3/ticker/price",
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_ticker_price())
          }
          return(as_dt_list(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_all_tickers,
        is_async = private$.is_async
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
    #' [Binance Symbol Order Book Ticker](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#symbol-order-book-ticker)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @return (BookTicker | promise<BookTicker>) one row, best bid/ask.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' book <- market$get_book_ticker("BTCUSDT")
    #' print(book)
    #' }
    get_book_ticker = function(symbol) {
      assert_args_BinanceMarketData__get_book_ticker(symbol)
      res <- private$.request(
        endpoint = "/api/v3/ticker/bookTicker",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_book_ticker,
        is_async = private$.is_async
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
    #' [Binance 24hr Ticker Price Change Statistics](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#24hr-ticker-price-change-statistics)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "symbol": "BTCUSDT",
    #'   "priceChange": "-150.23000000",
    #'   "priceChangePercent": "-0.223",
    #'   "weightedAvgPrice": "67150.45000000",
    #'   "prevClosePrice": "67380.00000000",
    #'   "lastPrice": "67232.90000000",
    #'   "lastQty": "0.00120000",
    #'   "bidPrice": "67232.00000000",
    #'   "bidQty": "0.41861839",
    #'   "askPrice": "67232.90000000",
    #'   "askQty": "1.24808993",
    #'   "openPrice": "67383.13000000",
    #'   "highPrice": "67890.00000000",
    #'   "lowPrice": "66500.00000000",
    #'   "volume": "18532.41200000",
    #'   "quoteVolume": "1244567890.12345678",
    #'   "openTime": 1710072000000,
    #'   "closeTime": 1710158399999,
    #'   "firstId": 3553450112,
    #'   "lastId": 3554123456,
    #'   "count": 673344
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @return (data.table | promise<data.table>) one row:
    #'   - symbol (character) Trading pair identifier.
    #'   - price_change (character) Absolute price change over 24h.
    #'   - price_change_percent (character) Percentage price change over 24h.
    #'   - weighted_avg_price (character) Volume-weighted average price over 24h.
    #'   - prev_close_price (character) Previous day's closing price.
    #'   - last_price (character) Most recent trade price.
    #'   - last_qty (character) Most recent trade quantity.
    #'   - bid_price (character) Current best bid price.
    #'   - bid_qty (character) Current best bid quantity.
    #'   - ask_price (character) Current best ask price.
    #'   - ask_qty (character) Current best ask quantity.
    #'   - open_price (character) Price at 24h window open.
    #'   - high_price (character) Highest price in 24h.
    #'   - low_price (character) Lowest price in 24h.
    #'   - volume (character) Total base asset volume in 24h.
    #'   - quote_volume (character) Total quote asset volume in 24h.
    #'   - open_time (POSIXct) Start of the 24h window.
    #'   - close_time (POSIXct) End of the 24h window.
    #'   - first_id (numeric) First trade ID in the window.
    #'   - last_id (numeric) Last trade ID in the window.
    #'   - count (integer) Total number of trades in 24h.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' stats <- market$get_24hr_stats("BTCUSDT")
    #' print(stats[, .(symbol, last_price, price_change_percent, volume)])
    #' }
    get_24hr_stats = function(symbol) {
      assert_args_BinanceMarketData__get_24hr_stats(symbol)
      res <- private$.request(
        endpoint = "/api/v3/ticker/24hr",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, c("open_time", "close_time"), ms_to_datetime)
          # 64-bit trade ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("first_id", "last_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_24hr_stats,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get 24hr Ticker Statistics for All Symbols
    #'
    #' Retrieves rolling 24-hour price change statistics for all trading pairs
    #' in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/api/v3/ticker/24hr` (no symbol parameter)
    #'
    #' ### Official Documentation
    #' [Binance 24hr Ticker Price Change Statistics](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#24hr-ticker-price-change-statistics)
    #'
    #' @return (data.table | promise<data.table>) one row per symbol, with the
    #'   same columns as `get_24hr_stats()`.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' all_stats <- market$get_all_24hr_stats()
    #' print(all_stats[1:5, .(symbol, last_price, price_change_percent, volume)])
    #' }
    get_all_24hr_stats = function() {
      res <- private$.request(
        endpoint = "/api/v3/ticker/24hr",
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_list(data)
          coerce_cols(dt, c("open_time", "close_time"), ms_to_datetime)
          # 64-bit trade ids -> numeric so a large id never overflows int32.
          coerce_cols(dt, c("first_id", "last_id"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_all_24hr_stats,
        is_async = private$.is_async
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
    #' [Binance Current Average Price](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#current-average-price)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @return (data.table | promise<data.table>) one row:
    #'   - mins (integer) Number of minutes in the averaging window.
    #'   - price (character) Weighted average price over the window.
    #'   - close_time (POSIXct) End of the averaging window.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' avg <- market$get_avg_price("BTCUSDT")
    #' print(avg)
    #' }
    get_avg_price = function(symbol) {
      assert_args_BinanceMarketData__get_avg_price(symbol)
      res <- private$.request(
        endpoint = "/api/v3/avgPrice",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "close_time", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_avg_price,
        is_async = private$.is_async
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
    #' [Binance Order Book](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#order-book)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/depth?symbol=BTCUSDT&limit=20'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "lastUpdateId": 1027024,
    #'   "bids": [
    #'     ["67232.00000000", "0.41861839"],
    #'     ["67231.50000000", "1.20000000"]
    #'   ],
    #'   "asks": [
    #'     ["67232.90000000", "1.24808993"],
    #'     ["67233.00000000", "0.85000000"]
    #'   ]
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param limit (scalar<count>?) depth limit. Valid values: 5, 10, 20, 50, 100,
    #'   500, 1000, 5000. Default 100.
    #' @return (OrderBook | promise<OrderBook>) one row per price level
    #'   (bids first, then asks).
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' depth <- market$get_depth("BTCUSDT", limit = 20)
    #' print(depth)
    #' }
    get_depth = function(symbol, limit = NULL) {
      assert_args_BinanceMarketData__get_depth(symbol, limit)
      res <- private$.request(
        endpoint = "/api/v3/depth",
        query = list(symbol = symbol, limit = limit),
        auth = FALSE,
        .parser = parse_orderbook
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_depth,
        is_async = private$.is_async
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
    #' [Binance Recent Trades List](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#recent-trades-list)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param limit (scalar<count>?) max results (default 500, max 1000).
    #' @return (Trade | promise<Trade>) one row per public trade.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' trades <- market$get_trades("BTCUSDT", limit = 10)
    #' print(trades)
    #' }
    get_trades = function(symbol, limit = NULL) {
      assert_args_BinanceMarketData__get_trades(symbol, limit)
      res <- private$.request(
        endpoint = "/api/v3/trades",
        query = list(symbol = symbol, limit = limit),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_trade())
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "time", ms_to_datetime)
          # 64-bit trade id -> numeric so a large id never overflows int32.
          coerce_cols(dt, "id", as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_trades,
        is_async = private$.is_async
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
    #' [Binance Kline/Candlestick Data](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#klinecandlestick-data)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=100'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   [
    #'     1710072000000,
    #'     "67100.00000000",
    #'     "67250.00000000",
    #'     "67050.00000000",
    #'     "67232.90000000",
    #'     "523.41200000",
    #'     1710075599999,
    #'     "35134567.89012345",
    #'     1234,
    #'     "261.70600000",
    #'     "17567283.94506172",
    #'     "0"
    #'   ]
    #' ]
    #' ```
    #'
    #' ### Automated Trading Usage
    #' - **Technical Analysis**: Feed OHLCV data into indicator calculations (RSI, MACD, etc.).
    #' - **Backtesting**: Download historical candles for strategy evaluation.
    #' - **Volume Analysis**: Use `volume` and `quote_volume` for liquidity assessment.
    #'
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
    #' @param interval (scalar<character>) candle interval. Valid values:
    #'   `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`,
    #'   `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`,
    #'   `"1d"`, `"3d"`, `"1w"`, `"1M"`.
    #' @param startTime (scalar<POSIXct> | scalar<numeric>?) start time (ms or POSIXct).
    #' @param endTime (scalar<POSIXct> | scalar<numeric>?) end time (ms or POSIXct).
    #' @param limit (scalar<count>?) max results (default 500, max 1000).
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
    #'   memory. Ignored in single-call mode (`fetch_all = FALSE`), where there is
    #'   only one page. Default `NULL` (buffer and return the combined table).
    #' @return (Ohlcv | promise<Ohlcv>) one row per candle. When
    #'   `fetch_all = TRUE` with an `on_page` callback the pages are streamed to
    #'   the callback and the method returns invisibly (`NULL`); the contract
    #'   below describes the buffered (returned) case.
    #'
    #' @examples
    #' \dontrun{
    #' market <- BinanceMarketData$new()
    #' klines <- market$get_klines("BTCUSDT", "1h", limit = 24)
    #'
    #' # Fetch all candles across a large date range (multiple API calls)
    #' all_klines <- market$get_klines(
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
      assert_args_BinanceMarketData__get_klines(symbol, interval, startTime, endTime, limit, fetch_all, sleep, on_page)
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
        # Convert ms strings back to POSIXct if needed
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
          endpoint = "/api/v3/klines",
          max_candles = 1000L,
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

      res <- private$.request(
        endpoint = "/api/v3/klines",
        query = list(
          symbol = symbol,
          interval = interval,
          startTime = startTime,
          endTime = endTime,
          limit = limit
        ),
        auth = FALSE,
        .parser = function(data) {
          dt <- parse_klines(data)
          if (nrow(dt) >= 1000L && is.null(limit)) {
            rlang::warn(
              "Binance returned 1000 candles (the maximum). Results may be truncated. Use `fetch_all = TRUE` for large date ranges, or pass an explicit `limit`."
            )
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_BinanceMarketData__get_klines,
        is_async = private$.is_async
      ))
    }
  )
)
