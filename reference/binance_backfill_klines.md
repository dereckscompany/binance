# Backfill Binance Kline Data to CSV

Downloads historical OHLCV candlestick data for one or more trading
pairs and timeframes, writing results incrementally to a CSV file.
Supports resuming from a partially completed backfill by reading the
existing file and skipping symbol-timeframe combinations that are
already up to date.

## Usage

``` r
binance_backfill_klines(
  symbols,
  timeframes = "1d",
  from = lubridate::now("UTC") - lubridate::ddays(365),
  to = lubridate::now("UTC"),
  file = "binance_klines.csv",
  base_url = "https://api.binance.com",
  sleep = 0.3,
  verbose = TRUE
)
```

## Arguments

- symbols:

  Character vector of trading pair symbols (e.g.,
  `c("BTCUSDT", "ETHUSDT")`). Must not be NULL or empty.

- timeframes:

  Character vector of candle timeframes (e.g., `c("1d", "1h")`). Valid
  values: `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`, `"1h"`,
  `"2h"`, `"4h"`, `"6h"`, `"8h"`, `"12h"`, `"1d"`, `"3d"`, `"1w"`,
  `"1M"`.

- from:

  POSIXct or numeric; start of the backfill window. Defaults to one year
  ago. Values before `"2017-07-01"` (or `-Inf`) are clamped to
  `"2017-07-01"` since Binance data does not exist before that date.

- to:

  POSIXct or numeric; end of the backfill window. Defaults to current
  time. `Inf` is replaced with current time.

- file:

  Character; path to the output CSV file. Data is appended incrementally
  so progress is saved even if the process is interrupted.

- base_url:

  Character; Binance API base URL.

- sleep:

  Numeric; seconds to sleep between each symbol-timeframe combination to
  respect rate limits.

- verbose:

  Logical; if `TRUE`, prints progress messages via
  [`rlang::inform()`](https://rlang.r-lib.org/reference/abort.html).

## Value

The file path (invisibly). If any symbol-timeframe combinations failed,
a `"failures"` attribute is attached containing a
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with columns `symbol`, `timeframe`, and `error`.

## Examples

``` r
if (FALSE) { # \dontrun{
binance_backfill_klines(
  symbols = c("BTCUSDT", "ETHUSDT"),
  timeframes = c("1d", "1h"),
  from = lubridate::as_datetime("2020-01-01"),
  file = "my_klines.csv"
)
} # }
```
