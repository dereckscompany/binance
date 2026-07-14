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

test_that("BinanceBase rejects max_tries outside [1, 10]", {
  expect_error(BinanceBase$new(keys = KEYS, base_url = BASE, max_tries = 0L))
  expect_error(BinanceBase$new(keys = KEYS, base_url = BASE, max_tries = 11L))
})

# -- max_tries: the hard GET-only retry carve-out --
#
# `httr2::req_perform()` short-circuits its retry loop whenever the `httr2_mock`
# option is set, so `local_mocked_responses()` cannot exercise retry. We mock the
# per-attempt fetch (`httr2:::req_perform1`) instead, letting `req_perform()`
# re-drive it against the policy the constructor's `max_tries` threaded into
# `connectcore::build_request()`; `sys_sleep` is stubbed so backoff is instant.

test_that("a non-idempotent POST is performed exactly once even with max_tries = 5", {
  base <- BinanceBase$new(keys = KEYS, base_url = BASE, max_tries = 5L)
  n <- 0L
  testthat::local_mocked_bindings(
    sys_sleep = function(seconds, ...) invisible(),
    req_perform1 = function(req, req_prep, path, handle, resend_count) {
      n <<- n + 1L
      return(mock_http_error(status_code = 500L, body_text = "Internal Server Error"))
    },
    .package = "httr2"
  )
  priv <- base$.__enclos_env__$private
  expect_error(priv$.request(endpoint = "/api/v3/order", method = "POST", auth = FALSE))
  expect_identical(n, 1L) # never a silent resend of an order
})

test_that("a transient 500 on a GET is retried and then succeeds (max_tries = 3)", {
  base <- BinanceBase$new(keys = KEYS, base_url = BASE, max_tries = 3L)
  n <- 0L
  testthat::local_mocked_bindings(
    sys_sleep = function(seconds, ...) invisible(),
    req_perform1 = function(req, req_prep, path, handle, resend_count) {
      n <<- n + 1L
      if (n == 1L) {
        return(mock_http_error(status_code = 500L, body_text = "Internal Server Error"))
      }
      return(mock_binance_response(data = list(ok = TRUE)))
    },
    .package = "httr2"
  )
  priv <- base$.__enclos_env__$private
  out <- priv$.request(endpoint = "/api/v3/ping", method = "GET", auth = FALSE)
  expect_true(out$ok)
  expect_identical(n, 2L) # retried once on the 500, then succeeded
})
