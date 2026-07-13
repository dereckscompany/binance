# File: R/utils_time.R
# Timestamp conversion utilities for Binance API interaction.

#' Convert Binance Timestamp to POSIXct
#'
#' Converts a UNIX timestamp from Binance's API into a POSIXct object in UTC.
#'
#' @param time_value (scalar<numeric>) the UNIX timestamp.
#' @param unit (scalar<character in c("ms", "ns", "s")>) input unit: `"ms"`
#'   (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).
#' @return (scalar<POSIXct>) POSIXct object in UTC.
#' @noassert time_value
#'
#' @examples
#' \dontrun{
#' time_convert_from_binance(1698777600000, unit = "ms")
#' time_convert_from_binance(1698777600000000000, unit = "ns")
#' time_convert_from_binance(1698777600, unit = "s")
#' }
#'
#' @importFrom lubridate as_datetime
#' @importFrom rlang abort
#' @export
time_convert_from_binance <- function(time_value, unit = c("ms", "ns", "s")) {
  unit <- match.arg(unit)
  assert_args_time_convert_from_binance(unit)
  if (!is.numeric(time_value)) {
    abort_binance_validation_error("Input must be a numeric value.")
  }

  seconds <- switch(
    unit,
    ms = time_value / 1000,
    ns = time_value / 1e9,
    s = time_value
  )

  return(assert_return_time_convert_from_binance(lubridate::as_datetime(seconds)))
}

#' Convert POSIXct to Binance Timestamp
#'
#' Converts a POSIXct object into a UNIX timestamp in the specified unit.
#'
#' @param datetime (scalar<POSIXct>) POSIXct object to convert.
#' @param unit (scalar<character in c("ms", "ns", "s")>) output unit: `"ms"`
#'   (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).
#' @return (scalar<numeric> | scalar<integer>) UNIX timestamp in the specified
#'   unit (an integer for `"s"`, a double otherwise).
#' @noassert datetime
#'
#' @examples
#' \dontrun{
#' dt <- lubridate::as_datetime("2023-10-31 16:00:00", tz = "UTC")
#' time_convert_to_binance(dt, unit = "ms")  # 1698768000000
#' time_convert_to_binance(dt, unit = "s")   # 1698768000
#' }
#'
#' @importFrom rlang abort
#' @export
time_convert_to_binance <- function(datetime, unit = c("ms", "ns", "s")) {
  unit <- match.arg(unit)
  assert_args_time_convert_to_binance(unit)
  if (!inherits(datetime, "POSIXct")) {
    abort_binance_validation_error("Input must be a POSIXct object.")
  }

  seconds <- as.numeric(datetime)

  result <- switch(
    unit,
    ms = seconds * 1000,
    ns = seconds * 1e9,
    s = as.integer(seconds)
  )

  return(assert_return_time_convert_to_binance(result))
}
