# binance — Roadmap

> Version 0.0.1 · Last updated 2026-03-08

## Naming convention

| Verb       | Meaning         | Suffixes |
|------------|-----------------|----------|
| `get_*`    | Query           | `_by_id` |
| `add_*`    | Create (POST)   | `_batch` |
| `cancel_*` | Cancel (DELETE) | `_by_id` |
| `modify_*` | Amend in place  |          |
| `set_*`    | Configure       |          |

snake_case throughout. No API version numbers in method names.

------------------------------------------------------------------------

## Implemented (v0.0.1)

### 1. Market Data — `BinanceMarketData` class

Tickers, klines, orderbooks, currencies, symbols, trade history, server
time, exchange info.

### 2. Trading — `BinanceTrading` class

Place, cancel, modify, and query spot orders.

### 3. Account — `BinanceAccount` class

Account balances, trade history, fee rates, API key info.

### 4. Deposit — `BinanceDeposit` class

Deposit addresses and history.

### 5. Withdrawal — `BinanceWithdrawal` class

Withdrawal creation, cancellation, and history.

### 6. Transfer — `BinanceTransfer` class

Internal asset transfers between wallets with paginated history.

### 7. OCO Orders — `BinanceOcoOrders` class

One-cancels-the-other order placement, queries, and cancellation.

### 8. Margin Data — `BinanceMarginData` class

Cross-margin pair info, price index, interest rate history, collateral
data.

### 9. Margin Trading — `BinanceMargin` class

Margin borrowing/repayment, order placement, account info, max
borrowable, trades.

### 10. Sub-Account — `BinanceSubAccount` class

Sub-account listing.

### 11. Earn — `BinanceEarn` class

Simple Earn flexible product listing, subscription, and position
queries.

### 12. Futures Data — `BinanceFuturesData` class

Futures market data: exchange info, klines, mark price, funding rates,
open interest.

### 13. Futures Trading — `BinanceFutures` class

Futures order lifecycle, account/balance/position queries, leverage and
margin-type configuration, income history, position mode.

------------------------------------------------------------------------

## Won’t do (for now)

- **WebSocket**: real-time feeds — significant separate architecture
