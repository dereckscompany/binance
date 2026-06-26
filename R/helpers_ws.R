# File: R/helpers_ws.R
# Pure, connection-free helpers for the WebSocket stream clients
# (BinanceWsBase / BinanceMarketStream). Unit-testable in isolation, and — like
# the public methods — typed and asserted via roxyassert (the type renders in the
# docs and generates the runtime check from one source). Named types it uses
# (`Speed`, `ControlMethod`) are defined in `types_ws.R`.

#' Build a Binance stream control message (SUBSCRIBE / UNSUBSCRIBE)
#'
#' Serialises the JSON control frame Binance expects on a live market-stream
#' connection. `params` is always encoded as a JSON array, even for a single
#' stream, so a one-element subscription is not accidentally unboxed to a scalar.
#'
#' @param method (ControlMethod) the control method.
#' @param params (character) stream names (lower-case, e.g. `"btcusdt@depth"`).
#' @param id (scalar<count in [1, Inf[>) client request id echoed back by the server.
#' @return (scalar<character>) a single-line JSON string ready to `$send()`.
#' @importFrom jsonlite toJSON
#' @keywords internal
#' @noRd
ws_control_message <- function(method, params, id) {
  assert_args_ws_control_message(method, params, id)
  return(assert_return_ws_control_message(as.character(jsonlite::toJSON(
    list(method = method, params = as.list(params), id = id),
    auto_unbox = TRUE
  ))))
}

#' Diff-depth stream name for a symbol
#'
#' Builds the `<symbol>@depth` (1000 ms, Binance default) or `<symbol>@depth@100ms`
#' stream name. The symbol is lower-cased, as Binance requires for stream paths.
#'
#' @param symbol (scalar<character>) trading pair (e.g. `"BTCUSDT"`).
#' @param speed (Speed) `"1000ms"` (default) or `"100ms"`.
#' @return (scalar<character>) the stream name (e.g. `"btcusdt@depth@100ms"`).
#' @keywords internal
#' @noRd
ws_depth_stream <- function(symbol, speed = "1000ms") {
  assert_args_ws_depth_stream(symbol, speed)
  name <- paste0(tolower(symbol), "@depth")
  if (speed == "100ms") {
    name <- paste0(name, "@100ms")
  }
  return(assert_return_ws_depth_stream(name))
}

#' Full-jitter exponential reconnect backoff (seconds)
#'
#' Returns a randomised delay that grows as `2^attempt` but is capped, so a flood
#' of reconnect attempts can never trip Binance's 300-connections-per-5-minutes
#' limit. Mirrors the algorithm used by the reference Binance clients.
#'
#' @param attempt (scalar<count in [1, Inf[>) the reconnect attempt number (1, 2, 3, ...).
#' @param cap_seconds (scalar<numeric in ]0, Inf[>) maximum delay before the jitter
#'   floor. Default 60.
#' @return (scalar<numeric in [1, Inf[>) a delay in seconds, always `>= 1`.
#' @importFrom stats runif
#' @keywords internal
#' @noRd
ws_backoff_delay <- function(attempt, cap_seconds = 60) {
  assert_args_ws_backoff_delay(attempt, cap_seconds)
  expo <- 2^attempt - 1
  return(assert_return_ws_backoff_delay(round(stats::runif(1) * min(cap_seconds, expo) + 1)))
}
