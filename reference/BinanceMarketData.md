# BinanceMarketData: Spot Market Data Retrieval

BinanceMarketData: Spot Market Data Retrieval

BinanceMarketData: Spot Market Data Retrieval

## Details

Provides methods for retrieving market data from Binance's Spot trading
API, including exchange info, klines, tickers, orderbooks, trade
history, and 24-hour statistics.

Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Exchange Info**: Retrieve trading pair metadata including precision,
  filters, and trading status.

- **Tickers**: Access real-time price data for individual symbols or all
  pairs.

- **Order Books**: Get order book depth snapshots.

- **Trade History**: Retrieve recent trades for any symbol.

- **24hr Statistics**: Get rolling 24-hour market statistics.

- **Klines**: Fetch historical candlestick data.

- **Server Time**: Get exchange server time for clock synchronisation.

### Usage

All methods are public endpoints requiring no authentication.

### Official Documentation

[Binance Spot Market
Data](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints)

### Endpoints Covered

|                      |                               |      |
|----------------------|-------------------------------|------|
| Method               | Endpoint                      | Auth |
| get_server_time      | GET /api/v3/time              | No   |
| get_exchange_info    | GET /api/v3/exchangeInfo      | No   |
| get_rate_limits      | GET /api/v3/exchangeInfo      | No   |
| get_exchange_filters | GET /api/v3/exchangeInfo      | No   |
| get_ticker           | GET /api/v3/ticker/price      | No   |
| get_all_tickers      | GET /api/v3/ticker/price      | No   |
| get_book_ticker      | GET /api/v3/ticker/bookTicker | No   |
| get_24hr_stats       | GET /api/v3/ticker/24hr       | No   |
| get_avg_price        | GET /api/v3/avgPrice          | No   |
| get_depth            | GET /api/v3/depth             | No   |
| get_trades           | GET /api/v3/trades            | No   |
| get_klines           | GET /api/v3/klines            | No   |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`binance::BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceMarketData`

## Methods

### Public methods

- [`BinanceMarketData$get_server_time()`](#method-BinanceMarketData-get_server_time)

- [`BinanceMarketData$get_exchange_info()`](#method-BinanceMarketData-get_exchange_info)

- [`BinanceMarketData$get_rate_limits()`](#method-BinanceMarketData-get_rate_limits)

- [`BinanceMarketData$get_exchange_filters()`](#method-BinanceMarketData-get_exchange_filters)

- [`BinanceMarketData$get_ticker()`](#method-BinanceMarketData-get_ticker)

- [`BinanceMarketData$get_all_tickers()`](#method-BinanceMarketData-get_all_tickers)

- [`BinanceMarketData$get_book_ticker()`](#method-BinanceMarketData-get_book_ticker)

- [`BinanceMarketData$get_24hr_stats()`](#method-BinanceMarketData-get_24hr_stats)

- [`BinanceMarketData$get_all_24hr_stats()`](#method-BinanceMarketData-get_all_24hr_stats)

- [`BinanceMarketData$get_avg_price()`](#method-BinanceMarketData-get_avg_price)

- [`BinanceMarketData$get_depth()`](#method-BinanceMarketData-get_depth)

- [`BinanceMarketData$get_trades()`](#method-BinanceMarketData-get_trades)

- [`BinanceMarketData$get_klines()`](#method-BinanceMarketData-get_klines)

- [`BinanceMarketData$clone()`](#method-BinanceMarketData-clone)

Inherited methods

- [`binance::BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### Method `get_server_time()`

Get Server Time

Retrieves the current server timestamp from Binance in milliseconds.
Useful for detecting clock drift and ensuring HMAC signatures are valid.

#### API Endpoint

`GET https://api.binance.com/api/v3/time`

#### Official Documentation

[Binance Check Server
Time](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/general-endpoints#check-server-time)
Verified: 2026-05-22

#### Automated Trading Usage

- **Clock Drift Detection**: Compare server time against local clock to
  detect drift.

- **Auth Debugging**: Binance tolerates `recvWindow` (default 5s);
  verify timestamps are in range.

- **Heartbeat**: Lightweight endpoint (weight 1) suitable for
  connectivity health checks.

#### curl

    curl -X GET 'https://api.binance.com/api/v3/time'

#### JSON Response

    { "serverTime": 1499827319559 }

#### Usage

    BinanceMarketData$get_server_time()

#### Returns

(data.table \| promise\<data.table\>) one row:

- server_time (POSIXct) Server time as UTC datetime.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    st <- market$get_server_time()
    drift <- as.numeric(difftime(Sys.time(), st$server_time, units = "secs"))
    cat("Clock drift:", round(drift * 1000), "ms\n")
    }

------------------------------------------------------------------------

### Method `get_exchange_info()`

Get Exchange Info

Retrieves exchange trading rules and symbol information. Includes
precision, order types, filters, and trading status for each symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/exchangeInfo`

#### Official Documentation

[Binance Exchange
Info](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/general-endpoints#exchange-information)
Verified: 2026-05-22

#### Automated Trading Usage

- **Symbol Discovery**: Find available trading pairs and their status.

- **Precision Lookup**: Get `base_asset_precision` and
  `quote_asset_precision` for order formatting.

- **Filter Validation**: Check LOT_SIZE, PRICE_FILTER, MIN_NOTIONAL
  before placing orders.

#### curl

    curl -X GET 'https://api.binance.com/api/v3/exchangeInfo?symbol=BTCUSDT'

#### JSON Response

    {
      "timezone": "UTC",
      "serverTime": 1710072000000,
      "symbols": [
        {
          "symbol": "BTCUSDT",
          "status": "TRADING",
          "baseAsset": "BTC",
          "baseAssetPrecision": 8,
          "quoteAsset": "USDT",
          "quotePrecision": 8,
          "quoteAssetPrecision": 8,
          "orderTypes": ["LIMIT","LIMIT_MAKER","MARKET","STOP_LOSS_LIMIT","TAKE_PROFIT_LIMIT"],
          "icebergAllowed": true,
          "ocoAllowed": true,
          "otoAllowed": true,
          "quoteOrderQtyMarketAllowed": true,
          "allowTrailingStop": true,
          "cancelReplaceAllowed": true,
          "isSpotTradingAllowed": true,
          "isMarginTradingAllowed": true,
          "filters": [
            {"filterType":"PRICE_FILTER","minPrice":"0.01000000","maxPrice":"1000000.00","tickSize":"0.01000000"},
            {"filterType":"LOT_SIZE","minQty":"0.00001000","maxQty":"9000.00000000","stepSize":"0.00001000"},
            {"filterType":"MIN_NOTIONAL","minNotional":"5.00000000"}
          ],
          "permissions": ["SPOT","MARGIN"],
          "defaultSelfTradePreventionMode": "EXPIRE_MAKER",
          "allowedSelfTradePreventionModes": ["EXPIRE_TAKER","EXPIRE_MAKER","EXPIRE_BOTH"]
        }
      ]
    }

#### Usage

    BinanceMarketData$get_exchange_info(symbol = NULL, symbols = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>?) specific symbol (e.g., `"BTCUSDT"`).

- `symbols`:

  (character?) multiple symbols.

#### Returns

(data.table \| promise\<data.table\>) one row per symbol, with all
symbol fields returned by the API, converted to snake_case (empty when
Binance returns no symbols). Key columns include:

- symbol (character) Trading pair identifier (e.g., `"BTCUSDT"`).

- status (character) Trading status (`"TRADING"`, `"HALT"`, `"BREAK"`).

- base_asset (character) Base asset code (e.g., `"BTC"`).

- base_asset_precision (integer) Decimal precision for base asset
  quantities.

- quote_asset (character) Quote asset code (e.g., `"USDT"`).

- quote_asset_precision (integer) Decimal precision for quote asset
  quantities.

- quote_precision (integer) Decimal precision for quote asset prices.

- order_types (character) Semicolon-separated allowed order types (e.g.,
  `"LIMIT;MARKET"`). Recover the vector via
  `strsplit(dt$order_types[1], ";", fixed = TRUE)[[1]]`.

- iceberg_allowed (logical) Whether iceberg orders are allowed.

- oco_allowed (logical) Whether OCO orders are allowed.

- oto_allowed (logical) Whether OTO orders are allowed.

- quote_order_qty_market_allowed (logical) Whether quote quantity market
  orders are allowed.

- allow_trailing_stop (logical) Whether trailing stop orders are
  allowed.

- cancel_replace_allowed (logical) Whether cancel-replace is allowed.

- is_spot_trading_allowed (logical) Whether spot trading is enabled.

- is_margin_trading_allowed (logical) Whether margin trading is enabled.

- lot_min_qty (numeric \| NA) Minimum order quantity from LOT_SIZE
  filter (`NA` when the symbol carries no LOT_SIZE filter).

- lot_max_qty (numeric \| NA) Maximum order quantity from LOT_SIZE
  filter.

- lot_step_size (numeric \| NA) Quantity step size from LOT_SIZE filter.

- price_min (numeric) Minimum price from PRICE_FILTER.

- price_max (numeric) Maximum price from PRICE_FILTER.

- price_tick_size (numeric) Price tick size from PRICE_FILTER.

- min_notional (numeric \| NA) Minimum notional value from MIN_NOTIONAL
  filter (`NA` when the symbol carries no NOTIONAL filter).

- filters_raw (character) JSON-encoded copy of the full per-symbol
  `filters` array. Preserves filter types not pulled into curated
  columns (`PERCENT_PRICE`, `PERCENT_PRICE_BY_SIDE`, `MARKET_LOT_SIZE`,
  `MAX_NUM_ORDERS`, `MAX_NUM_ALGO_ORDERS`, `MAX_NUM_ICEBERG_ORDERS`,
  `ICEBERG_PARTS`, `MAX_POSITION`, `TRAILING_DELTA`, ...). Recover with
  `jsonlite::fromJSON(dt$filters_raw[1])`. `NA` if Binance returned no
  filters for the symbol.

- permissions (character \| NA) Semicolon-separated trading permissions
  (e.g., `"SPOT;MARGIN"`). Recover via
  `strsplit(dt$permissions[1], ";", fixed = TRUE)[[1]]`. **Note:** on
  newer symbols Binance often returns `permissions = []` and populates
  `permission_sets` instead, so this column is `NA` for those symbols.
  Prefer `permission_sets` for new code.

- permission_sets (character \| NA) JSON string preserving Binance's
  array-of-arrays structure (e.g.
  `'[["SPOT","MARGIN"],["TRD_GRP_004"]]'`). Inner groupings carry
  semantic meaning — each inner array is an alternative permission set —
  so we don't flatten with `;`. Recover with
  `jsonlite::fromJSON(dt$permission_sets[1])`. `NA` when the symbol
  omits the field.

- default_self_trade_prevention_mode (character) Default STP mode.

- allowed_self_trade_prevention_modes (character) Semicolon-separated
  allowed STP modes.

Exchange-wide metadata returned by the same endpoint (`rateLimits`,
`exchangeFilters`, `sors`) is exposed via sibling methods — see
`get_rate_limits()` and `get_exchange_filters()`. The scalar
`serverTime` is available via the existing `get_server_time()`.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    info <- market$get_exchange_info("BTCUSDT")
    print(info[, .(symbol, status, base_asset, quote_asset)])

    # Recover filter types not in curated columns
    jsonlite::fromJSON(info$filters_raw[1])

    # Exchange-wide metadata via sibling methods
    market$get_rate_limits()
    market$get_exchange_filters()
    }

------------------------------------------------------------------------

### Method `get_rate_limits()`

Get Exchange Rate Limits

Retrieves the exchange-wide API rate-limit rules (request weight per
minute, orders per second / per day, etc.). These rules apply to every
method that hits the API, not to any single symbol — so they live on a
dedicated sibling method rather than being replicated on each row of
`get_exchange_info()`.

#### API Endpoint

`GET https://api.binance.com/api/v3/exchangeInfo` (returns the same
payload as `get_exchange_info()`; this method extracts the `rateLimits`
slice.)

#### Official Documentation

[Binance Exchange
Info](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/general-endpoints#exchange-information)
Verified: 2026-05-22

#### Usage

    BinanceMarketData$get_rate_limits()

#### Returns

(data.table \| promise\<data.table\>) one row per rate-limit rule (empty
when Binance returned no `rateLimits` block):

- rate_limit_type (character) `"REQUEST_WEIGHT"`, `"ORDERS"`,
  `"RAW_REQUESTS"`.

- interval (character) `"SECOND"`, `"MINUTE"`, `"DAY"`.

- interval_num (integer) Multiplier for `interval`.

- limit (integer) Maximum requests / orders permitted in the interval.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    market$get_rate_limits()
    }

------------------------------------------------------------------------

### Method `get_exchange_filters()`

Get Exchange-Wide Filters

Retrieves the exchange-wide filter rules (e.g.
`EXCHANGE_MAX_NUM_ORDERS`, `EXCHANGE_MAX_NUM_ALGO_ORDERS`). These
constrain the user across all symbols rather than per-symbol, so they're
a sibling method to `get_exchange_info()`.

Almost always empty in practice — Binance reserves the field for future
use but currently leaves it as `[]` on most accounts.

#### API Endpoint

`GET https://api.binance.com/api/v3/exchangeInfo` (returns the same
payload as `get_exchange_info()`; this method extracts the
`exchangeFilters` slice.)

#### Usage

    BinanceMarketData$get_exchange_filters()

#### Returns

(data.table \| promise\<data.table\>) one row per exchange-wide filter
rule. Empty when Binance returns no `exchangeFilters` (the common case),
so this return is schemaless (no fixed columns).

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    market$get_exchange_filters()
    }

------------------------------------------------------------------------

### Method `get_ticker()`

Get Symbol Price Ticker

Retrieves the latest price for a specific symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/ticker/price`

#### Official Documentation

[Binance Symbol Price
Ticker](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#symbol-price-ticker)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT'

#### JSON Response

    { "symbol": "BTCUSDT", "price": "67232.90000000" }

#### Usage

    BinanceMarketData$get_ticker(symbol)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row:

- symbol (character) Trading pair identifier.

- price (character) Latest traded price as string.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    ticker <- market$get_ticker("BTCUSDT")
    print(ticker)
    }

------------------------------------------------------------------------

### Method `get_all_tickers()`

Get All Symbol Price Tickers

Retrieves the latest price for all trading pairs in a single request.

#### API Endpoint

`GET https://api.binance.com/api/v3/ticker/price`

#### Official Documentation

[Binance Symbol Price
Ticker](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#symbol-price-ticker)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/ticker/price'

#### JSON Response

    [
      { "symbol": "BTCUSDT", "price": "67232.90000000" },
      { "symbol": "ETHUSDT", "price": "3456.78000000" },
      { "symbol": "BNBUSDT", "price": "543.21000000" }
    ]

#### Usage

    BinanceMarketData$get_all_tickers()

#### Returns

(data.table \| promise\<data.table\>) one row per symbol:

- symbol (character) Trading pair identifier.

- price (character) Latest traded price as string.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    all_tickers <- market$get_all_tickers()
    print(all_tickers[1:5])
    }

------------------------------------------------------------------------

### Method `get_book_ticker()`

Get Best Bid/Ask (Book Ticker)

Retrieves the best bid and ask price and quantity for a symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/ticker/bookTicker`

#### Official Documentation

[Binance Symbol Order Book
Ticker](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#symbol-order-book-ticker)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/ticker/bookTicker?symbol=BTCUSDT'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "bidPrice": "67232.00000000",
      "bidQty": "0.41861839",
      "askPrice": "67232.90000000",
      "askQty": "1.24808993"
    }

#### Usage

    BinanceMarketData$get_book_ticker(symbol)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

#### Returns

(BookTicker \| promise\<BookTicker\>) one row, best bid/ask.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    book <- market$get_book_ticker("BTCUSDT")
    print(book)
    }

------------------------------------------------------------------------

### Method `get_24hr_stats()`

Get 24hr Ticker Statistics

Retrieves rolling 24-hour price change statistics for a symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/ticker/24hr`

#### Official Documentation

[Binance 24hr Ticker Price Change
Statistics](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#24hr-ticker-price-change-statistics)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "priceChange": "-150.23000000",
      "priceChangePercent": "-0.223",
      "weightedAvgPrice": "67150.45000000",
      "prevClosePrice": "67380.00000000",
      "lastPrice": "67232.90000000",
      "lastQty": "0.00120000",
      "bidPrice": "67232.00000000",
      "bidQty": "0.41861839",
      "askPrice": "67232.90000000",
      "askQty": "1.24808993",
      "openPrice": "67383.13000000",
      "highPrice": "67890.00000000",
      "lowPrice": "66500.00000000",
      "volume": "18532.41200000",
      "quoteVolume": "1244567890.12345678",
      "openTime": 1710072000000,
      "closeTime": 1710158399999,
      "firstId": 3553450112,
      "lastId": 3554123456,
      "count": 673344
    }

#### Usage

    BinanceMarketData$get_24hr_stats(symbol)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row:

- symbol (character) Trading pair identifier.

- price_change (character) Absolute price change over 24h.

- price_change_percent (character) Percentage price change over 24h.

- weighted_avg_price (character) Volume-weighted average price over 24h.

- prev_close_price (character) Previous day's closing price.

- last_price (character) Most recent trade price.

- last_qty (character) Most recent trade quantity.

- bid_price (character) Current best bid price.

- bid_qty (character) Current best bid quantity.

- ask_price (character) Current best ask price.

- ask_qty (character) Current best ask quantity.

- open_price (character) Price at 24h window open.

- high_price (character) Highest price in 24h.

- low_price (character) Lowest price in 24h.

- volume (character) Total base asset volume in 24h.

- quote_volume (character) Total quote asset volume in 24h.

- open_time (POSIXct) Start of the 24h window.

- close_time (POSIXct) End of the 24h window.

- first_id (numeric) First trade ID in the window.

- last_id (numeric) Last trade ID in the window.

- count (integer) Total number of trades in 24h.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    stats <- market$get_24hr_stats("BTCUSDT")
    print(stats[, .(symbol, last_price, price_change_percent, volume)])
    }

------------------------------------------------------------------------

### Method `get_all_24hr_stats()`

Get 24hr Ticker Statistics for All Symbols

Retrieves rolling 24-hour price change statistics for all trading pairs
in a single request.

#### API Endpoint

`GET https://api.binance.com/api/v3/ticker/24hr` (no symbol parameter)

#### Official Documentation

[Binance 24hr Ticker Price Change
Statistics](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#24hr-ticker-price-change-statistics)

#### Usage

    BinanceMarketData$get_all_24hr_stats()

#### Returns

(data.table \| promise\<data.table\>) one row per symbol, the same
columns as `get_24hr_stats()`.

- symbol (character) Trading pair identifier.

- price_change (character) Absolute price change over 24h.

- price_change_percent (character) Percentage price change over 24h.

- weighted_avg_price (character) Volume-weighted average price over 24h.

- prev_close_price (character) Previous day's closing price.

- last_price (character) Most recent trade price.

- last_qty (character) Most recent trade quantity.

- bid_price (character) Current best bid price.

- bid_qty (character) Current best bid quantity.

- ask_price (character) Current best ask price.

- ask_qty (character) Current best ask quantity.

- open_price (character) Price at 24h window open.

- high_price (character) Highest price in 24h.

- low_price (character) Lowest price in 24h.

- volume (character) Total base asset volume in 24h.

- quote_volume (character) Total quote asset volume in 24h.

- open_time (POSIXct) Start of the 24h window.

- close_time (POSIXct) End of the 24h window.

- first_id (numeric) First trade ID in the window.

- last_id (numeric) Last trade ID in the window.

- count (integer) Total number of trades in 24h.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    all_stats <- market$get_all_24hr_stats()
    print(all_stats[1:5, .(symbol, last_price, price_change_percent, volume)])
    }

------------------------------------------------------------------------

### Method `get_avg_price()`

Get Average Price

Retrieves the current average price for a symbol (5-minute weighted
average).

#### API Endpoint

`GET https://api.binance.com/api/v3/avgPrice`

#### Official Documentation

[Binance Current Average
Price](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#current-average-price)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/avgPrice?symbol=BTCUSDT'

#### JSON Response

    { "mins": 5, "price": "67232.45000000", "closeTime": 1694061154503 }

#### Usage

    BinanceMarketData$get_avg_price(symbol)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row:

- mins (integer) Number of minutes in the averaging window.

- price (character) Weighted average price over the window.

- close_time (POSIXct) End of the averaging window.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    avg <- market$get_avg_price("BTCUSDT")
    print(avg)
    }

------------------------------------------------------------------------

### Method `get_depth()`

Get Order Book Depth

Retrieves the order book (bids and asks) for a symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/depth`

#### Official Documentation

[Binance Order
Book](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#order-book)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/depth?symbol=BTCUSDT&limit=20'

#### JSON Response

    {
      "lastUpdateId": 1027024,
      "bids": [
        ["67232.00000000", "0.41861839"],
        ["67231.50000000", "1.20000000"]
      ],
      "asks": [
        ["67232.90000000", "1.24808993"],
        ["67233.00000000", "0.85000000"]
      ]
    }

#### Usage

    BinanceMarketData$get_depth(symbol, limit = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `limit`:

  (scalar\<count\>?) depth limit. Valid values: 5, 10, 20, 50, 100, 500,
  1000, 5000. Default 100.

#### Returns

(OrderBook \| promise\<OrderBook\>) one row per price level (bids first,
then asks).

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    depth <- market$get_depth("BTCUSDT", limit = 20)
    print(depth)
    }

------------------------------------------------------------------------

### Method `get_trades()`

Get Recent Trades

Retrieves the most recent trades for a symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/trades`

#### Official Documentation

[Binance Recent Trades
List](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#recent-trades-list)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/trades?symbol=BTCUSDT&limit=10'

#### JSON Response

    [
      {
        "id": 28457,
        "price": "4.00000100",
        "qty": "12.00000000",
        "quoteQty": "48.000012",
        "time": 1499865549590,
        "isBuyerMaker": true,
        "isBestMatch": true
      }
    ]

#### Usage

    BinanceMarketData$get_trades(symbol, limit = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1000).

#### Returns

(Trade \| promise\<Trade\>) one row per public trade.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    trades <- market$get_trades("BTCUSDT", limit = 10)
    print(trades)
    }

------------------------------------------------------------------------

### Method `get_klines()`

Get Klines (Candlestick Data)

Retrieves historical kline/candlestick data for a symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/klines`

#### Official Documentation

[Binance Kline/Candlestick
Data](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints#klinecandlestick-data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=100'

#### JSON Response

    [
      [
        1710072000000,
        "67100.00000000",
        "67250.00000000",
        "67050.00000000",
        "67232.90000000",
        "523.41200000",
        1710075599999,
        "35134567.89012345",
        1234,
        "261.70600000",
        "17567283.94506172",
        "0"
      ]
    ]

#### Automated Trading Usage

- **Technical Analysis**: Feed OHLCV data into indicator calculations
  (RSI, MACD, etc.).

- **Backtesting**: Download historical candles for strategy evaluation.

- **Volume Analysis**: Use `volume` and `quote_volume` for liquidity
  assessment.

#### Usage

    BinanceMarketData$get_klines(
      symbol,
      interval = "1h",
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      fetch_all = FALSE,
      sleep = 0.2,
      on_page = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `interval`:

  (scalar\<character\>) candle interval. Valid values: `"1s"`, `"1m"`,
  `"3m"`, `"5m"`, `"15m"`, `"30m"`, `"1h"`, `"2h"`, `"4h"`, `"6h"`,
  `"8h"`, `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.

- `startTime`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) start time (ms or POSIXct).

- `endTime`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) end time (ms or POSIXct).

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1000).

- `fetch_all`:

  (scalar\<logical\>) if `TRUE`, automatically pages forward through the
  time range — following the data and stopping at the first empty or
  short page — and returns the combined result sorted by `open_time`.
  Both `startTime` and `endTime` are required when enabled. **Warning**:
  large date ranges will consume multiple API requests and may impact
  your rate-limit quota. Default `FALSE`.

- `sleep`:

  (scalar\<numeric\>) seconds to wait between consecutive API calls when
  `fetch_all = TRUE`. Use this to avoid hitting Binance rate limits.
  Only applies in synchronous mode; async mode chains requests
  sequentially via promises. Default `0.2`.

- `on_page`:

  (function?) optional `function(page)` called with each page (a
  `data.table`) as it is fetched, when `fetch_all = TRUE`. When
  supplied, pages are streamed to the callback and **not** accumulated —
  the method returns invisibly, so the callback owns the data (e.g.
  writes it to disk). Use it to process arbitrarily large ranges without
  holding everything in memory. Ignored in single-call mode
  (`fetch_all = FALSE`), where there is only one page. Default `NULL`
  (buffer and return the combined table).

#### Returns

(Ohlcv \| promise\<Ohlcv\>) one row per candle. When `fetch_all = TRUE`
with an `on_page` callback the pages are streamed to the callback and
the method returns invisibly (`NULL`); the contract below describes the
buffered (returned) case.

#### Examples

    \dontrun{
    market <- BinanceMarketData$new()
    klines <- market$get_klines("BTCUSDT", "1h", limit = 24)

    # Fetch all candles across a large date range (multiple API calls)
    all_klines <- market$get_klines(
      "BTCUSDT", "1h",
      startTime = as.POSIXct("2024-01-01", tz = "UTC"),
      endTime = as.POSIXct("2024-06-01", tz = "UTC"),
      fetch_all = TRUE, sleep = 0.5
    )
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceMarketData$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous usage
market <- BinanceMarketData$new()
ticker <- market$get_ticker("BTCUSDT")
print(ticker)

# Asynchronous usage
market_async <- BinanceMarketData$new(async = TRUE)
main <- coro::async(function() {
  ticker <- await(market_async$get_ticker("BTCUSDT"))
  print(ticker)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceMarketData$get_server_time`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
st <- market$get_server_time()
drift <- as.numeric(difftime(Sys.time(), st$server_time, units = "secs"))
cat("Clock drift:", round(drift * 1000), "ms\n")
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_exchange_info`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
info <- market$get_exchange_info("BTCUSDT")
print(info[, .(symbol, status, base_asset, quote_asset)])

# Recover filter types not in curated columns
jsonlite::fromJSON(info$filters_raw[1])

# Exchange-wide metadata via sibling methods
market$get_rate_limits()
market$get_exchange_filters()
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_rate_limits`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
market$get_rate_limits()
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_exchange_filters`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
market$get_exchange_filters()
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_ticker`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
ticker <- market$get_ticker("BTCUSDT")
print(ticker)
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_all_tickers`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
all_tickers <- market$get_all_tickers()
print(all_tickers[1:5])
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_book_ticker`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
book <- market$get_book_ticker("BTCUSDT")
print(book)
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_24hr_stats`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
stats <- market$get_24hr_stats("BTCUSDT")
print(stats[, .(symbol, last_price, price_change_percent, volume)])
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_all_24hr_stats`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
all_stats <- market$get_all_24hr_stats()
print(all_stats[1:5, .(symbol, last_price, price_change_percent, volume)])
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_avg_price`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
avg <- market$get_avg_price("BTCUSDT")
print(avg)
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_depth`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
depth <- market$get_depth("BTCUSDT", limit = 20)
print(depth)
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_trades`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
trades <- market$get_trades("BTCUSDT", limit = 10)
print(trades)
} # }

## ------------------------------------------------
## Method `BinanceMarketData$get_klines`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- BinanceMarketData$new()
klines <- market$get_klines("BTCUSDT", "1h", limit = 24)

# Fetch all candles across a large date range (multiple API calls)
all_klines <- market$get_klines(
  "BTCUSDT", "1h",
  startTime = as.POSIXct("2024-01-01", tz = "UTC"),
  endTime = as.POSIXct("2024-06-01", tz = "UTC"),
  fetch_all = TRUE, sleep = 0.5
)
} # }
```
