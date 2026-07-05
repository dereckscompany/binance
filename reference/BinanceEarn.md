# BinanceEarn: Simple Earn Management

BinanceEarn: Simple Earn Management

BinanceEarn: Simple Earn Management

## Details

Provides methods for subscribing, redeeming, and querying Simple Earn
flexible and locked products on Binance. Inherits from
[BinanceBase](https://dereckscompany.github.io/binance/reference/BinanceBase.md).

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

|  |  |  |
|----|----|----|
| Method | Endpoint | HTTP |
| get_flexible_products | GET /sapi/v1/simple-earn/flexible/list | GET |
| get_locked_products | GET /sapi/v1/simple-earn/locked/list | GET |
| add_flexible_subscription | POST /sapi/v1/simple-earn/flexible/subscribe | POST |
| add_locked_subscription | POST /sapi/v1/simple-earn/locked/subscribe | POST |
| add_flexible_redemption | POST /sapi/v1/simple-earn/flexible/redeem | POST |
| add_locked_redemption | POST /sapi/v1/simple-earn/locked/redeem | POST |
| get_flexible_position | GET /sapi/v1/simple-earn/flexible/position | GET |
| get_locked_position | GET /sapi/v1/simple-earn/locked/position | GET |
| get_flexible_subscription_history | GET /sapi/v1/simple-earn/flexible/history/subscriptionRecord | GET |
| get_locked_subscription_history | GET /sapi/v1/simple-earn/locked/history/subscriptionRecord | GET |
| get_flexible_redemption_history | GET /sapi/v1/simple-earn/flexible/history/redemptionRecord | GET |
| get_locked_redemption_history | GET /sapi/v1/simple-earn/locked/history/redemptionRecord | GET |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`binance::BinanceBase`](https://dereckscompany.github.io/binance/reference/BinanceBase.md)
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

- [`binance::BinanceBase$initialize()`](https://dereckscompany.github.io/binance/reference/BinanceBase.html#method-initialize)

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
Verified: 2026-05-22

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
          "tierAnnualPercentageRate": {
            "0-5BTC": 0.05,
            "5-10BTC": 0.03
          },
          "airDropPercentageRate": "0.05000000",
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
      recv_window = NULL
    )

#### Arguments

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"USDT"`).

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per product (empty when
there are none):

- asset (character) Asset symbol (e.g., `"USDT"`).

- latest_annual_percentage_rate (character) Current annual yield rate.

- tier_annual_percentage_rate (character \| NA) JSON-encoded per-tier
  APR map (dynamic keys like `"0-5BTC"`, `"5-10BTC"`). Recover via
  `jsonlite::fromJSON(dt$tier_annual_percentage_rate[1])`. `NA` when the
  field is absent.

- can_purchase (logical) Whether new subscriptions are accepted.

- can_redeem (logical) Whether redemptions are allowed.

- is_sold_out (logical) Whether the product is sold out.

- hot (logical) Whether the product is marked as popular.

- min_purchase_amount (character) Minimum subscription amount.

- product_id (character) Unique product identifier.

- subscription_start_time (POSIXct) Subscription start time.

- status (character) Product status (e.g., `"PURCHASING"`).

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
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/list?asset=BTC&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

Shape captured 2026-05-22 from the live docs. Binance renamed
`detail.apy` → `detail.apr` and added the extra-reward / boost fields;
older internal examples that still show `apy` are stale.

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
            "isSoldOut": false,
            "apr": "0.05000000",
            "status": "CREATED",
            "subscriptionStartTime": 1646182276000,
            "extraRewardAsset": "BNB",
            "extraRewardAPR": "0.01000000",
            "boostRewardAsset": "BTC",
            "boostApr": "0.00100000",
            "boostEndTime": 1646182276000
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
      recv_window = NULL
    )

#### Arguments

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"BTC"`).

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per product (empty when
there are none). Nested `detail` and `quota` objects are wide-prefixed
(`detail_*` and `quota_*`) per the package's "no list columns" policy.
Field names mirror the current Binance API (verified 2026-05-22):

- project_id (character) Unique project identifier.

- detail_asset (character) Subscription asset (e.g. `"BTC"`).

- detail_reward_asset (character) Reward asset.

- detail_duration (integer) Lock-up duration in days.

- detail_renewable (logical) Whether the product auto-renews.

- detail_is_sold_out (logical) Whether the offering is currently sold
  out (no new subscriptions accepted).

- detail_apr (character) Annual percentage rate. NOTE: Binance renamed
  this from `apy` → `apr` on the live API; older docs that show `apy`
  are stale.

- detail_status (character) Product lifecycle state (e.g. `"CREATED"`,
  `"PURCHASING"`).

- detail_subscription_start_time (POSIXct) Subscription open timestamp
  in milliseconds.

- detail_extra_reward_asset (character) Additional reward asset, if the
  product carries a boost.

- detail_extra_reward_apr (character) Extra reward APR.

- detail_boost_reward_asset (character) Boost reward asset.

- detail_boost_apr (character) Boost APR.

- detail_boost_end_time (POSIXct) Boost end time.

- quota_total_personal_quota (character) Per-user maximum.

- quota_minimum (character) Per-user minimum.

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
Verified: 2026-05-22

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
      product_id,
      amount,
      auto_subscribe = NULL,
      source_account = NULL,
      recv_window = NULL
    )

#### Arguments

- `product_id`:

  (scalar\<character\>) the product ID to subscribe to.

- `amount`:

  (scalar\<numeric\>) amount to subscribe.

- `auto_subscribe`:

  (scalar\<logical\>?) whether to enable auto-subscription.

- `source_account`:

  (scalar\<character\>?) source wallet: `"SPOT"`, `"FUND"`, or `"ALL"`.
  Default `"SPOT"`.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- purchase_id (numeric) Unique purchase identifier.

- success (logical) Whether the subscription was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_flexible_subscription(product_id = "USDT001", amount = 100)
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
Verified: 2026-05-22

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
      project_id,
      amount,
      auto_subscribe = NULL,
      recv_window = NULL
    )

#### Arguments

- `project_id`:

  (scalar\<character\>) the project ID to subscribe to.

- `amount`:

  (scalar\<numeric\>) amount to subscribe.

- `auto_subscribe`:

  (scalar\<logical\>?) whether to enable auto-subscription.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- purchase_id (numeric) Unique purchase identifier.

- position_id (character) Position identifier for the locked
  subscription.

- success (logical) Whether the subscription was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_locked_subscription(project_id = "BTC30d001", amount = 0.01)
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
Verified: 2026-05-22

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
      product_id,
      amount = NULL,
      redeem_all = NULL,
      dest_account = NULL,
      recv_window = NULL
    )

#### Arguments

- `product_id`:

  (scalar\<character\>) the product ID to redeem from.

- `amount`:

  (scalar\<numeric\>?) amount to redeem. If NULL, use `redeemAll`.

- `redeem_all`:

  (scalar\<logical\>?) if TRUE, redeem entire position.

- `dest_account`:

  (scalar\<character\>?) destination wallet: `"SPOT"` or `"FUND"`.
  Default `"SPOT"`.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- redeem_id (numeric) Unique redemption identifier.

- success (logical) Whether the redemption was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_flexible_redemption(product_id = "USDT001", amount = 50)
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
Verified: 2026-05-22

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

    BinanceEarn$add_locked_redemption(position_id, recv_window = NULL)

#### Arguments

- `position_id`:

  (scalar\<character\>) the position ID to redeem.

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row:

- redeem_id (numeric) Unique redemption identifier.

- success (logical) Whether the redemption was successful.

#### Examples

    \dontrun{
    earn <- BinanceEarn$new()
    result <- earn$add_locked_redemption(position_id = "12345")
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
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/position?asset=USDT&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

Shape captured 2026-05-22 from the live docs.

    {
      "total": 1,
      "rows": [
        {
          "totalAmount": "75.46000000",
          "tierAnnualPercentageRate": {
            "0-5BTC": 0.05,
            "5-10BTC": 0.03
          },
          "latestAnnualPercentageRate": "0.02599895",
          "yesterdayAirdropPercentageRate": "0.02599895",
          "asset": "USDT",
          "airDropAsset": "BETH",
          "canRedeem": true,
          "collateralAmount": "232.23123213",
          "productId": "USDT001",
          "yesterdayRealTimeRewards": "0.10293829",
          "cumulativeBonusRewards": "0.22759183",
          "cumulativeRealTimeRewards": "0.22759183",
          "cumulativeTotalRewards": "0.45459183",
          "autoSubscribe": true
        }
      ]
    }

#### Usage

    BinanceEarn$get_flexible_position(
      asset = NULL,
      product_id = NULL,
      current = NULL,
      size = NULL,
      recv_window = NULL
    )

#### Arguments

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"USDT"`).

- `product_id`:

  (scalar\<character\>?) filter by product ID.

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per position (empty when
there are none):

- total_amount (character) Total amount in the position.

- latest_annual_percentage_rate (character) Current annual yield rate.

- tier_annual_percentage_rate (character \| NA) optional; JSON-encoded
  per-tier APR map when the position carries tier-based rates (dynamic
  keys like `"0-5BTC"`). Recover via
  `jsonlite::fromJSON(dt$tier_annual_percentage_rate[1])`.

- yesterday_airdrop_percentage_rate (character) Air-drop APR for the
  previous accrual period.

- asset (character) Asset symbol (e.g., `"USDT"`).

- air_drop_asset (character) Asset paid as an air-drop reward, if any.

- can_redeem (logical) Whether redemption is allowed.

- collateral_amount (character) Amount currently locked as collateral,
  if the position is being used as such.

- product_id (character) Product identifier.

- yesterday_real_time_rewards (character) Real-time rewards accrued in
  the previous period.

- cumulative_bonus_rewards (character) Cumulative bonus rewards earned
  on this position.

- cumulative_real_time_rewards (character) Cumulative real-time rewards.

- cumulative_total_rewards (character) Cumulative total rewards (bonus +
  real-time).

- auto_subscribe (logical) Whether auto-subscription is enabled.

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
Verified: 2026-05-22

#### curl

    curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/position?asset=BTC&timestamp=1661493146000&signature=...' \
      -H 'X-MBX-APIKEY: your-api-key'

#### JSON Response

Shape captured 2026-05-22 from the live docs. NOTE: Binance returns the
rate as uppercase `APY` (not `apy`); our snake_case converter lowers it
to `apy` in the data.table.

    {
      "rows": [
        {
          "positionId": 123123,
          "parentPositionId": 123122,
          "projectId": "Axs*90",
          "asset": "AXS",
          "amount": "122.09202928",
          "purchaseTime": 1646182276000,
          "duration": "60",
          "accrualDays": "4",
          "rewardAsset": "AXS",
          "APY": "0.2032",
          "rewardAmt": "5.17181528",
          "extraRewardAsset": "BNB",
          "extraRewardAPR": "0.0203",
          "estExtraRewardAmt": "5.17181528",
          "boostRewardAsset": "AXS",
          "boostApr": "0.0121",
          "totalBoostRewardAmt": "3.98201829",
          "nextPay": "1.29295383",
          "nextPayDate": 1646697600000,
          "payPeriod": "1",
          "redeemAmountEarly": "2802.24068892",
          "rewardsEndDate": 1651449600000,
          "deliverDate": 1651536000000,
          "redeemPeriod": "1",
          "redeemingAmt": "232.2323",
          "redeemTo": "FLEXIBLE",
          "partialAmtDeliverDate": 1651536000000,
          "canRedeemEarly": true,
          "canFastRedemption": true,
          "autoSubscribe": true,
          "type": "AUTO",
          "status": "HOLDING",
          "canReStake": true
        }
      ],
      "total": 1
    }

#### Usage

    BinanceEarn$get_locked_position(
      asset = NULL,
      position_id = NULL,
      project_id = NULL,
      current = NULL,
      size = NULL,
      recv_window = NULL
    )

#### Arguments

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"BTC"`).

- `position_id`:

  (scalar\<character\>?) filter by position ID.

- `project_id`:

  (scalar\<character\>?) filter by project ID.

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per locked position (empty
when there are none), with whichever fields Binance returns, snake-cased
(Binance's uppercase `APY` lowers to `apy`). Common columns:
`position_id`, `parent_position_id`, `project_id`, `asset`, `amount`,
`purchase_time` (POSIXct), `duration`, `accrual_days`, `reward_asset`,
`apy`, `reward_amt`, `extra_reward_asset`, `extra_reward_apr`,
`est_extra_reward_amt`, `boost_reward_asset`, `boost_apr`,
`total_boost_reward_amt`, `next_pay`, `next_pay_date` (POSIXct),
`pay_period`, `redeem_amount_early`, `rewards_end_date` (POSIXct),
`deliver_date` (POSIXct), `redeem_period`, `redeeming_amt`, `redeem_to`,
`partial_amt_deliver_date` (POSIXct), `can_redeem_early`,
`can_fast_redemption`, `auto_subscribe`, `type`, `status`,
`can_re_stake`. The exact column set follows the payload, so the return
is typed only as a `data.table` (no fixed-column contract).

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
Verified: 2026-05-22

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
      product_id = NULL,
      purchase_id = NULL,
      asset = NULL,
      start_time = NULL,
      end_time = NULL,
      current = NULL,
      size = NULL,
      recv_window = NULL
    )

#### Arguments

- `product_id`:

  (scalar\<character\>?) filter by product ID.

- `purchase_id`:

  (scalar\<count\>?) filter by purchase ID.

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"USDT"`).

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per subscription record
(empty when there are none):

- amount (character) Subscription amount.

- asset (character) Asset symbol.

- time (POSIXct) Subscription time.

- purchase_id (numeric) Purchase identifier.

- type (character) Subscription type (e.g., `"AUTO"`, `"NORMAL"`).

- source_account (character) Source account (e.g., `"SPOT"`).

- status (character) Subscription status (e.g., `"SUCCESS"`).

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
Verified: 2026-05-22

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
      purchase_id = NULL,
      asset = NULL,
      start_time = NULL,
      end_time = NULL,
      current = NULL,
      size = NULL,
      recv_window = NULL
    )

#### Arguments

- `purchase_id`:

  (scalar\<count\>?) filter by purchase ID.

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"BTC"`).

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per subscription record
(empty when there are none):

- amount (character) Subscription amount.

- asset (character) Asset symbol.

- time (POSIXct) Subscription time.

- purchase_id (numeric) Purchase identifier.

- position_id (character) Position identifier.

- lock_period (integer) Lock duration in days.

- type (character) Subscription type.

- source_account (character) Source account.

- status (character) Subscription status.

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
Verified: 2026-05-22

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
      product_id = NULL,
      redeem_id = NULL,
      asset = NULL,
      start_time = NULL,
      end_time = NULL,
      current = NULL,
      size = NULL,
      recv_window = NULL
    )

#### Arguments

- `product_id`:

  (scalar\<character\>?) filter by product ID.

- `redeem_id`:

  (scalar\<count\>?) filter by redeem ID.

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"USDT"`).

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per redemption record
(empty when there are none):

- amount (character) Redemption amount.

- asset (character) Asset symbol.

- time (POSIXct) Redemption time.

- project_id (character) Product identifier.

- redeem_id (numeric) Redemption identifier.

- dest_account (character) Destination account.

- status (character) Redemption status (e.g., `"PAID"`).

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
Verified: 2026-05-22

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
          "deliverDate": 1664085146000,
          "status": "PAID"
        }
      ]
    }

#### Usage

    BinanceEarn$get_locked_redemption_history(
      position_id = NULL,
      redeem_id = NULL,
      asset = NULL,
      start_time = NULL,
      end_time = NULL,
      current = NULL,
      size = NULL,
      recv_window = NULL
    )

#### Arguments

- `position_id`:

  (scalar\<character\>?) filter by position ID.

- `redeem_id`:

  (scalar\<count\>?) filter by redeem ID.

- `asset`:

  (scalar\<character\>?) filter by asset (e.g., `"BTC"`).

- `start_time`:

  (scalar\<count\>?) start timestamp in milliseconds.

- `end_time`:

  (scalar\<count\>?) end timestamp in milliseconds.

- `current`:

  (scalar\<count\>?) current page (default 1, starting from 1).

- `size`:

  (scalar\<count\>?) page size (default 10, max 100).

- `recv_window`:

  (scalar\<count\>?) max 60000.

#### Returns

(data.table \| promise\<data.table\>) one row per redemption record
(empty when there are none):

- amount (character) Redemption amount.

- asset (character) Asset symbol.

- time (POSIXct) Redemption time.

- position_id (character) Position identifier.

- redeem_id (numeric) Redemption identifier.

- deliver_date (POSIXct) Expected delivery time.

- status (character) Redemption status.

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
result <- earn$add_flexible_subscription(product_id = "USDT001", amount = 100)
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
result <- earn$add_flexible_subscription(product_id = "USDT001", amount = 100)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceEarn$add_locked_subscription`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
result <- earn$add_locked_subscription(project_id = "BTC30d001", amount = 0.01)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceEarn$add_flexible_redemption`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
result <- earn$add_flexible_redemption(product_id = "USDT001", amount = 50)
print(result)
} # }

## ------------------------------------------------
## Method `BinanceEarn$add_locked_redemption`
## ------------------------------------------------

if (FALSE) { # \dontrun{
earn <- BinanceEarn$new()
result <- earn$add_locked_redemption(position_id = "12345")
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
