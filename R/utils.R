# File: R/utils.R
# General utility functions for the binance package.

#' Retrieve Binance API Base URL
#'
#' Returns the base URL for the Binance API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `BINANCE_API_ENDPOINT` environment variable.
#' 3. The default `"https://api.binance.com"`.
#'
#' @param url (scalar<character>?) explicit base URL. Defaults to
#'   `Sys.getenv("BINANCE_API_ENDPOINT")`.
#' @return (scalar<character>) the API base URL.
#'
#' @examples
#' \dontrun{
#' get_base_url()
#' get_base_url("https://testnet.binance.vision")
#' }
#' @export
get_base_url <- function(url = Sys.getenv("BINANCE_API_ENDPOINT")) {
  assert_args_get_base_url(url)
  if (is.null(url) || !nzchar(url)) {
    return(assert_return_get_base_url("https://api.binance.com"))
  }
  return(assert_return_get_base_url(url))
}

#' Retrieve Binance API Credentials
#'
#' Fetches API credentials from environment variables or explicit arguments.
#' Required environment variables: `BINANCE_API_KEY`, `BINANCE_API_SECRET`.
#'
#' @param api_key (scalar<character>) Binance API key. Defaults to `Sys.getenv("BINANCE_API_KEY")`.
#' @param api_secret (scalar<character>) Binance API secret. Defaults to `Sys.getenv("BINANCE_API_SECRET")`.
#' @return (list) named list with `api_key` and `api_secret`:
#' - api_key (scalar<character>) the API key.
#' - api_secret (scalar<character>) the API secret.
#'
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' keys <- get_api_keys(api_key = "my_key", api_secret = "my_secret")
#' }
#' @export
get_api_keys <- function(
  api_key = Sys.getenv("BINANCE_API_KEY"),
  api_secret = Sys.getenv("BINANCE_API_SECRET")
) {
  assert_args_get_api_keys(api_key, api_secret)
  if (!nzchar(api_key) || !nzchar(api_secret)) {
    rlang::warn(paste0(
      "Binance API credentials are empty. ",
      "Set BINANCE_API_KEY and BINANCE_API_SECRET environment variables or pass them explicitly."
    ))
  }
  return(assert_return_get_api_keys(list(
    api_key = api_key,
    api_secret = api_secret
  )))
}

#' Verify Ticker Symbol Format
#'
#' Checks whether a ticker symbol matches Binance's concatenated format
#' (e.g., `"BTCUSDT"`), consisting of uppercase alphanumeric characters
#' with no separator.
#'
#' @param ticker (scalar<character>) the ticker symbol to verify.
#' @return (scalar<logical>) `TRUE` if valid, `FALSE` otherwise.
#'
#' @examples
#' \dontrun{
#' verify_symbol("BTCUSDT")   # TRUE
#' verify_symbol("ETHBTC")    # TRUE
#' verify_symbol("BTC-USDT")  # FALSE
#' }
#' @export
verify_symbol <- function(ticker) {
  assert_args_verify_symbol(ticker)
  return(assert_return_verify_symbol(grepl("^[A-Za-z0-9]+$", ticker)))
}

#' Retrieve Binance Futures API Base URL
#'
#' Returns the base URL for the Binance USD-M Futures API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `BINANCE_FUTURES_API_ENDPOINT` environment variable.
#' 3. The default `"https://fapi.binance.com"`.
#'
#' @param url (scalar<character>?) explicit base URL. Defaults to
#'   `Sys.getenv("BINANCE_FUTURES_API_ENDPOINT")`.
#' @return (scalar<character>) the Futures API base URL.
#'
#' @examples
#' \dontrun{
#' get_futures_base_url()
#' get_futures_base_url("https://testnet.binancefuture.com")
#' }
#' @export
get_futures_base_url <- function(url = Sys.getenv("BINANCE_FUTURES_API_ENDPOINT")) {
  assert_args_get_futures_base_url(url)
  if (is.null(url) || !nzchar(url)) {
    return(assert_return_get_futures_base_url("https://fapi.binance.com"))
  }
  return(assert_return_get_futures_base_url(url))
}
