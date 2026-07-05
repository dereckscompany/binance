# BTC-USDT 4-Hour OHLCV Data from Binance

Historical candlestick (OHLCV) data for BTCUSDT on the Binance exchange
at 4-hour intervals. Contains 500 candles of sample data for
demonstration purposes. Produced by
[`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md).

## Usage

``` r
binance_btc_usdt_4h_ohlcv
```

## Format

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with 500 rows and 14 columns:

- `datetime` (POSIXct): Candle open time in UTC (the bar-reference
  time).

- `open` (Numeric): Opening price.

- `high` (Numeric): Highest price during the interval.

- `low` (Numeric): Lowest price during the interval.

- `close` (Numeric): Closing price.

- `volume` (Numeric): Trading volume in base currency (BTC).

- `close_time` (POSIXct): Candle close time in UTC.

- `quote_volume` (Numeric): Trading volume in quote currency (USDT).

- `trades` (Integer): Number of trades during the interval.

- `taker_buy_base_volume` (Numeric): Taker buy volume in base currency.

- `taker_buy_quote_volume` (Numeric): Taker buy volume in quote
  currency.

- `ignore` (Character): Unused field from Binance API.

- `symbol` (Character): Trading pair identifier, `"BTCUSDT"`.

- `interval` (Character): Candle interval, `"4h"`.

## Source

Binance API via
[`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)

## Examples

``` r
data(binance_btc_usdt_4h_ohlcv)
head(binance_btc_usdt_4h_ohlcv)
#>               datetime     open     high      low    close volume
#>                 <POSc>    <num>    <num>    <num>    <num>  <num>
#> 1: 2024-01-01 00:00:00 42000.00 42099.44 41921.66 41883.96 534.70
#> 2: 2024-01-01 04:00:00 42279.19 42430.65 42062.94 42224.05 550.12
#> 3: 2024-01-01 08:00:00 42171.25 42316.99 42045.05 42162.67 444.42
#> 4: 2024-01-01 12:00:00 42248.88 42348.75 42100.34 42155.15 155.05
#> 5: 2024-01-01 16:00:00 42380.45 42487.25 42261.60 42468.64  98.66
#> 6: 2024-01-01 20:00:00 42466.30 42530.30 42416.10 42391.80 241.64
#>             close_time quote_volume trades taker_buy_base_volume
#>                 <POSc>        <num>  <int>                 <num>
#> 1: 2024-01-01 03:59:59     22457400   5997                235.75
#> 2: 2024-01-01 07:59:59     23258629   6234                241.07
#> 3: 2024-01-01 11:59:59     18741748   4990                199.67
#> 4: 2024-01-01 15:59:59      6550688   4817                 78.46
#> 5: 2024-01-01 19:59:59      4181255   5799                 43.69
#> 6: 2024-01-01 23:59:59     10261558   6177                 97.91
#>    taker_buy_quote_volume ignore  symbol interval
#>                     <num> <char>  <char>   <char>
#> 1:                9901500      0 BTCUSDT       4h
#> 2:               10192245      0 BTCUSDT       4h
#> 3:                8420334      0 BTCUSDT       4h
#> 4:                3314847      0 BTCUSDT       4h
#> 5:                1851602      0 BTCUSDT       4h
#> 6:                4157876      0 BTCUSDT       4h
```
