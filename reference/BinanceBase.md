# BinanceBase: Abstract Base Class for Binance API Clients

BinanceBase: Abstract Base Class for Binance API Clients

BinanceBase: Abstract Base Class for Binance API Clients

## Details

Provides shared infrastructure for all Binance R6 classes, including API
credential management, sync/async execution mode, timestamp source
configuration, and a standardised method for calling implementation
functions.

### Sync vs Async

The `async` parameter controls execution mode for all API methods:

- `async = FALSE` (default): methods return results directly
  (`data.table`, character, etc.).

- `async = TRUE`: methods return
  [promises::promise](https://rstudio.github.io/promises/reference/promise.html)
  objects that resolve to the same types.

When async, use
[`coro::async()`](https://coro.r-lib.org/reference/async.html) and
`await()` or
[`promises::then()`](https://rstudio.github.io/promises/reference/then.html)
to consume results. The `promises` package must be installed for async
mode (`Suggests` dependency).

### Timestamp Source

The `time_source` parameter controls which clock is used for HMAC
request signing:

- `"local"` (default): uses
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) from the local
  machine.

- `"server"`: fetches the Binance server time via `GET /api/v3/time`
  before each authenticated request. This is slower (one extra HTTP
  round trip) but ensures signing works even when the local clock is out
  of sync.

### Design

This class is not meant to be instantiated directly. Subclasses (e.g.,
[BinanceMarketData](https://dereckscompany.github.io/binance/reference/BinanceMarketData.md),
[BinanceTrading](https://dereckscompany.github.io/binance/reference/BinanceTrading.md))
inherit from it and define their own public methods that delegate to
`private$.request()`.

## Fields

All fields are private:

- `.keys`: List; API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).

- `.base_url`: Character; API base URL from
  [`get_base_url()`](https://dereckscompany.github.io/binance/reference/get_base_url.md).

- `.perform`: Function; either
  [httr2::req_perform](https://httr2.r-lib.org/reference/req_perform.html)
  or
  [httr2::req_perform_promise](https://httr2.r-lib.org/reference/req_perform_promise.html).

- `.is_async`: Logical; whether the instance is in async mode.

- `.time_source`: Character; `"local"` or `"server"`.

- `.get_timestamp_ms`: Function; returns epoch milliseconds for HMAC
  signing.

## Active bindings

- `is_async`:

  Logical; read-only flag indicating whether this instance operates in
  async mode.

- `time_source`:

  Character; read-only flag indicating the timestamp source used for
  HMAC signing (`"local"` or `"server"`).

## Methods

### Public methods

- [`BinanceBase$new()`](#method-BinanceBase-new)

- [`BinanceBase$clone()`](#method-BinanceBase-clone)

------------------------------------------------------------------------

### Method `new()`

Initialise a BinanceBase Object

#### Usage

    BinanceBase$new(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    )

#### Arguments

- `keys`:

  List; API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).

- `base_url`:

  Character; API base URL. Defaults to
  [`get_base_url()`](https://dereckscompany.github.io/binance/reference/get_base_url.md).

- `async`:

  Logical; if `TRUE`, methods return promises. Default `FALSE`.

- `time_source`:

  Character; clock source for HMAC request signing. `"local"` (default)
  uses [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html). `"server"`
  fetches the Binance server time before each authenticated request,
  which adds latency but avoids clock-drift issues.

#### Returns

Invisible self.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinanceBase$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Not instantiated directly; use subclasses:
market <- BinanceMarketData$new()          # sync
market_async <- BinanceMarketData$new(async = TRUE)  # async

# Use server time for HMAC signing (avoids clock-drift issues):
trading <- BinanceTrading$new(time_source = "server")
} # }
```
