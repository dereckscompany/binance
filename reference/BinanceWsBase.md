# BinanceWsBase: Abstract Base Class for Binance WebSocket Streams

BinanceWsBase: Abstract Base Class for Binance WebSocket Streams

BinanceWsBase: Abstract Base Class for Binance WebSocket Streams

## Details

Node.js-style event-driven base for Binance's public market-data
WebSocket streams. You register handlers with `$on(event, handler)` —
exactly like `ws.on("message", ...)` in JavaScript — and the library
calls them as messages arrive on R's event loop (the `later` package,
which, like Node, is built on libuv). Subclasses such as
[BinanceMarketStream](https://dereckscompany.github.io/binance/reference/BinanceMarketStream.md)
add typed stream methods.

### Transport

This class is a thin Binance specialisation of
[connectcore::StreamClient](https://rdrr.io/pkg/connectcore/man/StreamClient.html),
the shared WebSocket transport base. Auto-reconnect (full-jitter
backoff), the keepalive tick, the silence watchdog, proactive reconnect,
and the event loop all live in `connectcore`; `BinanceWsBase` only
supplies the two stream-specific seams — how a raw frame becomes events
(`.dispatch()`, which filters Binance's control acks and routes
per-stream) and what to re-send after a (re)connect (`.resubscribe()`) —
plus Binance's `SUBSCRIBE` / `UNSUBSCRIBE` control protocol.

### Why no `async` flag (unlike the REST classes)

A REST call has a single result, so it can return a value (sync) or a
promise (async). A socket is an endless push stream with no single
result, so the only sensible shape is a callback. There is therefore
nothing to dualise: streams are always event-driven. The one thing R
needs that Node gives for free is a way to keep the process alive and
pump the loop — that is `$run()`.

### Events

- `"open"` — handler called (with the open event) once the socket
  connects.

- `"message"` — handler called with the **raw JSON string** of every
  message. Parse it with
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
  for structure, or write it straight to disk for faithful archival.

- `"close"` — handler called (with the close event) when the socket
  closes.

- `"error"` — handler called (with the error event) on a socket error.

### Connection management (handled for you)

- **Auto-reconnect** with full-jitter exponential backoff on an
  unexpected close (so a reconnect storm can never trip Binance's
  connection rate limit).

- **Proactive reconnect at 23h**, before Binance's 24-hour forced
  disconnect.

- **Re-subscribe** every tracked stream after any reconnect.

- **Ping/pong** keepalive is answered automatically by the `websocket`
  package.

### Dependencies

Built on
[connectcore::StreamClient](https://rdrr.io/pkg/connectcore/man/StreamClient.html),
itself built on the `websocket` (the client) and `later` (R's libuv
event loop) packages.

## Super class

[`connectcore::StreamClient`](https://rdrr.io/pkg/connectcore/man/StreamClient.html)
-\> `BinanceWsBase`

## Methods

### Public methods

- [`BinanceWsBase$new()`](#method-BinanceWsBase-new)

- [`BinanceWsBase$on()`](#method-BinanceWsBase-on)

- [`BinanceWsBase$subscribe()`](#method-BinanceWsBase-subscribe)

- [`BinanceWsBase$unsubscribe()`](#method-BinanceWsBase-unsubscribe)

- [`BinanceWsBase$subscriptions()`](#method-BinanceWsBase-subscriptions)

- [`BinanceWsBase$clone()`](#method-BinanceWsBase-clone)

Inherited methods

- [`connectcore::StreamClient$close()`](https://rdrr.io/pkg/connectcore/man/StreamClient.html#method-close)
- [`connectcore::StreamClient$connect()`](https://rdrr.io/pkg/connectcore/man/StreamClient.html#method-connect)
- [`connectcore::StreamClient$is_open()`](https://rdrr.io/pkg/connectcore/man/StreamClient.html#method-is_open)
- [`connectcore::StreamClient$run()`](https://rdrr.io/pkg/connectcore/man/StreamClient.html#method-run)
- [`connectcore::StreamClient$send()`](https://rdrr.io/pkg/connectcore/man/StreamClient.html#method-send)

------------------------------------------------------------------------

### Method `new()`

Initialise a BinanceWsBase Object

#### Usage

    BinanceWsBase$new(
      base_url = "wss://stream.binance.com:9443/stream",
      auto_reconnect = TRUE,
      max_reconnects = 10L,
      proactive_reconnect = TRUE
    )

#### Arguments

- `base_url`:

  (scalar\<character\>) the WebSocket base URL. Defaults to the spot
  combined-stream endpoint, so every message arrives tagged as
  `{"stream":...,"data":...}` and can be routed per stream. Pass a
  different URL (e.g. the USD-M futures endpoint) to point the client
  elsewhere.

- `auto_reconnect`:

  (scalar\<logical\>) reconnect automatically (with backoff) when the
  socket drops. Default `TRUE`.

- `max_reconnects`:

  (scalar\<count in \[1, Inf\[\>) give up after this many consecutive
  failed reconnects (the process then exits its `$run()` loop, so an
  external supervisor can restart it). Default `10`.

- `proactive_reconnect`:

  (scalar\<logical\>) reconnect proactively after 23 hours to beat
  Binance's 24-hour forced disconnect. Default `TRUE`.

#### Returns

(class\<BinanceWsBase\>) invisibly, self.

------------------------------------------------------------------------

### Method `on()`

Register an Event Handler (Node-style `ws.on`)

#### Usage

    BinanceWsBase$on(event, handler)

#### Arguments

- `event`:

  (scalar\<character in c("open", "message", "close", "error")\>) the
  event to handle.

- `handler`:

  (function) called when the event fires. For `"message"` it receives
  the raw JSON string; for the others it receives the socket event.

#### Returns

(class\<BinanceWsBase\>) invisibly, self (chainable).

------------------------------------------------------------------------

### Method `subscribe()`

Subscribe to Streams

Tracks the streams (so they are restored after a reconnect) and sends a
`SUBSCRIBE` frame if connected; otherwise they are sent on the next
open.

#### Usage

    BinanceWsBase$subscribe(streams)

#### Arguments

- `streams`:

  (character) stream names (e.g. `"btcusdt@depth"`).

#### Returns

(class\<BinanceWsBase\>) invisibly, self.

------------------------------------------------------------------------

### Method `unsubscribe()`

Unsubscribe from Streams

#### Usage

    BinanceWsBase$unsubscribe(streams)

#### Arguments

- `streams`:

  (character) stream names to drop.

#### Returns

(class\<BinanceWsBase\>) invisibly, self.

------------------------------------------------------------------------

### Method `subscriptions()`

Currently Tracked Subscriptions

#### Usage

    BinanceWsBase$subscriptions()

#### Returns

(character) subscribed stream names (possibly length 0).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceWsBase$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Subclasses are used in practice; the base shows the event API:
ws <- BinanceMarketStream$new()
ws$on("message", function(msg) cat(msg, "\n"))
ws$depth("BTCUSDT", speed = "100ms")
ws$run() # keeps the process alive and pumps the event loop
} # }
```
