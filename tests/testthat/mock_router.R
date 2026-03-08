# Shared mock HTTP router for README and vignettes.
#
# Dispatches httr2 requests to fixture data based on URL pattern matching.
# Fixtures come from mockery.R; this file only handles routing logic.
#
# Usage (in a hidden knitr setup chunk):
#   box::use(./tests/testthat/mock_router[mock_router])
#   options(httr2_mock = mock_router)

# Load all fixtures from mockery.R (sibling file)
box::use(./mockery[
  mock_response,
  mock_server_time_data, mock_exchange_info_data,
  mock_ticker_data, mock_all_tickers_data, mock_book_ticker_data,
  mock_24hr_stats_data, mock_avg_price_data,
  mock_orderbook_data, mock_trades_data, mock_klines_data,
  mock_order_response, mock_cancel_order_data, mock_query_order_data,
  mock_open_orders_data,
  mock_account_data, mock_my_trades_data
])

#' Route table: URL pattern -> fixture thunk
#' Order matters — more specific patterns first.
#' @keywords internal
.mock_routes <- list(
  # Market data
  list(pattern = "api/v3/time", fixture = function() mock_server_time_data()),
  list(pattern = "api/v3/exchangeInfo", fixture = function() mock_exchange_info_data()),
  list(pattern = "api/v3/ticker/bookTicker", fixture = function() mock_book_ticker_data()),
  list(pattern = "api/v3/ticker/24hr", fixture = function() mock_24hr_stats_data()),
  list(pattern = "api/v3/ticker/price", fixture = function() mock_ticker_data()),
  list(pattern = "api/v3/avgPrice", fixture = function() mock_avg_price_data()),
  list(pattern = "api/v3/depth", fixture = function() mock_orderbook_data()),
  list(pattern = "api/v3/trades", fixture = function() mock_trades_data()),
  list(pattern = "api/v3/klines", fixture = function() mock_klines_data()),
  # Trading (order matters: test before generic order)
  list(pattern = "api/v3/order/test", fixture = function() list(), method = "POST"),
  list(pattern = "api/v3/order", fixture = function() mock_order_response(), method = "POST"),
  list(pattern = "api/v3/order", fixture = function() mock_cancel_order_data(), method = "DELETE"),
  list(pattern = "api/v3/openOrders", fixture = function() mock_open_orders_data(), method = "GET"),
  list(pattern = "api/v3/openOrders", fixture = function() list(mock_cancel_order_data()), method = "DELETE"),
  list(pattern = "api/v3/allOrders", fixture = function() mock_open_orders_data()),
  list(pattern = "api/v3/order", fixture = function() mock_query_order_data(), method = "GET"),
  # Account
  list(pattern = "api/v3/account", fixture = function() mock_account_data()),
  list(pattern = "api/v3/myTrades", fixture = function() mock_my_trades_data())
)

#' Mock HTTP router for README and vignettes
#'
#' Dispatches `httr2` requests to fixture data based on URL pattern matching.
#' Set via `options(httr2_mock = mock_router)` in a hidden knitr setup chunk.
#'
#' @param req An `httr2_request` object.
#' @return An `httr2_response` object.
#' @export
mock_router <- function(req) {
  url <- req$url
  method <- req$method

  # Route table lookup
  for (route in .mock_routes) {
    if (grepl(route$pattern, url, fixed = TRUE)) {
      if (!is.null(route$method) && method != route$method) {
        next
      }
      return(mock_response(route$fixture()))
    }
  }

  stop("Unmocked request: ", method, " ", url)
}
