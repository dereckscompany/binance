# BinanceAccount: Account and Funding Management

BinanceAccount: Account and Funding Management

BinanceAccount: Account and Funding Management

## Details

Provides methods for querying account information, balances, and trade
history on Binance. Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **Account Info**: Retrieve balances, commission rates, and account
  permissions.

- **Trade History**: Paginated trade history for any symbol with
  datetime conversion.

### Usage

All methods require authentication (valid API key and secret set via
environment variables or passed to the constructor).

### Official Documentation

[Binance Account
Endpoints](https://binance-docs.github.io/apidocs/spot/en/#account-endpoints)

### Endpoints Covered

|                  |                      |      |
|------------------|----------------------|------|
| Method           | Endpoint             | HTTP |
| get_account_info | GET /api/v3/account  | GET  |
| get_balances     | GET /api/v3/account  | GET  |
| get_trades       | GET /api/v3/myTrades | GET  |

## Super class

[`binance::BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceAccount`

## Methods

### Public methods

- [`BinanceAccount$get_account_info()`](#method-BinanceAccount-get_account_info)

- [`BinanceAccount$get_balances()`](#method-BinanceAccount-get_balances)

- [`BinanceAccount$get_trades()`](#method-BinanceAccount-get_trades)

- [`BinanceAccount$clone()`](#method-BinanceAccount-clone)

Inherited methods

- [`binance::BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### Method `get_account_info()`

Get Account Information

Retrieves account metadata including commission rates, trading
permissions, and account type. For balances, use `get_balances()`.

#### API Endpoint

`GET https://api.binance.com/api/v3/account`

#### Official Documentation

[Binance Account
Information](https://binance-docs.github.io/apidocs/spot/en/#account-information-user_data)
Verified: 2026-03-10

#### Automated Trading Usage

- **Commission Rates**: Access maker/taker commission rates for cost
  analysis.

- **Permission Check**: Confirm `can_trade` is TRUE before placing
  orders.

#### curl

    curl -X GET 'https://api.binance.com/api/v3/account' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'timestamp=1729176273859&signature=...'

#### JSON Response

    {
      "makerCommission": 15,
      "takerCommission": 15,
      "canTrade": true,
      "canWithdraw": true,
      "canDeposit": true,
      "accountType": "SPOT",
      "balances": [...],
      "uid": 354937868
    }

#### Usage

    BinanceAccount$get_account_info(recvWindow = NULL)

#### Arguments

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `maker_commission` (integer): Maker commission rate (basis points).

- `taker_commission` (integer): Taker commission rate (basis points).

- `buyer_commission` (integer): Buyer commission rate (basis points).

- `seller_commission` (integer): Seller commission rate (basis points).

- `commission_rates` (list): Nested object with `maker`, `taker`,
  `buyer`, `seller` as decimal strings.

- `can_trade` (logical): Whether the account can place trades.

- `can_withdraw` (logical): Whether the account can withdraw.

- `can_deposit` (logical): Whether the account can deposit.

- `brokered` (logical): Whether this is a brokered account.

- `require_self_trade_prevention` (logical): Whether STP is required.

- `prevent_sor` (logical): Whether smart order routing is prevented.

- `update_time` (numeric): Last account update timestamp in
  milliseconds.

- `account_type` (character): Account type (e.g., `"SPOT"`).

- `permission` (character): Account permission (one row per permission,
  e.g., `"SPOT"`, `"MARGIN"`).

- `uid` (integer): Unique account identifier.

When the account has multiple permissions, account fields are repeated
on each row.

#### Examples

    \dontrun{
    account <- BinanceAccount$new()
    info <- account$get_account_info()
    print(info[, .(maker_commission, taker_commission, can_trade, account_type)])
    }

------------------------------------------------------------------------

### Method `get_balances()`

Get Account Balances

Retrieves asset balances for the account.

#### API Endpoint

`GET https://api.binance.com/api/v3/account`

#### Official Documentation

[Binance Account
Information](https://binance-docs.github.io/apidocs/spot/en/#account-information-user_data)
Verified: 2026-03-10

#### Automated Trading Usage

- **Balance Check**: Verify available funds before placing orders.

- **Portfolio Overview**: Get all asset balances in a single call.

#### curl

    curl -X GET 'https://api.binance.com/api/v3/account?omitZeroBalances=true' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'timestamp=1729176273859&signature=...'

#### JSON Response

    [
      {
        "asset": "BTC",
        "free": "0.00100000",
        "locked": "0.00000000"
      },
      {
        "asset": "USDT",
        "free": "500.00000000",
        "locked": "50.00000000"
      }
    ]

#### Usage

    BinanceAccount$get_balances(omitZeroBalances = NULL, recvWindow = NULL)

#### Arguments

- `omitZeroBalances`:

  Logical or NULL; if TRUE, omit assets with zero balance.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `asset` (character): Asset ticker (e.g., `"BTC"`, `"USDT"`).

- `free` (character): Available balance for trading.

- `locked` (character): Balance locked in open orders.

#### Examples

    \dontrun{
    account <- BinanceAccount$new()
    balances <- account$get_balances()
    print(balances[free != "0.00000000"])
    }

------------------------------------------------------------------------

### Method `get_trades()`

Get Account Trade List

Retrieves trades for a specific symbol. Requires authentication.

#### API Endpoint

`GET https://api.binance.com/api/v3/myTrades`

#### Official Documentation

[Binance Account Trade
List](https://binance-docs.github.io/apidocs/spot/en/#account-trade-list-user_data)
Verified: 2026-03-10

#### Automated Trading Usage

- **Trade History**: Build trade logs for P&L calculations.

- **Fill Analysis**: Analyse execution quality across trades.

- **Tax Reporting**: Export trade history for tax calculations.

#### curl

    curl -X GET 'https://api.binance.com/api/v3/myTrades?symbol=BTCUSDT' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'timestamp=1729176273859&signature=...'

#### JSON Response

    [
      {
        "symbol": "BNBBTC",
        "id": 28457,
        "orderId": 100234,
        "price": "4.00000100",
        "qty": "12.00000000",
        "quoteQty": "48.000012",
        "commission": "10.10000000",
        "commissionAsset": "BNB",
        "time": 1499865549590,
        "isBuyer": true,
        "isMaker": false,
        "isBestMatch": true
      }
    ]

#### Usage

    BinanceAccount$get_trades(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      fromId = NULL,
      limit = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `orderId`:

  Integer or NULL; filter by order ID.

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `fromId`:

  Integer or NULL; trade ID to fetch from.

- `limit`:

  Integer or NULL; max results (default 500, max 1000).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per trade and the following columns:

- `symbol` (character): Trading pair (e.g., `"BTCUSDT"`).

- `id` (integer): Unique trade identifier.

- `order_id` (integer): Order that generated this trade.

- `order_list_id` (integer): OCO order list ID; `-1` if not an OCO.

- `price` (character): Execution price.

- `qty` (character): Quantity traded.

- `quote_qty` (character): Quote asset amount transacted.

- `commission` (character): Commission charged.

- `commission_asset` (character): Asset used for commission (e.g.,
  `"BNB"`).

- `is_buyer` (logical): `TRUE` if you were the buyer.

- `is_maker` (logical): `TRUE` if you were the maker.

- `is_best_match` (logical): `TRUE` if this was the best price match.

- `time` (POSIXct): Trade execution time converted from `time`.

#### Examples

    \dontrun{
    account <- BinanceAccount$new()
    trades <- account$get_trades("BTCUSDT", limit = 50)
    print(trades[, .(id, price, qty, commission, time)])
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceAccount$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
account <- BinanceAccount$new()
info <- account$get_account_info()
print(info)
balances <- account$get_balances()
print(balances)

# Asynchronous
account_async <- BinanceAccount$new(async = TRUE)
main <- coro::async(function() {
  info <- await(account_async$get_account_info())
  print(info)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceAccount$get_account_info`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- BinanceAccount$new()
info <- account$get_account_info()
print(info[, .(maker_commission, taker_commission, can_trade, account_type)])
} # }

## ------------------------------------------------
## Method `BinanceAccount$get_balances`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- BinanceAccount$new()
balances <- account$get_balances()
print(balances[free != "0.00000000"])
} # }

## ------------------------------------------------
## Method `BinanceAccount$get_trades`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- BinanceAccount$new()
trades <- account$get_trades("BTCUSDT", limit = 50)
print(trades[, .(id, price, qty, commission, time)])
} # }
```
