# File: R/helpers_validate.R
# Input validation helpers for order parameters and symbol formats.

#' Validate Order Parameters
#'
#' Validates and normalises parameters for a single order (limit or market).
#' Converts numeric price/quantity/quoteOrderQty to character strings as required
#' by the Binance API. Returns a clean named list ready for query string serialisation.
#'
#' ### Validation Rules
#' - **Limit orders**: require `price`, `quantity`, and `timeInForce`.
#' - **Market orders**: require either `quantity` or `quoteOrderQty` (mutually exclusive);
#'   `price` not allowed.
#'
#' @param type (scalar<character>) order type, case-insensitive; one of `"LIMIT"`,
#'   `"MARKET"`, `"STOP_LOSS"`, `"STOP_LOSS_LIMIT"`, `"TAKE_PROFIT"`,
#'   `"TAKE_PROFIT_LIMIT"`, `"LIMIT_MAKER"`.
#' @param symbol (scalar<character>) trading pair (e.g., `"BTCUSDT"`).
#' @param side (scalar<character>) order side, case-insensitive; `"BUY"` or `"SELL"`.
#' @param quantity (scalar<numeric>?) base asset quantity.
#' @param quote_order_qty (scalar<numeric>?) quote asset quantity (market orders only).
#' @param price (scalar<numeric>?) price for limit orders.
#' @param time_in_force (scalar<character>?) `"GTC"`, `"IOC"`, `"FOK"`.
#' @param new_client_order_id (scalar<character>?) unique client order ID.
#' @param stop_price (scalar<numeric>?) trigger price for stop orders.
#' @param iceberg_qty (scalar<numeric>?) iceberg quantity.
#' @param new_order_resp_type (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
#' @param self_trade_prevention_mode (scalar<character>?) `"NONE"`, `"EXPIRE_TAKER"`,
#'   `"EXPIRE_MAKER"`, `"EXPIRE_BOTH"`.
#' @param recv_window (scalar<count in [1, Inf[>?) max 60000.
#' @return (list) named list of validated order parameters (NULLs removed).
#'
#' @importFrom rlang abort arg_match0
#' @keywords internal
#' @noRd
validate_order_params <- function(
  type,
  symbol,
  side,
  quantity = NULL,
  quote_order_qty = NULL,
  price = NULL,
  time_in_force = NULL,
  new_client_order_id = NULL,
  stop_price = NULL,
  iceberg_qty = NULL,
  new_order_resp_type = NULL,
  self_trade_prevention_mode = NULL,
  recv_window = NULL
) {
  assert_args_validate_order_params(
    type,
    symbol,
    side,
    quantity,
    quote_order_qty,
    price,
    time_in_force,
    new_client_order_id,
    stop_price,
    iceberg_qty,
    new_order_resp_type,
    self_trade_prevention_mode,
    recv_window
  )
  # Required field validation
  type <- toupper(type)
  side <- toupper(side)
  rlang::arg_match0(
    type,
    c("LIMIT", "MARKET", "STOP_LOSS", "STOP_LOSS_LIMIT", "TAKE_PROFIT", "TAKE_PROFIT_LIMIT", "LIMIT_MAKER")
  )
  rlang::arg_match0(side, c("BUY", "SELL"))

  if (!verify_symbol(symbol)) {
    abort_binance_validation_error("Parameter 'symbol' must be a valid Binance ticker (e.g., 'BTCUSDT').")
  }

  # Convert numerics to character for the API
  if (!is.null(price)) {
    price <- as.character(price)
  }
  if (!is.null(quantity)) {
    quantity <- as.character(quantity)
  }
  if (!is.null(quote_order_qty)) {
    quote_order_qty <- as.character(quote_order_qty)
  }
  if (!is.null(stop_price)) {
    stop_price <- as.character(stop_price)
  }
  if (!is.null(iceberg_qty)) {
    iceberg_qty <- as.character(iceberg_qty)
  }

  # Type-specific validation
  if (type == "LIMIT") {
    if (is.null(price)) {
      abort_binance_validation_error("Parameter 'price' is required for LIMIT orders.")
    }
    if (is.null(quantity)) {
      abort_binance_validation_error("Parameter 'quantity' is required for LIMIT orders.")
    }
    if (is.null(time_in_force)) time_in_force <- "GTC"
  } else if (type == "MARKET") {
    if (!is.null(price)) {
      abort_binance_validation_error("Parameter 'price' is not applicable for MARKET orders.")
    }
    if (is.null(quantity) && is.null(quote_order_qty)) {
      abort_binance_validation_error("Either 'quantity' or 'quote_order_qty' must be specified for MARKET orders.")
    }
    if (!is.null(quantity) && !is.null(quote_order_qty)) {
      abort_binance_validation_error(
        "Parameters 'quantity' and 'quote_order_qty' are mutually exclusive for MARKET orders."
      )
    }
  }

  # Optional parameter validation
  if (!is.null(time_in_force)) {
    time_in_force <- rlang::arg_match0(time_in_force, c("GTC", "IOC", "FOK"))
  }
  if (!is.null(new_order_resp_type)) {
    new_order_resp_type <- rlang::arg_match0(new_order_resp_type, c("ACK", "RESULT", "FULL"))
  }
  if (!is.null(self_trade_prevention_mode)) {
    self_trade_prevention_mode <- rlang::arg_match0(
      self_trade_prevention_mode,
      c("NONE", "EXPIRE_TAKER", "EXPIRE_MAKER", "EXPIRE_BOTH")
    )
  }
  if (!is.null(recv_window)) {
    recv_window <- as.integer(recv_window)
    if (recv_window > 60000L) abort_binance_validation_error("Parameter 'recv_window' must not exceed 60000.")
  }

  # Build the result list, dropping NULLs
  params <- list(
    symbol = symbol,
    side = side,
    type = type,
    timeInForce = time_in_force,
    quantity = quantity,
    quoteOrderQty = quote_order_qty,
    price = price,
    newClientOrderId = new_client_order_id,
    stopPrice = stop_price,
    icebergQty = iceberg_qty,
    newOrderRespType = new_order_resp_type,
    selfTradePreventionMode = self_trade_prevention_mode,
    recvWindow = recv_window
  )
  params <- params[!vapply(params, is.null, logical(1))]

  return(assert_return_validate_order_params(params))
}
