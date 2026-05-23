test_that("to_snake_case converts camelCase correctly", {
  expect_equal(binance:::to_snake_case("camelCase"), "camel_case")
  expect_equal(binance:::to_snake_case("priceChange"), "price_change")
  expect_equal(binance:::to_snake_case("isBuyerMaker"), "is_buyer_maker")
  expect_equal(binance:::to_snake_case("quoteOrderQty"), "quote_order_qty")
})

test_that("as_dt_row handles empty input", {
  expect_equal(nrow(binance:::as_dt_row(NULL)), 0)
  expect_equal(nrow(binance:::as_dt_row(list())), 0)
})

test_that("as_dt_row converts named list to data.table", {
  result <- binance:::as_dt_row(list(symbol = "BTCUSDT", price = "67000"))
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1)
  expect_equal(result$symbol, "BTCUSDT")
  expect_equal(result$price, "67000")
})

test_that("as_dt_list converts list of lists to data.table", {
  items <- list(
    list(symbol = "BTCUSDT", price = "67000"),
    list(symbol = "ETHUSDT", price = "3500")
  )
  result <- binance:::as_dt_list(items)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_equal(result$symbol, c("BTCUSDT", "ETHUSDT"))
})

test_that("ms_to_datetime converts milliseconds to POSIXct", {
  result <- binance:::ms_to_datetime(1499827319559)
  expect_s3_class(result, "POSIXct")
})

test_that("ms_to_datetime handles NULL and NA", {
  expect_true(is.na(binance:::ms_to_datetime(NULL)))
  expect_true(is.na(binance:::ms_to_datetime(NA)))
})

test_that("parse_klines returns proper OHLCV data.table", {
  kline_data <- list(
    list(
      1499040000000,
      "0.01634790",
      "0.80000000",
      "0.01575800",
      "0.01577100",
      "148976.11427815",
      1499644799999,
      "2434.19055334",
      308L,
      "1756.87402397",
      "28.46694368",
      "0"
    )
  )
  result <- binance:::parse_klines(kline_data)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1)
  expect_true("open_time" %in% names(result))
  expect_true("open" %in% names(result))
  expect_true("high" %in% names(result))
  expect_true("low" %in% names(result))
  expect_true("close" %in% names(result))
  expect_true("volume" %in% names(result))
})

test_that("parse_orderbook returns proper data.table", {
  ob_data <- list(
    lastUpdateId = 1027024,
    bids = list(list("4.00000000", "431.00000000")),
    asks = list(list("4.00000200", "12.00000000"))
  )
  result <- binance:::parse_orderbook(ob_data)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_true("side" %in% names(result))
  expect_true("price" %in% names(result))
  expect_true("size" %in% names(result))
  expect_equal(result$side, c("bid", "ask"))
})

test_that("parse_orderbook returns empty data.table on NULL or empty data (no crash)", {
  # Regression: parser used to do `data$bids` without guarding NULL,
  # crashing with "$ operator applied to NULL" if upstream returned
  # NULL (empty body / JSON-parse failure).
  empty_null <- binance:::parse_orderbook(NULL)
  expect_s3_class(empty_null, "data.table")
  expect_equal(nrow(empty_null), 0L)
  expect_true(all(c("last_update_id", "side", "price", "size") %in% names(empty_null)))

  empty_list <- binance:::parse_orderbook(list())
  expect_s3_class(empty_list, "data.table")
  expect_equal(nrow(empty_list), 0L)
})

test_that("parse_paginated returns empty data.table on NULL data (no crash)", {
  # Regression: parser used to do `rows <- data$rows` without guarding
  # NULL, crashing on empty-body responses.
  result <- binance:::parse_paginated(NULL)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)

  result_empty <- binance:::parse_paginated(list())
  expect_s3_class(result_empty, "data.table")
  expect_equal(nrow(result_empty), 0L)
})

# -- coerce_cols --

test_that("coerce_cols applies fn to each column present, in place", {
  dt <- data.table::data.table(
    a = c(1500000000000, 1600000000000),
    b = c("x", "y"),
    c = c(1700000000000, 1800000000000)
  )
  invisible(binance:::coerce_cols(dt, c("a", "c"), binance:::ms_to_datetime))
  expect_s3_class(dt$a, "POSIXct")
  expect_s3_class(dt$c, "POSIXct")
  # Unrelated column untouched.
  expect_equal(dt$b, c("x", "y"))
})

test_that("coerce_cols silently skips columns not in the data.table", {
  dt <- data.table::data.table(a = 1500000000000)
  invisible(binance:::coerce_cols(dt, c("a", "missing"), binance:::ms_to_datetime))
  expect_s3_class(dt$a, "POSIXct")
  expect_false("missing" %in% names(dt))
})

test_that("coerce_cols is a no-op on an empty data.table", {
  dt <- data.table::data.table(a = numeric())
  invisible(binance:::coerce_cols(dt, "a", binance:::ms_to_datetime))
  expect_equal(nrow(dt), 0L)
  # Column type unchanged (no fn applied because dt was empty).
  expect_type(dt$a, "double")
})

test_that("coerce_cols works with arbitrary functions, not just ms_to_datetime", {
  # The helper is converter-agnostic — anything that takes a vector and
  # returns a vector of the same length works.
  dt <- data.table::data.table(price = c("100.5", "200.5"), qty = c("1", "2"))
  invisible(binance:::coerce_cols(dt, c("price", "qty"), as.numeric))
  expect_type(dt$price, "double")
  expect_type(dt$qty, "double")
  expect_equal(dt$price, c(100.5, 200.5))
})

# -- utc_string_to_datetime --

test_that("utc_string_to_datetime parses Binance UTC strings", {
  result <- binance:::utc_string_to_datetime(c("2019-10-12 11:12:02", "2023-05-01 08:30:00"))
  expect_s3_class(result, "POSIXct")
  expect_equal(format(result[1], "%Y-%m-%d %H:%M:%S"), "2019-10-12 11:12:02")
})

test_that("utc_string_to_datetime treats empty strings as NA (no parse warning)", {
  # Binance returns "" for in-progress withdrawals — must round-trip to
  # NA cleanly without triggering the upstream ymd_hms "All formats
  # failed to parse" warning.
  expect_warning(
    result <- binance:::utc_string_to_datetime(c("2019-10-12 11:12:02", "")),
    regexp = NA
  )
  expect_s3_class(result, "POSIXct")
  expect_false(is.na(result[1]))
  expect_true(is.na(result[2]))
})

test_that("utc_string_to_datetime returns NA_POSIXct_ for NULL / zero-length input", {
  expect_true(is.na(binance:::utc_string_to_datetime(NULL)))
  expect_true(is.na(binance:::utc_string_to_datetime(character(0))))
})
