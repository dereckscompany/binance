# Verify Ticker Symbol Format

Checks whether a ticker symbol matches Binance's concatenated format
(e.g., `"BTCUSDT"`), consisting of uppercase alphanumeric characters
with no separator.

## Usage

``` r
verify_symbol(ticker)
```

## Arguments

- ticker:

  Character string; the ticker symbol to verify.

## Value

Logical; `TRUE` if valid, `FALSE` otherwise.

## Examples

``` r
if (FALSE) { # \dontrun{
verify_symbol("BTCUSDT")   # TRUE
verify_symbol("ETHBTC")    # TRUE
verify_symbol("BTC-USDT")  # FALSE
} # }
```
