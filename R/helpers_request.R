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
#' @param base_url Character; the API base URL.
#' @param time_endpoint Character; the server-time endpoint path. Default
#'   `"/api/v3/time"`.
#' @return Numeric; server time in epoch milliseconds.
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
#' @param req An [httr2::request] object to sign.
#' @param keys List of API credentials containing `api_key` and `api_secret`.
#' @param .get_timestamp_ms Function or NULL; zero-argument function returning
#'   epoch milliseconds. When `NULL` (default), falls back to the local UTC clock.
#' @return The signed [httr2::request] object with authentication applied.
#'
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
#' @param base_url Character; the API base URL.
#' @param endpoint Character; the API path.
#' @param method Character; HTTP method. Default `"GET"`.
#' @param query Named list; query parameters. Default `list()`.
#' @param body Named list or NULL; request body (for POST). Default `NULL`.
#' @param keys List or NULL; API credentials. Default `NULL`.
#' @param .perform Function; the httr2 perform function. Default `httr2::req_perform`.
#' @param .parser Function; post-processing function applied to parsed response.
#'   Default `identity`.
#' @param is_async Logical; whether `.perform` returns promises. Default `FALSE`.
#' @param timeout Numeric; request timeout in seconds. Default `10`.
#' @param .get_timestamp_ms Function or NULL; zero-argument function returning
#'   epoch milliseconds for HMAC signing.
#' @return Parsed and post-processed API response data, or a promise thereof.
#'
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
#' @param resp An [httr2::response] object.
#' @return The parsed JSON response data.
#'
#' @importFrom httr2 resp_status resp_body_json resp_body_string
#' @importFrom rlang abort
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
    rlang::abort(paste0(
      "Binance API error ",
      parsed$code,
      ": ",
      if (is.null(parsed$msg)) "No error message provided." else parsed$msg
    ))
  }

  if (status < 200L || status >= 300L) {
    body_text <- tryCatch(
      httr2::resp_body_string(resp),
      error = function(e) "<unable to read body>"
    )
    rlang::abort(paste0("Binance HTTP error ", status, "\n", body_text))
  }

  return(parsed)
}
