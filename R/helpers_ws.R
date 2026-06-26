# File: R/helpers_ws.R
# Pure, connection-free helpers for the WebSocket stream clients
# (BinanceWsBase / BinanceMarketStream). Unit-testable in isolation.

#' Build a Binance stream control message (SUBSCRIBE / UNSUBSCRIBE)
#'
#' Serialises the JSON control frame Binance expects on a live market-stream
#' connection. `params` is always encoded as a JSON array, even for a single
#' stream, so a one-element subscription is not accidentally unboxed to a scalar.
#'
#' @param method Character; `"SUBSCRIBE"`, `"UNSUBSCRIBE"`, or `"LIST_SUBSCRIPTIONS"`.
#' @param params Character vector; stream names (lower-case, e.g. `"btcusdt@depth"`).
#' @param id Integer; client request id echoed back by the server.
#' @return Character; a single-line JSON string ready to `$send()`.
#' @importFrom jsonlite toJSON
#' @keywords internal
#' @noRd
ws_control_message <- function(method, params, id) {
  return(as.character(jsonlite::toJSON(
    list(method = method, params = as.list(params), id = id),
    auto_unbox = TRUE
  )))
}

#' Diff-depth stream name for a symbol
#'
#' Builds the `<symbol>@depth` (1000 ms, Binance default) or `<symbol>@depth@100ms`
#' stream name. The symbol is lower-cased, as Binance requires for stream paths.
#'
#' @param symbol Character; trading pair (e.g. `"BTCUSDT"`).
#' @param speed Character; `"1000ms"` (default) or `"100ms"`.
#' @return Character; the stream name (e.g. `"btcusdt@depth@100ms"`).
#' @keywords internal
#' @noRd
ws_depth_stream <- function(symbol, speed = c("1000ms", "100ms")) {
  speed <- match.arg(speed)
  name <- paste0(tolower(symbol), "@depth")
  if (speed == "100ms") {
    return(paste0(name, "@100ms"))
  }
  return(name)
}

#' Full-jitter exponential reconnect backoff (seconds)
#'
#' Returns a randomised delay that grows as `2^attempt` but is capped, so a flood
#' of reconnect attempts can never trip Binance's 300-connections-per-5-minutes
#' limit. Mirrors the algorithm used by the reference Binance clients.
#'
#' @param attempt Integer; the reconnect attempt number (1, 2, 3, ...).
#' @param cap_seconds Numeric; maximum delay before the jitter floor. Default 60.
#' @return Numeric; a delay in seconds, always `>= 1`.
#' @importFrom stats runif
#' @keywords internal
#' @noRd
ws_backoff_delay <- function(attempt, cap_seconds = 60) {
  expo <- 2^attempt - 1
  return(round(stats::runif(1) * min(cap_seconds, expo) + 1))
}
