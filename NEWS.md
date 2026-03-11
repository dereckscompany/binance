# binance 0.0.1.9000

## IMPROVEMENTS

* **Long-format data.table returns**: Eliminated list-columns in favour of long (tidy) format throughout. Nested arrays from the API are now expanded to one row per element with parent fields repeated:
    - `BinanceTrading$add_order()`: `fills` expanded to rows with `fill_`-prefixed columns.
    - `BinanceOcoOrders` (add/cancel/get): `orders` expanded to rows with `order_`-prefixed columns.
    - `BinanceAccount$get_account_info()`: `permissions` expanded to one row per `permission`.
    - `BinanceMarketData$get_exchange_info()`: `order_types`, `permissions`, `allowed_self_trade_prevention_modes` comma-joined into character strings. `filters` kept as list-column (heterogeneous schemas).
    - `BinanceMargin$get_isolated_account()`: `assets` expanded to one row per isolated margin pair.
    - `BinanceFutures$get_account()`: `assets` expanded to rows with `asset_`-prefixed columns.
    - `BinanceSubAccount$get_futures_account()`: `assets` expanded to rows with `asset_`-prefixed columns.

## BUG FIXES

* Removed usage of `%||%` operator which was not defined or imported; replaced with explicit `if (is.null(...))` check in `helpers_request.R`.
* Fixed clock drift example in `BinanceMarketData$get_server_time()` — drift was computed in seconds but printed as "ms". Now correctly converts to milliseconds with `round(drift * 1000)`.

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
