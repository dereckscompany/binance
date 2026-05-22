# binance 0.1.0

This release adopts the **"one entity = one row, no list columns"**
convention used by the sister `alpaca` package, and applies it to every
binance method that returns nested API data. The change is breaking on
several endpoints; the new shape is fully documented in
`vignette("data-shapes", package = "binance")`.

## Shape policy (read this first)

Every method now follows one rule: identify the entity for the
endpoint, and return one row per entity. Nested data becomes one of
five shape treatments:

- **A — `;` collapse** for arrays of plain strings (`order_types`,
  `permissions`, condition codes). Recover via
  `strsplit(x, ";", fixed = TRUE)[[1]]`.
- **B — Long format** for arrays of objects (order `fills`, OCO
  `orderReports`, futures `assets`, sub-account
  `spotSubUserAssetBtcVoList`).
- **C — Wide prefix** for fixed-schema nested objects
  (`commissionRates_*`, Earn `detail_*` / `quota_*`, flattened
  `filters` from `exchangeInfo`).
- **D — Drop and document** for heterogeneous collections that would
  otherwise force a Cartesian join — `BinanceFutures::get_account`
  drops `positions` (use `get_positions()`); `get_account_info` drops
  `balances` (use `get_balances()`); spot/futures `exchangeInfo` drop
  top-level `rateLimits` / `exchangeFilters` / `sors`.
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
