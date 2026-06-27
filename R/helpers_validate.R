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
#' @param quoteOrderQty (scalar<numeric>?) quote asset quantity (market orders only).
#' @param price (scalar<numeric>?) price for limit orders.
#' @param timeInForce (scalar<character>?) `"GTC"`, `"IOC"`, `"FOK"`.
#' @param newClientOrderId (scalar<character>?) unique client order ID.
#' @param stopPrice (scalar<numeric>?) trigger price for stop orders.
#' @param icebergQty (scalar<numeric>?) iceberg quantity.
#' @param newOrderRespType (scalar<character>?) `"ACK"`, `"RESULT"`, or `"FULL"`.
#' @param selfTradePreventionMode (scalar<character>?) `"NONE"`, `"EXPIRE_TAKER"`,
#'   `"EXPIRE_MAKER"`, `"EXPIRE_BOTH"`.
#' @param recvWindow (scalar<count in [1, Inf[>?) max 60000.
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
  quoteOrderQty = NULL,
  price = NULL,
  timeInForce = NULL,
  newClientOrderId = NULL,
  stopPrice = NULL,
  icebergQty = NULL,
  newOrderRespType = NULL,
  selfTradePreventionMode = NULL,
  recvWindow = NULL
) {
  assert_args_validate_order_params(
    type,
    symbol,
    side,
    quantity,
    quoteOrderQty,
    price,
    timeInForce,
    newClientOrderId,
    stopPrice,
    icebergQty,
    newOrderRespType,
    selfTradePreventionMode,
    recvWindow
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
    rlang::abort("Parameter 'symbol' must be a valid Binance ticker (e.g., 'BTCUSDT').")
  }

  # Convert numerics to character for the API
  if (!is.null(price)) {
    price <- as.character(price)
  }
  if (!is.null(quantity)) {
    quantity <- as.character(quantity)
  }
  if (!is.null(quoteOrderQty)) {
    quoteOrderQty <- as.character(quoteOrderQty)
  }
  if (!is.null(stopPrice)) {
    stopPrice <- as.character(stopPrice)
  }
  if (!is.null(icebergQty)) {
    icebergQty <- as.character(icebergQty)
  }

  # Type-specific validation
  if (type == "LIMIT") {
    if (is.null(price)) {
      rlang::abort("Parameter 'price' is required for LIMIT orders.")
    }
    if (is.null(quantity)) {
      rlang::abort("Parameter 'quantity' is required for LIMIT orders.")
    }
    if (is.null(timeInForce)) timeInForce <- "GTC"
  } else if (type == "MARKET") {
    if (!is.null(price)) {
      rlang::abort("Parameter 'price' is not applicable for MARKET orders.")
    }
    if (is.null(quantity) && is.null(quoteOrderQty)) {
      rlang::abort("Either 'quantity' or 'quoteOrderQty' must be specified for MARKET orders.")
    }
    if (!is.null(quantity) && !is.null(quoteOrderQty)) {
      rlang::abort("Parameters 'quantity' and 'quoteOrderQty' are mutually exclusive for MARKET orders.")
    }
  }

  # Optional parameter validation
  if (!is.null(timeInForce)) {
    timeInForce <- rlang::arg_match0(timeInForce, c("GTC", "IOC", "FOK"))
  }
  if (!is.null(newOrderRespType)) {
    newOrderRespType <- rlang::arg_match0(newOrderRespType, c("ACK", "RESULT", "FULL"))
  }
  if (!is.null(selfTradePreventionMode)) {
    selfTradePreventionMode <- rlang::arg_match0(
      selfTradePreventionMode,
      c("NONE", "EXPIRE_TAKER", "EXPIRE_MAKER", "EXPIRE_BOTH")
    )
  }
  if (!is.null(recvWindow)) {
    recvWindow <- as.integer(recvWindow)
    if (recvWindow > 60000L) rlang::abort("Parameter 'recvWindow' must not exceed 60000.")
  }

  # Build the result list, dropping NULLs
  params <- list(
    symbol = symbol,
    side = side,
    type = type,
    timeInForce = timeInForce,
    quantity = quantity,
    quoteOrderQty = quoteOrderQty,
    price = price,
    newClientOrderId = newClientOrderId,
    stopPrice = stopPrice,
    icebergQty = icebergQty,
    newOrderRespType = newOrderRespType,
    selfTradePreventionMode = selfTradePreventionMode,
    recvWindow = recvWindow
  )
  params <- params[!vapply(params, is.null, logical(1))]

  return(assert_return_validate_order_params(params))
}
