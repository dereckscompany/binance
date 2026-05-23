# Suppress R CMD check notes for data.table non-standard evaluation
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":=",
  # Timestamp columns converted in-place via :=
  "server_time",
  "time",
  "open_time",
  "close_time",
  "update_time",
  "transact_time",
  "insert_time",
  "complete_time",
  "funding_time",
  "next_funding_time",
  "interest_accured_time",
  "create_time",
  "create_time_stamp",
  "timestamp",
  "updated_time",
  "working_time",
  "order_report_transact_time",
  "transaction_time",
  "subscription_start_time",
  "apply_time",
  # Orderbook / trade columns
  "last_update_id",
  "side",
  "price",
  "quantity",
  # Order columns
  "order_id",
  "client_order_id",
  "symbol",
  "timeframe",
  "interval"
))
