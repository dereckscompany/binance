# Guards the typed-empty invariant: every endpoint parser's empty branch must
# return a zero-row data.table that still carries its full typed column set,
# never a column-less `data.table()`. That column-less empty is what silently
# violates a method's `assert_has_columns` @return contract on a flat account /
# empty book / quiet window. Binance extracts each shape as a named
# `empty_dt_*()` constructor, so this file enumerates them all from the namespace
# and proves the invariant holds for every one.

# The two isolated-margin shapes carry a nested venue object per row (the
# isolated-pair `data` payload, and the `base_asset` / `quote_asset` sub-objects)
# as list columns by design, so they are exempted from the no-list-column check
# only.
nested_list_col_ctors <- c(
  "empty_dt_isolated_margin_data",
  "empty_dt_margin_isolated_account"
)

empty_ctors <- ls(asNamespace("binance"), pattern = "^empty_dt_")

test_that("the package exposes the full set of empty_dt_* constructors", {
  expect_gte(length(empty_ctors), 57L)
})

test_that("every empty_dt_* returns a zero-row, typed, non-column-less data.table", {
  for (nm in empty_ctors) {
    dt <- get(nm, envir = asNamespace("binance"))()
    expect_s3_class(dt, "data.table")
    expect_identical(nrow(dt), 0L, label = nm)
    expect_gt(ncol(dt), 0L, label = paste(nm, "column count"))
    expect_false(anyNA(names(dt)), label = paste(nm, "named columns"))
    expect_false(any(names(dt) == ""), label = paste(nm, "named columns"))
  }
})

test_that("every empty_dt_* has no list columns (bar the documented nested shapes)", {
  for (nm in setdiff(empty_ctors, nested_list_col_ctors)) {
    dt <- get(nm, envir = asNamespace("binance"))()
    has_list_col <- any(vapply(dt, is.list, logical(1L)))
    expect_false(has_list_col, label = paste(nm, "list column"))
  }
})
