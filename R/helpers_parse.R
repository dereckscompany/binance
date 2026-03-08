# File: R/helpers_parse.R
# Response parsing and data.table construction helpers.

#' Convert camelCase Names to snake_case
#'
#' Converts column names from Binance's camelCase convention to R's
#' snake_case convention.
#'
#' @param names Character vector; names to convert.
#' @return Character vector; converted snake_case names.
#'
#' @keywords internal
#' @noRd
to_snake_case <- function(names) {
  out <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", names)
  out <- gsub("([A-Z])([A-Z][a-z])", "\\1_\\2", out)
  out <- tolower(out)
  return(out)
}

#' Convert a List or Named List to a data.table Row
#'
#' Converts a flat named list (typically from a Binance API JSON response)
#' into a single-row [data.table::data.table]. NULL values become NA.
#' Column names are converted to snake_case.
#'
#' @param x A named list.
#' @return A single-row [data.table::data.table] with snake_case column names.
#'
#' @keywords internal
#' @noRd
as_dt_row <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(data.table::data.table())
  }
  x <- lapply(x, function(val) {
    if (is.null(val)) {
      return(NA)
    }
    if (is.list(val) && length(val) == 0) {
      return(NA)
    }
    if (is.list(val) && length(val) > 1) {
      return(list(val))
    }
    return(val)
  })
  dt <- data.table::as.data.table(x)
  data.table::setnames(dt, to_snake_case(names(dt)))
  return(dt)
}

#' Convert a List of Lists to a data.table
#'
#' Takes a list where each element is a named list (e.g., from a JSON array)
#' and row-binds them into a [data.table::data.table] with snake_case columns.
#'
#' @param items A list of named lists, or NULL.
#' @return A [data.table::data.table]. Returns an empty data.table if `items` is NULL or empty.
#'
#' @keywords internal
#' @noRd
as_dt_list <- function(items) {
  if (is.null(items) || length(items) == 0) {
    return(data.table::data.table())
  }
  dt <- data.table::rbindlist(items, fill = TRUE)
  data.table::setnames(dt, to_snake_case(names(dt)))
  return(dt)
}

#' Convert a Binance Millisecond Timestamp to POSIXct
#'
#' @param ms Numeric; millisecond Unix timestamp.
#' @return POSIXct in UTC, or NA if `ms` is NULL/NA.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
ms_to_datetime <- function(ms) {
  if (is.null(ms) || all(is.na(ms))) {
    return(lubridate::NA_POSIXct_)
  }
  return(lubridate::as_datetime(as.numeric(ms) / 1000))
}

#' Process Orderbook Data into a data.table
#'
#' Transforms the bids/asks arrays from a Binance orderbook response into a
#' tidy [data.table::data.table] with `side`, `price`, and `quantity` columns.
#'
#' @param data List; the parsed Binance orderbook response data containing
#'   `bids`, `asks`, and `lastUpdateId` fields.
#' @return A [data.table::data.table] with columns: `last_update_id`,
#'   `side`, `price`, `quantity`.
#'
#' @keywords internal
#' @noRd
parse_orderbook <- function(data) {
  parse_side <- function(entries, side_label) {
    if (is.null(entries) || length(entries) == 0) {
      return(data.table::data.table(
        side = character(),
        price = numeric(),
        quantity = numeric()
      ))
    }
    return(data.table::data.table(
      side = side_label,
      price = as.numeric(vapply(entries, `[[`, character(1), 1L)),
      quantity = as.numeric(vapply(entries, `[[`, character(1), 2L))
    ))
  }

  bids_dt <- parse_side(data$bids, "bid")
  asks_dt <- parse_side(data$asks, "ask")
  result <- data.table::rbindlist(list(bids_dt, asks_dt))

  result[, last_update_id := as.character(data$lastUpdateId)]
  data.table::setcolorder(result, c("last_update_id", "side", "price", "quantity"))

  return(result)
}

#' Parse Raw Binance Kline Data into a data.table
#'
#' Converts the array-of-arrays response from Binance's klines endpoint into
#' a typed [data.table::data.table] with standard OHLCV columns.
#' Each candle is returned as:
#' `[open_time, open, high, low, close, volume, close_time, quote_volume,
#'   trades, taker_buy_base, taker_buy_quote, ignore]`
#'
#' @param data List of lists; the raw kline response from Binance.
#' @return A [data.table::data.table] with columns: `datetime`, `open`, `high`,
#'   `low`, `close`, `volume`, `quote_volume`, `trades`,
#'   `taker_buy_base_volume`, `taker_buy_quote_volume`.
#'   Returns empty data.table if input is NULL or empty.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
parse_klines <- function(data) {
  if (is.null(data) || length(data) == 0) {
    return(data.table::data.table())
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
    quote_volume = as.numeric(vapply(data, `[[`, character(1), 8L)),
    trades = as.integer(vapply(data, `[[`, integer(1), 9L)),
    taker_buy_base_volume = as.numeric(vapply(data, `[[`, character(1), 10L)),
    taker_buy_quote_volume = as.numeric(vapply(data, `[[`, character(1), 11L))
  )
  return(dt)
}
