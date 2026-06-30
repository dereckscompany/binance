# Convert POSIXct to Binance Timestamp

Converts a POSIXct object into a UNIX timestamp in the specified unit.

## Usage

``` r
time_convert_to_binance(datetime, unit = c("ms", "ns", "s"))
```

## Arguments

- datetime:

  (scalar\<POSIXct\>) POSIXct object to convert.

- unit:

  (scalar\<character in c("ms", "ns", "s")\>) output unit: `"ms"`
  (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).

## Value

(scalar\<numeric\> \| scalar\<integer\>) UNIX timestamp in the specified
unit (an integer for `"s"`, a double otherwise).

## Examples

``` r
if (FALSE) { # \dontrun{
dt <- lubridate::as_datetime("2023-10-31 16:00:00", tz = "UTC")
time_convert_to_binance(dt, unit = "ms")  # 1698768000000
time_convert_to_binance(dt, unit = "s")   # 1698768000
} # }
```
