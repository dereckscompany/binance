# Precision regression: every numeric field Binance reports as a decimal
# STRING must survive parsing at full double precision, and every field the
# parser deliberately keeps as a STRING (Binance's own lossless wire format)
# must be returned byte-identical -- never silently coerced to numeric. No
# round(), signif(), sprintf("%.Nf"), format(nsmall = ), or other narrowing
# cast may ever sit between the venue's own text and what this package
# returns.
#
# Why this test exists: on 2026-09-13 the fleet found every Hyperliquid candle
# in the data lake had been stored to four decimal places for months -- a coin
# priced below a cent (e.g. "0.000212") lost almost all of its information,
# and a strategy that ranks coins by calmness ranked them wrongly as a direct
# result. The cause traced to a re-serialisation default in the data scraper
# (since fixed), NOT to the venue connectors: this package's own parse path
# (`parse_klines()` in R/helpers_parse.R, `as.numeric()` straight off the
# venue's decimal string; `as_dt_row()` for the ticker, which does not coerce
# at all) was proven correct. This test pins that fact for Binance so the
# layer that is currently correct STAYS correct: if anyone later adds a
# round()/signif()/sprintf("%.4f")/format(nsmall = ) or a narrowing cast to a
# parse helper, it fails immediately.
#
# Drives the real public client methods (get_klines / get_book_ticker) through
# the shared connectcore mock harness (a URL-pattern route table +
# local_mock_api()), exactly as test-mock-router.R does, with a synthetic
# fixture authored as raw JSON text (never built from an R list +
# jsonlite::toJSON()) so the exact wire digits/strings below are what the
# parser actually sees -- never a private helper reimplemented here. Uses
# expect_identical() throughout, never expect_equal()'s tolerance, because
# tolerance is exactly what would hide this defect.

KEYS <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
BASE <- "https://api.binance.com"

# ---- fixture: decimal strings with many significant digits ------------------

# A value just under 2^53 (the largest integer a double represents exactly),
# used as a character-typed identifier (`symbol`, and the kline `ignore`
# field) to prove an identifier-shaped column is never accidentally coerced
# to numeric.
.precision_big_id <- "9007199254740991"

.precision_strings <- list(
  a = "0.00023456789",
  b = "12345.678901234",
  c = "0.000000123456",
  d = "1e-10"
)

# Raw JSON, authored as literal text so the exact wire digits/strings below
# are what the parser actually sees.
.precision_klines_json <- sprintf(
  paste0(
    "[[1700000000000,\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",",
    "1700003599999,\"%s\",42,\"%s\",\"%s\",\"%s\"]]"
  ),
  .precision_strings$a,
  .precision_strings$b,
  .precision_strings$c,
  .precision_strings$d,
  .precision_strings$b,
  .precision_strings$a,
  .precision_strings$c,
  .precision_strings$d,
  .precision_big_id
)

.precision_book_ticker_json <- sprintf(
  '{"symbol":"%s","bidPrice":"%s","bidQty":"%s","askPrice":"%s","askQty":"%s"}',
  .precision_big_id,
  .precision_strings$a,
  .precision_strings$b,
  .precision_strings$c,
  .precision_strings$d
)

# A tiny URL-pattern route table covering exactly the two endpoints this test
# drives, built the same way the shared mock_router.R does, but with a
# synthetic high-precision fixture instead of the captured/synthetic
# real-shaped fixtures.
precision_routes <- function() {
  return(list(
    list(pattern = "api/v3/klines", fixture = .precision_klines_json),
    list(pattern = "api/v3/ticker/bookTicker", fixture = .precision_book_ticker_json)
  ))
}

# A shared digit-level check: sprintf("%.17g", .) prints enough significant
# digits to uniquely round-trip an IEEE-754 double, so if the parser silently
# narrowed the value (round()/signif()/a %.Nf format), the 17-digit rendering
# of the parsed value would diverge from the 17-digit rendering of the
# fixture's own as.numeric() value.
expect_full_precision <- function(actual, fixture_string) {
  expected <- as.numeric(fixture_string)
  expect_identical(actual, expected)
  return(expect_identical(sprintf("%.17g", actual), sprintf("%.17g", expected)))
}

new_market <- function() {
  return(BinanceMarketData$new(keys = KEYS, base_url = BASE))
}

# ---- candle/kline path: get_klines -------------------------------------------

test_that("get_klines preserves full OHLCV precision through the real parse path", {
  connectcore::local_mock_api(precision_routes())
  dt <- new_market()$get_klines("BTCUSDT", "1h")

  expect_identical(nrow(dt), 1L)
  expect_full_precision(dt$open, .precision_strings$a)
  expect_full_precision(dt$high, .precision_strings$b)
  expect_full_precision(dt$low, .precision_strings$c)
  expect_full_precision(dt$close, .precision_strings$d)
  expect_full_precision(dt$volume, .precision_strings$b)
  expect_full_precision(dt$quote_volume, .precision_strings$a)
  expect_full_precision(dt$taker_buy_base_volume, .precision_strings$c)
  expect_full_precision(dt$taker_buy_quote_volume, .precision_strings$d)
  # `ignore` stays character, byte-identical, never coerced to numeric.
  expect_type(dt$ignore, "character")
  expect_identical(dt$ignore, .precision_big_id)
})

# ---- ticker/market-data snapshot path: get_book_ticker -----------------------

test_that("get_book_ticker returns every price/quantity field byte-identical, uncoerced", {
  connectcore::local_mock_api(precision_routes())
  dt <- new_market()$get_book_ticker("BTCUSDT")

  expect_identical(nrow(dt), 1L)
  # Binance's own wire format for this endpoint IS the decimal string; the
  # parser (as_dt_row(), a straight pass-through) must never convert it to a
  # double -- that would be the exact narrowing this regression guards
  # against, just approached from the opposite direction (an unwanted cast
  # instead of a lossy one).
  expect_type(dt$bid_price, "character")
  expect_identical(dt$bid_price, .precision_strings$a)
  expect_type(dt$bid_qty, "character")
  expect_identical(dt$bid_qty, .precision_strings$b)
  expect_type(dt$ask_price, "character")
  expect_identical(dt$ask_price, .precision_strings$c)
  expect_type(dt$ask_qty, "character")
  expect_identical(dt$ask_qty, .precision_strings$d)
  # the identifier stays character, byte-identical, never coerced to numeric.
  expect_type(dt$symbol, "character")
  expect_identical(dt$symbol, .precision_big_id)
})
