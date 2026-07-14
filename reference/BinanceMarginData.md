# BinanceMarginData: Margin Market Data Retrieval

Provides methods for retrieving margin-specific market data from
Binance, including cross/isolated margin pairs, price indices, interest
rate history, and margin data summaries.

Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Margin Pairs**: Retrieve available cross and isolated margin trading
  pairs.

- **Price Index**: Access margin price index for a symbol.

- **Interest Rates**: Get historical interest rate data for margin
  borrowing.

- **Margin Data**: Retrieve cross and isolated margin data including
  borrowing limits and interest rates.

### Usage

Most methods require authentication (valid API key and secret).
`get_price_index` is a public endpoint requiring no authentication.

### Official Documentation

[Binance Margin
Account/Trade](https://developers.binance.com/docs/margin_trading/trade)

### Endpoints Covered

|                           |                                         |      |
|---------------------------|-----------------------------------------|------|
| Method                    | Endpoint                                | Auth |
| get_all_pairs             | GET /sapi/v1/margin/allPairs            | Yes  |
| get_isolated_pairs        | GET /sapi/v1/margin/isolated/allPairs   | Yes  |
| get_price_index           | GET /sapi/v1/margin/priceIndex          | No   |
| get_interest_rate_history | GET /sapi/v1/margin/interestRateHistory | Yes  |
| get_cross_margin_data     | GET /sapi/v1/margin/crossMarginData     | Yes  |
| get_isolated_margin_data  | GET /sapi/v1/margin/isolatedMarginData  | Yes  |

## Super classes

[`connectcore::RestClient`](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
-\>
[`BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceMarginData`

## Methods

### Public methods

- [`BinanceMarginData$get_all_pairs()`](#method-BinanceMarginData-get_all_pairs)

- [`BinanceMarginData$get_isolated_pairs()`](#method-BinanceMarginData-get_isolated_pairs)

- [`BinanceMarginData$get_price_index()`](#method-BinanceMarginData-get_price_index)

- [`BinanceMarginData$get_interest_rate_history()`](#method-BinanceMarginData-get_interest_rate_history)

- [`BinanceMarginData$get_cross_margin_data()`](#method-BinanceMarginData-get_cross_margin_data)

- [`BinanceMarginData$get_isolated_margin_data()`](#method-BinanceMarginData-get_isolated_margin_data)

- [`BinanceMarginData$clone()`](#method-BinanceMarginData-clone)

Inherited methods

- [`BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### `BinanceMarginData$get_all_pairs()`

Get All Cross Margin Pairs

Retrieves a list of all cross margin trading pairs available on Binance.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/allPairs`

#### Official Documentation

[Binance Get All Cross Margin
Pairs](https://developers.binance.com/docs/margin_trading/market-data/Get-All-Cross-Margin-Pairs)

Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/allPairs' \
      -H 'X-MBX-APIKEY: <key>'

#### JSON Response

    [
      {
        "base": "BTC",
        "id": 351637150,
        "isBuyAllowed": true,
        "isMarginTrade": true,
        "isSellAllowed": true,
        "quote": "USDT",
        "symbol": "BTCUSDT"
      },
      {
        "base": "ETH",
        "id": 351637155,
        "isBuyAllowed": true,
        "isMarginTrade": true,
        "isSellAllowed": true,
        "quote": "USDT",
        "symbol": "ETHUSDT"
      }
    ]

#### Usage

    BinanceMarginData$get_all_pairs(recv_window = NULL)

#### Arguments

- `recv_window`:

  (scalar\<count\>?) request validity window in milliseconds.

#### Returns

(data.table \| promise\<data.table\>) one row per pair:

- base (character) Base asset code (e.g., `"BTC"`).

- id (numeric) Pair identifier.

- is_buy_allowed (logical) Whether buying is allowed.

- is_margin_trade (logical) Whether margin trading is enabled.

- is_sell_allowed (logical) Whether selling is allowed.

- quote (character) Quote asset code (e.g., `"USDT"`).

- symbol (character) Trading pair identifier (e.g., `"BTCUSDT"`).

#### Examples

    margin <- BinanceMarginData$new()
    pairs <- margin$get_all_pairs()
    print(pairs)

------------------------------------------------------------------------

### `BinanceMarginData$get_isolated_pairs()`

Get All Isolated Margin Pairs

Retrieves a list of all isolated margin trading pairs available on
Binance.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/isolated/allPairs`

#### Official Documentation

[Binance Get All Isolated Margin
Symbol](https://developers.binance.com/docs/margin_trading/market-data/Get-All-Isolated-Margin-Symbol)

Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/isolated/allPairs' \
      -H 'X-MBX-APIKEY: <key>'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "base": "BTC",
        "quote": "USDT",
        "isMarginTrade": true,
        "isBuyAllowed": true,
        "isSellAllowed": true
      },
      {
        "symbol": "ETHUSDT",
        "base": "ETH",
        "quote": "USDT",
        "isMarginTrade": true,
        "isBuyAllowed": true,
        "isSellAllowed": true
      }
    ]

#### Usage

    BinanceMarginData$get_isolated_pairs(recv_window = NULL)

#### Arguments

- `recv_window`:

  (scalar\<count\>?) request validity window in milliseconds.

#### Returns

(data.table \| promise\<data.table\>) one row per pair:

- symbol (character) Trading pair identifier (e.g., `"BTCUSDT"`).

- base (character) Base asset code (e.g., `"BTC"`).

- quote (character) Quote asset code (e.g., `"USDT"`).

- is_margin_trade (logical) Whether margin trading is enabled.

- is_buy_allowed (logical) Whether buying is allowed.

- is_sell_allowed (logical) Whether selling is allowed.

#### Examples

    margin <- BinanceMarginData$new()
    pairs <- margin$get_isolated_pairs()
    print(pairs)

------------------------------------------------------------------------

### `BinanceMarginData$get_price_index()`

Get Margin Price Index

Retrieves the margin price index for a given symbol. This is a public
endpoint that does not require authentication.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/priceIndex`

#### Official Documentation

[Binance Query Margin
PriceIndex](https://developers.binance.com/docs/margin_trading/market-data/Query-Margin-PriceIndex)

Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/priceIndex?symbol=BTCUSDT'

#### JSON Response

    { "calcTime": 1562046418000, "price": "67232.90000000", "symbol": "BTCUSDT" }

#### Usage

    BinanceMarginData$get_price_index(symbol)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row:

- calc_time (POSIXct) Calculation time as UTC datetime.

- price (character) Margin price index value.

- symbol (character) Trading pair identifier.

#### Examples

    margin <- BinanceMarginData$new()
    idx <- margin$get_price_index("BTCUSDT")
    print(idx)

------------------------------------------------------------------------

### `BinanceMarginData$get_interest_rate_history()`

Get Interest Rate History

Retrieves historical interest rate data for a given asset.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/interestRateHistory`

#### Official Documentation

[Binance Query Margin Interest Rate
History](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Query-Margin-Interest-Rate-History)

Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/interestRateHistory?asset=BTC' \
      -H 'X-MBX-APIKEY: <key>'

#### JSON Response

    [
      {
        "asset": "BTC",
        "dailyInterestRate": "0.00025000",
        "timestamp": 1611544731000,
        "vipLevel": 0
      },
      {
        "asset": "BTC",
        "dailyInterestRate": "0.00020000",
        "timestamp": 1611458331000,
        "vipLevel": 0
      }
    ]

#### Usage

    BinanceMarginData$get_interest_rate_history(
      asset,
      vip_level = NULL,
      start_time = NULL,
      end_time = NULL,
      recv_window = NULL
    )

#### Arguments

- `asset`:

  (scalar\<character\>) asset code (e.g., `"BTC"`).

- `vip_level`:

  (scalar\<count\>?) VIP level to query. Defaults to user's VIP level.

- `start_time`:

  (scalar\<numeric\>?) start time in milliseconds.

- `end_time`:

  (scalar\<numeric\>?) end time in milliseconds.

- `recv_window`:

  (scalar\<count\>?) request validity window in milliseconds.

#### Returns

(data.table \| promise\<data.table\>) one row per rate record:

- asset (character) Asset code (e.g., `"BTC"`).

- daily_interest_rate (character) Daily interest rate as string.

- timestamp (POSIXct) Record timestamp as UTC datetime.

- vip_level (integer) VIP level for this rate.

#### Examples

    margin <- BinanceMarginData$new()
    history <- margin$get_interest_rate_history("BTC")
    print(history)

------------------------------------------------------------------------

### `BinanceMarginData$get_cross_margin_data()`

Get Cross Margin Data

Retrieves cross margin data including borrowing limits and interest
rates.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/crossMarginData`

#### Official Documentation

[Binance Query Cross Margin Fee
Data](https://developers.binance.com/docs/margin_trading/account/Query-Cross-Margin-Fee-Data)

Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/crossMarginData' \
      -H 'X-MBX-APIKEY: <key>'

#### JSON Response

    [
      {
        "vipLevel": 0,
        "coin": "BTC",
        "transferIn": true,
        "transferOut": true,
        "borrowable": true,
        "dailyInterest": "0.00026125",
        "yearlyInterest": "0.0953",
        "marginablePairs": ["BTCUSDT", "BTCBUSD"]
      },
      {
        "vipLevel": 0,
        "coin": "ETH",
        "transferIn": true,
        "transferOut": true,
        "borrowable": true,
        "dailyInterest": "0.00027400",
        "yearlyInterest": "0.1000",
        "marginablePairs": ["ETHUSDT", "ETHBUSD", "ETHBTC"]
      }
    ]

#### Usage

    BinanceMarginData$get_cross_margin_data(
      vip_level = NULL,
      coin = NULL,
      recv_window = NULL
    )

#### Arguments

- `vip_level`:

  (scalar\<count\>?) VIP level to query. Defaults to user's VIP level.

- `coin`:

  (scalar\<character\>?) specific coin to query (e.g., `"BTC"`).

- `recv_window`:

  (scalar\<count\>?) request validity window in milliseconds.

#### Returns

(data.table \| promise\<data.table\>) one row per coin-pair combination:

- vip_level (integer) VIP level tier.

- coin (character) Coin code (e.g., `"BTC"`).

- transfer_in (logical) Whether transfer in is allowed.

- transfer_out (logical) Whether transfer out is allowed.

- borrowable (logical) Whether borrowing is allowed.

- daily_interest (character) Daily interest rate as string.

- yearly_interest (character) Yearly interest rate as string.

- marginable_pair (character) Marginable trading pair (one row per
  coin-pair combination).

When a coin has multiple marginable pairs, coin-level fields are
repeated on each row.

#### Examples

    margin <- BinanceMarginData$new()
    data <- margin$get_cross_margin_data()
    print(data)

------------------------------------------------------------------------

### `BinanceMarginData$get_isolated_margin_data()`

Get Isolated Margin Data

Retrieves isolated margin data including leverage and borrowing limits.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/isolatedMarginData`

#### Official Documentation

[Binance Query Isolated Margin Fee
Data](https://developers.binance.com/docs/margin_trading/account/Query-Isolated-Margin-Fee-Data)

Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/isolatedMarginData' \
      -H 'X-MBX-APIKEY: <key>'

#### JSON Response

    [
      {
        "vipLevel": 0,
        "symbol": "BTCUSDT",
        "leverage": "10",
        "data": [
          {
            "coin": "BTC",
            "dailyInterest": "0.00026125",
            "borrowLimit": "9.00000000"
          },
          {
            "coin": "USDT",
            "dailyInterest": "0.000475",
            "borrowLimit": "270000.00000000"
          }
        ]
      },
      {
        "vipLevel": 0,
        "symbol": "ETHUSDT",
        "leverage": "10",
        "data": [
          {
            "coin": "ETH",
            "dailyInterest": "0.00027400",
            "borrowLimit": "90.00000000"
          },
          {
            "coin": "USDT",
            "dailyInterest": "0.000475",
            "borrowLimit": "270000.00000000"
          }
        ]
      }
    ]

#### Usage

    BinanceMarginData$get_isolated_margin_data(
      vip_level = NULL,
      symbol = NULL,
      recv_window = NULL
    )

#### Arguments

- `vip_level`:

  (scalar\<count\>?) VIP level to query. Defaults to user's VIP level.

- `symbol`:

  (scalar\<character\>?) specific symbol to query (e.g., `"BTCUSDT"`).

- `recv_window`:

  (scalar\<count\>?) request validity window in milliseconds.

#### Returns

(data.table \| promise\<data.table\>) one row per symbol:

- vip_level (integer) VIP level tier.

- symbol (character) Trading pair identifier.

- leverage (character) Maximum leverage available.

- data (list) Nested list of coin-level margin details.

#### Examples

    margin <- BinanceMarginData$new()
    data <- margin$get_isolated_margin_data()
    print(data)

------------------------------------------------------------------------

### `BinanceMarginData$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceMarginData$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous usage
margin <- BinanceMarginData$new()
pairs <- margin$get_all_pairs()
print(pairs)

# Public endpoint (no auth needed)
margin_pub <- BinanceMarginData$new()
idx <- margin_pub$get_price_index("BTCUSDT")
print(idx)

# Asynchronous usage
margin_async <- BinanceMarginData$new(async = TRUE)
main <- coro::async(function() {
  pairs <- await(margin_async$get_all_pairs())
  print(pairs)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceMarginData$get_all_pairs()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMarginData$new()
pairs <- margin$get_all_pairs()
print(pairs)
} # }

## ------------------------------------------------
## Method `BinanceMarginData$get_isolated_pairs()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMarginData$new()
pairs <- margin$get_isolated_pairs()
print(pairs)
} # }

## ------------------------------------------------
## Method `BinanceMarginData$get_price_index()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMarginData$new()
idx <- margin$get_price_index("BTCUSDT")
print(idx)
} # }

## ------------------------------------------------
## Method `BinanceMarginData$get_interest_rate_history()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMarginData$new()
history <- margin$get_interest_rate_history("BTC")
print(history)
} # }

## ------------------------------------------------
## Method `BinanceMarginData$get_cross_margin_data()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMarginData$new()
data <- margin$get_cross_margin_data()
print(data)
} # }

## ------------------------------------------------
## Method `BinanceMarginData$get_isolated_margin_data()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMarginData$new()
data <- margin$get_isolated_margin_data()
print(data)
} # }
```
