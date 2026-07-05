# BinanceTransfer: Universal Transfer Management

BinanceTransfer: Universal Transfer Management

BinanceTransfer: Universal Transfer Management

## Details

Provides methods for initiating and querying universal transfers between
wallet types on Binance. Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **Transfer Initiation**: Move assets between spot, margin, futures,
  and funding wallets using the universal transfer endpoint.

- **Transfer History**: Query transfer records with pagination support.

### Usage

All methods require authentication (valid API key and secret). These are
wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.

### Official Documentation

[Binance Universal
Transfer](https://developers.binance.com/docs/wallet/asset/user-universal-transfer)

### Endpoints Covered

|                      |                              |      |
|----------------------|------------------------------|------|
| Method               | Endpoint                     | HTTP |
| add_transfer         | POST /sapi/v1/asset/transfer | POST |
| get_transfer_history | GET /sapi/v1/asset/transfer  | GET  |

### Transfer Types

- `MAIN_UMFUTURE`: Spot to USDM Futures

- `MAIN_CMFUTURE`: Spot to COINM Futures

- `MAIN_MARGIN`: Spot to Cross Margin

- `UMFUTURE_MAIN`: USDM Futures to Spot

- `UMFUTURE_MARGIN`: USDM Futures to Cross Margin

- `CMFUTURE_MAIN`: COINM Futures to Spot

- `MARGIN_MAIN`: Cross Margin to Spot

- `MARGIN_UMFUTURE`: Cross Margin to USDM Futures

- `MAIN_FUNDING`: Spot to Funding

- `FUNDING_MAIN`: Funding to Spot

- `FUNDING_UMFUTURE`: Funding to USDM Futures

- `UMFUTURE_FUNDING`: USDM Futures to Funding

- `MARGIN_FUNDING`: Cross Margin to Funding

- `FUNDING_MARGIN`: Funding to Cross Margin

- `FUNDING_CMFUTURE`: Funding to COINM Futures

- `CMFUTURE_FUNDING`: COINM Futures to Funding

- `MAIN_ISOLATED_MARGIN`: Spot to Isolated Margin

- `ISOLATED_MARGIN_MAIN`: Isolated Margin to Spot

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`binance::BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceTransfer`

## Methods

### Public methods

- [`BinanceTransfer$add_transfer()`](#method-BinanceTransfer-add_transfer)

- [`BinanceTransfer$get_transfer_history()`](#method-BinanceTransfer-get_transfer_history)

- [`BinanceTransfer$clone()`](#method-BinanceTransfer-clone)

Inherited methods

- [`binance::BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_transfer()`

Initiate a Universal Transfer

Transfers assets between wallet types (spot, margin, futures, funding).

#### API Endpoint

`POST https://api.binance.com/sapi/v1/asset/transfer`

#### Official Documentation

[Binance Universal
Transfer](https://developers.binance.com/docs/wallet/asset/user-universal-transfer)
Verified: 2026-05-22

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/asset/transfer' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'type=MAIN_UMFUTURE&asset=USDT&amount=100&timestamp=1661493146000&signature=...'

#### JSON Request

    {
      "type": "MAIN_UMFUTURE",
      "asset": "USDT",
      "amount": "100",
      "timestamp": 1661493146000,
      "signature": "..."
    }

#### JSON Response

    {
      "tranId": 13526853623
    }

#### Usage

    BinanceTransfer$add_transfer(
      type,
      asset,
      amount,
      from_symbol = NULL,
      to_symbol = NULL,
      recv_window = NULL
    )

#### Arguments

- `type`:

  (scalar\<character\>) transfer type. One of `"MAIN_UMFUTURE"`,
  `"MAIN_CMFUTURE"`, `"MAIN_MARGIN"`, `"UMFUTURE_MAIN"`,
  `"UMFUTURE_MARGIN"`, `"CMFUTURE_MAIN"`, `"MARGIN_MAIN"`,
  `"MARGIN_UMFUTURE"`, `"MAIN_FUNDING"`, `"FUNDING_MAIN"`,
  `"FUNDING_UMFUTURE"`, `"UMFUTURE_FUNDING"`, `"MARGIN_FUNDING"`,
  `"FUNDING_MARGIN"`, `"FUNDING_CMFUTURE"`, `"CMFUTURE_FUNDING"`,
  `"MAIN_ISOLATED_MARGIN"`, `"ISOLATED_MARGIN_MAIN"`.

- `asset`:

  (scalar\<character\>) asset to transfer (e.g., `"USDT"`).

- `amount`:

  (scalar\<numeric\>) amount to transfer.

- `from_symbol`:

  (scalar\<character\>?) mandatory when `type` involves isolated margin
  (e.g., `"BNBUSDT"`).

- `to_symbol`:

  (scalar\<character\>?) mandatory when `type` involves isolated margin
  (e.g., `"BNBUSDT"`).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- tran_id (numeric) Unique transfer identifier assigned by Binance.

#### Examples

    \dontrun{
    transfer <- BinanceTransfer$new()
    result <- transfer$add_transfer(
      type = "MAIN_UMFUTURE", asset = "USDT", amount = 100
    )
    print(result)
    }

------------------------------------------------------------------------

### Method `get_transfer_history()`

Query Universal Transfer History

Retrieves transfer history for a given transfer type, with optional time
range and pagination.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/asset/transfer`

#### Official Documentation

[Binance Universal
Transfer](https://developers.binance.com/docs/wallet/asset/query-user-universal-transfer)
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/asset/transfer?type=MAIN_UMFUTURE&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 2,
      "rows": [
        {
          "asset": "USDT",
          "amount": "100.00000000",
          "type": "MAIN_UMFUTURE",
          "status": "CONFIRMED",
          "tranId": 13526853623,
          "timestamp": 1661493146000
        }
      ]
    }

#### Usage

    BinanceTransfer$get_transfer_history(
      type,
      start_time = NULL,
      end_time = NULL,
      current = NULL,
      size = NULL,
      from_symbol = NULL,
      to_symbol = NULL,
      recv_window = NULL
    )

#### Arguments

- `type`:

  (scalar\<character\>) transfer type. Same options as `add_transfer()`.

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `from_symbol`:

  (scalar\<character\>?) must be sent when `type` involves isolated
  margin.

- `to_symbol`:

  (scalar\<character\>?) must be sent when `type` involves isolated
  margin.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per transfer (empty when
there are no matching transfers):

- asset (character) Transferred asset (e.g., `"USDT"`).

- amount (character) Amount transferred.

- type (character) Transfer type (e.g., `"MAIN_UMFUTURE"`).

- status (character) Transfer status (`"CONFIRMED"`, `"FAILED"`,
  `"PENDING"`).

- tran_id (numeric) Unique transfer identifier.

- timestamp (POSIXct) Transfer time converted from milliseconds.

#### Examples

    \dontrun{
    transfer <- BinanceTransfer$new()
    history <- transfer$get_transfer_history(type = "MAIN_UMFUTURE")
    print(history)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceTransfer$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
transfer <- BinanceTransfer$new()
result <- transfer$add_transfer(
  type = "MAIN_UMFUTURE", asset = "USDT", amount = 100
)
print(result)

# Asynchronous
transfer_async <- BinanceTransfer$new(async = TRUE)
main <- coro::async(function() {
  result <- await(transfer_async$add_transfer(
    type = "MAIN_UMFUTURE", asset = "USDT", amount = 100
  ))
  print(result)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceTransfer$add_transfer`
## ------------------------------------------------

if (FALSE) { # \dontrun{
transfer <- BinanceTransfer$new()
result <- transfer$add_transfer(
  type = "MAIN_UMFUTURE", asset = "USDT", amount = 100
)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceTransfer$get_transfer_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
transfer <- BinanceTransfer$new()
history <- transfer$get_transfer_history(type = "MAIN_UMFUTURE")
print(history)
} # }
```
