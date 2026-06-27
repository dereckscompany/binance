# File: R/BinanceWsBase.R
# Abstract R6 base class for Binance WebSocket market-stream clients.

#' BinanceWsBase: Abstract Base Class for Binance WebSocket Streams
#'
#' Node.js-style event-driven base for Binance's public market-data WebSocket
#' streams. You register handlers with `$on(event, handler)` — exactly like
#' `ws.on("message", ...)` in JavaScript — and the library calls them as messages
#' arrive on R's event loop (the `later` package, which, like Node, is built on
#' libuv). Subclasses such as [BinanceMarketStream] add typed stream methods.
#'
#' ### Transport
#' This class is a thin Binance specialisation of [connectcore::StreamClient], the
#' shared WebSocket transport base. Auto-reconnect (full-jitter backoff), the
#' keepalive tick, the silence watchdog, proactive reconnect, and the event loop
#' all live in `connectcore`; `BinanceWsBase` only supplies the two stream-specific
#' seams — how a raw frame becomes events (`.dispatch()`, which filters Binance's
#' control acks and routes per-stream) and what to re-send after a (re)connect
#' (`.resubscribe()`) — plus Binance's `SUBSCRIBE` / `UNSUBSCRIBE` control protocol.
#'
#' ### Why no `async` flag (unlike the REST classes)
#' A REST call has a single result, so it can return a value (sync) or a promise
#' (async). A socket is an endless push stream with no single result, so the only
#' sensible shape is a callback. There is therefore nothing to dualise: streams
#' are always event-driven. The one thing R needs that Node gives for free is a
#' way to keep the process alive and pump the loop — that is `$run()`.
#'
#' ### Events
#' - `"open"` — handler called (with the open event) once the socket connects.
#' - `"message"` — handler called with the **raw JSON string** of every message.
#'   Parse it with [jsonlite::fromJSON()] for structure, or write it straight to
#'   disk for faithful archival.
#' - `"close"` — handler called (with the close event) when the socket closes.
#' - `"error"` — handler called (with the error event) on a socket error.
#'
#' ### Connection management (handled for you)
#' - **Auto-reconnect** with full-jitter exponential backoff on an unexpected
#'   close (so a reconnect storm can never trip Binance's connection rate limit).
#' - **Proactive reconnect at 23h**, before Binance's 24-hour forced disconnect.
#' - **Re-subscribe** every tracked stream after any reconnect.
#' - **Ping/pong** keepalive is answered automatically by the `websocket` package.
#'
#' ### Dependencies
#' Built on [connectcore::StreamClient], itself built on the `websocket` (the
#' client) and `later` (R's libuv event loop) packages.
#'
#' @examples
#' \dontrun{
#' # Subclasses are used in practice; the base shows the event API:
#' ws <- BinanceMarketStream$new()
#' ws$on("message", function(msg) cat(msg, "\n"))
#' ws$depth("BTCUSDT", speed = "100ms")
#' ws$run() # keeps the process alive and pumps the event loop
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceWsBase <- R6::R6Class(
  "BinanceWsBase",
  inherit = connectcore::StreamClient,
  public = list(
    #' @description
    #' Initialise a BinanceWsBase Object
    #'
    #' @param base_url (scalar<character>) the WebSocket base URL. Defaults to the
    #'   spot combined-stream endpoint, so every message arrives tagged as
    #'   `{"stream":...,"data":...}` and can be routed per stream. Pass a different
    #'   URL (e.g. the USD-M futures endpoint) to point the client elsewhere.
    #' @param auto_reconnect (scalar<logical>) reconnect automatically (with
    #'   backoff) when the socket drops. Default `TRUE`.
    #' @param max_reconnects (scalar<count in [1, Inf[>) give up after this many
    #'   consecutive failed reconnects (the process then exits its `$run()` loop, so
    #'   an external supervisor can restart it). Default `10`.
    #' @param proactive_reconnect (scalar<logical>) reconnect proactively after 23
    #'   hours to beat Binance's 24-hour forced disconnect. Default `TRUE`.
    #' @return (class<BinanceWsBase>) invisibly, self.
    initialize = function(
      base_url = "wss://stream.binance.com:9443/stream",
      auto_reconnect = TRUE,
      max_reconnects = 10L,
      proactive_reconnect = TRUE
    ) {
      assert_args_BinanceWsBase__initialize(base_url, auto_reconnect, max_reconnects, proactive_reconnect)
      assert::assert_nonempty_strings(base_url)
      super$initialize(
        url = base_url,
        auto_reconnect = auto_reconnect,
        # connectcore's StreamClient types max_reconnects as a double (it accepts
        # Inf); Binance's own contract counts it, so coerce to numeric here.
        max_reconnects = as.numeric(max_reconnects),
        # Binance forces a disconnect at 24h; refresh proactively at 23h.
        proactive_reconnect = if (isTRUE(proactive_reconnect)) 23 * 3600 else NULL
      )
      return(invisible(assert_return_BinanceWsBase__initialize(self)))
    },

    #' @description
    #' Register an Event Handler (Node-style `ws.on`)
    #'
    #' @param event (scalar<character in c("open", "message", "close", "error")>)
    #'   the event to handle.
    #' @param handler (function) called when the event fires. For `"message"` it
    #'   receives the raw JSON string; for the others it receives the socket event.
    #' @return (class<BinanceWsBase>) invisibly, self (chainable).
    on = function(event, handler) {
      assert_args_BinanceWsBase__on(event, handler)
      super$on(event, handler)
      return(invisible(assert_return_BinanceWsBase__on(self)))
    },

    #' @description
    #' Subscribe to Streams
    #'
    #' Tracks the streams (so they are restored after a reconnect) and sends a
    #' `SUBSCRIBE` frame if connected; otherwise they are sent on the next open.
    #' @param streams (character) stream names (e.g. `"btcusdt@depth"`).
    #' @return (class<BinanceWsBase>) invisibly, self.
    subscribe = function(streams) {
      assert_args_BinanceWsBase__subscribe(streams)
      streams <- tolower(streams)
      private$.streams <- union(private$.streams, streams)
      if (self$is_open()) {
        private$.send_control("SUBSCRIBE", streams)
      }
      return(invisible(assert_return_BinanceWsBase__subscribe(self)))
    },

    #' @description
    #' Unsubscribe from Streams
    #' @param streams (character) stream names to drop.
    #' @return (class<BinanceWsBase>) invisibly, self.
    unsubscribe = function(streams) {
      assert_args_BinanceWsBase__unsubscribe(streams)
      streams <- tolower(streams)
      private$.streams <- setdiff(private$.streams, streams)
      private$.stream_handlers[streams] <- NULL
      if (self$is_open()) {
        private$.send_control("UNSUBSCRIBE", streams)
      }
      return(invisible(assert_return_BinanceWsBase__unsubscribe(self)))
    },

    #' @description
    #' Currently Tracked Subscriptions
    #' @return (character) subscribed stream names (possibly length 0).
    subscriptions = function() {
      return(assert_return_BinanceWsBase__subscriptions(private$.streams))
    }
  ),
  private = list(
    .streams = character(0),
    .stream_handlers = list(),
    .next_id = 0L,

    # ---- Dispatch ----

    # Every "message" handler gets the raw string (Node parity). Per-stream
    # handlers (registered by subclasses) are routed via the combined-stream
    # `stream` key, parsed only when any are present.
    .dispatch = function(raw) {
      # Control responses are not stream data: {"result":...} acks a SUBSCRIBE /
      # UNSUBSCRIBE, {"error":...} reports one that failed. Never deliver either as
      # a "message" (it would corrupt a raw archive); surface a failure to "error".
      if (startsWith(raw, "{\"result\"")) {
        return(invisible(NULL))
      }
      if (startsWith(raw, "{\"error\"")) {
        private$.emit("error", jsonlite::fromJSON(raw, simplifyVector = FALSE))
        return(invisible(NULL))
      }
      private$.emit("message", raw)
      if (length(private$.stream_handlers) > 0L) {
        parsed <- tryCatch(jsonlite::fromJSON(raw, simplifyVector = FALSE), error = function(e) NULL)
        stream <- parsed$stream
        if (!is.null(stream) && !is.null(private$.stream_handlers[[stream]])) {
          for (h in private$.stream_handlers[[stream]]) {
            private$.safe_call(h, raw)
          }
        }
      }
      return(invisible(NULL))
    },

    # Register a per-stream handler (used by typed subclass methods).
    .add_stream_handler = function(stream, handler) {
      if (is.null(handler)) {
        return(invisible(NULL))
      }
      stream <- tolower(stream)
      private$.stream_handlers[[stream]] <- c(private$.stream_handlers[[stream]], handler)
      return(invisible(NULL))
    },

    # ---- Subscribe ----

    .send_control = function(method, streams) {
      if (length(streams) == 0L) {
        return(invisible(NULL))
      }
      private$.next_id <- private$.next_id + 1L
      self$send(ws_control_message(method, streams, private$.next_id))
      return(invisible(NULL))
    },

    # Replay tracked subscriptions after every (re)connect (the StreamClient hook).
    .resubscribe = function() {
      if (length(private$.streams) > 0L) {
        private$.send_control("SUBSCRIBE", private$.streams)
      }
      return(invisible(NULL))
    }
  )
)
