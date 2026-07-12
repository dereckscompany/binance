# File: R/conditions.R
# Binance's typed API-error condition. Binance has two failure surfaces, both
# funnelled through `parse_binance_response()`: a venue error signalled by a
# negative `code` in the JSON body (which can arrive even on an HTTP 200), and a
# plain non-2xx HTTP status. A single raiser serves both, layering Binance's own
# class family IN FRONT of connectcore's, per the recipe in
# `?connectcore_conditions`. The per-status class is keyed on the HTTP status
# (`connectcore::scrub_url()`-safe `url`); the venue `code` rides along as a
# structured field. A caller can then catch `binance_api_error` (any Binance
# failure), `connectcore_api_error` (any HTTP failure fleet-wide), or
# `connectcore_error` (any transport failure) — reading `e$status` / `e$code` /
# `e$url` / `e$body_snippet` instead of grepping the message text.
#
# Backward compatibility is a hard contract: the message string is byte-identical
# to the bare `rlang::abort()` calls this replaced — "Binance API error <code>:
# <msg>" for the venue-code surface and "Binance HTTP error <status>\n<body>" for
# the HTTP surface. The classes and fields are purely additive.

#' Raise a typed Binance API error
#'
#' Signals a condition classed
#' `c("binance_api_error_<status>", "binance_api_error",`
#' `"connectcore_api_error_<status>", "connectcore_api_error",`
#' `"connectcore_error")` (on top of rlang's error classes), carrying the HTTP
#' `status`, the venue error `code` (negative on Binance failures; `NULL` for a
#' plain HTTP failure), the request `url` (query-string credentials redacted with
#' [connectcore::scrub_url()]), and the response `body_snippet` as structured
#' fields. With `message = NULL` the message defaults to the byte-identical
#' venue-code string `"Binance API error <code>: <msg>"`; the HTTP-status funnel
#' passes its own byte-identical `"Binance HTTP error <status>\n<body>"` string as
#' `message`. See [connectcore::connectcore_conditions] for the taxonomy and the
#' subclass recipe.
#'
#' @param status (scalar<count in [100, 599]>) the HTTP status code. Also names
#'   the most specific classes, `binance_api_error_<status>` and
#'   `connectcore_api_error_<status>`.
#' @param code (scalar<numeric> | NULL) the Binance venue error code (negative on
#'   failure), stored on the `code` field. `NULL` for a plain HTTP failure.
#'   Default `NULL`.
#' @param msg (scalar<character> | NULL) the venue error message; rendered into
#'   the default message after the code. `NULL` renders
#'   `"No error message provided."`. Default `NULL`.
#' @param url (scalar<character> | NULL) the request URL; query-string credentials
#'   are redacted with [connectcore::scrub_url()] before storing on the `url`
#'   field. Default `NULL`.
#' @param body (scalar<character> | NULL) the response body text; stored on the
#'   `body_snippet` field (named `body_snippet`, not `body`, because
#'   `rlang::abort()` reserves `body`). Default `NULL`.
#' @param message (scalar<character> | NULL) the condition message. `NULL`
#'   (default) derives the byte-identical venue-code string from `code` and `msg`;
#'   the HTTP funnel supplies its own string here.
#' @return (class<connectcore_error>) never returns normally; signals the classed
#'   condition described above.
#'
#' @importFrom rlang abort caller_env
#' @keywords internal
#' @noassert
#' @noRd
abort_binance_error <- function(status, code = NULL, msg = NULL, url = NULL, body = NULL, message = NULL) {
  if (is.null(message)) {
    resolved_msg <- if (is.null(msg)) "No error message provided." else msg
    message <- paste0("Binance API error ", code, ": ", resolved_msg)
  }
  return(rlang::abort(
    message = message,
    class = c(
      sprintf("binance_api_error_%d", as.integer(status)),
      "binance_api_error",
      sprintf("connectcore_api_error_%d", as.integer(status)),
      "connectcore_api_error",
      "connectcore_error"
    ),
    status = as.integer(status),
    code = code,
    url = connectcore::scrub_url(url),
    body_snippet = body,
    call = rlang::caller_env()
  ))
}
