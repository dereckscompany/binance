
# binance

<!-- badges: start -->

[![R-CMD-check](https://github.com/dereckscompany/binance/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dereckscompany/binance/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**In plain terms:** Binance is one of the largest cryptocurrency
exchanges, where people buy, sell and hold digital coins. This package
is the R doorway to it: you can pull historical price data and stream
live market updates such as the order book, place and manage buy and
sell orders on both the spot and futures markets, and handle the account
side – balances, deposits, withdrawals, transfers and sub-accounts – all
from R scripts. Requests can run the ordinary way, where your code waits
for each answer, or in the background so your program keeps working and
collects the results later. For research it can bulk-download years of
price history and resume where it left off if it is interrupted, handing
everything back as tidy tables ready for analysis. Because it can move
real funds and place real trades, it is built to be driven deliberately
and tested with small amounts first.

## Technical overview

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

All API responses are returned as `data.table` objects. The package
targets a consistent “one entity = one row, no list columns” shape, but
the exact transformation is endpoint-specific. See each method’s
`@return` block for the precise list of columns and any per-endpoint
behaviour.

The transformations the parsers apply:

1.  **snake_case column names** - camelCase keys from the JSON response
    (e.g. `insertTime`, `quoteQty`) are converted to snake_case
    (`insert_time`, `quote_qty`). A handful of endpoints additionally
    rename for clarity (e.g. nested objects are wide-prefixed to
    `parent_child` columns; collapsed array fields land under the plural
    form like `permissions`).

2.  **Type coercion** for well-known columns - millisecond timestamps
    become `POSIXct`; selected nested numeric `filters` are extracted
    into flat `lot_min_qty` / `price_tick_size` / `min_notional`
    columns.

3.  **Shape normalisation** for nested arrays and objects, applied per
    endpoint:

    - **Arrays of plain strings** (e.g. `orderTypes`, `permissions`,
      `allowedSelfTradePreventionModes`) → collapsed into one
      `;`-separated character column. Recover via
      `strsplit(x, ";", fixed = TRUE)[[1]]`.
    - **Arrays of objects with a fixed schema** (e.g. order `fills`,
      account `assets`, OCO `orderReports`, sub-account
      `spotSubUserAssetBtcVoList`) → exploded to long format with parent
      fields replicated and a `<child>_` prefix on the child columns. A
      1-indexed position column is added where order matters.
    - **Single nested objects with a fixed schema** (e.g. account
      `commissionRates`, locked-earn `detail` / `quota`) → flattened to
      wide `parent_child` columns.
    - **Nested objects with dynamic keys** (e.g. spot exchange-info
      `permissionSets`, flexible-earn `tierAnnualPercentageRate`) →
      serialised as a JSON string column so the inner structure is
      preserved; recover via `jsonlite::fromJSON(x)`.

**Endpoints that reshape rather than drop:**

The parsers never discard API data — every field is either on the row,
on a sibling row, on a sibling method’s return, or attached as an
attribute on the returned `data.table`.

- `get_account_info()` (spot) - account-level fields are returned as a
  single row; the companion `balances` array is parsed by the sibling
  `get_balances()` (both methods hit `/api/v3/account` and parse
  different halves).
- `get_account()` (futures) - one row per asset balance; the companion
  `positions` array is parsed by the sibling `get_positions()` (which
  hits `/fapi/v2/positionRisk`).
- `get_exchange_info()` (spot and futures) - one row per symbol. The
  full per-symbol `filters` array is preserved as a JSON-encoded
  `filters_raw` column alongside the curated `lot_*` / `price_*` /
  `min_notional` columns (recover with
  `jsonlite::fromJSON(dt$filters_raw[1])`). Exchange-wide blocks (rate
  limits, exchange-wide filter rules, and on futures the margin-asset
  config) are exposed via sibling methods on the same class:
  `get_rate_limits()`, `get_exchange_filters()`, and (futures only)
  `get_futures_assets()`. `serverTime` is the long-standing
  `get_server_time()`. The constants (`timezone = "UTC"`,
  `futuresType = "U_M"`) are not re-exposed.
- The OCO endpoints (`add_oco_order()`, `cancel_oco_order()`) expand the
  richer `orderReports` payload; the thinner `orders` duplicate is a
  strict subset of the same data and so is omitted.

**Klines** are a special case: Binance returns positional arrays instead
of named objects, so we assign descriptive column names (`open_time`,
`open`, `high`, `low`, `close`, `volume`, `close_time`, etc.) matching
the Binance documentation.

If a column you expect is missing, check the method’s `@return`; if it
still looks wrong, please file an issue.

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
| `BinanceMarketStream` | Live spot market-data WebSocket streams (order-book depth) | No |
| `BinanceBase` | Internal base class (not used directly) | — |
| `BinanceWsBase` | Internal base class for WebSocket streams (not used directly) | — |

All REST classes accept an `async = TRUE` argument at construction and
share a common `time_source` parameter for clock drift correction. The
WebSocket classes are always event-driven (a socket is an endless push
stream, not a single request) — see [WebSocket
Streams](#websocket-streams) below.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("dereckscompany/binance")
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
documentation](https://developers.binance.com/docs/binance-spot-api-docs).

## Quick Start – Market Data

Market data endpoints are public and require no authentication.

``` r
market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)
```

### Price Ticker

``` r
market$get_ticker(symbol = "BTCUSDT")
```

    #>     symbol          price
    #>     <char>         <char>
    #> 1: BTCUSDT 67232.90000000

### Klines (Candlestick Data)

``` r
market$get_klines(symbol = "BTCUSDT", interval = "1h", limit = 5)
```

    #>      datetime      open   high      low    close   volume          close_time
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

When you need more than 1000 candles, pass `fetch_all = TRUE`. The
method pages forward through the range — following the data and stopping
at the first empty or short page — and returns the combined result.
Because Binance returns candles from the first one on or after
`start_time`, an empty leading stretch (e.g. dates before a symbol was
listed) is skipped in a single request:

``` r
all_klines <- market$get_klines(
  symbol = "BTCUSDT",
  interval = "1h",
  start_time = lubridate::as_datetime("2024-01-01", tz = "UTC"),
  end_time = lubridate::as_datetime("2024-06-01", tz = "UTC"),
  fetch_all = TRUE,
  sleep = 0
)
nrow(all_klines)
```

    #> [1] 3

Pass an `on_page` callback to **stream** each page as it is fetched
instead of holding the whole result in memory — the method then returns
invisibly and your callback owns the data (this is how
`binance_backfill_klines()` writes to disk page by page):

``` r
candles <- 0L
market$get_klines(
  symbol = "BTCUSDT", interval = "1h",
  start_time = lubridate::as_datetime("2024-01-01", tz = "UTC"),
  end_time = lubridate::as_datetime("2024-02-01", tz = "UTC"),
  fetch_all = TRUE,
  on_page = function(page) candles <<- candles + nrow(page)
)
candles
```

    #> [1] 3

> **Note:** Large date ranges consume multiple API requests. Use the
> `sleep` parameter to avoid hitting Binance rate limits. For bulk
> multi-symbol downloads, see `binance_backfill_klines()`.

### Order Book Depth

``` r
market$get_depth(symbol = "BTCUSDT", limit = 5)
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
market$get_24hr_stats(symbol = "BTCUSDT")
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
    #>       <num>   <num> <int>
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

    #>    validated
    #>       <lgcl>
    #> 1:      TRUE

### Query an Order

``` r
trading$get_order(symbol = "BTCUSDT", order_id = 12345)
```

    #>     symbol order_id order_list_id        client_order_id          price
    #>     <char>    <num>         <num>                 <char>         <char>
    #> 1: BTCUSDT       28            -1 6gCrw2kRUAF9CvJDGP16IP 50000.00000000
    #>      orig_qty executed_qty cummulative_quote_qty status time_in_force   type
    #>        <char>       <char>                <char> <char>        <char> <char>
    #> 1: 0.00010000   0.00010000            5.00000000 FILLED           GTC  LIMIT
    #>      side stop_price iceberg_qty                time         update_time
    #>    <char>     <char>      <char>              <POSc>              <POSc>
    #> 1:    BUY 0.00000000  0.00000000 2017-10-11 12:32:56 2017-10-11 12:32:56
    #>    is_working orig_quote_order_qty        working_time
    #>        <lgcl>               <char>              <POSc>
    #> 1:       TRUE           0.00000000 2017-10-11 12:32:56
    #>    self_trade_prevention_mode
    #>                        <char>
    #> 1:                       NONE

### Get Open Orders

``` r
trading$get_open_orders(symbol = "BTCUSDT")
```

    #>     symbol order_id order_list_id        client_order_id          price
    #>     <char>    <num>         <num>                 <char>         <char>
    #> 1: BTCUSDT       28            -1 6gCrw2kRUAF9CvJDGP16IP 50000.00000000
    #>      orig_qty executed_qty cummulative_quote_qty status time_in_force   type
    #>        <char>       <char>                <char> <char>        <char> <char>
    #> 1: 0.00010000   0.00000000            0.00000000    NEW           GTC  LIMIT
    #>      side stop_price iceberg_qty                time is_working
    #>    <char>     <char>      <char>              <POSc>     <lgcl>
    #> 1:    BUY 0.00000000  0.00000000 2017-10-11 12:32:56       TRUE
    #>    orig_quote_order_qty        working_time self_trade_prevention_mode
    #>                  <char>              <POSc>                     <char>
    #> 1:           0.00000000 2017-10-11 12:32:56                       NONE

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
    #>    can_trade can_withdraw can_deposit brokered require_self_trade_prevention
    #>       <lgcl>       <lgcl>      <lgcl>   <lgcl>                        <lgcl>
    #> 1:      TRUE         TRUE        TRUE    FALSE                         FALSE
    #>    prevent_sor         update_time account_type permissions       uid
    #>         <lgcl>              <POSc>       <char>      <char>     <num>
    #> 1:       FALSE 1970-01-02 10:17:36         SPOT        SPOT 354937868
    #>    commission_rates_maker commission_rates_taker commission_rates_buyer
    #>                    <char>                 <char>                 <char>
    #> 1:             0.00150000             0.00150000             0.00000000
    #>    commission_rates_seller
    #>                     <char>
    #> 1:              0.00000000

### Trade History

``` r
account$get_trades(symbol = "BTCUSDT")
```

    #>     symbol    id order_id order_list_id          price        qty   quote_qty
    #>     <char> <num>    <num>         <num>         <char>     <char>      <char>
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
    #> 2:           TRUE  11.64405625         6.82000000             0.58633215
    #>    total_net_asset_of_btc trade_enabled transfer_enabled account_type
    #>                    <char>        <lgcl>           <lgcl>       <char>
    #> 1:             6.23366785          TRUE             TRUE       MARGIN
    #> 2:             6.23366785          TRUE             TRUE       MARGIN
    #>    user_asset_asset user_asset_borrowed user_asset_free user_asset_interest
    #>              <char>              <char>          <char>              <char>
    #> 1:              BTC          0.00000000      0.00499500          0.00000000
    #> 2:             USDT        100.00000000    200.00000000          0.01000000
    #>    user_asset_locked user_asset_net_asset
    #>               <char>               <char>
    #> 1:        0.00000000           0.00499500
    #> 2:        0.00000000          99.99000000

### Max Borrowable

``` r
margin$get_max_borrowable(asset = "USDT")
```

    #>        amount borrow_limit
    #>        <char>       <char>
    #> 1: 1.69248805           60

### Margin Trades

``` r
margin$get_trades(symbol = "BTCUSDT")
```

    #>     symbol    id order_id          price        qty   quote_qty commission
    #>     <char> <num>    <num>         <char>     <char>      <char>     <char>
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
fdata$get_mark_price(symbol = "BTCUSDT")
```

    #>     symbol     mark_price    index_price estimated_settle_price
    #>     <char>         <char>         <char>                 <char>
    #> 1: BTCUSDT 67232.90000000 67230.50000000         67231.70000000
    #>    last_funding_rate   next_funding_time interest_rate                time
    #>               <char>              <POSc>        <char>              <POSc>
    #> 1:        0.00010000 2022-08-26 06:00:00    0.00010000 2022-08-26 05:52:26

#### Funding Rate History

``` r
fdata$get_funding_rate(symbol = "BTCUSDT", limit = 3)
```

    #>     symbol funding_rate        funding_time     mark_price
    #>     <char>       <char>              <POSc>         <char>
    #> 1: BTCUSDT   0.00010000 2022-08-26 06:00:00 67232.90000000
    #> 2: BTCUSDT   0.00012000 2022-08-26 14:00:00 67500.00000000

#### Open Interest

``` r
fdata$get_open_interest(symbol = "BTCUSDT")
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
futures$get_positions(symbol = "BTCUSDT")
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
  time_in_force = "GTC"
)
```

    #>    validated
    #>       <lgcl>
    #> 1:      TRUE

#### Set Leverage

``` r
futures$set_leverage(symbol = "BTCUSDT", leverage = 10)
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
  ticker <- await(market_async$get_ticker(symbol = "BTCUSDT"))
  klines <- await(market_async$get_klines(symbol = "BTCUSDT", interval = "1h", limit = 10))

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
    #> 1: BTCUSDT 67232.90000000
    #>      datetime      open   high      low    close   volume          close_time
    #>        <POSc>     <num>  <num>    <num>    <num>    <num>              <POSc>
    #> 1: 2017-07-03 0.0163479 0.8000 0.015758 0.015771 148976.1 2017-07-09 23:59:59
    #> 2: 2017-07-10 0.0157710 0.0158 0.015730 0.015788  95432.0 2017-07-16 23:59:59
    #> 3: 2017-07-17 0.0157880 0.0159 0.015700 0.015850 120000.0 2017-07-23 23:59:59
    #>    quote_volume trades taker_buy_base_volume taker_buy_quote_volume ignore
    #>           <num>  <int>                 <num>                  <num> <char>
    #> 1:     2434.191    308             1756.8740               28.46694      0
    #> 2:     1505.250    205              876.1235               13.82000      0
    #> 3:     1899.600    250              950.0000               15.06750      0

## WebSocket Streams

Beyond the REST API, the package opens **live market-data WebSocket
streams** — most importantly the order-book **diff stream**, the only
order-book data Binance does not archive, so it has to be captured as it
happens. The client is event-driven, modelled on the Node.js `ws` API:
register handlers with `$on()`, then drive R’s `later` event loop
yourself — the same explicit pattern as the async REST example above.

``` r
box::use(binance[BinanceMarketStream], later)

stream <- BinanceMarketStream$new()

# handlers receive the raw JSON message string
stream$on("open", function(e) message("connected"))
stream$on("message", function(msg) cat(msg, "\n"))

# subscribe to the BTC/USDT order-book diff stream at 100 ms
stream$depth("BTCUSDT", speed = "100ms")

# connect, then drive the event loop explicitly (interrupt to stop)
stream$connect()
while (!later$loop_empty()) {
  later$run_now(0.1) # the timeout makes each tick wait for work, not busy-spin
}
```

`$run()` is a convenience that wraps exactly that connect-and-pump loop
and tears down cleanly on an interrupt — reach for it when the stream is
the only thing running. Write each raw message straight to an
append-only file and you have an order-book recorder; see
`vignette("websocket-streams")` for the recorder pattern and
reconnection.

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
See [LICENSE](LICENSE) for the full text.
