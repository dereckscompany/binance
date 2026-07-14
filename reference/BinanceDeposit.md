# BinanceDeposit: Deposit Management

Provides methods for retrieving deposit addresses and deposit history on
Binance. Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **Deposit Address**: Retrieve deposit addresses for any supported coin
  and network.

- **Deposit History**: Query deposit transaction records with status
  tracking, timestamps, and on-chain transaction IDs.

### Usage

All methods require authentication (valid API key and secret). These are
wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.

### Official Documentation

[Binance Deposit
Endpoints](https://developers.binance.com/docs/wallet/capital)

### Endpoints Covered

|                     |                                      |      |
|---------------------|--------------------------------------|------|
| Method              | Endpoint                             | HTTP |
| get_deposit_address | GET /sapi/v1/capital/deposit/address | GET  |
| get_deposit_history | GET /sapi/v1/capital/deposit/hisrec  | GET  |

## Deposit Status Codes

- `0`: Pending

- `1`: Success (confirmed and credited)

- `6`: Credited but cannot withdraw

- `7`: Wrong deposit

- `8`: Waiting user confirm

## Super classes

[`connectcore::RestClient`](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
-\>
[`BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceDeposit`

## Methods

### Public methods

- [`BinanceDeposit$get_deposit_address()`](#method-BinanceDeposit-get_deposit_address)

- [`BinanceDeposit$get_deposit_history()`](#method-BinanceDeposit-get_deposit_history)

- [`BinanceDeposit$clone()`](#method-BinanceDeposit-clone)

Inherited methods

- [`BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### `BinanceDeposit$get_deposit_address()`

Get Deposit Address

Retrieves the deposit address for a specific coin. If `network` is not
specified, returns the address for the coin's default network.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/capital/deposit/address`

#### Official Documentation

[Binance Deposit
Address](https://developers.binance.com/docs/wallet/capital/deposite-address)
Verified: 2026-05-22

#### Automated Trading Usage

- **Address Lookup**: Retrieve deposit addresses to share with external
  systems or users.

- **Multi-Network Support**: Specify `network` (e.g., `"ETH"`, `"TRX"`,
  `"BSC"`) to get the address on the correct chain.

- **Pre-Flight Check**: Verify the deposit address exists before
  initiating an external transfer.

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/capital/deposit/address?coin=BTC&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "address": "1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv",
      "coin": "BTC",
      "tag": "",
      "url": "https://btc.com/1HPn8Rx2y6nNSfagQBKy27GB99Vbzg89wv"
    }

#### Usage

    BinanceDeposit$get_deposit_address(coin, network = NULL, recv_window = NULL)

#### Arguments

- `coin`:

  (scalar\<character\>) coin symbol (e.g., `"BTC"`, `"ETH"`, `"USDT"`).

- `network`:

  (scalar\<character\>?) blockchain network (e.g., `"ETH"`, `"TRX"`,
  `"BSC"`). If NULL, uses the coin's default network.

- `recv_window`:

  (scalar\<count in \[1, Inf\[\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- address (character) the deposit wallet address.

- coin (character) coin symbol (e.g., `"BTC"`).

- tag (character) address tag/memo (empty string if not applicable).

- url (character) blockchain explorer URL for the address.

#### Examples

    deposit <- BinanceDeposit$new()

    # Get BTC deposit address (default network)
    btc <- deposit$get_deposit_address(coin = "BTC")
    print(btc$address)

    # Get USDT deposit address on TRC20
    usdt <- deposit$get_deposit_address(coin = "USDT", network = "TRX")
    print(usdt[, .(address, coin, tag)])

------------------------------------------------------------------------

### `BinanceDeposit$get_deposit_history()`

Get Deposit History

Retrieves deposit transaction history with optional filtering by coin,
status, and time range. Converts `insertTime` timestamps to POSIXct.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/capital/deposit/hisrec`

#### Official Documentation

[Binance Deposit
History](https://developers.binance.com/docs/wallet/capital/deposite-history)
Verified: 2026-05-22

#### Automated Trading Usage

- **Deposit Monitoring**: Poll for status `1` (success) deposits to
  trigger trading logic when funds arrive.

- **Reconciliation**: Match `tx_id` against on-chain transaction hashes
  for audit.

- **Time-Windowed Queries**: Use `startTime`/`endTime` to retrieve
  deposits within a specific period. Max range is 90 days.

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/capital/deposit/hisrec?coin=BTC&status=1&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "id": "769800519366885376",
        "amount": "0.001",
        "coin": "BNB",
        "network": "BNB",
        "status": 1,
        "address": "bnb136ns6lfw4zs5hg4n85vdthaad7hq5m4gtkgf23",
        "addressTag": "101764890",
        "txId": "98A3EA560C6B3336D348B6C83F0F95ECE4F1F5919E94BD006E5BF3BF264FACFC",
        "insertTime": 1661493146000,
        "completeTime": 1661493146000,
        "transferType": 0,
        "confirmTimes": "1/1",
        "unlockConfirm": 0,
        "walletType": 0
      }
    ]

#### Usage

    BinanceDeposit$get_deposit_history(
      coin = NULL,
      status = NULL,
      start_time = NULL,
      end_time = NULL,
      offset = NULL,
      limit = NULL,
      tx_id = NULL,
      recv_window = NULL
    )

#### Arguments

- `coin`:

  (scalar\<character\>?) filter by coin (e.g., `"BTC"`, `"USDT"`).

- `status`:

  (scalar\<count\>?) filter by status: `0` (pending), `1` (success), `6`
  (credited), `7` (wrong), `8` (waiting confirm).

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `offset`:

  (scalar\<count\>?) pagination offset (default 0).

- `limit`:

  (scalar\<count\>?) max results (default 1000, max 1000).

- `tx_id`:

  (scalar\<character\>?) filter by transaction ID.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per deposit (empty when
there are no matching deposits):

- id (character) unique deposit identifier.

- amount (character) deposit amount.

- coin (character) deposited coin symbol.

- network (character) blockchain network used.

- status (integer) deposit status code (0=pending, 1=success,
  6=credited).

- address (character) deposit address.

- address_tag (character) address tag/memo.

- tx_id (character) on-chain transaction hash.

- transfer_type (integer) 0=external, 1=internal.

- confirm_times (character) confirmation progress (e.g., `"1/1"`).

- unlock_confirm (integer) confirmations needed to unlock.

- wallet_type (integer) 0=spot, 1=funding.

- insert_time (POSIXct) deposit time converted from `insertTime`.

- complete_time (POSIXct) completion time converted from `completeTime`.

#### Examples

    deposit <- BinanceDeposit$new()

    # Get all successful BTC deposits
    history <- deposit$get_deposit_history(coin = "BTC", status = 1)
    print(history[, .(amount, coin, status, insert_time)])

    # Get deposits from the last 24 hours
    now_ms <- as.integer(as.numeric(Sys.time()) * 1000)
    recent <- deposit$get_deposit_history(
      start_time = now_ms - 86400000L,
      end_time = now_ms
    )

------------------------------------------------------------------------

### `BinanceDeposit$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceDeposit$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
deposit <- BinanceDeposit$new()
addr <- deposit$get_deposit_address(coin = "BTC")
print(addr)

# Asynchronous
deposit_async <- BinanceDeposit$new(async = TRUE)
main <- coro::async(function() {
  addr <- await(deposit_async$get_deposit_address(coin = "BTC"))
  print(addr)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceDeposit$get_deposit_address()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
deposit <- BinanceDeposit$new()

# Get BTC deposit address (default network)
btc <- deposit$get_deposit_address(coin = "BTC")
print(btc$address)

# Get USDT deposit address on TRC20
usdt <- deposit$get_deposit_address(coin = "USDT", network = "TRX")
print(usdt[, .(address, coin, tag)])
} # }

## ------------------------------------------------
## Method `BinanceDeposit$get_deposit_history()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
deposit <- BinanceDeposit$new()

# Get all successful BTC deposits
history <- deposit$get_deposit_history(coin = "BTC", status = 1)
print(history[, .(amount, coin, status, insert_time)])

# Get deposits from the last 24 hours
now_ms <- as.integer(as.numeric(Sys.time()) * 1000)
recent <- deposit$get_deposit_history(
  start_time = now_ms - 86400000L,
  end_time = now_ms
)
} # }
```
