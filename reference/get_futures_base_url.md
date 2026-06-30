# Retrieve Binance Futures API Base URL

Returns the base URL for the Binance USD-M Futures API in the following
priority:

1.  The explicitly provided `url` parameter.

2.  The `BINANCE_FUTURES_API_ENDPOINT` environment variable.

3.  The default `"https://fapi.binance.com"`.

## Usage

``` r
get_futures_base_url(url = Sys.getenv("BINANCE_FUTURES_API_ENDPOINT"))
```

## Arguments

- url:

  (scalar\<character\>?) explicit base URL. Defaults to
  `Sys.getenv("BINANCE_FUTURES_API_ENDPOINT")`.

## Value

(scalar\<character\>) the Futures API base URL.

## Examples

``` r
if (FALSE) { # \dontrun{
get_futures_base_url()
get_futures_base_url("https://testnet.binancefuture.com")
} # }
```
