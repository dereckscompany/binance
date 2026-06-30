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

  (character) trading pair symbols (e.g., `c("BTCUSDT", "ETHUSDT")`).
  Must not be NULL or empty.

- timeframes:

  (character) candle timeframes (e.g., `c("1d", "1h")`). Valid values:
  `"1s"`, `"1m"`, `"3m"`, `"5m"`, `"15m"`, `"30m"`, `"1h"`, `"2h"`,
  `"4h"`, `"6h"`, `"8h"`, `"12h"`, `"1d"`, `"3d"`, `"1w"`, `"1M"`.

- from:

  (scalar\<POSIXct\> \| scalar\<numeric\>) start of the backfill window.
  Defaults to one year ago. Values before `"2017-07-01"` (or `-Inf`) are
  clamped to `"2017-07-01"` since Binance data does not exist before
  that date.

- to:

  (scalar\<POSIXct\> \| scalar\<numeric\>) end of the backfill window.
  Defaults to current time. `Inf` is replaced with current time.

- file:

  (scalar\<character\>) path to the output CSV file. Data is appended
  incrementally so progress is saved even if the process is interrupted.

- base_url:

  (scalar\<character\>) Binance API base URL.

- sleep:

  (scalar\<numeric in \[0, Inf\[\>) seconds to sleep between each
  symbol-timeframe combination to respect rate limits.

- verbose:

  (scalar\<logical\>) if `TRUE`, prints progress messages via
  [`rlang::inform()`](https://rlang.r-lib.org/reference/abort.html).

## Value

(scalar\<character\>) the file path (invisibly).

Per-combo failures are surfaced as warnings during the run (one
[`rlang::warn()`](https://rlang.r-lib.org/reference/abort.html) per
failed `(symbol, timeframe)` pair, with the underlying error message).
After the loop, if any combinations failed, a final summary warning
lists the count and the affected pairs. No failure data is hidden on the
return value.

## Details

Only **closed** candles are persisted: the candle still forming at the
live edge (one whose `close_time` is in the future) is dropped before
writing, so a half-built candle is never stored. Because resume advances
past the last stored candle, an unclosed candle written once would never
be refreshed to its final values — dropping it means the next run
re-fetches and completes it. Closed historical candles are unaffected.

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
