# binance

<!-- badges: start -->
[![R-CMD-check](https://github.com/dereckmezquita/binance/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dereckmezquita/binance/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

An R API wrapper for the [Binance](https://www.binance.com/) cryptocurrency exchange. Provides R6 classes for spot market data, trading, account management, deposits, withdrawals, and sub-accounts. Supports both synchronous and asynchronous (promise-based) operation via httr2.

## Disclaimer

This software is provided "as is", without warranty of any kind. **This package interacts with live cryptocurrency exchange accounts and can execute real trades, transfers, and withdrawals involving real money.** By using this package you accept full responsibility for any financial losses, erroneous transactions, or other damages that may result. Always test with small amounts first, use API key permissions to restrict access to only what you need, and never share your API credentials. The author(s) and contributor(s) are not liable for any financial loss or damage arising from the use of this software.

We invite you to read the source code and make contributions if you find a bug or wish to make an improvement.

## Design Philosophy

All API responses are returned as `data.table` objects with two transformations applied:

1. **snake_case column names** — camelCase keys from the JSON response (e.g. `insertTime`, `quoteQty`) are converted to snake_case (`insert_time`, `quote_qty`) via a mechanical transformation. No columns are renamed beyond this.

2. **Millisecond timestamps to POSIXct** — Columns containing epoch-millisecond timestamps are converted to `POSIXct` in-place under their snake_case name (e.g. `insertTime` becomes `insert_time` as a `POSIXct`).

That's it. **No fields are dropped and no columns are renamed** beyond the camelCase-to-snake_case conversion. If a column exists in the Binance API response, it will exist in the returned `data.table`. If you don't need a column, drop it yourself.

The only exception is klines (candlestick data), where Binance returns positional arrays instead of named objects. These are assigned descriptive column names (`open_time`, `open`, `high`, `low`, `close`, `volume`, `close_time`, etc.) matching the Binance documentation.

## Installation

```r
# install.packages("remotes")
remotes::install_github("dereckmezquita/binance")
```

## Setup

Set your API credentials as environment variables in `.Renviron`:

```bash
BINANCE_API_ENDPOINT = "https://api.binance.com"
BINANCE_API_KEY = your-api-key
BINANCE_API_SECRET = your-api-secret
```

If you don't have a key, visit the [Binance API documentation](https://binance-docs.github.io/apidocs/).

## Citation

If you use this package in your work, please cite it:

```r
citation("binance")
```

> Mezquita, D. (2026). binance: R API Wrapper to Binance Cryptocurrency
> Exchange. R package version 0.0.1.

## Licence

MIT &copy; [Dereck Mezquita](https://github.com/dereckmezquita) [![ORCID](https://img.shields.io/badge/ORCID-0000--0002--9307--6762-green)](https://orcid.org/0000-0002-9307-6762). See [LICENSE.md](LICENSE.md) for the full text, including the citation clause.
