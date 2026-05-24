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
    return(data.table::data.table()[])
  }
  x <- lapply(x, function(val) {
    if (is.null(val)) {
      return(NA)
    }
    if (is.list(val) && length(val) == 0) {
      return(NA)
    }
    if (is.list(val) && length(val) >= 1) {
      return(list(val))
    }
    return(val)
  })
  dt <- data.table::as.data.table(x)
  data.table::setnames(dt, to_snake_case(names(dt)))
  return(dt[])
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
    return(data.table::data.table()[])
  }
  dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
  return(dt[])
}

#' Collapse a Plain-String Array Field on a Single Record
#'
#' Walks the named list `x` and replaces any named field whose value is a
#' length >= 1 list of plain character strings (or atomic character vector)
#' with a single semicolon-separated character scalar. Used by the parsers
#' that need a one-row-per-entity shape with no list columns.
#'
#' ### Separator choice
#' We use `;` rather than `,` because semicolon is far less likely to
#' appear inside any of the values themselves (the array elements are
#' short codes / snake_case identifiers / tickers — none of which contain
#' semicolons). Commas legitimately appear inside URL query strings, so
#' a future URL-valued field would need either URL-encoding or a
#' different separator entirely. Semicolon sidesteps that.
#'
#' The same convention is used across the sister packages (`alpaca`,
#' `kucoin`) for cross-package consistency.
#'
#' If any individual value contains a literal `;`, we'd silently corrupt
#' the data on a subsequent split. To make any future shape change loud,
#' we emit a once-per-session warning when that happens.
#'
#' ### Recovering the original values
#' Splitting on `;` gives back the original vector:
#'
#' ```r
#' dt <- market$get_exchange_info()
#' strsplit(dt$permissions[1], ";", fixed = TRUE)[[1]]
#' #> [1] "SPOT" "MARGIN"
#' ```
#'
#' Empty / missing arrays are written as `NA_character_` (not `list()`),
#' so downstream `rbindlist(fill = TRUE)` builds a character column
#' rather than falling back to a list column when some records have
#' arrays and others don't.
#'
#' Only fields in `fields` are touched; nested objects elsewhere are left
#' alone so they can be flattened by their own parser.
#'
#' @param x A named list representing a single API record.
#' @param fields Character vector; names of fields to collapse.
#' @return The same named list with the matching fields collapsed in place.
#'
#' @keywords internal
#' @noRd
collapse_string_array_fields <- function(x, fields) {
  for (nm in fields) {
    val <- x[[nm]]
    if (is.null(val) || length(val) == 0L) {
      x[[nm]] <- NA_character_
      next
    }
    if (is.list(val)) {
      val <- unlist(val, use.names = FALSE)
    }
    if (is.atomic(val) && length(val) >= 1L) {
      val_chr <- as.character(val)
      # Drop NA elements BEFORE joining. `paste(c("real", NA),
      # collapse = ";")` would produce the literal string `"real;NA"`,
      # indistinguishable from a real "NA" value — same trap we hit on
      # alpaca's news image_sizes. If every element is NA, fall back to
      # `NA_character_` so empty / all-missing arrays round-trip to NA.
      val_chr <- val_chr[!is.na(val_chr)]
      if (length(val_chr) == 0L) {
        x[[nm]] <- NA_character_
        next
      }
      # `na.rm = TRUE` on the collision check is defensive — by here
      # `val_chr` has no NAs, but it's cheap insurance against future
      # refactors that might add an `NA` element back upstream.
      if (any(grepl(";", val_chr, fixed = TRUE), na.rm = TRUE)) {
        rlang::warn(
          paste0(
            "Field `",
            nm,
            "` contains a literal `;` which collides with the ",
            "collapse separator. Joining anyway; downstream code that ",
            "splits on `;` will see corrupted values. Please report this ",
            "so we can switch the separator for this field."
          ),
          # Fire once per session per field — once the user has seen the
          # warning for a given field they know that field's shape is
          # changing, and there's no value in repeating.
          .frequency = "once",
          .frequency_id = paste0("collapse_sep_collision_", nm)
        )
      }
      x[[nm]] <- paste(val_chr, collapse = ";")
    }
  }
  return(x)
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
  if (is.null(ms)) {
    return(lubridate::NA_POSIXct_)
  }
  # Don't short-circuit on `all(is.na(ms))` — returning the length-1
  # `NA_POSIXct_` from there would, when fed back through
  # `coerce_cols()` -> `data.table::set()`, get recycled into the
  # existing column's type rather than replacing the column with a
  # POSIXct one. The helper must return a vector the same length as
  # `ms` so the column lands as POSIXct regardless of whether every
  # value is NA. `lubridate::as_datetime()` does the right thing on
  # all-NA input on its own.
  if (is.numeric(ms)) {
    return(lubridate::as_datetime(ms / 1000))
  }
  # Character path. Only feed real (non-NA) values to `as.numeric()` so
  # the documented NA-in -> NA-out contract is silent, but a genuinely
  # malformed string (e.g. `"not-a-number"`) still triggers the usual
  # "NAs introduced by coercion" warning. `suppressWarnings()` here
  # would silence real bugs too.
  result <- rep(NA_real_, length(ms))
  not_na <- !is.na(ms)
  if (any(not_na)) {
    result[not_na] <- as.numeric(ms[not_na])
  }
  return(lubridate::as_datetime(result / 1000))
}

#' Parse a Binance UTC Datetime String to POSIXct
#'
#' Handles fields the API returns as `"YYYY-MM-DD HH:MM:SS"` strings (so far
#' just `apply_time` / `complete_time` on withdrawal history). Empty strings
#' — used by Binance to signal "not set yet" on in-progress records — are
#' normalised to `NA` before `lubridate::ymd_hms()` runs so we don't trip
#' the upstream "All formats failed to parse" warning.
#'
#' @param x Character vector of UTC datetime strings.
#' @return POSIXct vector in UTC.
#'
#' @importFrom lubridate ymd_hms
#' @keywords internal
#' @noRd
utc_string_to_datetime <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(lubridate::NA_POSIXct_)
  }
  x[!nzchar(x)] <- NA_character_
  return(lubridate::ymd_hms(x, tz = "UTC"))
}

#' Apply a Function to Selected Columns of a data.table by Reference
#'
#' Walks `cols`; for each that exists in `dt`, replaces it in place with the
#' result of `fn(dt[[col]])`. Columns that are not in `dt` are silently
#' skipped — useful for endpoints whose payload sometimes omits optional
#' fields (e.g. `working_time` on legacy orders). A zero-row `dt` short-
#' circuits, so the caller can pipe through this without a separate
#' `nrow(dt) > 0` guard.
#'
#' Replaces the repeated boilerplate of:
#'
#' ```r
#' if (nrow(dt) > 0 && "transact_time" %in% names(dt)) {
#'   dt[, transact_time := ms_to_datetime(transact_time)]
#' }
#' if (nrow(dt) > 0 && "working_time" %in% names(dt)) {
#'   dt[, working_time := ms_to_datetime(working_time)]
#' }
#' ```
#'
#' with:
#'
#' ```r
#' coerce_cols(dt, c("transact_time", "working_time"), ms_to_datetime)
#' ```
#'
#' Modifies `dt` by reference via `data.table::set()`; returns `dt`
#' invisibly so the call can be the last line of a parser.
#'
#' @param dt A [data.table::data.table].
#' @param cols Character; candidate column names to convert.
#' @param fn Function; takes a column vector, returns the coerced vector.
#'
#' @return `dt`, modified by reference and returned invisibly.
#'
#' @keywords internal
#' @noRd
coerce_cols <- function(dt, cols, fn) {
  if (nrow(dt) == 0L) {
    return(invisible(dt))
  }
  # `unique()` prevents double-coercion when a caller passes the same
  # column name twice (e.g. `coerce_cols(dt, c("time", "time"),
  # ms_to_datetime)` would otherwise re-feed the already-converted
  # POSIXct vector back through `as.numeric / 1000 / as_datetime`, which
  # produces wildly wrong values silently).
  for (col in unique(cols)) {
    if (col %in% names(dt)) {
      data.table::set(dt, j = col, value = fn(dt[[col]]))
    }
  }
  return(invisible(dt))
}

#' Process Orderbook Data into a data.table
#'
#' Transforms the bids/asks arrays from a Binance orderbook response into a
#' tidy [data.table::data.table] with `side`, `price`, and `size` columns.
#'
#' @param data List; the parsed Binance orderbook response data containing
#'   `bids`, `asks`, and `lastUpdateId` fields.
#' @return A [data.table::data.table] with columns: `last_update_id`,
#'   `side`, `price`, `size`.
#'
#' @keywords internal
#' @noRd
parse_orderbook <- function(data) {
  # Guard against `data = NULL` / empty list (which `parse_binance_response()`
  # can return on an empty body or JSON-parse failure). Without this,
  # `data$bids` and `data$lastUpdateId` below would error with
  # "$ operator applied to NULL".
  if (is.null(data) || length(data) == 0) {
    return(data.table::data.table(
      last_update_id = character(),
      side = character(),
      price = numeric(),
      size = numeric()
    )[])
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

  return(result[])
}

#' Parse Paginated Binance Response
#'
#' Extracts the `rows` array from a paginated Binance response that has the
#' shape `{"total": N, "rows": [...]}` and converts to a [data.table::data.table].
#'
#' @param data List; the parsed Binance response containing `total` and `rows`.
#' @param time_cols Character vector; column names to convert from ms to POSIXct.
#' @return A [data.table::data.table] with snake_case column names.
#'
#' @keywords internal
#' @noRd
parse_paginated <- function(data, time_cols = character(0)) {
  # Guard against `data = NULL` (empty body / JSON-parse failure) before
  # subscripting. `is.null(data$rows)` on a NULL `data` returns TRUE so
  # this is partly defensive — but `data` itself being NULL is a real
  # path through `parse_binance_response()`.
  if (is.null(data) || length(data) == 0) {
    return(data.table::data.table()[])
  }
  rows <- data$rows
  if (is.null(rows) || length(rows) == 0) {
    return(data.table::data.table()[])
  }
  dt <- as_dt_list(rows)
  coerce_cols(dt, time_cols, ms_to_datetime)
  return(dt[])
}

#' @keywords internal
#' @noRd
parse_klines <- function(data) {
  if (is.null(data) || length(data) == 0) {
    return(data.table::data.table()[])
  }
  # Binance kline fields (0-indexed):
  # [0] Open time, [1] Open, [2] High, [3] Low, [4] Close, [5] Volume,
  # [6] Close time, [7] Quote asset volume, [8] Number of trades,
  # [9] Taker buy base vol, [10] Taker buy quote vol, [11] Ignore
  dt <- data.table::data.table(
    open_time = lubridate::as_datetime(as.numeric(vapply(data, `[[`, numeric(1), 1L)) / 1000),
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
  return(dt[])
}
