# Suppress R CMD check notes for data.table non-standard evaluation
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":=",
  # Standardised datetime_* columns used in := assignments
  "datetime_close",
  "datetime_complete",
  "datetime_created",
  "datetime_insert",
  "datetime_trade",
  "datetime_transact",
  "datetime_updated",
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
