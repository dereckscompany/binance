test_that("verify_symbol accepts valid Binance symbols", {
  expect_true(verify_symbol("BTCUSDT"))
  expect_true(verify_symbol("ETHBTC"))
  expect_true(verify_symbol("BNBUSDT"))
})

test_that("verify_symbol rejects invalid symbols", {
  expect_false(verify_symbol("BTC-USDT"))
  expect_false(verify_symbol("BTC_USDT"))
  expect_false(verify_symbol("BTC USDT"))
  expect_false(verify_symbol(""))
})

test_that("get_base_url returns default URL", {
  withr::with_envvar(c("BINANCE_API_ENDPOINT" = ""), {
    expect_equal(get_base_url(), "https://api.binance.com")
  })
})

test_that("get_base_url uses environment variable", {
  withr::with_envvar(c("BINANCE_API_ENDPOINT" = "https://testnet.binance.vision"), {
    expect_equal(get_base_url(), "https://testnet.binance.vision")
  })
})

test_that("get_api_keys returns a list with api_key and api_secret", {
  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  expect_type(keys, "list")
  expect_equal(keys$api_key, "test-key")
  expect_equal(keys$api_secret, "test-secret")
})
