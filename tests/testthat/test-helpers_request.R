# tests/testthat/test-helpers_request.R
# Tests for request helpers: sign_request, parse_binance_response, binance_build_request.

# -- sign_request --

test_that("sign_request adds timestamp and signature query params", {
  req <- httr2::request("https://api.binance.com")
  req <- httr2::req_url_path_append(req, "/api/v3/order")
  req <- httr2::req_url_query(req, symbol = "BTCUSDT", side = "BUY")

  keys <- list(
    api_key = "vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A",
    api_secret = "NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j"
  )
  fixed_ts <- function() 1499827319559

  signed <- binance:::sign_request(req, keys, .get_timestamp_ms = fixed_ts)
  parsed <- httr2::url_parse(signed$url)

  expect_equal(parsed$query$timestamp, "1499827319559")
  expect_true(!is.null(parsed$query$signature))
  expect_true(nchar(parsed$query$signature) == 64) # hex-encoded SHA256 = 64 chars
})

test_that("sign_request adds X-MBX-APIKEY header", {
  req <- httr2::request("https://api.binance.com")
  req <- httr2::req_url_path_append(req, "/api/v3/time")

  keys <- list(api_key = "test-api-key", api_secret = "test-secret")
  fixed_ts <- function() 1000000

  signed <- binance:::sign_request(req, keys, .get_timestamp_ms = fixed_ts)
  expect_equal(signed$headers$`X-MBX-APIKEY`, "test-api-key")
})

# -- parse_binance_response --

test_that("parse_binance_response returns parsed JSON on success", {
  resp <- mock_binance_response(data = list(symbol = "BTCUSDT", price = "67000"))
  result <- binance:::parse_binance_response(resp)
  expect_equal(result$symbol, "BTCUSDT")
  expect_equal(result$price, "67000")
})

test_that("parse_binance_response raises error on negative code", {
  resp <- mock_binance_error(code = -1021, msg = "Timestamp for this request is outside of the recvWindow.")
  expect_error(
    binance:::parse_binance_response(resp),
    "Binance API error -1021"
  )
})

test_that("parse_binance_response raises error on HTTP failure", {
  resp <- mock_http_error(status_code = 503L, body_text = "Service Unavailable")
  expect_error(
    binance:::parse_binance_response(resp),
    "503"
  )
})

# -- binance_build_request --

test_that("binance_build_request sends correct endpoint", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(serverTime = 123))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  binance_build_request(
    base_url = "https://api.binance.com",
    endpoint = "/api/v3/time",
    method = "GET"
  )
  expect_true(grepl("api/v3/time", captured_url))
})

test_that("binance_build_request applies .parser", {
  resp <- mock_binance_response(data = list(serverTime = 123456))
  httr2::local_mocked_responses(function(req) resp)

  result <- binance_build_request(
    base_url = "https://api.binance.com",
    endpoint = "/api/v3/time",
    .parser = function(data) data$serverTime * 2
  )
  expect_equal(result, 123456 * 2)
})

test_that("binance_build_request drops NULL query params", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(symbol = "BTCUSDT"))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  binance_build_request(
    base_url = "https://api.binance.com",
    endpoint = "/api/v3/ticker/price",
    query = list(symbol = "BTCUSDT", limit = NULL)
  )
  expect_true(grepl("symbol=BTCUSDT", captured_url))
  expect_false(grepl("limit", captured_url))
})

test_that("binance_build_request signs when keys provided", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  keys <- list(api_key = "test-key", api_secret = "test-secret")
  binance_build_request(
    base_url = "https://api.binance.com",
    endpoint = "/api/v3/account",
    keys = keys
  )
  expect_true(grepl("timestamp=", captured_url))
  expect_true(grepl("signature=", captured_url))
})

test_that("binance_build_request does not sign when keys is NULL", {
  captured_url <- NULL
  resp <- mock_binance_response(data = list(serverTime = 123))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  binance_build_request(
    base_url = "https://api.binance.com",
    endpoint = "/api/v3/time",
    keys = NULL
  )
  expect_false(grepl("timestamp=", captured_url))
  expect_false(grepl("signature=", captured_url))
})
