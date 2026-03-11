# tests/testthat/test-live-integration-private.R
# Live integration tests for authenticated endpoints.
# These hit the real Binance API — no mocking.
# Requires API keys set via environment variables.
#
# Write tests only use the /order/test endpoint (dry-run, no real execution).
#
# Run with:
#   BINANCE_LIVE_TESTS=true Rscript -e 'devtools::test(filter = "live")'

skip_if_not(
  identical(Sys.getenv("BINANCE_LIVE_TESTS"), "true"),
  "Live API tests skipped (set BINANCE_LIVE_TESTS=true to run)"
)

.api_key <- Sys.getenv("BINANCE_API_KEY", "")
.api_secret <- Sys.getenv("BINANCE_API_SECRET", "")

skip_if(
  .api_key == "" || .api_secret == "",
  "No API keys configured (set BINANCE_API_KEY + BINANCE_API_SECRET)"
)

.keys <- get_api_keys(api_key = .api_key, api_secret = .api_secret)

# Rate limit helper
throttle <- function() Sys.sleep(0.3)

# =============================================================================
# BinanceAccount — Read-only
# =============================================================================

account <- BinanceAccount$new(keys = .keys)

test_that("[LIVE] get_account returns data.table with account info", {
  dt <- account$get_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("can_trade" %in% names(dt))
  expect_true("account_type" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_my_trades returns data.table for BTCUSDT", {
  dt <- account$get_my_trades("BTCUSDT", limit = 10)
  expect_s3_class(dt, "data.table")
  # May be empty if no trades
  if (nrow(dt) > 0) {
    expect_true(all(c("symbol", "price", "qty", "time") %in% names(dt)))
    expect_s3_class(dt$time, "POSIXct")
  }
  throttle()
})

# =============================================================================
# BinanceTrading — Write (test endpoint only, no real orders)
# =============================================================================

trading <- BinanceTrading$new(keys = .keys)

test_that("[LIVE] add_order_test validates a limit order without executing", {
  dt <- trading$add_order_test(
    symbol = "BTCUSDT",
    side = "BUY",
    type = "LIMIT",
    quantity = 0.00001,
    price = 10000,
    timeInForce = "GTC"
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] add_order_test validates a market order without executing", {
  dt <- trading$add_order_test(
    symbol = "BTCUSDT",
    side = "BUY",
    type = "MARKET",
    quantity = 0.00001
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# BinanceTrading — Read-only getters
# =============================================================================

test_that("[LIVE] get_open_orders returns data.table", {
  dt <- trading$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_all_orders returns data.table", {
  dt <- trading$get_all_orders("BTCUSDT", limit = 10)
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("symbol" %in% names(dt))
    expect_true("status" %in% names(dt))
  }
  throttle()
})

# =============================================================================
# BinanceDeposit — Read-only
# =============================================================================

deposit <- BinanceDeposit$new(keys = .keys)

test_that("[LIVE] get_deposit_address returns data.table for BTC", {
  dt <- deposit$get_deposit_address(coin = "BTC")
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("address" %in% names(dt))
    expect_true("coin" %in% names(dt))
  }
  throttle()
})

test_that("[LIVE] get_deposit_history returns data.table", {
  dt <- deposit$get_deposit_history()
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("insert_time" %in% names(dt))
  }
  throttle()
})

# =============================================================================
# BinanceWithdrawal — Read-only
# =============================================================================

withdrawal <- BinanceWithdrawal$new(keys = .keys)

test_that("[LIVE] get_withdrawal_history returns data.table", {
  dt <- withdrawal$get_withdrawal_history()
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# BinanceTransfer — Read-only
# =============================================================================

transfer <- BinanceTransfer$new(keys = .keys)

test_that("[LIVE] get_transfer_history returns data.table", {
  dt <- transfer$get_transfer_history(type = "MAIN_UMFUTURE")
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# BinanceOcoOrders — Read-only
# =============================================================================

oco <- BinanceOcoOrders$new(keys = .keys)

test_that("[LIVE] get_open_oco_orders returns data.table", {
  dt <- oco$get_open_oco_orders()
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_all_oco_orders returns data.table", {
  dt <- oco$get_all_oco_orders(limit = 10)
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# BinanceMarginData — Public-ish (some need auth)
# =============================================================================

margin_data <- BinanceMarginData$new(keys = .keys)

test_that("[LIVE] get_all_pairs returns data.table with margin pairs", {
  dt <- margin_data$get_all_pairs()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true("symbol" %in% names(dt))
  expect_true("BTCUSDT" %in% dt$symbol)
  throttle()
})

test_that("[LIVE] get_price_index returns data.table for BTCUSDT", {
  dt <- margin_data$get_price_index("BTCUSDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("price" %in% names(dt))
  expect_true("calc_time" %in% names(dt))
  expect_s3_class(dt$calc_time, "POSIXct")
  throttle()
})

# =============================================================================
# BinanceMargin — Read-only
# =============================================================================

margin <- BinanceMargin$new(keys = .keys)

test_that("[LIVE] get_account returns data.table with margin info", {
  dt <- margin$get_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("margin_level" %in% names(dt))
  expect_true("trade_enabled" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_max_borrowable returns data.table", {
  dt <- margin$get_max_borrowable("USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("amount" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_open_orders returns data.table", {
  dt <- margin$get_open_orders("BTCUSDT")
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# BinanceFutures — Read-only (requires futures account)
# =============================================================================

# NOTE: These tests require a futures-enabled account.
# They are wrapped in tryCatch to gracefully skip if futures is not available.

futures <- BinanceFutures$new(keys = .keys)

test_that("[LIVE] futures get_account returns data.table", {
  dt <- tryCatch(
    futures$get_account(),
    error = function(e) {
      skip(paste("Futures account not available:", conditionMessage(e)))
    }
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("can_trade" %in% names(dt))
  throttle()
})

test_that("[LIVE] futures get_balances returns data.table", {
  dt <- tryCatch(
    futures$get_balances(),
    error = function(e) {
      skip(paste("Futures account not available:", conditionMessage(e)))
    }
  )
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("asset" %in% names(dt))
    expect_true("balance" %in% names(dt))
  }
  throttle()
})

test_that("[LIVE] futures get_positions returns data.table", {
  dt <- tryCatch(
    futures$get_positions("BTCUSDT"),
    error = function(e) {
      skip(paste("Futures account not available:", conditionMessage(e)))
    }
  )
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("symbol" %in% names(dt))
    expect_true("leverage" %in% names(dt))
  }
  throttle()
})

test_that("[LIVE] futures get_position_mode returns data.table", {
  dt <- tryCatch(
    futures$get_position_mode(),
    error = function(e) {
      skip(paste("Futures account not available:", conditionMessage(e)))
    }
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("dual_side_position" %in% names(dt))
  throttle()
})

test_that("[LIVE] futures add_order_test validates without executing", {
  dt <- tryCatch(
    futures$add_order_test(
      symbol = "BTCUSDT",
      side = "BUY",
      type = "LIMIT",
      quantity = 0.001,
      price = 10000,
      timeInForce = "GTC"
    ),
    error = function(e) {
      skip(paste("Futures account not available:", conditionMessage(e)))
    }
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures get_open_orders returns data.table", {
  dt <- tryCatch(
    futures$get_open_orders("BTCUSDT"),
    error = function(e) {
      skip(paste("Futures account not available:", conditionMessage(e)))
    }
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures get_income_history returns data.table", {
  dt <- tryCatch(
    futures$get_income_history(limit = 10),
    error = function(e) {
      skip(paste("Futures account not available:", conditionMessage(e)))
    }
  )
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("time" %in% names(dt))
    expect_s3_class(dt$time, "POSIXct")
  }
  throttle()
})
