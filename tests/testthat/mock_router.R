# Shared mock HTTP router for the binance README, vignettes, and tests.
#
# This is the THIN binance-specific layer over connectcore's shared mock harness
# (connectcore::mock_router / with_mock_api / local_mock_api / load_fixtures /
# mock_response). connectcore owns the response builder, the dispatch loop, and
# the scoped-activation helpers; this file only declares the route table — URL
# substring (+ optional HTTP method) -> the fixture for that endpoint — and loads
# the fixtures from disk.
#
# Each route's fixture is the SYNTHETIC binance JSON for that endpoint, parsed
# verbatim from tests/testthat/fixtures/*.json by connectcore::load_fixtures()
# (a named list keyed by file basename; here parsed to a list so the few routes
# that wrap a single object in an array can do so). The fixtures are fully
# synthetic — no live capture, no real account data.
#
# httr2 exposes a native global mock hook: connectcore::with_mock_api(.mock_routes,
# { ... }) (or local_mock_api(.mock_routes)) installs the dispatcher as the
# httr2_mock option, intercepting every req_perform / req_perform_promise call,
# so docs render and tests run against canned, deterministic data with no
# network, no real credentials, and no funds.
#
# Usage (in a hidden knitr setup chunk or a test):
#   box::use(./tests/testthat/mock_router[.mock_routes])
#   connectcore::with_mock_api(.mock_routes, { ...code... })  # scoped to a block
#   connectcore::local_mock_api(.mock_routes)                 # scoped to a frame

box::use(
  connectcore[load_fixtures, mock_router_cc = mock_router]
)

# Parse every synthetic fixture once into a named list, keyed by file basename
# (account_data.json -> "account_data"). Resolved relative to THIS module file
# so it works from the package root (README), vignettes/, and tests/testthat.
.fixtures <- load_fixtures(box::file("fixtures"), parse = TRUE)

# Binance returns one object with a `symbol` query param vs. the full array
# without it, on the SAME ticker URL (verified against the live API). Every other
# venue uses a distinct path for single-vs-all, so this query reader stays local
# here rather than in connectcore.
.absent <- function(req, param) is.null(httr2::url_parse(req$url)$query[[param]])

#' Route table: URL substring (+ optional method) -> synthetic-fixture list.
#'
#' Order matters — more specific patterns first. Each `fixture` is the parsed
#' fixture list (served by connectcore::mock_response), or a thunk for the few
#' endpoints whose live response wraps a single fixture object in an array.
#' @export
.mock_routes <- list(
  # ---- Spot market data (api.binance.com) ----
  list(pattern = "api/v3/time", fixture = .fixtures$server_time_data),
  list(pattern = "api/v3/exchangeInfo", fixture = .fixtures$exchange_info_data),
  list(pattern = "api/v3/ticker/bookTicker", fixture = .fixtures$book_ticker_data),
  # /ticker/24hr and /ticker/price return one row with `symbol`, all rows without
  # (live-verified). The "absent -> all" route must precede the single fallback.
  list(
    match = function(req) grepl("api/v3/ticker/24hr", req$url, fixed = TRUE) && .absent(req, "symbol"),
    fixture = .fixtures$all_24hr_stats_data
  ),
  list(pattern = "api/v3/ticker/24hr", fixture = .fixtures$"24hr_stats_data"),
  list(
    match = function(req) grepl("api/v3/ticker/price", req$url, fixed = TRUE) && .absent(req, "symbol"),
    fixture = .fixtures$all_tickers_data
  ),
  list(pattern = "api/v3/ticker/price", fixture = .fixtures$ticker_data),
  list(pattern = "api/v3/avgPrice", fixture = .fixtures$avg_price_data),
  list(pattern = "api/v3/depth", fixture = .fixtures$orderbook_data),
  list(pattern = "api/v3/trades", fixture = .fixtures$trades_data),
  list(pattern = "api/v3/klines", fixture = .fixtures$klines_data),

  # ---- Spot trading (order matters: test before generic order) ----
  list(pattern = "api/v3/order/test", fixture = list(), method = "POST"),
  list(pattern = "api/v3/order", fixture = .fixtures$order_response, method = "POST"),
  list(pattern = "api/v3/order", fixture = .fixtures$cancel_order_data, method = "DELETE"),
  list(pattern = "api/v3/openOrders", fixture = .fixtures$open_orders_data, method = "GET"),
  list(pattern = "api/v3/openOrders", fixture = function() list(.fixtures$cancel_order_data), method = "DELETE"),
  list(pattern = "api/v3/allOrders", fixture = .fixtures$open_orders_data),
  list(pattern = "api/v3/order", fixture = .fixtures$query_order_data, method = "GET"),

  # ---- Account ----
  list(pattern = "api/v3/account", fixture = .fixtures$account_data),
  list(pattern = "api/v3/myTrades", fixture = .fixtures$my_trades_data),

  # ---- Deposit ----
  list(pattern = "sapi/v1/capital/deposit/address", fixture = .fixtures$deposit_address_data),
  list(pattern = "sapi/v1/capital/deposit/hisrec", fixture = .fixtures$deposit_history_data),

  # ---- Withdrawal ----
  list(pattern = "sapi/v1/capital/withdraw/apply", fixture = .fixtures$withdrawal_response, method = "POST"),
  list(pattern = "sapi/v1/capital/withdraw/history", fixture = .fixtures$withdrawal_history_data),

  # ---- OCO orders ----
  list(pattern = "api/v3/order/oco", fixture = .fixtures$oco_order_response, method = "POST"),
  list(pattern = "api/v3/openOrderList", fixture = function() list(.fixtures$oco_query_data), method = "GET"),
  list(pattern = "api/v3/allOrderList", fixture = function() list(.fixtures$oco_query_data), method = "GET"),
  list(pattern = "api/v3/orderList", fixture = .fixtures$oco_query_data, method = "GET"),
  list(pattern = "api/v3/orderList", fixture = .fixtures$oco_order_response, method = "DELETE"),

  # ---- Transfer ----
  list(pattern = "sapi/v1/asset/transfer", fixture = .fixtures$transfer_response, method = "POST"),
  list(pattern = "sapi/v1/asset/transfer", fixture = .fixtures$transfer_history_data, method = "GET"),

  # ---- Margin data ----
  list(pattern = "sapi/v1/margin/allPairs", fixture = .fixtures$margin_all_pairs_data),
  list(pattern = "sapi/v1/margin/priceIndex", fixture = .fixtures$margin_price_index_data),
  list(pattern = "sapi/v1/margin/crossMarginData", fixture = .fixtures$cross_margin_data),
  list(pattern = "sapi/v1/margin/interestRateHistory", fixture = .fixtures$interest_rate_history_data),

  # ---- Margin trading ----
  list(pattern = "sapi/v1/margin/borrow-repay", fixture = .fixtures$margin_borrow_response, method = "POST"),
  list(pattern = "sapi/v1/margin/order", fixture = .fixtures$margin_order_response, method = "POST"),
  list(pattern = "sapi/v1/margin/order", fixture = .fixtures$margin_order_response, method = "DELETE"),
  list(pattern = "sapi/v1/margin/openOrders", fixture = function() list(.fixtures$margin_order_response)),
  list(pattern = "sapi/v1/margin/allOrders", fixture = function() list(.fixtures$margin_order_response)),
  list(pattern = "sapi/v1/margin/account", fixture = .fixtures$margin_account_data),
  list(pattern = "sapi/v1/margin/maxBorrowable", fixture = .fixtures$max_borrowable_data),
  list(pattern = "sapi/v1/margin/myTrades", fixture = .fixtures$margin_trades_data),

  # ---- Sub-account ----
  list(pattern = "sapi/v1/sub-account/list", fixture = .fixtures$sub_account_list_data),

  # ---- Earn ----
  list(pattern = "sapi/v1/simple-earn/flexible/list", fixture = .fixtures$flexible_products_data),
  list(
    pattern = "sapi/v1/simple-earn/flexible/subscribe",
    fixture = .fixtures$flexible_subscribe_response,
    method = "POST"
  ),
  list(pattern = "sapi/v1/simple-earn/flexible/position", fixture = .fixtures$flexible_position_data),

  # ---- Futures data (fapi) ----
  list(pattern = "fapi/v1/exchangeInfo", fixture = .fixtures$futures_exchange_info_data),
  list(pattern = "fapi/v1/premiumIndex", fixture = .fixtures$futures_mark_price_data),
  list(pattern = "fapi/v1/fundingRate", fixture = .fixtures$futures_funding_rate_data),
  list(pattern = "fapi/v1/openInterest", fixture = .fixtures$futures_open_interest_data),
  list(pattern = "fapi/v1/ticker/24hr", fixture = .fixtures$"24hr_stats_data"),
  list(pattern = "fapi/v1/ticker/price", fixture = .fixtures$futures_ticker_data),
  list(pattern = "fapi/v1/ticker/bookTicker", fixture = .fixtures$book_ticker_data),
  list(pattern = "fapi/v1/depth", fixture = .fixtures$orderbook_data),
  list(pattern = "fapi/v1/trades", fixture = .fixtures$trades_data),
  list(pattern = "fapi/v1/klines", fixture = .fixtures$klines_data),
  list(pattern = "fapi/v1/markPriceKlines", fixture = .fixtures$klines_data),
  list(pattern = "fapi/v1/indexPriceKlines", fixture = .fixtures$klines_data),

  # ---- Futures trading ----
  list(pattern = "fapi/v1/order/test", fixture = list(), method = "POST"),
  list(pattern = "fapi/v1/order", fixture = .fixtures$futures_order_response, method = "POST"),
  list(pattern = "fapi/v1/order", fixture = .fixtures$futures_order_response, method = "DELETE"),
  list(pattern = "fapi/v1/allOpenOrders", fixture = .fixtures$futures_cancel_all_response, method = "DELETE"),
  list(pattern = "fapi/v1/openOrders", fixture = function() list(.fixtures$futures_order_response)),
  list(pattern = "fapi/v1/allOrders", fixture = function() list(.fixtures$futures_order_response)),
  list(pattern = "fapi/v1/order", fixture = .fixtures$futures_order_response, method = "GET"),
  list(pattern = "fapi/v2/account", fixture = .fixtures$futures_account_data),
  list(pattern = "fapi/v2/balance", fixture = .fixtures$futures_balances_data),
  list(pattern = "fapi/v2/positionRisk", fixture = .fixtures$futures_positions_data),
  list(pattern = "fapi/v1/leverage", fixture = .fixtures$futures_leverage_response, method = "POST"),
  list(pattern = "fapi/v1/marginType", fixture = .fixtures$futures_margin_type_response, method = "POST"),
  list(pattern = "fapi/v1/userTrades", fixture = .fixtures$futures_trades_data),
  list(pattern = "fapi/v1/income", fixture = .fixtures$futures_income_data),
  list(pattern = "fapi/v1/positionSide/dual", fixture = .fixtures$futures_position_mode_data, method = "GET"),
  list(pattern = "fapi/v1/positionSide/dual", fixture = .fixtures$futures_margin_type_response, method = "POST")
)

#' Mock HTTP router for the README and vignettes (back-compat shim).
#'
#' A ready-built dispatcher over `.mock_routes`, for the docs that install the
#' hook directly with `options(httr2_mock = mock_router)`. Tests and new docs
#' should prefer `connectcore::with_mock_api(.mock_routes, { ... })` or
#' `connectcore::local_mock_api(.mock_routes)`.
#' @export
mock_router <- mock_router_cc(.mock_routes)
