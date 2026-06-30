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

  (scalar\<character\>) Binance API key. Defaults to
  `Sys.getenv("BINANCE_API_KEY")`.

- api_secret:

  (scalar\<character\>) Binance API secret. Defaults to
  `Sys.getenv("BINANCE_API_SECRET")`.

## Value

(list) named list with `api_key` and `api_secret`:

- api_key (scalar\<character\>) the API key.

- api_secret (scalar\<character\>) the API secret.

## Examples

``` r
if (FALSE) { # \dontrun{
keys <- get_api_keys()
keys <- get_api_keys(api_key = "my_key", api_secret = "my_secret")
} # }
```
