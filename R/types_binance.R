# File: R/types_binance.R
# Reusable roxyassert `@type` shapes for the data.tables returned by the Binance
# REST endpoint classes. Modelled on tradebot-core's R/types_exchange.R.

#' @title Binance REST return shapes
#' @description Reusable roxyassert `@type` shapes for the `data.table`s returned
#' by the Binance REST endpoint classes. A method documents its return as
#' `(promise<Shape>)` (a Binance call returns a value in sync mode or a
#' `promises::promise` resolving to the same value in async mode), and the
#' contract roclet expands the shape into the generated `assert_return_*` helper.
#' The helper is wired at the call site through
#' [connectcore::then_or_now()] so the row-and-column contract runs in BOTH
#' execution modes.
#'
#' Each column is typed to what the parser actually produces (verified against
#' the parse helpers in `R/helpers_parse.R` and the `tests/testthat` fixtures).
#' Binance returns most numeric quantities as JSON **strings**, so price/size/
#' quantity columns are `character` unless a parser explicitly coerces them
#' (klines and the order book coerce to `numeric`; `numeric` is the strict
#' double, per the package convention). Millisecond timestamps the parsers run
#' through `ms_to_datetime()` become `POSIXct`. A column is marked `| NA` only
#' where the value can legitimately be missing in the parsed result.
#'
#' Only shapes returned by three or more methods, or that derive from one another
#' (`extends` / `pick` / `omit`), are declared here; a one-off return is written
#' inline at its method with the same column-bullet grammar.
#'
#' Each shape is referenced by a table-returning method's `@return`, so the
#' contract roclet expands it inline into that method's generated
#' `assert_return_*` -- no standalone `assert_type_<Shape>()` is emitted. binance
#' is a leaf connector: nothing internal calls a per-shape validator and no
#' downstream package validates against these shapes, so there is no `@genassert`
#' (no callable validators to generate) and no `@exportassert` (nothing to
#' export).
#' @name binance_shapes
#'
#' @type Ohlcv (data.table) one row per candle, as parsed by `parse_klines()`
#'   (shared by spot `get_klines()` and the futures kline endpoints):
#' - open_time (POSIXct) candle open time.
#' - open (numeric) open price.
#' - high (numeric) high price.
#' - low (numeric) low price.
#' - close (numeric) close price.
#' - volume (numeric) base-asset volume traded.
#' - close_time (POSIXct) candle close time.
#' - quote_volume (numeric) quote-asset volume traded.
#' - trades (integer) number of trades in the interval.
#' - taker_buy_base_volume (numeric) base-asset volume bought by takers.
#' - taker_buy_quote_volume (numeric) quote-asset volume bought by takers.
#' - ignore (character) unused field Binance returns as a string.
#'
#' @type OrderBook (data.table) one row per price level, as parsed by
#'   `parse_orderbook()` (bids first, then asks):
#' - last_update_id (character) order-book sequence id (same on every row).
#' - side (character in c("bid", "ask")) book side.
#' - price (numeric) level price.
#' - size (numeric) size available at the level.
#'
#' @type Trade (data.table) one row per public trade, as parsed from
#'   `GET /api/v3/trades` and `GET /fapi/v1/trades`:
#' - id (numeric) trade id (a 64-bit id; `numeric` to avoid 32-bit overflow).
#' - price (character) execution price.
#' - qty (character) base-asset quantity.
#' - quote_qty (character) quote-asset quantity.
#' - time (POSIXct) execution time.
#' - is_buyer_maker (logical) `TRUE` if the buyer was the maker.
#' - is_best_match (logical) `TRUE` if the trade was at the best price.
#'
#' @type BookTicker (data.table) one row, best bid/ask, shared by the spot and
#'   futures book-ticker endpoints:
#' - symbol (character) the trading pair.
#' - bid_price (character) best bid price.
#' - bid_qty (character) quantity at the best bid.
#' - ask_price (character) best ask price.
#' - ask_qty (character) quantity at the best ask.
#'
#' @type SpotOrderAck (data.table) the order-placement / cancel acknowledgement
#'   shared by spot trading. One row per order (a placement that fills expands
#'   into one row per fill via the `fill_*` columns, which are `NA` when the
#'   order placed with no fills):
#' - symbol (character) the trading pair.
#' - order_id (numeric) exchange-assigned order id (a 64-bit id; `numeric` to
#'   avoid 32-bit overflow).
#' - order_list_id (numeric) OCO list id, or `-1` for a non-OCO order (a 64-bit
#'   id; `numeric` to avoid 32-bit overflow).
#' - client_order_id (character) client-assigned order id.
#' - transact_time (POSIXct) transaction time.
#' - price (character) order price.
#' - orig_qty (character) original requested quantity.
#' - executed_qty (character) quantity filled so far.
#' - cummulative_quote_qty (character) cumulative quote quantity filled
#'   (Binance's field spelling, preserved).
#' - status (character) order status.
#' - time_in_force (character) time-in-force policy.
#' - type (character) order type.
#' - side (character) `"BUY"` or `"SELL"`.
#' - self_trade_prevention_mode (character) self-trade-prevention mode.
#'
#' @type SpotOrderQuery (data.table) the query / list order shape shared by spot
#'   `get_order()`, `get_open_orders()`, `get_all_orders()`. One row per order:
#' - symbol (character) the trading pair.
#' - order_id (numeric) exchange-assigned order id (a 64-bit id; `numeric` to
#'   avoid 32-bit overflow).
#' - order_list_id (numeric) OCO list id, or `-1` for a non-OCO order (a 64-bit
#'   id; `numeric` to avoid 32-bit overflow).
#' - client_order_id (character) client-assigned order id.
#' - price (character) order price.
#' - orig_qty (character) original requested quantity.
#' - executed_qty (character) quantity filled so far.
#' - cummulative_quote_qty (character) cumulative quote quantity filled.
#' - status (character) order status.
#' - time_in_force (character) time-in-force policy.
#' - type (character) order type.
#' - side (character) `"BUY"` or `"SELL"`.
#' - stop_price (character) stop trigger price (`"0.00000000"` when not a stop).
#' - iceberg_qty (character) iceberg quantity (`"0.00000000"` when not iceberg).
#' - time (POSIXct) order creation time.
#' - update_time (POSIXct) most recent update time.
#' - is_working (logical) whether the order is on the book.
#' - orig_quote_order_qty (character) original quote order quantity.
#' - working_time (POSIXct) time the order started working.
#' - self_trade_prevention_mode (character) self-trade-prevention mode.
#'
#' @type FuturesOrder (data.table) the USD-M futures order shape shared by
#'   `add_order()`, `cancel_order()`, `get_order()`, `get_open_orders()`,
#'   `get_all_orders()`. One row per order:
#' - order_id (numeric) exchange-assigned order id (a 64-bit id; `numeric` to
#'   avoid 32-bit overflow).
#' - symbol (character) the trading pair.
#' - status (character) order status.
#' - client_order_id (character) client-assigned order id.
#' - price (character) order price.
#' - avg_price (character) average fill price (`"0.00"` when unfilled).
#' - orig_qty (character) original requested quantity.
#' - executed_qty (character) quantity filled so far.
#' - cum_quote (character) cumulative filled quote quantity.
#' - time_in_force (character) time-in-force policy.
#' - type (character) order type.
#' - reduce_only (logical) reduce-only flag.
#' - close_position (logical) close-position flag.
#' - side (character) `"BUY"` or `"SELL"`.
#' - position_side (character) `"BOTH"`, `"LONG"`, or `"SHORT"`.
#' - stop_price (character) stop trigger price.
#' - working_type (character) trigger price type (`"CONTRACT_PRICE"` / `"MARK_PRICE"`).
#' - orig_type (character) original order type.
#' - price_match (character) price-match mode.
#' - self_trade_prevention_mode (character) self-trade-prevention mode.
#' - good_till_date (numeric) GTD expiry epoch ms, or `0` when not GTD (an
#'   epoch-ms value that exceeds 32-bit range; `numeric` to avoid overflow).
#' - update_time (POSIXct) most recent update time.
#'
#' @type AccountTrade (data.table) one row per account trade (fill), shared by
#'   spot `get_trades()` and margin `get_trades()` (margin adds `is_isolated`):
#' - symbol (character) the trading pair.
#' - id (numeric) trade id (a 64-bit id; `numeric` to avoid 32-bit overflow).
#' - order_id (numeric) the order this fill belongs to (a 64-bit id; `numeric`
#'   to avoid 32-bit overflow).
#' - price (character) fill price.
#' - qty (character) base-asset fill quantity.
#' - quote_qty (character) quote-asset fill quantity.
#' - commission (character) commission charged.
#' - commission_asset (character) asset the commission was charged in.
#' - time (POSIXct) fill time.
#' - is_buyer (logical) `TRUE` if the account was the buyer.
#' - is_maker (logical) `TRUE` if the account was the maker.
#' - is_best_match (logical) `TRUE` if the fill was at the best price.
NULL
