# Suppress R CMD check notes for data.table non-standard evaluation
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":=",
  # Standardised datetime columns used in := assignments
  "datetime",
  "datetime_close",
  "datetime_created",
  "datetime_updated",
  "datetime_complete",
  # Raw API columns consumed then removed in := assignments
  "time",
  "open_time",
  "close_time",
  "update_time",
  "transact_time",
  "insert_time",
  "complete_time",
  # Orderbook / trade columns
  "last_update_id",
  "side",
  "price",
  "quantity",
  # Order columns
  "order_id",
  "client_order_id",
  "symbol"
))
