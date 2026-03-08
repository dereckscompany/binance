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
  # Market data
  mock_server_time_data, mock_exchange_info_data,
  mock_ticker_data, mock_all_tickers_data, mock_book_ticker_data,
  mock_24hr_stats_data, mock_avg_price_data,
  mock_orderbook_data, mock_trades_data, mock_klines_data,
  # Trading
  mock_order_response, mock_cancel_order_data, mock_query_order_data,
  mock_open_orders_data,
  # Account
  mock_account_data, mock_my_trades_data,
  # Deposit / Withdrawal
  mock_deposit_address_data, mock_deposit_history_data,
  mock_withdrawal_response, mock_withdrawal_history_data,
  # OCO Orders
  mock_oco_order_response, mock_oco_query_data,
  # Transfer
  mock_transfer_response, mock_transfer_history_data,
  # Margin Data
  mock_margin_all_pairs_data, mock_margin_price_index_data,
  mock_cross_margin_data, mock_interest_rate_history_data,
  # Margin Trading
  mock_margin_borrow_response, mock_margin_order_response,
  mock_margin_account_data, mock_max_borrowable_data,
  mock_margin_trades_data,
  # Sub-Account
  mock_sub_account_list_data,
  # Earn
  mock_flexible_products_data, mock_flexible_subscribe_response,
  mock_flexible_position_data,
  # Futures Data
  mock_futures_exchange_info_data, mock_futures_mark_price_data,
  mock_futures_funding_rate_data, mock_futures_open_interest_data,
  mock_futures_ticker_data,
  # Futures Trading
  mock_futures_order_response, mock_futures_cancel_all_response,
  mock_futures_account_data, mock_futures_balances_data,
  mock_futures_positions_data, mock_futures_leverage_response,
  mock_futures_margin_type_response, mock_futures_trades_data,
  mock_futures_income_data, mock_futures_position_mode_data
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
  list(pattern = "api/v3/myTrades", fixture = function() mock_my_trades_data()),
  # Deposit
  list(pattern = "sapi/v1/capital/deposit/address", fixture = function() mock_deposit_address_data()),
  list(pattern = "sapi/v1/capital/deposit/hisrec", fixture = function() mock_deposit_history_data()),
  # Withdrawal
  list(pattern = "sapi/v1/capital/withdraw/apply", fixture = function() mock_withdrawal_response(), method = "POST"),
  list(pattern = "sapi/v1/capital/withdraw/history", fixture = function() mock_withdrawal_history_data()),
  # OCO Orders
  list(pattern = "api/v3/order/oco", fixture = function() mock_oco_order_response(), method = "POST"),
  list(pattern = "api/v3/openOrderList", fixture = function() list(mock_oco_query_data()), method = "GET"),
  list(pattern = "api/v3/allOrderList", fixture = function() list(mock_oco_query_data()), method = "GET"),
  list(pattern = "api/v3/orderList", fixture = function() mock_oco_query_data(), method = "GET"),
  list(pattern = "api/v3/orderList", fixture = function() mock_oco_order_response(), method = "DELETE"),
  # Transfer
  list(pattern = "sapi/v1/asset/transfer", fixture = function() mock_transfer_response(), method = "POST"),
  list(pattern = "sapi/v1/asset/transfer", fixture = function() mock_transfer_history_data(), method = "GET"),
  # Margin Data
  list(pattern = "sapi/v1/margin/allPairs", fixture = function() mock_margin_all_pairs_data()),
  list(pattern = "sapi/v1/margin/priceIndex", fixture = function() mock_margin_price_index_data()),
  list(pattern = "sapi/v1/margin/crossMarginData", fixture = function() mock_cross_margin_data()),
  list(pattern = "sapi/v1/margin/interestRateHistory", fixture = function() mock_interest_rate_history_data()),
  # Margin Trading
  list(pattern = "sapi/v1/margin/borrow-repay", fixture = function() mock_margin_borrow_response(), method = "POST"),
  list(pattern = "sapi/v1/margin/order", fixture = function() mock_margin_order_response(), method = "POST"),
  list(pattern = "sapi/v1/margin/order", fixture = function() mock_margin_order_response(), method = "DELETE"),
  list(pattern = "sapi/v1/margin/openOrders", fixture = function() list(mock_margin_order_response())),
  list(pattern = "sapi/v1/margin/allOrders", fixture = function() list(mock_margin_order_response())),
  list(pattern = "sapi/v1/margin/account", fixture = function() mock_margin_account_data()),
  list(pattern = "sapi/v1/margin/maxBorrowable", fixture = function() mock_max_borrowable_data()),
  list(pattern = "sapi/v1/margin/myTrades", fixture = function() mock_margin_trades_data()),
  # Sub-Account
  list(pattern = "sapi/v1/sub-account/list", fixture = function() mock_sub_account_list_data()),
  # Earn
  list(pattern = "sapi/v1/simple-earn/flexible/list", fixture = function() mock_flexible_products_data()),
  list(pattern = "sapi/v1/simple-earn/flexible/subscribe", fixture = function() mock_flexible_subscribe_response(), method = "POST"),
  list(pattern = "sapi/v1/simple-earn/flexible/position", fixture = function() mock_flexible_position_data()),
  # Futures Data (fapi endpoints)
  list(pattern = "fapi/v1/exchangeInfo", fixture = function() mock_futures_exchange_info_data()),
  list(pattern = "fapi/v1/premiumIndex", fixture = function() mock_futures_mark_price_data()),
  list(pattern = "fapi/v1/fundingRate", fixture = function() mock_futures_funding_rate_data()),
  list(pattern = "fapi/v1/openInterest", fixture = function() mock_futures_open_interest_data()),
  list(pattern = "fapi/v1/ticker/24hr", fixture = function() mock_24hr_stats_data()),
  list(pattern = "fapi/v1/ticker/price", fixture = function() mock_futures_ticker_data()),
  list(pattern = "fapi/v1/ticker/bookTicker", fixture = function() mock_book_ticker_data()),
  list(pattern = "fapi/v1/depth", fixture = function() mock_orderbook_data()),
  list(pattern = "fapi/v1/trades", fixture = function() mock_trades_data()),
  list(pattern = "fapi/v1/klines", fixture = function() mock_klines_data()),
  list(pattern = "fapi/v1/markPriceKlines", fixture = function() mock_klines_data()),
  list(pattern = "fapi/v1/indexPriceKlines", fixture = function() mock_klines_data()),
  # Futures Trading
  list(pattern = "fapi/v1/order/test", fixture = function() list(), method = "POST"),
  list(pattern = "fapi/v1/order", fixture = function() mock_futures_order_response(), method = "POST"),
  list(pattern = "fapi/v1/order", fixture = function() mock_futures_order_response(), method = "DELETE"),
  list(pattern = "fapi/v1/allOpenOrders", fixture = function() mock_futures_cancel_all_response(), method = "DELETE"),
  list(pattern = "fapi/v1/openOrders", fixture = function() list(mock_futures_order_response())),
  list(pattern = "fapi/v1/allOrders", fixture = function() list(mock_futures_order_response())),
  list(pattern = "fapi/v1/order", fixture = function() mock_futures_order_response(), method = "GET"),
  list(pattern = "fapi/v2/account", fixture = function() mock_futures_account_data()),
  list(pattern = "fapi/v2/balance", fixture = function() mock_futures_balances_data()),
  list(pattern = "fapi/v2/positionRisk", fixture = function() mock_futures_positions_data()),
  list(pattern = "fapi/v1/leverage", fixture = function() mock_futures_leverage_response(), method = "POST"),
  list(pattern = "fapi/v1/marginType", fixture = function() mock_futures_margin_type_response(), method = "POST"),
  list(pattern = "fapi/v1/userTrades", fixture = function() mock_futures_trades_data()),
  list(pattern = "fapi/v1/income", fixture = function() mock_futures_income_data()),
  list(pattern = "fapi/v1/positionSide/dual", fixture = function() mock_futures_position_mode_data(), method = "GET"),
  list(pattern = "fapi/v1/positionSide/dual", fixture = function() mock_futures_margin_type_response(), method = "POST")
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
