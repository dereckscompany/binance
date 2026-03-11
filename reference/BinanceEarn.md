# BinanceEarn: Simple Earn Management

BinanceEarn: Simple Earn Management

BinanceEarn: Simple Earn Management

## Details

Provides methods for subscribing, redeeming, and querying Simple Earn
flexible and locked products on Binance. Inherits from
[BinanceBase](https://dereckmezquita.github.io/binance/reference/BinanceBase.md).

### Purpose and Scope

- **Product Discovery**: List available flexible and locked earn
  products.

- **Subscriptions**: Subscribe to flexible or locked products.

- **Redemptions**: Redeem from flexible or locked positions.

- **Positions**: Query current flexible and locked positions.

- **History**: Retrieve subscription and redemption history records.

### Usage

All methods require authentication (valid API key and secret). These are
wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.

### Official Documentation

[Binance Simple
Earn](https://developers.binance.com/docs/simple_earn/Introduction)

### Endpoints Covered

|                                   |                                                              |      |
|-----------------------------------|--------------------------------------------------------------|------|
| Method                            | Endpoint                                                     | HTTP |
| get_flexible_products             | GET /sapi/v1/simple-earn/flexible/list                       | GET  |
| get_locked_products               | GET /sapi/v1/simple-earn/locked/list                         | GET  |
| add_flexible_subscription         | POST /sapi/v1/simple-earn/flexible/subscribe                 | POST |
| add_locked_subscription           | POST /sapi/v1/simple-earn/locked/subscribe                   | POST |
| add_flexible_redemption           | POST /sapi/v1/simple-earn/flexible/redeem                    | POST |
| add_locked_redemption             | POST /sapi/v1/simple-earn/locked/redeem                      | POST |
| get_flexible_position             | GET /sapi/v1/simple-earn/flexible/position                   | GET  |
| get_locked_position               | GET /sapi/v1/simple-earn/locked/position                     | GET  |
| get_flexible_subscription_history | GET /sapi/v1/simple-earn/flexible/history/subscriptionRecord | GET  |
| get_locked_subscription_history   | GET /sapi/v1/simple-earn/locked/history/subscriptionRecord   | GET  |
| get_flexible_redemption_history   | GET /sapi/v1/simple-earn/flexible/history/redemptionRecord   | GET  |
| get_locked_redemption_history     | GET /sapi/v1/simple-earn/locked/history/redemptionRecord     | GET  |

## Super class

[`binance::BinanceBase`](https://dereckmezquita.github.io/binance/reference/BinanceBase.md)
-\> `BinanceEarn`

## Methods

### Public methods

- [`BinanceEarn$get_flexible_products()`](#method-BinanceEarn-get_flexible_products)

- [`BinanceEarn$get_locked_products()`](#method-BinanceEarn-get_locked_products)

- [`BinanceEarn$add_flexible_subscription()`](#method-BinanceEarn-add_flexible_subscription)

- [`BinanceEarn$add_locked_subscription()`](#method-BinanceEarn-add_locked_subscription)

- [`BinanceEarn$add_flexible_redemption()`](#method-BinanceEarn-add_flexible_redemption)

- [`BinanceEarn$add_locked_redemption()`](#method-BinanceEarn-add_locked_redemption)

- [`BinanceEarn$get_flexible_position()`](#method-BinanceEarn-get_flexible_position)

- [`BinanceEarn$get_locked_position()`](#method-BinanceEarn-get_locked_position)

- [`BinanceEarn$get_flexible_subscription_history()`](#method-BinanceEarn-get_flexible_subscription_history)

- [`BinanceEarn$get_locked_subscription_history()`](#method-BinanceEarn-get_locked_subscription_history)

- [`BinanceEarn$get_flexible_redemption_history()`](#method-BinanceEarn-get_flexible_redemption_history)

- [`BinanceEarn$get_locked_redemption_history()`](#method-BinanceEarn-get_locked_redemption_history)

- [`BinanceEarn$clone()`](#method-BinanceEarn-clone)

Inherited methods

- [`binance::BinanceBase$initialize()`](https://dereckmezquita.github.io/binance/reference/BinanceBase.html#method-initialize)

------------------------------------------------------------------------

### Method `get_flexible_products()`

Get Flexible Products

Lists available Simple Earn flexible products, optionally filtered by
asset.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/flexible/list`

#### Official Documentation

[Binance Simple Earn Flexible
List](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Simple-Earn-Flexible-Product-List)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/list?asset=USDT&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "asset": "USDT",
          "latestAnnualPercentageRate": "0.03250000",
          "canPurchase": true,
          "canRedeem": true,
          "isSoldOut": false,
          "hot": true,
          "minPurchaseAmount": "0.10000000",
          "productId": "USDT001",
          "subscriptionStartTime": 1661493146000,
          "status": "PURCHASING"
        }
      ]
    }

#### Usage

    BinanceEarn$get_flexible_products(
      asset = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character or NULL; filter by asset (e.g., `"USDT"`).

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per product and the following columns:

- `asset` (character): Asset symbol (e.g., `"USDT"`).

- `latest_annual_percentage_rate` (character): Current annual yield
  rate.

- `can_purchase` (logical): Whether new subscriptions are accepted.

- `can_redeem` (logical): Whether redemptions are allowed.

- `is_sold_out` (logical): Whether the product is sold out.

- `hot` (logical): Whether the product is marked as popular.

- `min_purchase_amount` (character): Minimum subscription amount.

- `product_id` (character): Unique product identifier.

- `subscription_start_time` (numeric): Subscription start timestamp in
  ms.

- `status` (character): Product status (e.g., `"PURCHASING"`).

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    products <- earn$get_flexible_products(asset = "USDT")
    print(products)
    }

------------------------------------------------------------------------

### Method `get_locked_products()`

Get Locked Products

Lists available Simple Earn locked products, optionally filtered by
asset.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/locked/list`

#### Official Documentation

[Binance Simple Earn Locked
List](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Simple-Earn-Locked-Product-List)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/list?asset=BTC&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "projectId": "BTC30d001",
          "detail": {
            "asset": "BTC",
            "rewardAsset": "BTC",
            "duration": 30,
            "renewable": true,
            "apy": "0.05000000"
          },
          "quota": {
            "totalPersonalQuota": "10.00000000",
            "minimum": "0.001"
          }
        }
      ]
    }

#### Usage

    BinanceEarn$get_locked_products(
      asset = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character or NULL; filter by asset (e.g., `"BTC"`).

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per product and the following columns:

- `project_id` (character): Unique project identifier.

- `detail` (list): Nested product details (asset, reward asset,
  duration, APY).

- `quota` (list): Nested quota details (total personal quota, minimum).

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    products <- earn$get_locked_products(asset = "BTC")
    print(products)
    }

------------------------------------------------------------------------

### Method `add_flexible_subscription()`

Subscribe to Flexible Product

Subscribes to a Simple Earn flexible product.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/simple-earn/flexible/subscribe`

#### Official Documentation

[Binance Simple Earn Flexible
Subscribe](https://developers.binance.com/docs/simple_earn/flexible-locked/earn)
Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/flexible/subscribe' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'productId=USDT001&amount=100&timestamp=1661493146000&signature=...'

#### JSON Request

    {
      "productId": "USDT001",
      "amount": "100",
      "autoSubscribe": true,
      "sourceAccount": "SPOT"
    }

#### JSON Response

    {
      "purchaseId": 40607,
      "success": true
    }

#### Usage

    BinanceEarn$add_flexible_subscription(
      productId,
      amount,
      autoSubscribe = NULL,
      sourceAccount = NULL,
      recvWindow = NULL
    )

#### Arguments

- `productId`:

  Character; the product ID to subscribe to.

- `amount`:

  Numeric; amount to subscribe.

- `autoSubscribe`:

  Logical or NULL; whether to enable auto-subscription.

- `sourceAccount`:

  Character or NULL; source wallet: `"SPOT"`, `"FUND"`, or `"ALL"`.
  Default `"SPOT"`.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `purchase_id` (integer): Unique purchase identifier.

- `success` (logical): Whether the subscription was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_flexible_subscription(productId = "USDT001", amount = 100)
    print(result)
    }

------------------------------------------------------------------------

### Method `add_locked_subscription()`

Subscribe to Locked Product

Subscribes to a Simple Earn locked product.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/simple-earn/locked/subscribe`

#### Official Documentation

[Binance Simple Earn Locked
Subscribe](https://developers.binance.com/docs/simple_earn/flexible-locked/earn/Subscribe-Locked-Product)
Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/locked/subscribe' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'projectId=BTC30d001&amount=0.01&timestamp=1661493146000&signature=...'

#### JSON Request

    {
      "projectId": "BTC30d001",
      "amount": "0.01",
      "autoSubscribe": true
    }

#### JSON Response

    {
      "purchaseId": 40608,
      "positionId": "12345",
      "success": true
    }

#### Usage

    BinanceEarn$add_locked_subscription(
      projectId,
      amount,
      autoSubscribe = NULL,
      recvWindow = NULL
    )

#### Arguments

- `projectId`:

  Character; the project ID to subscribe to.

- `amount`:

  Numeric; amount to subscribe.

- `autoSubscribe`:

  Logical or NULL; whether to enable auto-subscription.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `purchase_id` (integer): Unique purchase identifier.

- `position_id` (character): Position identifier for the locked
  subscription.

- `success` (logical): Whether the subscription was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_locked_subscription(projectId = "BTC30d001", amount = 0.01)
    print(result)
    }

------------------------------------------------------------------------

### Method `add_flexible_redemption()`

Redeem Flexible Product

Redeems from a Simple Earn flexible product.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/simple-earn/flexible/redeem`

#### Official Documentation

[Binance Simple Earn Flexible
Redeem](https://developers.binance.com/docs/simple_earn/flexible-locked/earn/Redeem-Flexible-Product)
Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/flexible/redeem' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'productId=USDT001&amount=50&timestamp=1661493146000&signature=...'

#### JSON Request

    {
      "productId": "USDT001",
      "amount": "50",
      "redeemAll": false,
      "destAccount": "SPOT"
    }

#### JSON Response

    {
      "redeemId": 40609,
      "success": true
    }

#### Usage

    BinanceEarn$add_flexible_redemption(
      productId,
      amount = NULL,
      redeemAll = NULL,
      destAccount = NULL,
      recvWindow = NULL
    )

#### Arguments

- `productId`:

  Character; the product ID to redeem from.

- `amount`:

  Numeric or NULL; amount to redeem. If NULL, use `redeemAll`.

- `redeemAll`:

  Logical or NULL; if TRUE, redeem entire position.

- `destAccount`:

  Character or NULL; destination wallet: `"SPOT"` or `"FUND"`. Default
  `"SPOT"`.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `redeem_id` (integer): Unique redemption identifier.

- `success` (logical): Whether the redemption was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_flexible_redemption(productId = "USDT001", amount = 50)
    print(result)
    }

------------------------------------------------------------------------

### Method `add_locked_redemption()`

Redeem Locked Product

Redeems from a Simple Earn locked product.

#### API Endpoint

`POST https://api.binance.com/sapi/v1/simple-earn/locked/redeem`

#### Official Documentation

[Binance Simple Earn Locked
Redeem](https://developers.binance.com/docs/simple_earn/flexible-locked/earn/Redeem-Locked-Product)
Verified: 2026-03-10

#### curl

    curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/locked/redeem' \
      -H 'X-MBX-APIKEY: your-api-key' \
      -d 'positionId=12345&timestamp=1661493146000&signature=...'

#### JSON Request

    {
      "positionId": "12345"
    }

#### JSON Response

    {
      "redeemId": 40610,
      "success": true
    }

#### Usage

    BinanceEarn$add_locked_redemption(positionId, recvWindow = NULL)

#### Arguments

- `positionId`:

  Character; the position ID to redeem.

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row and the following columns:

- `redeem_id` (integer): Unique redemption identifier.

- `success` (logical): Whether the redemption was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_locked_redemption(positionId = "12345")
    print(result)
    }

------------------------------------------------------------------------

### Method `get_flexible_position()`

Get Flexible Position

Retrieves current flexible earn positions, optionally filtered by asset
or product.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/flexible/position`

#### Official Documentation

[Binance Simple Earn Flexible
Position](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Flexible-Product-Position)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/position?asset=USDT&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "totalAmount": "100.00000000",
          "latestAnnualPercentageRate": "0.03250000",
          "asset": "USDT",
          "canRedeem": true,
          "productId": "USDT001",
          "autoSubscribe": true
        }
      ]
    }

#### Usage

    BinanceEarn$get_flexible_position(
      asset = NULL,
      productId = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character or NULL; filter by asset (e.g., `"USDT"`).

- `productId`:

  Character or NULL; filter by product ID.

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per position and the following columns:

- `total_amount` (character): Total amount in the position.

- `latest_annual_percentage_rate` (character): Current annual yield
  rate.

- `asset` (character): Asset symbol (e.g., `"USDT"`).

- `can_redeem` (logical): Whether redemption is allowed.

- `product_id` (character): Product identifier.

- `auto_subscribe` (logical): Whether auto-subscription is enabled.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    positions <- earn$get_flexible_position(asset = "USDT")
    print(positions)
    }

------------------------------------------------------------------------

### Method `get_locked_position()`

Get Locked Position

Retrieves current locked earn positions, optionally filtered by asset,
position ID, or project ID.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/locked/position`

#### Official Documentation

[Binance Simple Earn Locked
Position](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Locked-Product-Position)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/position?asset=BTC&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "positionId": "12345",
          "projectId": "BTC30d001",
          "asset": "BTC",
          "amount": "0.01000000",
          "purchaseTime": 1661493146000,
          "duration": 30,
          "accrualDays": 15,
          "rewardAsset": "BTC",
          "apy": "0.05000000",
          "isRenewable": true,
          "isAutoRenew": true,
          "redeemDate": 1664085146000
        }
      ]
    }

#### Usage

    BinanceEarn$get_locked_position(
      asset = NULL,
      positionId = NULL,
      projectId = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `asset`:

  Character or NULL; filter by asset (e.g., `"BTC"`).

- `positionId`:

  Character or NULL; filter by position ID.

- `projectId`:

  Character or NULL; filter by project ID.

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per position and the following columns:

- `position_id` (character): Position identifier.

- `project_id` (character): Project identifier.

- `asset` (character): Asset symbol.

- `amount` (character): Locked amount.

- `purchase_time` (numeric): Subscription timestamp in ms.

- `duration` (integer): Lock duration in days.

- `accrual_days` (integer): Number of days interest has accrued.

- `reward_asset` (character): Reward asset symbol.

- `apy` (character): Annual percentage yield.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    positions <- earn$get_locked_position(asset = "BTC")
    print(positions)
    }

------------------------------------------------------------------------

### Method `get_flexible_subscription_history()`

Get Flexible Subscription History

Retrieves subscription history for flexible earn products.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/flexible/history/subscriptionRecord`

#### Official Documentation

[Binance Simple Earn Flexible Subscription
Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/history/subscriptionRecord?asset=USDT&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "amount": "100.00000000",
          "asset": "USDT",
          "time": 1661493146000,
          "purchaseId": 40607,
          "type": "AUTO",
          "sourceAccount": "SPOT",
          "status": "SUCCESS"
        }
      ]
    }

#### Usage

    BinanceEarn$get_flexible_subscription_history(
      productId = NULL,
      purchaseId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `productId`:

  Character or NULL; filter by product ID.

- `purchaseId`:

  Integer or NULL; filter by purchase ID.

- `asset`:

  Character or NULL; filter by asset (e.g., `"USDT"`).

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per subscription record and the following
columns:

- `amount` (character): Subscription amount.

- `asset` (character): Asset symbol.

- `time` (POSIXct): Subscription time.

- `purchase_id` (integer): Purchase identifier.

- `type` (character): Subscription type (e.g., `"AUTO"`, `"NORMAL"`).

- `source_account` (character): Source account (e.g., `"SPOT"`).

- `status` (character): Subscription status (e.g., `"SUCCESS"`).

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    history <- earn$get_flexible_subscription_history(asset = "USDT")
    print(history)
    }

------------------------------------------------------------------------

### Method `get_locked_subscription_history()`

Get Locked Subscription History

Retrieves subscription history for locked earn products.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/locked/history/subscriptionRecord`

#### Official Documentation

[Binance Simple Earn Locked Subscription
Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history/Get-Locked-Subscription-Record)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/history/subscriptionRecord?asset=BTC&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "amount": "0.01000000",
          "asset": "BTC",
          "time": 1661493146000,
          "purchaseId": 40608,
          "positionId": "12345",
          "lockPeriod": 30,
          "type": "NORMAL",
          "sourceAccount": "SPOT",
          "status": "SUCCESS"
        }
      ]
    }

#### Usage

    BinanceEarn$get_locked_subscription_history(
      purchaseId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `purchaseId`:

  Integer or NULL; filter by purchase ID.

- `asset`:

  Character or NULL; filter by asset (e.g., `"BTC"`).

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per subscription record and the following
columns:

- `amount` (character): Subscription amount.

- `asset` (character): Asset symbol.

- `time` (POSIXct): Subscription time.

- `purchase_id` (integer): Purchase identifier.

- `position_id` (character): Position identifier.

- `lock_period` (integer): Lock duration in days.

- `type` (character): Subscription type.

- `source_account` (character): Source account.

- `status` (character): Subscription status.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    history <- earn$get_locked_subscription_history(asset = "BTC")
    print(history)
    }

------------------------------------------------------------------------

### Method `get_flexible_redemption_history()`

Get Flexible Redemption History

Retrieves redemption history for flexible earn products.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/flexible/history/redemptionRecord`

#### Official Documentation

[Binance Simple Earn Flexible Redemption
Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history/Get-Flexible-Redemption-Record)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/history/redemptionRecord?asset=USDT&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "amount": "50.00000000",
          "asset": "USDT",
          "time": 1661493146000,
          "projectId": "USDT001",
          "redeemId": 40609,
          "destAccount": "SPOT",
          "status": "PAID"
        }
      ]
    }

#### Usage

    BinanceEarn$get_flexible_redemption_history(
      productId = NULL,
      redeemId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `productId`:

  Character or NULL; filter by product ID.

- `redeemId`:

  Integer or NULL; filter by redeem ID.

- `asset`:

  Character or NULL; filter by asset (e.g., `"USDT"`).

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per redemption record and the following
columns:

- `amount` (character): Redemption amount.

- `asset` (character): Asset symbol.

- `time` (POSIXct): Redemption time.

- `project_id` (character): Product identifier.

- `redeem_id` (integer): Redemption identifier.

- `dest_account` (character): Destination account.

- `status` (character): Redemption status (e.g., `"PAID"`).

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    history <- earn$get_flexible_redemption_history(asset = "USDT")
    print(history)
    }

------------------------------------------------------------------------

### Method `get_locked_redemption_history()`

Get Locked Redemption History

Retrieves redemption history for locked earn products.

#### API Endpoint

`GET https://api.binance.com/sapi/v1/simple-earn/locked/history/redemptionRecord`

#### Official Documentation

[Binance Simple Earn Locked Redemption
Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history/Get-Locked-Redemption-Record)
Verified: 2026-03-10

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/history/redemptionRecord?asset=BTC&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

    {
      "total": 1,
      "rows": [
        {
          "amount": "0.01000000",
          "asset": "BTC",
          "time": 1661493146000,
          "positionId": "12345",
          "redeemId": 40610,
          "deliverDate": "1664085146000",
          "status": "PAID"
        }
      ]
    }

#### Usage

    BinanceEarn$get_locked_redemption_history(
      positionId = NULL,
      redeemId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    )

#### Arguments

- `positionId`:

  Character or NULL; filter by position ID.

- `redeemId`:

  Integer or NULL; filter by redeem ID.

- `asset`:

  Character or NULL; filter by asset (e.g., `"BTC"`).

- `startTime`:

  Integer or NULL; start timestamp in milliseconds.

- `endTime`:

  Integer or NULL; end timestamp in milliseconds.

- `current`:

  Integer or NULL; current page (default 1, starting from 1).

- `size`:

  Integer or NULL; page size (default 10, max 100).

- `recvWindow`:

  Integer or NULL; max 60000.

#### Returns

`data.table` with one row per redemption record and the following
columns:

- `amount` (character): Redemption amount.

- `asset` (character): Asset symbol.

- `time` (POSIXct): Redemption time.

- `position_id` (character): Position identifier.

- `redeem_id` (integer): Redemption identifier.

- `deliver_date` (character): Expected delivery date.

- `status` (character): Redemption status.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    history <- earn$get_locked_redemption_history(asset = "BTC")
    print(history)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceEarn$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
earn <- BinanceEarn$new()
products <- earn$get_flexible_products(asset = "USDT")
print(products)

# Subscribe
result <- earn$add_flexible_subscription(productId = "USDT001", amount = 100)
print(result)

# Asynchronous
earn_async <- BinanceEarn$new(async = TRUE)
main <- coro::async(function() {
  products <- await(earn_async$get_flexible_products(asset = "USDT"))
  print(products)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `BinanceEarn$get_flexible_products`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
products <- earn$get_flexible_products(asset = "USDT")
print(products)
} # }

## ------------------------------------------------
## Method `BinanceEarn$get_locked_products`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
products <- earn$get_locked_products(asset = "BTC")
print(products)
} # }

## ------------------------------------------------
## Method `BinanceEarn$add_flexible_subscription`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
result <- earn$add_flexible_subscription(productId = "USDT001", amount = 100)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceEarn$add_locked_subscription`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
result <- earn$add_locked_subscription(projectId = "BTC30d001", amount = 0.01)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceEarn$add_flexible_redemption`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
result <- earn$add_flexible_redemption(productId = "USDT001", amount = 50)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceEarn$add_locked_redemption`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
result <- earn$add_locked_redemption(positionId = "12345")
print(result)
} # }

## ------------------------------------------------
## Method `BinanceEarn$get_flexible_position`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
positions <- earn$get_flexible_position(asset = "USDT")
print(positions)
} # }

## ------------------------------------------------
## Method `BinanceEarn$get_locked_position`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
positions <- earn$get_locked_position(asset = "BTC")
print(positions)
} # }

## ------------------------------------------------
## Method `BinanceEarn$get_flexible_subscription_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
history <- earn$get_flexible_subscription_history(asset = "USDT")
print(history)
} # }

## ------------------------------------------------
## Method `BinanceEarn$get_locked_subscription_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
history <- earn$get_locked_subscription_history(asset = "BTC")
print(history)
} # }

## ------------------------------------------------
## Method `BinanceEarn$get_flexible_redemption_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
history <- earn$get_flexible_redemption_history(asset = "USDT")
print(history)
} # }

## ------------------------------------------------
## Method `BinanceEarn$get_locked_redemption_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
history <- earn$get_locked_redemption_history(asset = "BTC")
print(history)
} # }
```
