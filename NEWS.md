# binance 0.2.4

## Features

* **Kline fetching now pages forward by following the data** instead of
  pre-slicing the range into fixed windows. `binance_fetch_klines()` (used by
  `get_klines(fetch_all = TRUE)` on both `BinanceMarketData` and
  `BinanceFuturesData`, and by `binance_backfill_klines()`) requests up to
  `max_candles` candles from a cursor, advances past the last candle returned,
  and stops as soon as a page comes back empty or short. Because Binance returns
  candles with `open_time >= startTime`, an empty leading stretch — e.g. years
  before a symbol was listed — is skipped in a **single** request instead of
  being probed slice by slice. This turns what used to be hundreds of empty
  requests into one, with identical results on dense ranges.

* **New `on_page` callback** on `BinanceMarketData$get_klines()` and
  `BinanceFuturesData$get_klines()` (active when `fetch_all = TRUE`). Each page
  (a `data.table`) is passed to `on_page(page)` as it is fetched and is **not**
  accumulated — so a caller can process arbitrarily large ranges without holding
  everything in memory; the method then returns invisibly. Works in both
  synchronous and asynchronous modes.

* **`binance_backfill_klines()` now writes each page as it is fetched** (via the
  same `on_page` mechanism), so an interrupted backfill loses at most one page
  and never re-requests a page that was already written. The closed-candle filter
  (only persist candles whose `close_time` has passed) now runs per page.

# binance 0.2.3

## Bug fixes

* **`binance_backfill_klines()` no longer persists the still-forming candle.**
  When the backfill window reached the live edge, Binance returns the candle
  currently forming (its `close_time` in the future). The function wrote that
  half-built candle to the CSV, and because resume advances past the last stored
  `open_time`, it was never refreshed to its final values — so the most recent
  candle of every `(symbol, timeframe)` could be permanently incomplete. The
  function now drops any candle whose `close_time` is in the future before
  writing; the next run re-fetches and completes it once closed. Closed
  historical candles — including ones that straddle an explicit past `to` — are
  unaffected.

# binance 0.2.2

## Bug fixes

* **`coerce_cols(dt, cols, fn)` deduplicates `cols`**. Previously passing the same column name twice — `coerce_cols(dt, c("time", "time"), ms_to_datetime)` — would feed the already-coerced POSIXct value back through `ms_to_datetime`, reinterpreting epoch-seconds as epoch-ms and silently producing wildly wrong values (year 56,000+). Now uses `for (col in unique(cols))`. Same fix applied to the sister `kucoin` and `alpaca` helpers.
* **`ms_to_datetime()` no longer emits spurious `"NAs introduced by coercion"` warnings** on all-`NA_character_` input. Implemented by type-dispatching on the input and only feeding the non-NA entries to `as.numeric()` — not `suppressWarnings()`, which would hide genuine bad input (e.g. a malformed numeric string from a future API change). Pinned by a counter-regression test that asserts a malformed string still warns loudly. Applies to every endpoint whose payload sometimes omits a timestamp field.

# binance 0.2.1

## Refactor

* **New internal `coerce_cols(dt, cols, fn)` helper** in `R/helpers_parse.R`.
  Replaces the repeated
  `if (nrow(dt) > 0 && "X" %in% names(dt)) { dt[, X := fn(X)] }`
  boilerplate that appeared 67 times across 13 R6 method files. Per-
  column conversion now reads as
  `coerce_cols(dt, c("transact_time", "working_time"), ms_to_datetime)`.
  Modifies `dt` by reference via `data.table::set()`; columns not in
  `dt` are silently skipped; empty `dt` short-circuits. Converter-
  agnostic — passes any `fn(vec) → vec` function.

* **New internal `utc_string_to_datetime(x)`** alongside `ms_to_datetime`.
  Parses Binance's UTC datetime strings (`"YYYY-MM-DD HH:MM:SS"`) via
  `lubridate::ymd_hms()` and normalises empty strings — Binance's
  "not set yet" signal on in-progress withdrawals — to `NA` so the
  parse doesn't warn. Used by `BinanceWithdrawal::get_withdrawal_history`.

* **`parse_paginated()` now delegates** its `time_cols` loop to
  `coerce_cols()` — one place to maintain the conversion contract.

No behaviour change. Refactor only.

# binance 0.2.0

## Timestamp fields are now POSIXct (breaking)

A batch of millisecond-timestamp fields that were previously returned
as raw numeric `numeric` (or, in two endpoints, as character UTC
strings) are now parsed to `POSIXct` (UTC), matching the cross-package
convention shared with `alpaca`. The conversion happens inside the
parser; downstream code that already treated these as datetimes
(e.g. `format(dt$working_time, ...)`) keeps working. Code that did
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
- **`BinanceMargin`** — `updated_time` on `get_force_liquidation_history()`
  (the parser used to silently drop the conversion despite the
  `@return` doc claiming POSIXct).
- **`BinanceEarn`** — `subscription_start_time` on
  `get_flexible_position()`; `purchase_time`, `next_pay_date`,
  `rewards_end_date`, `deliver_date`, `partial_amt_deliver_date` on
  `get_locked_position()`; `detail_subscription_start_time`,
  `detail_boost_end_time` on `get_locked_products()`; `deliver_date`
  on `get_locked_redemption_history()`.
- **`BinanceWithdrawal`** — `apply_time` and `complete_time` on
  `get_withdrawal_history()`. Binance returns these as UTC datetime
  strings (e.g. `"2019-10-12 11:12:02"`), parsed via
  `lubridate::ymd_hms()`.

The roxygen `@return` blocks are updated to reflect the new types.

## Tooling

* **LICENSE consolidated to a single MIT file.** Previously the package
  shipped both `LICENSE` (a 2-line CRAN stub) and `LICENSE.md` (the
  full MIT text with an extra Citation clause). That layout caused
  GitHub to display the licence as "Unknown, MIT licenses found"; the
  consolidated single-file form fixes the detector and drops the
  custom Citation clause. CRAN-compatible (`License: MIT + file
  LICENSE` accepts the new form), `R CMD check` clean.

* **New `scripts/LINT.sh`** mirroring the alpaca script — runs
  `devtools::load_all()` before `lintr::lint_package()` so that
  `object_usage_linter` honours the `utils::globalVariables()`
  declarations in `R/zzz.R` for data.table NSE columns. Exits 0 if
  clean, 1 if any warnings.

# binance 0.1.0

This release adopts the **"one entity = one row, no list columns"**
convention used by the sister `alpaca` package, and applies it to every
binance method that returns nested API data. The change is breaking on
several endpoints; the new shape is fully documented in
`vignette("data-shapes", package = "binance")`.

## Shape policy (read this first)

Every method now follows one rule: identify the entity for the
endpoint, and return one row per entity. Nested data becomes one of
the following shape treatments — no data is dropped, only reshaped:

- **A — `;` collapse** for arrays of plain strings (`order_types`,
  `permissions`, condition codes). Recover via
  `strsplit(x, ";", fixed = TRUE)[[1]]`.
- **B — Long format** for arrays of objects (order `fills`, OCO
  `orderReports`, futures `assets`, sub-account
  `spotSubUserAssetBtcVoList`).
- **C — Wide prefix** for fixed-schema nested objects
  (`commissionRates_*`, Earn `detail_*` / `quota_*`, flattened
  `filters` from `exchangeInfo`).
- **D — Re-route to a sibling method** for collections that don't fit
  the per-entity row of the calling endpoint. `BinanceFutures::get_account`
  re-routes `positions` to `get_positions()`; `get_account_info`
  re-routes `balances` to `get_balances()`; `get_exchange_info()`
  (spot + futures) re-routes the exchange-wide `rateLimits`,
  `exchangeFilters`, and (futures only) `assets` blocks to dedicated
  sibling methods. Same data, right shape — every method returns one
  `data.table`.
- **E — JSON string** for dynamic-key or array-of-array objects where
  `;`-collapse would erase semantic grouping — spot `exchangeInfo`
  `permission_sets`, Earn `tier_annual_percentage_rate`. Recover via
  `jsonlite::fromJSON(dt$col[1])`.

Two cross-cutting rules: empty / null array → `NA_character_` (no
list cells), empty response → empty `data.table` (no synthetic stub
rows).

## Breaking changes

* **No more list columns at the public API level.** If you indexed
  into a list column with `dt$col[[i]]`, that code now needs to use
  `strsplit()` or `jsonlite::fromJSON()` depending on the field. See
  the data-shapes vignette for per-endpoint recovery snippets.

* **Separator changed from `,` to `;`.** Previously-collapsed string
  arrays now use `;` for cross-package consistency with `alpaca` and
  `kucoin`. `dt$permissions` is `"SPOT;MARGIN"`, not `"SPOT,MARGIN"`.

* **`get_account_info()` returns a single row.** Was one row per
  permission; `permissions` is now `;`-collapsed.

* **`BinanceFutures::get_account()` returns one row per asset, not
  one row per `(asset × position)`.** Fixes a bug that collapsed
  assets to row 1 when positions were also expanded. The `positions`
  array is now intentionally dropped — use `get_positions()` (hits
  `/fapi/v2/positionRisk`) for per-position data.

* **`add_order_test()`** (spot + futures) now returns
  `data.table(validated = TRUE)` instead of a synthetic
  `(symbol, side, type, status = "validated")` row. The absence of
  an error is the validation signal; the synthetic row was echoing
  request parameters that weren't returned by Binance.

* **`cancel_all_orders()`** (spot + margin) now returns an empty
  `data.table` when there were no orders to cancel, instead of a
  synthetic `(symbol, status = "cancelled")` stub row.

* **`get_spot_summary()`** returns an empty `data.table` when there
  are no sub-accounts, instead of a 1-row master-only fabrication.

* **`cancel_oco_order()` expands `orderReports` instead of `orders`.**
  Previously dropped the richer payload (cancellation status, prices,
  quantities, stop price). Columns are now prefixed `order_report_*`
  to match `add_oco_order()` exactly.

* **Earn locked-product field names match the current Binance API.**
  `detail.apy` → `detail_apr`. Added `detail_is_sold_out`,
  `detail_status`, `detail_subscription_start_time`, and the
  extra-reward / boost field set.

## New features

* **`BinanceMarketData::get_rate_limits()` and
  `get_exchange_filters()`; `BinanceFuturesData::get_rate_limits()`,
  `get_exchange_filters()`, and `get_futures_assets()`** — sibling
  methods that surface the exchange-wide blocks returned alongside
  the per-symbol rows in `/exchangeInfo`. Previously these blocks
  were silently dropped by the per-symbol parser.

* **`BinanceMarketData::get_all_24hr_stats()`** — fetches 24hr stats
  for every symbol on the exchange in one call.

* **`add_order()`** (spot) — `fill_*` columns are now always present
  (with `NA` when the order had no fills) so the schema is stable
  across `newOrderRespType` values. Added `fill_index` (1-indexed)
  and `fill_trade_id`.

* **8 previously-untested public methods** now have unit-test
  coverage: `BinanceFutures::{get_position_margin_history,
  modify_position_margin}` and `BinanceMargin::{add_repay,
  cancel_all_orders, get_open_orders, get_all_orders,
  get_max_transferable, get_force_liquidation_history}`.

## Bug fixes

* **`get_exchange_info()` (spot + futures) no longer silently drops
  exchange-wide metadata or rarely-used filter types.** Two leaks
  fixed in one go:
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
    JSON-encoded `filters_raw` column. The curated `lot_*` / `price_*`
    / `min_notional` columns are unchanged, but filter types we don't
    pull into curated columns (`PERCENT_PRICE`, `PERCENT_PRICE_BY_SIDE`,
    `MARKET_LOT_SIZE`, `MAX_NUM_ORDERS`, `MAX_NUM_ALGO_ORDERS`,
    `MAX_NUM_ICEBERG_ORDERS`, `ICEBERG_PARTS`, `MAX_POSITION`,
    `TRAILING_DELTA`) used to be discarded with the raw list. Recover
    with `jsonlite::fromJSON(dt$filters_raw[1])`.

* **`binance_backfill_klines()` no longer hides failures on a return
  attribute.** Previously, per-combo errors were captured during the
  loop and bolted onto the return value as `attr(file, "failures")`
  — easy to miss. The function now emits the existing
  per-`(symbol, timeframe)` `rlang::warn()` *and* a final summary
  warning at the end (`"N of M (symbol, timeframe) combinations
  failed: ..."`). Return value is now just the file path; no hidden
  state. Code that previously read `attr(result, "failures")` should
  capture warnings via `withCallingHandlers()` or `tryCatch()`
  instead.

* **NULL-input crashes in three parsers.** `parse_orderbook`,
  `parse_paginated`, and the `add_order` parser used to dereference
  `data$foo` without guarding `data = NULL`, throwing
  `"$ operator applied to NULL"` on empty bodies or JSON-parse
  failures. All three now early-return an empty `data.table`.

* **`collapse_string_array_fields` was not NA-safe.** A scalar
  `NA_character_` input would throw (`grepl` → `NA` → `any(NA)` →
  `if (NA)` errors). `paste(c("real", NA), collapse = ";")` would
  produce the literal `"real;NA"`. Fixed by filtering NAs before
  joining and treating all-NA vectors as `NA_character_`.

* **`BinanceFutures::initialize()` `time_source = "server"` branch
  returned the wrong value.** Used to return the assigned
  `.get_timestamp_ms` function instead of `invisible(self)`; both
  branches now return `invisible(self)`.

* **One pre-existing test typo** — `test-live-integration-public.R`
  called `market$get_orderbook()` (method doesn't exist; should be
  `get_depth()`). Silently broken whenever `BINANCE_LIVE_TESTS` was
  set.

## Documentation

* **New `vignette("data-shapes", package = "binance")`** walking
  through the five shape treatments with runnable binance-specific
  examples and recovery idioms.

* **Every `Verified:` marker bumped to 2026-05-22** — 104 markers
  total, all now linked to the current `developers.binance.com`
  URLs.

* **51 stale `binance-docs.github.io` URLs migrated.** Binance
  retired that host; it now `301`s to a generic Changelog page with
  the in-page anchor dropped. New canonical URLs verified for every
  endpoint.

* **`README.Rmd` "Design Philosophy" rewritten** to describe the
  actual per-endpoint normalisations, including the explicit list of
  endpoints that drop fields.

* **JSON Response examples in roxygen** updated to match the live
  API shapes — Earn flexible/locked positions previously showed the
  old field set; spot `exchangeInfo` now shows `permissionSets` and
  the modern `commissionRates` object.

* **New `R/helpers_parse.R::collapse_string_array_fields`** — shared
  helper with worked round-trip examples for plain-string fields,
  NA-safety handling, and a once-per-session collision warning if
  any input value contains the separator.

## Tooling

* **`.lintr` config repaired** — the leading `# .lintr` header
  comment was breaking DCF parsing, so `lintr::lint_package()`
  couldn't run. New three-style `object_name_linter` policy plus a
  binance-specific `camelCase` allowance for API parameter names
  (`recvWindow`, `orderId`, `omitZeroBalances`).

* **`.Rbuildignore`** excludes `docs/` and `.playwright-mcp/` so
  `R CMD check` stays clean.

# binance 0.0.1

Initial release of the `binance` R package — a comprehensive API wrapper for
the Binance cryptocurrency exchange.

## Classes

* **BinanceMarketData** — public market data: tickers, klines, orderbook depth,
  24hr stats, exchange info, server time, recent trades, average price.
* **BinanceTrading** — spot order placement (limit, market, stop-limit),
  cancellation, modification, and queries; includes test-order endpoint.
* **BinanceAccount** — account balances, trade history, fee rates, snapshots.
* **BinanceDeposit** — deposit address creation and deposit history.
* **BinanceWithdrawal** — withdrawal submission and history.
* **BinanceTransfer** — internal asset transfers between wallets (spot, margin,
  futures, funding) with paginated history.
* **BinanceOcoOrders** — OCO (one-cancels-the-other) order placement, queries,
  and cancellation.
* **BinanceMarginData** — cross-margin pair info, price index, interest rate
  history, cross-margin collateral data.
* **BinanceMargin** — margin borrowing/repayment, margin order placement,
  account info, max borrowable queries, margin trades.
* **BinanceSubAccount** — sub-account listing.
* **BinanceEarn** — Simple Earn flexible product listing, subscription, and
  position queries.
* **BinanceFuturesData** — futures market data: exchange info, klines, mark
  price, funding rates, open interest, index/mark price klines.
* **BinanceFutures** — futures trading: order placement, cancellation, account
  and balance queries, position management, leverage/margin-type configuration,
  income history, position mode.

## Features

* All responses returned as `data.table` with snake_case column names.
* Millisecond timestamps automatically converted to `POSIXct`.
* Synchronous and asynchronous (promise-based) operation via `async = TRUE`.
* HMAC-SHA256 authentication with configurable timestamp source.
* 988 unit tests with full mocking via `httr2`.
* 48 live integration tests (skip-guarded).
