# BinanceFuturesData: USD-M Futures Market Data Retrieval

Provides methods for retrieving market data from Binance's USD-M Futures
API, including exchange info, klines, mark prices, funding rates,
tickers, order books, open interest, and trade history.

Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Exchange Info**: Retrieve futures trading pair metadata including
  precision, filters, and contract type.

- **Klines**: Fetch historical candlestick data for futures contracts.

- **Mark Price**: Access mark prices and funding rate information.

- **Funding Rates**: Get historical funding rate data.

- **Tickers**: Access real-time price data for individual symbols or all
  pairs.

- **Order Books**: Get order book depth snapshots.

- **Open Interest**: Retrieve open interest data for futures contracts.

- **Trade History**: Retrieve recent trades for any symbol.

- **Index/Mark Price Klines**: Fetch historical index price and mark
  price candlestick data.

### Usage

All methods are public endpoints requiring no authentication. The base
URL defaults to `https://fapi.binance.com` via
[`get_futures_base_url()`](https://dereckscompany.github.io/binance/reference/get_futures_base_url.md).

### Official Documentation

[Binance USD-M Futures Market
Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api)

### Endpoints Covered

|                        |                                |      |
|------------------------|--------------------------------|------|
| Method                 | Endpoint                       | Auth |
| get_exchange_info      | GET /fapi/v1/exchangeInfo      | No   |
| get_rate_limits        | GET /fapi/v1/exchangeInfo      | No   |
| get_exchange_filters   | GET /fapi/v1/exchangeInfo      | No   |
| get_futures_assets     | GET /fapi/v1/exchangeInfo      | No   |
| get_klines             | GET /fapi/v1/klines            | No   |
| get_mark_price         | GET /fapi/v1/premiumIndex      | No   |
| get_funding_rate       | GET /fapi/v1/fundingRate       | No   |
| get_funding_info       | GET /fapi/v1/fundingInfo       | No   |
| get_24hr_stats         | GET /fapi/v1/ticker/24hr       | No   |
| get_ticker             | GET /fapi/v1/ticker/price      | No   |
| get_book_ticker        | GET /fapi/v1/ticker/bookTicker | No   |
| get_open_interest      | GET /fapi/v1/openInterest      | No   |
| get_depth              | GET /fapi/v1/depth             | No   |
| get_trades             | GET /fapi/v1/trades            | No   |
| get_index_price_klines | GET /fapi/v1/indexPriceKlines  | No   |
| get_mark_price_klines  | GET /fapi/v1/markPriceKlines   | No   |

## Super classes

[`connectcore::RestClient`](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
-\>
[`BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceFuturesData`

## Methods

### Public methods

- [`BinanceFuturesData$new()`](#method-BinanceFuturesData-initialize)

- [`BinanceFuturesData$get_exchange_info()`](#method-BinanceFuturesData-get_exchange_info)

- [`BinanceFuturesData$get_rate_limits()`](#method-BinanceFuturesData-get_rate_limits)

- [`BinanceFuturesData$get_exchange_filters()`](#method-BinanceFuturesData-get_exchange_filters)

- [`BinanceFuturesData$get_futures_assets()`](#method-BinanceFuturesData-get_futures_assets)

- [`BinanceFuturesData$get_klines()`](#method-BinanceFuturesData-get_klines)

- [`BinanceFuturesData$get_mark_price()`](#method-BinanceFuturesData-get_mark_price)

- [`BinanceFuturesData$get_funding_rate()`](#method-BinanceFuturesData-get_funding_rate)

- [`BinanceFuturesData$get_funding_info()`](#method-BinanceFuturesData-get_funding_info)

- [`BinanceFuturesData$get_24hr_stats()`](#method-BinanceFuturesData-get_24hr_stats)

- [`BinanceFuturesData$get_ticker()`](#method-BinanceFuturesData-get_ticker)

- [`BinanceFuturesData$get_book_ticker()`](#method-BinanceFuturesData-get_book_ticker)

- [`BinanceFuturesData$get_open_interest()`](#method-BinanceFuturesData-get_open_interest)

- [`BinanceFuturesData$get_depth()`](#method-BinanceFuturesData-get_depth)

- [`BinanceFuturesData$get_trades()`](#method-BinanceFuturesData-get_trades)

- [`BinanceFuturesData$get_index_price_klines()`](#method-BinanceFuturesData-get_index_price_klines)

- [`BinanceFuturesData$get_mark_price_klines()`](#method-BinanceFuturesData-get_mark_price_klines)

- [`BinanceFuturesData$clone()`](#method-BinanceFuturesData-clone)

------------------------------------------------------------------------

### `BinanceFuturesData$new()`

Initialise a BinanceFuturesData Object

Overrides the default base URL to use the Futures API endpoint and
configures the server time endpoint for futures when
`time_source = "server"`.

#### Usage

    BinanceFuturesData$new(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    )

#### Arguments

- `keys`:

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) API base URL. Defaults to
  [`get_futures_base_url()`](https://dereckscompany.github.io/binance/reference/get_futures_base_url.md).

- `async`:

  (scalar\<logical\>) if `TRUE`, methods return promises. Default
  `FALSE`.

- `time_source`:

  (scalar\<character\>) clock source for HMAC request signing. `"local"`
  (default) uses [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).
  `"server"` fetches the Binance Futures server time before each
  authenticated request.

#### Returns

(class\<BinanceFuturesData\>) invisibly, self.

------------------------------------------------------------------------

### `BinanceFuturesData$get_exchange_info()`

Get Futures Exchange Info

Retrieves exchange trading rules and symbol information for USD-M
futures. Includes precision, order types, filters, contract type, and
trading status.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/exchangeInfo`

#### Official Documentation

[Binance Futures Exchange
Info](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Exchange-Information)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/exchangeInfo'

#### JSON Response

    {
      "timezone": "UTC",
      "serverTime": 1710028800000,
      "symbols": [
        {
          "symbol": "BTCUSDT",
          "pair": "BTCUSDT",
          "contractType": "PERPETUAL",
          "deliveryDate": 4133404800000,
          "onboardDate": 1569398400000,
          "status": "TRADING",
          "baseAsset": "BTC",
          "quoteAsset": "USDT",
          "marginAsset": "USDT",
          "pricePrecision": 2,
          "quantityPrecision": 3,
          "baseAssetPrecision": 8,
          "quotePrecision": 8,
          "underlyingType": "COIN",
          "settlePlan": 0,
          "triggerProtect": "0.0500",
          "orderTypes": ["LIMIT", "MARKET", "STOP", "STOP_MARKET", "TAKE_PROFIT", "TAKE_PROFIT_MARKET", "TRAILING_STOP_MARKET"],
          "timeInForce": ["GTC", "IOC", "FOK", "GTX", "GTD"],
          "filters": [
            {"filterType": "PRICE_FILTER", "minPrice": "556.80", "maxPrice": "4529764", "tickSize": "0.10"},
            {"filterType": "LOT_SIZE", "minQty": "0.001", "maxQty": "1000", "stepSize": "0.001"},
            {"filterType": "MIN_NOTIONAL", "notional": "5"}
          ]
        }
      ]
    }

#### Usage

    BinanceFuturesData$get_exchange_info()

#### Returns

(data.table \| promise\<data.table\>) one row per symbol, with all
symbol fields returned by the API, converted to snake_case (empty when
Binance returns no symbols). Key columns include:

- symbol (character) Trading pair identifier (e.g., `"BTCUSDT"`).

- pair (character) Underlying pair.

- contract_type (character) Contract type (e.g., `"PERPETUAL"`).

- status (character) Trading status (`"TRADING"`, etc.).

- base_asset (character) Base asset code (e.g., `"BTC"`).

- quote_asset (character) Quote asset code (e.g., `"USDT"`).

- margin_asset (character) Margin asset code (e.g., `"USDT"`).

- price_precision (integer) Decimal precision for prices.

- quantity_precision (integer) Decimal precision for quantities.

- order_types (character) Semicolon-separated allowed order types.
  Recover via `strsplit(dt$order_types[1], ";", fixed = TRUE)[[1]]`.

- time_in_force (character) Semicolon-separated allowed time-in-force
  values.

- underlying_sub_type (character \| NA) Semicolon-separated underlying
  sub-types (`NA` when the symbol omits the field, as many non-coin /
  index-style contracts do).

- permission_sets (character \| NA) Semicolon-separated permission sets
  (`NA` when the symbol omits the field).

- lot_min_qty (numeric \| NA) Minimum order quantity (from LOT_SIZE
  filter; `NA` when the symbol carries no LOT_SIZE filter).

- lot_max_qty (numeric \| NA) Maximum order quantity (from LOT_SIZE
  filter).

- lot_step_size (numeric \| NA) Quantity step size (from LOT_SIZE
  filter).

- price_min (numeric \| NA) Minimum price (from PRICE_FILTER; `NA` when
  the symbol carries no PRICE_FILTER).

- price_max (numeric \| NA) Maximum price (from PRICE_FILTER; `NA` when
  the symbol carries no PRICE_FILTER).

- price_tick_size (numeric \| NA) Price tick size (from PRICE_FILTER;
  `NA` when the symbol carries no PRICE_FILTER).

- min_notional (numeric \| NA) Minimum notional value (from MIN_NOTIONAL
  filter; `NA` when the symbol carries no MIN_NOTIONAL filter).

- filters_raw (character \| NA) JSON-encoded copy of the full per-symbol
  `filters` array. Preserves filter types not pulled into curated
  columns (`PERCENT_PRICE`, `MARKET_LOT_SIZE`, `MAX_NUM_ORDERS`,
  `MAX_NUM_ALGO_ORDERS`, `MIN_NOTIONAL`'s extra fields, ...). Recover
  with `jsonlite::fromJSON(dt$filters_raw[1])`. `NA` if Binance returned
  no filters for the symbol.

Exchange-wide metadata returned by the same endpoint is exposed via
sibling methods: `get_rate_limits()`, `get_exchange_filters()`,
`get_futures_assets()`. Server time is available via
`BinanceMarketData$get_server_time()`.

#### Examples

    futures <- BinanceFuturesData$new()
    info <- futures$get_exchange_info()
    print(info[, .(symbol, contract_type, status, base_asset)])

    # Recover filter types not in curated columns
    jsonlite::fromJSON(info$filters_raw[1])

    # Exchange-wide metadata via sibling methods
    futures$get_rate_limits()
    futures$get_futures_assets()

------------------------------------------------------------------------

### `BinanceFuturesData$get_rate_limits()`

Get Futures Exchange Rate Limits

Retrieves the USDⓈ-M futures API rate-limit rules. Same sibling pattern
as `BinanceMarketData$get_rate_limits()`.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/exchangeInfo`

#### Usage

    BinanceFuturesData$get_rate_limits()

#### Returns

(data.table \| promise\<data.table\>) one row per rate-limit rule (empty
when Binance returned no `rateLimits` block):

- rate_limit_type (character) `"REQUEST_WEIGHT"`, `"ORDERS"`,
  `"RAW_REQUESTS"`.

- interval (character) `"SECOND"`, `"MINUTE"`, `"DAY"`.

- interval_num (integer) Multiplier for `interval`.

- limit (integer) Maximum requests / orders permitted in the interval.

#### Examples

    futures <- BinanceFuturesData$new()
    futures$get_rate_limits()

------------------------------------------------------------------------

### `BinanceFuturesData$get_exchange_filters()`

Get Futures Exchange-Wide Filters

Retrieves the exchange-wide filter rules. Almost always empty. Sibling
to `get_exchange_info()`.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/exchangeInfo`

#### Usage

    BinanceFuturesData$get_exchange_filters()

#### Returns

(data.table \| promise\<data.table\>) one row per exchange-wide filter
rule (schemaless empty when none, the common case).

#### Examples

    futures <- BinanceFuturesData$new()
    futures$get_exchange_filters()

------------------------------------------------------------------------

### `BinanceFuturesData$get_futures_assets()`

Get Futures Margin Assets

Retrieves the margin-asset configuration returned at the top level of
futures `/fapi/v1/exchangeInfo` (one row per asset usable as margin —
USDT, BNFCR, etc.).

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/exchangeInfo`

#### Usage

    BinanceFuturesData$get_futures_assets()

#### Returns

(data.table \| promise\<data.table\>) one row per margin asset (empty
when Binance returned no `assets` block):

- asset (character) Asset symbol (e.g., `"USDT"`).

- margin_available (logical) Whether the asset can be used as margin.

- auto_asset_exchange (character) Auto-exchange threshold.

#### Examples

    futures <- BinanceFuturesData$new()
    futures$get_futures_assets()

------------------------------------------------------------------------

### `BinanceFuturesData$get_klines()`

Get Klines (Candlestick Data)

Retrieves historical kline/candlestick data for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/klines`

#### Official Documentation

[Binance Futures Kline/Candlestick
Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Kline-Candlestick-Data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/klines?symbol=BTCUSDT&interval=1h&limit=100'

#### JSON Response

    [
      [
        1710028800000,
        "67521.30",
        "67845.90",
        "67310.50",
        "67632.40",
        "12534.812",
        1710032399999,
        "847293156.23",
        48921,
        "6231.405",
        "421234567.89",
        "0"
      ]
    ]

#### Usage

    BinanceFuturesData$get_klines(
      symbol,
      interval = "1h",
      start_time = NULL,
      end_time = NULL,
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

- `start_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) start time (ms or POSIXct).

- `end_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) end time (ms or POSIXct).

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1500).

- `fetch_all`:

  (scalar\<logical\>) if `TRUE`, automatically pages forward through the
  time range — following the data and stopping at the first empty or
  short page — and returns the combined result sorted by `datetime`.
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
  (`fetch_all = FALSE`). Default `NULL`.

#### Returns

(Ohlcv \| promise\<Ohlcv\>) one row per candle. When `fetch_all = TRUE`
with an `on_page` callback the pages are streamed to the callback and
the method returns invisibly (`NULL`); the contract describes the
buffered (returned) case.

#### Examples

    futures <- BinanceFuturesData$new()
    klines <- futures$get_klines("BTCUSDT", "1h", limit = 24)

    # Fetch all candles across a large date range (multiple API calls)
    all_klines <- futures$get_klines(
      "BTCUSDT", "1h",
      start_time = as.POSIXct("2024-01-01", tz = "UTC"),
      end_time = as.POSIXct("2024-06-01", tz = "UTC"),
      fetch_all = TRUE, sleep = 0.5
    )

------------------------------------------------------------------------

### `BinanceFuturesData$get_mark_price()`

Get Mark Price

Retrieves the mark price, index price, and funding rate information for
a specific symbol or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/premiumIndex`

#### Official Documentation

[Binance Futures Mark
Price](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Mark-Price)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/premiumIndex?symbol=BTCUSDT'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "markPrice": "67582.35000000",
      "indexPrice": "67575.12345678",
      "estimatedSettlePrice": "67579.88654321",
      "lastFundingRate": "0.00010000",
      "nextFundingTime": 1710057600000,
      "interestRate": "0.00010000",
      "time": 1710028800000
    }

#### Usage

    BinanceFuturesData$get_mark_price(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>?) trading pair (e.g., `"BTCUSDT"`). If NULL,
  returns data for all symbols.

#### Returns

(data.table \| promise\<data.table\>) one row per symbol (a single row
when `symbol` is given):

- symbol (character) Trading pair identifier.

- mark_price (character) Current mark price.

- index_price (character) Current index price.

- estimated_settle_price (character) Estimated settlement price.

- last_funding_rate (character) Last funding rate.

- next_funding_time (POSIXct) Next funding time.

- interest_rate (character) Interest rate.

- time (POSIXct) Data timestamp.

#### Examples

    futures <- BinanceFuturesData$new()
    mark <- futures$get_mark_price("BTCUSDT")
    print(mark)

    # All symbols
    all_marks <- futures$get_mark_price()
    print(all_marks)

------------------------------------------------------------------------

### `BinanceFuturesData$get_funding_rate()`

Get Funding Rate History

Retrieves historical funding rate data for a symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/fundingRate`

#### Official Documentation

[Binance Futures Funding Rate
History](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Get-Funding-Rate-History)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/fundingRate?symbol=BTCUSDT&limit=100'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "fundingRate": "0.00010000",
        "fundingTime": 1710028800000,
        "markPrice": "67582.35000000"
      },
      {
        "symbol": "BTCUSDT",
        "fundingRate": "0.00012500",
        "fundingTime": 1710000000000,
        "markPrice": "67245.10000000"
      }
    ]

#### Usage

    BinanceFuturesData$get_funding_rate(
      symbol,
      start_time = NULL,
      end_time = NULL,
      limit = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `start_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) start time (ms or POSIXct).

- `end_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) end time (ms or POSIXct).

- `limit`:

  (scalar\<count\>?) max results (default 100, max 1000).

#### Returns

(data.table \| promise\<data.table\>) one row per funding event (empty
when there are none):

- symbol (character) Trading pair identifier.

- funding_rate (character) Funding rate value.

- funding_time (POSIXct) Funding timestamp.

- mark_price (character) Mark price at funding time.

#### Examples

    futures <- BinanceFuturesData$new()
    rates <- futures$get_funding_rate("BTCUSDT", limit = 10)
    print(rates)

------------------------------------------------------------------------

### `BinanceFuturesData$get_funding_info()`

Get Funding Info (Interval Declarations)

Binance publishes a small list declaring the perpetuals whose funding
parameters deviate from the venue defaults — chiefly the contracts on a
non-standard funding interval (4h or 1h instead of the default 8h), plus
the declared rate cap/floor for each such symbol. Symbols on the plain
8h default with no override are omitted, so the list is short and can
even be empty. This is the declaration source; use `get_funding_rate()`
for the realised funding-settlement history.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/fundingInfo`

#### Official Documentation

[Binance Futures Get Funding Rate
Info](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Get-Funding-Rate-Info)
Verified: 2026-07-14

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/fundingInfo'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "adjustedFundingRateCap": "0.02000000",
        "adjustedFundingRateFloor": "-0.02000000",
        "fundingIntervalHours": 8,
        "disclaimer": false,
        "updateTime": 1710028800000
      }
    ]

#### Usage

    BinanceFuturesData$get_funding_info()

#### Returns

(data.table \| promise\<data.table\>) one row per declared symbol (empty
when Binance returns no declarations, e.g. every symbol on the default
schedule):

- symbol (character) Trading pair identifier (e.g., `"BTCUSDT"`).

- adjusted_funding_rate_cap (numeric \| NA) Upper bound applied to the
  symbol's funding rate (`NA` when Binance omits the field).

- adjusted_funding_rate_floor (numeric \| NA) Lower bound applied to the
  symbol's funding rate (`NA` when Binance omits the field).

- funding_interval_hours (integer \| NA) Declared funding interval in
  whole hours (e.g. `4`; `NA` when Binance omits the field). Symbols
  absent from this list settle on the 8-hour default.

- disclaimer (logical) Whether Binance attaches a funding disclaimer to
  the symbol.

- update_time (POSIXct) Time the declaration was last updated.

#### Examples

    futures <- BinanceFuturesData$new()
    info <- futures$get_funding_info()
    print(info[funding_interval_hours != 8L, .(symbol, funding_interval_hours)])

------------------------------------------------------------------------

### `BinanceFuturesData$get_24hr_stats()`

Get 24hr Ticker Statistics

Retrieves rolling 24-hour price change statistics for a futures symbol
or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/ticker/24hr`

#### Official Documentation

[Binance Futures 24hr
Ticker](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/24hr-Ticker-Price-Change-Statistics)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/24hr?symbol=BTCUSDT'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "priceChange": "1250.30",
      "priceChangePercent": "1.882",
      "weightedAvgPrice": "67123.45",
      "lastPrice": "67632.40",
      "lastQty": "0.012",
      "openPrice": "66382.10",
      "highPrice": "67845.90",
      "lowPrice": "65980.00",
      "volume": "285431.234",
      "quoteVolume": "19187654321.56",
      "openTime": 1709942400000,
      "closeTime": 1710028799999,
      "firstId": 4123456789,
      "lastId": 4123987654,
      "count": 530865
    }

#### Usage

    BinanceFuturesData$get_24hr_stats(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>?) trading pair (e.g., `"BTCUSDT"`). If NULL,
  returns data for all symbols.

#### Returns

(data.table \| promise\<data.table\>) one row per symbol (a single row
when `symbol` is given):

- symbol (character) Trading pair identifier.

- price_change (character) Absolute price change over 24h.

- price_change_percent (character) Percentage price change over 24h.

- weighted_avg_price (character) Volume-weighted average price over 24h.

- last_price (character) Most recent trade price.

- volume (character) Total base asset volume in 24h.

- quote_volume (character) Total quote asset volume in 24h.

- open_time (POSIXct) Start of the 24h window.

- close_time (POSIXct) End of the 24h window.

#### Examples

    futures <- BinanceFuturesData$new()
    stats <- futures$get_24hr_stats("BTCUSDT")
    print(stats[, .(symbol, last_price, price_change_percent, volume)])

------------------------------------------------------------------------

### `BinanceFuturesData$get_ticker()`

Get Symbol Price Ticker

Retrieves the latest price for a specific futures symbol or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/ticker/price`

#### Official Documentation

[Binance Futures Symbol Price
Ticker](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Symbol-Price-Ticker)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/price?symbol=BTCUSDT'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "price": "67632.40",
      "time": 1710028800000
    }

#### Usage

    BinanceFuturesData$get_ticker(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>?) trading pair (e.g., `"BTCUSDT"`). If NULL,
  returns data for all symbols.

#### Returns

(data.table \| promise\<data.table\>) one row per symbol (a single row
when `symbol` is given):

- symbol (character) Trading pair identifier.

- price (character) Latest traded price as string.

- time (POSIXct) Timestamp (if present in response).

#### Examples

    futures <- BinanceFuturesData$new()
    ticker <- futures$get_ticker("BTCUSDT")
    print(ticker)

------------------------------------------------------------------------

### `BinanceFuturesData$get_book_ticker()`

Get Best Bid/Ask (Book Ticker)

Retrieves the best bid and ask price and quantity for a futures symbol
or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/ticker/bookTicker`

#### Official Documentation

[Binance Futures Symbol Order Book
Ticker](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Symbol-Order-Book-Ticker)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/ticker/bookTicker?symbol=BTCUSDT'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "bidPrice": "67630.20",
      "bidQty": "5.432",
      "askPrice": "67632.40",
      "askQty": "3.218",
      "time": 1710028800000
    }

#### Usage

    BinanceFuturesData$get_book_ticker(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>?) trading pair (e.g., `"BTCUSDT"`). If NULL,
  returns data for all symbols.

#### Returns

(data.table \| promise\<data.table\>) one row per symbol (a single row
when `symbol` is given):

- symbol (character) Trading pair identifier.

- bid_price (character) Best bid price.

- bid_qty (character) Quantity available at best bid.

- ask_price (character) Best ask price.

- ask_qty (character) Quantity available at best ask.

#### Examples

    futures <- BinanceFuturesData$new()
    book <- futures$get_book_ticker("BTCUSDT")
    print(book)

------------------------------------------------------------------------

### `BinanceFuturesData$get_open_interest()`

Get Open Interest

Retrieves the current open interest for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/openInterest`

#### Official Documentation

[Binance Futures Open
Interest](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Open-Interest)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/openInterest?symbol=BTCUSDT'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "openInterest": "72381.532",
      "time": 1710028800000
    }

#### Usage

    BinanceFuturesData$get_open_interest(symbol)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row:

- symbol (character) Trading pair identifier.

- open_interest (character) Current open interest.

- time (POSIXct) Timestamp (if present in response).

#### Examples

    futures <- BinanceFuturesData$new()
    oi <- futures$get_open_interest("BTCUSDT")
    print(oi)

------------------------------------------------------------------------

### `BinanceFuturesData$get_depth()`

Get Order Book Depth

Retrieves the order book (bids and asks) for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/depth`

#### Official Documentation

[Binance Futures Order
Book](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Order-Book)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/depth?symbol=BTCUSDT&limit=20'

#### JSON Response

    {
      "lastUpdateId": 2731879654321,
      "E": 1710028800000,
      "T": 1710028800000,
      "bids": [
        ["67630.20", "5.432"],
        ["67629.90", "2.100"],
        ["67629.50", "8.750"]
      ],
      "asks": [
        ["67632.40", "3.218"],
        ["67632.80", "1.500"],
        ["67633.10", "6.340"]
      ]
    }

#### Usage

    BinanceFuturesData$get_depth(symbol, limit = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `limit`:

  (scalar\<count\>?) depth limit. Valid values: 5, 10, 20, 50, 100,
  500, 1000. Default 500.

#### Returns

(OrderBook \| promise\<OrderBook\>) one row per price level (bids first,
then asks).

#### Examples

    futures <- BinanceFuturesData$new()
    depth <- futures$get_depth("BTCUSDT", limit = 20)
    print(depth)

------------------------------------------------------------------------

### `BinanceFuturesData$get_trades()`

Get Recent Trades

Retrieves the most recent trades for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/trades`

#### Official Documentation

[Binance Futures Recent Trades
List](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Recent-Trades-List)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/trades?symbol=BTCUSDT&limit=10'

#### JSON Response

    [
      {
        "id": 3456789012,
        "price": "67632.40",
        "qty": "0.015",
        "quoteQty": "1014.49",
        "time": 1710028800123,
        "isBuyerMaker": false
      },
      {
        "id": 3456789013,
        "price": "67630.20",
        "qty": "0.200",
        "quoteQty": "13526.04",
        "time": 1710028800456,
        "isBuyerMaker": true
      }
    ]

#### Usage

    BinanceFuturesData$get_trades(symbol, limit = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1000).

#### Returns

(data.table \| promise\<data.table\>) one row per public trade (empty
when there are none):

- id (numeric) Unique trade identifier.

- price (character) Trade execution price.

- qty (character) Base asset quantity traded.

- quote_qty (character) Quote asset quantity traded.

- time (POSIXct) Trade execution time.

- is_buyer_maker (logical) `TRUE` if the buyer was the maker.

#### Examples

    futures <- BinanceFuturesData$new()
    trades <- futures$get_trades("BTCUSDT", limit = 10)
    print(trades)

------------------------------------------------------------------------

### `BinanceFuturesData$get_index_price_klines()`

Get Index Price Klines

Retrieves historical index price kline/candlestick data for a pair.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/indexPriceKlines`

#### Official Documentation

[Binance Futures Index Price Kline/Candlestick
Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Index-Price-Kline-Candlestick-Data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/indexPriceKlines?pair=BTCUSDT&interval=1h&limit=100'

#### JSON Response

    [
      [
        1710028800000,
        "67518.42",
        "67840.15",
        "67305.78",
        "67625.33",
        "0",
        1710032399999,
        "0",
        0,
        "0",
        "0",
        "0"
      ]
    ]

#### Usage

    BinanceFuturesData$get_index_price_klines(
      pair,
      interval = "1h",
      start_time = NULL,
      end_time = NULL,
      limit = NULL
    )

#### Arguments

- `pair`:

  (scalar\<character\>) underlying pair (e.g., `"BTCUSDT"`).

- `interval`:

  (scalar\<character\>) candle interval. Valid values: `"1s"`, `"1m"`,
  `"3m"`, `"5m"`, `"15m"`, `"30m"`, `"1h"`, `"2h"`, `"4h"`, `"6h"`,
  `"8h"`, `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.

- `start_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) start time (ms or POSIXct).

- `end_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) end time (ms or POSIXct).

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1500).

#### Returns

(Ohlcv \| promise\<Ohlcv\>) one row per candle.

#### Examples

    futures <- BinanceFuturesData$new()
    klines <- futures$get_index_price_klines("BTCUSDT", "1h", limit = 24)
    print(klines)

------------------------------------------------------------------------

### `BinanceFuturesData$get_mark_price_klines()`

Get Mark Price Klines

Retrieves historical mark price kline/candlestick data for a symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/markPriceKlines`

#### Official Documentation

[Binance Futures Mark Price Kline/Candlestick
Data](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Mark-Price-Kline-Candlestick-Data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://fapi.binance.com/fapi/v1/markPriceKlines?symbol=BTCUSDT&interval=1h&limit=100'

#### JSON Response

    [
      [
        1710028800000,
        "67525.10",
        "67848.75",
        "67312.40",
        "67635.20",
        "0",
        1710032399999,
        "0",
        0,
        "0",
        "0",
        "0"
      ]
    ]

#### Usage

    BinanceFuturesData$get_mark_price_klines(
      symbol,
      interval = "1h",
      start_time = NULL,
      end_time = NULL,
      limit = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `interval`:

  (scalar\<character\>) candle interval. Valid values: `"1s"`, `"1m"`,
  `"3m"`, `"5m"`, `"15m"`, `"30m"`, `"1h"`, `"2h"`, `"4h"`, `"6h"`,
  `"8h"`, `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.

- `start_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) start time (ms or POSIXct).

- `end_time`:

  (scalar\<POSIXct\> \| scalar\<numeric\>?) end time (ms or POSIXct).

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1500).

#### Returns

(Ohlcv \| promise\<Ohlcv\>) one row per candle.

#### Examples

    futures <- BinanceFuturesData$new()
    klines <- futures$get_mark_price_klines("BTCUSDT", "1h", limit = 24)
    print(klines)

------------------------------------------------------------------------

### `BinanceFuturesData$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceFuturesData$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous usage
futures <- BinanceFuturesData$new()
mark <- futures$get_mark_price("BTCUSDT")
print(mark)

# Asynchronous usage
futures_async <- BinanceFuturesData$new(async = TRUE)
main <- coro::async(function() {
  mark <- await(futures_async$get_mark_price("BTCUSDT"))
  print(mark)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceFuturesData$get_exchange_info()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
info <- futures$get_exchange_info()
print(info[, .(symbol, contract_type, status, base_asset)])

# Recover filter types not in curated columns
jsonlite::fromJSON(info$filters_raw[1])

# Exchange-wide metadata via sibling methods
futures$get_rate_limits()
futures$get_futures_assets()
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_rate_limits()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
futures$get_rate_limits()
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_exchange_filters()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
futures$get_exchange_filters()
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_futures_assets()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
futures$get_futures_assets()
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_klines()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
klines <- futures$get_klines("BTCUSDT", "1h", limit = 24)

# Fetch all candles across a large date range (multiple API calls)
all_klines <- futures$get_klines(
  "BTCUSDT", "1h",
  start_time = as.POSIXct("2024-01-01", tz = "UTC"),
  end_time = as.POSIXct("2024-06-01", tz = "UTC"),
  fetch_all = TRUE, sleep = 0.5
)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_mark_price()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
mark <- futures$get_mark_price("BTCUSDT")
print(mark)

# All symbols
all_marks <- futures$get_mark_price()
print(all_marks)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_funding_rate()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
rates <- futures$get_funding_rate("BTCUSDT", limit = 10)
print(rates)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_funding_info()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
info <- futures$get_funding_info()
print(info[funding_interval_hours != 8L, .(symbol, funding_interval_hours)])
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_24hr_stats()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
stats <- futures$get_24hr_stats("BTCUSDT")
print(stats[, .(symbol, last_price, price_change_percent, volume)])
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_ticker()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
ticker <- futures$get_ticker("BTCUSDT")
print(ticker)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_book_ticker()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
book <- futures$get_book_ticker("BTCUSDT")
print(book)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_open_interest()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
oi <- futures$get_open_interest("BTCUSDT")
print(oi)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_depth()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
depth <- futures$get_depth("BTCUSDT", limit = 20)
print(depth)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_trades()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
trades <- futures$get_trades("BTCUSDT", limit = 10)
print(trades)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_index_price_klines()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
klines <- futures$get_index_price_klines("BTCUSDT", "1h", limit = 24)
print(klines)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_mark_price_klines()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
klines <- futures$get_mark_price_klines("BTCUSDT", "1h", limit = 24)
print(klines)
} # }
```
