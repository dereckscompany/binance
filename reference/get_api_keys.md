# Retrieve Binance API Credentials

Fetches API credentials from environment variables or explicit
arguments. Required environment variables: `BINANCE_API_KEY`,
`BINANCE_API_SECRET`.

## Usage

``` r
get_api_keys(
  api_key = Sys.getenv("BINANCE_API_KEY"),
  api_secret = Sys.getenv("BINANCE_API_SECRET")
)
```

## Arguments

- api_key:

  Character string; Binance API key. Defaults to
  `Sys.getenv("BINANCE_API_KEY")`.

- api_secret:

  Character string; Binance API secret. Defaults to
  `Sys.getenv("BINANCE_API_SECRET")`.

## Value

Named list with `api_key` and `api_secret`.

## Examples

``` r
if (FALSE) { # \dontrun{
keys <- get_api_keys()
keys <- get_api_keys(api_key = "my_key", api_secret = "my_secret")
} # }
```
