# Getting Started with binance

This vignette demonstrates how to use `binance` in **synchronous** mode.

## Setup

``` r
box::use(
  binance[
    BinanceMarketData, BinanceTrading, BinanceOcoOrders,
    BinanceAccount, BinanceDeposit, BinanceWithdrawal,
    BinanceTransfer, BinanceSubAccount, BinanceEarn,
    get_api_keys
  ]
)

keys <- get_api_keys(
  api_key = "your-api-key",
  api_secret = "your-api-secret"
)
```

------------------------------------------------------------------------

## Market Data

The `BinanceMarketData` class covers all public (no auth) market
endpoints.

``` r
market <- BinanceMarketData$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

### Exchange Info

``` r
info <- market$get_exchange_info("BTCUSDT")
info[, .(symbol, status, base_asset, quote_asset)]
```

    #>     symbol  status base_asset quote_asset
    #>     <char>  <char>     <char>      <char>
    #> 1: BTCUSDT TRADING        BTC        USDT
    #> 2: ETHUSDT TRADING        ETH        USDT

### Ticker

``` r
ticker <- market$get_ticker("BTCUSDT")
ticker
```

    #>     symbol          price
    #>     <char>         <char>
    #> 1: BTCUSDT 67232.90000000

### All Tickers

``` r
tickers <- market$get_all_tickers()
tickers
```

    #>                v1
    #>            <char>
    #> 1:        BTCUSDT
    #> 2: 67232.90000000

### Book Ticker

Best bid/ask prices and quantities:

``` r
book <- market$get_book_ticker("BTCUSDT")
book
```

    #>     symbol      bid_price    bid_qty      ask_price    ask_qty
    #>     <char>         <char>     <char>         <char>     <char>
    #> 1: BTCUSDT 67232.00000000 0.41861839 67232.90000000 1.24808993

### Average Price

``` r
avg <- market$get_avg_price("BTCUSDT")
avg
```

    #>     mins          price          close_time
    #>    <int>         <char>              <POSc>
    #> 1:     5 67232.45000000 2023-09-07 04:32:34

### 24hr Statistics

``` r
stats <- market$get_24hr_stats("BTCUSDT")
stats[, .(symbol, last_price, price_change_percent, volume)]
```

    #>     symbol     last_price price_change_percent        volume
    #>     <char>         <char>               <char>        <char>
    #> 1: BTCUSDT 67232.90000000               -1.140 3456.78901234

### Order Book Depth

``` r
depth <- market$get_depth("BTCUSDT", limit = 5)
depth
```

    #>    last_update_id   side   price      size
    #>            <char> <char>   <num>     <num>
    #> 1:        1027024    bid 67232.8 0.4186184
    #> 2:        1027024    bid 67232.5 1.5000000
    #> 3:        1027024    bid 67230.0 0.8000000
    #> 4:        1027024    ask 67232.9 1.2480899
    #> 5:        1027024    ask 67233.5 0.5000000
    #> 6:        1027024    ask 67235.0 2.1000000

### Recent Trades

``` r
trades <- market$get_trades("BTCUSDT")
trades
```

    #>       id          price        qty    quote_qty                time
    #>    <int>         <char>     <char>       <char>              <POSc>
    #> 1: 28457 67232.90000000 0.00007682   5.16527540 2017-07-12 13:19:09
    #> 2: 28458 67231.50000000 0.01234000 829.63251000 2017-07-12 13:19:10
    #> 3: 28459 67233.00000000 0.00500000 336.16500000 2017-07-12 13:19:11
    #>    is_buyer_maker is_best_match
    #>            <lgcl>        <lgcl>
    #> 1:           TRUE          TRUE
    #> 2:          FALSE          TRUE
    #> 3:           TRUE          TRUE

### Klines (Candlestick Data)

``` r
klines <- market$get_klines("BTCUSDT", "1h", limit = 5)
klines[, .(open_time, open, high, low, close, volume)]
```

    #>     open_time      open   high      low    close   volume
    #>        <POSc>     <num>  <num>    <num>    <num>    <num>
    #> 1: 2017-07-03 0.0163479 0.8000 0.015758 0.015771 148976.1
    #> 2: 2017-07-10 0.0157710 0.0158 0.015730 0.015788  95432.0
    #> 3: 2017-07-17 0.0157880 0.0159 0.015700 0.015850 120000.0

### Fetch All Klines (Large Date Ranges)

When you need more than 1000 candles, use `fetch_all = TRUE` to
automatically segment the time range into multiple API calls,
deduplicate boundaries, and return the combined result:

``` r
# Fetch all 1h klines across a 5-month date range (multiple API calls)
all_klines <- market$get_klines("BTCUSDT", "1h",
  startTime = as.POSIXct("2024-01-01", tz = "UTC"),
  endTime = as.POSIXct("2024-06-01", tz = "UTC"),
  fetch_all = TRUE, sleep = 0.5
)

nrow(all_klines)
head(all_klines[, .(open_time, open, high, low, close, volume)])
```

> **Note:** Large date ranges consume multiple API requests. Use the
> `sleep` parameter to respect Binance rate limits. For bulk
> multi-symbol downloads, see
> [`?binance_backfill_klines`](https://dereckmezquita.github.io/binance/reference/binance_backfill_klines.md).

### Server Time

``` r
st <- market$get_server_time()
st
```

    #>            server_time
    #>                 <POSc>
    #> 1: 2017-07-12 02:41:59

------------------------------------------------------------------------

## Trading

The `BinanceTrading` class manages spot orders. All trading endpoints
require authentication.

``` r
trading <- BinanceTrading$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

### Place a Test Order

Test orders validate parameters without executing:

``` r
result <- trading$add_order_test(
  type = "LIMIT",
  symbol = "BTCUSDT",
  side = "BUY",
  price = 50000,
  quantity = 0.0001
)
result
```

    #>     symbol   side   type    status
    #>     <char> <char> <char>    <char>
    #> 1: BTCUSDT    BUY  LIMIT validated

### Place a Real Order

``` r
order <- trading$add_order(
  type = "LIMIT",
  symbol = "BTCUSDT",
  side = "BUY",
  price = 50000,
  quantity = 0.0001,
  timeInForce = "GTC"
)
order
```

### Query an Order

``` r
order <- trading$get_order("BTCUSDT", orderId = 12345)
order
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
open_orders <- trading$get_open_orders("BTCUSDT")
open_orders
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

### Cancel an Order

``` r
cancelled <- trading$cancel_order("BTCUSDT", orderId = 12345)
cancelled
```

------------------------------------------------------------------------

## OCO Orders

An OCO (One-Cancels-Other) order pairs a limit order with a stop-limit
order; when one side fills, the other is cancelled automatically.

``` r
oco <- BinanceOcoOrders$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

``` r
result <- oco$add_order(
  symbol = "BTCUSDT",
  side = "SELL",
  quantity = 0.001,
  price = 110000,          # Limit price (take profit)
  stopPrice = 90000,       # Stop trigger price
  stopLimitPrice = 89500,  # Stop limit price
  stopLimitTimeInForce = "GTC"
)
result
```

### Query OCO Orders

``` r
open_oco <- oco$get_open_oco_orders()
open_oco
```

    #>    order_list_id contingency_type list_status_type list_order_status
    #>            <int>           <char>           <char>            <char>
    #> 1:             0              OCO         ALL_DONE          ALL_DONE
    #> 2:             0              OCO         ALL_DONE          ALL_DONE
    #>      list_client_order_id    transaction_time  symbol order_symbol
    #>                    <char>              <POSc>  <char>       <char>
    #> 1: JYVpp3F0f5CAG15DhtrqLp 2019-07-18 02:38:00 BTCUSDT      BTCUSDT
    #> 2: JYVpp3F0f5CAG15DhtrqLp 2019-07-18 02:38:00 BTCUSDT      BTCUSDT
    #>    order_order_id  order_client_order_id
    #>             <int>                 <char>
    #> 1:             12 bX5wROblo6YeDwa9iTLeyY
    #> 2:             13 Tnu2IP0J5Y4mxw3IATBfmW

------------------------------------------------------------------------

## Account Management

### Account Info

``` r
account <- BinanceAccount$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

``` r
info <- account$get_account_info()
info[, .(maker_commission, taker_commission, can_trade, account_type)]
```

    #>    maker_commission taker_commission can_trade account_type
    #>               <int>            <int>    <lgcl>       <char>
    #> 1:               15               15      TRUE         SPOT

### Trade History

``` r
trades <- account$get_trades("BTCUSDT")
trades
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

------------------------------------------------------------------------

## Deposits

``` r
deposit <- BinanceDeposit$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

### Get Deposit Address

``` r
addr <- deposit$get_deposit_address(coin = "BTC")
addr
```

    #>                               address   coin    tag
    #>                                <char> <char> <char>
    #> 1: 1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv    BTC       
    #>                                                   url
    #>                                                <char>
    #> 1: https://btc.com/1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv

### Deposit History

``` r
history <- deposit$get_deposit_history(coin = "BTC")
history
```

    #>                    id     amount   coin network status
    #>                <char>     <char> <char>  <char>  <int>
    #> 1: 769800519366885376      0.001    BNB     BNB      1
    #> 2: 769800519366885377 0.50000000    ETH     ETH      0
    #>                                       address address_tag
    #>                                        <char>      <char>
    #> 1: bnb136ns6lfw4zs5hg4n85vdthaad7hq5m4gtkgf23   101764890
    #> 2: 0x94df8b352de7f46f64b01d3666bf6e936e44ce60            
    #>                                                               tx_id
    #>                                                              <char>
    #> 1: 98A3EA560C6B3336D348B6C83F0F95ECE4F1F5919E94BD006E5BF3BF264FACFC
    #> 2:                                                   0xabc123def456
    #>            insert_time       complete_time transfer_type confirm_times
    #>                 <POSc>              <POSc>         <int>        <char>
    #> 1: 2022-08-26 05:52:26 2022-08-26 05:54:06             0           1/1
    #> 2: 2022-08-26 05:54:06 1970-01-01 00:00:00             0          5/12
    #>    unlock_confirm wallet_type
    #>             <int>       <int>
    #> 1:              0           0
    #> 2:             12           0

------------------------------------------------------------------------

## Withdrawals

``` r
withdrawal <- BinanceWithdrawal$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

### Withdrawal History

``` r
history <- withdrawal$get_withdrawal_history(coin = "USDT")
history
```

    #>                                  id     amount transaction_fee   coin status
    #>                              <char>     <char>          <char> <char>  <int>
    #> 1: b6ae22b3aa844210a7041aee7589627c 8.91000000           0.004   USDT      6
    #> 2: c7bf33c4bb955321b8152618faa69738 0.10000000          0.0005    BTC      4
    #>                                       address
    #>                                        <char>
    #> 1: 0x94df8b352de7f46f64b01d3666bf6e936e44ce60
    #> 2:         1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv
    #>                                                                 tx_id
    #>                                                                <char>
    #> 1: 0xb5ef8c13b968a406cc62a93a8bd80f9e9a906ef1b3fcf20a2e48573c17659268
    #> 2:                                                                   
    #>             apply_time network transfer_type withdraw_order_id   info
    #>                 <char>  <char>         <int>            <char> <char>
    #> 1: 2019-10-12 11:12:02     ETH             0   WITHDRAWtest123       
    #> 2: 2023-05-01 08:30:00     BTC             0                         
    #>    confirm_no wallet_type tx_key       complete_time
    #>         <int>       <int> <char>              <char>
    #> 1:          3           1        2023-03-23 16:52:41
    #> 2:          0           0

### Submit a Withdrawal

``` r
result <- withdrawal$add_withdrawal(
  coin = "USDT",
  address = "your-trc20-address",
  amount = 10,
  network = "TRX"
)
result
```

------------------------------------------------------------------------

## Fund Transfers

Use `BinanceTransfer` to move assets between wallet types (spot, margin,
futures, funding).

``` r
transfer <- BinanceTransfer$new()
```

``` r
# Transfer 100 USDT from spot to futures
result <- transfer$add_transfer(
  type = "MAIN_UMFUTURE",
  asset = "USDT",
  amount = 100
)
result

# Check transfer history
history <- transfer$get_transfer_history(type = "MAIN_UMFUTURE")
history
```

------------------------------------------------------------------------

## Simple Earn

Use `BinanceEarn` to subscribe to flexible savings products:

``` r
earn <- BinanceEarn$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

### List Available Products

``` r
products <- earn$get_flexible_products()
products
```

    #>     asset latest_annual_percentage_rate can_purchase can_redeem is_sold_out
    #>    <char>                        <char>       <lgcl>     <lgcl>      <lgcl>
    #> 1:   USDT                    0.03250000         TRUE       TRUE       FALSE
    #>       hot min_purchase_amount product_id subscription_start_time     status
    #>    <lgcl>              <char>     <char>                   <num>     <char>
    #> 1:   TRUE          0.10000000    USDT001            1.661493e+12 PURCHASING

### Subscribe

``` r
result <- earn$subscribe_flexible(productId = "BTC001", amount = 0.01)
result
```

### Check Positions

``` r
positions <- earn$get_flexible_position()
positions
```

    #>    total_amount tier_annual_percentage_rate latest_annual_percentage_rate
    #>          <char>                      <lgcl>                        <char>
    #> 1: 100.00000000                          NA                    0.03250000
    #>    yesterday_airdrop_percentage_rate  asset air_drop_asset can_redeem
    #>                               <char> <char>         <char>     <lgcl>
    #> 1:                        0.00008000   USDT           USDT       TRUE
    #>    collateral_amount product_id yesterday_real_time_rewards
    #>               <char>     <char>                      <char>
    #> 1:        0.00000000    USDT001                  0.00800000
    #>    cumulative_bonus_rewards cumulative_real_time_rewards
    #>                      <char>                       <char>
    #> 1:               0.15000000                   0.08000000
    #>    cumulative_total_rewards auto_subscribe
    #>                      <char>         <lgcl>
    #> 1:               0.23000000           TRUE

------------------------------------------------------------------------

## Sub-Account Management

``` r
sub <- BinanceSubAccount$new()
```

    #> Warning: Binance API credentials are empty. Set BINANCE_API_KEY and
    #> BINANCE_API_SECRET environment variables or pass them explicitly.

``` r
subs <- sub$get_sub_accounts()
subs
```

    #>                    email is_freeze         create_time is_managed_sub_account
    #>                   <char>    <lgcl>              <POSc>                 <lgcl>
    #> 1: testsub01@virtual.com     FALSE 2022-08-26 05:52:26                  FALSE
    #> 2: testsub02@virtual.com      TRUE 2022-08-26 05:54:06                  FALSE
    #>    is_asset_management_sub_account
    #>                             <lgcl>
    #> 1:                           FALSE
    #> 2:                           FALSE

------------------------------------------------------------------------

## Clock Drift: Server Time Signing

By default, HMAC request signatures use your local machine’s clock. If
your system time is out of sync with Binance’s servers, authenticated
requests may fail with timestamp errors. You can configure any class to
fetch the server time before each authenticated request:

``` r
# Use server time for signing (adds one round trip per request)
trading <- BinanceTrading$new(time_source = "server")

# All authenticated calls now use the exchange clock
order <- trading$add_order_test(
  type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
  price = 50000, quantity = 0.0001
)
```

The `time_source` parameter is available on all class constructors:
`BinanceTrading`, `BinanceAccount`, `BinanceOcoOrders`,
`BinanceDeposit`, `BinanceWithdrawal`, `BinanceTransfer`,
`BinanceSubAccount`, `BinanceMargin`, `BinanceEarn`, and
`BinanceFutures`.

------------------------------------------------------------------------

## Bulk Historical Data: Backfill Klines

Download historical kline data across multiple symbols and intervals,
with automatic CSV-based resume support:

``` r
binance_backfill_klines(
  symbols = c("BTCUSDT", "ETHUSDT"),
  intervals = c("1d", "4h"),
  from = lubridate::as_datetime("2020-01-01"),
  to = lubridate::now("UTC"),
  file = "my_klines.csv"
)

# Resume an interrupted download — just run the same call again
# It reads the existing CSV and skips completed symbol-interval combos
```

------------------------------------------------------------------------

## Next Steps

- See
  [`vignette("async-usage")`](https://dereckmezquita.github.io/binance/articles/async-usage.md)
  for promise-based asynchronous operation.
- See
  [`vignette("margin-futures-trading")`](https://dereckmezquita.github.io/binance/articles/margin-futures-trading.md)
  for margin and USD-M futures trading.
- Browse the [pkgdown site](https://dereckmezquita.github.io/binance/)
  for full method documentation.
- For bulk historical data, see
  [`?binance_backfill_klines`](https://dereckmezquita.github.io/binance/reference/binance_backfill_klines.md).
