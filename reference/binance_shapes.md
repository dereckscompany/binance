# Binance REST return shapes

Reusable roxyassert `@type` shapes for the `data.table`s returned by the
Binance REST endpoint classes. A method documents its return as
`(promise<Shape>)` (a Binance call returns a value in sync mode or a
[`promises::promise`](https://rstudio.github.io/promises/reference/promise.html)
resolving to the same value in async mode), and the contract roclet
expands the shape into the generated `assert_return_*` helper. The
helper is wired at the call site through
[`connectcore::then_or_now()`](https://rdrr.io/pkg/connectcore/man/then_or_now.html)
so the row-and-column contract runs in BOTH execution modes.

Each column is typed to what the parser actually produces (verified
against the parse helpers in `R/helpers_parse.R` and the
`tests/testthat` fixtures). Binance returns most numeric quantities as
JSON **strings**, so price/size/ quantity columns are `character` unless
a parser explicitly coerces them (klines and the order book coerce to
`numeric`; `numeric` is the strict double, per the package convention).
Millisecond timestamps the parsers run through `ms_to_datetime()` become
`POSIXct`. A column is marked `| NA` only where the value can
legitimately be missing in the parsed result.

Only shapes returned by three or more methods, or that derive from one
another (`extends` / `pick` / `omit`), are declared here; a one-off
return is written inline at its method with the same column-bullet
grammar.

Each shape is referenced by a table-returning method's `@return`, so the
contract roclet expands it inline into that method's generated
`assert_return_*` – no standalone `assert_type_<Shape>()` is emitted.
binance is a leaf connector: nothing internal calls a per-shape
validator and no downstream package validates against these shapes, so
there is no `@genassert` (no callable validators to generate) and no
`@exportassert` (nothing to export).
