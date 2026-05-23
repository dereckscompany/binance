# tests/testthat/test-backfill.R
# Tests for binance_backfill_klines() with mocked HTTP.

# -- Input Validation --

test_that("backfill rejects NULL symbols", {
  expect_error(
    binance_backfill_klines(symbols = NULL, timeframes = "1d"),
    "non-empty"
  )
})

test_that("backfill rejects empty symbols", {
  expect_error(
    binance_backfill_klines(symbols = character(0), timeframes = "1d"),
    "non-empty"
  )
})

# -- Successful Backfill --

test_that("backfill writes CSV and returns file path", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  # Mock the HTTP layer
  kline_data <- mock_klines_data()
  resp <- mock_response(kline_data)
  httr2::local_mocked_responses(function(req) resp)

  result <- binance_backfill_klines(
    symbols = "BTCUSDT",
    timeframes = "1d",
    from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
    to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  expect_equal(result, outfile)
  expect_true(file.exists(outfile))

  dt <- data.table::fread(outfile)
  expect_true(nrow(dt) > 0L)
  expect_true("symbol" %in% names(dt))
  expect_true("timeframe" %in% names(dt))
  expect_true("open_time" %in% names(dt))
  expect_equal(unique(dt$symbol), "BTCUSDT")
  expect_equal(unique(dt$timeframe), "1d")
})

# -- Resume Support --

test_that("backfill skips completed combos on resume", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  # Write a pre-existing CSV with data up to `to`
  existing <- data.table::data.table(
    open_time = "2024-10-17T00:00:00",
    open = 67000,
    high = 67100,
    low = 66900,
    close = 67050,
    volume = 100,
    close_time = "2024-10-17T23:59:59",
    quote_volume = 6700000,
    trades = 500L,
    taker_buy_base_volume = 50,
    taker_buy_quote_volume = 3350000,
    ignore = "0",
    symbol = "BTCUSDT",
    timeframe = "1d"
  )
  data.table::fwrite(existing, outfile)

  captured_urls <- character()
  resp <- mock_response(mock_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_urls <<- c(captured_urls, req$url)
    return(resp)
  })

  binance_backfill_klines(
    symbols = "BTCUSDT",
    timeframes = "1d",
    from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
    to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  # Should have been skipped (already up to date), so no HTTP requests
  expect_equal(length(captured_urls), 0L)
})

# -- from Clamping --

test_that("backfill clamps -Inf from to 2017-07-01", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  resp <- mock_response(mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  # Should not error with -Inf from
  result <- binance_backfill_klines(
    symbols = "BTCUSDT",
    timeframes = "1d",
    from = -Inf,
    to = lubridate::as_datetime("2017-07-02", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  expect_equal(result, outfile)
})

# -- Error Handling --

test_that("backfill warns per failure and emits a final summary warning", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  # Mock HTTP to return an error
  httr2::local_mocked_responses(function(req) {
    return(httr2::response(
      status_code = 500L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw("{\"code\": -1000, \"msg\": \"Internal error\"}")
    ))
  })

  warnings_seen <- character(0)
  result <- withCallingHandlers(
    binance_backfill_klines(
      symbols = "BTCUSDT",
      timeframes = "1d",
      from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
      to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
      file = outfile,
      sleep = 0,
      verbose = FALSE
    ),
    warning = function(w) {
      warnings_seen <<- c(warnings_seen, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  # Per-combo warning fires inside the tryCatch (line 160 of backfill.R)
  expect_true(any(grepl("BTCUSDT", warnings_seen) & grepl("FAILED", warnings_seen)))
  # Final summary warning lists the failure count + combo identifier.
  expect_true(any(grepl("1 of 1", warnings_seen) & grepl("BTCUSDT/1d", warnings_seen)))

  # No hidden state on the return value — it's just the file path.
  expect_type(result, "character")
  expect_null(attr(result, "failures"))
})

# -- Multiple Symbols/Timeframes --

test_that("backfill handles multiple symbol-timeframe combos", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  resp <- mock_response(mock_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  result <- binance_backfill_klines(
    symbols = c("BTCUSDT", "ETHUSDT"),
    timeframes = c("1d"),
    from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
    to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  dt <- data.table::fread(outfile)
  expect_true(nrow(dt) > 0L)
  expect_true("BTCUSDT" %in% dt$symbol)
  expect_true("ETHUSDT" %in% dt$symbol)
})
