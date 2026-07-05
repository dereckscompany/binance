# tests/testthat/test-helpers_parse.R
# Binance-specific parsers. The generic JSON->data.table toolkit
# (`to_snake_case`, `as_dt_row`, `as_dt_list`, `coerce_cols`,
# `collapse_string_array_fields`, `ms_to_datetime`) is imported from
# connectcore and tested there; this file covers only the parsers Binance
# defines itself.

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
  expect_true("datetime" %in% names(result))
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
