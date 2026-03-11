# BinanceFuturesData: USD-M Futures Market Data Retrieval

BinanceFuturesData: USD-M Futures Market Data Retrieval

BinanceFuturesData: USD-M Futures Market Data Retrieval

## Details

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
Data](https://binance-docs.github.io/apidocs/futures/en/#market-data-endpoints)

### Endpoints Covered

|                        |                                |      |
|------------------------|--------------------------------|------|
| Method                 | Endpoint                       | Auth |
| get_exchange_info      | GET /fapi/v1/exchangeInfo      | No   |
| get_klines             | GET /fapi/v1/klines            | No   |
| get_mark_price         | GET /fapi/v1/premiumIndex      | No   |
| get_funding_rate       | GET /fapi/v1/fundingRate       | No   |
| get_24hr_stats         | GET /fapi/v1/ticker/24hr       | No   |
| get_ticker             | GET /fapi/v1/ticker/price      | No   |
| get_book_ticker        | GET /fapi/v1/ticker/bookTicker | No   |
| get_open_interest      | GET /fapi/v1/openInterest      | No   |
| get_depth              | GET /fapi/v1/depth             | No   |
| get_trades             | GET /fapi/v1/trades            | No   |
| get_index_price_klines | GET /fapi/v1/indexPriceKlines  | No   |
| get_mark_price_klines  | GET /fapi/v1/markPriceKlines   | No   |

## Super class

[`binance::BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceFuturesData`

## Methods

### Public methods

- [`BinanceFuturesData$new()`](#method-BinanceFuturesData-new)

- [`BinanceFuturesData$get_exchange_info()`](#method-BinanceFuturesData-get_exchange_info)

- [`BinanceFuturesData$get_klines()`](#method-BinanceFuturesData-get_klines)

- [`BinanceFuturesData$get_mark_price()`](#method-BinanceFuturesData-get_mark_price)

- [`BinanceFuturesData$get_funding_rate()`](#method-BinanceFuturesData-get_funding_rate)

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

### Method `new()`

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

  List; API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).

- `base_url`:

  Character; API base URL. Defaults to
  [`get_futures_base_url()`](https://dereckscompany.github.io/binance/reference/get_futures_base_url.md).

- `async`:

  Logical; if `TRUE`, methods return promises. Default `FALSE`.

- `time_source`:

  Character; clock source for HMAC request signing. `"local"` (default)
  uses [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html). `"server"`
  fetches the Binance Futures server time before each authenticated
  request.

#### Returns

Invisible self.

------------------------------------------------------------------------

### Method `get_exchange_info()`

Get Futures Exchange Info

Retrieves exchange trading rules and symbol information for USD-M
futures. Includes precision, order types, filters, contract type, and
trading status.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/exchangeInfo`

#### Official Documentation

[Binance Futures Exchange
Info](https://binance-docs.github.io/apidocs/futures/en/#exchange-information)
Verified: 2026-03-10

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

`data.table` (or `promise<data.table>` if `async = TRUE`) with all
symbol fields returned by the API, converted to snake_case. Key columns
include:

- `symbol` (character): Trading pair identifier (e.g., `"BTCUSDT"`).

- `pair` (character): Underlying pair.

- `contract_type` (character): Contract type (e.g., `"PERPETUAL"`).

- `status` (character): Trading status (`"TRADING"`, etc.).

- `base_asset` (character): Base asset code (e.g., `"BTC"`).

- `quote_asset` (character): Quote asset code (e.g., `"USDT"`).

- `margin_asset` (character): Margin asset code (e.g., `"USDT"`).

- `price_precision` (integer): Decimal precision for prices.

- `quantity_precision` (integer): Decimal precision for quantities.

- `order_types` (list): Allowed order types for this symbol.

- `filters` (list): List of filter objects.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    info <- futures$get_exchange_info()
    print(info[, .(symbol, contract_type, status, base_asset)])
    }

------------------------------------------------------------------------

### Method `get_klines()`

Get Klines (Candlestick Data)

Retrieves historical kline/candlestick data for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/klines`

#### Official Documentation

[Binance Futures Kline/Candlestick
Data](https://binance-docs.github.io/apidocs/futures/en/#kline-candlestick-data)
Verified: 2026-03-10

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
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      fetch_all = FALSE,
      sleep = 0.2
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `interval`:

  Character; candle interval. Valid values: `"1s"`, `"1m"`, `"3m"`,
  `"5m"`, `"15m"`, `"30m"`, `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`,
  `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.

- `startTime`:

  POSIXct or numeric or NULL; start time (ms or POSIXct).

- `endTime`:

  POSIXct or numeric or NULL; end time (ms or POSIXct).

- `limit`:

  Integer or NULL; max results (default 500, max 1500).

- `fetch_all`:

  Logical; if `TRUE`, automatically segments the time range into
  multiple API calls of up to 1500 candles each, fetches all segments,
  deduplicates overlapping boundaries, and returns the combined result
  sorted by `open_time`. Both `startTime` and `endTime` are required
  when enabled. **Warning**: large date ranges will consume multiple API
  requests and may impact your rate-limit quota. Default `FALSE`.

- `sleep`:

  Numeric; seconds to wait between consecutive API calls when
  `fetch_all = TRUE`. Use this to avoid hitting Binance rate limits.
  Only applies in synchronous mode; async mode chains requests
  sequentially via promises. Default `0.2`.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `open_time` (POSIXct): Candle open time.

- `open` (numeric): Opening price.

- `high` (numeric): Highest price during the interval.

- `low` (numeric): Lowest price during the interval.

- `close` (numeric): Closing price.

- `volume` (numeric): Base asset volume traded.

- `close_time` (POSIXct): Candle close time.

- `quote_volume` (numeric): Quote asset volume traded.

- `trades` (integer): Number of trades during the interval.

- `taker_buy_base_volume` (numeric): Base asset volume bought by takers.

- `taker_buy_quote_volume` (numeric): Quote asset volume bought by
  takers.

- `ignore` (character): Unused field from Binance API.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    klines <- futures$get_klines("BTCUSDT", "1h", limit = 24)

    # Fetch all candles across a large date range (multiple API calls)
    all_klines <- futures$get_klines(
      "BTCUSDT", "1h",
      startTime = as.POSIXct("2024-01-01", tz = "UTC"),
      endTime = as.POSIXct("2024-06-01", tz = "UTC"),
      fetch_all = TRUE, sleep = 0.5
    )
    }

------------------------------------------------------------------------

### Method `get_mark_price()`

Get Mark Price

Retrieves the mark price, index price, and funding rate information for
a specific symbol or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/premiumIndex`

#### Official Documentation

[Binance Futures Mark
Price](https://binance-docs.github.io/apidocs/futures/en/#mark-price)
Verified: 2026-03-10

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

  Character or NULL; trading pair (e.g., `"BTCUSDT"`). If NULL, returns
  data for all symbols.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `symbol` (character): Trading pair identifier.

- `mark_price` (character): Current mark price.

- `index_price` (character): Current index price.

- `estimated_settle_price` (character): Estimated settlement price.

- `last_funding_rate` (character): Last funding rate.

- `next_funding_time` (POSIXct): Next funding time.

- `interest_rate` (character): Interest rate.

- `time` (POSIXct): Data timestamp.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    mark <- futures$get_mark_price("BTCUSDT")
    print(mark)

    # All symbols
    all_marks <- futures$get_mark_price()
    print(all_marks)
    }

------------------------------------------------------------------------

### Method `get_funding_rate()`

Get Funding Rate History

Retrieves historical funding rate data for a symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/fundingRate`

#### Official Documentation

[Binance Futures Funding Rate
History](https://binance-docs.github.io/apidocs/futures/en/#get-funding-rate-history)
Verified: 2026-03-10

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
      startTime = NULL,
      endTime = NULL,
      limit = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `startTime`:

  POSIXct or numeric or NULL; start time (ms or POSIXct).

- `endTime`:

  POSIXct or numeric or NULL; end time (ms or POSIXct).

- `limit`:

  Integer or NULL; max results (default 100, max 1000).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `symbol` (character): Trading pair identifier.

- `funding_rate` (character): Funding rate value.

- `funding_time` (POSIXct): Funding timestamp.

- `mark_price` (character): Mark price at funding time.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    rates <- futures$get_funding_rate("BTCUSDT", limit = 10)
    print(rates)
    }

------------------------------------------------------------------------

### Method `get_24hr_stats()`

Get 24hr Ticker Statistics

Retrieves rolling 24-hour price change statistics for a futures symbol
or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/ticker/24hr`

#### Official Documentation

[Binance Futures 24hr
Ticker](https://binance-docs.github.io/apidocs/futures/en/#24hr-ticker-price-change-statistics)
Verified: 2026-03-10

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

  Character or NULL; trading pair (e.g., `"BTCUSDT"`). If NULL, returns
  data for all symbols.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `symbol` (character): Trading pair identifier.

- `price_change` (character): Absolute price change over 24h.

- `price_change_percent` (character): Percentage price change over 24h.

- `weighted_avg_price` (character): Volume-weighted average price over
  24h.

- `last_price` (character): Most recent trade price.

- `volume` (character): Total base asset volume in 24h.

- `quote_volume` (character): Total quote asset volume in 24h.

- `open_time` (POSIXct): Start of the 24h window.

- `close_time` (POSIXct): End of the 24h window.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    stats <- futures$get_24hr_stats("BTCUSDT")
    print(stats[, .(symbol, last_price, price_change_percent, volume)])
    }

------------------------------------------------------------------------

### Method `get_ticker()`

Get Symbol Price Ticker

Retrieves the latest price for a specific futures symbol or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/ticker/price`

#### Official Documentation

[Binance Futures Symbol Price
Ticker](https://binance-docs.github.io/apidocs/futures/en/#symbol-price-ticker)
Verified: 2026-03-10

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

  Character or NULL; trading pair (e.g., `"BTCUSDT"`). If NULL, returns
  data for all symbols.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `symbol` (character): Trading pair identifier.

- `price` (character): Latest traded price as string.

- `time` (POSIXct): Timestamp (if present in response).

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    ticker <- futures$get_ticker("BTCUSDT")
    print(ticker)
    }

------------------------------------------------------------------------

### Method `get_book_ticker()`

Get Best Bid/Ask (Book Ticker)

Retrieves the best bid and ask price and quantity for a futures symbol
or all symbols.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/ticker/bookTicker`

#### Official Documentation

[Binance Futures Symbol Order Book
Ticker](https://binance-docs.github.io/apidocs/futures/en/#symbol-order-book-ticker)
Verified: 2026-03-10

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

  Character or NULL; trading pair (e.g., `"BTCUSDT"`). If NULL, returns
  data for all symbols.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `symbol` (character): Trading pair identifier.

- `bid_price` (character): Best bid price.

- `bid_qty` (character): Quantity available at best bid.

- `ask_price` (character): Best ask price.

- `ask_qty` (character): Quantity available at best ask.

- `time` (POSIXct): Timestamp (if present in response).

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    book <- futures$get_book_ticker("BTCUSDT")
    print(book)
    }

------------------------------------------------------------------------

### Method `get_open_interest()`

Get Open Interest

Retrieves the current open interest for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/openInterest`

#### Official Documentation

[Binance Futures Open
Interest](https://binance-docs.github.io/apidocs/futures/en/#open-interest)
Verified: 2026-03-10

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

  Character; trading pair (e.g., `"BTCUSDT"`).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `symbol` (character): Trading pair identifier.

- `open_interest` (character): Current open interest.

- `time` (POSIXct): Timestamp (if present in response).

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    oi <- futures$get_open_interest("BTCUSDT")
    print(oi)
    }

------------------------------------------------------------------------

### Method `get_depth()`

Get Order Book Depth

Retrieves the order book (bids and asks) for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/depth`

#### Official Documentation

[Binance Futures Order
Book](https://binance-docs.github.io/apidocs/futures/en/#order-book)
Verified: 2026-03-10

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

  Character; trading pair (e.g., `"BTCUSDT"`).

- `limit`:

  Integer or NULL; depth limit. Valid values: 5, 10, 20, 50, 100,
  500, 1000. Default 500.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `last_update_id` (character): Sequence ID for orderbook
  synchronisation.

- `side` (character): `"bid"` or `"ask"`.

- `price` (numeric): Price level.

- `size` (numeric): Available size at this price level.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    depth <- futures$get_depth("BTCUSDT", limit = 20)
    print(depth)
    }

------------------------------------------------------------------------

### Method `get_trades()`

Get Recent Trades

Retrieves the most recent trades for a futures symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/trades`

#### Official Documentation

[Binance Futures Recent Trades
List](https://binance-docs.github.io/apidocs/futures/en/#recent-trades-list)
Verified: 2026-03-10

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

  Character; trading pair (e.g., `"BTCUSDT"`).

- `limit`:

  Integer or NULL; max results (default 500, max 1000).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `id` (integer): Unique trade identifier.

- `price` (character): Trade execution price.

- `qty` (character): Base asset quantity traded.

- `quote_qty` (character): Quote asset quantity traded.

- `time` (POSIXct): Trade execution time.

- `is_buyer_maker` (logical): `TRUE` if the buyer was the maker.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    trades <- futures$get_trades("BTCUSDT", limit = 10)
    print(trades)
    }

------------------------------------------------------------------------

### Method `get_index_price_klines()`

Get Index Price Klines

Retrieves historical index price kline/candlestick data for a pair.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/indexPriceKlines`

#### Official Documentation

[Binance Futures Index Price Kline/Candlestick
Data](https://binance-docs.github.io/apidocs/futures/en/#index-price-kline-candlestick-data)
Verified: 2026-03-10

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
      startTime = NULL,
      endTime = NULL,
      limit = NULL
    )

#### Arguments

- `pair`:

  Character; underlying pair (e.g., `"BTCUSDT"`).

- `interval`:

  Character; candle interval. Valid values: `"1s"`, `"1m"`, `"3m"`,
  `"5m"`, `"15m"`, `"30m"`, `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`,
  `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.

- `startTime`:

  POSIXct or numeric or NULL; start time (ms or POSIXct).

- `endTime`:

  POSIXct or numeric or NULL; end time (ms or POSIXct).

- `limit`:

  Integer or NULL; max results (default 500, max 1500).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `open_time` (POSIXct): Candle open time.

- `open` (numeric): Opening price.

- `high` (numeric): Highest price.

- `low` (numeric): Lowest price.

- `close` (numeric): Closing price.

- `volume` (numeric): Trading volume.

- `close_time` (POSIXct): Candle close time.

- `quote_volume` (numeric): Quote asset volume.

- `trades` (integer): Number of trades.

- `taker_buy_base_volume` (numeric): Taker buy base asset volume.

- `taker_buy_quote_volume` (numeric): Taker buy quote asset volume.

- `ignore` (character): Unused field.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    klines <- futures$get_index_price_klines("BTCUSDT", "1h", limit = 24)
    print(klines)
    }

------------------------------------------------------------------------

### Method `get_mark_price_klines()`

Get Mark Price Klines

Retrieves historical mark price kline/candlestick data for a symbol.

#### API Endpoint

`GET https://fapi.binance.com/fapi/v1/markPriceKlines`

#### Official Documentation

[Binance Futures Mark Price Kline/Candlestick
Data](https://binance-docs.github.io/apidocs/futures/en/#mark-price-kline-candlestick-data)
Verified: 2026-03-10

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
      startTime = NULL,
      endTime = NULL,
      limit = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `interval`:

  Character; candle interval. Valid values: `"1s"`, `"1m"`, `"3m"`,
  `"5m"`, `"15m"`, `"30m"`, `"1h"`, `"2h"`, `"4h"`, `"6h"`, `"8h"`,
  `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.

- `startTime`:

  POSIXct or numeric or NULL; start time (ms or POSIXct).

- `endTime`:

  POSIXct or numeric or NULL; end time (ms or POSIXct).

- `limit`:

  Integer or NULL; max results (default 500, max 1500).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `open_time` (POSIXct): Candle open time.

- `open` (numeric): Opening price.

- `high` (numeric): Highest price.

- `low` (numeric): Lowest price.

- `close` (numeric): Closing price.

- `volume` (numeric): Trading volume.

- `close_time` (POSIXct): Candle close time.

- `quote_volume` (numeric): Quote asset volume.

- `trades` (integer): Number of trades.

- `taker_buy_base_volume` (numeric): Taker buy base asset volume.

- `taker_buy_quote_volume` (numeric): Taker buy quote asset volume.

- `ignore` (character): Unused field.

#### Examples

    \dontrun{
    futures <- BinanceFuturesData$new()
    klines <- futures$get_mark_price_klines("BTCUSDT", "1h", limit = 24)
    print(klines)
    }

------------------------------------------------------------------------

### Method `clone()`

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
## Method `BinanceFuturesData$get_exchange_info`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
info <- futures$get_exchange_info()
print(info[, .(symbol, contract_type, status, base_asset)])
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_klines`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
klines <- futures$get_klines("BTCUSDT", "1h", limit = 24)

# Fetch all candles across a large date range (multiple API calls)
all_klines <- futures$get_klines(
  "BTCUSDT", "1h",
  startTime = as.POSIXct("2024-01-01", tz = "UTC"),
  endTime = as.POSIXct("2024-06-01", tz = "UTC"),
  fetch_all = TRUE, sleep = 0.5
)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_mark_price`
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
## Method `BinanceFuturesData$get_funding_rate`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
rates <- futures$get_funding_rate("BTCUSDT", limit = 10)
print(rates)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_24hr_stats`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
stats <- futures$get_24hr_stats("BTCUSDT")
print(stats[, .(symbol, last_price, price_change_percent, volume)])
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_ticker`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
ticker <- futures$get_ticker("BTCUSDT")
print(ticker)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_book_ticker`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
book <- futures$get_book_ticker("BTCUSDT")
print(book)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_open_interest`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
oi <- futures$get_open_interest("BTCUSDT")
print(oi)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_depth`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
depth <- futures$get_depth("BTCUSDT", limit = 20)
print(depth)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_trades`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
trades <- futures$get_trades("BTCUSDT", limit = 10)
print(trades)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_index_price_klines`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
klines <- futures$get_index_price_klines("BTCUSDT", "1h", limit = 24)
print(klines)
} # }

## ------------------------------------------------
## Method `BinanceFuturesData$get_mark_price_klines`
## ------------------------------------------------

if (FALSE) { # \dontrun{
futures <- BinanceFuturesData$new()
klines <- futures$get_mark_price_klines("BTCUSDT", "1h", limit = 24)
print(klines)
} # }
```
