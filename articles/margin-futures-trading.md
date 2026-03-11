# Margin and Futures Trading with binance

This vignette covers margin and USD-M futures trading using the
`binance` package. All examples use synchronous mode and mock data so
they run without a live API connection.

## Overview

The package provides four classes for margin and futures operations:

| Class                | Purpose                                                                     |
|----------------------|-----------------------------------------------------------------------------|
| `BinanceMarginData`  | Query margin pairs, price index, interest rates, cross/isolated margin data |
| `BinanceMargin`      | Borrow, repay, place margin orders, query margin account                    |
| `BinanceFuturesData` | Futures exchange info, mark price, funding rates, klines, open interest     |
| `BinanceFutures`     | Place futures orders, manage positions, leverage, account queries           |

------------------------------------------------------------------------

## Setup

``` r
library(binance)

keys <- get_api_keys(
  api_key = "your-key",
  api_secret = "your-secret"
)

# Margin clients
margin_data <- BinanceMarginData$new(keys = keys)
margin <- BinanceMargin$new(keys = keys)

# Futures clients
futures_data <- BinanceFuturesData$new(keys = keys)
futures <- BinanceFutures$new(keys = keys)
```

------------------------------------------------------------------------

## Margin Trading

### Available Margin Pairs

Retrieve all cross margin trading pairs to see which symbols support
margin trading:

``` r
pairs <- margin_data$get_all_pairs()
print(pairs)
```

    #>      base        id is_buy_allowed is_margin_trade is_sell_allowed  quote
    #>    <char>     <int>         <lgcl>          <lgcl>          <lgcl> <char>
    #> 1:    BTC 351637150           TRUE            TRUE            TRUE   USDT
    #> 2:    ETH 351637151           TRUE            TRUE            TRUE   USDT
    #>     symbol
    #>     <char>
    #> 1: BTCUSDT
    #> 2: ETHUSDT

### Price Index

The margin price index is a public endpoint (no authentication
required). It returns the index price used for margin calculations:

``` r
idx <- margin_data$get_price_index(symbol = "BTCUSDT")
print(idx)
```

    #>              calc_time          price  symbol
    #>                 <POSc>         <char>  <char>
    #> 1: 2019-07-02 05:46:58 67232.90000000 BTCUSDT

### Cross Margin Data

Query cross margin fee data including daily/yearly interest rates and
borrowing limits per coin:

``` r
cm_data <- margin_data$get_cross_margin_data()
print(cm_data)
```

    #>    vip_level   coin transfer_in transfer_out borrowable daily_interest
    #>        <int> <char>      <lgcl>       <lgcl>     <lgcl>         <char>
    #> 1:         0    BTC        TRUE         TRUE       TRUE     0.00015000
    #>    yearly_interest marginable_pairs
    #>             <char>           <list>
    #> 1:      0.05475000        <list[2]>

### Interest Rate History

Check historical interest rates for a specific asset:

``` r
rate_history <- margin_data$get_interest_rate_history(asset = "BTC")
print(rate_history)
```

    #>     asset daily_interest_rate           timestamp vip_level
    #>    <char>              <char>              <POSc>     <int>
    #> 1:    BTC          0.00015000 2022-08-26 05:52:26         0
    #> 2:    BTC          0.00012000 2022-08-26 05:54:06         0

### Borrowing and Repaying

Borrow assets against your margin collateral and repay loans. These are
write operations that modify account state:

``` r
# Borrow 100 USDT on cross margin
loan <- margin$add_borrow(asset = "USDT", amount = 100)
print(loan)

# Repay the loan
repay <- margin$add_repay(asset = "USDT", amount = 100)
print(repay)

# Check max borrowable amount
max_borrow <- margin$get_max_borrowable(asset = "USDT")
print(max_borrow)
```

### Placing Margin Orders

Place a limit buy order on cross margin. The `sideEffectType` parameter
controls auto-borrowing behaviour:

- `"NO_SIDE_EFFECT"` – normal order, no auto-borrow.
- `"MARGIN_BUY"` – auto-borrow if insufficient balance.
- `"AUTO_REPAY"` – auto-repay after the trade fills.

``` r
order <- margin$add_order(
  symbol = "BTCUSDT",
  side = "BUY",
  type = "LIMIT",
  quantity = 0.001,
  price = 50000,
  timeInForce = "GTC",
  sideEffectType = "MARGIN_BUY"
)
print(order)
```

    #>     symbol order_id        client_order_id       transact_time          price
    #>     <char>    <int>                 <char>              <POSc>         <char>
    #> 1: BTCUSDT       28 6gCrw2kRUAF9CvJDGP16IP 2017-10-11 12:32:56 50000.00000000
    #>      orig_qty executed_qty cummulative_quote_qty status time_in_force   type
    #>        <char>       <char>                <char> <char>        <char> <char>
    #> 1: 0.00010000   0.00000000            0.00000000    NEW           GTC  LIMIT
    #>      side is_isolated self_trade_prevention_mode
    #>    <char>      <lgcl>                     <char>
    #> 1:    BUY       FALSE                       NONE

Query open margin orders:

``` r
open <- margin$get_open_orders(symbol = "BTCUSDT")
print(open)
```

    #>     symbol order_id        client_order_id transact_time          price
    #>     <char>    <int>                 <char>         <num>         <char>
    #> 1: BTCUSDT       28 6gCrw2kRUAF9CvJDGP16IP  1.507725e+12 50000.00000000
    #>      orig_qty executed_qty cummulative_quote_qty status time_in_force   type
    #>        <char>       <char>                <char> <char>        <char> <char>
    #> 1: 0.00010000   0.00000000            0.00000000    NEW           GTC  LIMIT
    #>      side is_isolated self_trade_prevention_mode
    #>    <char>      <lgcl>                     <char>
    #> 1:    BUY       FALSE                       NONE

### Margin Account Information

Get a summary of your cross margin account including margin level, total
assets, and liabilities:

``` r
account <- margin$get_account()
print(account[, .(borrow_enabled, margin_level, total_asset_of_btc,
                   total_liability_of_btc, total_net_asset_of_btc)])
```

    #>    borrow_enabled margin_level total_asset_of_btc total_liability_of_btc
    #>            <lgcl>       <char>             <char>                 <char>
    #> 1:           TRUE  11.64405625         6.82000000             0.58633215
    #>    total_net_asset_of_btc
    #>                    <char>
    #> 1:             6.23366785

### Margin Trade History

Retrieve executed margin trades for a symbol:

``` r
trades <- margin$get_trades(symbol = "BTCUSDT")
print(trades)
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

------------------------------------------------------------------------

## Futures Trading

### Exchange Information

Retrieve futures trading pair metadata including contract type,
precision, and filters:

``` r
info <- futures_data$get_exchange_info()
print(info[, .(symbol, contract_type, status, base_asset, quote_asset)])
```

    #>     symbol contract_type  status base_asset quote_asset
    #>     <char>        <char>  <char>     <char>      <char>
    #> 1: BTCUSDT     PERPETUAL TRADING        BTC        USDT

### Mark Price and Funding Rate

The mark price is used for liquidation and unrealised PnL calculations.
Funding rates are periodic payments between long and short positions:

``` r
mark <- futures_data$get_mark_price(symbol = "BTCUSDT")
print(mark)
```

    #>     symbol     mark_price    index_price estimated_settle_price
    #>     <char>         <char>         <char>                 <char>
    #> 1: BTCUSDT 67232.90000000 67230.50000000         67231.70000000
    #>    last_funding_rate   next_funding_time interest_rate                time
    #>               <char>              <POSc>        <char>              <POSc>
    #> 1:        0.00010000 2022-08-26 06:00:00    0.00010000 2022-08-26 05:52:26

``` r
rates <- futures_data$get_funding_rate(symbol = "BTCUSDT", limit = 5)
print(rates)
```

    #>     symbol funding_rate        funding_time     mark_price
    #>     <char>       <char>              <POSc>         <char>
    #> 1: BTCUSDT   0.00010000 2022-08-26 06:00:00 67232.90000000
    #> 2: BTCUSDT   0.00012000 2022-08-26 14:00:00 67500.00000000

### Futures Klines

Fetch historical candlestick data for futures contracts:

``` r
klines <- futures_data$get_klines(symbol = "BTCUSDT", interval = "1h", limit = 5)
print(klines)
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

### Open Interest

Check the total open interest for a futures symbol:

``` r
oi <- futures_data$get_open_interest(symbol = "BTCUSDT")
print(oi)
```

    #>     symbol open_interest                time
    #>     <char>        <char>              <POSc>
    #> 1: BTCUSDT     12345.678 2022-08-26 05:52:26

### Futures Account and Positions

Query your futures account summary and current positions:

``` r
account <- futures$get_account()
print(account[, .(total_initial_margin, total_maint_margin,
                   total_wallet_balance, total_unrealized_profit,
                   available_balance)])
```

    #>    total_initial_margin total_maint_margin total_wallet_balance
    #>                  <char>             <char>               <char>
    #> 1:           0.00000000         0.00000000        1000.00000000
    #>    total_unrealized_profit available_balance
    #>                     <char>            <char>
    #> 1:              0.00000000     1000.00000000

``` r
positions <- futures$get_positions(symbol = "BTCUSDT")
print(positions)
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

### Futures Balances

Retrieve per-asset balances in the futures account:

``` r
balances <- futures$get_balances()
print(balances)
```

    #>    account_alias  asset       balance cross_wallet_balance cross_un_pnl
    #>           <char> <char>        <char>               <char>       <char>
    #> 1:          SgsR   USDT 1000.00000000        1000.00000000   0.00000000
    #>    available_balance max_withdraw_amount margin_available         update_time
    #>               <char>              <char>           <lgcl>              <POSc>
    #> 1:     1000.00000000       1000.00000000             TRUE 2022-08-26 05:52:26

### Setting Leverage

Adjust the initial leverage for a futures symbol (1-125x):

``` r
result <- futures$set_leverage(symbol = "BTCUSDT", leverage = 10)
print(result)
```

    #>    leverage max_notional_value  symbol
    #>       <int>             <char>  <char>
    #> 1:       20           25000000 BTCUSDT

### Placing Futures Orders

Use the test endpoint to validate order parameters without creating a
real order:

``` r
test <- futures$add_order_test(
  symbol = "BTCUSDT",
  side = "BUY",
  type = "LIMIT",
  quantity = 0.001,
  price = 50000,
  timeInForce = "GTC"
)
print(test)
```

    #>     symbol   side   type    status
    #>     <char> <char> <char>    <char>
    #> 1: BTCUSDT    BUY  LIMIT validated

Place a real futures order (use with caution on a live account):

``` r
order <- futures$add_order(
  symbol = "BTCUSDT",
  side = "BUY",
  type = "LIMIT",
  quantity = 0.001,
  price = 50000,
  timeInForce = "GTC"
)
print(order)
```

Market orders require only the quantity:

``` r
order <- futures$add_order(
  symbol = "BTCUSDT",
  side = "BUY",
  type = "MARKET",
  quantity = 0.001
)
print(order)
```

### Margin Type and Position Mode

Switch between crossed and isolated margin, and between one-way and
hedge mode:

``` r
# Switch to isolated margin
futures$set_margin_type(symbol = "BTCUSDT", marginType = "ISOLATED")

# Enable hedge mode (dual side positions)
futures$set_position_mode(dualSidePosition = TRUE)
```

### Income History

Retrieve funding fees, realised PnL, commissions, and other income
entries:

``` r
income <- futures$get_income_history(symbol = "BTCUSDT")
print(income)
```

    #>     symbol income_type      income  asset   info                time   tran_id
    #>     <char>      <char>      <char> <char> <char>              <POSc>     <int>
    #> 1: BTCUSDT FUNDING_FEE -0.01200000   USDT        2022-08-26 05:52:26 100000001
    #>    trade_id
    #>      <char>
    #> 1:

### Futures Trade History

Query executed trades on the futures account:

``` r
trades <- futures$get_trades(symbol = "BTCUSDT")
print(trades)
```

    #>     symbol     id  order_id   side    price    qty realized_pnl margin_asset
    #>     <char>  <int>     <int> <char>   <char> <char>       <char>       <char>
    #> 1: BTCUSDT 100001 283194212    BUY 50000.00  0.001   0.00000000         USDT
    #>      quote_qty commission commission_asset                time position_side
    #>         <char>     <char>           <char>              <POSc>        <char>
    #> 1: 50.00000000 0.02000000             USDT 2022-08-26 05:52:26          BOTH
    #>     buyer  maker
    #>    <lgcl> <lgcl>
    #> 1:   TRUE  FALSE

------------------------------------------------------------------------

## Method Reference

### BinanceMarginData

| Method                             | Description                       |
|------------------------------------|-----------------------------------|
| `get_all_pairs()`                  | All cross margin trading pairs    |
| `get_isolated_pairs()`             | All isolated margin trading pairs |
| `get_price_index(symbol)`          | Margin price index (public)       |
| `get_interest_rate_history(asset)` | Historical interest rates         |
| `get_cross_margin_data()`          | Cross margin fee data             |
| `get_isolated_margin_data()`       | Isolated margin fee data          |

### BinanceMargin

| Method                          | Description                               |
|---------------------------------|-------------------------------------------|
| `add_borrow(asset, amount)`     | Borrow assets on margin                   |
| `add_repay(asset, amount)`      | Repay margin loan                         |
| `add_order(...)`                | Place a margin order                      |
| `cancel_order(symbol, orderId)` | Cancel a margin order                     |
| `cancel_all_orders(symbol)`     | Cancel all open margin orders             |
| `get_order(symbol, orderId)`    | Query a specific order                    |
| `get_open_orders(symbol)`       | List open margin orders                   |
| `get_all_orders(symbol)`        | List all margin orders                    |
| `get_account()`                 | Cross margin account info                 |
| `get_max_borrowable(asset)`     | Max borrowable amount                     |
| `get_max_transferable(asset)`   | Max transferable amount                   |
| `get_interest_history()`        | Interest accrual history                  |
| `get_trades(symbol)`            | Margin trade history                      |
| `get_isolated_account()`        | Isolated margin account info              |
| `add_isolated_transfer(...)`    | Transfer between spot and isolated margin |

### BinanceFuturesData

| Method                                    | Description                           |
|-------------------------------------------|---------------------------------------|
| `get_exchange_info()`                     | Futures trading pair metadata         |
| `get_klines(symbol, interval)`            | Historical candlestick data           |
| `get_mark_price(symbol)`                  | Mark price, index price, funding rate |
| `get_funding_rate(symbol)`                | Historical funding rates              |
| `get_24hr_stats(symbol)`                  | 24h price change statistics           |
| `get_ticker(symbol)`                      | Latest price ticker                   |
| `get_book_ticker(symbol)`                 | Best bid/ask prices                   |
| `get_open_interest(symbol)`               | Current open interest                 |
| `get_depth(symbol)`                       | Order book depth                      |
| `get_trades(symbol)`                      | Recent trades                         |
| `get_index_price_klines(pair, interval)`  | Index price klines                    |
| `get_mark_price_klines(symbol, interval)` | Mark price klines                     |

### BinanceFutures

| Method                                         | Description                         |
|------------------------------------------------|-------------------------------------|
| `add_order(...)`                               | Place a futures order               |
| `add_order_test(...)`                          | Validate order without placing      |
| `cancel_order(symbol, orderId)`                | Cancel a futures order              |
| `cancel_all_orders(symbol)`                    | Cancel all open futures orders      |
| `get_order(symbol, orderId)`                   | Query a specific order              |
| `get_open_orders(symbol)`                      | List open futures orders            |
| `get_all_orders(symbol)`                       | List all futures orders             |
| `get_account()`                                | Futures account info                |
| `get_balances()`                               | Per-asset balances                  |
| `get_positions(symbol)`                        | Position risk info                  |
| `set_leverage(symbol, leverage)`               | Set initial leverage (1-125x)       |
| `set_margin_type(symbol, marginType)`          | Set crossed or isolated margin      |
| `modify_position_margin(symbol, amount, type)` | Add or reduce position margin       |
| `get_trades(symbol)`                           | Futures trade history               |
| `get_income_history(symbol)`                   | Income history (funding, PnL, etc.) |
| `set_position_mode(dualSidePosition)`          | Switch one-way / hedge mode         |
| `get_position_mode()`                          | Query current position mode         |
