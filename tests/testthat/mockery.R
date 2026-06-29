# Synthetic Binance fixture accessors for tests, README, and vignettes.
#
# The fixture DATA lives as JSON under tests/testthat/fixtures/ (one file per
# endpoint, named <builder-without-mock-prefix>.json). This module is a thin
# accessor layer: each mock_*() returns the parsed JSON list for its fixture,
# so the on-disk JSON is the single source of truth shared by the connectcore
# route table (mock_router.R) and the direct-response tests.
#
# Fixtures are fully SYNTHETIC (no live capture, no real account data).
#
# Used in two ways:
#   1. As a box module via box::use() from README.Rmd and vignettes.
#   2. Via source() from helper-mock.R (testthat context).
# We use :: notation so it works in both contexts.

box::use(
  connectcore[load_fixtures, mock_response_cc = mock_response]
)

# Resolve the fixtures directory in BOTH contexts:
#   * box::use() (README/vignettes) -> box::file() points at this module's dir;
#   * source() (helper-mock.R under testthat) -> box::file() is unavailable, so
#     fall back to the testthat fixtures path.
.fixtures_dir <- tryCatch(
  box::file("fixtures"),
  error = function(e) testthat::test_path("fixtures")
)

# Parse every JSON fixture once into a named list (keyed by file basename),
# making the on-disk JSON the single source of truth for tests and docs.
.fixtures <- load_fixtures(.fixtures_dir, parse = TRUE)

#' Build a fake httr2 response with a Binance JSON body
#'
#' Thin wrapper over connectcore::mock_response that keeps the historical
#' binance signature (data, status_code) used across the test suite.
#' @export
mock_response <- function(data, status_code = 200L) {
  return(mock_response_cc(data, status = status_code))
}

#' @export
mock_24hr_stats_data <- function() {
  return(.fixtures$`24hr_stats_data`)
}

#' @export
mock_account_data <- function() {
  return(.fixtures$account_data)
}

#' @export
mock_all_24hr_stats_data <- function() {
  return(.fixtures$all_24hr_stats_data)
}

#' @export
mock_all_tickers_data <- function() {
  return(.fixtures$all_tickers_data)
}

#' @export
mock_avg_price_data <- function() {
  return(.fixtures$avg_price_data)
}

#' @export
mock_book_ticker_data <- function() {
  return(.fixtures$book_ticker_data)
}

#' @export
mock_cancel_order_data <- function() {
  return(.fixtures$cancel_order_data)
}

#' @export
mock_cross_margin_data <- function() {
  return(.fixtures$cross_margin_data)
}

#' @export
mock_deposit_address_data <- function() {
  return(.fixtures$deposit_address_data)
}

#' @export
mock_deposit_history_data <- function() {
  return(.fixtures$deposit_history_data)
}

#' @export
mock_exchange_info_data <- function() {
  return(.fixtures$exchange_info_data)
}

#' @export
mock_flexible_position_data <- function() {
  return(.fixtures$flexible_position_data)
}

#' @export
mock_flexible_products_data <- function() {
  return(.fixtures$flexible_products_data)
}

#' @export
mock_flexible_redeem_response <- function() {
  return(.fixtures$flexible_redeem_response)
}

#' @export
mock_flexible_subscribe_response <- function() {
  return(.fixtures$flexible_subscribe_response)
}

#' @export
mock_flexible_subscription_history_data <- function() {
  return(.fixtures$flexible_subscription_history_data)
}

#' @export
mock_futures_account_data <- function() {
  return(.fixtures$futures_account_data)
}

#' @export
mock_futures_balances_data <- function() {
  return(.fixtures$futures_balances_data)
}

#' @export
mock_futures_cancel_all_response <- function() {
  return(.fixtures$futures_cancel_all_response)
}

#' @export
mock_futures_exchange_info_data <- function() {
  return(.fixtures$futures_exchange_info_data)
}

#' @export
mock_futures_funding_rate_data <- function() {
  return(.fixtures$futures_funding_rate_data)
}

#' @export
mock_futures_income_data <- function() {
  return(.fixtures$futures_income_data)
}

#' @export
mock_futures_leverage_response <- function() {
  return(.fixtures$futures_leverage_response)
}

#' @export
mock_futures_margin_type_response <- function() {
  return(.fixtures$futures_margin_type_response)
}

#' @export
mock_futures_mark_price_data <- function() {
  return(.fixtures$futures_mark_price_data)
}

#' @export
mock_futures_modify_position_margin_response <- function() {
  return(.fixtures$futures_modify_position_margin_response)
}

#' @export
mock_futures_open_interest_data <- function() {
  return(.fixtures$futures_open_interest_data)
}

#' @export
mock_futures_order_response <- function() {
  return(.fixtures$futures_order_response)
}

#' @export
mock_futures_position_margin_history_data <- function() {
  return(.fixtures$futures_position_margin_history_data)
}

#' @export
mock_futures_position_mode_data <- function() {
  return(.fixtures$futures_position_mode_data)
}

#' @export
mock_futures_positions_data <- function() {
  return(.fixtures$futures_positions_data)
}

#' @export
mock_futures_ticker_data <- function() {
  return(.fixtures$futures_ticker_data)
}

#' @export
mock_futures_trades_data <- function() {
  return(.fixtures$futures_trades_data)
}

#' @export
mock_interest_rate_history_data <- function() {
  return(.fixtures$interest_rate_history_data)
}

#' @export
mock_isolated_margin_account_data <- function() {
  return(.fixtures$isolated_margin_account_data)
}

#' @export
mock_isolated_margin_data <- function() {
  return(.fixtures$isolated_margin_data)
}

#' @export
mock_isolated_transfer_response <- function() {
  return(.fixtures$isolated_transfer_response)
}

#' @export
mock_klines_data <- function() {
  return(.fixtures$klines_data)
}

#' @export
mock_locked_products_data <- function() {
  return(.fixtures$locked_products_data)
}

#' @export
mock_locked_redeem_response <- function() {
  return(.fixtures$locked_redeem_response)
}

#' @export
mock_locked_subscribe_response <- function() {
  return(.fixtures$locked_subscribe_response)
}

#' @export
mock_margin_account_data <- function() {
  return(.fixtures$margin_account_data)
}

#' @export
mock_margin_all_pairs_data <- function() {
  return(.fixtures$margin_all_pairs_data)
}

#' @export
mock_margin_borrow_response <- function() {
  return(.fixtures$margin_borrow_response)
}

#' @export
mock_margin_cancel_order_data <- function() {
  return(.fixtures$margin_cancel_order_data)
}

#' @export
mock_margin_force_liquidation_data <- function() {
  return(.fixtures$margin_force_liquidation_data)
}

#' @export
mock_margin_interest_history_data <- function() {
  return(.fixtures$margin_interest_history_data)
}

#' @export
mock_margin_isolated_pairs_data <- function() {
  return(.fixtures$margin_isolated_pairs_data)
}

#' @export
mock_margin_max_transferable_data <- function() {
  return(.fixtures$margin_max_transferable_data)
}

#' @export
mock_margin_order_response <- function() {
  return(.fixtures$margin_order_response)
}

#' @export
mock_margin_price_index_data <- function() {
  return(.fixtures$margin_price_index_data)
}

#' @export
mock_margin_query_order_data <- function() {
  return(.fixtures$margin_query_order_data)
}

#' @export
mock_margin_trades_data <- function() {
  return(.fixtures$margin_trades_data)
}

#' @export
mock_max_borrowable_data <- function() {
  return(.fixtures$max_borrowable_data)
}

#' @export
mock_my_trades_data <- function() {
  return(.fixtures$my_trades_data)
}

#' @export
mock_oco_order_response <- function() {
  return(.fixtures$oco_order_response)
}

#' @export
mock_oco_query_data <- function() {
  return(.fixtures$oco_query_data)
}

#' @export
mock_open_orders_data <- function() {
  return(.fixtures$open_orders_data)
}

#' @export
mock_order_response <- function() {
  return(.fixtures$order_response)
}

#' @export
mock_orderbook_data <- function() {
  return(.fixtures$orderbook_data)
}

#' @export
mock_query_order_data <- function() {
  return(.fixtures$query_order_data)
}

#' @export
mock_server_time_data <- function() {
  return(.fixtures$server_time_data)
}

#' @export
mock_sub_account_balances_data <- function() {
  return(.fixtures$sub_account_balances_data)
}

#' @export
mock_sub_account_create_response <- function() {
  return(.fixtures$sub_account_create_response)
}

#' @export
mock_sub_account_list_data <- function() {
  return(.fixtures$sub_account_list_data)
}

#' @export
mock_sub_account_status_data <- function() {
  return(.fixtures$sub_account_status_data)
}

#' @export
mock_sub_account_transfer_history_data <- function() {
  return(.fixtures$sub_account_transfer_history_data)
}

#' @export
mock_sub_account_transfer_response <- function() {
  return(.fixtures$sub_account_transfer_response)
}

#' @export
mock_ticker_data <- function() {
  return(.fixtures$ticker_data)
}

#' @export
mock_trades_data <- function() {
  return(.fixtures$trades_data)
}

#' @export
mock_transfer_history_data <- function() {
  return(.fixtures$transfer_history_data)
}

#' @export
mock_transfer_response <- function() {
  return(.fixtures$transfer_response)
}

#' @export
mock_withdrawal_history_data <- function() {
  return(.fixtures$withdrawal_history_data)
}

#' @export
mock_withdrawal_response <- function() {
  return(.fixtures$withdrawal_response)
}
