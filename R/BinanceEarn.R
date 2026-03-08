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
    #' [Binance Simple Earn Flexible List](https://developers.binance.com/docs/simple_earn/account/Get-Simple-Earn-Flexible-Product-List)
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
    #' @return `data.table` with one row per product. Columns depend on API response
    #'   and are converted to snake_case. Returns empty `data.table` if no products found.
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
          return(parse_paginated(data))
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
    #' [Binance Simple Earn Locked List](https://developers.binance.com/docs/simple_earn/account/Get-Simple-Earn-Locked-Product-List)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/list?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
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
    #'         "apy": "0.05000000"
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
    #' @return `data.table` with one row per product. Columns depend on API response
    #'   and are converted to snake_case. Returns empty `data.table` if no products found.
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
          return(parse_paginated(data))
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
    #' [Binance Simple Earn Flexible Subscribe](https://developers.binance.com/docs/simple_earn/earn/Subscribe-Flexible-Product)
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/flexible/subscribe' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'productId=USDT001&amount=100&timestamp=1661493146000&signature=...'
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
    add_flexible_subscription = function(productId, amount, autoSubscribe = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/subscribe",
        method = "POST",
        query = list(
          productId = productId,
          amount = as.character(amount),
          autoSubscribe = autoSubscribe,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data))
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
    #' [Binance Simple Earn Locked Subscribe](https://developers.binance.com/docs/simple_earn/earn/Subscribe-Locked-Product)
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/locked/subscribe' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'projectId=BTC30d001&amount=0.01&timestamp=1661493146000&signature=...'
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
          return(as_dt_row(data))
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
    #' [Binance Simple Earn Flexible Redeem](https://developers.binance.com/docs/simple_earn/earn/Redeem-Flexible-Product)
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/flexible/redeem' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'productId=USDT001&amount=50&timestamp=1661493146000&signature=...'
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
    add_flexible_redemption = function(productId, amount = NULL, redeemAll = NULL, recvWindow = NULL) {
      return(private$.request(
        endpoint = "/sapi/v1/simple-earn/flexible/redeem",
        method = "POST",
        query = list(
          productId = productId,
          amount = if (!is.null(amount)) as.character(amount) else NULL,
          redeemAll = redeemAll,
          recvWindow = recvWindow
        ),
        .parser = function(data) {
          return(as_dt_row(data))
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
    #' [Binance Simple Earn Locked Redeem](https://developers.binance.com/docs/simple_earn/earn/Redeem-Locked-Product)
    #'
    #' ### curl
    #' ```
    #' curl -X POST 'https://api.binance.com/sapi/v1/simple-earn/locked/redeem' \
    #'   -H 'X-MBX-APIKEY: your-api-key' \
    #'   -d 'positionId=12345&timestamp=1661493146000&signature=...'
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
          return(as_dt_row(data))
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
    #' [Binance Simple Earn Flexible Position](https://developers.binance.com/docs/simple_earn/account/Get-Flexible-Product-Position)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/position?asset=USDT&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "total": 1,
    #'   "rows": [
    #'     {
    #'       "totalAmount": "100.00000000",
    #'       "latestAnnualPercentageRate": "0.03250000",
    #'       "asset": "USDT",
    #'       "canRedeem": true,
    #'       "productId": "USDT001",
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
    #' @return `data.table` with one row per position. Columns depend on API response
    #'   and are converted to snake_case. Returns empty `data.table` if no positions found.
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
          return(parse_paginated(data))
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
    #' [Binance Simple Earn Locked Position](https://developers.binance.com/docs/simple_earn/account/Get-Locked-Product-Position)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/position?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' @param asset Character or NULL; filter by asset (e.g., `"BTC"`).
    #' @param positionId Character or NULL; filter by position ID.
    #' @param projectId Character or NULL; filter by project ID.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per position. Columns depend on API response
    #'   and are converted to snake_case. Returns empty `data.table` if no positions found.
    #'
    #' @examples
    #' \dontrun{
    #' earn <- BinanceEarn$new()
    #' positions <- earn$get_locked_position(asset = "BTC")
    #' print(positions)
    #' }
    get_locked_position = function(asset = NULL, positionId = NULL, projectId = NULL, current = NULL, size = NULL, recvWindow = NULL) {
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
          return(parse_paginated(data))
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
    #' [Binance Simple Earn Flexible Subscription Record](https://developers.binance.com/docs/simple_earn/history/Get-Flexible-Subscription-Record)
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
    #' @return `data.table` with one row per subscription record. The `time` column
    #'   is converted to POSIXct. Returns empty `data.table` if no records found.
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
          return(parse_paginated(data, time_cols = "time"))
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
    #' [Binance Simple Earn Locked Subscription Record](https://developers.binance.com/docs/simple_earn/history/Get-Locked-Subscription-Record)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/history/subscriptionRecord?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
    #' ```
    #'
    #' @param purchaseId Integer or NULL; filter by purchase ID.
    #' @param asset Character or NULL; filter by asset (e.g., `"BTC"`).
    #' @param startTime Integer or NULL; start timestamp in milliseconds.
    #' @param endTime Integer or NULL; end timestamp in milliseconds.
    #' @param current Integer or NULL; current page (default 1, starting from 1).
    #' @param size Integer or NULL; page size (default 10, max 100).
    #' @param recvWindow Integer or NULL; max 60000.
    #' @return `data.table` with one row per subscription record. The `time` column
    #'   is converted to POSIXct. Returns empty `data.table` if no records found.
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
          return(parse_paginated(data, time_cols = "time"))
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
    #' [Binance Simple Earn Flexible Redemption Record](https://developers.binance.com/docs/simple_earn/history/Get-Flexible-Redemption-Record)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/flexible/history/redemptionRecord?asset=USDT&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
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
    #' @return `data.table` with one row per redemption record. The `time` column
    #'   is converted to POSIXct. Returns empty `data.table` if no records found.
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
          return(parse_paginated(data, time_cols = "time"))
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
    #' [Binance Simple Earn Locked Redemption Record](https://developers.binance.com/docs/simple_earn/history/Get-Locked-Redemption-Record)
    #'
    #' ### curl
    #' ```
    #' curl -X GET 'https://api.binance.com/sapi/v1/simple-earn/locked/history/redemptionRecord?asset=BTC&timestamp=1661493146000&signature=...' \
    #'   -H 'X-MBX-APIKEY: your-api-key'
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
    #' @return `data.table` with one row per redemption record. The `time` column
    #'   is converted to POSIXct. Returns empty `data.table` if no records found.
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
          return(parse_paginated(data, time_cols = "time"))
        }
      ))
    }
  )
)
