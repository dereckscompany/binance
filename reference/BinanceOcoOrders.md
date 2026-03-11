# BinanceOcoOrders: OCO Order Management

BinanceOcoOrders: OCO Order Management

BinanceOcoOrders: OCO Order Management

## Details

Provides methods for placing, cancelling, and querying OCO
(One-Cancels-Other) orders on Binance. Inherits from
[BinanceBase](https://dereckmezquita.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **OCO Placement**: Place OCO orders combining a limit and a stop-loss.

- **OCO Cancellation**: Cancel an entire OCO order list by ID.

- **OCO Queries**: Retrieve a specific OCO, all open OCOs, or historical
  OCOs.

### Usage

All methods require authentication (valid API key and secret).

### Official Documentation

[Binance Spot
Trading](https://binance-docs.github.io/apidocs/spot/en/#spot-account-trade)

### Endpoints Covered

|                     |                           |        |
|---------------------|---------------------------|--------|
| Method              | Endpoint                  | HTTP   |
| add_oco_order       | POST /api/v3/order/oco    | POST   |
| cancel_oco_order    | DELETE /api/v3/orderList  | DELETE |
| get_oco_order       | GET /api/v3/orderList     | GET    |
| get_open_oco_orders | GET /api/v3/openOrderList | GET    |
| get_all_oco_orders  | GET /api/v3/allOrderList  | GET    |

## Super class

[`binance::BinanceBase`](https://dereckmezquita.github.io/binance/reference/BinanceBase.md)
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

- [`binance::BinanceBase$initialize()`](https://dereckmezquita.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_oco_order()`

Place an OCO Order

Places a new OCO (One-Cancels-Other) order on Binance. An OCO combines a
limit order and a stop-loss (or stop-loss-limit) order.

#### API Endpoint

`POST https://api.binance.com/api/v3/order/oco`

#### Official Documentation

[Binance New
OCO](https://binance-docs.github.io/apidocs/spot/en/#new-oco-trade)
Verified: 2026-03-10

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
      stopPrice,
      stopLimitPrice = NULL,
      stopLimitTimeInForce = NULL,
      listClientOrderId = NULL,
      limitClientOrderId = NULL,
      stopClientOrderId = NULL,
      limitIcebergQty = NULL,
      stopIcebergQty = NULL,
      newOrderRespType = NULL,
      selfTradePreventionMode = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `side`:

  Character; `"BUY"` or `"SELL"`.

- `quantity`:

  Numeric; base asset quantity.

- `price`:

  Numeric; price for the limit leg.

- `stopPrice`:

  Numeric; trigger price for the stop-loss leg.

- `stopLimitPrice`:

  Numeric or NULL; limit price for the stop-loss-limit leg.

- `stopLimitTimeInForce`:

  Character or NULL; time-in-force for the stop-limit leg (`"GTC"`,
  `"IOC"`, `"FOK"`). Required if `stopLimitPrice` is provided.

- `listClientOrderId`:

  Character or NULL; unique ID for the entire OCO list.

- `limitClientOrderId`:

  Character or NULL; unique ID for the limit leg.

- `stopClientOrderId`:

  Character or NULL; unique ID for the stop-loss leg.

- `limitIcebergQty`:

  Numeric or NULL; iceberg quantity for the limit leg.

- `stopIcebergQty`:

  Numeric or NULL; iceberg quantity for the stop-loss leg.

- `newOrderRespType`:

  Character or NULL; `"ACK"`, `"RESULT"`, or `"FULL"`.

- `selfTradePreventionMode`:

  Character or NULL.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per child order (long format) and the
following columns:

- `order_list_id` (integer): OCO order list identifier (repeated per
  child order).

- `contingency_type` (character): Always `"OCO"`.

- `list_status_type` (character): Status type (e.g., `"EXEC_STARTED"`).

- `list_order_status` (character): Order status (e.g., `"EXECUTING"`).

- `list_client_order_id` (character): Client-assigned list ID.

- `transact_time` (POSIXct): Transaction time.

- `symbol` (character): Trading pair from parent OCO.

- `order_symbol` (character): Trading pair from child order.

- `order_id` (integer): Child order ID.

- `client_order_id` (character): Child order client ID.

- `order_reports` (list): List of order report objects (kept as
  list-column).

#### Examples

    \dontrun{
    oco <- BinanceOcoOrders$new()
    result <- oco$add_oco_order(
      symbol = "BTCUSDT", side = "SELL",
      quantity = 0.0001, price = 55000, stopPrice = 49000,
      stopLimitPrice = 48500, stopLimitTimeInForce = "GTC"
    )
    print(result)
    }

------------------------------------------------------------------------

### Method `cancel_oco_order()`

Cancel an OCO Order

Cancels an entire OCO order list by order list ID or client order ID.

#### API Endpoint

`DELETE https://api.binance.com/api/v3/orderList`

#### Official Documentation

[Binance Cancel
OCO](https://binance-docs.github.io/apidocs/spot/en/#cancel-oco-trade)
Verified: 2026-03-10

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
      orderListId = NULL,
      listClientOrderId = NULL,
      recvWindow = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTCUSDT"`).

- `orderListId`:

  Integer or NULL; the OCO order list ID.

- `listClientOrderId`:

  Character or NULL; the client order list ID.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per child order (long format) and the
following columns:

- `order_list_id` (integer): OCO order list identifier (repeated per
  child order).

- `contingency_type` (character): Always `"OCO"`.

- `list_status_type` (character): Status type (e.g., `"ALL_DONE"`).

- `list_order_status` (character): Order status (e.g., `"ALL_DONE"`).

- `list_client_order_id` (character): Client-assigned list ID.

- `transact_time` (POSIXct): Cancellation time (if present).

- `symbol` (character): Trading pair from parent OCO.

- `order_symbol` (character): Trading pair from child order.

- `order_id` (integer): Child order ID.

- `client_order_id` (character): Child order client ID.

#### Examples

    \dontrun{
    oco <- BinanceOcoOrders$new()
    cancelled <- oco$cancel_oco_order("BTCUSDT", orderListId = 0)
    print(cancelled)
    }

------------------------------------------------------------------------

### Method `get_oco_order()`

Query an OCO Order

Retrieves details for a specific OCO order by order list ID or original
client order ID.

#### API Endpoint

`GET https://api.binance.com/api/v3/orderList`

#### Official Documentation

[Binance Query
OCO](https://binance-docs.github.io/apidocs/spot/en/#query-oco-user_data)
Verified: 2026-03-10

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
      orderListId = NULL,
      origClientOrderId = NULL,
      recvWindow = NULL
    )

#### Arguments

- `orderListId`:

  Integer or NULL; the OCO order list ID.

- `origClientOrderId`:

  Character or NULL; the original client order list ID.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per child order (long format) and the
following columns:

- `order_list_id` (integer): OCO order list identifier (repeated per
  child order).

- `contingency_type` (character): Always `"OCO"`.

- `list_status_type` (character): Status type (e.g., `"ALL_DONE"`).

- `list_order_status` (character): Order status.

- `list_client_order_id` (character): Client-assigned list ID.

- `transaction_time` (POSIXct): Transaction time (if present).

- `symbol` (character): Trading pair from parent OCO.

- `order_symbol` (character): Trading pair from child order.

- `order_id` (integer): Child order ID.

- `client_order_id` (character): Child order client ID.

#### Examples

    \dontrun{
    oco <- BinanceOcoOrders$new()
    order <- oco$get_oco_order(orderListId = 0)
    print(order)
    }

------------------------------------------------------------------------

### Method `get_open_oco_orders()`

Get Open OCO Orders

Retrieves all currently open OCO order lists.

#### API Endpoint

`GET https://api.binance.com/api/v3/openOrderList`

#### Official Documentation

[Binance Query Open
OCO](https://binance-docs.github.io/apidocs/spot/en/#query-open-oco-user_data)
Verified: 2026-03-10

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

    BinanceOcoOrders$get_open_oco_orders(recvWindow = NULL)

#### Arguments

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per child order across all open OCOs (long
format). Columns include:

- `order_list_id` (integer): OCO order list identifier (repeated per
  child order).

- `contingency_type` (character): Always `"OCO"`.

- `list_status_type` (character): Status type.

- `list_order_status` (character): Order status.

- `list_client_order_id` (character): Client-assigned list ID.

- `transaction_time` (POSIXct): Transaction time.

- `symbol` (character): Trading pair from parent OCO.

- `order_symbol` (character): Trading pair from child order.

- `order_id` (integer): Child order ID.

- `client_order_id` (character): Child order client ID.

#### Examples

    \dontrun{
    oco <- BinanceOcoOrders$new()
    open <- oco$get_open_oco_orders()
    print(open)
    }

------------------------------------------------------------------------

### Method `get_all_oco_orders()`

Get All OCO Orders

Retrieves all OCO order lists (open, cancelled, done). If `fromId` is
set, returns OCOs with order list ID \>= that value. Otherwise returns
the most recent OCOs.

#### API Endpoint

`GET https://api.binance.com/api/v3/allOrderList`

#### Official Documentation

[Binance Query All
OCO](https://binance-docs.github.io/apidocs/spot/en/#query-all-oco-user_data)
Verified: 2026-03-10

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
      fromId = NULL,
      startTime = NULL,
      endTime = NULL,
      limit = NULL,
      recvWindow = NULL
    )

#### Arguments

- `fromId`:

  Integer or NULL; pagination cursor (orderListId).

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `limit`:

  Integer or NULL; max results (default 500, max 1000).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per child order across all OCOs (long format).
Columns include:

- `order_list_id` (integer): OCO order list identifier (repeated per
  child order).

- `contingency_type` (character): Always `"OCO"`.

- `list_status_type` (character): Status type.

- `list_order_status` (character): Order status.

- `list_client_order_id` (character): Client-assigned list ID.

- `transaction_time` (POSIXct): Transaction time.

- `symbol` (character): Trading pair from parent OCO.

- `order_symbol` (character): Trading pair from child order.

- `order_id` (integer): Child order ID.

- `client_order_id` (character): Child order client ID.

#### Examples

    \dontrun{
    oco <- BinanceOcoOrders$new()
    all <- oco$get_all_oco_orders(limit = 50)
    print(all)
    }

------------------------------------------------------------------------

### Method `clone()`

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
  quantity = 0.0001, price = 55000, stopPrice = 49000,
  stopLimitPrice = 48500, stopLimitTimeInForce = "GTC"
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
## Method `BinanceOcoOrders$add_oco_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
result <- oco$add_oco_order(
  symbol = "BTCUSDT", side = "SELL",
  quantity = 0.0001, price = 55000, stopPrice = 49000,
  stopLimitPrice = 48500, stopLimitTimeInForce = "GTC"
)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$cancel_oco_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
cancelled <- oco$cancel_oco_order("BTCUSDT", orderListId = 0)
print(cancelled)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$get_oco_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
order <- oco$get_oco_order(orderListId = 0)
print(order)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$get_open_oco_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
open <- oco$get_open_oco_orders()
print(open)
} # }

## ------------------------------------------------
## Method `BinanceOcoOrders$get_all_oco_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- BinanceOcoOrders$new()
all <- oco$get_all_oco_orders(limit = 50)
print(all)
} # }
```
