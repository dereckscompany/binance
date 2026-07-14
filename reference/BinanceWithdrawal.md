# BinanceWithdrawal: Withdrawal Management

Provides methods for submitting withdrawals and querying withdrawal
history on Binance. Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **Withdrawal Submission**: Initiate withdrawals to external addresses.

- **Withdrawal History**: Retrieve paginated withdrawal records with
  status tracking.

### Usage

All methods require authentication (valid API key and secret). The API
key must have **Withdrawal** permission for `add_withdrawal()`. These
are wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.

### Official Documentation

[Binance Withdrawal
Endpoints](https://developers.binance.com/docs/wallet/capital)

### Endpoints Covered

|                        |                                       |      |
|------------------------|---------------------------------------|------|
| Method                 | Endpoint                              | HTTP |
| add_withdrawal         | POST /sapi/v1/capital/withdraw/apply  | POST |
| get_withdrawal_history | GET /sapi/v1/capital/withdraw/history | GET  |

## Withdrawal Status Codes

- `0`: Email Sent

- `1`: Cancelled

- `2`: Awaiting Approval

- `3`: Rejected

- `4`: Processing

- `5`: Failure

- `6`: Completed

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
-\> `BinanceWithdrawal`

## Methods

### Public methods

- [`BinanceWithdrawal$add_withdrawal()`](#method-BinanceWithdrawal-add_withdrawal)

- [`BinanceWithdrawal$get_withdrawal_history()`](#method-BinanceWithdrawal-get_withdrawal_history)

- [`BinanceWithdrawal$clone()`](#method-BinanceWithdrawal-clone)

Inherited methods

- [`BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### `BinanceWithdrawal$add_withdrawal()`

Submit Withdrawal

Initiates a withdrawal request. The API key must have Withdrawal
permission enabled. Returns a withdrawal ID on success.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/capital/withdraw/apply`

#### Official Documentation

[Binance
Withdraw](https://developers.binance.com/docs/wallet/capital/withdraw)
Verified: 2026-05-22

#### Automated Trading Usage

- **Profit Extraction**: Withdraw profits to a cold wallet at regular
  intervals.

- **Multi-Network Support**: Specify `network` (e.g., `"ETH"`, `"TRX"`,
  `"BSC"`) to select the cheapest or fastest network.

- **Wallet Selection**: Use `walletType` to withdraw from spot (0) or
  funding (1) wallet.

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/capital/withdraw/apply' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'coin=USDT&address=TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8&amount=10&network=TRX&timestamp=...&signature=...'

#### JSON Request

    {
      "coin": "USDT",
      "address": "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
      "amount": "10",
      "network": "TRX",
      "timestamp": 1661493146000,
      "signature": "..."
    }

#### JSON Response

    { "id": "7213fea8e94b4a5593d507237e5a555b" }

#### Usage

    BinanceWithdrawal$add_withdrawal(
      coin,
      address,
      amount,
      network = NULL,
      withdraw_order_id = NULL,
      address_tag = NULL,
      transaction_fee_flag = NULL,
      name = NULL,
      wallet_type = NULL,
      recv_window = NULL
    )

#### Arguments

- `coin`:

  (scalar\<character\>) coin symbol (e.g., `"BTC"`, `"USDT"`).

- `address`:

  (scalar\<character\>) destination wallet address.

- `amount`:

  (scalar\<numeric\> \| scalar\<character\>) withdrawal amount.

- `network`:

  (scalar\<character\>?) blockchain network (e.g., `"ETH"`, `"TRX"`,
  `"BSC"`). If NULL, uses the coin's default network.

- `withdraw_order_id`:

  (scalar\<character\>?) client-side withdrawal ID for tracking.

- `address_tag`:

  (scalar\<character\>?) secondary address identifier (required for
  coins like XRP, XMR, XLM).

- `transaction_fee_flag`:

  (scalar\<logical\>?) for internal transfers: `TRUE` returns fee to
  destination, `FALSE` to origin.

- `name`:

  (scalar\<character\>?) description for the address (max 200 entries in
  address book).

- `wallet_type`:

  (scalar\<count\>?) `0` for spot wallet, `1` for funding wallet.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- id (character) Unique withdrawal identifier assigned by Binance.

#### Examples

    withdrawal <- BinanceWithdrawal$new()

    # Withdraw USDT via TRC20
    result <- withdrawal$add_withdrawal(
      coin = "USDT",
      address = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
      amount = 10,
      network = "TRX"
    )
    print(result$id)

------------------------------------------------------------------------

### `BinanceWithdrawal$get_withdrawal_history()`

Get Withdrawal History

Retrieves withdrawal transaction history with optional filtering by
coin, status, and time range. Max time range is 90 days.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/capital/withdraw/history`

#### Official Documentation

[Binance Withdraw
History](https://developers.binance.com/docs/wallet/capital/withdraw-history)
Verified: 2026-05-22

#### Automated Trading Usage

- **Withdrawal Monitoring**: Poll for status `6` (completed) to confirm
  funds have left the exchange.

- **Reconciliation**: Match `tx_id` against on-chain transaction hashes
  for audit.

- **Failure Diagnosis**: Check `info` field for error details on failed
  withdrawals.

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/capital/withdraw/history?coin=USDT&status=6&timestamp=...&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    [
      {
        "id": "b6ae22b3aa844210a7041aee7589627c",
        "amount": "8.91000000",
        "transactionFee": "0.004",
        "coin": "USDT",
        "status": 6,
        "address": "0x94df8b352de7f46f64b01d3666bf6e936e44ce60",
        "txId": "0xb5ef8c13b968a406cc62a93a8bd80f9e9a906ef1b3fcf20a2e48573c17659268",
        "applyTime": "2019-10-12 11:12:02",
        "network": "ETH",
        "transferType": 0,
        "withdrawOrderId": "WITHDRAWtest123",
        "info": "",
        "confirmNo": 3,
        "walletType": 1,
        "txKey": "",
        "completeTime": "2023-03-23 16:52:41"
      }
    ]

#### Usage

    BinanceWithdrawal$get_withdrawal_history(
      coin = NULL,
      withdraw_order_id = NULL,
      status = NULL,
      start_time = NULL,
      end_time = NULL,
      offset = NULL,
      limit = NULL,
      recv_window = NULL
    )

#### Arguments

- `coin`:

  (scalar\<character\>?) filter by coin (e.g., `"BTC"`, `"USDT"`).

- `withdraw_order_id`:

  (scalar\<character\>?) filter by client-side withdrawal ID.

- `status`:

  (scalar\<count\>?) filter by status: `0` (email sent), `1`
  (cancelled), `2` (awaiting approval), `3` (rejected), `4`
  (processing), `5` (failure), `6` (completed).

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `offset`:

  (scalar\<count\>?) pagination offset (default 0).

- `limit`:

  (scalar\<count\>?) max results (default 1000, max 1000).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per withdrawal (empty when
there are no matching withdrawals):

- id (character) Unique withdrawal identifier.

- amount (character) Withdrawal amount.

- transaction_fee (character) Fee charged for the withdrawal.

- coin (character) Withdrawn coin symbol.

- status (integer) Withdrawal status code (0-6).

- address (character) Destination address.

- tx_id (character) On-chain transaction hash.

- apply_time (POSIXct) Time the withdrawal was submitted (parsed from
  the UTC string Binance returns).

- network (character) Blockchain network used.

- transfer_type (integer) 0=external, 1=internal.

- withdraw_order_id (character) Client-side withdrawal ID.

- info (character) Additional info or error message.

- confirm_no (integer) Number of on-chain confirmations.

- wallet_type (integer) 0=spot, 1=funding.

- tx_key (character) Transaction key.

- complete_time (POSIXct \| NA) Completion time (parsed from the UTC
  string Binance returns; `NA` for in-progress withdrawals, which
  Binance sends as an empty string).

#### Examples

    withdrawal <- BinanceWithdrawal$new()

    # Get all completed USDT withdrawals
    history <- withdrawal$get_withdrawal_history(coin = "USDT", status = 6)
    print(history[, .(amount, coin, status, address, apply_time)])

    # Get withdrawals from the last 7 days
    now_ms <- as.integer(as.numeric(Sys.time()) * 1000)
    recent <- withdrawal$get_withdrawal_history(
      start_time = now_ms - 7 * 86400000L,
      end_time = now_ms
    )

------------------------------------------------------------------------

### `BinanceWithdrawal$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceWithdrawal$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
withdrawal <- BinanceWithdrawal$new()
history <- withdrawal$get_withdrawal_history(coin = "USDT")
print(history)

# Asynchronous
withdrawal_async <- BinanceWithdrawal$new(async = TRUE)
main <- coro::async(function() {
  history <- await(withdrawal_async$get_withdrawal_history(coin = "BTC"))
  print(history)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceWithdrawal$add_withdrawal()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- BinanceWithdrawal$new()

# Withdraw USDT via TRC20
result <- withdrawal$add_withdrawal(
  coin = "USDT",
  address = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
  amount = 10,
  network = "TRX"
)
print(result$id)
} # }

## ------------------------------------------------
## Method `BinanceWithdrawal$get_withdrawal_history()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- BinanceWithdrawal$new()

# Get all completed USDT withdrawals
history <- withdrawal$get_withdrawal_history(coin = "USDT", status = 6)
print(history[, .(amount, coin, status, address, apply_time)])

# Get withdrawals from the last 7 days
now_ms <- as.integer(as.numeric(Sys.time()) * 1000)
recent <- withdrawal$get_withdrawal_history(
  start_time = now_ms - 7 * 86400000L,
  end_time = now_ms
)
} # }
```
