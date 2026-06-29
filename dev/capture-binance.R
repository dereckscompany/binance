#!/usr/bin/env Rscript
# File: dev/capture-binance.R
#
# READ-ONLY capture harness for the `binance` package.
#
# Purpose: hit the REAL Binance API with GET-only read requests against the
# PUBLIC market-data endpoints (no authentication) and dump each raw response
# body verbatim to local/raw-data/binance/<name>.json. Those captures are then
# compared by hand (or by a sibling validation script) against the SYNTHETIC
# fixtures committed in tests/testthat/fixtures/ to prove the public fixtures
# faithfully mirror the live wire shapes.
#
# SAFETY: this script issues ONLY HTTP GET requests against PUBLIC read
# endpoints (ping/time/exchangeInfo/ticker/depth/trades/klines/...). It sends NO
# API key, never POSTs/PUTs/PATCHes/DELETEs, never places/cancels orders, never
# moves funds. NO credentials are read or required. The private/account fixtures
# (account, orders, margin, futures account, sub-accounts) cannot be validated
# without keys and STAY SYNTHETIC. Raw bodies are written ONLY under
# local/raw-data/binance/ which is git-ignored.
#
# Run from the package root:
#   Rscript dev/capture-binance.R

suppressWarnings(suppressMessages({
  library(httr2)
  library(jsonlite)
}))

# ---------------------------------------------------------------------------
# Hosts -- public market data only; no credentials.
# ---------------------------------------------------------------------------
SPOT_HOST <- Sys.getenv("BINANCE_API_ENDPOINT")
if (!nzchar(SPOT_HOST)) {
  SPOT_HOST <- "https://api.binance.com"
}

FUTURES_HOST <- Sys.getenv("BINANCE_FUTURES_API_ENDPOINT")
if (!nzchar(FUTURES_HOST)) {
  FUTURES_HOST <- "https://fapi.binance.com"
}

OUT_DIR <- file.path("local", "raw-data", "binance")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Defensive: refuse to write anywhere git would track. local/ is git-ignored.
if (Sys.which("git") != "") {
  probe <- file.path(OUT_DIR, "ignore-probe.json")
  ignored <- suppressWarnings(system2(
    "git",
    c("check-ignore", probe),
    stdout = TRUE,
    stderr = FALSE
  ))
  if (length(ignored) == 0L) {
    stop(
      "Refusing to write: ",
      OUT_DIR,
      " is NOT git-ignored. Aborting to avoid committing raw captures."
    )
  }
}

cat("Spot host   :", SPOT_HOST, "\n")
cat("Futures host:", FUTURES_HOST, "\n")
cat("Output dir  :", normalizePath(OUT_DIR), "\n\n")

# ---------------------------------------------------------------------------
# One GET: perform, write raw body verbatim, log a one-line status. Wrapped so a
# single failure (network, 4xx, parse) never aborts the batch. NO auth header.
# ---------------------------------------------------------------------------
log_rows <- list()

is_empty_body <- function(parsed) {
  if (is.null(parsed)) {
    return(TRUE)
  }
  if (length(parsed) == 0L) {
    return(TRUE)
  }
  return(FALSE)
}

capture <- function(name, host, path, query = list()) {
  url <- paste0(host, path)
  result <- tryCatch(
    {
      req <- httr2::request(url) |>
        httr2::req_method("GET") |>
        httr2::req_timeout(30) |>
        # Do NOT throw on 4xx/5xx -- we want to capture the error body too.
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_user_agent("binance-capture-readonly/1.0")
      if (length(query) > 0L) {
        req <- httr2::req_url_query(req, !!!query)
      }
      resp <- httr2::req_perform(req)

      status <- httr2::resp_status(resp)
      body_raw <- httr2::resp_body_raw(resp)
      out_path <- file.path(OUT_DIR, paste0(name, ".json"))
      writeBin(body_raw, out_path)

      parsed <- tryCatch(
        jsonlite::fromJSON(rawToChar(body_raw), simplifyVector = FALSE),
        error = function(e) NULL
      )
      empty <- is_empty_body(parsed)
      list(
        name = name,
        status = status,
        bytes = length(body_raw),
        empty = empty,
        ok = status >= 200 && status < 300,
        parsed = parsed
      )
    },
    error = function(e) {
      list(
        name = name,
        status = NA_integer_,
        bytes = 0L,
        empty = NA,
        ok = FALSE,
        parsed = NULL,
        err = conditionMessage(e)
      )
    }
  )

  state <- if (!isTRUE(result$ok)) {
    "FAIL"
  } else if (isTRUE(result$empty)) {
    "EMPTY"
  } else {
    "POPULATED"
  }
  cat(sprintf(
    "%-28s GET %-34s status=%-4s bytes=%-8s %s%s\n",
    name,
    path,
    ifelse(is.na(result$status), "ERR", result$status),
    result$bytes,
    state,
    if (!is.null(result$err)) paste0("  <", result$err, ">") else ""
  ))
  log_rows[[name]] <<- result
  Sys.sleep(0.3) # be polite to Binance rate limits
  return(invisible(result))
}

# ---------------------------------------------------------------------------
# SPOT PUBLIC market data (api.binance.com) -- read endpoints only.
# Fixture name on the right of each line is the committed synthetic counterpart.
# ---------------------------------------------------------------------------
cat("== Spot Public Market Data ==\n")
capture("ping", SPOT_HOST, "/api/v3/ping")
capture("server_time_data", SPOT_HOST, "/api/v3/time")
# exchangeInfo is huge exchange-wide; pull a 2-symbol slice to mirror fixture.
capture("exchange_info_data", SPOT_HOST, "/api/v3/exchangeInfo", list(symbols = '["BTCUSDT","ETHUSDT"]'))
capture("ticker_data", SPOT_HOST, "/api/v3/ticker/price", list(symbol = "BTCUSDT"))
capture("all_tickers_data", SPOT_HOST, "/api/v3/ticker/price")
capture("book_ticker_data", SPOT_HOST, "/api/v3/ticker/bookTicker", list(symbol = "BTCUSDT"))
capture("24hr_stats_data", SPOT_HOST, "/api/v3/ticker/24hr", list(symbol = "BTCUSDT"))
capture("all_24hr_stats_data", SPOT_HOST, "/api/v3/ticker/24hr", list(symbols = '["BTCUSDT","ETHUSDT"]'))
capture("avg_price_data", SPOT_HOST, "/api/v3/avgPrice", list(symbol = "BTCUSDT"))
capture("orderbook_data", SPOT_HOST, "/api/v3/depth", list(symbol = "BTCUSDT", limit = 5))
capture("trades_data", SPOT_HOST, "/api/v3/trades", list(symbol = "BTCUSDT", limit = 5))
capture("klines_data", SPOT_HOST, "/api/v3/klines", list(symbol = "BTCUSDT", interval = "1d", limit = 3))

# ---------------------------------------------------------------------------
# FUTURES PUBLIC market data (fapi.binance.com) -- read endpoints only.
# ---------------------------------------------------------------------------
cat("\n== Futures Public Market Data ==\n")
capture("futures_ping", FUTURES_HOST, "/fapi/v1/ping")
# Futures exchangeInfo has no symbol filter; capture full then we slice by hand.
capture("futures_exchange_info_data", FUTURES_HOST, "/fapi/v1/exchangeInfo")
capture("futures_klines_data", FUTURES_HOST, "/fapi/v1/klines", list(symbol = "BTCUSDT", interval = "1h", limit = 3))
capture("futures_mark_price_data", FUTURES_HOST, "/fapi/v1/premiumIndex", list(symbol = "BTCUSDT"))
capture("futures_funding_rate_data", FUTURES_HOST, "/fapi/v1/fundingRate", list(symbol = "BTCUSDT", limit = 3))
capture("futures_24hr_stats_data", FUTURES_HOST, "/fapi/v1/ticker/24hr", list(symbol = "BTCUSDT"))
capture("futures_ticker_data", FUTURES_HOST, "/fapi/v1/ticker/price", list(symbol = "BTCUSDT"))
capture("futures_book_ticker_data", FUTURES_HOST, "/fapi/v1/ticker/bookTicker", list(symbol = "BTCUSDT"))
capture("futures_open_interest_data", FUTURES_HOST, "/fapi/v1/openInterest", list(symbol = "BTCUSDT"))
capture("futures_depth_data", FUTURES_HOST, "/fapi/v1/depth", list(symbol = "BTCUSDT", limit = 5))
capture("futures_public_trades_data", FUTURES_HOST, "/fapi/v1/trades", list(symbol = "BTCUSDT", limit = 5))

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
cat("\n== Summary ==\n")
states <- vapply(
  log_rows,
  function(r) {
    if (!isTRUE(r$ok)) {
      "FAIL"
    } else if (isTRUE(r$empty)) {
      "EMPTY"
    } else {
      "POPULATED"
    }
  },
  character(1)
)
cat("POPULATED:", sum(states == "POPULATED"), "\n")
cat("EMPTY    :", sum(states == "EMPTY"), "\n")
cat("FAIL     :", sum(states == "FAIL"), "\n")
cat("Total    :", length(states), "\n")
cat("\nCaptures written to", OUT_DIR, "\n")
