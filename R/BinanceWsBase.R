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
#' Requires the `websocket` and `later` packages (both `Suggests`). They are
#' checked at construction.
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
  public = list(
    #' @description
    #' Initialise a BinanceWsBase Object
    #'
    #' @param base_url Character; the WebSocket base URL. Defaults to the spot
    #'   combined-stream endpoint, so every message arrives tagged as
    #'   `{"stream":...,"data":...}` and can be routed per stream.
    #' @param auto_reconnect Logical; reconnect automatically (with backoff) when
    #'   the socket drops. Default `TRUE`.
    #' @param max_reconnects Integer; give up after this many consecutive failed
    #'   reconnects (the process then exits its `$run()` loop, so an external
    #'   supervisor can restart it). Default `10`.
    #' @param proactive_reconnect Logical; reconnect proactively after 23 hours to
    #'   beat Binance's 24-hour forced disconnect. Default `TRUE`.
    #' @return Invisible self.
    initialize = function(
      base_url = "wss://stream.binance.com:9443/stream",
      auto_reconnect = TRUE,
      max_reconnects = 10L,
      proactive_reconnect = TRUE
    ) {
      for (pkg in c("websocket", "later")) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
          rlang::abort(sprintf(
            "Package '%s' is required for WebSocket streams. Install with: install.packages('%s')",
            pkg, pkg
          ))
        }
      }
      private$.base_url <- base_url
      private$.auto_reconnect <- isTRUE(auto_reconnect)
      private$.max_reconnects <- as.integer(max_reconnects)
      private$.proactive_reconnect <- isTRUE(proactive_reconnect)
      private$.handlers <- list(open = list(), message = list(), close = list(), error = list())
      return(invisible(self))
    },

    #' @description
    #' Register an Event Handler (Node-style `ws.on`)
    #'
    #' @param event Character; one of `"open"`, `"message"`, `"close"`, `"error"`.
    #' @param handler Function; called when the event fires. For `"message"` it
    #'   receives the raw JSON string; for the others it receives the socket event.
    #' @return Invisible self (chainable).
    on = function(event, handler) {
      event <- match.arg(event, c("open", "message", "close", "error"))
      if (!is.function(handler)) {
        rlang::abort("`handler` must be a function.")
      }
      private$.handlers[[event]] <- c(private$.handlers[[event]], handler)
      return(invisible(self))
    },

    #' @description
    #' Open the Connection
    #'
    #' Wires the socket callbacks and connects. Idempotent — a no-op if already
    #' open. You usually do not call this directly: `$run()` connects for you.
    #' @return Invisible self.
    connect = function() {
      if (private$.is_connecting_or_open()) {
        return(invisible(self))
      }
      private$.running <- TRUE
      private$.open_socket()
      return(invisible(self))
    },

    #' @description
    #' Subscribe to Streams
    #'
    #' Tracks the streams (so they are restored after a reconnect) and sends a
    #' `SUBSCRIBE` frame if connected; otherwise they are sent on the next open.
    #' @param streams Character vector; stream names (e.g. `"btcusdt@depth"`).
    #' @return Invisible self.
    subscribe = function(streams) {
      streams <- tolower(streams)
      private$.streams <- union(private$.streams, streams)
      if (private$.is_open()) {
        private$.send_control("SUBSCRIBE", streams)
      }
      return(invisible(self))
    },

    #' @description
    #' Unsubscribe from Streams
    #' @param streams Character vector; stream names to drop.
    #' @return Invisible self.
    unsubscribe = function(streams) {
      streams <- tolower(streams)
      private$.streams <- setdiff(private$.streams, streams)
      private$.stream_handlers[streams] <- NULL
      if (private$.is_open()) {
        private$.send_control("UNSUBSCRIBE", streams)
      }
      return(invisible(self))
    },

    #' @description
    #' Send a Raw Control Message
    #' @param message Character; a JSON string to send on the socket.
    #' @return Invisible self.
    send = function(message) {
      if (!private$.is_open()) {
        rlang::abort("Cannot send: socket is not open.")
      }
      private$.ws$send(message)
      return(invisible(self))
    },

    #' @description
    #' Run the Event Loop (keep the process alive)
    #'
    #' Connects if needed, then blocks and pumps R's `later` event loop so handlers
    #' keep firing — the equivalent of Node keeping a process alive while a socket
    #' is open. It runs until the client is closed: either `$close()` is called
    #' (e.g. from a handler) or reconnects are exhausted. Stop a running recorder
    #' with an interrupt.
    #'
    #' @param timeout Numeric; seconds each `later::run_now()` tick waits for work
    #'   before looping (keeps CPU near zero between messages). Default `0.1`.
    #' @return Invisible self.
    run = function(timeout = 0.1) {
      if (!private$.is_connecting_or_open()) {
        self$connect()
      }
      while (isTRUE(private$.running)) {
        later::run_now(timeout)
      }
      return(invisible(self))
    },

    #' @description
    #' Close the Connection
    #'
    #' Stops auto-reconnect, cancels timers, and closes the socket. After this,
    #' `$run()` returns.
    #' @return Invisible self.
    close = function() {
      private$.running <- FALSE
      private$.cancel_timers()
      if (!is.null(private$.ws)) {
        try(private$.ws$close(), silent = TRUE)
      }
      return(invisible(self))
    },

    #' @description
    #' Currently Tracked Subscriptions
    #' @return Character vector of subscribed stream names.
    subscriptions = function() {
      return(private$.streams)
    },

    #' @description
    #' Is the Socket Open?
    #' @return Logical scalar.
    is_open = function() {
      return(private$.is_open())
    }
  ),
  private = list(
    .base_url = NULL,
    .auto_reconnect = TRUE,
    .max_reconnects = 10L,
    .proactive_reconnect = TRUE,
    .ws = NULL,
    .streams = character(0),
    .handlers = NULL,
    .stream_handlers = list(),
    .running = FALSE,
    .reconnect_attempts = 0L,
    .next_id = 0L,
    .reconnect_timer = NULL,
    .proactive_timer = NULL,

    # ---- Connection ----

    .open_socket = function() {
      ws <- websocket::WebSocket$new(private$.base_url, autoConnect = FALSE)
      ws$onOpen(function(event) {
        private$.reconnect_attempts <- 0L
        private$.resubscribe()
        private$.schedule_proactive_reconnect()
        private$.emit("open", event)
        return(invisible(NULL))
      })
      ws$onMessage(function(event) {
        private$.dispatch(event$data)
        return(invisible(NULL))
      })
      ws$onClose(function(event) {
        private$.cancel_timers()
        private$.emit("close", event)
        if (private$.auto_reconnect && isTRUE(private$.running)) {
          private$.schedule_reconnect()
        }
        return(invisible(NULL))
      })
      ws$onError(function(event) {
        private$.emit("error", event)
        return(invisible(NULL))
      })
      private$.ws <- ws
      ws$connect()
      return(invisible(NULL))
    },

    .is_open = function() {
      return(!is.null(private$.ws) && identical(private$.ws$readyState(), 1L))
    },

    .is_connecting_or_open = function() {
      return(!is.null(private$.ws) && private$.ws$readyState() %in% c(0L, 1L))
    },

    # ---- Dispatch ----

    # Every "message" handler gets the raw string (Node parity). Per-stream
    # handlers (registered by subclasses) are routed via the combined-stream
    # `stream` key, parsed only when any are present.
    .dispatch = function(raw) {
      # SUBSCRIBE/UNSUBSCRIBE acknowledgements ({"result":...,"id":...}) are
      # control responses, not stream data — never deliver them to handlers.
      if (startsWith(raw, "{\"result\"")) {
        return(invisible(NULL))
      }
      for (h in private$.handlers$message) {
        private$.safe_call(h, raw)
      }
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

    .emit = function(event, payload) {
      for (h in private$.handlers[[event]]) {
        private$.safe_call(h, payload)
      }
      return(invisible(NULL))
    },

    # A throwing handler warns but never kills the loop.
    .safe_call = function(handler, payload) {
      tryCatch(
        handler(payload),
        error = function(e) rlang::warn(sprintf("WebSocket handler error: %s", conditionMessage(e)))
      )
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
      private$.ws$send(ws_control_message(method, streams, private$.next_id))
      return(invisible(NULL))
    },

    .resubscribe = function() {
      if (length(private$.streams) > 0L) {
        private$.send_control("SUBSCRIBE", private$.streams)
      }
      return(invisible(NULL))
    },

    # ---- Reconnection ----

    .schedule_reconnect = function() {
      private$.reconnect_attempts <- private$.reconnect_attempts + 1L
      if (private$.reconnect_attempts > private$.max_reconnects) {
        rlang::warn(sprintf(
          "WebSocket: giving up after %d failed reconnects.", private$.max_reconnects
        ))
        private$.running <- FALSE
        return(invisible(NULL))
      }
      delay <- ws_backoff_delay(private$.reconnect_attempts)
      private$.reconnect_timer <- later::later(function() {
        if (isTRUE(private$.running)) {
          private$.open_socket()
        }
        return(invisible(NULL))
      }, delay)
      return(invisible(NULL))
    },

    .schedule_proactive_reconnect = function() {
      if (!private$.proactive_reconnect) {
        return(invisible(NULL))
      }
      private$.proactive_timer <- later::later(function() {
        if (isTRUE(private$.running) && !is.null(private$.ws)) {
          try(private$.ws$close(), silent = TRUE) # onClose triggers a fresh reconnect
        }
        return(invisible(NULL))
      }, 23 * 3600)
      return(invisible(NULL))
    },

    .cancel_timers = function() {
      # later::later() returns a function that cancels the callback when called.
      for (t in list(private$.reconnect_timer, private$.proactive_timer)) {
        if (is.function(t)) {
          try(t(), silent = TRUE)
        }
      }
      private$.reconnect_timer <- NULL
      private$.proactive_timer <- NULL
      return(invisible(NULL))
    }
  )
)
