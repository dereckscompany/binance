# Typed Binance input-validation conditions. Every non-transport abort is raised
# through abort_binance_validation_error(), classed c("binance_validation_error",
# "binance_error") -- binance_error is the connector's DOMAIN root, parallel to
# the transport connectcore_error root. The message strings stay byte-identical
# to the bare rlang::abort() calls each site replaced (the goldens below pin
# that). If a golden fails, the backward-compatibility contract broke.

test_that("abort_binance_validation_error layers binance_validation_error then binance_error", {
  err <- tryCatch(
    binance:::abort_binance_validation_error("boom"),
    error = function(e) e
  )
  expect_identical(
    class(err),
    c("binance_validation_error", "binance_error", "rlang_error", "error", "condition")
  )
  expect_identical(conditionMessage(err), "boom")
})

test_that("binance_validation_error is caught by the binance_error domain root", {
  caught <- tryCatch(
    binance:::abort_binance_validation_error("x"),
    binance_error = function(e) "root"
  )
  expect_identical(caught, "root")
})

test_that("a validation failure is NOT a transport (connectcore_error) failure", {
  # The domain root and the transport root are parallel and never meet.
  err <- tryCatch(binance:::abort_binance_validation_error("x"), error = function(e) e)
  expect_false(inherits(err, "connectcore_error"))
})

# ---- Real sites: class, and byte-identical message (golden) ----

test_that("time_convert_from_binance rejects a non-numeric with binance_validation_error (golden)", {
  err <- tryCatch(time_convert_from_binance("not-a-number"), error = function(e) e)
  expect_s3_class(err, "binance_validation_error")
  expect_s3_class(err, "binance_error")
  expect_identical(conditionMessage(err), "Input must be a numeric value.")
})

test_that("validate_order_params rejects a LIMIT order without price with binance_validation_error (golden)", {
  err <- tryCatch(
    binance:::validate_order_params(type = "LIMIT", symbol = "BTCUSDT", side = "BUY", quantity = 0.001),
    error = function(e) e
  )
  expect_s3_class(err, "binance_validation_error")
  expect_s3_class(err, "binance_error")
  expect_identical(conditionMessage(err), "Parameter 'price' is required for LIMIT orders.")
})
