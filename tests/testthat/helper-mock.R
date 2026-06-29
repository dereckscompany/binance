# tests/testthat/helper-mock.R
# Shared mock response builders for Binance API tests.
# Sources the synthetic JSON-backed fixture accessors from mockery.R and adds
# the test-only error-injection helpers (which have no JSON fixture equivalent).

# NOTE: We source() mockery.R rather than box::use(./mockery) so its mock_*()
# accessors and mock_response() land as loose globals in the test environment
# (box::use would bind them under a namespace object instead). mockery.R itself
# resolves its fixtures directory defensively for both the source() and the
# box::use() (README/vignette) contexts.
source(file.path(testthat::test_path(), "mockery.R"), local = TRUE)

# Backward-compatible alias
mock_binance_response <- mock_response

# ---------------------------------------------------------------------------
# Test-only helpers (not shared with README/vignettes)
# ---------------------------------------------------------------------------

#' Build a fake Binance error response (negative code in JSON body)
mock_binance_error <- function(code = -1013, msg = "Filter failure: LOT_SIZE", status_code = 400L) {
  body <- jsonlite::toJSON(
    list(code = code, msg = msg),
    auto_unbox = TRUE
  )
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  ))
}

#' Build a fake HTTP error response (non-200 status, no JSON)
mock_http_error <- function(status_code = 500L, body_text = "Internal Server Error") {
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "text/plain"),
    body = charToRaw(body_text)
  ))
}
