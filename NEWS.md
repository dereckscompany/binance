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
