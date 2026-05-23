# tests/testthat/test-BinanceEarn.R
# Tests for BinanceEarn R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_earn <- function() {
  return(BinanceEarn$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("BinanceEarn inherits from BinanceBase", {
  e <- new_earn()
  expect_s3_class(e, "BinanceEarn")
  expect_s3_class(e, "BinanceBase")
})

# -- get_flexible_products --

test_that("get_flexible_products returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_flexible_products_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_products()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("asset" %in% names(dt))
  expect_true("product_id" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_equal(dt$asset, "USDT")
  expect_equal(dt$product_id, "USDT001")

  # tierAnnualPercentageRate has dynamic keys — preserved as JSON string,
  # not list-column. Recover via jsonlite::fromJSON.
  expect_true("tier_annual_percentage_rate" %in% names(dt))
  expect_type(dt$tier_annual_percentage_rate, "character")
  recovered <- jsonlite::fromJSON(dt$tier_annual_percentage_rate)
  expect_equal(recovered$`0-5BTC`, 0.05)
  expect_equal(recovered$`5-10BTC`, 0.03)

  # No list columns anywhere.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("get_flexible_products hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_flexible_products_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_flexible_products(asset = "USDT")
  expect_true(grepl("sapi/v1/simple-earn/flexible/list", captured_url))
  expect_true(grepl("asset=USDT", captured_url))
})

test_that("get_flexible_products passes pagination parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_flexible_products_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_flexible_products(current = 1, size = 50)
  expect_true(grepl("current=1", captured_url))
  expect_true(grepl("size=50", captured_url))
})

test_that("get_flexible_products returns empty data.table when no products", {
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_products()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_flexible_products emits NA tier_annual_percentage_rate when upstream omits it", {
  # Regression: the JSON-encode branch in the parser sets the field to
  # NA_character_ when `tierAnnualPercentageRate` is missing/empty.
  # Without a fixture variant that omits the field, this empty branch
  # is dead code in tests.
  data <- mock_flexible_products_data()
  data$rows[[1]]$tierAnnualPercentageRate <- NULL
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_products()
  expect_equal(nrow(dt), 1L)
  expect_true("tier_annual_percentage_rate" %in% names(dt))
  expect_true(is.na(dt$tier_annual_percentage_rate))
  expect_type(dt$tier_annual_percentage_rate, "character")
  # Still no list columns.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

# -- get_locked_products --

test_that("get_locked_products returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_locked_products_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_locked_products()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("project_id" %in% names(dt))
  expect_equal(dt$project_id, "BTC30d001")
})

test_that("get_locked_products wide-prefixes nested detail/quota (no list columns)", {
  resp <- mock_binance_response(data = mock_locked_products_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_locked_products()

  # No list columns anywhere — nested objects are flattened.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)

  # Detail object wide-prefixed. Field set tracks current Binance API
  # (verified 2026-05-22): `apr` not `apy`, plus extra-reward / boost
  # fields.
  expect_true(all(
    c(
      "detail_asset",
      "detail_reward_asset",
      "detail_duration",
      "detail_renewable",
      "detail_is_sold_out",
      "detail_apr",
      "detail_status",
      "detail_subscription_start_time",
      "detail_extra_reward_asset",
      "detail_extra_reward_apr",
      "detail_boost_reward_asset",
      "detail_boost_apr",
      "detail_boost_end_time"
    ) %in%
      names(dt)
  ))
  expect_equal(dt$detail_asset, "BTC")
  expect_equal(dt$detail_reward_asset, "BTC")
  expect_equal(dt$detail_duration, 30L)
  expect_true(dt$detail_renewable)
  expect_false(dt$detail_is_sold_out)
  expect_equal(dt$detail_apr, "0.05000000")
  expect_equal(dt$detail_status, "CREATED")
  expect_equal(dt$detail_extra_reward_asset, "BNB")
  expect_equal(dt$detail_boost_apr, "0.00100000")

  # Quota object wide-prefixed.
  expect_true(all(
    c("quota_total_personal_quota", "quota_minimum") %in% names(dt)
  ))
  expect_equal(dt$quota_total_personal_quota, "10.00000000")
  expect_equal(dt$quota_minimum, "0.001")

  # Raw nested fields are gone.
  expect_false("detail" %in% names(dt))
  expect_false("quota" %in% names(dt))

  # ms timestamps inside `detail` are now POSIXct (regression — were
  # numeric ms in 0.1.0).
  expect_s3_class(dt$detail_subscription_start_time, "POSIXct")
  expect_s3_class(dt$detail_boost_end_time, "POSIXct")
})

test_that("get_locked_products hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_locked_products_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_locked_products(asset = "BTC")
  expect_true(grepl("sapi/v1/simple-earn/locked/list", captured_url))
  expect_true(grepl("asset=BTC", captured_url))
})

# -- add_flexible_subscription --

test_that("add_flexible_subscription returns data.table with purchase_id and success", {
  resp <- mock_binance_response(data = mock_flexible_subscribe_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$add_flexible_subscription(productId = "USDT001", amount = 100)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("purchase_id" %in% names(dt))
  expect_true("success" %in% names(dt))
  expect_equal(dt$purchase_id, 40607L)
  expect_true(dt$success)
})

test_that("add_flexible_subscription hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_flexible_subscribe_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_earn()$add_flexible_subscription(productId = "USDT001", amount = 100)
  expect_true(grepl("sapi/v1/simple-earn/flexible/subscribe", captured_url))
  expect_equal(captured_method, "POST")
})

test_that("add_flexible_subscription converts amount to character in query", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_flexible_subscribe_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$add_flexible_subscription(productId = "USDT001", amount = 100.5)
  expect_true(grepl("amount=100.5", captured_url))
  expect_true(grepl("productId=USDT001", captured_url))
})

# -- add_locked_subscription --

test_that("add_locked_subscription returns data.table with position_id", {
  resp <- mock_binance_response(data = mock_locked_subscribe_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$add_locked_subscription(projectId = "BTC30d001", amount = 0.01)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("purchase_id" %in% names(dt))
  expect_true("position_id" %in% names(dt))
  expect_true("success" %in% names(dt))
  expect_equal(dt$position_id, "12345")
})

test_that("add_locked_subscription hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_locked_subscribe_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_earn()$add_locked_subscription(projectId = "BTC30d001", amount = 0.01)
  expect_true(grepl("sapi/v1/simple-earn/locked/subscribe", captured_url))
  expect_equal(captured_method, "POST")
})

# -- add_flexible_redemption --

test_that("add_flexible_redemption returns data.table with redeem_id and success", {
  resp <- mock_binance_response(data = mock_flexible_redeem_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$add_flexible_redemption(productId = "USDT001", amount = 50)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("redeem_id" %in% names(dt))
  expect_true("success" %in% names(dt))
  expect_equal(dt$redeem_id, 40609L)
  expect_true(dt$success)
})

test_that("add_flexible_redemption hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_flexible_redeem_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_earn()$add_flexible_redemption(productId = "USDT001", amount = 50)
  expect_true(grepl("sapi/v1/simple-earn/flexible/redeem", captured_url))
  expect_equal(captured_method, "POST")
})

test_that("add_flexible_redemption converts amount to character if provided", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_flexible_redeem_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$add_flexible_redemption(productId = "USDT001", amount = 25.5)
  expect_true(grepl("amount=25.5", captured_url))
})

test_that("add_flexible_redemption works with redeemAll instead of amount", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_flexible_redeem_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$add_flexible_redemption(productId = "USDT001", redeemAll = TRUE)
  expect_true(grepl("redeemAll=TRUE", captured_url))
  expect_false(grepl("amount=", captured_url))
})

# -- add_locked_redemption --

test_that("add_locked_redemption returns data.table with redeem_id", {
  resp <- mock_binance_response(data = mock_locked_redeem_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$add_locked_redemption(positionId = "12345")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("redeem_id" %in% names(dt))
  expect_equal(dt$redeem_id, 40610L)
})

test_that("add_locked_redemption hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_locked_redeem_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    return(resp)
  })

  new_earn()$add_locked_redemption(positionId = "12345")
  expect_true(grepl("sapi/v1/simple-earn/locked/redeem", captured_url))
  expect_equal(captured_method, "POST")
})

# -- get_flexible_position --

test_that("get_flexible_position returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_flexible_position_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_position()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("total_amount" %in% names(dt))
  expect_true("asset" %in% names(dt))
  expect_true("product_id" %in% names(dt))
  expect_true("can_redeem" %in% names(dt))
  expect_true("auto_subscribe" %in% names(dt))
  expect_equal(dt$asset, "USDT")
  expect_equal(dt$product_id, "USDT001")
  # Reward / collateral / airdrop fields surfaced.
  expect_true("yesterday_airdrop_percentage_rate" %in% names(dt))
  expect_true("air_drop_asset" %in% names(dt))
  expect_true("collateral_amount" %in% names(dt))
  expect_true("cumulative_total_rewards" %in% names(dt))
  # tier_annual_percentage_rate: mock has it as `list()` (empty) — the
  # JSON-encode branch converts that to NA_character_ for schema
  # stability. Without this assertion the empty-branch is dead code.
  expect_true("tier_annual_percentage_rate" %in% names(dt))
  expect_true(is.na(dt$tier_annual_percentage_rate))
  expect_type(dt$tier_annual_percentage_rate, "character")
  # No list columns.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("get_flexible_position JSON-encodes populated tierAnnualPercentageRate", {
  data <- mock_flexible_position_data()
  data$rows[[1]]$tierAnnualPercentageRate <- list(
    "0-5BTC" = 0.05,
    "5-10BTC" = 0.03
  )
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_position()
  expect_equal(nrow(dt), 1L)
  expect_type(dt$tier_annual_percentage_rate, "character")
  recovered <- jsonlite::fromJSON(dt$tier_annual_percentage_rate)
  expect_equal(recovered$`0-5BTC`, 0.05)
  expect_equal(recovered$`5-10BTC`, 0.03)
})

test_that("get_flexible_position hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_flexible_position_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_flexible_position(asset = "USDT", productId = "USDT001")
  expect_true(grepl("sapi/v1/simple-earn/flexible/position", captured_url))
  expect_true(grepl("asset=USDT", captured_url))
  expect_true(grepl("productId=USDT001", captured_url))
})

test_that("get_flexible_position returns empty data.table when no positions", {
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_position()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_flexible_position converts subscription_start_time to POSIXct (regression)", {
  # Was numeric ms in 0.1.0. Patch the default fixture to include the
  # field so the conversion is exercised.
  data <- mock_flexible_position_data()
  data$rows[[1]]$subscriptionStartTime <- 1646182276000
  resp <- mock_binance_response(data = data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_position()
  expect_true("subscription_start_time" %in% names(dt))
  expect_s3_class(dt$subscription_start_time, "POSIXct")
})

# -- get_locked_position --

test_that("get_locked_position converts purchase_time / next_pay_date / rewards_end_date / deliver_date / partial_amt_deliver_date to POSIXct (regression)", {
  # All five were numeric ms in 0.1.0.
  resp <- mock_binance_response(
    data = list(
      total = 1L,
      rows = list(
        list(
          positionId = 12345L,
          projectId = "BTC30d001",
          asset = "BTC",
          amount = "0.10000000",
          purchaseTime = 1646182276000,
          duration = 30L,
          nextPayDate = 1646697600000,
          rewardsEndDate = 1648824276000,
          deliverDate = 1649084276000,
          partialAmtDeliverDate = 1648824276000
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_locked_position(asset = "BTC")
  for (col in c("purchase_time", "next_pay_date", "rewards_end_date", "deliver_date", "partial_amt_deliver_date")) {
    expect_true(col %in% names(dt), info = paste("missing column:", col))
    expect_s3_class(dt[[col]], "POSIXct")
  }
})

test_that("get_locked_position hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_locked_position(asset = "BTC", positionId = "12345")
  expect_true(grepl("sapi/v1/simple-earn/locked/position", captured_url))
  expect_true(grepl("asset=BTC", captured_url))
  expect_true(grepl("positionId=12345", captured_url))
})

# -- get_flexible_subscription_history --

test_that("get_flexible_subscription_history returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_flexible_subscription_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_subscription_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("amount" %in% names(dt))
  expect_true("asset" %in% names(dt))
  expect_true("time" %in% names(dt))
  expect_true("purchase_id" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_equal(dt$asset, "USDT")
  expect_equal(dt$status, "SUCCESS")
})

test_that("get_flexible_subscription_history converts time to POSIXct", {
  resp <- mock_binance_response(data = mock_flexible_subscription_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_subscription_history()
  expect_true("time" %in% names(dt))
  expect_s3_class(dt$time, "POSIXct")
})

test_that("get_flexible_subscription_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_flexible_subscription_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_flexible_subscription_history(asset = "USDT", startTime = 1661493146000, endTime = 1661593146000)
  expect_true(grepl("sapi/v1/simple-earn/flexible/history/subscriptionRecord", captured_url))
  expect_true(grepl("asset=USDT", captured_url))
  expect_true(grepl("startTime=1661493146000", captured_url))
  expect_true(grepl("endTime=1661593146000", captured_url))
})

test_that("get_flexible_subscription_history returns empty data.table when no records", {
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_flexible_subscription_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_locked_subscription_history --

test_that("get_locked_subscription_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_locked_subscription_history(asset = "BTC", current = 1, size = 10)
  expect_true(grepl("sapi/v1/simple-earn/locked/history/subscriptionRecord", captured_url))
  expect_true(grepl("asset=BTC", captured_url))
})

# -- get_flexible_redemption_history --

test_that("get_flexible_redemption_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_flexible_redemption_history(productId = "USDT001", asset = "USDT")
  expect_true(grepl("sapi/v1/simple-earn/flexible/history/redemptionRecord", captured_url))
  expect_true(grepl("productId=USDT001", captured_url))
  expect_true(grepl("asset=USDT", captured_url))
})

# -- get_locked_redemption_history --

test_that("get_locked_redemption_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(total = 0L, rows = list()))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_earn()$get_locked_redemption_history(positionId = "12345", asset = "BTC")
  expect_true(grepl("sapi/v1/simple-earn/locked/history/redemptionRecord", captured_url))
  expect_true(grepl("positionId=12345", captured_url))
  expect_true(grepl("asset=BTC", captured_url))
})

test_that("get_locked_redemption_history converts deliver_date to POSIXct (regression)", {
  # Was documented as character "Expected delivery date" in 0.1.0 but
  # Binance actually returns a numeric ms timestamp. Now parsed as POSIXct.
  resp <- mock_binance_response(
    data = list(
      total = 1L,
      rows = list(
        list(
          amount = "0.01000000",
          asset = "BTC",
          time = 1661493146000,
          positionId = "12345",
          redeemId = 40610L,
          deliverDate = 1664085146000,
          status = "PAID"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_earn()$get_locked_redemption_history()
  expect_true("deliver_date" %in% names(dt))
  expect_s3_class(dt$deliver_date, "POSIXct")
  expect_s3_class(dt$time, "POSIXct")
})
