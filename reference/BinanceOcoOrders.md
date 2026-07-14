# BinanceOcoOrders: OCO Order Management

Provides methods for placing, cancelling, and querying OCO
(One-Cancels-Other) orders on Binance. Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **OCO Placement**: Place OCO orders combining a limit and a stop-loss.

- **OCO Cancellation**: Cancel an entire OCO order list by ID.

- **OCO Queries**: Retrieve a specific OCO, all open OCOs, or historical
  OCOs.

### Usage

All methods require authentication (valid API key and secret).

### Official Documentation

[Binance Spot
Trading](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints)

### Endpoints Covered

|                     |                           |        |
|---------------------|---------------------------|--------|
| Method              | Endpoint                  | HTTP   |
| add_oco_order       | POST /api/v3/order/oco    | POST   |
| cancel_oco_order    | DELETE /api/v3/orderList  | DELETE |
| get_oco_order       | GET /api/v3/orderList     | GET    |
| get_open_oco_orders | GET /api/v3/openOrderList | GET    |
| get_all_oco_orders  | GET /api/v3/allOrderList  | GET    |

## Super classes

[`connectcore::RestClient`](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
-\>
[`BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceOcoOrders`

## Methods

### Public methods

- [`BinanceOcoOrders$add_oco_order()`](#method-BinanceOcoOrders-add_oco_order)

- [`BinanceOcoOrders$cancel_oco_order()`](#method-BinanceOcoOrders-cancel_oco_order)

- [`BinanceOcoOrders$get_oco_order()`](#method-BinanceOcoOrders-get_oco_order)

- [`BinanceOcoOrders$get_open_oco_orders()`](#method-BinanceOcoOrders-get_open_oco_orders)

- [`BinanceOcoOrders$get_all_oco_orders()`](#method-BinanceOcoOrders-get_all_oco_orders)

- [`BinanceOcoOrders$clone()`](#method-BinanceOcoOrders-clone)

Inherited methods

- [`BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### `BinanceOcoOrders$add_oco_order()`

Place an OCO Order

Places a new OCO (One-Cancels-Other) order on Binance. An OCO combines a
limit order and a stop-loss (or stop-loss-limit) order.

#### API Endpoint

`POST https://api.binance.com/api/v3/order/oco`

#### Official Documentation

[Binance New
OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#order-lists)
Verified: 2026-05-22

#### curl

    curl -X POST 'https://api.binance.com/api/v3/order/oco' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'symbol=BTCUSDT&side=SELL&quantity=0.0001&price=55000&stopPrice=49000&timestamp=...&signature=...'

#### JSON Request

    {
      "symbol": "BTCUSDT",
      "side": "SELL",
      "quantity": "0.0001",
      "price": "55000",
      "stopPrice": "49000",
      "stopLimitPrice": "48500",
      "stopLimitTimeInForce": "GTC",
      "timestamp": 1563417480525,
      "signature": "..."
    }

#### JSON Response

    {
      "orderListId": 0,
      "contingencyType": "OCO",
      "listStatusType": "EXEC_STARTED",
      "listOrderStatus": "EXECUTING",
      "listClientOrderId": "JYVpp3F0f5CAG15DhtrqLp",
      "transactTime": 1563417480525,
      "symbol": "BTCUSDT",
      "orders": [...],
      "orderReports": [...]
    }

#### Usage

    BinanceOcoOrders$add_oco_order(
      symbol,
      side,
      quantity,
      price,
      stop_price,
      stop_limit_price = NULL,
      stop_limit_time_in_force = NULL,
      list_client_order_id = NULL,
      limit_client_order_id = NULL,
      stop_client_order_id = NULL,
      limit_iceberg_qty = NULL,
      stop_iceberg_qty = NULL,
      new_order_resp_type = NULL,
      self_trade_prevention_mode = NULL,
      recv_window = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `side`:

  (scalar\<character\>) `"BUY"` or `"SELL"`.

- `quantity`:

  (scalar\<numeric\>) base asset quantity.

- `price`:

  (scalar\<numeric\>) price for the limit leg.

- `stop_price`:

  (scalar\<numeric\>) trigger price for the stop-loss leg.

- `stop_limit_price`:

  (scalar\<numeric\>?) limit price for the stop-loss-limit leg.

- `stop_limit_time_in_force`:

  (scalar\<character\>?) time-in-force for the stop-limit leg (`"GTC"`,
  `"IOC"`, `"FOK"`). Required if `stopLimitPrice` is provided.

- `list_client_order_id`:

  (scalar\<character\>?) unique ID for the entire OCO list.

- `limit_client_order_id`:

  (scalar\<character\>?) unique ID for the limit leg.

- `stop_client_order_id`:

  (scalar\<character\>?) unique ID for the stop-loss leg.

- `limit_iceberg_qty`:

  (scalar\<numeric\>?) iceberg quantity for the limit leg.

- `stop_iceberg_qty`:

  (scalar\<numeric\>?) iceberg quantity for the stop-loss leg.

- `new_order_resp_type`:

  (scalar\<character\>?) `"ACK"`, `"RESULT"`, or `"FULL"`.

- `self_trade_prevention_mode`:

  (scalar\<character\>?)

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per child order report
(long format):

- order_list_id (numeric) OCO order list identifier (repeated per child
  order).

- contingency_type (character) Always `"OCO"`.

- list_status_type (character) Status type (e.g., `"EXEC_STARTED"`).

- list_order_status (character) Order status (e.g., `"EXECUTING"`).

- list_client_order_id (character) Client-assigned list ID.

- transact_time (POSIXct) Transaction time.

- symbol (character) Trading pair from parent OCO.

- order_report_symbol (character) Trading pair from child order report.

- order_report_order_id (numeric) Child order ID.

- order_report_order_list_id (numeric) Child order's OCO list ID.

- order_report_client_order_id (character) Child order client ID.

- order_report_transact_time (POSIXct) Child order transaction time.

- order_report_price (character) Child order price.

- order_report_orig_qty (character) Child order original quantity.

- order_report_executed_qty (character) Child order executed quantity.

- order_report_cummulative_quote_qty (character) Child order cumulative
  quote quantity filled.

- order_report_status (character) Child order status (e.g., `"NEW"`).

- order_report_time_in_force (character) Child order time-in-force
  policy.

- order_report_type (character) Child order type (e.g.,
  `"STOP_LOSS_LIMIT"`, `"LIMIT_MAKER"`).

- order_report_side (character) Child order side.

- order_report_stop_price (character \| NA) Stop price (`NA` for the
  non-stop leg, e.g. the `LIMIT_MAKER` order).

- order_report_self_trade_prevention_mode (character)
  Self-trade-prevention mode.

#### Examples

    oco <- BinanceOcoOrders$new()
    result <- oco$add_oco_order(
      symbol = "BTCUSDT", side = "SELL",
      quantity = 0.0001, price = 55000, stop_price = 49000,
      stop_limit_price = 48500, stop_limit_time_in_force = "GTC"
    )
    print(result)

------------------------------------------------------------------------

### `BinanceOcoOrders$cancel_oco_order()`

Cancel an OCO Order

Cancels an entire OCO order list by order list ID or client order ID.

#### API Endpoint

`DELETE https://api.binance.com/api/v3/orderList`

#### Official Documentation

[Binance Cancel
OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints#order-lists)
Verified: 2026-05-22

#### curl

    curl -X DELETE 'https://api.binance.com/api/v3/orderList?symbol=BTCUSDT&orderListId=0&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "orderListId": 0,
      "contingencyType": "OCO",
      "listStatusType": "ALL_DONE",
      "listOrderStatus": "ALL_DONE",
      "listClientOrderId": "C3wyj4WVEktd7u9aVBRXcN",
      "transactTime": 1563417480525,
      "symbol": "BTCUSDT",
      "orders": [
        {
          "symbol": "BTCUSDT",
          "orderId": 12569099453,
          "clientOrderId": "bfYPSQdLoqAJeNrOr9adzq"
        },
        {
          "symbol": "BTCUSDT",
          "orderId": 12569099454,
          "clientOrderId": "0NPFMfBo6cMGlwnSfzBrdg"
        }
      ],
      "orderReports": [
        {
          "symbol": "BTCUSDT",
          "orderId": 12569099453,
          "orderListId": 0,
          "clientOrderId": "bfYPSQdLoqAJeNrOr9adzq",
          "transactTime": 1563417480525,
          "price": "55000.00000000",
          "origQty": "0.00010000",
          "executedQty": "0.00000000",
          "cummulativeQuoteQty": "0.00000000",
          "status": "CANCELED",
          "timeInForce": "GTC",
          "type": "LIMIT_MAKER",
          "side": "SELL"
        },
        {
          "symbol": "BTCUSDT",
          "orderId": 12569099454,
          "orderListId": 0,
          "clientOrderId": "0NPFMfBo6cMGlwnSfzBrdg",
          "transactTime": 1563417480525,
          "price": "48500.00000000",
          "origQty": "0.00010000",
          "executedQty": "0.00000000",
          "cummulativeQuoteQty": "0.00000000",
          "status": "CANCELED",
          "timeInForce": "GTC",
          "type": "STOP_LOSS_LIMIT",
          "side": "SELL",
          "stopPrice": "49000.00000000"
        }
      ]
    }

#### Usage

    BinanceOcoOrders$cancel_oco_order(
      symbol,
      order_list_id = NULL,
      list_client_order_id = NULL,
      recv_window = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTCUSDT"`).

- `order_list_id`:

  (scalar\<count\>?) the OCO order list ID.

- `list_client_order_id`:

  (scalar\<character\>?) the client order list ID.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per child order report
(long format), matching the shape returned by `add_oco_order()`. The
thinner `orders` array Binance returns is dropped in favour of the
richer `orderReports` payload, which includes the cancellation status,
prices, quantities, and stop price for each child order:

- order_list_id (numeric) OCO order list identifier (repeated per child
  order).

- contingency_type (character) Always `"OCO"`.

- list_status_type (character) Status type (e.g., `"ALL_DONE"`).

- list_order_status (character) Order status (e.g., `"ALL_DONE"`).

- list_client_order_id (character) Client-assigned list ID.

- transact_time (POSIXct) Cancellation time (if present).

- symbol (character) Trading pair from parent OCO.

- order_report_symbol (character) Trading pair from child order.

- order_report_order_id (numeric) Child order ID.

- order_report_order_list_id (numeric) Child order's OCO list ID.

- order_report_client_order_id (character) Child order client ID.

- order_report_transact_time (POSIXct) Child order transaction time.

- order_report_price (character) Child order price.

- order_report_orig_qty (character) Child order original quantity.

- order_report_executed_qty (character) Child order executed quantity.

- order_report_cummulative_quote_qty (character) Child order cumulative
  quote quantity filled.

- order_report_status (character) Child order status (e.g.,
  `"CANCELED"`).

- order_report_time_in_force (character) Child order time-in-force
  policy.

- order_report_type (character) Child order type.

- order_report_side (character) Child order side.

- order_report_stop_price (character \| NA) Stop price (`NA` for the
  non-stop leg).

- order_report_self_trade_prevention_mode (character)
  Self-trade-prevention mode.

#### Examples

    oco <- BinanceOcoOrders$new()
    cancelled <- oco$cancel_oco_order("BTCUSDT", order_list_id = 0)
    print(cancelled)

------------------------------------------------------------------------

### `BinanceOcoOrders$get_oco_order()`

Query an OCO Order

Retrieves details for a specific OCO order by order list ID or original
client order ID.

#### API Endpoint

`GET https://api.binance.com/api/v3/orderList`

#### Official Documentation

[Binance Query
OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-order-list-user_data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/orderList?orderListId=0&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "orderListId": 0,
      "contingencyType": "OCO",
      "listStatusType": "ALL_DONE",
      "listOrderStatus": "ALL_DONE",
      "listClientOrderId": "C3wyj4WVEktd7u9aVBRXcN",
      "transactionTime": 1563417480525,
      "symbol": "BTCUSDT",
      "orders": [
        {
          "symbol": "BTCUSDT",
          "orderId": 12569099453,
          "clientOrderId": "bfYPSQdLoqAJeNrOr9adzq"
        },
        {
          "symbol": "BTCUSDT",
          "orderId": 12569099454,
          "clientOrderId": "0NPFMfBo6cMGlwnSfzBrdg"
        }
      ]
    }

#### Usage

    BinanceOcoOrders$get_oco_order(
      order_list_id = NULL,
      orig_client_order_id = NULL,
      recv_window = NULL
    )

#### Arguments

- `order_list_id`:

  (scalar\<count\>?) the OCO order list ID.

- `orig_client_order_id`:

  (scalar\<character\>?) the original client order list ID.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per child order (long
format):

- order_list_id (numeric) OCO order list identifier (repeated per child
  order).

- contingency_type (character) Always `"OCO"`.

- list_status_type (character) Status type (e.g., `"ALL_DONE"`).

- list_order_status (character) Order status.

- list_client_order_id (character) Client-assigned list ID.

- transaction_time (POSIXct) Transaction time (if present).

- symbol (character) Trading pair from parent OCO.

- order_symbol (character) Trading pair from child order.

- order_order_id (numeric) Child order ID.

- order_client_order_id (character) Child order client ID.

#### Examples

    oco <- BinanceOcoOrders$new()
    order <- oco$get_oco_order(order_list_id = 0)
    print(order)

------------------------------------------------------------------------

### `BinanceOcoOrders$get_open_oco_orders()`

Get Open OCO Orders

Retrieves all currently open OCO order lists.

#### API Endpoint

`GET https://api.binance.com/api/v3/openOrderList`

#### Official Documentation

[Binance Query Open
OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-open-order-lists-user_data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/openOrderList?timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "orderListId": 31,
        "contingencyType": "OCO",
        "listStatusType": "EXEC_STARTED",
        "listOrderStatus": "EXECUTING",
        "listClientOrderId": "wuB13fmulKj3YjdqWEcsnp",
        "transactionTime": 1565246080644,
        "symbol": "LTCBTC",
        "orders": [
          {
            "symbol": "LTCBTC",
            "orderId": 4,
            "clientOrderId": "r3EH2N76dHfLoSZWIUw1bT"
          },
          {
            "symbol": "LTCBTC",
            "orderId": 5,
            "clientOrderId": "Cv1SnyPD3qhqpbjpYEHbd2"
          }
        ]
      }
    ]

#### Usage

    BinanceOcoOrders$get_open_oco_orders(recv_window = NULL)

#### Arguments

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per child order across all
open OCOs (long format; empty when there are no open OCOs):

- order_list_id (numeric) OCO order list identifier (repeated per child
  order).

- contingency_type (character) Always `"OCO"`.

- list_status_type (character) Status type.

- list_order_status (character) Order status.

- list_client_order_id (character) Client-assigned list ID.

- transaction_time (POSIXct) Transaction time.

- symbol (character) Trading pair from parent OCO.

- order_symbol (character) Trading pair from child order.

- order_order_id (numeric) Child order ID.

- order_client_order_id (character) Child order client ID.

#### Examples

    oco <- BinanceOcoOrders$new()
    open <- oco$get_open_oco_orders()
    print(open)

------------------------------------------------------------------------

### `BinanceOcoOrders$get_all_oco_orders()`

Get All OCO Orders

Retrieves all OCO order lists (open, cancelled, done). If `fromId` is
set, returns OCOs with order list ID \>= that value. Otherwise returns
the most recent OCOs.

#### API Endpoint

`GET https://api.binance.com/api/v3/allOrderList`

#### Official Documentation

[Binance Query All
OCO](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/account-endpoints#query-all-order-lists-user_data)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/api/v3/allOrderList?limit=50&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "orderListId": 29,
        "contingencyType": "OCO",
        "listStatusType": "EXEC_STARTED",
        "listOrderStatus": "EXECUTING",
        "listClientOrderId": "amEEAXryFzFwYF1FeRpUoZ",
        "transactionTime": 1565245913483,
        "symbol": "LTCBTC",
        "orders": [
          {
            "symbol": "LTCBTC",
            "orderId": 4,
            "clientOrderId": "oD7aesZqjEGlZrbtRpy5zB"
          },
          {
            "symbol": "LTCBTC",
            "orderId": 5,
            "clientOrderId": "Jr1h6xirOxgeJOUuYQS7V3"
          }
        ]
      },
      {
        "orderListId": 30,
        "contingencyType": "OCO",
        "listStatusType": "ALL_DONE",
        "listOrderStatus": "ALL_DONE",
        "listClientOrderId": "XbijSrMBk4cGLvoDYtU08w",
        "transactionTime": 1565245913847,
        "symbol": "BTCUSDT",
        "orders": [
          {
            "symbol": "BTCUSDT",
            "orderId": 8,
            "clientOrderId": "pO9ufTiFGg3ndn3Kq7BuSA"
          },
          {
            "symbol": "BTCUSDT",
            "orderId": 9,
            "clientOrderId": "TXOvglzXuaubXAaENpaRCB"
          }
        ]
      }
    ]

#### Usage

    BinanceOcoOrders$get_all_oco_orders(
      from_id = NULL,
      start_time = NULL,
      end_time = NULL,
      limit = NULL,
      recv_window = NULL
    )

#### Arguments

- `from_id`:

  (scalar\<count\>?) pagination cursor (orderListId).

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `limit`:

  (scalar\<count\>?) max results (default 500, max 1000).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per child order across all
OCOs (long format; empty when there are no matching OCOs):

- order_list_id (numeric) OCO order list identifier (repeated per child
  order).

- contingency_type (character) Always `"OCO"`.

- list_status_type (character) Status type.

- list_order_status (character) Order status.

- list_client_order_id (character) Client-assigned list ID.

- transaction_time (POSIXct) Transaction time.

- symbol (character) Trading pair from parent OCO.

- order_symbol (character) Trading pair from child order.

- order_order_id (numeric) Child order ID.

- order_client_order_id (character) Child order client ID.

#### Examples

    oco <- BinanceOcoOrders$new()
    all <- oco$get_all_oco_orders(limit = 50)
    print(all)

------------------------------------------------------------------------

### `BinanceOcoOrders$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceOcoOrders$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
oco <- BinanceOcoOrders$new()
result <- oco$add_oco_order(
  symbol = "BTCUSDT", side = "SELL",
  quantity = 0.0001, price = 55000, stop_price = 49000,
  stop_limit_price = 48500, stop_limit_time_in_force = "GTC"
)
print(result)

# Asynchronous
oco_async <- BinanceOcoOrders$new(async = TRUE)
main <- coro::async(function() {
  result <- await(oco_async$get_open_oco_orders())
  print(result)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceOcoOrders$add_oco_order()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
result <- oco$add_oco_order(
  symbol = "BTCUSDT", side = "SELL",
  quantity = 0.0001, price = 55000, stop_price = 49000,
  stop_limit_price = 48500, stop_limit_time_in_force = "GTC"
)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$cancel_oco_order()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
cancelled <- oco$cancel_oco_order("BTCUSDT", order_list_id = 0)
print(cancelled)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$get_oco_order()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
order <- oco$get_oco_order(order_list_id = 0)
print(order)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$get_open_oco_orders()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
open <- oco$get_open_oco_orders()
print(open)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$get_all_oco_orders()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
all <- oco$get_all_oco_orders(limit = 50)
print(all)
} # }
```
