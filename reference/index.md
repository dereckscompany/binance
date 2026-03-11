# Package index

## API Client Classes

R6 classes for interacting with Binance REST API

- [`BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
  : BinanceBase: Abstract Base Class for Binance API Clients
- [`BinanceMarketData`](https://dereckscompany.github.io/binance/reference/BinanceMarketData.md)
  : BinanceMarketData: Spot Market Data Retrieval
- [`BinanceTrading`](https://dereckscompany.github.io/binance/reference/BinanceTrading.md)
  : BinanceTrading: Spot Order Management
- [`BinanceOcoOrders`](https://dereckscompany.github.io/binance/reference/BinanceOcoOrders.md)
  : BinanceOcoOrders: OCO Order Management
- [`BinanceAccount`](https://dereckscompany.github.io/binance/reference/BinanceAccount.md)
  : BinanceAccount: Account and Funding Management
- [`BinanceDeposit`](https://dereckscompany.github.io/binance/reference/BinanceDeposit.md)
  : BinanceDeposit: Deposit Management
- [`BinanceWithdrawal`](https://dereckscompany.github.io/binance/reference/BinanceWithdrawal.md)
  : BinanceWithdrawal: Withdrawal Management
- [`BinanceTransfer`](https://dereckscompany.github.io/binance/reference/BinanceTransfer.md)
  : BinanceTransfer: Universal Transfer Management
- [`BinanceSubAccount`](https://dereckscompany.github.io/binance/reference/BinanceSubAccount.md)
  : BinanceSubAccount: Sub-Account Management
- [`BinanceMarginData`](https://dereckscompany.github.io/binance/reference/BinanceMarginData.md)
  : BinanceMarginData: Margin Market Data Retrieval
- [`BinanceMargin`](https://dereckscompany.github.io/binance/reference/BinanceMargin.md)
  : BinanceMargin: Margin Trading Operations
- [`BinanceEarn`](https://dereckscompany.github.io/binance/reference/BinanceEarn.md)
  : BinanceEarn: Simple Earn Management
- [`BinanceFuturesData`](https://dereckscompany.github.io/binance/reference/BinanceFuturesData.md)
  : BinanceFuturesData: USD-M Futures Market Data Retrieval
- [`BinanceFutures`](https://dereckscompany.github.io/binance/reference/BinanceFutures.md)
  : BinanceFutures: USD-M Futures Trading

## Configuration

API credential and endpoint helpers

- [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md)
  : Retrieve Binance API Credentials
- [`get_base_url()`](https://dereckscompany.github.io/binance/reference/get_base_url.md)
  : Retrieve Binance API Base URL
- [`get_futures_base_url()`](https://dereckscompany.github.io/binance/reference/get_futures_base_url.md)
  : Retrieve Binance Futures API Base URL

## Low-Level Request Helpers

Functions for building and executing Binance API requests

- [`binance_build_request()`](https://dereckscompany.github.io/binance/reference/binance_build_request.md)
  : Build and Execute a Binance API Request
- [`verify_symbol()`](https://dereckscompany.github.io/binance/reference/verify_symbol.md)
  : Verify Ticker Symbol Format

## Backfill and Data

Bulk data download and included datasets

- [`binance_backfill_klines()`](https://dereckscompany.github.io/binance/reference/binance_backfill_klines.md)
  : Backfill Binance Kline Data to CSV
- [`binance_btc_usdt_4h_ohlcv`](https://dereckscompany.github.io/binance/reference/binance_btc_usdt_4h_ohlcv.md)
  : BTC-USDT 4-Hour OHLCV Data from Binance

## Utilities

Time conversion helpers

- [`time_convert_from_binance()`](https://dereckscompany.github.io/binance/reference/time_convert_from_binance.md)
  : Convert Binance Timestamp to POSIXct
- [`time_convert_to_binance()`](https://dereckscompany.github.io/binance/reference/time_convert_to_binance.md)
  : Convert POSIXct to Binance Timestamp
