# File: R/helpers_parse.R
# Response parsing and data.table construction helpers.

#' Parse a Binance UTC Datetime String to POSIXct
#'
#' Handles fields the API returns as `"YYYY-MM-DD HH:MM:SS"` strings (so far
#' just `apply_time` / `complete_time` on withdrawal history). Empty strings
#' — used by Binance to signal "not set yet" on in-progress records — are
#' normalised to `NA` before `lubridate::ymd_hms()` runs so we don't trip
#' the upstream "All formats failed to parse" warning.
#'
#' @param x (vector<character, 0..>?) UTC datetime strings (possibly empty or NULL).
#' @return (POSIXct | NA) POSIXct vector in UTC (NA elements where unparseable or empty).
#'
#' @importFrom lubridate ymd_hms
#' @keywords internal
#' @noRd
utc_string_to_datetime <- function(x) {
  assert_args_utc_string_to_datetime(x)
  if (is.null(x) || length(x) == 0L) {
    return(assert_return_utc_string_to_datetime(lubridate::NA_POSIXct_))
  }
  x[!nzchar(x)] <- NA_character_
  return(assert_return_utc_string_to_datetime(lubridate::ymd_hms(x, tz = "UTC")))
}

#' Process Orderbook Data into a data.table
#'
#' Transforms the bids/asks arrays from a Binance orderbook response into a
#' tidy [data.table::data.table] with `side`, `price`, and `size` columns.
#'
#' @param data (list?) the parsed Binance orderbook response data containing
#'   `bids`, `asks`, and `lastUpdateId` fields.
#' @return (data.table) a [data.table::data.table] with columns:
#' - last_update_id (character) order book sequence id.
#' - side (character) `"bid"` or `"ask"`.
#' - price (numeric) price level.
#' - size (numeric) size at this price level.
#'
#' @keywords internal
#' @noRd
parse_orderbook <- function(data) {
  assert_args_parse_orderbook(data)
  # Guard against `data = NULL` / empty list (which `parse_binance_response()`
  # can return on an empty body or JSON-parse failure). Without this,
  # `data$bids` and `data$lastUpdateId` below would error with
  # "$ operator applied to NULL".
  if (is.null(data) || length(data) == 0) {
    return(assert_return_parse_orderbook(data.table::data.table(
      last_update_id = character(),
      side = character(),
      price = numeric(),
      size = numeric()
    )[]))
  }
  parse_side <- function(entries, side_label) {
    if (is.null(entries) || length(entries) == 0) {
      return(data.table::data.table(
        side = character(),
        price = numeric(),
        size = numeric()
      )[])
    }
    return(data.table::data.table(
      side = side_label,
      price = as.numeric(vapply(entries, `[[`, character(1), 1L)),
      size = as.numeric(vapply(entries, `[[`, character(1), 2L))
    )[])
  }

  bids_dt <- parse_side(data$bids, "bid")
  asks_dt <- parse_side(data$asks, "ask")
  result <- data.table::rbindlist(list(bids_dt, asks_dt))

  result[, last_update_id := as.character(data$lastUpdateId)]
  data.table::setcolorder(result, c("last_update_id", "side", "price", "size"))

  return(assert_return_parse_orderbook(result[]))
}

#' Parse Paginated Binance Response
#'
#' Extracts the `rows` array from a paginated Binance response that has the
#' shape `{"total": N, "rows": [...]}` and converts to a [data.table::data.table].
#'
#' @param data (list?) the parsed Binance response containing `total` and `rows`.
#' @param time_cols (vector<character, 0..>) column names to convert from ms to
#'   POSIXct (possibly none).
#' @return (data.table) a [data.table::data.table] with snake_case column names.
#'
#' @keywords internal
#' @noRd
parse_paginated <- function(data, time_cols = character(0)) {
  assert_args_parse_paginated(data, time_cols)
  # Guard against `data = NULL` (empty body / JSON-parse failure) before
  # subscripting. `is.null(data$rows)` on a NULL `data` returns TRUE so
  # this is partly defensive — but `data` itself being NULL is a real
  # path through `parse_binance_response()`.
  if (is.null(data) || length(data) == 0) {
    return(assert_return_parse_paginated(data.table::data.table()[]))
  }
  rows <- data$rows
  if (is.null(rows) || length(rows) == 0) {
    return(assert_return_parse_paginated(data.table::data.table()[]))
  }
  dt <- as_dt_list(rows)
  coerce_cols(dt, time_cols, ms_to_datetime)
  return(assert_return_parse_paginated(dt[]))
}

# ---- Typed zero-row empties ------------------------------------------------
# A list-returning endpoint's empty path returns the fully-typed zero-row table
# for its documented shape (columns and types EXACTLY matching the method's
# `@return` contract and the parser's non-empty branch) so the method's column
# contract still holds on an empty result. Datetime columns are built with the
# same `ms_to_datetime()` helper the parser uses so class and tz match the
# populated case. These mirror their shape; they are deliberately not asserted.

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_balances <- function() {
  return(data.table::data.table(
    asset = character(0),
    free = character(0),
    locked = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_account_trade <- function() {
  return(data.table::data.table(
    symbol = character(0),
    id = numeric(0),
    order_id = numeric(0),
    order_list_id = numeric(0),
    price = character(0),
    qty = character(0),
    quote_qty = character(0),
    commission = character(0),
    commission_asset = character(0),
    is_buyer = logical(0),
    is_maker = logical(0),
    is_best_match = logical(0),
    time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_ohlcv <- function() {
  return(data.table::data.table(
    datetime = ms_to_datetime(numeric(0)),
    open = numeric(0),
    high = numeric(0),
    low = numeric(0),
    close = numeric(0),
    volume = numeric(0),
    close_time = ms_to_datetime(numeric(0)),
    quote_volume = numeric(0),
    trades = integer(0),
    taker_buy_base_volume = numeric(0),
    taker_buy_quote_volume = numeric(0),
    ignore = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_trade <- function() {
  return(data.table::data.table(
    id = numeric(0),
    price = character(0),
    qty = character(0),
    quote_qty = character(0),
    time = ms_to_datetime(numeric(0)),
    is_buyer_maker = logical(0),
    is_best_match = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_exchange_info <- function() {
  return(data.table::data.table(
    symbol = character(0),
    status = character(0),
    base_asset = character(0),
    base_asset_precision = integer(0),
    quote_asset = character(0),
    quote_asset_precision = integer(0),
    quote_precision = integer(0),
    order_types = character(0),
    iceberg_allowed = logical(0),
    oco_allowed = logical(0),
    oto_allowed = logical(0),
    quote_order_qty_market_allowed = logical(0),
    allow_trailing_stop = logical(0),
    cancel_replace_allowed = logical(0),
    is_spot_trading_allowed = logical(0),
    is_margin_trading_allowed = logical(0),
    lot_min_qty = numeric(0),
    lot_max_qty = numeric(0),
    lot_step_size = numeric(0),
    price_min = numeric(0),
    price_max = numeric(0),
    price_tick_size = numeric(0),
    min_notional = numeric(0),
    filters_raw = character(0),
    permissions = character(0),
    permission_sets = character(0),
    default_self_trade_prevention_mode = character(0),
    allowed_self_trade_prevention_modes = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_rate_limit <- function() {
  return(data.table::data.table(
    rate_limit_type = character(0),
    interval = character(0),
    interval_num = integer(0),
    limit = integer(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_spot_order_query <- function() {
  return(data.table::data.table(
    symbol = character(0),
    order_id = numeric(0),
    order_list_id = numeric(0),
    client_order_id = character(0),
    price = character(0),
    orig_qty = character(0),
    executed_qty = character(0),
    cummulative_quote_qty = character(0),
    status = character(0),
    time_in_force = character(0),
    type = character(0),
    side = character(0),
    stop_price = character(0),
    iceberg_qty = character(0),
    is_working = logical(0),
    orig_quote_order_qty = character(0),
    working_time = ms_to_datetime(numeric(0)),
    self_trade_prevention_mode = character(0),
    time = ms_to_datetime(numeric(0)),
    update_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_spot_order_list <- function() {
  return(data.table::data.table(
    symbol = character(0),
    order_id = numeric(0),
    order_list_id = numeric(0),
    client_order_id = character(0),
    price = character(0),
    orig_qty = character(0),
    executed_qty = character(0),
    cummulative_quote_qty = character(0),
    status = character(0),
    time_in_force = character(0),
    type = character(0),
    side = character(0),
    stop_price = character(0),
    iceberg_qty = character(0),
    time = ms_to_datetime(numeric(0)),
    is_working = logical(0),
    orig_quote_order_qty = character(0),
    working_time = ms_to_datetime(numeric(0)),
    self_trade_prevention_mode = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_spot_cancel <- function() {
  return(data.table::data.table(
    symbol = character(0),
    orig_client_order_id = character(0),
    order_id = numeric(0),
    order_list_id = numeric(0),
    client_order_id = character(0),
    price = character(0),
    orig_qty = character(0),
    executed_qty = character(0),
    cummulative_quote_qty = character(0),
    status = character(0),
    time_in_force = character(0),
    type = character(0),
    side = character(0),
    self_trade_prevention_mode = character(0),
    transact_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_spot_order_ack_fills <- function() {
  return(data.table::data.table(
    symbol = character(0),
    order_id = numeric(0),
    order_list_id = numeric(0),
    client_order_id = character(0),
    price = character(0),
    orig_qty = character(0),
    executed_qty = character(0),
    cummulative_quote_qty = character(0),
    status = character(0),
    time_in_force = character(0),
    type = character(0),
    side = character(0),
    working_time = ms_to_datetime(numeric(0)),
    self_trade_prevention_mode = character(0),
    transact_time = ms_to_datetime(numeric(0)),
    fill_index = integer(0),
    fill_price = character(0),
    fill_qty = character(0),
    fill_commission = character(0),
    fill_commission_asset = character(0),
    fill_trade_id = numeric(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_oco_add <- function() {
  return(data.table::data.table(
    order_list_id = numeric(0),
    contingency_type = character(0),
    list_status_type = character(0),
    list_order_status = character(0),
    list_client_order_id = character(0),
    transact_time = ms_to_datetime(numeric(0)),
    symbol = character(0),
    order_report_symbol = character(0),
    order_report_order_id = numeric(0),
    order_report_order_list_id = numeric(0),
    order_report_client_order_id = character(0),
    order_report_transact_time = ms_to_datetime(numeric(0)),
    order_report_price = character(0),
    order_report_orig_qty = character(0),
    order_report_executed_qty = character(0),
    order_report_cummulative_quote_qty = character(0),
    order_report_status = character(0),
    order_report_time_in_force = character(0),
    order_report_type = character(0),
    order_report_side = character(0),
    order_report_stop_price = character(0),
    order_report_self_trade_prevention_mode = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_oco_cancel <- function() {
  return(empty_dt_oco_add())
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_oco_query <- function() {
  return(data.table::data.table(
    order_list_id = numeric(0),
    contingency_type = character(0),
    list_status_type = character(0),
    list_order_status = character(0),
    list_client_order_id = character(0),
    transaction_time = ms_to_datetime(numeric(0)),
    symbol = character(0),
    order_symbol = character(0),
    order_order_id = numeric(0),
    order_client_order_id = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_deposit_history <- function() {
  return(data.table::data.table(
    id = character(0),
    amount = character(0),
    coin = character(0),
    network = character(0),
    status = integer(0),
    address = character(0),
    address_tag = character(0),
    tx_id = character(0),
    transfer_type = integer(0),
    confirm_times = character(0),
    unlock_confirm = integer(0),
    wallet_type = integer(0),
    insert_time = ms_to_datetime(numeric(0)),
    complete_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_withdrawal_history <- function() {
  return(data.table::data.table(
    id = character(0),
    amount = character(0),
    transaction_fee = character(0),
    coin = character(0),
    status = integer(0),
    address = character(0),
    tx_id = character(0),
    apply_time = utc_string_to_datetime(character(0)),
    network = character(0),
    transfer_type = integer(0),
    withdraw_order_id = character(0),
    info = character(0),
    confirm_no = integer(0),
    wallet_type = integer(0),
    tx_key = character(0),
    complete_time = utc_string_to_datetime(character(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_transfer_history <- function() {
  return(data.table::data.table(
    asset = character(0),
    amount = character(0),
    type = character(0),
    status = character(0),
    tran_id = numeric(0),
    timestamp = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_all_pairs <- function() {
  return(data.table::data.table(
    base = character(0),
    id = numeric(0),
    is_buy_allowed = logical(0),
    is_margin_trade = logical(0),
    is_sell_allowed = logical(0),
    quote = character(0),
    symbol = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_isolated_pairs <- function() {
  return(data.table::data.table(
    symbol = character(0),
    base = character(0),
    quote = character(0),
    is_margin_trade = logical(0),
    is_buy_allowed = logical(0),
    is_sell_allowed = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_interest_rate <- function() {
  return(data.table::data.table(
    asset = character(0),
    daily_interest_rate = character(0),
    timestamp = ms_to_datetime(numeric(0)),
    vip_level = integer(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_cross_margin_data <- function() {
  return(data.table::data.table(
    vip_level = integer(0),
    coin = character(0),
    transfer_in = logical(0),
    transfer_out = logical(0),
    borrowable = logical(0),
    daily_interest = character(0),
    yearly_interest = character(0),
    marginable_pair = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_isolated_margin_data <- function() {
  return(data.table::data.table(
    vip_level = integer(0),
    symbol = character(0),
    leverage = character(0),
    data = list()
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_sub_accounts <- function() {
  return(data.table::data.table(
    email = character(0),
    is_freeze = logical(0),
    create_time = ms_to_datetime(numeric(0)),
    is_managed_sub_account = logical(0),
    is_asset_management_sub_account = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_sub_balances <- function() {
  return(data.table::data.table(
    asset = character(0),
    free = numeric(0),
    locked = numeric(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_sub_spot_summary <- function() {
  return(data.table::data.table(
    total_count = integer(0),
    master_account_total_asset = character(0),
    sub_user_email = character(0),
    sub_user_total_asset = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_sub_transfer_history <- function() {
  return(data.table::data.table(
    tran_id = numeric(0),
    from_email = character(0),
    to_email = character(0),
    asset = character(0),
    amount = character(0),
    create_time_stamp = ms_to_datetime(numeric(0)),
    from_account_type = character(0),
    to_account_type = character(0),
    status = character(0),
    client_tran_id = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_sub_futures_account <- function() {
  return(data.table::data.table(
    email = character(0),
    asset = character(0),
    can_deposit = logical(0),
    can_trade = logical(0),
    can_withdraw = logical(0),
    fee_tier = integer(0),
    max_withdraw_amount = character(0),
    total_initial_margin = character(0),
    total_margin_balance = character(0),
    total_wallet_balance = character(0),
    total_unrealized_profit = character(0),
    update_time = ms_to_datetime(numeric(0)),
    asset_asset = character(0),
    asset_wallet_balance = character(0),
    asset_margin_balance = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_sub_status <- function() {
  return(data.table::data.table(
    email = character(0),
    is_sub_user_enabled = logical(0),
    is_user_active = logical(0),
    insert_time = ms_to_datetime(numeric(0)),
    is_margin_enabled = logical(0),
    is_future_enabled = logical(0),
    mobile = integer(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_cancel <- function() {
  return(data.table::data.table(
    symbol = character(0),
    order_id = numeric(0),
    orig_client_order_id = character(0),
    status = character(0),
    transact_time = ms_to_datetime(numeric(0)),
    is_isolated = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_order_query <- function() {
  return(data.table::data.table(
    symbol = character(0),
    order_id = numeric(0),
    client_order_id = character(0),
    price = character(0),
    orig_qty = character(0),
    executed_qty = character(0),
    status = character(0),
    type = character(0),
    side = character(0),
    time = ms_to_datetime(numeric(0)),
    update_time = ms_to_datetime(numeric(0)),
    is_isolated = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_interest_history <- function() {
  return(data.table::data.table(
    asset = character(0),
    interest = character(0),
    interest_accured_time = ms_to_datetime(numeric(0)),
    interest_rate = character(0),
    principal = character(0),
    type = character(0),
    isolated_symbol = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_force_liquidation <- function() {
  return(data.table::data.table(
    avg_price = character(0),
    executed_qty = character(0),
    order_id = numeric(0),
    price = character(0),
    qty = character(0),
    side = character(0),
    symbol = character(0),
    time = ms_to_datetime(numeric(0)),
    is_isolated = logical(0),
    updated_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_trade <- function() {
  return(data.table::data.table(
    symbol = character(0),
    id = numeric(0),
    order_id = numeric(0),
    price = character(0),
    qty = character(0),
    commission = character(0),
    commission_asset = character(0),
    time = ms_to_datetime(numeric(0)),
    is_buyer = logical(0),
    is_maker = logical(0),
    is_isolated = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_margin_isolated_account <- function() {
  return(data.table::data.table(
    total_asset_of_btc = character(0),
    total_liability_of_btc = character(0),
    total_net_asset_of_btc = character(0),
    base_asset = list(),
    quote_asset = list(),
    symbol = character(0),
    isolated_created = logical(0),
    enabled = logical(0),
    margin_level = character(0),
    trade_enabled = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_flexible_products <- function() {
  return(data.table::data.table(
    asset = character(0),
    latest_annual_percentage_rate = character(0),
    tier_annual_percentage_rate = character(0),
    can_purchase = logical(0),
    can_redeem = logical(0),
    is_sold_out = logical(0),
    hot = logical(0),
    min_purchase_amount = character(0),
    product_id = character(0),
    subscription_start_time = ms_to_datetime(numeric(0)),
    status = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_locked_products <- function() {
  return(data.table::data.table(
    project_id = character(0),
    detail_asset = character(0),
    detail_reward_asset = character(0),
    detail_duration = integer(0),
    detail_renewable = logical(0),
    detail_is_sold_out = logical(0),
    detail_apr = character(0),
    detail_status = character(0),
    detail_subscription_start_time = ms_to_datetime(numeric(0)),
    detail_extra_reward_asset = character(0),
    detail_extra_reward_apr = character(0),
    detail_boost_reward_asset = character(0),
    detail_boost_apr = character(0),
    detail_boost_end_time = ms_to_datetime(numeric(0)),
    quota_total_personal_quota = character(0),
    quota_minimum = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_flexible_position <- function() {
  return(data.table::data.table(
    total_amount = character(0),
    latest_annual_percentage_rate = character(0),
    tier_annual_percentage_rate = character(0),
    yesterday_airdrop_percentage_rate = character(0),
    asset = character(0),
    air_drop_asset = character(0),
    can_redeem = logical(0),
    collateral_amount = character(0),
    product_id = character(0),
    yesterday_real_time_rewards = character(0),
    cumulative_bonus_rewards = character(0),
    cumulative_real_time_rewards = character(0),
    cumulative_total_rewards = character(0),
    auto_subscribe = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_locked_position <- function() {
  return(data.table::data.table(
    position_id = numeric(0),
    parent_position_id = numeric(0),
    project_id = character(0),
    asset = character(0),
    amount = character(0),
    purchase_time = ms_to_datetime(numeric(0)),
    duration = character(0),
    accrual_days = character(0),
    reward_asset = character(0),
    apy = character(0),
    reward_amt = character(0),
    extra_reward_asset = character(0),
    extra_reward_apr = character(0),
    est_extra_reward_amt = character(0),
    boost_reward_asset = character(0),
    boost_apr = character(0),
    total_boost_reward_amt = character(0),
    next_pay = character(0),
    next_pay_date = ms_to_datetime(numeric(0)),
    pay_period = character(0),
    redeem_amount_early = character(0),
    rewards_end_date = ms_to_datetime(numeric(0)),
    deliver_date = ms_to_datetime(numeric(0)),
    redeem_period = character(0),
    redeeming_amt = character(0),
    redeem_to = character(0),
    partial_amt_deliver_date = ms_to_datetime(numeric(0)),
    can_redeem_early = logical(0),
    can_fast_redemption = logical(0),
    auto_subscribe = logical(0),
    type = character(0),
    status = character(0),
    can_re_stake = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_flexible_subscription_history <- function() {
  return(data.table::data.table(
    amount = character(0),
    asset = character(0),
    time = ms_to_datetime(numeric(0)),
    purchase_id = numeric(0),
    type = character(0),
    source_account = character(0),
    status = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_locked_subscription_history <- function() {
  return(data.table::data.table(
    amount = character(0),
    asset = character(0),
    time = ms_to_datetime(numeric(0)),
    purchase_id = numeric(0),
    position_id = character(0),
    lock_period = integer(0),
    type = character(0),
    source_account = character(0),
    status = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_flexible_redemption_history <- function() {
  return(data.table::data.table(
    amount = character(0),
    asset = character(0),
    time = ms_to_datetime(numeric(0)),
    project_id = character(0),
    redeem_id = numeric(0),
    dest_account = character(0),
    status = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_earn_locked_redemption_history <- function() {
  return(data.table::data.table(
    amount = character(0),
    asset = character(0),
    time = ms_to_datetime(numeric(0)),
    position_id = character(0),
    redeem_id = numeric(0),
    deliver_date = ms_to_datetime(numeric(0)),
    status = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_order_query <- function() {
  return(data.table::data.table(
    symbol = character(0),
    order_id = numeric(0),
    client_order_id = character(0),
    price = character(0),
    orig_qty = character(0),
    executed_qty = character(0),
    status = character(0),
    type = character(0),
    side = character(0),
    position_side = character(0),
    time = ms_to_datetime(numeric(0)),
    update_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_balances <- function() {
  return(data.table::data.table(
    account_alias = character(0),
    asset = character(0),
    balance = character(0),
    cross_wallet_balance = character(0),
    cross_un_pnl = character(0),
    available_balance = character(0),
    max_withdraw_amount = character(0),
    margin_available = logical(0),
    update_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_positions <- function() {
  return(data.table::data.table(
    symbol = character(0),
    position_side = character(0),
    position_amt = character(0),
    entry_price = character(0),
    mark_price = character(0),
    un_realized_profit = character(0),
    liquidation_price = character(0),
    leverage = character(0),
    margin_type = character(0),
    isolated_margin = character(0),
    notional = character(0),
    update_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_margin_history <- function() {
  return(data.table::data.table(
    symbol = character(0),
    type = integer(0),
    delta_type = character(0),
    amount = character(0),
    asset = character(0),
    time = ms_to_datetime(numeric(0)),
    position_side = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_trade <- function() {
  return(data.table::data.table(
    symbol = character(0),
    id = numeric(0),
    order_id = numeric(0),
    price = character(0),
    qty = character(0),
    quote_qty = character(0),
    commission = character(0),
    commission_asset = character(0),
    realized_pnl = character(0),
    side = character(0),
    position_side = character(0),
    buyer = logical(0),
    maker = logical(0),
    time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_income <- function() {
  return(data.table::data.table(
    symbol = character(0),
    income_type = character(0),
    income = character(0),
    asset = character(0),
    info = character(0),
    time = ms_to_datetime(numeric(0)),
    tran_id = numeric(0),
    trade_id = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_exchange_info <- function() {
  return(data.table::data.table(
    symbol = character(0),
    pair = character(0),
    contract_type = character(0),
    status = character(0),
    base_asset = character(0),
    quote_asset = character(0),
    margin_asset = character(0),
    price_precision = integer(0),
    quantity_precision = integer(0),
    order_types = character(0),
    time_in_force = character(0),
    underlying_sub_type = character(0),
    permission_sets = character(0),
    lot_min_qty = numeric(0),
    lot_max_qty = numeric(0),
    lot_step_size = numeric(0),
    price_min = numeric(0),
    price_max = numeric(0),
    price_tick_size = numeric(0),
    min_notional = numeric(0),
    filters_raw = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_assets <- function() {
  return(data.table::data.table(
    asset = character(0),
    margin_available = logical(0),
    auto_asset_exchange = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_funding_rate <- function() {
  return(data.table::data.table(
    symbol = character(0),
    funding_rate = character(0),
    funding_time = ms_to_datetime(numeric(0)),
    mark_price = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_mark_price <- function() {
  return(data.table::data.table(
    symbol = character(0),
    mark_price = character(0),
    index_price = character(0),
    estimated_settle_price = character(0),
    last_funding_rate = character(0),
    next_funding_time = ms_to_datetime(numeric(0)),
    interest_rate = character(0),
    time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_24hr_stats <- function() {
  return(data.table::data.table(
    symbol = character(0),
    price_change = character(0),
    price_change_percent = character(0),
    weighted_avg_price = character(0),
    last_price = character(0),
    volume = character(0),
    quote_volume = character(0),
    open_time = ms_to_datetime(numeric(0)),
    close_time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_ticker <- function() {
  return(data.table::data.table(
    symbol = character(0),
    price = character(0),
    time = ms_to_datetime(numeric(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_book_ticker <- function() {
  return(data.table::data.table(
    symbol = character(0),
    bid_price = character(0),
    bid_qty = character(0),
    ask_price = character(0),
    ask_qty = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_futures_trade_public <- function() {
  return(data.table::data.table(
    id = numeric(0),
    price = character(0),
    qty = character(0),
    quote_qty = character(0),
    time = ms_to_datetime(numeric(0)),
    is_buyer_maker = logical(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_ticker_price <- function() {
  return(data.table::data.table(
    symbol = character(0),
    price = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_ticker_24hr <- function() {
  return(data.table::data.table(
    symbol = character(0),
    price_change = character(0),
    price_change_percent = character(0),
    weighted_avg_price = character(0),
    prev_close_price = character(0),
    last_price = character(0),
    last_qty = character(0),
    bid_price = character(0),
    bid_qty = character(0),
    ask_price = character(0),
    ask_qty = character(0),
    open_price = character(0),
    high_price = character(0),
    low_price = character(0),
    volume = character(0),
    quote_volume = character(0),
    open_time = ms_to_datetime(numeric(0)),
    close_time = ms_to_datetime(numeric(0)),
    first_id = numeric(0),
    last_id = numeric(0),
    count = integer(0)
  ))
}

#' Parse a Binance Klines Array into a data.table
#'
#' @param data (list?) the parsed Binance klines response: a list of 12-element
#'   candle arrays, or NULL/empty.
#' @return (data.table) OHLCV candles with snake_case columns.
#'   - datetime (POSIXct) Candle open time (the bar-reference time).
#'   - open (numeric) Open price.
#'   - high (numeric) High price.
#'   - low (numeric) Low price.
#'   - close (numeric) Close price.
#'   - volume (numeric) Base asset volume.
#'   - close_time (POSIXct) Candle close time.
#'   - quote_volume (numeric) Quote asset volume.
#'   - trades (integer) Number of trades in the candle.
#'   - taker_buy_base_volume (numeric) Taker buy base asset volume.
#'   - taker_buy_quote_volume (numeric) Taker buy quote asset volume.
#'   - ignore (character) Unused field Binance reserves.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
parse_klines <- function(data) {
  assert_args_parse_klines(data)
  if (is.null(data) || length(data) == 0) {
    return(assert_return_parse_klines(empty_dt_ohlcv()))
  }
  # Binance kline fields (0-indexed):
  # [0] Open time, [1] Open, [2] High, [3] Low, [4] Close, [5] Volume,
  # [6] Close time, [7] Quote asset volume, [8] Number of trades,
  # [9] Taker buy base vol, [10] Taker buy quote vol, [11] Ignore
  dt <- data.table::data.table(
    datetime = lubridate::as_datetime(as.numeric(vapply(data, `[[`, numeric(1), 1L)) / 1000),
    open = as.numeric(vapply(data, `[[`, character(1), 2L)),
    high = as.numeric(vapply(data, `[[`, character(1), 3L)),
    low = as.numeric(vapply(data, `[[`, character(1), 4L)),
    close = as.numeric(vapply(data, `[[`, character(1), 5L)),
    volume = as.numeric(vapply(data, `[[`, character(1), 6L)),
    close_time = lubridate::as_datetime(as.numeric(vapply(data, `[[`, numeric(1), 7L)) / 1000),
    quote_volume = as.numeric(vapply(data, `[[`, character(1), 8L)),
    trades = as.integer(vapply(data, `[[`, numeric(1), 9L)),
    taker_buy_base_volume = as.numeric(vapply(data, `[[`, character(1), 10L)),
    taker_buy_quote_volume = as.numeric(vapply(data, `[[`, character(1), 11L)),
    ignore = vapply(data, `[[`, character(1), 12L)
  )
  return(assert_return_parse_klines(dt[]))
}
