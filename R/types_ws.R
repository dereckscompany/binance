# File: R/types_ws.R
# Reusable roxyassert @type definitions for the WebSocket stream clients. Each
# type is declared once here and referenced by name (e.g. `(Speed)`) wherever it
# appears in the WS classes/helpers, so a vocabulary or constraint is written in
# exactly one place and every check derives from it.

#' WebSocket stream types
#'
#' @type Speed (scalar<character in c("1000ms", "100ms")>)
#' @type WsEvent (scalar<character in c("open", "message", "close", "error")>)
#' @type ControlMethod (scalar<character in c("SUBSCRIBE", "UNSUBSCRIBE", "LIST_SUBSCRIPTIONS")>)
#' @type ReconnectLimit (scalar<count in [1, Inf[>)
#' @noRd
NULL
