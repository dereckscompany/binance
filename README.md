
# binance

<!-- badges: start -->

[![R-CMD-check](https://github.com/dereckmezquita/binance/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dereckmezquita/binance/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

An R API wrapper for the [Binance](https://www.binance.com/)
cryptocurrency exchange. Provides R6 classes for spot market data,
trading, account management, deposits, withdrawals, and sub-accounts.
Supports both synchronous and asynchronous (promise-based) operation via
httr2.

## Disclaimer

This software is provided “as is”, without warranty of any kind. **This
package interacts with live cryptocurrency exchange accounts and can
execute real trades, transfers, and withdrawals involving real money.**
By using this package you accept full responsibility for any financial
losses, erroneous transactions, or other damages that may result. Always
test with small amounts first, use API key permissions to restrict
access to only what you need, and never share your API credentials. The
author(s) and contributor(s) are not liable for any financial loss or
damage arising from the use of this software.

We invite you to read the source code and make contributions if you find
a bug or wish to make an improvement.

## Design Philosophy

All API responses are returned as `data.table` objects with two
transformations applied:

1.  **snake_case column names** — camelCase keys from the JSON response
    (e.g. `insertTime`, `quoteQty`) are converted to snake_case
    (`insert_time`, `quote_qty`) via a mechanical transformation. No
    columns are renamed beyond this.

2.  **Millisecond timestamps to POSIXct** — Columns containing
    epoch-millisecond timestamps are converted to `POSIXct` in-place
    under their snake_case name (e.g. `insertTime` becomes `insert_time`
    as a `POSIXct`).

That’s it. **No fields are dropped and no columns are renamed** beyond
the camelCase-to-snake_case conversion. If a column exists in the
Binance API response, it will exist in the returned `data.table`. If you
don’t need a column, drop it yourself.

The only exception is klines (candlestick data), where Binance returns
positional arrays instead of named objects. These are assigned
descriptive column names (`open_time`, `open`, `high`, `low`, `close`,
`volume`, `close_time`, etc.) matching the Binance documentation.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("dereckmezquita/binance")
```

## Setup

Set your API credentials as environment variables in `.Renviron`:

``` bash
BINANCE_API_ENDPOINT = "https://api.binance.com"
BINANCE_API_KEY = your-api-key
BINANCE_API_SECRET = your-api-secret
```

If you don’t have a key, visit the [Binance API
documentation](https://binance-docs.github.io/apidocs/).

## Quick Start – Market Data

Market data endpoints are public and require no authentication.

``` r
market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)
```

### Price Ticker

``` r
market$get_ticker("BTCUSDT")
#>     symbol          price
#>     <char>         <char>
#> 1: BTCUSDT 67232.90000000
```

### Klines (Candlestick Data)

``` r
klines <- market$get_klines("BTCUSDT", interval = "1h", limit = 5)
klines[, .(open_time, open, high, low, close, volume)]
#>     open_time      open   high      low    close   volume
#>        <POSc>     <num>  <num>    <num>    <num>    <num>
#> 1: 2017-07-03 0.0163479 0.8000 0.015758 0.015771 148976.1
#> 2: 2017-07-10 0.0157710 0.0158 0.015730 0.015788  95432.0
#> 3: 2017-07-17 0.0157880 0.0159 0.015700 0.015850 120000.0
```

### Order Book Depth

``` r
depth <- market$get_depth("BTCUSDT", limit = 5)
depth
```

### 24hr Statistics

``` r
stats <- market$get_24hr_stats("BTCUSDT")
stats[, .(symbol, last_price, price_change_percent, volume)]
#>     symbol     last_price price_change_percent        volume
#>     <char>         <char>               <char>        <char>
#> 1: BTCUSDT 67232.90000000               -1.140 3456.78901234
```

## Trading

Trading endpoints require authentication. Use `add_order_test()` to
validate order parameters without placing a real order.

``` r
trading <- BinanceTrading$new(keys = KEYS, base_url = BASE)
```

### Test Order (No Execution)

``` r
trading$add_order_test(
  type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
  price = 50000, quantity = 0.0001
)
#> Null data.table (0 rows and 0 cols)
```

### Query an Order

``` r
trading$get_order("BTCUSDT", orderId = 12345)
```

### Get Open Orders

``` r
trading$get_open_orders("BTCUSDT")
```

## Account

``` r
account <- BinanceAccount$new(keys = KEYS, base_url = BASE)
```

### Account Info

``` r
info <- account$get_account_info()
info[, .(maker_commission, taker_commission, can_trade, account_type)]
#>    maker_commission taker_commission can_trade account_type
#>               <int>            <int>    <lgcl>       <char>
#> 1:               15               15      TRUE         SPOT
```

### Trade History

``` r
account$get_trades("BTCUSDT")
```

## Margin Trading

Margin endpoints use the same credential setup. Here is a brief
overview:

``` r
margin <- BinanceMargin$new(keys = KEYS, base_url = BASE)
```

### Margin Account

``` r
acct <- margin$get_account()
acct[, .(margin_level, total_asset_of_btc, total_net_asset_of_btc)]
#>    margin_level total_asset_of_btc total_net_asset_of_btc
#>          <char>             <char>                 <char>
#> 1:  11.64405625         6.82000000             6.23366785
```

### Max Borrowable

``` r
margin$get_max_borrowable(asset = "USDT")
#>        amount borrow_limit
#>        <char>       <char>
#> 1: 1.69248805           60
```

### Margin Trades

``` r
margin$get_trades("BTCUSDT")
```

## Futures

### Futures Market Data

``` r
fdata <- BinanceFuturesData$new(keys = KEYS, base_url = FBASE)
```

#### Mark Price and Funding Rate

``` r
fdata$get_mark_price("BTCUSDT")
```

#### Funding Rate History

``` r
fdata$get_funding_rate("BTCUSDT", limit = 3)
```

#### Open Interest

``` r
fdata$get_open_interest("BTCUSDT")
```

### Futures Trading

``` r
futures <- BinanceFutures$new(keys = KEYS, base_url = FBASE)
```

#### Positions

``` r
futures$get_positions("BTCUSDT")
```

#### Futures Test Order

``` r
futures$add_order_test(
  symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
  quantity = 0.001, price = 50000, timeInForce = "GTC"
)
#> Null data.table (0 rows and 0 cols)
```

#### Set Leverage

``` r
futures$set_leverage("BTCUSDT", leverage = 10)
#>    leverage max_notional_value  symbol
#>       <int>             <char>  <char>
#> 1:       20           25000000 BTCUSDT
```

## Async Usage

All classes accept `async = TRUE`, causing methods to return promises.
Use `coro::async()` to write sequential-looking async code:

``` r
market_async <- BinanceMarketData$new(async = TRUE)

main <- coro::async(function() {
  ticker <- await(market_async$get_ticker("BTCUSDT"))
  klines <- await(market_async$get_klines("BTCUSDT", "1h", limit = 10))

  print(ticker)
  print(klines)
})

main()
while (!later::loop_empty()) later::run_now()
```

## Citation

If you use this package in your work, please cite it:

``` r
citation("binance")
```

> Mezquita, D. (2026). binance: R API Wrapper to Binance Cryptocurrency
> Exchange. R package version 0.0.1.

## Licence

MIT © [Dereck Mezquita](https://github.com/dereckmezquita)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0002--9307--6762-green)](https://orcid.org/0000-0002-9307-6762).
See [LICENSE.md](LICENSE.md) for the full text, including the citation
clause.
