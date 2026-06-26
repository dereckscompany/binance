# File: R/BinanceMarketStream.R
# R6 class for Binance Spot public market-data WebSocket streams.

#' BinanceMarketStream: Spot Market-Data WebSocket Streams
#'
#' Typed, event-driven client for Binance's **public** spot market-data streams.
#' Inherits the Node.js-style event API and connection management from
#' [BinanceWsBase] (`$on()`, `$subscribe()`, `$run()`, auto-reconnect). No API key
#' is required — these are public streams.
#'
#' Many symbols ride a single connection (Binance allows up to 1024 streams per
#' connection), so subscribing to 100 order books is one socket, not 100.
#'
#' ### Streams Covered
#' | Method | Stream | Auth |
#' |--------|--------|------|
#' | depth | `<symbol>@depth` / `<symbol>@depth@100ms` | No |
#'
#' Handlers receive the **raw JSON message string** (parse with
#' [jsonlite::fromJSON()], or write it straight to disk for archival). The
#' `@depth` stream is the full diff stream — every order-book change — from which
#' the complete book can be reconstructed; reconstruction is a separate concern
#' (a future helper), this class faithfully captures the stream.
#'
#' @examples
#' \dontrun{
#' # Record BTC + ETH order-book diffs at 100ms to disk:
#' stream <- BinanceMarketStream$new()
#' stream$on("message", function(msg) cat(msg, file = "orderbook.ndjson", append = TRUE))
#' stream$on("message", function(msg) cat(msg, "\n"))
#' stream$depth("BTCUSDT", speed = "100ms")
#' stream$depth("ETHUSDT", speed = "100ms")
#' stream$run() # blocks, pumping the event loop; interrupt to stop
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceMarketStream <- R6::R6Class(
  "BinanceMarketStream",
  inherit = BinanceWsBase,
  public = list(
    #' @description
    #' Initialise a BinanceMarketStream Object
    #'
    #' @param base_url Character; WebSocket base URL. Defaults to the spot
    #'   combined-stream endpoint.
    #' @param auto_reconnect Logical; auto-reconnect with backoff. Default `TRUE`.
    #' @param max_reconnects Integer; give up after this many failed reconnects.
    #'   Default `10`.
    #' @param proactive_reconnect Logical; reconnect at 23h to beat the 24h cutoff.
    #'   Default `TRUE`.
    #' @return Invisible self.
    initialize = function(
      base_url = "wss://stream.binance.com:9443/stream",
      auto_reconnect = TRUE,
      max_reconnects = 10L,
      proactive_reconnect = TRUE
    ) {
      super$initialize(
        base_url = base_url,
        auto_reconnect = auto_reconnect,
        max_reconnects = max_reconnects,
        proactive_reconnect = proactive_reconnect
      )
      return(invisible(self))
    },

    #' @description
    #' Subscribe to the Order-Book Diff-Depth Stream
    #'
    #' Subscribes to `<symbol>@depth` — the full stream of order-book changes
    #' (each message lists the bid/ask levels that changed; quantity `0` means the
    #' level was removed). This is the data needed to maintain a complete local
    #' order book, and the only order-book data Binance does **not** archive, so
    #' it must be streamed live.
    #'
    #' ### Official Documentation
    #' [Depth stream](https://developers.binance.com/docs/binance-spot-api-docs/web-socket-streams#diff-depth-stream)
    #'
    #' ### JSON Message
    #' ```json
    #' {
    #'   "stream": "btcusdt@depth",
    #'   "data": {
    #'     "e": "depthUpdate", "E": 1571889248277, "s": "BTCUSDT",
    #'     "U": 390497796, "u": 390497878,
    #'     "b": [["7403.89", "0.002"], ["7403.90", "3.906"]],
    #'     "a": [["7405.96", "3.340"], ["7406.63", "4.525"]]
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g. `"BTCUSDT"`).
    #' @param speed Character; update cadence, `"1000ms"` (Binance default) or
    #'   `"100ms"` (full fidelity). Default `"1000ms"`.
    #' @param handler Function or NULL; if supplied, called with the raw JSON
    #'   string for **this** stream only. If NULL, use a global `$on("message")`
    #'   handler instead. Default NULL.
    #' @return Invisible self (chainable).
    #'
    #' @examples
    #' \dontrun{
    #' stream <- BinanceMarketStream$new()
    #' stream$depth("BTCUSDT", speed = "100ms", handler = function(msg) print(msg))
    #' stream$run()
    #' }
    depth = function(symbol, speed = c("1000ms", "100ms"), handler = NULL) {
      speed <- match.arg(speed)
      stream <- ws_depth_stream(symbol, speed)
      private$.add_stream_handler(stream, handler)
      self$subscribe(stream)
      return(invisible(self))
    }
  )
)
