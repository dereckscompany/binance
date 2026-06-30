# Convert Binance Timestamp to POSIXct

Converts a UNIX timestamp from Binance's API into a POSIXct object in
UTC.

## Usage

``` r
time_convert_from_binance(time_value, unit = c("ms", "ns", "s"))
```

## Arguments

- time_value:

  (scalar\<numeric\>) the UNIX timestamp.

- unit:

  (scalar\<character in c("ms", "ns", "s")\>) input unit: `"ms"`
  (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).

## Value

(scalar\<POSIXct\>) POSIXct object in UTC.

## Examples

``` r
if (FALSE) { # \dontrun{
time_convert_from_binance(1698777600000, unit = "ms")
time_convert_from_binance(1698777600000000000, unit = "ns")
time_convert_from_binance(1698777600, unit = "s")
} # }
```
