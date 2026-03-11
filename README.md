
# binance

<!-- badges: start -->

[![R-CMD-check](https://github.com/dereckmezquita/binance/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dereckmezquita/binance/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

An R API wrapper for the [Binance](https://www.binance.com/)
cryptocurrency exchange. Provides `R6` classes for spot market data,
trading, account management, deposits, withdrawals, and sub-accounts.
Supports both synchronous and asynchronous (promise based) operation via
`httr2`.

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

1.  **snake_case column names** - camelCase keys from the JSON response
    (e.g. `insertTime`, `quoteQty`) are converted to snake_case
    (`insert_time`, `quote_qty`). No columns are renamed beyond.
2.  **type coercion** - known columns are type coerced in `data.table`
    before return.

That’s it. **No fields are dropped and no columns are renamed** beyond
snake case conversion. If a column exists in the Binance API response,
it will exist in the returned `data.table`. If you don’t need a column,
drop it yourself.

- The only exception is klines (candlestick data), where Binance returns
  positional arrays instead of named objects. These are assigned
  descriptive column names (`open_time`, `open`, `high`, `low`, `close`,
  `volume`, `close_time`, etc.) matching the Binance documentation.

## Available Classes

| Class | Purpose | Auth Required |
|----|----|:--:|
| `BinanceMarketData` | Spot market data: tickers, klines, depth, trades, exchange info | No |
| `BinanceTrading` | Spot order placement, query, and cancellation | Yes |
| `BinanceOcoOrders` | One-Cancels-Other order management | Yes |
| `BinanceAccount` | Account info and trade history | Yes |
| `BinanceDeposit` | Deposit addresses and deposit history | Yes |
| `BinanceWithdrawal` | Withdrawal submission and history | Yes |
| `BinanceTransfer` | Internal transfers between wallet types (spot, margin, futures) | Yes |
| `BinanceSubAccount` | Sub-account listing and management | Yes |
| `BinanceEarn` | Simple Earn: flexible savings products and positions | Yes |
| `BinanceMarginData` | Margin pairs, price index, interest rates, cross/isolated data | Mixed |
| `BinanceMargin` | Margin borrowing, repayment, orders, and account queries | Yes |
| `BinanceFuturesData` | Futures exchange info, mark price, funding rates, klines | No |
| `BinanceFutures` | Futures order placement, positions, leverage, account queries | Yes |
| `BinanceBase` | Internal base class (not used directly) | — |

All classes accept an `async = TRUE` argument at construction and share
a common `time_source` parameter for clock drift correction.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("dereckmezquita/binance")
```

## Setup

``` r
# special mock for local build
box::use(
  binance[
    get_api_keys,
    get_futures_base_url
  ],
  ./tests/testthat/mock_router[mock_router]
)

KEYS <- get_api_keys(
  api_key = "fake-key",
  api_secret = "fake-secret"
)

BASE <- "https://api.binance.com"
FBASE <- "https://fapi.binance.com"

options(httr2_mock = mock_router)

# normal imports
box::use(
  binance[
    BinanceMarketData,
    BinanceTrading,
    BinanceAccount,
    BinanceMargin,
    BinanceFutures,
    BinanceFuturesData
  ]
)
```

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
```

    #>     symbol          price
    #>     <char>         <char>
    #> 1: BTCUSDT 67232.90000000

### Klines (Candlestick Data)

``` r
market$get_klines("BTCUSDT", interval = "1h", limit = 5)
```

    #>     open_time      open   high      low    close   volume          close_time
    #>        <POSc>     <num>  <num>    <num>    <num>    <num>              <POSc>
    #> 1: 2017-07-03 0.0163479 0.8000 0.015758 0.015771 148976.1 2017-07-09 23:59:59
    #> 2: 2017-07-10 0.0157710 0.0158 0.015730 0.015788  95432.0 2017-07-16 23:59:59
    #> 3: 2017-07-17 0.0157880 0.0159 0.015700 0.015850 120000.0 2017-07-23 23:59:59
    #>    quote_volume trades taker_buy_base_volume taker_buy_quote_volume ignore
    #>           <num>  <int>                 <num>                  <num> <char>
    #> 1:     2434.191    308             1756.8740               28.46694      0
    #> 2:     1505.250    205              876.1235               13.82000      0
    #> 3:     1899.600    250              950.0000               15.06750      0

### Fetch All Klines (Large Date Ranges)

When you need historical data spanning more than 1000 candles, use
`fetch_all = TRUE`. This automatically segments the time range into
multiple API calls, deduplicates overlapping boundaries, and returns the
combined result:

``` r
# Fetch all 1h klines across a 5-month date range (multiple API calls)
market$get_klines(
  symbol = "BTCUSDT",
  interval = "1h",
  startTime = as.POSIXct("2024-01-01", tz = "UTC"),
  endTime = as.POSIXct("2024-06-01", tz = "UTC"),
  fetch_all = TRUE,
  sleep = 0.5
)
```

> **Note:** Large date ranges consume multiple API requests. Use the
> `sleep` parameter to avoid hitting Binance rate limits. For bulk
> multi-symbol downloads, see `binance_backfill_klines()`.

### Order Book Depth

``` r
market$get_depth("BTCUSDT", limit = 5)
```

    #>    last_update_id   side   price      size
    #>            <char> <char>   <num>     <num>
    #> 1:        1027024    bid 67232.8 0.4186184
    #> 2:        1027024    bid 67232.5 1.5000000
    #> 3:        1027024    bid 67230.0 0.8000000
    #> 4:        1027024    ask 67232.9 1.2480899
    #> 5:        1027024    ask 67233.5 0.5000000
    #> 6:        1027024    ask 67235.0 2.1000000

### 24hr Statistics

``` r
market$get_24hr_stats("BTCUSDT")
```

    #>     symbol  price_change price_change_percent weighted_avg_price
    #>     <char>        <char>               <char>             <char>
    #> 1: BTCUSDT -772.10000000               -1.140     67450.50000000
    #>    prev_close_price     last_price   last_qty      bid_price    bid_qty
    #>              <char>         <char>     <char>         <char>     <char>
    #> 1:   68005.00000000 67232.90000000 0.00100000 67232.80000000 0.41861839
    #>         ask_price    ask_qty     open_price     high_price      low_price
    #>            <char>     <char>         <char>         <char>         <char>
    #> 1: 67232.90000000 1.24808993 68005.00000000 68100.00000000 66800.00000000
    #>           volume       quote_volume           open_time          close_time
    #>           <char>             <char>              <POSc>              <POSc>
    #> 1: 3456.78901234 232456789.12000000 2024-10-16 10:04:19 2024-10-17 10:04:19
    #>    first_id last_id count
    #>       <int>   <int> <int>
    #> 1:     1000    2000  1001

## Trading

Trading endpoints require authentication. Use `add_order_test()` to
validate order parameters without placing a real order.

``` r
trading <- BinanceTrading$new(keys = KEYS, base_url = BASE)
```

### Test Order (No Execution)

``` r
trading$add_order_test(
  type = "LIMIT",
  symbol = "BTCUSDT",
  side = "BUY",
  price = 50000,
  quantity = 0.0001
)
```

    #>     symbol   side   type    status
    #>     <char> <char> <char>    <char>
    #> 1: BTCUSDT    BUY  LIMIT validated

### Query an Order

``` r
trading$get_order("BTCUSDT", orderId = 12345)
```

    #>     symbol order_id order_list_id        client_order_id          price
    #>     <char>    <int>         <int>                 <char>         <char>
    #> 1: BTCUSDT       28            -1 6gCrw2kRUAF9CvJDGP16IP 50000.00000000
    #>      orig_qty executed_qty cummulative_quote_qty status time_in_force   type
    #>        <char>       <char>                <char> <char>        <char> <char>
    #> 1: 0.00010000   0.00010000            5.00000000 FILLED           GTC  LIMIT
    #>      side stop_price iceberg_qty                time         update_time
    #>    <char>     <char>      <char>              <POSc>              <POSc>
    #> 1:    BUY 0.00000000  0.00000000 2017-10-11 12:32:56 2017-10-11 12:32:56
    #>    is_working orig_quote_order_qty working_time self_trade_prevention_mode
    #>        <lgcl>               <char>        <num>                     <char>
    #> 1:       TRUE           0.00000000 1.507725e+12                       NONE

### Get Open Orders

``` r
trading$get_open_orders("BTCUSDT")
```

    #>     symbol order_id order_list_id        client_order_id          price
    #>     <char>    <int>         <int>                 <char>         <char>
    #> 1: BTCUSDT       28            -1 6gCrw2kRUAF9CvJDGP16IP 50000.00000000
    #>      orig_qty executed_qty cummulative_quote_qty status time_in_force   type
    #>        <char>       <char>                <char> <char>        <char> <char>
    #> 1: 0.00010000   0.00000000            0.00000000    NEW           GTC  LIMIT
    #>      side stop_price iceberg_qty                time is_working
    #>    <char>     <char>      <char>              <POSc>     <lgcl>
    #> 1:    BUY 0.00000000  0.00000000 2017-10-11 12:32:56       TRUE
    #>    orig_quote_order_qty working_time self_trade_prevention_mode
    #>                  <char>        <num>                     <char>
    #> 1:           0.00000000 1.507725e+12                       NONE

## Account

``` r
account <- BinanceAccount$new(keys = KEYS, base_url = BASE)
```

### Account Info

``` r
account$get_account_info()
```

    #>    maker_commission taker_commission buyer_commission seller_commission
    #>               <int>            <int>            <int>             <int>
    #> 1:               15               15                0                 0
    #>    commission_rates can_trade can_withdraw can_deposit brokered
    #>              <list>    <lgcl>       <lgcl>      <lgcl>   <lgcl>
    #> 1:        <list[4]>      TRUE         TRUE        TRUE    FALSE
    #>    require_self_trade_prevention prevent_sor update_time account_type
    #>                           <lgcl>      <lgcl>       <int>       <char>
    #> 1:                         FALSE       FALSE   123456789         SPOT
    #>    permissions       uid
    #>         <list>     <int>
    #> 1:   <list[1]> 354937868

### Trade History

``` r
account$get_trades("BTCUSDT")
```

    #>     symbol    id order_id order_list_id          price        qty   quote_qty
    #>     <char> <int>    <int>         <int>         <char>     <char>      <char>
    #> 1: BTCUSDT 28457   100234            -1 67232.90000000 0.00100000 67.23290000
    #> 2: BTCUSDT 28458   100235            -1 67200.00000000 0.00050000 33.60000000
    #>    commission commission_asset                time is_buyer is_maker
    #>        <char>           <char>              <POSc>   <lgcl>   <lgcl>
    #> 1: 0.00000100              BTC 2017-07-12 13:19:09     TRUE    FALSE
    #> 2: 0.00000050              BTC 2017-07-12 13:19:10    FALSE     TRUE
    #>    is_best_match
    #>           <lgcl>
    #> 1:          TRUE
    #> 2:          TRUE

## Margin Trading

Margin endpoints use the same credential setup. Here is a brief
overview:

``` r
margin <- BinanceMargin$new(keys = KEYS, base_url = BASE)
```

### Margin Account

``` r
margin$get_account()
```

    #>    borrow_enabled margin_level total_asset_of_btc total_liability_of_btc
    #>            <lgcl>       <char>             <char>                 <char>
    #> 1:           TRUE  11.64405625         6.82000000             0.58633215
    #>    total_net_asset_of_btc trade_enabled transfer_enabled account_type
    #>                    <char>        <lgcl>           <lgcl>       <char>
    #> 1:             6.23366785          TRUE             TRUE       MARGIN
    #>    user_assets
    #>         <list>
    #> 1:   <list[2]>

### Max Borrowable

``` r
margin$get_max_borrowable(asset = "USDT")
```

    #>        amount borrow_limit
    #>        <char>       <char>
    #> 1: 1.69248805           60

### Margin Trades

``` r
margin$get_trades("BTCUSDT")
```

    #>     symbol    id order_id          price        qty   quote_qty commission
    #>     <char> <int>    <int>         <char>     <char>      <char>     <char>
    #> 1: BTCUSDT 28457   100234 67232.90000000 0.00100000 67.23290000 0.00000100
    #>    commission_asset                time is_buyer is_maker is_best_match
    #>              <char>              <POSc>   <lgcl>   <lgcl>        <lgcl>
    #> 1:              BTC 2017-07-12 13:19:09     TRUE    FALSE          TRUE
    #>    is_isolated
    #>         <lgcl>
    #> 1:       FALSE

## Futures

### Futures Market Data

``` r
fdata <- BinanceFuturesData$new(keys = KEYS, base_url = FBASE)
```

#### Mark Price and Funding Rate

``` r
fdata$get_mark_price("BTCUSDT")
```

    #>     symbol     mark_price    index_price estimated_settle_price
    #>     <char>         <char>         <char>                 <char>
    #> 1: BTCUSDT 67232.90000000 67230.50000000         67231.70000000
    #>    last_funding_rate   next_funding_time interest_rate                time
    #>               <char>              <POSc>        <char>              <POSc>
    #> 1:        0.00010000 2022-08-26 06:00:00    0.00010000 2022-08-26 05:52:26

#### Funding Rate History

``` r
fdata$get_funding_rate("BTCUSDT", limit = 3)
```

    #>     symbol funding_rate        funding_time     mark_price
    #>     <char>       <char>              <POSc>         <char>
    #> 1: BTCUSDT   0.00010000 2022-08-26 06:00:00 67232.90000000
    #> 2: BTCUSDT   0.00012000 2022-08-26 14:00:00 67500.00000000

#### Open Interest

``` r
fdata$get_open_interest("BTCUSDT")
```

    #>     symbol open_interest                time
    #>     <char>        <char>              <POSc>
    #> 1: BTCUSDT     12345.678 2022-08-26 05:52:26

### Futures Trading

``` r
futures <- BinanceFutures$new(keys = KEYS, base_url = FBASE)
```

#### Positions

``` r
futures$get_positions("BTCUSDT")
```

    #>     symbol position_amt entry_price break_even_price mark_price
    #>     <char>       <char>      <char>           <char>     <char>
    #> 1: BTCUSDT        0.001    50000.00         50025.00   67232.90
    #>    un_realized_profit liquidation_price leverage max_notional_value margin_type
    #>                <char>            <char>   <char>             <char>      <char>
    #> 1:        17.23290000                 0       20           25000000       cross
    #>    isolated_margin is_auto_add_margin position_side    notional isolated_wallet
    #>             <char>             <char>        <char>      <char>          <char>
    #> 1:      0.00000000              false          BOTH 67.23290000               0
    #>            update_time
    #>                 <POSc>
    #> 1: 2022-08-26 05:52:26

#### Futures Test Order

``` r
futures$add_order_test(
  symbol = "BTCUSDT",
  side = "BUY",
  type = "LIMIT",
  quantity = 0.001,
  price = 50000,
  timeInForce = "GTC"
)
```

    #>     symbol   side   type    status
    #>     <char> <char> <char>    <char>
    #> 1: BTCUSDT    BUY  LIMIT validated

#### Set Leverage

``` r
futures$set_leverage("BTCUSDT", leverage = 10)
```

    #>    leverage max_notional_value  symbol
    #>       <int>             <char>  <char>
    #> 1:       20           25000000 BTCUSDT

## Async Usage

This package is meant to be used in an asynchronous non-blocking event
loop (i.e. à la JavaScript) and is written around promises. Please use
`later` to run your event loop. I recommend the pattern shown below.

We offer a synchronous and asynchronous instance of the classes. All
classes accept `async = TRUE`, this makes methods return promises
instead of objects. You can resolve promises in whichever way you like,
either `$then()` chaining or `async`/`await` patterns.

I recommend use `coro::async()` to write sequential looking async code:

``` r
box::use(coro, later)

market_async <- BinanceMarketData$new(async = TRUE)

main <- coro$async(function() {
  ticker <- await(market_async$get_ticker("BTCUSDT"))
  klines <- await(market_async$get_klines("BTCUSDT", "1h", limit = 10))

  print(ticker)
  print(klines)
})

main()

while (!later$loop_empty()) {
  later$run_now()
}
```

    #>     symbol          price
    #>     <char>         <char>
    #> 1: BTCUSDT 69951.33000000
    #>               open_time     open     high      low    close    volume
    #>                  <POSc>    <num>    <num>    <num>    <num>     <num>
    #>  1: 2026-03-10 20:00:00 70043.63 70350.00 70007.52 70235.60  671.8897
    #>  2: 2026-03-10 21:00:00 70236.34 70417.30 69541.91 69763.01  830.8687
    #>  3: 2026-03-10 22:00:00 69763.02 69869.90 69452.42 69721.58  937.2009
    #>  4: 2026-03-10 23:00:00 69721.58 69981.80 69698.46 69948.63 1165.1591
    #>  5: 2026-03-11 00:00:00 69948.64 70173.25 69759.63 70044.87  728.9296
    #>  6: 2026-03-11 01:00:00 70044.87 70144.00 69880.00 70071.26  947.2488
    #>  7: 2026-03-11 02:00:00 70071.26 70119.59 69614.00 69810.72 1612.8755
    #>  8: 2026-03-11 03:00:00 69810.73 69887.11 69488.70 69551.91 1113.4141
    #>  9: 2026-03-11 04:00:00 69551.91 70281.87 69501.55 70130.99  759.4160
    #> 10: 2026-03-11 05:00:00 70130.99 70200.96 69880.00 69951.33  170.3363
    #>              close_time quote_volume trades taker_buy_base_volume
    #>                  <POSc>        <num>  <int>                 <num>
    #>  1: 2026-03-10 20:59:59     47179926 104421             331.80815
    #>  2: 2026-03-10 21:59:59     58065221 120034             366.13855
    #>  3: 2026-03-10 22:59:59     65279900 110217             464.68161
    #>  4: 2026-03-10 23:59:59     81377772 119557             483.60908
    #>  5: 2026-03-11 00:59:59     51015676 154124             338.21923
    #>  6: 2026-03-11 01:59:59     66359226 132156             555.98820
    #>  7: 2026-03-11 02:59:59    112718434 133771             971.95761
    #>  8: 2026-03-11 03:59:59     77509259 121595             556.74333
    #>  9: 2026-03-11 04:59:59     53066815 131224             454.60323
    #> 10: 2026-03-11 05:59:59     11929648  37564              77.42888
    #>     taker_buy_quote_volume ignore
    #>                      <num> <char>
    #>  1:               23300993      0
    #>  2:               25589091      0
    #>  3:               32370447      0
    #>  4:               33773404      0
    #>  5:               23674731      0
    #>  6:               38948457      0
    #>  7:               67947297      0
    #>  8:               38736107      0
    #>  9:               31788196      0
    #> 10:                5424607      0

## Sample Data

The package ships with a sample dataset of 500 BTC-USDT 4-hour candles
for demonstration and testing:

``` r
data(binance_btc_usdt_4h_ohlcv)
head(binance_btc_usdt_4h_ohlcv)
```

See `?binance_btc_usdt_4h_ohlcv` for column descriptions. This data was
produced by `binance_backfill_klines()`.

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
