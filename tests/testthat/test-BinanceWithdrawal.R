# tests/testthat/test-BinanceWithdrawal.R
# Tests for BinanceWithdrawal R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

new_withdrawal <- function() {
  BinanceWithdrawal$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("BinanceWithdrawal inherits from BinanceBase", {
  w <- new_withdrawal()
  expect_s3_class(w, "BinanceWithdrawal")
  expect_s3_class(w, "BinanceBase")
})

# -- add_withdrawal --

test_that("add_withdrawal returns data.table with id", {
  resp <- mock_binance_response(data = mock_withdrawal_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$add_withdrawal(
    coin = "USDT",
    address = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    amount = 10
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("id" %in% names(dt))
  expect_equal(dt$id, "7213fea8e94b4a5593d507237e5a555b")
})

test_that("add_withdrawal hits correct endpoint with POST", {
  captured_url <- NULL
  captured_method <- NULL
  resp <- mock_binance_response(data = mock_withdrawal_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_method <<- req$method
    resp
  })

  new_withdrawal()$add_withdrawal(
    coin = "USDT",
    address = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    amount = 10
  )
  expect_true(grepl("sapi/v1/capital/withdraw/apply", captured_url))
  expect_equal(captured_method, "POST")
})

test_that("add_withdrawal validates coin parameter", {
  expect_error(
    new_withdrawal()$add_withdrawal(coin = "", address = "addr", amount = 1),
    "coin"
  )
})

test_that("add_withdrawal validates address parameter", {
  expect_error(
    new_withdrawal()$add_withdrawal(coin = "BTC", address = "", amount = 1),
    "address"
  )
})

# -- get_withdrawal_history --

test_that("get_withdrawal_history returns data.table with expected columns", {
  resp <- mock_binance_response(data = mock_withdrawal_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$get_withdrawal_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)

  # Expected columns
  expect_true("id" %in% names(dt))
  expect_true("amount" %in% names(dt))
  expect_true("transaction_fee" %in% names(dt))
  expect_true("coin" %in% names(dt))
  expect_true("status" %in% names(dt))
  expect_true("address" %in% names(dt))
  expect_true("tx_id" %in% names(dt))
  expect_true("apply_time" %in% names(dt))
  expect_true("network" %in% names(dt))
  expect_true("transfer_type" %in% names(dt))
  expect_true("withdraw_order_id" %in% names(dt))
  expect_true("info" %in% names(dt))
  expect_true("confirm_no" %in% names(dt))
  expect_true("wallet_type" %in% names(dt))
  expect_true("tx_key" %in% names(dt))
  expect_true("complete_time" %in% names(dt))

  # Values
  expect_equal(dt$coin[1], "USDT")
  expect_equal(dt$status[1], 6L)
  expect_equal(dt$coin[2], "BTC")
  expect_equal(dt$status[2], 4L)
})

test_that("get_withdrawal_history hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_withdrawal_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_withdrawal()$get_withdrawal_history()
  expect_true(grepl("sapi/v1/capital/withdraw/history", captured_url))
})

test_that("get_withdrawal_history passes query parameters", {
  captured_url <- NULL
  resp <- mock_binance_response(data = mock_withdrawal_history_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_withdrawal()$get_withdrawal_history(coin = "USDT", status = 6, limit = 100)
  expect_true(grepl("coin=USDT", captured_url))
  expect_true(grepl("status=6", captured_url))
  expect_true(grepl("limit=100", captured_url))
})

test_that("get_withdrawal_history returns empty data.table when no withdrawals", {
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$get_withdrawal_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
