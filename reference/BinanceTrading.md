# BinanceTrading: Spot Order Management

BinanceTrading: Spot Order Management

BinanceTrading: Spot Order Management

## Details

Provides methods for placing, cancelling, and querying spot orders on
Binance. Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **Order Placement**: Place limit/market orders with full parameter
  control.

- **Order Testing**: Validate order parameters without execution via the
  test endpoint.

- **Order Cancellation**: Cancel by order ID, client order ID, or all
  open orders on a symbol.

- **Order Queries**: Retrieve order details, open orders, and all
  orders.

### Usage

All methods require authentication (valid API key and secret).

### Official Documentation

[Binance Spot
Trading](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints)

### Endpoints Covered

|                   |                           |        |
|-------------------|---------------------------|--------|
| Method            | Endpoint                  | HTTP   |
| add_order         | POST /api/v3/order        | POST   |
| add_order_test    | POST /api/v3/order/test   | POST   |
| cancel_order      | DELETE /api/v3/order      | DELETE |
| cancel_all_orders | DELETE /api/v3/openOrders | DELETE |
| get_order         | GET /api/v3/order         | GET    |
| get_open_orders   | GET /api/v3/openOrders    | GET    |
| get_all_orders    | GET /api/v3/allOrders     | GET    |

## Order Types

- `"LIMIT"`: requires `price`, `quantity`, `timeInForce`.

- `"MARKET"`: requires either `quantity` or `quoteOrderQty`.

- `"STOP_LOSS"`, `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`,
  `"TAKE_PROFIT_LIMIT"`: conditional.

- `"LIMIT_MAKER"`: like LIMIT but rejected if it would immediately
  match.

## Time-In-Force Options

- `"GTC"` (Good Till Cancelled): Remains until filled or cancelled.
  Default.

- `"IOC"` (Immediate Or Cancel): Fill immediately or cancel remainder.

- `"FOK"` (Fill Or Kill): Fill entirely or cancel completely.

## Self-Trade Prevention

- `"NONE"`, `"EXPIRE_TAKER"`, `"EXPIRE_MAKER"`, `"EXPIRE_BOTH"`.

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`binance::BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceTrading`

## Methods

### Public methods

- [`BinanceTrading$add_order()`](#method-BinanceTrading-add_order)

- [`BinanceTrading$add_order_test()`](#method-BinanceTrading-add_order_test)

- [`BinanceTrading$cancel_order()`](#method-BinanceTrading-cancel_order)

- [`BinanceTrading$cancel_all_orders()`](#method-BinanceTrading-cancel_all_orders)

- [`BinanceTrading$get_order()`](#method-BinanceTrading-get_order)

- [`BinanceTrading$get_open_orders()`](#method-BinanceTrading-get_open_orders)

- [`BinanceTrading$get_all_orders()`](#method-BinanceTrading-get_all_orders)

- [`BinanceTrading$clone()`](#method-BinanceTrading-clone)

Inherited methods

- [`binance::BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_order()`

Place an Order

Places a new spot order on Binance.

#### API Endpoint

`POST https://api.binance.com/api/v3/order`

#### Official Documentation

[Binance New
Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#new-order-trade)
Verified: 2026-05-22

#### Automated Trading Usage

- **Limit Orders**: Set specific entry/exit prices for strategy
  execution.

- **Market Orders**: Execute immediately at best available price.

- **Response Type**: Use `newOrderRespType = "FULL"` to get fill details
  in the response.

#### curl

    curl -X POST 'https://api.binance.com/api/v3/order' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'symbol=BTCUSDT&side=BUY&type=LIMIT&timeInForce=GTC&quantity=0.0001&price=50000&timestamp=1729176273859&signature=...'

#### JSON Response (FULL)

    {
      "symbol": "BTCUSDT",
      "orderId": 28,
      "orderListId": -1,
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
      "fills": []
    }

#### Usage

    BinanceTrading$add_order(
      type,
      symbol,
      side,
      quantity = NULL,
      quoteOrderQty = NULL,
      price = NULL,
      timeInForce = NULL,
      newClientOrderId = NULL,
      stopPrice = NULL,
      icebergQty = NULL,
      newOrderRespType = NULL,
      selfTradePreventionMode = NULL,
      recvWindow = NULL
    )

#### Arguments

- `type`:

  (scalar\<character\>) `"LIMIT"` or `"MARKET"` (and stop/take-profit
  variants).

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `side`:

  (scalar\<character\>) `"BUY"` or `"SELL"`.

- `quantity`:

  (scalar\<numeric\>?) base asset quantity.

- `quoteOrderQty`:

  (scalar\<numeric\>?) quote asset quantity (market orders only).

- `price`:

  (scalar\<numeric\>?) price for limit orders.

- `timeInForce`:

  (scalar\<character\>?) `"GTC"`, `"IOC"`, `"FOK"`.

- `newClientOrderId`:

  (scalar\<character\>?) unique client order ID.

- `stopPrice`:

  (scalar\<numeric\>?) trigger price for stop orders.

- `icebergQty`:

  (scalar\<numeric\>?) iceberg quantity.

- `newOrderRespType`:

  (scalar\<character\>?) `"ACK"`, `"RESULT"`, or `"FULL"`.

- `selfTradePreventionMode`:

  (scalar\<character\>?)

- `recvWindow`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per fill (one row with
`NA` `fill_*` columns when the order had no fills):

- symbol (character) Trading pair (e.g., `"BTCUSDT"`).

- order_id (numeric) Unique order identifier assigned by Binance.

- order_list_id (numeric) OCO order list ID; `-1` if not an OCO.

- client_order_id (character) Client-assigned order ID.

- price (character) Order price.

- orig_qty (character) Original requested quantity.

- executed_qty (character) Quantity filled so far.

- cummulative_quote_qty (character) Cumulative quote asset transacted.

- status (character) Order status (`"NEW"`, `"FILLED"`, `"CANCELED"`,
  etc.).

- time_in_force (character) Time-in-force policy (`"GTC"`, `"IOC"`,
  `"FOK"`).

- type (character) Order type (`"LIMIT"`, `"MARKET"`, etc.).

- side (character) `"BUY"` or `"SELL"`.

- working_time (POSIXct) Time when the order started working.

- self_trade_prevention_mode (character) STP mode applied.

- transact_time (POSIXct) Transaction time converted from
  `transactTime`.

- fill_index (integer \| NA) 1-indexed fill position (`NA` when the
  order had no fills).

- fill_price (character \| NA) Fill execution price (`NA` when no
  fills).

- fill_qty (character \| NA) Fill quantity (`NA` when no fills).

- fill_commission (character \| NA) Commission charged for this fill
  (`NA` when no fills).

- fill_commission_asset (character \| NA) Asset used for commission
  (e.g., `"BNB"`; `NA` when no fills).

- fill_trade_id (numeric \| NA) Fill trade ID (a 64-bit id; `numeric` to
  avoid 32-bit overflow; `NA` when no fills).

When the order has N fills, the parent order fields are replicated on
each of the N rows and `fill_index` runs `1..N`. When the order has no
fills (e.g. a resting `LIMIT` order with `newOrderRespType = "ACK"` /
`"RESULT"`), a single row is returned with the `fill_*` columns present
as `NA` so the schema is stable across response types.

#### Examples

    \dontrun{
    trading <- BinanceTrading$new()
    order <- trading$add_order(
      type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
      price = 50000, quantity = 0.0001
    )
    print(order)
    }

------------------------------------------------------------------------

### Method `add_order_test()`

Test Order Placement

Simulates placing an order without execution. Validates all parameters
and authentication exactly as `add_order()`, but no order is actually
created. Returns [`{}`](https://rdrr.io/r/base/Paren.html) on success.

#### API Endpoint

`POST https://api.binance.com/api/v3/order/test`

#### Official Documentation

[Binance Test New
Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#test-new-order-trade)
Verified: 2026-05-22

#### Automated Trading Usage

- **Parameter Validation**: Verify order parameters are correct before
  live submission.

- **Auth Testing**: Confirm API credentials work for order placement.

- **Integration Testing**: Test your trading pipeline end-to-end without
  risk.

#### curl

    curl -X POST 'https://api.binance.com/api/v3/order/test' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'symbol=BTCUSDT&side=BUY&type=LIMIT&timeInForce=GTC&quantity=0.0001&price=50000.00&timestamp=1729176273859&signature=...'

#### JSON Request

    {
      "symbol": "BTCUSDT",
      "side": "BUY",
      "type": "LIMIT",
      "timeInForce": "GTC",
      "quantity": "0.00010000",
      "price": "50000.00000000",
      "timestamp": 1729176273859,
      "signature": "..."
    }

#### JSON Response

    {}

#### Usage

    BinanceTrading$add_order_test(
      type,
      symbol,
      side,
      quantity = NULL,
      quoteOrderQty = NULL,
      price = NULL,
      timeInForce = NULL,
      newClientOrderId = NULL,
      stopPrice = NULL,
      icebergQty = NULL,
      newOrderRespType = NULL,
      selfTradePreventionMode = NULL,
      recvWindow = NULL
    )

#### Arguments

- `type`:

  (scalar\<character\>) `"LIMIT"` or `"MARKET"` (and stop/take-profit
  variants).

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `side`:

  (scalar\<character\>) `"BUY"` or `"SELL"`.

- `quantity`:

  (scalar\<numeric\>?) base asset quantity.

- `quoteOrderQty`:

  (scalar\<numeric\>?) quote asset quantity (market orders only).

- `price`:

  (scalar\<numeric\>?) price for limit orders.

- `timeInForce`:

  (scalar\<character\>?) `"GTC"`, `"IOC"`, `"FOK"`.

- `newClientOrderId`:

  (scalar\<character\>?) unique client order ID.

- `stopPrice`:

  (scalar\<numeric\>?) trigger price for stop orders.

- `icebergQty`:

  (scalar\<numeric\>?) iceberg quantity.

- `newOrderRespType`:

  (scalar\<character\>?) `"ACK"`, `"RESULT"`, or `"FULL"`.

- `selfTradePreventionMode`:

  (scalar\<character\>?)

- `recvWindow`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) a single row. Binance returns
[`{}`](https://rdrr.io/r/base/Paren.html) on a successful test order —
the absence of an error is the validation signal, so we don't fabricate
a stub row echoing the request parameters (per the cross-package "no
stub rows" convention).

- validated (logical) `TRUE` on a successful test order.

#### Examples

    \dontrun{
    trading <- BinanceTrading$new()
    test <- trading$add_order_test(
      type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
      price = 50000, quantity = 0.0001
    )
    stopifnot(test$validated)
    }

------------------------------------------------------------------------

### Method `cancel_order()`

Cancel an Order

Cancels an active order by order ID or client order ID.

#### API Endpoint

`DELETE https://api.binance.com/api/v3/order`

#### Official Documentation

[Binance Cancel
Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#cancel-order-trade)
Verified: 2026-05-22

#### curl

    curl -X DELETE 'https://api.binance.com/api/v3/order?symbol=BTCUSDT&orderId=4293153&timestamp=1729176273859&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "origClientOrderId": "msXkySR3u5uYwpvRMFsi3u",
      "orderId": 4293153,
      "orderListId": -1,
      "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
      "transactTime": 1507725176595,
      "price": "50000.00000000",
      "origQty": "0.00010000",
      "executedQty": "0.00000000",
      "cummulativeQuoteQty": "0.00000000",
      "status": "CANCELED",
      "timeInForce": "GTC",
      "type": "LIMIT",
      "side": "BUY",
      "selfTradePreventionMode": "NONE"
    }

#### Usage

    BinanceTrading$cancel_order(
      symbol,
      orderId = NULL,
      origClientOrderId = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `orderId`:

  (scalar\<count\>?) the order ID to cancel.

- `origClientOrderId`:

  (scalar\<character\>?) the client order ID to cancel.

- `recvWindow`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- symbol (character) Trading pair.

- orig_client_order_id (character) Original client order ID.

- order_id (numeric) Unique order identifier.

- order_list_id (numeric) OCO order list ID; `-1` if not an OCO.

- client_order_id (character) New client order ID after cancellation.

- price (character) Order price.

- orig_qty (character) Original requested quantity.

- executed_qty (character) Quantity filled before cancellation.

- cummulative_quote_qty (character) Cumulative quote asset transacted.

- status (character) Order status (typically `"CANCELED"`).

- time_in_force (character) Time-in-force policy.

- type (character) Order type.

- side (character) `"BUY"` or `"SELL"`.

- self_trade_prevention_mode (character) STP mode applied.

- transact_time (POSIXct) Cancellation time converted from
  `transactTime`.

#### Examples

    \dontrun{
    trading <- BinanceTrading$new()
    cancelled <- trading$cancel_order("BTCUSDT", orderId = 12345)
    print(cancelled)
    }

------------------------------------------------------------------------

### Method `cancel_all_orders()`

Cancel All Open Orders on a Symbol

Cancels all active orders on a trading pair.

#### API Endpoint

`DELETE https://api.binance.com/api/v3/openOrders`

#### Official Documentation

[Binance Cancel All Open
Orders](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#cancel-all-open-orders-on-a-symbol-trade)
Verified: 2026-05-22

#### curl

    curl -X DELETE 'https://api.binance.com/api/v3/openOrders?symbol=BTCUSDT&timestamp=1729176273859&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "origClientOrderId": "E6APeyTJvkMvLMYMqu1KQ4",
        "orderId": 11,
        "orderListId": -1,
        "clientOrderId": "pXLV6Hz6mprAcVYpVMTGgx",
        "transactTime": 1684804350068,
        "price": "50000.00000000",
        "origQty": "0.00010000",
        "executedQty": "0.00000000",
        "cummulativeQuoteQty": "0.00000000",
        "status": "CANCELED",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "side": "BUY",
        "selfTradePreventionMode": "NONE"
      },
      {
        "symbol": "BTCUSDT",
        "origClientOrderId": "A3EF2HCwxgZPFMrfwbgrhv",
        "orderId": 13,
        "orderListId": -1,
        "clientOrderId": "pXLV6Hz6mprAcVYpVMTGgx",
        "transactTime": 1684804350068,
        "price": "48000.00000000",
        "origQty": "0.00020000",
        "executedQty": "0.00000000",
        "cummulativeQuoteQty": "0.00000000",
        "status": "CANCELED",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "side": "BUY",
        "selfTradePreventionMode": "NONE"
      }
    ]

#### Usage

    BinanceTrading$cancel_all_orders(symbol, recvWindow = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `recvWindow`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per cancelled order (empty
when there were no open orders to cancel, per the cross-package "no stub
rows" convention — the absence of an error is the success signal):

- symbol (character) Trading pair.

- orig_client_order_id (character) Original client order ID.

- order_id (numeric) Unique order identifier.

- order_list_id (numeric) OCO order list ID; `-1` if not an OCO.

- client_order_id (character) New client order ID after cancellation.

- price (character) Order price.

- orig_qty (character) Original requested quantity.

- executed_qty (character) Quantity filled before cancellation.

- cummulative_quote_qty (character) Cumulative quote asset transacted.

- status (character) Order status (typically `"CANCELED"`).

- time_in_force (character) Time-in-force policy.

- type (character) Order type.

- side (character) `"BUY"` or `"SELL"`.

- self_trade_prevention_mode (character) STP mode applied.

- transact_time (POSIXct) Cancellation time.

#### Examples

    \dontrun{
    trading <- BinanceTrading$new()
    cancelled <- trading$cancel_all_orders("BTCUSDT")
    print(cancelled)
    }

------------------------------------------------------------------------

### Method `get_order()`

Query Order

Retrieves details for a specific order by order ID or client order ID.

#### API Endpoint

`GET https://api.binance.com/api/v3/order`

#### Official Documentation

[Binance Query
Order](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-order-user_data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/order?symbol=BTCUSDT&orderId=4293153&timestamp=1729176273859&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "symbol": "BTCUSDT",
      "orderId": 4293153,
      "orderListId": -1,
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
      "isWorking": true,
      "workingTime": 1507725176595,
      "origQuoteOrderQty": "0.00000000",
      "selfTradePreventionMode": "NONE"
    }

#### Usage

    BinanceTrading$get_order(
      symbol,
      orderId = NULL,
      origClientOrderId = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `orderId`:

  (scalar\<count\>?) the order ID.

- `origClientOrderId`:

  (scalar\<character\>?) the client order ID.

- `recvWindow`:

  (scalar\<count\>?) max 60000.

#### Returns

(SpotOrderQuery \| promise\<SpotOrderQuery\>) one row, the order.

#### Examples

    \dontrun{
    trading <- BinanceTrading$new()
    order <- trading$get_order("BTCUSDT", orderId = 12345)
    print(order)
    }

------------------------------------------------------------------------

### Method `get_open_orders()`

Get Open Orders

Retrieves all currently open orders, optionally filtered by symbol.

#### API Endpoint

`GET https://api.binance.com/api/v3/openOrders`

#### Official Documentation

[Binance Current Open
Orders](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#current-open-orders-user_data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/openOrders?symbol=BTCUSDT&timestamp=1729176273859&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "orderId": 4293153,
        "orderListId": -1,
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
        "isWorking": true,
        "workingTime": 1507725176595,
        "origQuoteOrderQty": "0.00000000",
        "selfTradePreventionMode": "NONE"
      }
    ]

#### Usage

    BinanceTrading$get_open_orders(symbol = NULL, recvWindow = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>?) trading pair (e.g., `"BTCUSDT"`). If NULL,
  returns open orders for all symbols (weight 80).

- `recvWindow`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per open order (empty when
there are none):

- symbol (character) Trading pair.

- order_id (numeric) Exchange-assigned order id.

- order_list_id (numeric) OCO list id, or `-1` for a non-OCO order.

- client_order_id (character) Client-assigned order id.

- price (character) Order price.

- orig_qty (character) Original requested quantity.

- executed_qty (character) Quantity filled so far.

- cummulative_quote_qty (character) Cumulative quote quantity filled.

- status (character) Order status.

- time_in_force (character) Time-in-force policy.

- type (character) Order type.

- side (character) `"BUY"` or `"SELL"`.

- stop_price (character) Stop trigger price.

- iceberg_qty (character) Iceberg quantity.

- time (POSIXct) Order creation time.

- is_working (logical) Whether the order is on the book.

- orig_quote_order_qty (character) Original quote order quantity.

- working_time (POSIXct) Time the order started working.

- self_trade_prevention_mode (character) Self-trade-prevention mode.

#### Examples

    \dontrun{
    trading <- BinanceTrading$new()
    open <- trading$get_open_orders("BTCUSDT")
    print(open)
    }

------------------------------------------------------------------------

### Method `get_all_orders()`

Get All Orders

Retrieves all orders for a symbol (open, cancelled, filled). If
`orderId` is set, orders \>= that ID are returned. Otherwise the most
recent orders are returned.

#### API Endpoint

`GET https://api.binance.com/api/v3/allOrders`

#### Official Documentation

[Binance All
Orders](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#all-orders-user_data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/allOrders?symbol=BTCUSDT&limit=50&timestamp=1729176273859&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "symbol": "BTCUSDT",
        "orderId": 4293153,
        "orderListId": -1,
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
        "isWorking": true,
        "workingTime": 1507725176595,
        "origQuoteOrderQty": "0.00000000",
        "selfTradePreventionMode": "NONE"
      },
      {
        "symbol": "BTCUSDT",
        "orderId": 4293154,
        "orderListId": -1,
        "clientOrderId": "x]]C3kvs44T7fYqJ09VBfg",
        "price": "0.00000000",
        "origQty": "0.00010000",
        "executedQty": "0.00010000",
        "cummulativeQuoteQty": "5.10230000",
        "status": "FILLED",
        "timeInForce": "GTC",
        "type": "MARKET",
        "side": "SELL",
        "stopPrice": "0.00000000",
        "icebergQty": "0.00000000",
        "time": 1507725276595,
        "updateTime": 1507725276595,
        "isWorking": true,
        "workingTime": 1507725276595,
        "origQuoteOrderQty": "0.00000000",
        "selfTradePreventionMode": "NONE"
      }
    ]

#### Usage

    BinanceTrading$get_all_orders(
      symbol,
      orderId = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `orderId`:

  (scalar\<count\>?) pagination cursor.

- `startTime`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `endTime`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1000).

- `recvWindow`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per order (empty when
there are no matching orders):

- symbol (character) Trading pair.

- order_id (numeric) Exchange-assigned order id.

- order_list_id (numeric) OCO list id, or `-1` for a non-OCO order.

- client_order_id (character) Client-assigned order id.

- price (character) Order price.

- orig_qty (character) Original requested quantity.

- executed_qty (character) Quantity filled so far.

- cummulative_quote_qty (character) Cumulative quote quantity filled.

- status (character) Order status.

- time_in_force (character) Time-in-force policy.

- type (character) Order type.

- side (character) `"BUY"` or `"SELL"`.

- stop_price (character) Stop trigger price.

- iceberg_qty (character) Iceberg quantity.

- time (POSIXct) Order creation time.

- is_working (logical) Whether the order is on the book.

- orig_quote_order_qty (character) Original quote order quantity.

- working_time (POSIXct) Time the order started working.

- self_trade_prevention_mode (character) Self-trade-prevention mode.

#### Examples

    \dontrun{
    trading <- BinanceTrading$new()
    all <- trading$get_all_orders("BTCUSDT", limit = 50)
    print(all[, .(order_id, side, price, status, time)])
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceTrading$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
trading <- BinanceTrading$new()
order <- trading$add_order_test(type = "LIMIT", symbol = "BTCUSDT",
                                 side = "BUY", price = 50000, quantity = 0.0001)
print(order)

# Asynchronous
trading_async <- BinanceTrading$new(async = TRUE)
main <- coro::async(function() {
  order <- await(trading_async$add_order_test(
    type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
    price = 50000, quantity = 0.0001
  ))
  print(order)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceTrading$add_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- BinanceTrading$new()
order <- trading$add_order(
  type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
  price = 50000, quantity = 0.0001
)
print(order)
} # }

## ------------------------------------------------
## Method `BinanceTrading$add_order_test`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- BinanceTrading$new()
test <- trading$add_order_test(
  type = "LIMIT", symbol = "BTCUSDT", side = "BUY",
  price = 50000, quantity = 0.0001
)
stopifnot(test$validated)
} # }

## ------------------------------------------------
## Method `BinanceTrading$cancel_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- BinanceTrading$new()
cancelled <- trading$cancel_order("BTCUSDT", orderId = 12345)
print(cancelled)
} # }

## ------------------------------------------------
## Method `BinanceTrading$cancel_all_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- BinanceTrading$new()
cancelled <- trading$cancel_all_orders("BTCUSDT")
print(cancelled)
} # }

## ------------------------------------------------
## Method `BinanceTrading$get_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- BinanceTrading$new()
order <- trading$get_order("BTCUSDT", orderId = 12345)
print(order)
} # }

## ------------------------------------------------
## Method `BinanceTrading$get_open_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- BinanceTrading$new()
open <- trading$get_open_orders("BTCUSDT")
print(open)
} # }

## ------------------------------------------------
## Method `BinanceTrading$get_all_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- BinanceTrading$new()
all <- trading$get_all_orders("BTCUSDT", limit = 50)
print(all[, .(order_id, side, price, status, time)])
} # }
```
