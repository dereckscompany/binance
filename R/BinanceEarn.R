# File: R/BinanceEarn.R
# R6 class for Binance Simple Earn operations.

#' BinanceEarn: Simple Earn Management
#'
#' Provides methods for subscribing, redeeming, and querying Simple Earn
#' flexible and locked products on Binance. Inherits from [BinanceBase].
#'
#' ### Purpose and Scope
#' - **Product Discovery**: List available flexible and locked earn products.
#' - **Subscriptions**: Subscribe to flexible or locked products.
#' - **Redemptions**: Redeem from flexible or locked positions.
#' - **Positions**: Query current flexible and locked positions.
#' - **History**: Retrieve subscription and redemption history records.
#'
#' ### Usage
#' All methods require authentication (valid API key and secret).
#' These are wallet (`/sapi/`) endpoints, not spot (`/api/`) endpoints.
#'
#' ### Official Documentation
#' [Binance Simple Earn](https://developers.binance.com/docs/simple_earn/Introduction)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_flexible_products | GET /sapi/v1/simple-earn/flexible/list | GET |
#' | get_locked_products | GET /sapi/v1/simple-earn/locked/list | GET |
#' | add_flexible_subscription | POST /sapi/v1/simple-earn/flexible/subscribe | POST |
#' | add_locked_subscription | POST /sapi/v1/simple-earn/locked/subscribe | POST |
#' | add_flexible_redemption | POST /sapi/v1/simple-earn/flexible/redeem | POST |
#' | add_locked_redemption | POST /sapi/v1/simple-earn/locked/redeem | POST |
#' | get_flexible_position | GET /sapi/v1/simple-earn/flexible/position | GET |
#' | get_locked_position | GET /sapi/v1/simple-earn/locked/position | GET |
#' | get_flexible_subscription_history | GET /sapi/v1/simple-earn/flexible/history/subscriptionRecord | GET |
#' | get_locked_subscription_history | GET /sapi/v1/simple-earn/locked/history/subscriptionRecord | GET |
#' | get_flexible_redemption_history | GET /sapi/v1/simple-earn/flexible/history/redemptionRecord | GET |
#' | get_locked_redemption_history | GET /sapi/v1/simple-earn/locked/history/redemptionRecord | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' earn <- BinanceEarn$new()
#' products <- earn$get_flexible_products(asset = "USDT")
#' print(products)
#'
#' # Subscribe
#' result <- earn$add_flexible_subscription(productId = "USDT001", amount = 100)
#' print(result)
#'
#' # Asynchronous
#' earn_async <- BinanceEarn$new(async = TRUE)
#' main <- coro::async(function() {
#'   products <- await(earn_async$get_flexible_products(asset = "USDT"))
#'   print(products)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceEarn <- R6::R6Class(
  "BinanceEarn",
  inherit = BinanceBase,
  public = list(
    # ---- Product Listing ----

    #' @description
    #' Get Flexible Products
    #'
    #' Lists available Simple Earn flexible products, optionally filtered by asset.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/flexible/list`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Flexible List](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Simple-Earn-Flexible-Product-List)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/list?asset=USDT&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "asset": "USDT",
    #'       "latestAnnualPercentageRate": "0.03250000",
    #'       "tierAnnualPercentageRate": {
    #'         "0-5BTC": 0.05,
    #'         "5-10BTC": 0.03
    #'       },
    #'       "airDropPercentageRate": "0.05000000",
    #'       "canPurchase": true,
    #'       "canRedeem": true,
    #'       "isSoldOut": false,
    #'       "hot": true,
    #'       "minPurchaseAmount": "0.10000000",
    #'       "productId": "USDT001",
    #'       "subscriptionStartTime": 1661493146000,
    #'       "status": "PURCHASING"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param asset Character or NULL; filter by asset (e.g., `"USDT"`).
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per product and the following columns:
    #' - `asset` (character): Asset symbol (e.g., `"USDT"`).
    #' - `latest_annual_percentage_rate` (character): Current annual yield rate.
    #' - `tier_annual_percentage_rate` (character): JSON-encoded
    #'   per-tier APR map (dynamic keys like `"0-5BTC"`, `"5-10BTC"`).
    #'   Recover via `jsonlite::fromJSON(dt$tier_annual_percentage_rate[1])`.
    #'   `NA` when the field is absent.
    #' - `air_drop_percentage_rate` (character): Air-drop APR if the
    #'   product currently carries one.
    #' - `can_purchase` (logical): Whether new subscriptions are accepted.
    #' - `can_redeem` (logical): Whether redemptions are allowed.
    #' - `is_sold_out` (logical): Whether the product is sold out.
    #' - `hot` (logical): Whether the product is marked as popular.
    #' - `min_purchase_amount` (character): Minimum subscription amount.
    #' - `product_id` (character): Unique product identifier.
    #' - `subscription_start_time` (POSIXct): Subscription start time.
    #' - `status` (character): Product status (e.g., `"PURCHASING"`).
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' products <- earn$get_flexible_products(asset = "USDT")
    #' print(products)
    #' }
    get_flexible_products = function(asset = NULL, current = NULL, size = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/list",
        query = list(
          asset = asset,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          rows <- data$rows
          if (is.null(rows) || length(rows) == 0) {
            return(data.table::data.table()[])
          }
          # `tierAnnualPercentageRate` is a nested object with DYNAMIC
          # keys (e.g. `"0-5BTC": 0.05, "5-10BTC": 0.03`) — different
          # products use different tier breakpoints. Wide-prefixing
          # would produce a sparse soup of columns; instead serialise
          # the whole field as a JSON string so the structure is
          # preserved and recoverable via
          # `jsonlite::fromJSON(dt$tier_annual_percentage_rate[1])`.
          rows <- lapply(rows, function(r) {
            tier <- r[["tierAnnualPercentageRate"]]
            if (is.null(tier) || length(tier) == 0L) {
              r[["tierAnnualPercentageRate"]] <- NA_character_
            } else {
              r[["tierAnnualPercentageRate"]] <- as.character(
                jsonlite::toJSON(tier, auto_unbox = TRUE)
              )
            }
            return(r)
          })
          return(as_dt_list(rows)[])
        }
      ))
    },

    #' @description
    #' Get Locked Products
    #'
    #' Lists available Simple Earn locked products, optionally filtered by asset.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/locked/list`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Locked List](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Simple-Earn-Locked-Product-List)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/list?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' Shape captured 2026-05-22 from the live docs. Binance renamed
    #' `detail.apy` → `detail.apr` and added the extra-reward / boost
    #' fields; older internal examples that still show `apy` are stale.
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "projectId": "BTC30d001",
    #'       "detail": {
    #'         "asset": "BTC",
    #'         "rewardAsset": "BTC",
    #'         "duration": 30,
    #'         "renewable": true,
    #'         "isSoldOut": false,
    #'         "apr": "0.05000000",
    #'         "status": "CREATED",
    #'         "subscriptionStartTime": 1646182276000,
    #'         "extraRewardAsset": "BNB",
    #'         "extraRewardAPR": "0.01000000",
    #'         "boostRewardAsset": "BTC",
    #'         "boostApr": "0.00100000",
    #'         "boostEndTime": 1646182276000
    #'       },
    #'       "quota": {
    #'         "totalPersonalQuota": "10.00000000",
    #'         "minimum": "0.001"
    #'       }
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param asset Character or NULL; filter by asset (e.g., `"BTC"`).
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with **one row per product** and the following
    #'   columns. Nested `detail` and `quota` objects are wide-prefixed
    #'   (`detail_*` and `quota_*`) per the package's "no list columns"
    #'   policy. Field names mirror the current Binance API
    #'   (verified 2026-05-22):
    #' - `project_id` (character): Unique project identifier.
    #' - `detail_asset` (character): Subscription asset (e.g. `"BTC"`).
    #' - `detail_reward_asset` (character): Reward asset.
    #' - `detail_duration` (integer): Lock-up duration in days.
    #' - `detail_renewable` (logical): Whether the product auto-renews.
    #' - `detail_is_sold_out` (logical): Whether the offering is currently
    #'   sold out (no new subscriptions accepted).
    #' - `detail_apr` (character): Annual percentage rate. NOTE: Binance
    #'   renamed this from `apy` → `apr` on the live API; older docs
    #'   that show `apy` are stale.
    #' - `detail_status` (character): Product lifecycle state (e.g.
    #'   `"CREATED"`, `"PURCHASING"`).
    #' - `detail_subscription_start_time` (POSIXct): Subscription open
    #'   timestamp in milliseconds.
    #' - `detail_extra_reward_asset` (character): Additional reward
    #'   asset, if the product carries a boost.
    #' - `detail_extra_reward_apr` (character): Extra reward APR.
    #' - `detail_boost_reward_asset` (character): Boost reward asset.
    #' - `detail_boost_apr` (character): Boost APR.
    #' - `detail_boost_end_time` (POSIXct): Boost end time.
    #' - `quota_total_personal_quota` (character): Per-user maximum.
    #' - `quota_minimum` (character): Per-user minimum.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' products <- earn$get_locked_products(asset = "BTC")
    #' print(products)
    #' }
    get_locked_products = function(asset = NULL, current = NULL, size = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/locked/list",
        query = list(
          asset = asset,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          rows <- data$rows
          if (is.null(rows) || length(rows) == 0) {
            return(data.table::data.table()[])
          }
          # Wide-prefix the nested `detail` and `quota` fixed-schema
          # objects so the returned table has no list columns. Mirrors
          # the alpaca `parse_snapshot` approach for nested objects.
          rows <- lapply(rows, function(r) {
            for (nested in c("detail", "quota")) {
              sub <- r[[nested]]
              if (!is.null(sub) && is.list(sub) && length(sub) > 0) {
                for (nm in names(sub)) {
                  r[[paste0(nested, "_", nm)]] <- sub[[nm]]
                }
              }
              r[[nested]] <- NULL
            }
            return(r)
          })
          dt <- as_dt_list(rows)
          for (col in c("detail_subscription_start_time", "detail_boost_end_time")) {
            if (nrow(dt) > 0 && col %in% names(dt)) {
              data.table::set(dt, j = col, value = ms_to_datetime(dt[[col]]))
            }
          }
          return(dt[])
        }
      ))
    },

    # ---- Subscriptions ----

    #' @description
    #' Subscribe to Flexible Product
    #'
    #' Subscribes to a Simple Earn flexible product.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/simple-earn/flexible/subscribe`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Flexible Subscribe](https://developers.binance.com/docs/simple_earn/flexible-locked/earn)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/flexible/subscribe' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'productId=USDT001&amount=100&timestamp=1661493146000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "productId": "USDT001",
    #'   "amount": "100",
    #'   "autoSubscribe": true,
    #'   "sourceAccount": "SPOT"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "purchaseId": 40607,
    #'   "success": true
    #' }
    #' ```
    #'
    #' @param productId Character; the product ID to subscribe to.
    #' @param amount Numeric; amount to subscribe.
    #' @param autoSubscribe Logical or NULL; whether to enable auto-subscription.
    #' @param sourceAccount Character or NULL; source wallet: `"SPOT"`, `"FUND"`, or `"ALL"`. Default `"SPOT"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `purchase_id` (integer): Unique purchase identifier.
    #' - `success` (logical): Whether the subscription was successful.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' result <- earn$add_flexible_subscription(productId = "USDT001", amount = 100)
    #' print(result)
    #' }
    add_flexible_subscription = function(
      productId,
      amount,
      autoSubscribe = NULL,
      sourceAccount = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/subscribe",
        method = "POST",
        query = list(
          productId = productId,
          amount = as.character(amount),
          autoSubscribe = autoSubscribe,
          sourceAccount = sourceAccount,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Subscribe to Locked Product
    #'
    #' Subscribes to a Simple Earn locked product.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/simple-earn/locked/subscribe`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Locked Subscribe](https://developers.binance.com/docs/simple_earn/flexible-locked/earn/Subscribe-Locked-Product)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/locked/subscribe' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'projectId=BTC30d001&amount=0.01&timestamp=1661493146000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "projectId": "BTC30d001",
    #'   "amount": "0.01",
    #'   "autoSubscribe": true
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "purchaseId": 40608,
    #'   "positionId": "12345",
    #'   "success": true
    #' }
    #' ```
    #'
    #' @param projectId Character; the project ID to subscribe to.
    #' @param amount Numeric; amount to subscribe.
    #' @param autoSubscribe Logical or NULL; whether to enable auto-subscription.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `purchase_id` (integer): Unique purchase identifier.
    #' - `position_id` (character): Position identifier for the locked subscription.
    #' - `success` (logical): Whether the subscription was successful.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' result <- earn$add_locked_subscription(projectId = "BTC30d001", amount = 0.01)
    #' print(result)
    #' }
    add_locked_subscription = function(projectId, amount, autoSubscribe = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/locked/subscribe",
        method = "POST",
        query = list(
          projectId = projectId,
          amount = as.character(amount),
          autoSubscribe = autoSubscribe,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    # ---- Redemptions ----

    #' @description
    #' Redeem Flexible Product
    #'
    #' Redeems from a Simple Earn flexible product.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/simple-earn/flexible/redeem`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Flexible Redeem](https://developers.binance.com/docs/simple_earn/flexible-locked/earn/Redeem-Flexible-Product)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/flexible/redeem' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'productId=USDT001&amount=50&timestamp=1661493146000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "productId": "USDT001",
    #'   "amount": "50",
    #'   "redeemAll": false,
    #'   "destAccount": "SPOT"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "redeemId": 40609,
    #'   "success": true
    #' }
    #' ```
    #'
    #' @param productId Character; the product ID to redeem from.
    #' @param amount Numeric or NULL; amount to redeem. If NULL, use `redeemAll`.
    #' @param redeemAll Logical or NULL; if TRUE, redeem entire position.
    #' @param destAccount Character or NULL; destination wallet: `"SPOT"` or `"FUND"`. Default `"SPOT"`.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `redeem_id` (integer): Unique redemption identifier.
    #' - `success` (logical): Whether the redemption was successful.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' result <- earn$add_flexible_redemption(productId = "USDT001", amount = 50)
    #' print(result)
    #' }
    add_flexible_redemption = function(
      productId,
      amount = NULL,
      redeemAll = NULL,
      destAccount = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/redeem",
        method = "POST",
        query = list(
          productId = productId,
          amount = if (!is.null(amount)) as.character(amount) else NULL,
          redeemAll = redeemAll,
          destAccount = destAccount,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    #' @description
    #' Redeem Locked Product
    #'
    #' Redeems from a Simple Earn locked product.
    #'
    #' ### API Endpoint
    #' `POST https://api.binance.com/sapi/v1/simple-earn/locked/redeem`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Locked Redeem](https://developers.binance.com/docs/simple_earn/flexible-locked/earn/Redeem-Locked-Product)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/locked/redeem' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'positionId=12345&timestamp=1661493146000&signature=...'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "positionId": "12345"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "redeemId": 40610,
    #'   "success": true
    #' }
    #' ```
    #'
    #' @param positionId Character; the position ID to redeem.
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row and the following columns:
    #' - `redeem_id` (integer): Unique redemption identifier.
    #' - `success` (logical): Whether the redemption was successful.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' result <- earn$add_locked_redemption(positionId = "12345")
    #' print(result)
    #' }
    add_locked_redemption = function(positionId, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/locked/redeem",
        method = "POST",
        query = list(
          positionId = positionId,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      ))
    },

    # ---- Positions ----

    #' @description
    #' Get Flexible Position
    #'
    #' Retrieves current flexible earn positions, optionally filtered by asset or product.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/flexible/position`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Flexible Position](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Flexible-Product-Position)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/position?asset=USDT&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' Shape captured 2026-05-22 from the live docs.
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "totalAmount": "75.46000000",
    #'       "tierAnnualPercentageRate": {
    #'         "0-5BTC": 0.05,
    #'         "5-10BTC": 0.03
    #'       },
    #'       "latestAnnualPercentageRate": "0.02599895",
    #'       "yesterdayAirdropPercentageRate": "0.02599895",
    #'       "asset": "USDT",
    #'       "airDropAsset": "BETH",
    #'       "canRedeem": true,
    #'       "collateralAmount": "232.23123213",
    #'       "productId": "USDT001",
    #'       "yesterdayRealTimeRewards": "0.10293829",
    #'       "cumulativeBonusRewards": "0.22759183",
    #'       "cumulativeRealTimeRewards": "0.22759183",
    #'       "cumulativeTotalRewards": "0.45459183",
    #'       "autoSubscribe": true
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param asset Character or NULL; filter by asset (e.g., `"USDT"`).
    #' @param productId Character or NULL; filter by product ID.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per position and the following columns:
    #' - `total_amount` (character): Total amount in the position.
    #' - `latest_annual_percentage_rate` (character): Current annual yield rate.
    #' - `tier_annual_percentage_rate` (character, optional):
    #'   JSON-encoded per-tier APR map when the position carries
    #'   tier-based rates (dynamic keys like `"0-5BTC"`). Recover via
    #'   `jsonlite::fromJSON(dt$tier_annual_percentage_rate[1])`.
    #' - `yesterday_airdrop_percentage_rate` (character): Air-drop APR
    #'   for the previous accrual period.
    #' - `asset` (character): Asset symbol (e.g., `"USDT"`).
    #' - `air_drop_asset` (character): Asset paid as an air-drop reward,
    #'   if any.
    #' - `can_redeem` (logical): Whether redemption is allowed.
    #' - `collateral_amount` (character): Amount currently locked as
    #'   collateral, if the position is being used as such.
    #' - `product_id` (character): Product identifier.
    #' - `yesterday_real_time_rewards` (character): Real-time rewards
    #'   accrued in the previous period.
    #' - `cumulative_bonus_rewards` (character): Cumulative bonus
    #'   rewards earned on this position.
    #' - `cumulative_real_time_rewards` (character): Cumulative
    #'   real-time rewards.
    #' - `cumulative_total_rewards` (character): Cumulative total
    #'   rewards (bonus + real-time).
    #' - `auto_subscribe` (logical): Whether auto-subscription is enabled.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' positions <- earn$get_flexible_position(asset = "USDT")
    #' print(positions)
    #' }
    get_flexible_position = function(asset = NULL, productId = NULL, current = NULL, size = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/position",
        query = list(
          asset = asset,
          productId = productId,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          rows <- data$rows
          if (is.null(rows) || length(rows) == 0) {
            return(data.table::data.table()[])
          }
          # `tierAnnualPercentageRate` can appear on position rows too;
          # same treatment as `get_flexible_products` — JSON-encode so
          # dynamic tier keys are preserved.
          rows <- lapply(rows, function(r) {
            tier <- r[["tierAnnualPercentageRate"]]
            if (!is.null(tier) && length(tier) > 0L) {
              r[["tierAnnualPercentageRate"]] <- as.character(
                jsonlite::toJSON(tier, auto_unbox = TRUE)
              )
            } else if (!is.null(tier)) {
              r[["tierAnnualPercentageRate"]] <- NA_character_
            }
            return(r)
          })
          dt <- as_dt_list(rows)
          if (nrow(dt) > 0 && "subscription_start_time" %in% names(dt)) {
            dt[, subscription_start_time := ms_to_datetime(subscription_start_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Locked Position
    #'
    #' Retrieves current locked earn positions, optionally filtered by asset,
    #' position ID, or project ID.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/locked/position`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Locked Position](https://developers.binance.com/docs/simple_earn/flexible-locked/account/Get-Locked-Product-Position)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/position?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' Shape captured 2026-05-22 from the live docs. NOTE: Binance
    #' returns the rate as uppercase `APY` (not `apy`); our snake_case
    #' converter lowers it to `apy` in the data.table.
    #' ```json
    #' {
    #'   "rows": [
    #'     {
    #'       "positionId": 123123,
    #'       "parentPositionId": 123122,
    #'       "projectId": "Axs*90",
    #'       "asset": "AXS",
    #'       "amount": "122.09202928",
    #'       "purchaseTime": 1646182276000,
    #'       "duration": "60",
    #'       "accrualDays": "4",
    #'       "rewardAsset": "AXS",
    #'       "APY": "0.2032",
    #'       "rewardAmt": "5.17181528",
    #'       "extraRewardAsset": "BNB",
    #'       "extraRewardAPR": "0.0203",
    #'       "estExtraRewardAmt": "5.17181528",
    #'       "boostRewardAsset": "AXS",
    #'       "boostApr": "0.0121",
    #'       "totalBoostRewardAmt": "3.98201829",
    #'       "nextPay": "1.29295383",
    #'       "nextPayDate": 1646697600000,
    #'       "payPeriod": "1",
    #'       "redeemAmountEarly": "2802.24068892",
    #'       "rewardsEndDate": 1651449600000,
    #'       "deliverDate": 1651536000000,
    #'       "redeemPeriod": "1",
    #'       "redeemingAmt": "232.2323",
    #'       "redeemTo": "FLEXIBLE",
    #'       "partialAmtDeliverDate": 1651536000000,
    #'       "canRedeemEarly": true,
    #'       "canFastRedemption": true,
    #'       "autoSubscribe": true,
    #'       "type": "AUTO",
    #'       "status": "HOLDING",
    #'       "canReStake": true
    #'     }
    #'   ],
    #'   "total": 1
    #' }
    #' ```
    #'
    #' @param asset Character or NULL; filter by asset (e.g., `"BTC"`).
    #' @param positionId Character or NULL; filter by position ID.
    #' @param projectId Character or NULL; filter by project ID.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per position and the following columns
    #'   (snake-case names; Binance's uppercase `APY` lowers to `apy`):
    #' - `position_id` (numeric): Locked position identifier.
    #' - `parent_position_id` (numeric): Parent position identifier
    #'   (cross-reference for auto-renewed positions).
    #' - `project_id` (character): Locked project identifier.
    #' - `asset` (character): Locked asset symbol.
    #' - `amount` (character): Locked amount.
    #' - `purchase_time` (POSIXct): Subscription time.
    #' - `duration` (character): Lock duration in days.
    #' - `accrual_days` (character): Days interest has accrued.
    #' - `reward_asset` (character): Earned asset symbol.
    #' - `apy` (character): Annual percentage yield (snake_case of `APY`).
    #' - `reward_amt` (character): Earned amount so far.
    #' - `extra_reward_asset` (character): Asset for the extra staking
    #'   reward, if any.
    #' - `extra_reward_apr` (character): APR of the extra staking reward.
    #' - `est_extra_reward_amt` (character): Estimated extra reward
    #'   distributed at maturity.
    #' - `boost_reward_asset` (character): Boost reward asset.
    #' - `boost_apr` (character): Boost APR.
    #' - `total_boost_reward_amt` (character): Total boost reward earned.
    #' - `next_pay` (character): Next estimated reward payment.
    #' - `next_pay_date` (POSIXct): Next reward payment time.
    #' - `pay_period` (character): Payment cycle in days.
    #' - `redeem_amount_early` (character): Amount available for early
    #'   redemption.
    #' - `rewards_end_date` (POSIXct): Rewards accrual end time.
    #' - `deliver_date` (POSIXct): Redemption arrival time.
    #' - `redeem_period` (character): Redemption interval in days.
    #' - `redeeming_amt` (character): Amount currently being redeemed.
    #' - `redeem_to` (character): Destination on redemption
    #'   (`"FLEXIBLE"` or `"SPOT"`).
    #' - `partial_amt_deliver_date` (POSIXct): Arrival time of partial
    #'   redemption.
    #' - `can_redeem_early` (logical): Whether early redemption is allowed.
    #' - `can_fast_redemption` (logical): Whether fast redemption is allowed.
    #' - `auto_subscribe` (logical): Whether auto-subscription is enabled.
    #' - `type` (character): Order type (`"AUTO"` or `"NORMAL"`).
    #' - `status` (character): Position status (e.g., `"HOLDING"`).
    #' - `can_re_stake` (logical): Whether re-staking is available.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' positions <- earn$get_locked_position(asset = "BTC")
    #' print(positions)
    #' }
    get_locked_position = function(
      asset = NULL,
      positionId = NULL,
      projectId = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/locked/position",
        query = list(
          asset = asset,
          positionId = positionId,
          projectId = projectId,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(parse_paginated(
            data,
            time_cols = c(
              "purchase_time",
              "next_pay_date",
              "rewards_end_date",
              "deliver_date",
              "partial_amt_deliver_date"
            )
          )[])
        }
      ))
    },

    # ---- History ----

    #' @description
    #' Get Flexible Subscription History
    #'
    #' Retrieves subscription history for flexible earn products.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/flexible/history/subscriptionRecord`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Flexible Subscription Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/history/subscriptionRecord?asset=USDT&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "amount": "100.00000000",
    #'       "asset": "USDT",
    #'       "time": 1661493146000,
    #'       "purchaseId": 40607,
    #'       "type": "AUTO",
    #'       "sourceAccount": "SPOT",
    #'       "status": "SUCCESS"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param productId Character or NULL; filter by product ID.
    #' @param purchaseId Integer or NULL; filter by purchase ID.
    #' @param asset Character or NULL; filter by asset (e.g., `"USDT"`).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per subscription record and the following columns:
    #' - `amount` (character): Subscription amount.
    #' - `asset` (character): Asset symbol.
    #' - `time` (POSIXct): Subscription time.
    #' - `purchase_id` (integer): Purchase identifier.
    #' - `type` (character): Subscription type (e.g., `"AUTO"`, `"NORMAL"`).
    #' - `source_account` (character): Source account (e.g., `"SPOT"`).
    #' - `status` (character): Subscription status (e.g., `"SUCCESS"`).
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' history <- earn$get_flexible_subscription_history(asset = "USDT")
    #' print(history)
    #' }
    get_flexible_subscription_history = function(
      productId = NULL,
      purchaseId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/history/subscriptionRecord",
        query = list(
          productId = productId,
          purchaseId = purchaseId,
          asset = asset,
          startTime = startTime,
          endTime = endTime,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(parse_paginated(data, time_cols = "time")[])
        }
      ))
    },

    #' @description
    #' Get Locked Subscription History
    #'
    #' Retrieves subscription history for locked earn products.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/locked/history/subscriptionRecord`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Locked Subscription Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history/Get-Locked-Subscription-Record)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/history/subscriptionRecord?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "amount": "0.01000000",
    #'       "asset": "BTC",
    #'       "time": 1661493146000,
    #'       "purchaseId": 40608,
    #'       "positionId": "12345",
    #'       "lockPeriod": 30,
    #'       "type": "NORMAL",
    #'       "sourceAccount": "SPOT",
    #'       "status": "SUCCESS"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param purchaseId Integer or NULL; filter by purchase ID.
    #' @param asset Character or NULL; filter by asset (e.g., `"BTC"`).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per subscription record and the following columns:
    #' - `amount` (character): Subscription amount.
    #' - `asset` (character): Asset symbol.
    #' - `time` (POSIXct): Subscription time.
    #' - `purchase_id` (integer): Purchase identifier.
    #' - `position_id` (character): Position identifier.
    #' - `lock_period` (integer): Lock duration in days.
    #' - `type` (character): Subscription type.
    #' - `source_account` (character): Source account.
    #' - `status` (character): Subscription status.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' history <- earn$get_locked_subscription_history(asset = "BTC")
    #' print(history)
    #' }
    get_locked_subscription_history = function(
      purchaseId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/locked/history/subscriptionRecord",
        query = list(
          purchaseId = purchaseId,
          asset = asset,
          startTime = startTime,
          endTime = endTime,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(parse_paginated(data, time_cols = "time")[])
        }
      ))
    },

    #' @description
    #' Get Flexible Redemption History
    #'
    #' Retrieves redemption history for flexible earn products.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/flexible/history/redemptionRecord`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Flexible Redemption Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history/Get-Flexible-Redemption-Record)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/history/redemptionRecord?asset=USDT&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "amount": "50.00000000",
    #'       "asset": "USDT",
    #'       "time": 1661493146000,
    #'       "projectId": "USDT001",
    #'       "redeemId": 40609,
    #'       "destAccount": "SPOT",
    #'       "status": "PAID"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param productId Character or NULL; filter by product ID.
    #' @param redeemId Integer or NULL; filter by redeem ID.
    #' @param asset Character or NULL; filter by asset (e.g., `"USDT"`).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per redemption record and the following columns:
    #' - `amount` (character): Redemption amount.
    #' - `asset` (character): Asset symbol.
    #' - `time` (POSIXct): Redemption time.
    #' - `project_id` (character): Product identifier.
    #' - `redeem_id` (integer): Redemption identifier.
    #' - `dest_account` (character): Destination account.
    #' - `status` (character): Redemption status (e.g., `"PAID"`).
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' history <- earn$get_flexible_redemption_history(asset = "USDT")
    #' print(history)
    #' }
    get_flexible_redemption_history = function(
      productId = NULL,
      redeemId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/history/redemptionRecord",
        query = list(
          productId = productId,
          redeemId = redeemId,
          asset = asset,
          startTime = startTime,
          endTime = endTime,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(parse_paginated(data, time_cols = "time")[])
        }
      ))
    },

    #' @description
    #' Get Locked Redemption History
    #'
    #' Retrieves redemption history for locked earn products.
    #'
    #' ### API Endpoint
    #' `GET https://api.binance.com/sapi/v1/simple-earn/locked/history/redemptionRecord`
    #'
    #' ### Official Documentation
    #' [Binance Simple Earn Locked Redemption Record](https://developers.binance.com/docs/simple_earn/flexible-locked/history/Get-Locked-Redemption-Record)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/history/redemptionRecord?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "amount": "0.01000000",
    #'       "asset": "BTC",
    #'       "time": 1661493146000,
    #'       "positionId": "12345",
    #'       "redeemId": 40610,
    #'       "deliverDate": 1664085146000,
    #'       "status": "PAID"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param positionId Character or NULL; filter by position ID.
    #' @param redeemId Integer or NULL; filter by redeem ID.
    #' @param asset Character or NULL; filter by asset (e.g., `"BTC"`).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per redemption record and the following columns:
    #' - `amount` (character): Redemption amount.
    #' - `asset` (character): Asset symbol.
    #' - `time` (POSIXct): Redemption time.
    #' - `position_id` (character): Position identifier.
    #' - `redeem_id` (integer): Redemption identifier.
    #' - `deliver_date` (POSIXct): Expected delivery time.
    #' - `status` (character): Redemption status.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' history <- earn$get_locked_redemption_history(asset = "BTC")
    #' print(history)
    #' }
    get_locked_redemption_history = function(
      positionId = NULL,
      redeemId = NULL,
      asset = NULL,
      startTime = NULL,
      endTime = NULL,
      current = NULL,
      size = NULL,
      recvWindow = NULL
    ) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/locked/history/redemptionRecord",
        query = list(
          positionId = positionId,
          redeemId = redeemId,
          asset = asset,
          startTime = startTime,
          endTime = endTime,
          current = current,
          size = size,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(parse_paginated(data, time_cols = c("time", "deliver_date"))[])
        }
      ))
    }
  )
)
