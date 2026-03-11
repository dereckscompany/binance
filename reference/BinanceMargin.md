# BinanceMargin: Margin Trading Operations

BinanceMargin: Margin Trading Operations

BinanceMargin: Margin Trading Operations

## Details

Provides methods for margin borrowing, repaying, order management, and
account queries on Binance. Inherits from
[BinanceBase](https://dereckmezquita.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **Borrowing / Repaying**: Borrow and repay assets on cross or isolated
  margin.

- **Order Management**: Place, cancel, and query margin orders.

- **Account Info**: Query margin account details, max
  borrowable/transferable amounts.

- **History**: Retrieve interest history, force liquidation records, and
  trade history.

- **Isolated Margin**: Query isolated margin accounts and initiate
  isolated transfers.

### Usage

All methods require authentication (valid API key and secret). These are
SAPI (`/sapi/`) endpoints.

### Official Documentation

[Binance Margin
Trading](https://developers.binance.com/docs/margin_trading/Introduction)

### Endpoints Covered

|                               |                                                 |        |
|-------------------------------|-------------------------------------------------|--------|
| Method                        | Endpoint                                        | HTTP   |
| add_borrow                    | POST /sapi/v1/margin/borrow-repay (type=BORROW) | POST   |
| add_repay                     | POST /sapi/v1/margin/borrow-repay (type=REPAY)  | POST   |
| add_order                     | POST /sapi/v1/margin/order                      | POST   |
| cancel_order                  | DELETE /sapi/v1/margin/order                    | DELETE |
| cancel_all_orders             | DELETE /sapi/v1/margin/openOrders               | DELETE |
| get_order                     | GET /sapi/v1/margin/order                       | GET    |
| get_open_orders               | GET /sapi/v1/margin/openOrders                  | GET    |
| get_all_orders                | GET /sapi/v1/margin/allOrders                   | GET    |
| get_account                   | GET /sapi/v1/margin/account                     | GET    |
| get_max_borrowable            | GET /sapi/v1/margin/maxBorrowable               | GET    |
| get_max_transferable          | GET /sapi/v1/margin/maxTransferable             | GET    |
| get_interest_history          | GET /sapi/v1/margin/interestHistory             | GET    |
| get_force_liquidation_history | GET /sapi/v1/margin/forceLiquidationRec         | GET    |
| get_trades                    | GET /sapi/v1/margin/myTrades                    | GET    |
| get_isolated_account          | GET /sapi/v1/margin/isolated/account            | GET    |
| add_isolated_transfer         | POST /sapi/v1/margin/isolated/transfer          | POST   |

## Order Types

- `"LIMIT"`: requires `price`, `quantity`, `timeInForce`.

- `"MARKET"`: requires either `quantity` or `quoteOrderQty`.

- `"STOP_LOSS"`, `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`,
  `"TAKE_PROFIT_LIMIT"`: conditional.

- `"LIMIT_MAKER"`: like LIMIT but rejected if it would immediately
  match.

## Side Effect Types

- `"NO_SIDE_EFFECT"`: Normal trade order.

- `"MARGIN_BUY"`: Margin trade order with auto-borrow.

- `"AUTO_REPAY"`: Margin trade order with auto-repay.

## Super class

[`binance::BinanceBase`](https://dereckmezquita.github.io/binance/reference/BinanceBase.md)
-\> `BinanceMargin`

## Methods

### Public methods

- [`BinanceMargin$add_borrow()`](#method-BinanceMargin-add_borrow)

- [`BinanceMargin$add_repay()`](#method-BinanceMargin-add_repay)

- [`BinanceMargin$add_order()`](#method-BinanceMargin-add_order)

- [`BinanceMargin$cancel_order()`](#method-BinanceMargin-cancel_order)

- [`BinanceMargin$cancel_all_orders()`](#method-BinanceMargin-cancel_all_orders)

- [`BinanceMargin$get_order()`](#method-BinanceMargin-get_order)

- [`BinanceMargin$get_open_orders()`](#method-BinanceMargin-get_open_orders)

- [`BinanceMargin$get_all_orders()`](#method-BinanceMargin-get_all_orders)

- [`BinanceMargin$get_account()`](#method-BinanceMargin-get_account)

- [`BinanceMargin$get_max_borrowable()`](#method-BinanceMargin-get_max_borrowable)

- [`BinanceMargin$get_max_transferable()`](#method-BinanceMargin-get_max_transferable)

- [`BinanceMargin$get_interest_history()`](#method-BinanceMargin-get_interest_history)

- [`BinanceMargin$get_force_liquidation_history()`](#method-BinanceMargin-get_force_liquidation_history)

- [`BinanceMargin$get_trades()`](#method-BinanceMargin-get_trades)

- [`BinanceMargin$get_isolated_account()`](#method-BinanceMargin-get_isolated_account)

- [`BinanceMargin$add_isolated_transfer()`](#method-BinanceMargin-add_isolated_transfer)

- [`BinanceMargin$clone()`](#method-BinanceMargin-clone)

Inherited methods

- [`binance::BinanceBase$initialize()`](https://dereckmezquita.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_borrow()`

Borrow on Margin

Initiates a margin loan for the specified asset and amount. Uses the
consolidated borrow-repay endpoint with `type = "BORROW"`.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/margin/borrow-repay`

#### Official Documentation

[Binance Margin
Borrow-Repay](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Margin-Account-Borrow-Repay)

Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/margin/borrow-repay?asset=USDT&amount=100&type=BORROW&isIsolated=FALSE&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Request

    {
      "asset": "USDT",
      "amount": "100",
      "type": "BORROW",
      "isIsolated": "FALSE"
    }

#### JSON Response

    {
      "tranId": 100000001
    }

#### Usage

    BinanceMargin$add_borrow(
      asset,
      amount,
      isIsolated = "FALSE",
      symbol = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character; asset to borrow (e.g., `"USDT"`).

- `amount`:

  Numeric; amount to borrow.

- `isIsolated`:

  Character; `"TRUE"` or `"FALSE"` for isolated margin. Default
  `"FALSE"`.

- `symbol`:

  Character or NULL; required when `isIsolated = "TRUE"`.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `tran_id` (integer): Transaction identifier.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    result <- margin$add_borrow(asset = "USDT", amount = 100)
    print(result)
    }

------------------------------------------------------------------------

### Method `add_repay()`

Repay Margin Loan

Repays a margin loan for the specified asset and amount. Uses the
consolidated borrow-repay endpoint with `type = "REPAY"`.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/margin/borrow-repay`

#### Official Documentation

[Binance Margin
Borrow-Repay](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Margin-Account-Borrow-Repay)

Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/margin/borrow-repay?asset=USDT&amount=100&type=REPAY&isIsolated=FALSE&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Request

    {
      "asset": "USDT",
      "amount": "100",
      "type": "REPAY",
      "isIsolated": "FALSE"
    }

#### JSON Response

    {
      "tranId": 100000002
    }

#### Usage

    BinanceMargin$add_repay(
      asset,
      amount,
      isIsolated = "FALSE",
      symbol = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character; asset to repay (e.g., `"USDT"`).

- `amount`:

  Numeric; amount to repay.

- `isIsolated`:

  Character; `"TRUE"` or `"FALSE"` for isolated margin. Default
  `"FALSE"`.

- `symbol`:

  Character or NULL; required when `isIsolated = "TRUE"`.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `tran_id` (integer): Transaction identifier.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    result <- margin$add_repay(asset = "USDT", amount = 100)
    print(result)
    }

------------------------------------------------------------------------

### Method `add_order()`

Place a Margin Order

Places a new margin order on Binance.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/margin/order`

#### Official Documentation

[Binance Margin New
Order](https://developers.binance.com/docs/margin_trading/trade/Margin-Account-New-Order)

Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/margin/order?symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=0.0001&price=50000&timeInForce=GTC&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Request

    {
      "symbol": "BTCUSDT",
      "side": "BUY",
      "type": "LIMIT",
      "quantity": "0.0001",
      "price": "50000",
      "timeInForce": "GTC",
      "sideEffectType": "NO_SIDE_EFFECT"
    }

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "orderId": 28,
      "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
      "transactTime": 1507725176595,
      "price": "50000.00000000",
      "origQty": "0.00010000",
      "executedQty": "0.00000000",
      "cummulativeQuoteQty": "0.00000000",
      "status": "NEW",
      "timeInForce": "GTC",
      "type": "LIMIT",
      "side": "BUY",
      "isIsolated": false
    }

#### Usage

    BinanceMargin$add_order(
      symbol,
      side,
      type,
      quantity = NULL,
      quoteOrderQty = NULL,
      price = NULL,
      stopPrice = NULL,
      timeInForce = NULL,
      newClientOrderId = NULL,
      newOrderRespType = NULL,
      sideEffectType = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `side`:

  Character; `"BUY"` or `"SELL"`.

- `type`:

  Character; order type: `"LIMIT"`, `"MARKET"`, `"STOP_LOSS"`,
  `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`, `"TAKE_PROFIT_LIMIT"`,
  `"LIMIT_MAKER"`.

- `quantity`:

  Numeric or NULL; base asset quantity.

- `quoteOrderQty`:

  Numeric or NULL; quote asset quantity (market orders only).

- `price`:

  Numeric or NULL; price for limit orders.

- `stopPrice`:

  Numeric or NULL; trigger price for stop orders.

- `timeInForce`:

  Character or NULL; `"GTC"`, `"IOC"`, `"FOK"`.

- `newClientOrderId`:

  Character or NULL; unique client order ID.

- `newOrderRespType`:

  Character or NULL; `"ACK"`, `"RESULT"`, or `"FULL"`.

- `sideEffectType`:

  Character or NULL; `"NO_SIDE_EFFECT"`, `"MARGIN_BUY"`, `"AUTO_REPAY"`.

- `isIsolated`:

  Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and columns including:

- `symbol` (character): Trading pair.

- `order_id` (integer): Unique order identifier.

- `client_order_id` (character): Client-assigned order ID.

- `transact_time` (POSIXct): Transaction time.

- `price` (character): Order price.

- `orig_qty` (character): Original requested quantity.

- `executed_qty` (character): Quantity filled so far.

- `status` (character): Order status.

- `type` (character): Order type.

- `side` (character): `"BUY"` or `"SELL"`.

- `is_isolated` (logical): Whether this is an isolated margin order.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    order <- margin$add_order(
      symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
      price = 50000, quantity = 0.0001, timeInForce = "GTC"
    )
    print(order)
    }

------------------------------------------------------------------------

### Method `cancel_order()`

Cancel a Margin Order

Cancels an active margin order by order ID or client order ID.

#### API Endpoint

`DELETE https://api.binance.com/sapi/v1/margin/order`

#### Official Documentation

[Binance Margin Cancel
Order](https://developers.binance.com/docs/margin_trading/trade/Margin-Account-Cancel-Order)

Verified: 2026-03-10

#### curl

    curl -X DELETE 'https://api.binance.com/sapi/v1/margin/order?symbol=BTCUSDT&orderId=28&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Request

    {
      "symbol": "BTCUSDT",
      "orderId": 28
    }

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "orderId": 28,
      "origClientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
      "clientOrderId": "cancelMyOrder1",
      "transactTime": 1507725176595,
      "price": "50000.00000000",
      "origQty": "0.00010000",
      "executedQty": "0.00000000",
      "cummulativeQuoteQty": "0.00000000",
      "status": "CANCELED",
      "timeInForce": "GTC",
      "type": "LIMIT",
      "side": "BUY",
      "isIsolated": false
    }

#### Usage

    BinanceMargin$cancel_order(
      symbol,
      orderId = NULL,
      origClientOrderId = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `orderId`:

  Integer or NULL; the order ID to cancel.

- `origClientOrderId`:

  Character or NULL; the client order ID to cancel.

- `isIsolated`:

  Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and columns including:

- `symbol` (character): Trading pair.

- `order_id` (integer): Unique order identifier.

- `orig_client_order_id` (character): Original client order ID.

- `status` (character): Order status (typically `"CANCELED"`).

- `transact_time` (POSIXct): Cancellation time.

- `is_isolated` (logical): Whether this is an isolated margin order.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    cancelled <- margin$cancel_order("BTCUSDT", orderId = 28)
    print(cancelled)
    }

------------------------------------------------------------------------

### Method `cancel_all_orders()`

Cancel All Open Margin Orders on a Symbol

Cancels all active margin orders on a trading pair.

#### API Endpoint

`DELETE https://api.binance.com/sapi/v1/margin/openOrders`

#### Official Documentation

[Binance Margin Cancel All
Orders](https://developers.binance.com/docs/margin_trading/trade/Margin-Account-Cancel-All-Open-Orders)

Verified: 2026-03-10

#### curl

    curl -X DELETE 'https://api.binance.com/sapi/v1/margin/openOrders?symbol=BTCUSDT&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Request

    {
      "symbol": "BTCUSDT"
    }

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "orderId": 28,
        "origClientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
        "clientOrderId": "cancelMyOrder1",
        "transactTime": 1507725176595,
        "price": "50000.00000000",
        "origQty": "0.00010000",
        "executedQty": "0.00000000",
        "cummulativeQuoteQty": "0.00000000",
        "status": "CANCELED",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "side": "BUY",
        "isIsolated": false
      }
    ]

#### Usage

    BinanceMargin$cancel_all_orders(symbol, isIsolated = NULL, recvWindow = NULL)

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `isIsolated`:

  Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`). When orders
are cancelled, one row per order with columns:

- `symbol` (character): Trading pair.

- `order_id` (integer): Unique order identifier.

- `orig_client_order_id` (character): Original client order ID.

- `status` (character): Order status (typically `"CANCELED"`).

- `transact_time` (POSIXct): Cancellation time.

- `is_isolated` (logical): Whether this is an isolated margin order.

When no open orders exist, a single confirmation row with columns:

- `symbol` (character): The requested trading pair.

- `status` (character): `"cancelled"`.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    cancelled <- margin$cancel_all_orders("BTCUSDT")
    print(cancelled)
    }

------------------------------------------------------------------------

### Method `get_order()`

Query a Margin Order

Retrieves details for a specific margin order by order ID or client
order ID.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/order`

#### Official Documentation

[Binance Margin Query
Order](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-Order)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/order?symbol=BTCUSDT&orderId=28&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "orderId": 28,
      "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
      "price": "50000.00000000",
      "origQty": "0.00010000",
      "executedQty": "0.00010000",
      "cummulativeQuoteQty": "5.00000000",
      "status": "FILLED",
      "timeInForce": "GTC",
      "type": "LIMIT",
      "side": "BUY",
      "stopPrice": "0.00000000",
      "icebergQty": "0.00000000",
      "time": 1507725176595,
      "updateTime": 1507725176595,
      "isIsolated": false
    }

#### Usage

    BinanceMargin$get_order(
      symbol,
      orderId = NULL,
      origClientOrderId = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `orderId`:

  Integer or NULL; the order ID.

- `origClientOrderId`:

  Character or NULL; the client order ID.

- `isIsolated`:

  Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and columns including:

- `symbol` (character): Trading pair.

- `order_id` (integer): Unique order identifier.

- `client_order_id` (character): Client-assigned order ID.

- `price` (character): Order price.

- `orig_qty` (character): Original requested quantity.

- `executed_qty` (character): Quantity filled so far.

- `status` (character): Order status.

- `type` (character): Order type.

- `side` (character): `"BUY"` or `"SELL"`.

- `time` (POSIXct): Order creation time.

- `update_time` (POSIXct): Last update time.

- `is_isolated` (logical): Whether this is an isolated margin order.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    order <- margin$get_order("BTCUSDT", orderId = 28)
    print(order)
    }

------------------------------------------------------------------------

### Method `get_open_orders()`

Get Open Margin Orders

Retrieves all currently open margin orders, optionally filtered by
symbol.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/openOrders`

#### Official Documentation

[Binance Margin Open
Orders](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-Open-Orders)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/openOrders?symbol=BTCUSDT&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "orderId": 28,
        "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
        "price": "50000.00000000",
        "origQty": "0.00010000",
        "executedQty": "0.00000000",
        "cummulativeQuoteQty": "0.00000000",
        "status": "NEW",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "side": "BUY",
        "stopPrice": "0.00000000",
        "icebergQty": "0.00000000",
        "time": 1507725176595,
        "updateTime": 1507725176595,
        "isIsolated": false
      }
    ]

#### Usage

    BinanceMargin$get_open_orders(
      symbol = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character or NULL; trading pair (e.g., `"BTCUSDT"`).

- `isIsolated`:

  Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per open order and the following columns:

- `symbol` (character): Trading pair.

- `order_id` (integer): Unique order identifier.

- `client_order_id` (character): Client-assigned order ID.

- `price` (character): Order price.

- `orig_qty` (character): Original requested quantity.

- `executed_qty` (character): Quantity filled so far.

- `status` (character): Order status.

- `type` (character): Order type.

- `side` (character): `"BUY"` or `"SELL"`.

- `time` (POSIXct): Order creation time.

- `update_time` (POSIXct): Last update time.

- `is_isolated` (logical): Whether this is an isolated margin order.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    open <- margin$get_open_orders("BTCUSDT")
    print(open)
    }

------------------------------------------------------------------------

### Method `get_all_orders()`

Get All Margin Orders

Retrieves all margin orders for a symbol (open, cancelled, filled).

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/allOrders`

#### Official Documentation

[Binance Margin All
Orders](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-All-Orders)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/allOrders?symbol=BTCUSDT&limit=50&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "orderId": 28,
        "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
        "price": "50000.00000000",
        "origQty": "0.00010000",
        "executedQty": "0.00010000",
        "cummulativeQuoteQty": "5.00000000",
        "status": "FILLED",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "side": "BUY",
        "stopPrice": "0.00000000",
        "icebergQty": "0.00000000",
        "time": 1507725176595,
        "updateTime": 1507725176595,
        "isIsolated": false
      },
      {
        "symbol": "BTCUSDT",
        "orderId": 29,
        "clientOrderId": "x]]Xk3RFN1g2MjEDKWNq8t",
        "price": "0.00000000",
        "origQty": "0.00020000",
        "executedQty": "0.00020000",
        "cummulativeQuoteQty": "10.48000000",
        "status": "FILLED",
        "timeInForce": "GTC",
        "type": "MARKET",
        "side": "SELL",
        "stopPrice": "0.00000000",
        "icebergQty": "0.00000000",
        "time": 1507725276595,
        "updateTime": 1507725276595,
        "isIsolated": false
      }
    ]

#### Usage

    BinanceMargin$get_all_orders(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      isIsolated = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `orderId`:

  Integer or NULL; pagination cursor.

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `limit`:

  Integer or NULL; max results (default 500, max 500).

- `isIsolated`:

  Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per order and the following columns:

- `symbol` (character): Trading pair.

- `order_id` (integer): Unique order identifier.

- `client_order_id` (character): Client-assigned order ID.

- `price` (character): Order price.

- `orig_qty` (character): Original requested quantity.

- `executed_qty` (character): Quantity filled so far.

- `status` (character): Order status.

- `type` (character): Order type.

- `side` (character): `"BUY"` or `"SELL"`.

- `time` (POSIXct): Order creation time.

- `update_time` (POSIXct): Last update time.

- `is_isolated` (logical): Whether this is an isolated margin order.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    all <- margin$get_all_orders("BTCUSDT", limit = 50)
    print(all)
    }

------------------------------------------------------------------------

### Method `get_account()`

Get Margin Account Information

Retrieves cross margin account details including balances and margin
level.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/account`

#### Official Documentation

[Binance Margin
Account](https://developers.binance.com/docs/margin_trading/account/Query-Cross-Margin-Account-Details)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/account?timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "borrowEnabled": true,
      "marginLevel": "11.64405625",
      "totalAssetOfBtc": "6.82728457",
      "totalLiabilityOfBtc": "0.58633215",
      "totalNetAssetOfBtc": "6.24095242",
      "tradeEnabled": true,
      "transferEnabled": true,
      "accountType": "MARGIN",
      "userAssets": [
        {
          "asset": "BTC",
          "borrowed": "0.00000000",
          "free": "0.00499500",
          "interest": "0.00000000",
          "locked": "0.00000000",
          "netAsset": "0.00499500"
        },
        {
          "asset": "USDT",
          "borrowed": "200.00000000",
          "free": "1500.50000000",
          "interest": "0.01055556",
          "locked": "0.00000000",
          "netAsset": "1300.48944444"
        }
      ]
    }

#### Usage

    BinanceMargin$get_account(recvWindow = NULL)

#### Arguments

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and columns including:

- `borrow_enabled` (logical): Whether borrowing is enabled.

- `margin_level` (character): Current margin level.

- `total_asset_of_btc` (character): Total asset value in BTC.

- `total_liability_of_btc` (character): Total liability in BTC.

- `total_net_asset_of_btc` (character): Net asset value in BTC.

- `trade_enabled` (logical): Whether trading is enabled.

- `transfer_enabled` (logical): Whether transfers are enabled.

- `account_type` (character): Account type (`"MARGIN"`).

- `user_assets` (list): List of asset balance objects.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    account <- margin$get_account()
    print(account)
    }

------------------------------------------------------------------------

### Method `get_max_borrowable()`

Get Max Borrowable Amount

Queries the maximum borrowable amount for an asset on margin.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/maxBorrowable`

#### Official Documentation

[Binance Max
Borrowable](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Query-Max-Borrow)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/maxBorrowable?asset=USDT&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "amount": "1.69248805",
      "borrowLimit": "60"
    }

#### Usage

    BinanceMargin$get_max_borrowable(
      asset,
      isolatedSymbol = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character; asset to query (e.g., `"USDT"`).

- `isolatedSymbol`:

  Character or NULL; isolated margin pair (e.g., `"BTCUSDT"`).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `amount` (character): Maximum borrowable amount.

- `borrow_limit` (character): Borrow limit.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    max_borrow <- margin$get_max_borrowable(asset = "USDT")
    print(max_borrow)
    }

------------------------------------------------------------------------

### Method `get_max_transferable()`

Get Max Transferable Amount

Queries the maximum transferable-out amount for an asset on margin.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/maxTransferable`

#### Official Documentation

[Binance Max
Transferable](https://developers.binance.com/docs/margin_trading/transfer/Query-Max-Transfer-Out-Amount)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/maxTransferable?asset=USDT&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "amount": "3.59498107"
    }

#### Usage

    BinanceMargin$get_max_transferable(
      asset,
      isolatedSymbol = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character; asset to query (e.g., `"USDT"`).

- `isolatedSymbol`:

  Character or NULL; isolated margin pair (e.g., `"BTCUSDT"`).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `amount` (character): Maximum transferable-out amount.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    max_transfer <- margin$get_max_transferable(asset = "USDT")
    print(max_transfer)
    }

------------------------------------------------------------------------

### Method `get_interest_history()`

Get Margin Interest History

Retrieves margin interest accrual history with pagination.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/interestHistory`

#### Official Documentation

[Binance Interest
History](https://developers.binance.com/docs/margin_trading/borrow-and-repay/Get-Interest-History)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/interestHistory?asset=USDT&current=1&size=10&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "rows": [
        {
          "isolatedSymbol": "",
          "asset": "USDT",
          "interest": "0.01055556",
          "interestAccuredTime": 1672012800000,
          "interestRate": "0.00019",
          "principal": "200.00000000",
          "type": "ON_BORROW"
        },
        {
          "isolatedSymbol": "",
          "asset": "USDT",
          "interest": "0.01055556",
          "interestAccuredTime": 1672099200000,
          "interestRate": "0.00019",
          "principal": "200.00000000",
          "type": "PERIODIC"
        }
      ],
      "total": 2
    }

#### Usage

    BinanceMargin$get_interest_history(
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      archived = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character or NULL; filter by asset (e.g., `"USDT"`).

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `current`:

  Integer or NULL; current page (default 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `archived`:

  Character or NULL; `"true"` to query 6-month archived data.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per interest record and the following columns:

- `asset` (character): Asset charged interest.

- `interest` (character): Interest amount accrued.

- `interest_accured_time` (POSIXct): Time of interest accrual.

- `interest_rate` (character): Applied interest rate.

- `principal` (character): Principal amount borrowed.

- `type` (character): Margin type (`"ON_BORROW"`, `"PERIODIC"`, etc.).

- `isolated_symbol` (character): Isolated margin pair (if applicable).

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    history <- margin$get_interest_history(asset = "USDT")
    print(history)
    }

------------------------------------------------------------------------

### Method `get_force_liquidation_history()`

Get Force Liquidation History

Retrieves margin force liquidation records with pagination.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/forceLiquidationRec`

#### Official Documentation

[Binance Force
Liquidation](https://developers.binance.com/docs/margin_trading/trade/Get-Force-Liquidation-Record)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/forceLiquidationRec?current=1&size=10&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "rows": [
        {
          "avgPrice": "52341.12000000",
          "executedQty": "0.00100000",
          "orderId": 12345678,
          "price": "52000.00000000",
          "qty": "0.00100000",
          "side": "SELL",
          "symbol": "BTCUSDT",
          "timeInForce": "GTC",
          "isIsolated": false,
          "updatedTime": 1672099200000,
          "time": 1672099100000
        }
      ],
      "total": 1
    }

#### Usage

    BinanceMargin$get_force_liquidation_history(
      startTime = NULL,
      endTime = NULL,
      isolatedSymbol = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `isolatedSymbol`:

  Character or NULL; isolated margin pair.

- `current`:

  Integer or NULL; current page (default 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per liquidation record and the following
columns:

- `avg_price` (character): Average liquidation price.

- `executed_qty` (character): Liquidated quantity.

- `order_id` (integer): Liquidation order identifier.

- `price` (character): Liquidation price.

- `qty` (character): Total quantity.

- `side` (character): `"BUY"` or `"SELL"`.

- `symbol` (character): Trading pair.

- `time` (POSIXct): Liquidation time.

- `is_isolated` (logical): Whether this was an isolated margin
  liquidation.

- `updated_time` (POSIXct): Last update time.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    liquidations <- margin$get_force_liquidation_history()
    print(liquidations)
    }

------------------------------------------------------------------------

### Method `get_trades()`

Get Margin Trades

Retrieves margin trade history for a symbol.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/myTrades`

#### Official Documentation

[Binance Margin
Trades](https://developers.binance.com/docs/margin_trading/trade/Query-Margin-Account-Trade-List)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/myTrades?symbol=BTCUSDT&limit=500&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "commission": "0.00000500",
        "commissionAsset": "BTC",
        "id": 6,
        "isBestMatch": true,
        "isBuyer": true,
        "isMaker": false,
        "orderId": 28,
        "price": "52341.12000000",
        "qty": "0.00010000",
        "symbol": "BTCUSDT",
        "isIsolated": false,
        "time": 1507725176595
      }
    ]

#### Usage

    BinanceMargin$get_trades(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      fromId = NULL,
      limit = NULL,
      isIsolated = NULL,
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

- `isIsolated`:

  Character or NULL; `"TRUE"` or `"FALSE"` for isolated margin.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per trade and columns including:

- `symbol` (character): Trading pair.

- `id` (integer): Trade ID.

- `order_id` (integer): Order ID.

- `price` (character): Trade price.

- `qty` (character): Trade quantity.

- `commission` (character): Commission paid.

- `commission_asset` (character): Commission asset.

- `time` (POSIXct): Trade execution time.

- `is_buyer` (logical): Whether the trade was a buy.

- `is_maker` (logical): Whether the trade was a maker.

- `is_isolated` (logical): Whether this is an isolated margin trade.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    trades <- margin$get_trades("BTCUSDT")
    print(trades)
    }

------------------------------------------------------------------------

### Method `get_isolated_account()`

Get Isolated Margin Account Info

Retrieves isolated margin account details.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/margin/isolated/account`

#### Official Documentation

[Binance Isolated Margin
Account](https://developers.binance.com/docs/margin_trading/account/Query-Isolated-Margin-Account-Info)

Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/margin/isolated/account?symbols=BTCUSDT,ETHUSDT&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "assets": [
        {
          "baseAsset": {
            "asset": "BTC",
            "borrowEnabled": true,
            "borrowed": "0.00000000",
            "free": "0.00100000",
            "interest": "0.00000000",
            "locked": "0.00000000",
            "netAsset": "0.00100000",
            "netAssetOfBtc": "0.00100000",
            "repayEnabled": true,
            "totalAsset": "0.00100000"
          },
          "quoteAsset": {
            "asset": "USDT",
            "borrowEnabled": true,
            "borrowed": "0.00000000",
            "free": "50.00000000",
            "interest": "0.00000000",
            "locked": "0.00000000",
            "netAsset": "50.00000000",
            "netAssetOfBtc": "0.00094750",
            "repayEnabled": true,
            "totalAsset": "50.00000000"
          },
          "symbol": "BTCUSDT",
          "isolatedCreated": true,
          "enabled": true,
          "marginLevel": "999.00000000",
          "marginRatio": "5.00000000",
          "indexPrice": "52800.00000000",
          "liquidatePrice": "0.00000000",
          "liquidateRate": "0.00000000",
          "tradeEnabled": true
        }
      ],
      "totalAssetOfBtc": "0.00194750",
      "totalLiabilityOfBtc": "0.00000000",
      "totalNetAssetOfBtc": "0.00194750"
    }

#### Usage

    BinanceMargin$get_isolated_account(symbols = NULL, recvWindow = NULL)

#### Arguments

- `symbols`:

  Character or NULL; comma-separated symbols (max 5, e.g.,
  `"BTCUSDT,ETHUSDT"`).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per isolated margin pair (long format) and
columns including:

- `total_asset_of_btc` (character): Total asset value in BTC (repeated
  per pair).

- `total_liability_of_btc` (character): Total liability in BTC (repeated
  per pair).

- `total_net_asset_of_btc` (character): Net asset value in BTC (repeated
  per pair).

- `base_asset` (list): Base asset details (nested object kept as
  list-column).

- `quote_asset` (list): Quote asset details (nested object kept as
  list-column).

- `symbol` (character): Isolated margin pair symbol.

- `isolated_created` (logical): Whether the isolated pair has been
  created.

- `enabled` (logical): Whether the pair is enabled.

- `margin_level` (character): Current margin level.

- `trade_enabled` (logical): Whether trading is enabled.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    isolated <- margin$get_isolated_account()
    print(isolated)
    }

------------------------------------------------------------------------

### Method `add_isolated_transfer()`

Isolated Margin Transfer

Transfers assets between spot and isolated margin accounts.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/margin/isolated/transfer`

#### Official Documentation

[Binance Isolated Margin
Transfer](https://developers.binance.com/docs/margin_trading/transfer/Isolated-Margin-Account-Transfer)

Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/margin/isolated/transfer?asset=USDT&symbol=BTCUSDT&transFrom=SPOT&transTo=ISOLATED_MARGIN&amount=100&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Request

    {
      "asset": "USDT",
      "symbol": "BTCUSDT",
      "transFrom": "SPOT",
      "transTo": "ISOLATED_MARGIN",
      "amount": "100"
    }

#### JSON Response

    {
      "tranId": 100000003
    }

#### Usage

    BinanceMargin$add_isolated_transfer(
      asset,
      symbol,
      transFrom,
      transTo,
      amount,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character; asset to transfer (e.g., `"USDT"`).

- `symbol`:

  Character; isolated margin pair (e.g., `"BTCUSDT"`).

- `transFrom`:

  Character; source account: `"SPOT"` or `"ISOLATED_MARGIN"`.

- `transTo`:

  Character; destination account: `"SPOT"` or `"ISOLATED_MARGIN"`.

- `amount`:

  Numeric; amount to transfer.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `tran_id` (integer): Transaction identifier.

#### Examples

    \dontrun{
    margin <- BinanceMargin$new()
    result <- margin$add_isolated_transfer(
      asset = "USDT", symbol = "BTCUSDT",
      transFrom = "SPOT", transTo = "ISOLATED_MARGIN",
      amount = 100
    )
    print(result)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceMargin$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
margin <- BinanceMargin$new()
account <- margin$get_account()
print(account)

# Asynchronous
margin_async <- BinanceMargin$new(async = TRUE)
main <- coro::async(function() {
  account <- await(margin_async$get_account())
  print(account)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceMargin$add_borrow`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
result <- margin$add_borrow(asset = "USDT", amount = 100)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceMargin$add_repay`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
result <- margin$add_repay(asset = "USDT", amount = 100)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceMargin$add_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
order <- margin$add_order(
  symbol = "BTCUSDT", side = "BUY", type = "LIMIT",
  price = 50000, quantity = 0.0001, timeInForce = "GTC"
)
print(order)
} # }

## ------------------------------------------------
## Method `BinanceMargin$cancel_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
cancelled <- margin$cancel_order("BTCUSDT", orderId = 28)
print(cancelled)
} # }

## ------------------------------------------------
## Method `BinanceMargin$cancel_all_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
cancelled <- margin$cancel_all_orders("BTCUSDT")
print(cancelled)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
order <- margin$get_order("BTCUSDT", orderId = 28)
print(order)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_open_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
open <- margin$get_open_orders("BTCUSDT")
print(open)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_all_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
all <- margin$get_all_orders("BTCUSDT", limit = 50)
print(all)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_account`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
account <- margin$get_account()
print(account)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_max_borrowable`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
max_borrow <- margin$get_max_borrowable(asset = "USDT")
print(max_borrow)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_max_transferable`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
max_transfer <- margin$get_max_transferable(asset = "USDT")
print(max_transfer)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_interest_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
history <- margin$get_interest_history(asset = "USDT")
print(history)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_force_liquidation_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
liquidations <- margin$get_force_liquidation_history()
print(liquidations)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_trades`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
trades <- margin$get_trades("BTCUSDT")
print(trades)
} # }

## ------------------------------------------------
## Method `BinanceMargin$get_isolated_account`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
isolated <- margin$get_isolated_account()
print(isolated)
} # }

## ------------------------------------------------
## Method `BinanceMargin$add_isolated_transfer`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin <- BinanceMargin$new()
result <- margin$add_isolated_transfer(
  asset = "USDT", symbol = "BTCUSDT",
  transFrom = "SPOT", transTo = "ISOLATED_MARGIN",
  amount = 100
)
print(result)
} # }
```
