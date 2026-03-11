# tests/testthat/test-BinanceBase.R
# Tests for BinanceBase R6 class.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

# -- Construction --

test_that("BinanceBase can be instantiated with explicit keys", {
  base <- BinanceBase$new(keys = KEYS, base_url = BASE)
  expect_s3_class(base, "BinanceBase")
  expect_false(base$is_async)
  expect_equal(base$time_source, "local")
})

test_that("BinanceBase async mode sets is_async = TRUE", {
  base <- BinanceBase$new(keys = KEYS, base_url = BASE, async = TRUE)
  expect_true(base$is_async)
})

test_that("BinanceBase server time_source accepted", {
  # Server time source means .get_timestamp_ms calls fetch_server_time_ms
  base <- BinanceBase$new(keys = KEYS, base_url = BASE, time_source = "server")
  expect_equal(base$time_source, "server")
})

test_that("BinanceBase rejects invalid time_source", {
  expect_error(
    BinanceBase$new(keys = KEYS, base_url = BASE, time_source = "invalid"),
    "local.*server"
  )
})
