# File: R/types_ws.R
# Reusable roxyassert @type definitions for the WebSocket stream clients. Each
# type is declared once here and referenced by name (e.g. `(Speed)`) wherever it
# appears in the WS classes/helpers, so a vocabulary or constraint is written in
# exactly one place and every check derives from it.

#' Update cadence of a depth stream
#'
#' @type Speed (scalar<character in c("1000ms", "100ms")>)
#' @noRd
NULL

#' A WebSocket event name (the `$on()` vocabulary)
#'
#' @type WsEvent (scalar<character in c("open", "message", "close", "error")>)
#' @noRd
NULL

#' A stream control method
#'
#' @type ControlMethod (scalar<character in c("SUBSCRIBE", "UNSUBSCRIBE", "LIST_SUBSCRIPTIONS")>)
#' @noRd
NULL

#' Maximum consecutive failed reconnects before giving up
#'
#' @type ReconnectLimit (scalar<count in [1, Inf[>)
#' @noRd
NULL
