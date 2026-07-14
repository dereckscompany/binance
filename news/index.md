# Changelog

## binance 0.9.0

### Column-type NA audit (org discussion [\#2](https://github.com/dereckscompany/binance/issues/2)): the exchange-info filter cluster tolerates absent filters

The per-connector type-fidelity audit reaches binance. The venue’s
always-present-sentinel API design means most strict columns were
already correct; the one defect cluster found is in both
get_exchange_info parsers, whose filter extraction demonstrably emits NA
when a symbol lacks a PRICE_FILTER or ships an empty filters array,
while price_min/price_max/price_tick_size/filters_raw were typed strict
— filters_raw’s own prose even promised an NA its type forbade. Eight
columns across the two methods move to `| NA`, aligning them with the
sibling filter columns that were already permissive. Latent rather than
live-firing (all 3,636 current spot symbols carry a PRICE_FILTER today),
so this is a contract-and-docs correction with two new empty-filter
tests.

## binance 0.8.0

### Typed input-validation conditions (the non-transport half of the taxonomy)

- The connector’s 25 non-transport
  [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html) sites
  — a method’s argument or parameter is malformed or violates a rule
  *before* any request is made (a missing required order id, an unset
  LIMIT price, a bad ticker, a `recv_window` over the cap) — now signal
  a **classed condition** through a new
  `abort_binance_validation_error()` raiser, so a caller branches on
  error *type* instead of grepping the message text. This completes the
  taxonomy: the request funnel already raised typed transport conditions
  (0.7.0); this covers the input-validation surface.
- The class vector is `c("binance_validation_error", "binance_error")`
  (on top of rlang’s error classes). `binance_error` is the connector’s
  DOMAIN root, parallel to the transport `connectcore_error` root: a
  validation failure is not a transport failure, so the two roots never
  meet — exactly the `core_error` / `connectcore_error` split the fleet
  already uses. Catch `binance_validation_error` for input bugs
  specifically, or `binance_error` for any non-transport binance
  failure.
- The message strings are **byte-identical** to the bare
  [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html) calls
  they replaced (a reverse-substitution proves every one of the 25
  reproduces master exactly; golden tests pin a representative site), so
  existing tests and downstream message greps keep matching. The classes
  are purely additive;
  [`conditionMessage()`](https://rdrr.io/r/base/conditions.html) and
  `inherits(e, "error")` are unchanged. No behaviour changes.
- Follows the org convention (dereckscompany/tradebot-core#30;
  discussion “throw typed errors, not bare strings”). The transport/API
  funnel (`abort_binance_error`, rooted at `connectcore_error`) is
  untouched.

## binance 0.7.0

### Typed API-error conditions

- Both failure surfaces of the request funnel
  (`parse_binance_response()`) now signal a **classed condition**
  instead of a bare
  [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html), so a
  caller branches on error *type* and reads structured *fields* rather
  than grepping the message text. This covers the venue-code surface (a
  negative `code` in the JSON body, which can arrive even on an
  HTTP 200) and the plain non-2xx HTTP surface. The class vector is
  ordered specific -\> general: `binance_api_error_<status>` (keyed on
  the HTTP status), `binance_api_error` (any Binance failure), then the
  inherited connectcore family `connectcore_api_error_<status>` /
  `connectcore_api_error` / `connectcore_error` (any HTTP or transport
  failure fleet-wide). The condition carries `status` (integer), `code`
  (the Binance venue error code, `NULL` on a plain HTTP failure), `url`
  (query-string credentials redacted), and `body_snippet` (the response
  body) as fields — read `e$code`, not a regex.
- The message strings are **byte-identical** to the previous
  `"Binance API error <code>: <msg>"` (venue-code path) and
  `"Binance HTTP error <status>\n<body>"` (HTTP path), so existing tests
  and downstream message greps keep matching. The classes and fields are
  purely additive.
- This follows the connector-subclass recipe documented in connectcore
  0.4.0 (`?connectcore_conditions`); the floor is bumped to
  `connectcore (>= 0.4.0)`.

## binance 0.6.1

### Bug fixes

- **[`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)’s
  `timeout` now accepts a whole number, not only a decimal.** It was
  contracted as `scalar<numeric in ]0, Inf[>` — a strict double — so a
  caller passing an integer (e.g. a `timeout` read from a YAML config,
  where `30` parses as an R integer) hit
  `` `timeout` must be a single double value ``. The contract is widened
  to `scalar<numeric in ]0, Inf[> | scalar<integer in [1, Inf[>`, so
  both a whole-number and a decimal timeout are accepted while a
  non-positive value is still rejected.

## binance 0.6.0

This release brings binance into line with the fleet-wide connector
conventions. Every method argument is now plain snake_case (the words
you type in R), while the Binance API still receives its own camelCase
field names on the wire — the translation now happens inside each method
rather than leaking the exchange’s spelling into your R code. It is a
clean break with no deprecation shims, so calls that passed camelCase
argument names by keyword must be updated (for example
`cancel_order("BTCUSDT", orderId = 123)` becomes
`cancel_order("BTCUSDT", order_id = 123)`).

### Breaking changes

- **All method arguments are now snake_case.** The ~275 camelCase
  arguments across every R6 class (`recvWindow`, `orderId`, `startTime`,
  `origClientOrderId`, `quoteOrderQty`, `timeInForce`,
  `newOrderRespType`, `selfTradePreventionMode`, and the rest) are
  renamed to snake_case; the Binance vocabulary survives untouched as
  the wire payload keys (`recvWindow = recv_window`) and accepted
  values. The blessed `.lintr` drops its camelCase allowance and now
  enforces pure snake_case. No deprecation shims — update
  keyword-argument call sites.
- **The OHLCV bar-reference column is renamed `open_time` to
  `datetime`.** Per the fleet datetime convention (`datetime` for a
  bar/candle reference time, `timestamp` for an event time),
  `get_klines()` and the futures kline methods,
  [`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md),
  and the bundled `binance_btc_usdt_4h_ohlcv` sample dataset now name
  the candle open time `datetime`. The candle `close_time` keeps its
  name as a documented venue extra. The 24-hour ticker’s `open_time` /
  `close_time` window bounds are unchanged (they are not a bar-reference
  time).

### Internal

- **The generic JSON-to-data.table toolkit is imported from connectcore,
  not inlined.** `to_snake_case()`, `as_dt_row()`, `as_dt_list()`,
  `coerce_cols()`, `collapse_string_array_fields()`, and
  `ms_to_datetime()` were local copies in `R/helpers_parse.R`; they are
  now imported from connectcore (floor raised to
  `connectcore (>= 0.3.0)`), which is where the fleet-canonical,
  NA-preserving `ms_to_datetime()` now lives. Binance-specific parsers
  (`parse_klines()`, `parse_orderbook()`, `parse_paginated()`,
  `utc_string_to_datetime()`) and every `empty_dt_*()` constructor stay
  local.
- **A `test-empty-constructors.R` guards the 57 `empty_dt_*()`
  constructors** — each returns a zero-row, fully-typed, non-column-less
  `data.table` with no list columns (bar the two documented
  isolated-margin nested shapes).
- **`renv.lock` and shared infrastructure refreshed.** The lockfile
  records connectcore 0.3.0 and the previously-missing dev dependencies
  (`covr`, `DT`, `rcmdcheck`, `devtools`, `lintr`) so the CI runners
  restore a complete environment; `.cruft.json` is re-pinned to the
  current templates-cookiecutter master.
- **Folds in the open add_order ACK-test repair** (previously PR
  [\#29](https://github.com/dereckscompany/binance/issues/29)): the
  shared order fixture is stripped to a resting `NEW` order before the
  fills-free ACK assertion.

## binance 0.5.4

### Bug fixes

- **[`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)
  now retries transient request failures, so a single timeout no longer
  truncates a symbol’s history.** Every page request ran with retry
  disabled and a 10s timeout, so one `curl` timeout to `api.binance.com`
  mid-backfill — near-certain on the 500+ sequential pages of a year of
  1m candles, and worse through a VPN — aborted the fetch and left a
  truncated CSV; because the crawler’s resume floor is the earliest year
  already written, the gap then became permanent. The function gains
  `timeout` (default `30`) and `max_tries` (default `5`) parameters,
  threaded through
  [`binance_build_request()`](https://dereckscompany.github.io/binance/reference/binance_build_request.md)
  into `connectcore`’s `req_retry()` exponential backoff (which also
  honours `Retry-After`); backfill is an idempotent GET, so retrying is
  always safe.
  [`binance_build_request()`](https://dereckscompany.github.io/binance/reference/binance_build_request.md)
  gains a matching `max_tries` passthrough defaulting to `1` (retry
  off), so retry stays opt-in per call and is never enabled for order
  placement, where a resend could double-submit.

## binance 0.5.3

### Internal

- **Table-returning methods with a fixed schema now document their
  columns as typed nested bullets.** The handful of methods still typed
  as a bare `(data.table)` despite returning a known, fixed column set
  are now refined per the cross-package roxyassert convention: each
  `@return` lists one nested bullet per column carrying that column’s
  element type, which generates an `assert_has_columns()` plus a
  per-column `assert_<type>()` in `R/contracts-generated.R`. Covered:
  `BinanceMarketData$get_all_24hr_stats()` (the full 24hr ticker schema,
  the same columns as `get_24hr_stats()`),
  `BinanceFuturesData$get_rate_limits()` (`rate_limit_type`, `interval`,
  `interval_num`, `limit`), the single-row `validated` confirmation
  returned by `add_order_test()` on both `BinanceFutures` and
  `BinanceTrading`, and the internal `parse_klines()` OHLCV helper. The
  genuinely payload-shaped tables (sub-account futures/margin account,
  locked-earn position, the schemaless exchange-wide filters) keep their
  bare `(data.table)` contract, as do the generic parsing helpers
  (`as_dt_row()`, `as_dt_list()`, `coerce_cols()`, `parse_paginated()`)
  whose columns follow the caller.
- **`get_all_24hr_stats()`’s empty path returns the typed zero-row
  schema.** With no symbols the parser previously returned a column-less
  `data.table`, which would abort the new column contract; it now
  returns the typed empty `empty_dt_ticker_24hr()` so the schema holds
  whether or not Binance returns any rows.

## binance 0.5.2

### Bug fixes

- **Two over-strict `get_exchange_info()` return contracts rejected real
  live responses.** The synthetic fixtures hid a divergence the real
  Binance API exposes: on the spot endpoint every symbol now returns an
  empty `permissions` array (the data has moved to `permission_sets`),
  and on the futures endpoint many non-coin / index-style contracts
  return no `underlyingSubType` — in both cases the parser correctly
  emits `NA`, but the `@type` contract still asserted no missing values
  and aborted. Loosened `permissions` (spot) and `underlying_sub_type`
  (futures) to `character | NA` in the `@return` grammar and regenerated
  `R/contracts-generated.R`; the parser already round-tripped the empty
  array to `NA` via `collapse_string_array_fields()`, so no parser
  change was needed. Surfaced by the public live-integration tests
  (`BINANCE_LIVE_TESTS=true`) run against the real API.
- **An empty kline range returned a column-less table and would abort
  `get_klines()`’s contract.** `binance_fetch_klines()` /
  `combine_klines()` returned a bare `data.table()` for a zero-width /
  inverted range or a window with no candles, but `get_klines()`’s
  `@return` requires the twelve OHLCV columns (`assert_has_columns`), so
  an empty range aborted instead of returning empty. Both now return the
  typed zero-row schema via the existing `empty_dt_ohlcv()` constructor;
  the zero-width-range regression test is upgraded to pin the result to
  that schema and assert it passes the generated `get_klines` contract.

### Internal

- **Public market-data fixtures validated and enriched against the real
  wire shapes.** A new read-only capture harness
  (`dev/capture-binance.R`, GET-only, public market-data endpoints, no
  credentials, raw bodies written only to the git-ignored
  `local/raw-data/binance/`) was used to diff every committed public
  fixture against a fresh live capture. The spot and futures
  `exchangeInfo` fixtures gained the real superset of per-symbol fields
  they previously omitted — spot: `baseCommissionPrecision`,
  `quoteCommissionPrecision`, `opoAllowed`, `amendAllowed`,
  `pegInstructionsAllowed`; futures: `liquidationFee`,
  `maintMarginPercent`, `requiredMarginPercent`, `marketTakeBound`,
  `maxMoveOrderLimit`, `permissionSets` — so the mock harness mirrors a
  current live response. The remaining market-data fixtures (ticker,
  book ticker, 24hr stats, average price, depth, trades, klines, mark
  price, funding rate, open interest) matched the live shapes verbatim.
  The private / account fixtures (account, orders, margin, futures
  account, sub-accounts) require API keys and remain fully synthetic —
  they are not validated by this pass.

## binance 0.5.1

### Internal

- **Every 64-bit identifier is now typed `numeric` and coerced in its
  parser.** jsonlite returns a double for any JSON integer at or above
  2^31, so an `order_id`, `order_list_id`, trade `id`, `fill_trade_id`,
  OCO child id, account `uid`, epoch-ms `good_till_date`, 24hr-stats
  `first_id`/`last_id`, margin-pair `id`, or earn
  `purchase_id`/`redeem_id` can exceed R’s 32-bit `integer` range — at
  which point an `integer` `@type` contract would reject the parser’s
  own output on a real response. Each such field is now typed `numeric`
  (in `types_binance.R`, the `@return` bullets, and the typed zero-row
  `empty_dt_*()` empties) and coerced with
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html) in its method
  parser, so the populated path emits a stable double in both sync and
  async modes. `modify_position_margin()`’s `amount` is likewise typed
  `numeric` (Binance returns it as a JSON decimal). Genuinely small
  bounded counters (`fill_index`, `count`, precisions, status enums)
  remain `integer`.
- **Required string identifiers are checked non-empty at the public
  boundary.** roxyassert has no non-empty string type, so a required
  identifier (`symbol`, `coin`, `asset`, `productId`, `projectId`,
  `positionId`, `pair`, `email`, sub-account string, `address`, client
  order ids, `base_url`) could be passed an empty string and still
  satisfy its `@type`. Each method now calls
  [`assert::assert_nonempty_strings()`](https://dereckscompany.github.io/assert/reference/assert_nonempty_strings.html)
  right after its generated `assert_args_*()` guard — bare for required
  identifiers, `null_ok = TRUE` for optional ones.
- **`.lintr` aligned with the connector gold standard** —
  `object_length_linter` and `commented_code_linter` are disabled (long
  API-field names and documentation-banner comments are intentional),
  keeping the `camelCase` object-name allowance for Binance’s verbatim
  API parameters.

## binance 0.5.0

### Internal

- **REST endpoint contracts via `roxyassert`.** Every `@param` and
  `@return` on the REST endpoint classes (`BinanceAccount`,
  `BinanceDeposit`, `BinanceEarn`, `BinanceFutures`,
  `BinanceFuturesData`, `BinanceMargin`, `BinanceMarginData`,
  `BinanceMarketData`, `BinanceOcoOrders`, `BinanceSubAccount`,
  `BinanceTrading`, `BinanceTransfer`, `BinanceWithdrawal`) and the
  package helpers (`backfill`, `helpers_parse`, `helpers_request`,
  `helpers_validate`, `utils`, `utils_time`) is now written in the
  `roxyassert` type grammar instead of prose, completing the migration
  begun for the WebSocket/base classes. The documented type both renders
  in the help page and generates a runtime `assert_args_*()` guard, so
  every method now validates its inputs against its documented contract
  at the top of the call.
  - This is **purely additive validation** — no public signature or
    behaviour changes for valid inputs; the full test suite passes
    untouched.
  - Endpoint methods that resolve sync-or-async are typed
    `(data.table | promise<data.table>)` (or `(Shape | promise<Shape>)`
    for the shared shapes), so the contract describes the data the
    caller receives whether the client is synchronous or returns a
    promise.
  - A handful of polymorphic / hand-guarded inputs
    (e.g. `ms_to_datetime()`’s coercion-dispatched argument,
    [`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)’s
    emptiness-checked `symbols`, the thin transport delegators) are
    typed for documentation but exempted from the generated check with
    `@noassert`, leaving their existing bespoke guards in place.
- **Return contracts now enforced at every call site.** Each
  table-returning REST method wires its generated `assert_return_*()`
  through \[connectcore::then_or_now()\], so the documented
  row-and-column contract runs in both sync and async modes (previously
  the helpers were generated but never invoked). Eight reusable `@type`
  shapes (`Ohlcv`, `OrderBook`, `Trade`, `BookTicker`, `SpotOrderAck`,
  `SpotOrderQuery`, `FuturesOrder`, `AccountTrade`) are declared once
  and shared across the methods that return them. Each shape expands
  inline into the referencing method’s `assert_return_*`; binance is a
  leaf connector, so no standalone `assert_type_<Shape>()` validators
  are generated or exported (the `@type` block carries no `@genassert` /
  `@exportassert`).
  - Each list-returning method’s empty path now returns a fully-typed
    zero-row `data.table` (the `empty_dt_*()` helpers in
    `helpers_parse.R`), so a method’s column contract holds even when
    the API returns nothing.
  - JSON-number columns whose R type depends on the value’s magnitude
    are coerced to a stable `numeric` so the schema no longer flips
    between `integer` and `double`: every `tran_id` (spot/sub-account
    transfers, margin borrow / repay / isolated transfer, futures
    income) and sub-account `free`/`locked`. A transaction id is a large
    identifier that overflows R’s 32-bit `integer`, so `numeric` is the
    correct, uniform type. Genuine whole-number counters (trade counts,
    IDs that stay in range) remain `integer`. Columns that can
    legitimately be absent in the payload are typed `| NA`, and the
    handful of methods whose payload shape varies per call (sub-account
    futures/margin account, locked-earn position) are typed as a plain
    `data.table`.

## binance 0.4.0

### Internal

- **Transport migrated onto `connectcore`.** The package’s hand-rolled
  transport layer now sits on
  [`connectcore`](https://github.com/dereckscompany/connectcore), the
  shared transport base extracted from these connectors’ common
  patterns. This is a purely internal swap — **the public API is
  unchanged** (the same exported classes, methods, signatures, and
  return shapes; all tests pass untouched).
  - **`BinanceBase`** now inherits
    [`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
    and supplies only the two venue-specific seams: `.sign()`
    (delegating to
    [`connectcore::hmac_query_sign()`](https://rdrr.io/pkg/connectcore/man/hmac_query_sign.html)
    with Binance’s `X-MBX-APIKEY` header) and `.parse_envelope()`
    (Binance’s negative-`code` error body). The request funnel,
    sync/async branching, retry, and throttle now live in `connectcore`.
  - **`BinanceWsBase`** now inherits
    [`connectcore::StreamClient`](https://rdrr.io/pkg/connectcore/man/StreamClient.html)
    and supplies only `.dispatch()` (control-ack filtering + per-stream
    routing) and `.resubscribe()` plus Binance’s
    `SUBSCRIBE`/`UNSUBSCRIBE` control protocol. Auto-reconnect,
    keepalive, the silence watchdog, proactive reconnect, and the event
    loop now live in `connectcore`.
  - Deleted the now-duplicated transport machinery (`then_or_now()`, the
    request-building/signing internals, and the
    reconnect/keepalive/dispatch internals), routing the retained
    wrappers
    ([`binance_build_request()`](https://dereckscompany.github.io/binance/reference/binance_build_request.md),
    `sign_request()`, `fetch_server_time_ms()`) through `connectcore`
    instead.
  - Adds `connectcore` to `Imports`.

## binance 0.3.0

### New features

- **Live WebSocket market-data streams.** A new event-driven client for
  Binance’s public spot streams, modelled on the Node.js `ws` API (and
  on Binance’s own official connectors). Two new exported R6 classes:

  - **`BinanceWsBase`** — the abstract base: register handlers with
    `$on("message"|"open"|"close"|"error", handler)`, `$subscribe()` /
    `$unsubscribe()`, and `$run()` to keep the process alive and pump
    R’s `later` event loop (which, like Node, is built on libuv).
    Connection management is automatic: full-jitter exponential-backoff
    reconnect on an unexpected close, a proactive reconnect at 23h
    (before Binance’s 24h forced disconnect), automatic re-subscribe of
    every tracked stream after a reconnect, and library-handled
    ping/pong.
  - **`BinanceMarketStream`** — typed spot streams; first endpoint is
    **`$depth(symbol, speed)`**, the order-book diff stream
    (`<symbol>@depth` / `@depth@100ms`) — the only order-book data
    Binance does not archive, so it must be captured live. Many symbols
    share one connection (up to 1024 streams).

  Handlers receive the **raw JSON message string** — parse with
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
  or write straight to disk for faithful archival. Unlike the REST
  classes there is no `async` flag: a socket is an endless push stream
  with no single result, so it is always event-driven (the one thing R
  adds over Node is `$run()` to keep the loop alive). Built on the
  `websocket` and `later` packages, now hard `Imports`.

- **New
  [`vignette("websocket-streams", package = "binance")`](https://dereckscompany.github.io/binance/articles/websocket-streams.md)**
  — the event API, the two ways to drive the event loop (your own
  `later` loop, or `$run()`), the order-book recorder pattern, and
  reconnection.

- **Typed contracts via `roxyassert`.** The new WebSocket classes adopt
  [`roxyassert`](https://github.com/dereckscompany/roxyassert): every
  `@param`/`@return` is a typed annotation, and the argument/return
  checks are generated from it into `R/contracts-generated.R`
  (committed, like `NAMESPACE`) so the documented contract and the
  runtime check come from one source. This is the first use of
  roxyassert in the package; the rest migrates incrementally (untyped
  tags are untouched). Adds `assert` to `Imports`.

## binance 0.2.4

### Features

- **Kline fetching now pages forward by following the data** instead of
  pre-slicing the range into fixed windows. `binance_fetch_klines()`
  (used by `get_klines(fetch_all = TRUE)` on both `BinanceMarketData`
  and `BinanceFuturesData`, and by
  [`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md))
  requests up to `max_candles` candles from a cursor, advances past the
  last candle returned, and stops as soon as a page comes back empty or
  short. Because Binance returns candles with `open_time >= startTime`,
  an empty leading stretch — e.g. years before a symbol was listed — is
  skipped in a **single** request instead of being probed slice by
  slice. This turns what used to be hundreds of empty requests into one,
  with identical results on dense ranges.

- **New `on_page` callback** on `BinanceMarketData$get_klines()` and
  `BinanceFuturesData$get_klines()` (active when `fetch_all = TRUE`).
  Each page (a `data.table`) is passed to `on_page(page)` as it is
  fetched and is **not** accumulated — so a caller can process
  arbitrarily large ranges without holding everything in memory; the
  method then returns invisibly. Works in both synchronous and
  asynchronous modes.

- **[`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)
  now writes each page as it is fetched** (via the same `on_page`
  mechanism), so an interrupted backfill loses at most one page and
  never re-requests a page that was already written. The closed-candle
  filter (only persist candles whose `close_time` has passed) now runs
  per page.

## binance 0.2.3

### Bug fixes

- **[`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)
  no longer persists the still-forming candle.** When the backfill
  window reached the live edge, Binance returns the candle currently
  forming (its `close_time` in the future). The function wrote that
  half-built candle to the CSV, and because resume advances past the
  last stored `open_time`, it was never refreshed to its final values —
  so the most recent candle of every `(symbol, timeframe)` could be
  permanently incomplete. The function now drops any candle whose
  `close_time` is in the future before writing; the next run re-fetches
  and completes it once closed. Closed historical candles — including
  ones that straddle an explicit past `to` — are unaffected.

## binance 0.2.2

### Bug fixes

- **`coerce_cols(dt, cols, fn)` deduplicates `cols`**. Previously
  passing the same column name twice —
  `coerce_cols(dt, c("time", "time"), ms_to_datetime)` — would feed the
  already-coerced POSIXct value back through `ms_to_datetime`,
  reinterpreting epoch-seconds as epoch-ms and silently producing wildly
  wrong values (year 56,000+). Now uses `for (col in unique(cols))`.
  Same fix applied to the sister `kucoin` and `alpaca` helpers.
- **`ms_to_datetime()` no longer emits spurious
  `"NAs introduced by coercion"` warnings** on all-`NA_character_`
  input. Implemented by type-dispatching on the input and only feeding
  the non-NA entries to
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html) — not
  [`suppressWarnings()`](https://rdrr.io/r/base/warning.html), which
  would hide genuine bad input (e.g. a malformed numeric string from a
  future API change). Pinned by a counter-regression test that asserts a
  malformed string still warns loudly. Applies to every endpoint whose
  payload sometimes omits a timestamp field.

## binance 0.2.1

### Refactor

- **New internal `coerce_cols(dt, cols, fn)` helper** in
  `R/helpers_parse.R`. Replaces the repeated
  `if (nrow(dt) > 0 && "X" %in% names(dt)) { dt[, X := fn(X)] }`
  boilerplate that appeared 67 times across 13 R6 method files. Per-
  column conversion now reads as
  `coerce_cols(dt, c("transact_time", "working_time"), ms_to_datetime)`.
  Modifies `dt` by reference via
  [`data.table::set()`](https://rdrr.io/pkg/data.table/man/assign.html);
  columns not in `dt` are silently skipped; empty `dt` short-circuits.
  Converter- agnostic — passes any `fn(vec) → vec` function.

- **New internal `utc_string_to_datetime(x)`** alongside
  `ms_to_datetime`. Parses Binance’s UTC datetime strings
  (`"YYYY-MM-DD HH:MM:SS"`) via
  [`lubridate::ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html)
  and normalises empty strings — Binance’s “not set yet” signal on
  in-progress withdrawals — to `NA` so the parse doesn’t warn. Used by
  `BinanceWithdrawal::get_withdrawal_history`.

- **`parse_paginated()` now delegates** its `time_cols` loop to
  `coerce_cols()` — one place to maintain the conversion contract.

No behaviour change. Refactor only.

## binance 0.2.0

### Timestamp fields are now POSIXct (breaking)

A batch of millisecond-timestamp fields that were previously returned as
raw numeric `numeric` (or, in two endpoints, as character UTC strings)
are now parsed to `POSIXct` (UTC), matching the cross-package convention
shared with `alpaca`. The conversion happens inside the parser;
downstream code that already treated these as datetimes
(e.g. `format(dt$working_time, ...)`) keeps working. Code that did
`as.numeric(dt$working_time)` to recover the raw ms needs to use
`as.numeric(dt$working_time) * 1000` (POSIXct epoch seconds → ms) or
`format(dt$working_time)` instead.

Affected methods and fields:

- **`BinanceTrading`** — `working_time` on `add_order()`, `get_order()`,
  `get_open_orders()`, `get_all_orders()`.
- **`BinanceOcoOrders`** — `order_report_transact_time` on
  `add_oco_order()` and `cancel_oco_order()`.
- **`BinanceAccount`** — `update_time` on `get_account_info()`.
- **`BinanceSubAccount`** — `update_time` on `get_futures_account()`,
  `insert_time` on `get_status()`.
- **`BinanceMargin`** — `updated_time` on
  `get_force_liquidation_history()` (the parser used to silently drop
  the conversion despite the `@return` doc claiming POSIXct).
- **`BinanceEarn`** — `subscription_start_time` on
  `get_flexible_position()`; `purchase_time`, `next_pay_date`,
  `rewards_end_date`, `deliver_date`, `partial_amt_deliver_date` on
  `get_locked_position()`; `detail_subscription_start_time`,
  `detail_boost_end_time` on `get_locked_products()`; `deliver_date` on
  `get_locked_redemption_history()`.
- **`BinanceWithdrawal`** — `apply_time` and `complete_time` on
  `get_withdrawal_history()`. Binance returns these as UTC datetime
  strings (e.g. `"2019-10-12 11:12:02"`), parsed via
  [`lubridate::ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html).

The roxygen `@return` blocks are updated to reflect the new types.

### Tooling

- **LICENSE consolidated to a single MIT file.** Previously the package
  shipped both `LICENSE` (a 2-line CRAN stub) and `LICENSE.md` (the full
  MIT text with an extra Citation clause). That layout caused GitHub to
  display the licence as “Unknown, MIT licenses found”; the consolidated
  single-file form fixes the detector and drops the custom Citation
  clause. CRAN-compatible (`License: MIT + file LICENSE` accepts the new
  form), `R CMD check` clean.

- **New `scripts/LINT.sh`** mirroring the alpaca script — runs
  `devtools::load_all()` before `lintr::lint_package()` so that
  `object_usage_linter` honours the
  [`utils::globalVariables()`](https://rdrr.io/r/utils/globalVariables.html)
  declarations in `R/zzz.R` for data.table NSE columns. Exits 0 if
  clean, 1 if any warnings.

## binance 0.1.0

This release adopts the **“one entity = one row, no list columns”**
convention used by the sister `alpaca` package, and applies it to every
binance method that returns nested API data. The change is breaking on
several endpoints; the new shape is fully documented in
[`vignette("data-shapes", package = "binance")`](https://dereckscompany.github.io/binance/articles/data-shapes.md).

### Shape policy (read this first)

Every method now follows one rule: identify the entity for the endpoint,
and return one row per entity. Nested data becomes one of the following
shape treatments — no data is dropped, only reshaped:

- **A — `;` collapse** for arrays of plain strings (`order_types`,
  `permissions`, condition codes). Recover via
  `strsplit(x, ";", fixed = TRUE)[[1]]`.
- **B — Long format** for arrays of objects (order `fills`, OCO
  `orderReports`, futures `assets`, sub-account
  `spotSubUserAssetBtcVoList`).
- **C — Wide prefix** for fixed-schema nested objects
  (`commissionRates_*`, Earn `detail_*` / `quota_*`, flattened `filters`
  from `exchangeInfo`).
- **D — Re-route to a sibling method** for collections that don’t fit
  the per-entity row of the calling endpoint.
  `BinanceFutures::get_account` re-routes `positions` to
  `get_positions()`; `get_account_info` re-routes `balances` to
  `get_balances()`; `get_exchange_info()` (spot + futures) re-routes the
  exchange-wide `rateLimits`, `exchangeFilters`, and (futures only)
  `assets` blocks to dedicated sibling methods. Same data, right shape —
  every method returns one `data.table`.
- **E — JSON string** for dynamic-key or array-of-array objects where
  `;`-collapse would erase semantic grouping — spot `exchangeInfo`
  `permission_sets`, Earn `tier_annual_percentage_rate`. Recover via
  `jsonlite::fromJSON(dt$col[1])`.

Two cross-cutting rules: empty / null array → `NA_character_` (no list
cells), empty response → empty `data.table` (no synthetic stub rows).

### Breaking changes

- **No more list columns at the public API level.** If you indexed into
  a list column with `dt$col[[i]]`, that code now needs to use
  [`strsplit()`](https://rdrr.io/r/base/strsplit.html) or
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
  depending on the field. See the data-shapes vignette for per-endpoint
  recovery snippets.

- **Separator changed from `,` to `;`.** Previously-collapsed string
  arrays now use `;` for cross-package consistency with `alpaca` and
  `kucoin`. `dt$permissions` is `"SPOT;MARGIN"`, not `"SPOT,MARGIN"`.

- **`get_account_info()` returns a single row.** Was one row per
  permission; `permissions` is now `;`-collapsed.

- **`BinanceFutures::get_account()` returns one row per asset, not one
  row per `(asset × position)`.** Fixes a bug that collapsed assets to
  row 1 when positions were also expanded. The `positions` array is now
  intentionally dropped — use `get_positions()` (hits
  `/fapi/v2/positionRisk`) for per-position data.

- **`add_order_test()`** (spot + futures) now returns
  `data.table(validated = TRUE)` instead of a synthetic
  `(symbol, side, type, status = "validated")` row. The absence of an
  error is the validation signal; the synthetic row was echoing request
  parameters that weren’t returned by Binance.

- **`cancel_all_orders()`** (spot + margin) now returns an empty
  `data.table` when there were no orders to cancel, instead of a
  synthetic `(symbol, status = "cancelled")` stub row.

- **`get_spot_summary()`** returns an empty `data.table` when there are
  no sub-accounts, instead of a 1-row master-only fabrication.

- **`cancel_oco_order()` expands `orderReports` instead of `orders`.**
  Previously dropped the richer payload (cancellation status, prices,
  quantities, stop price). Columns are now prefixed `order_report_*` to
  match `add_oco_order()` exactly.

- **Earn locked-product field names match the current Binance API.**
  `detail.apy` → `detail_apr`. Added `detail_is_sold_out`,
  `detail_status`, `detail_subscription_start_time`, and the
  extra-reward / boost field set.

### New features

- **`BinanceMarketData::get_rate_limits()` and `get_exchange_filters()`;
  `BinanceFuturesData::get_rate_limits()`, `get_exchange_filters()`, and
  `get_futures_assets()`** — sibling methods that surface the
  exchange-wide blocks returned alongside the per-symbol rows in
  `/exchangeInfo`. Previously these blocks were silently dropped by the
  per-symbol parser.

- **`BinanceMarketData::get_all_24hr_stats()`** — fetches 24hr stats for
  every symbol on the exchange in one call.

- **`add_order()`** (spot) — `fill_*` columns are now always present
  (with `NA` when the order had no fills) so the schema is stable across
  `newOrderRespType` values. Added `fill_index` (1-indexed) and
  `fill_trade_id`.

- **8 previously-untested public methods** now have unit-test coverage:
  `BinanceFutures::{get_position_margin_history, modify_position_margin}`
  and
  `BinanceMargin::{add_repay, cancel_all_orders, get_open_orders, get_all_orders, get_max_transferable, get_force_liquidation_history}`.

### Bug fixes

- **`get_exchange_info()` (spot + futures) no longer silently drops
  exchange-wide metadata or rarely-used filter types.** Two leaks fixed
  in one go:

  - Top-level `rateLimits`, `exchangeFilters`, and (futures only)
    `assets` are now exposed as sibling methods —
    `BinanceMarketData$get_rate_limits()`,
    `BinanceMarketData$get_exchange_filters()`,
    `BinanceFuturesData$get_rate_limits()`,
    `BinanceFuturesData$get_exchange_filters()`,
    `BinanceFuturesData$get_futures_assets()`. Each returns one
    `data.table`, same shape policy as `get_balances()` /
    `get_account_info()`. (Spot `sors` and the constant scalars
    `timezone` / `serverTime` / `futuresType` were not exposed
    separately: `serverTime` already has the long-standing
    `get_server_time()` method; `timezone` is always `"UTC"`;
    `futuresType` is always `"U_M"` for that endpoint.)
  - The full per-symbol `filters` array is now preserved as a
    JSON-encoded `filters_raw` column. The curated `lot_*` / `price_*` /
    `min_notional` columns are unchanged, but filter types we don’t pull
    into curated columns (`PERCENT_PRICE`, `PERCENT_PRICE_BY_SIDE`,
    `MARKET_LOT_SIZE`, `MAX_NUM_ORDERS`, `MAX_NUM_ALGO_ORDERS`,
    `MAX_NUM_ICEBERG_ORDERS`, `ICEBERG_PARTS`, `MAX_POSITION`,
    `TRAILING_DELTA`) used to be discarded with the raw list. Recover
    with `jsonlite::fromJSON(dt$filters_raw[1])`.

- **[`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)
  no longer hides failures on a return attribute.** Previously,
  per-combo errors were captured during the loop and bolted onto the
  return value as `attr(file, "failures")` — easy to miss. The function
  now emits the existing per-`(symbol, timeframe)`
  [`rlang::warn()`](https://rlang.r-lib.org/reference/abort.html) *and*
  a final summary warning at the end
  (`"N of M (symbol, timeframe) combinations failed: ..."`). Return
  value is now just the file path; no hidden state. Code that previously
  read `attr(result, "failures")` should capture warnings via
  [`withCallingHandlers()`](https://rdrr.io/r/base/conditions.html) or
  [`tryCatch()`](https://rdrr.io/r/base/conditions.html) instead.

- **NULL-input crashes in three parsers.** `parse_orderbook`,
  `parse_paginated`, and the `add_order` parser used to dereference
  `data$foo` without guarding `data = NULL`, throwing
  `"$ operator applied to NULL"` on empty bodies or JSON-parse failures.
  All three now early-return an empty `data.table`.

- **`collapse_string_array_fields` was not NA-safe.** A scalar
  `NA_character_` input would throw (`grepl` → `NA` → `any(NA)` →
  `if (NA)` errors). `paste(c("real", NA), collapse = ";")` would
  produce the literal `"real;NA"`. Fixed by filtering NAs before joining
  and treating all-NA vectors as `NA_character_`.

- **`BinanceFutures::initialize()` `time_source = "server"` branch
  returned the wrong value.** Used to return the assigned
  `.get_timestamp_ms` function instead of `invisible(self)`; both
  branches now return `invisible(self)`.

- **One pre-existing test typo** — `test-live-integration-public.R`
  called `market$get_orderbook()` (method doesn’t exist; should be
  `get_depth()`). Silently broken whenever `BINANCE_LIVE_TESTS` was set.

### Documentation

- **New
  [`vignette("data-shapes", package = "binance")`](https://dereckscompany.github.io/binance/articles/data-shapes.md)**
  walking through the five shape treatments with runnable
  binance-specific examples and recovery idioms.

- **Every `Verified:` marker bumped to 2026-05-22** — 104 markers total,
  all now linked to the current `developers.binance.com` URLs.

- **51 stale `binance-docs.github.io` URLs migrated.** Binance retired
  that host; it now `301`s to a generic Changelog page with the in-page
  anchor dropped. New canonical URLs verified for every endpoint.

- **`README.Rmd` “Design Philosophy” rewritten** to describe the actual
  per-endpoint normalisations, including the explicit list of endpoints
  that drop fields.

- **JSON Response examples in roxygen** updated to match the live API
  shapes — Earn flexible/locked positions previously showed the old
  field set; spot `exchangeInfo` now shows `permissionSets` and the
  modern `commissionRates` object.

- **New `R/helpers_parse.R::collapse_string_array_fields`** — shared
  helper with worked round-trip examples for plain-string fields,
  NA-safety handling, and a once-per-session collision warning if any
  input value contains the separator.

### Tooling

- **`.lintr` config repaired** — the leading `# .lintr` header comment
  was breaking DCF parsing, so `lintr::lint_package()` couldn’t run. New
  three-style `object_name_linter` policy plus a binance-specific
  `camelCase` allowance for API parameter names (`recvWindow`,
  `orderId`, `omitZeroBalances`).

- **`.Rbuildignore`** excludes `docs/` and `.playwright-mcp/` so
  `R CMD check` stays clean.

## binance 0.0.1

Initial release of the `binance` R package — a comprehensive API wrapper
for the Binance cryptocurrency exchange.

### Classes

- **BinanceMarketData** — public market data: tickers, klines, orderbook
  depth, 24hr stats, exchange info, server time, recent trades, average
  price.
- **BinanceTrading** — spot order placement (limit, market, stop-limit),
  cancellation, modification, and queries; includes test-order endpoint.
- **BinanceAccount** — account balances, trade history, fee rates,
  snapshots.
- **BinanceDeposit** — deposit address creation and deposit history.
- **BinanceWithdrawal** — withdrawal submission and history.
- **BinanceTransfer** — internal asset transfers between wallets (spot,
  margin, futures, funding) with paginated history.
- **BinanceOcoOrders** — OCO (one-cancels-the-other) order placement,
  queries, and cancellation.
- **BinanceMarginData** — cross-margin pair info, price index, interest
  rate history, cross-margin collateral data.
- **BinanceMargin** — margin borrowing/repayment, margin order
  placement, account info, max borrowable queries, margin trades.
- **BinanceSubAccount** — sub-account listing.
- **BinanceEarn** — Simple Earn flexible product listing, subscription,
  and position queries.
- **BinanceFuturesData** — futures market data: exchange info, klines,
  mark price, funding rates, open interest, index/mark price klines.
- **BinanceFutures** — futures trading: order placement, cancellation,
  account and balance queries, position management, leverage/margin-type
  configuration, income history, position mode.

### Features

- All responses returned as `data.table` with snake_case column names.
- Millisecond timestamps automatically converted to `POSIXct`.
- Synchronous and asynchronous (promise-based) operation via
  `async = TRUE`.
- HMAC-SHA256 authentication with configurable timestamp source.
- 988 unit tests with full mocking via `httr2`.
- 48 live integration tests (skip-guarded).
