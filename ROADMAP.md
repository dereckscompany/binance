# binance — Roadmap

> Version 0.0.1 · Last updated 2026-03-08

## Naming convention

| Verb | Meaning | Suffixes |
|------|---------|----------|
| `get_*` | Query | `_by_id` |
| `add_*` | Create (POST) | `_batch` |
| `cancel_*` | Cancel (DELETE) | `_by_id` |
| `modify_*` | Amend in place | |
| `set_*` | Configure | |

snake_case throughout. No API version numbers in method names.

---

## Planned

### 1. Market Data — `BinanceMarketData` class

Tickers, klines, orderbooks, currencies, symbols, trade history, server time, exchange info.

### 2. Trading — `BinanceTrading` class

Place, cancel, modify, and query spot orders.

### 3. Account — `BinanceAccount` class

Account balances, trade history, fee rates, API key info.

### 4. Deposit — `BinanceDeposit` class

Deposit addresses and history.

### 5. Withdrawal — `BinanceWithdrawal` class

Withdrawal creation, cancellation, and history.

### 6. SubAccount — `BinanceSubAccount` class

Sub-account creation and balance queries.

---

## Won't do (for now)

- **Futures**: entirely different API domain
- **WebSocket**: real-time feeds — significant separate architecture
