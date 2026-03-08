# File: R/helpers_request.R
# Core HTTP request infrastructure for the binance package.
# Provides sign_request(), binance_build_request().

#' Apply Continuation to a Value or Promise
#'
#' Routes a value through `fn` either synchronously or asynchronously depending on
#' whether the caller is in async mode. This is the single sync/async branching
#' point in the package.
#'
#' @param x A value or a [promises::promise].
#' @param fn A function to apply to the resolved value of `x`.
#' @param is_async Logical; whether the caller is in async mode.
#' @return If `is_async`, returns `promises::then(x, fn)`. Otherwise returns `fn(x)`.
#' @keywords internal
#' @noRd
then_or_now <- function(x, fn, is_async = FALSE) {
  if (is_async) {
    return(promises::then(x, fn))
  }
  return(fn(x))
}

#' Fetch Binance Server Time (Milliseconds)
#'
#' Makes a lightweight synchronous `GET /api/v3/time` request and returns
#' the server's epoch time in milliseconds. Used internally when
#' `time_source = "server"` to avoid clock-drift issues with HMAC signing.
#'
#' @param base_url Character; the API base URL.
#' @return Numeric; server time in epoch milliseconds.
#' @keywords internal
#' @noRd
fetch_server_time_ms <- function(base_url) {
  req <- httr2::request(base_url)
  req <- httr2::req_url_path_append(req, "/api/v3/time")
  req <- httr2::req_method(req, "GET")
  req <- httr2::req_timeout(req, 5)
  resp <- httr2::req_perform(req)
  parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  if (is.null(parsed$serverTime)) {
    rlang::abort("Failed to fetch Binance server time: unexpected response format.")
  }
  return(as.numeric(parsed$serverTime))
}

#' Sign an httr2 Request for Binance Authentication
#'
#' Adds the `X-MBX-APIKEY` header and appends `timestamp` and `signature`
#' query parameters to an [httr2::request] object using HMAC-SHA256.
#'
#' @param req An [httr2::request] object to sign.
#' @param keys List of API credentials containing `api_key` and `api_secret`.
#' @param .get_timestamp_ms Function or NULL; zero-argument function returning
#'   epoch milliseconds. When `NULL` (default), falls back to `Sys.time()`.
#' @return The signed [httr2::request] object with authentication applied.
#'
#' @importFrom digest hmac
#' @importFrom httr2 req_headers req_url_query url_parse
#' @keywords internal
#' @noRd
sign_request <- function(req, keys, .get_timestamp_ms = NULL) {
  if (is.null(.get_timestamp_ms)) {
    .get_timestamp_ms <- function() floor(as.numeric(Sys.time()) * 1000)
  }
  timestamp <- format(.get_timestamp_ms(), scientific = FALSE)

  # Add timestamp to query
  req <- httr2::req_url_query(req, timestamp = timestamp)

  # Extract full query string for signing
  parsed_url <- httr2::url_parse(req$url)
  query_string <- ""
  if (length(parsed_url$query) > 0) {
    query_string <- paste0(names(parsed_url$query), "=", parsed_url$query, collapse = "&")
  }

  # Compute HMAC-SHA256 signature (hex-encoded)
  signature <- digest::hmac(
    key = keys$api_secret,
    object = query_string,
    algo = "sha256",
    serialize = FALSE
  )

  # Add signature and API key header
  req <- httr2::req_url_query(req, signature = signature)
  req <- httr2::req_headers(req, `X-MBX-APIKEY` = keys$api_key)

  return(req)
}

#' Build and Execute a Binance API Request
#'
#' Constructs an [httr2::request], optionally signs it, performs it via the supplied
#' `.perform` function, and parses the JSON response. This is the single
#' point through which all Binance API calls flow.
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
#' @importFrom httr2 request req_method req_url_path_append req_url_query req_body_form
#'   req_timeout req_perform url_parse
#' @importFrom jsonlite toJSON
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
  req <- httr2::request(base_url)
  req <- httr2::req_url_path_append(req, endpoint)
  req <- httr2::req_method(req, method)
  req <- httr2::req_timeout(req, timeout)

  # Add query parameters (drop NULLs)
  query <- query[!vapply(query, is.null, logical(1))]
  if (length(query) > 0) {
    req <- httr2::req_url_query(req, !!!query)
  }

  # For POST with body, add as form-encoded query parameters
  # Binance uses query string parameters for signed endpoints, not JSON body
  if (!is.null(body)) {
    body <- body[!vapply(body, is.null, logical(1))]
    if (length(body) > 0) {
      req <- httr2::req_url_query(req, !!!body)
    }
  }

  # Suppress httr2 auto-error so parse_binance_response handles errors
  req <- httr2::req_error(req, is_error = function(resp) FALSE)

  # Sign if authenticated
  if (!is.null(keys)) {
    req <- sign_request(req, keys, .get_timestamp_ms = .get_timestamp_ms)
  }

  result <- .perform(req)

  # Single branching point: parse response then apply .parser
  return(then_or_now(
    result,
    function(resp) {
      data <- parse_binance_response(resp)
      return(.parser(data))
    },
    is_async = is_async
  ))
}

#' Parse and Validate a Binance API Response
#'
#' Extracts JSON from an [httr2::response], validates the HTTP status and checks
#' for Binance error codes, and returns the parsed data.
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
      parsed$msg %||% "No error message provided."
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
