# tests/testthat/test-BinanceSubAccount.R
# Tests for BinanceSubAccount R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_sub <- function() {
  BinanceSubAccount$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceSubAccount inherits from BinanceBase", {
  s <- new_sub()
  expect_s3_class(s, "BinanceSubAccount")
  expect_s3_class(s, "BinanceBase")
})

# -- add_sub_account --

test_that("add_sub_account returns data.table with email", {
  resp <- mock_binance_response(data = mock_sub_account_create_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$add_sub_account(subAccountString = "testsub01")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("email" %in% names(dt))
  expect_equal(dt$email, "testsub01@virtual.com")
})

test_that("add_sub_account hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_sub_account_create_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    resp
  })

  new_sub()$add_sub_account(subAccountString = "testsub01")
  expect_true(grepl("sapi/v1/sub-account/virtualSubAccount", captured_url))
  expect_equal(captured_method, "POST")
})

# -- get_sub_accounts --

test_that("get_sub_accounts returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_sub_account_list_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_sub_accounts()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("email" %in% names(dt))
  expect_true("is_freeze" %in% names(dt))
  expect_true("create_time" %in% names(dt))
  expect_true("is_managed_sub_account" %in% names(dt))
  expect_true("is_asset_management_sub_account" %in% names(dt))
  expect_equal(dt$email[1], "testsub01@virtual.com")
  expect_equal(dt$email[2], "testsub02@virtual.com")
})

test_that("get_sub_accounts converts create_time to POSIXct", {
  resp <- mock_binance_response(data = mock_sub_account_list_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_sub_accounts()
  expect_true("create_time" %in% names(dt))
  expect_s3_class(dt$create_time, "POSIXct")
})

test_that("get_sub_accounts hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_sub_account_list_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_sub_accounts()
  expect_true(grepl("sapi/v1/sub-account/list", captured_url))
})

test_that("get_sub_accounts passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_sub_account_list_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_sub_accounts(email = "testsub01@virtual.com", page = 1, limit = 10)
  expect_true(grepl("email=testsub01", captured_url))
  expect_true(grepl("page=1", captured_url))
  expect_true(grepl("limit=10", captured_url))
})

test_that("get_sub_accounts returns empty data.table when no subAccounts", {
  resp <- mock_binance_response(data = list(subAccounts = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_sub_accounts()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_balances --

test_that("get_balances returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_sub_account_balances_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_balances(email = "testsub01@virtual.com")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("asset" %in% names(dt))
  expect_true("free" %in% names(dt))
  expect_true("locked" %in% names(dt))
  expect_equal(dt$asset[1], "BTC")
  expect_equal(dt$asset[2], "USDT")
})

test_that("get_balances hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_sub_account_balances_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_balances(email = "testsub01@virtual.com")
  expect_true(grepl("sapi/v3/sub-account/assets", captured_url))
  expect_true(grepl("email=testsub01", captured_url))
})

test_that("get_balances returns empty data.table when no balances", {
  resp <- mock_binance_response(data = list(balances = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_balances(email = "testsub01@virtual.com")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_spot_summary --

test_that("get_spot_summary hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(totalCount = 2L, masterAccountTotalAsset = "0.5"))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_spot_summary()
  expect_true(grepl("sapi/v1/sub-account/spotSummary", captured_url))
})

test_that("get_spot_summary returns data.table", {
  resp <- mock_binance_response(data = list(totalCount = 2L, masterAccountTotalAsset = "0.5"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_spot_summary()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

# -- add_transfer --

test_that("add_transfer returns data.table with tranId", {
  resp <- mock_binance_response(data = mock_sub_account_transfer_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$add_transfer(
    toEmail = "testsub01@virtual.com",
    fromAccountType = "SPOT",
    toAccountType = "SPOT",
    asset = "USDT",
    amount = 100
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("tran_id" %in% names(dt))
  expect_true("client_tran_id" %in% names(dt))
})

test_that("add_transfer hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_sub_account_transfer_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    resp
  })

  new_sub()$add_transfer(
    fromAccountType = "SPOT", toAccountType = "SPOT",
    asset = "USDT", amount = 100
  )
  expect_true(grepl("sapi/v1/sub-account/universalTransfer", captured_url))
  expect_equal(captured_method, "POST")
})

test_that("add_transfer validates fromAccountType", {
  expect_error(
    new_sub()$add_transfer(
      fromAccountType = "INVALID",
      toAccountType = "SPOT",
      asset = "USDT",
      amount = 100
    ),
    "fromAccountType"
  )
})

test_that("add_transfer validates toAccountType", {
  expect_error(
    new_sub()$add_transfer(
      fromAccountType = "SPOT",
      toAccountType = "INVALID",
      asset = "USDT",
      amount = 100
    ),
    "toAccountType"
  )
})

# -- get_transfer_history --

test_that("get_transfer_history returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_sub_account_transfer_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_transfer_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("tran_id" %in% names(dt))
  expect_true("from_email" %in% names(dt))
  expect_true("to_email" %in% names(dt))
  expect_true("asset" %in% names(dt))
  expect_true("amount" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_true("client_tran_id" %in% names(dt))
})

test_that("get_transfer_history converts create_time_stamp to POSIXct", {
  resp <- mock_binance_response(data = mock_sub_account_transfer_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_transfer_history()
  expect_true("create_time_stamp" %in% names(dt))
  expect_s3_class(dt$create_time_stamp, "POSIXct")
})

test_that("get_transfer_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_sub_account_transfer_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_transfer_history()
  expect_true(grepl("sapi/v1/sub-account/universalTransfer", captured_url))
})

test_that("get_transfer_history passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_sub_account_transfer_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_transfer_history(fromEmail = "master@test.com", page = 1, limit = 10)
  expect_true(grepl("fromEmail=master", captured_url))
  expect_true(grepl("page=1", captured_url))
  expect_true(grepl("limit=10", captured_url))
})

test_that("get_transfer_history returns empty data.table when no results", {
  resp <- mock_binance_response(data = list(result = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_transfer_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_futures_account --

test_that("get_futures_account hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(email = "sub@virtual.com", asset = "USDT", totalInitialMargin = "0.0"))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_futures_account(email = "sub@virtual.com", futuresType = 1)
  expect_true(grepl("sapi/v2/sub-account/futures/account", captured_url))
  expect_true(grepl("email=sub", captured_url))
  expect_true(grepl("futuresType=1", captured_url))
})

test_that("get_futures_account returns data.table", {
  resp <- mock_binance_response(data = list(email = "sub@virtual.com", asset = "USDT", totalInitialMargin = "0.0"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_futures_account(email = "sub@virtual.com", futuresType = 1)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

# -- get_margin_account --

test_that("get_margin_account hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(email = "sub@virtual.com", marginLevel = "999.0", totalAssetOfBtc = "0.1"))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_margin_account(email = "sub@virtual.com")
  expect_true(grepl("sapi/v1/sub-account/margin/account", captured_url))
  expect_true(grepl("email=sub", captured_url))
})

test_that("get_margin_account returns data.table", {
  resp <- mock_binance_response(data = list(email = "sub@virtual.com", marginLevel = "999.0", totalAssetOfBtc = "0.1"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_margin_account(email = "sub@virtual.com")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

# -- get_status --

test_that("get_status returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_sub_account_status_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_status()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("email" %in% names(dt))
  expect_true("is_sub_user_enabled" %in% names(dt))
  expect_true("is_user_active" %in% names(dt))
  expect_true("insert_time" %in% names(dt))
  expect_true("is_margin_enabled" %in% names(dt))
  expect_true("is_future_enabled" %in% names(dt))
  expect_equal(dt$email, "testsub01@virtual.com")
})

test_that("get_status hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_sub_account_status_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_status()
  expect_true(grepl("sapi/v1/sub-account/status", captured_url))
})

test_that("get_status passes email parameter", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_sub_account_status_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_sub()$get_status(email = "testsub01@virtual.com")
  expect_true(grepl("email=testsub01", captured_url))
})

test_that("get_status returns empty data.table when no data", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_status()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
