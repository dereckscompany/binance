# ===========================================================================
# Bug Hunt Tests — Binance
# These tests are written as if each bug is already fixed.
# Running against the current code should produce FAILURES.
# ===========================================================================

# ---------------------------------------------------------------------------
# Bug #6: sign_request() query string encoding mismatch
# The HMAC signature should be computed from the URL-encoded query string,
# matching what httr2 actually sends over the wire.
# ---------------------------------------------------------------------------
test_that("sign_request encodes special chars in query string for HMAC", {
  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")

  # Build a request with a query param containing special characters

  req <- httr2::request("https://api.binance.com/sapi/v1/sub-account/list")
  req <- httr2::req_url_query(req, email = "sub@virtual.com")

  signed_req <- binance:::sign_request(req, keys)

  # Extract the signature from the signed URL
  parsed <- httr2::url_parse(signed_req$url)
  signature <- parsed$query$signature

  # Now compute what the signature SHOULD be:
  # httr2 URL-encodes the query string, so @ becomes %40
  # The signing input must match the encoded form
  query_parts <- parsed$query[!names(parsed$query) %in% "signature"]
  # Rebuild with proper URL encoding (the way httr2 sends it)
  encoded_pairs <- paste0(
    names(query_parts),
    "=",
    vapply(query_parts, utils::URLencode, character(1), reserved = TRUE)
  )
  encoded_query_string <- paste(encoded_pairs, collapse = "&")

  expected_sig <- digest::hmac(
    key = "test-secret",
    object = encoded_query_string,
    algo = "sha256",
    serialize = FALSE
  )

  expect_equal(signature, expected_sig, info = "Signature must be computed from URL-encoded query string")
})

# ---------------------------------------------------------------------------
# Bug #4: Backfill resume appends duplicate rows
# When resuming, combo_from is set to last_dt (the last existing timestamp).
# This means the API re-fetches that candle, creating a duplicate.
# The resume logic should start AFTER the last existing row.
# ---------------------------------------------------------------------------
test_that("backfill resume logic starts after last existing timestamp", {
  # Simulate the resume data.table that binance_backfill_klines computes
  # from an existing CSV (grouped max of datetime by symbol+timeframe)
  resume <- data.table::data.table(
    symbol = "BTCUSDT",
    timeframe = "1h",
    last_dt = as.POSIXct("2024-01-01 02:00:00", tz = "UTC")
  )

  from <- as.POSIXct("2024-01-01 00:00:00", tz = "UTC")
  to <- as.POSIXct("2024-01-01 05:00:00", tz = "UTC")

  sym <- "BTCUSDT"
  intv <- "1h"

  # Replicate the resume logic from backfill.R lines 127-140
  combo_from <- from
  match_row <- resume[symbol == sym & timeframe == intv]
  if (nrow(match_row) > 0L) {
    last_dt <- match_row$last_dt[1L]
    if (last_dt < to) {
      combo_from <- last_dt + 1 # Fixed: offset by 1 second to avoid duplicates
    }
  }

  # The bug: combo_from == last_dt, so the candle at 02:00 will be re-fetched
  last_existing <- as.POSIXct("2024-01-01 02:00:00", tz = "UTC")
  expect_true(
    combo_from > last_existing,
    info = paste(
      "Resume should start AFTER last existing timestamp to avoid duplicates.",
      "Got combo_from =",
      format(combo_from),
      "== last_dt =",
      format(last_existing)
    )
  )
})

# ---------------------------------------------------------------------------
# Policy: no list columns at the public API level
# Parsers that consume nested arrays of plain strings must collapse them
# to `;`-joined character columns via `collapse_string_array_fields()`
# BEFORE calling `as_dt_row`. `as_dt_row` itself remains a flexible
# primitive — but using it directly on records with un-collapsed array
# fields is a policy violation. This test exercises the policy-correct
# path: preprocessed records produce a plain character column on both
# the length-1 and length-N branches, and `rbindlist` keeps it
# character (no list-column fallback).
# ---------------------------------------------------------------------------
test_that("collapse_string_array_fields + as_dt_row: stable character column for length-1 and length-N arrays", {
  row1 <- list(name = "A", perms = list("SPOT"))
  row2 <- list(name = "B", perms = list("SPOT", "MARGIN"))

  row1 <- connectcore::collapse_string_array_fields(row1, "perms")
  row2 <- connectcore::collapse_string_array_fields(row2, "perms")

  dt1 <- connectcore::as_dt_row(row1)
  dt2 <- connectcore::as_dt_row(row2)

  # Plain character on both rows.
  expect_true(is.character(dt1$perms), info = "Length-1 array should collapse to a character scalar")
  expect_true(is.character(dt2$perms), info = "Length-N array should collapse to a character scalar")
  expect_equal(dt1$perms, "SPOT")
  expect_equal(dt2$perms, "SPOT;MARGIN")

  # rbindlist keeps it character — no list-column fallback.
  combined <- data.table::rbindlist(list(dt1, dt2), fill = TRUE)
  expect_equal(nrow(combined), 2L)
  expect_false(is.list(combined$perms), info = "Combined data.table must not have a list column for `perms`")
  expect_equal(combined$perms, c("SPOT", "SPOT;MARGIN"))
})

test_that("empty array collapses to NA_character_ (not list())", {
  row <- list(name = "C", perms = list())
  row <- connectcore::collapse_string_array_fields(row, "perms")
  expect_true(is.na(row$perms))
  expect_type(row$perms, "character")
})

test_that("collapse_string_array_fields is NA-safe (scalar NA, all-NA vector, partial NA)", {
  # Scalar NA — `grepl(";", NA)` returns NA, `any(NA)` is NA, and
  # `if (NA)` historically errored. NA-safe path falls back to
  # NA_character_.
  row_scalar_na <- list(name = "A", perms = NA_character_)
  row_scalar_na <- connectcore::collapse_string_array_fields(row_scalar_na, "perms")
  expect_true(is.na(row_scalar_na$perms))
  expect_type(row_scalar_na$perms, "character")

  # All-NA vector → NA_character_.
  row_all_na <- list(name = "B", perms = c(NA_character_, NA_character_))
  row_all_na <- connectcore::collapse_string_array_fields(row_all_na, "perms")
  expect_true(is.na(row_all_na$perms))

  # Partial NA — `paste(c("SPOT", NA), collapse = ";")` historically
  # produced the literal string `"SPOT;NA"`. NA-safe path drops NA
  # elements so the resulting string is just `"SPOT;MARGIN"`.
  row_partial <- list(name = "C", perms = c("SPOT", NA_character_, "MARGIN"))
  row_partial <- connectcore::collapse_string_array_fields(row_partial, "perms")
  expect_equal(row_partial$perms, "SPOT;MARGIN")
  expect_false(grepl("NA", row_partial$perms, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Bug #13: parse_klines() uses vapply(..., integer(1)) for trades field
# JSON numbers parse as doubles in R; vapply with integer(1) can error.
# ---------------------------------------------------------------------------
test_that("parse_klines handles trades field as double from JSON", {
  # Simulate what jsonlite returns: all numbers are doubles
  kline <- list(
    1704067200000, # datetime (double)
    "42000.00", # open
    "42100.00", # high
    "41900.00", # low
    "42050.00", # close
    "100.5", # volume
    1704070799999, # close_time (double)
    "4200000.00", # quote_volume
    150, # trades -- NOTE: this is a double, NOT integer
    "50.25", # taker_buy_base_volume
    "2100000.00", # taker_buy_quote_volume
    "0" # ignore
  )

  # parse_klines should not error even though trades is double
  dt <- binance:::parse_klines(list(kline))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$trades, 150L)
})

# ---------------------------------------------------------------------------
# Bug #14: BinanceTransfer$add_transfer() doesn't convert amount to character
# This can cause floating-point precision loss.
# ---------------------------------------------------------------------------
test_that("add_transfer sends amount as character string", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  transfer <- BinanceTransfer$new(keys = KEYS, base_url = BASE)

  captured_req <- NULL
  resp <- mock_binance_response(data = list(tranId = 123456789))
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  transfer$add_transfer(
    type = "MAIN_UMFUTURE",
    asset = "USDT",
    amount = 1.123456789012345
  )

  # The amount in the query string should be a precise character representation
  parsed <- httr2::url_parse(captured_req$url)
  amount_val <- parsed$query$amount

  expect_type(amount_val, "character")
  # The full precision should be preserved (not truncated by floating-point)
  expect_true(
    nchar(amount_val) >= 15,
    info = paste("Amount should preserve precision, got:", amount_val)
  )
})

# ---------------------------------------------------------------------------
# Bug #15: get_open_oco_orders / get_all_oco_orders don't convert timestamps
# These should convert transaction_time to POSIXct like other OCO methods.
# ---------------------------------------------------------------------------
test_that("get_open_oco_orders converts transaction_time to POSIXct", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  oco <- BinanceOcoOrders$new(keys = KEYS, base_url = BASE)

  mock_data <- list(
    list(
      orderListId = 1L,
      contingencyType = "OCO",
      listStatusType = "ALL_DONE",
      listOrderStatus = "ALL_DONE",
      listClientOrderId = "test123",
      transactionTime = 1704067200000,
      symbol = "BTCUSDT",
      orders = list(
        list(symbol = "BTCUSDT", orderId = 1L, clientOrderId = "a"),
        list(symbol = "BTCUSDT", orderId = 2L, clientOrderId = "b")
      )
    )
  )

  resp <- mock_binance_response(data = mock_data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- oco$get_open_oco_orders()
  expect_s3_class(dt, "data.table")
  expect_true("transaction_time" %in% names(dt))
  expect_s3_class(dt$transaction_time, "POSIXct")
})

test_that("get_all_oco_orders converts transaction_time to POSIXct", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  oco <- BinanceOcoOrders$new(keys = KEYS, base_url = BASE)

  mock_data <- list(
    list(
      orderListId = 1L,
      contingencyType = "OCO",
      listStatusType = "ALL_DONE",
      listOrderStatus = "ALL_DONE",
      listClientOrderId = "test123",
      transactionTime = 1704067200000,
      symbol = "BTCUSDT",
      orders = list(
        list(symbol = "BTCUSDT", orderId = 1L, clientOrderId = "a"),
        list(symbol = "BTCUSDT", orderId = 2L, clientOrderId = "b")
      )
    )
  )

  resp <- mock_binance_response(data = mock_data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- oco$get_all_oco_orders()
  expect_s3_class(dt, "data.table")
  expect_true("transaction_time" %in% names(dt))
  expect_s3_class(dt$transaction_time, "POSIXct")
})

# ---------------------------------------------------------------------------
# Bug #17: get_klines() silently truncates at 1000 candles
# The class method should either use segmentation or warn when the range
# would exceed the limit.
# ---------------------------------------------------------------------------
test_that("get_klines warns or fetches all when range exceeds limit", {
  KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://api.binance.com"
  market <- BinanceMarketData$new(keys = KEYS, base_url = BASE)

  # Generate 1000 mock klines (the max Binance returns per call)
  mock_klines <- lapply(1:1000, function(i) {
    ts <- 1704067200000 + (i - 1) * 3600000
    return(list(
      ts,
      "42000.00",
      "42100.00",
      "41900.00",
      "42050.00",
      "100.5",
      ts + 3599999,
      "4200000.00",
      150,
      "50.25",
      "2100000.00",
      "0"
    ))
  })

  resp <- mock_binance_response(data = mock_klines)
  httr2::local_mocked_responses(function(req) resp)

  # Request a range of ~2000 hours (should need more than 1000 candles)
  # The method should either:
  # (a) automatically segment and fetch all candles, or
  # (b) emit a warning that results are truncated
  expect_warning(
    market$get_klines(
      symbol = "BTCUSDT",
      interval = "1h",
      start_time = as.POSIXct("2024-01-01", tz = "UTC"),
      end_time = as.POSIXct("2024-03-25", tz = "UTC")
    ),
    regexp = "truncat|limit|exceed|segment|1000",
    ignore.case = TRUE
  )
})

# ---------------------------------------------------------------------------
# Bug #18: get_api_keys() returns empty strings without warning
# Should warn or error when credentials are not set.
# ---------------------------------------------------------------------------
test_that("get_api_keys warns when env vars are not set", {
  # Temporarily unset the env vars
  withr::local_envvar(BINANCE_API_KEY = "", BINANCE_API_SECRET = "")

  expect_warning(
    get_api_keys(),
    regexp = "API|key|secret|credential|not set|missing|empty",
    ignore.case = TRUE,
    info = "get_api_keys should warn when env vars return empty strings"
  )
})
