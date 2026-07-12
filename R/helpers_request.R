# File: R/helpers_request.R
# Binance-specific request helpers layered over the connectcore transport base.
# The request funnel, sync/async branching, retry, and throttle all live in
# connectcore; this file keeps only what is genuinely Binance-specific — the
# HMAC-query signer (X-MBX-APIKEY) and the negative-code error envelope — plus
# thin compatibility wrappers (`fetch_server_time_ms`, `binance_build_request`)
# that preserve the package's historical signatures.

#' Fetch Binance Server Time (Milliseconds)
#'
#' Makes a lightweight synchronous `GET /api/v3/time` request and returns
#' the server's epoch time in milliseconds. Used internally when
#' `time_source = "server"` to avoid clock-drift issues with HMAC signing.
#' Thin wrapper over [connectcore::fetch_server_time_ms()] that defaults the
#' endpoint to the spot one (subclasses pass the futures endpoint).
#'
#' @param base_url (scalar<character>) the API base URL.
#' @param time_endpoint (scalar<character>) the server-time endpoint path. Default
#'   `"/api/v3/time"`.
#' @return (scalar<numeric>) server time in epoch milliseconds.
#' @noassert
#' @keywords internal
#' @noRd
fetch_server_time_ms <- function(base_url, time_endpoint = "/api/v3/time") {
  return(connectcore::fetch_server_time_ms(base_url, time_endpoint, field = "serverTime"))
}

#' Sign an httr2 Request for Binance Authentication
#'
#' Adds the `X-MBX-APIKEY` header and appends `timestamp` and `signature`
#' query parameters to an [httr2::request] object using HMAC-SHA256. A thin
#' wrapper over [connectcore::hmac_query_sign()] fixing Binance's header name.
#'
#' @param req (class<httr2_request>) an [httr2::request] object to sign.
#' @param keys (list) API credentials containing `api_key` and `api_secret`:
#' - api_key (scalar<character>) the API key.
#' - api_secret (scalar<character>) the API secret.
#' @param .get_timestamp_ms (function?) zero-argument function returning epoch
#'   milliseconds. When `NULL` (default), falls back to the local UTC clock.
#' @return (class<httr2_request>) the signed [httr2::request] object with
#'   authentication applied.
#'
#' @noassert
#' @keywords internal
#' @noRd
sign_request <- function(req, keys, .get_timestamp_ms = NULL) {
  return(connectcore::hmac_query_sign(
    req,
    keys,
    get_timestamp_ms = .get_timestamp_ms,
    api_key_header = "X-MBX-APIKEY"
  ))
}

#' Build and Execute a Binance API Request
#'
#' Constructs an [httr2::request], optionally signs it, performs it via the supplied
#' `.perform` function, and parses the JSON response. This is the single
#' point through which all Binance API calls flow. A thin wrapper over
#' [connectcore::build_request()] that injects Binance's signer and error
#' envelope and carries signed parameters in the query string
#' (`body_format = "query"`).
#'
#' @param base_url (scalar<character>) the API base URL.
#' @param endpoint (scalar<character>) the API path.
#' @param method (scalar<character>) HTTP method. Default `"GET"`.
#' @param query (list) query parameters. Default `list()`.
#' @param body (list | NULL) request body (for POST). Default `NULL`.
#' @param keys (list | NULL) API credentials. Default `NULL`.
#' @param .perform (function) the httr2 perform function. Default `httr2::req_perform`.
#' @param .parser (function) post-processing function applied to parsed response.
#'   Default `identity`.
#' @param is_async (scalar<logical>) whether `.perform` returns promises. Default `FALSE`.
#' @param timeout (scalar<numeric in ]0, Inf[>) request timeout in seconds. Default `10`.
#' @param max_tries (scalar<count in [1, Inf[>) retry up to this many times with
#'   backoff on a transient failure — a timeout, a dropped connection, a 5xx, or
#'   a 429. `1` (default) disables retry. Enable this only for idempotent GETs
#'   (never for order placement, where a resend could double-submit).
#' @param .get_timestamp_ms (function?) zero-argument function returning epoch
#'   milliseconds for HMAC signing.
#' @return (promise<any>) parsed and post-processed API response data, or a
#'   promise thereof.
#'
#' @noassert
#' @export
binance_build_request <- function(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  timeout = 10,
  max_tries = 1L,
  .get_timestamp_ms = NULL
) {
  return(connectcore::build_request(
    base_url = base_url,
    endpoint = endpoint,
    method = method,
    query = query,
    body = body,
    keys = keys,
    sign = function(req, keys, ctx) sign_request(req, keys, ctx$get_timestamp_ms),
    parse_envelope = parse_binance_response,
    body_format = "query",
    .perform = .perform,
    .parser = .parser,
    is_async = is_async,
    timeout = timeout,
    max_tries = max_tries,
    ctx = list(get_timestamp_ms = .get_timestamp_ms)
  ))
}

#' Parse and Validate a Binance API Response
#'
#' Extracts JSON from an [httr2::response], validates the HTTP status and checks
#' for Binance error codes, and returns the parsed data. This is Binance's
#' venue-specific error envelope: a negative `code` in the JSON body signals an
#' API error even on a non-200 status.
#'
#' @param resp (class<httr2_response>) an [httr2::response] object.
#' @return (any) the parsed JSON response data.
#'
#' @importFrom httr2 resp_status resp_body_json resp_body_string
#' @importFrom rlang abort
#' @noassert
#' @keywords internal
#' @noRd
parse_binance_response <- function(resp) {
  status <- httr2::resp_status(resp)

  parsed <- tryCatch(
    httr2::resp_body_json(resp, simplifyVector = FALSE),
    error = function(e) NULL
  )

  # Binance returns error codes in the JSON body even on non-200 status

  if (!is.null(parsed) && !is.null(parsed$code) && parsed$code < 0) {
    body_text <- tryCatch(httr2::resp_body_string(resp), error = function(e) NULL)
    abort_binance_error(
      status = status,
      code = parsed$code,
      msg = parsed$msg,
      url = resp$url,
      body = body_text
    )
  }

  if (status < 200L || status >= 300L) {
    body_text <- tryCatch(
      httr2::resp_body_string(resp),
      error = function(e) "<unable to read body>"
    )
    abort_binance_error(
      status = status,
      url = resp$url,
      body = body_text,
      message = paste0("Binance HTTP error ", status, "\n", body_text)
    )
  }

  return(parsed)
}
