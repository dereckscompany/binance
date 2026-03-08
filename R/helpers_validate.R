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
#' @param type Character; `"LIMIT"` or `"MARKET"`.
#' @param symbol Character; trading pair (e.g., `"BTCUSDT"`).
#' @param side Character; `"BUY"` or `"SELL"`.
#' @param quantity Numeric or NULL; base asset quantity.
#' @param quoteOrderQty Numeric or NULL; quote asset quantity (market orders only).
#' @param price Numeric or NULL; price for limit orders.
#' @param timeInForce Character or NULL; `"GTC"`, `"IOC"`, `"FOK"`.
#' @param newClientOrderId Character or NULL; unique client order ID.
#' @param stopPrice Numeric or NULL; trigger price for stop orders.
#' @param icebergQty Numeric or NULL; iceberg quantity.
#' @param newOrderRespType Character or NULL; `"ACK"`, `"RESULT"`, or `"FULL"`.
#' @param selfTradePreventionMode Character or NULL; `"NONE"`, `"EXPIRE_TAKER"`,
#'   `"EXPIRE_MAKER"`, `"EXPIRE_BOTH"`.
#' @param recvWindow Integer or NULL; max 60000.
#' @return Named list of validated order parameters (NULLs removed).
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
  # Required field validation
  type <- toupper(type)
  side <- toupper(side)
  rlang::arg_match0(type, c("LIMIT", "MARKET", "STOP_LOSS", "STOP_LOSS_LIMIT", "TAKE_PROFIT", "TAKE_PROFIT_LIMIT", "LIMIT_MAKER"))
  rlang::arg_match0(side, c("BUY", "SELL"))

  if (!verify_symbol(symbol)) {
    rlang::abort("Parameter 'symbol' must be a valid Binance ticker (e.g., 'BTCUSDT').")
  }

  # Convert numerics to character for the API
  if (!is.null(price)) price <- as.character(price)
  if (!is.null(quantity)) quantity <- as.character(quantity)
  if (!is.null(quoteOrderQty)) quoteOrderQty <- as.character(quoteOrderQty)
  if (!is.null(stopPrice)) stopPrice <- as.character(stopPrice)
  if (!is.null(icebergQty)) icebergQty <- as.character(icebergQty)

  # Type-specific validation
  if (type == "LIMIT") {
    if (is.null(price)) rlang::abort("Parameter 'price' is required for LIMIT orders.")
    if (is.null(quantity)) rlang::abort("Parameter 'quantity' is required for LIMIT orders.")
    if (is.null(timeInForce)) timeInForce <- "GTC"
  } else if (type == "MARKET") {
    if (!is.null(price)) rlang::abort("Parameter 'price' is not applicable for MARKET orders.")
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

  return(params)
}
