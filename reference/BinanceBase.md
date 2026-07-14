# BinanceBase: Abstract Base Class for Binance API Clients

Provides shared infrastructure for all Binance R6 classes, including API
credential management, sync/async execution mode, timestamp source
configuration, and a standardised method for calling implementation
functions.

### Transport

This class is a thin Binance specialisation of
[connectcore::RestClient](https://rdrr.io/pkg/connectcore/man/RestClient.html),
the shared transport base. The request funnel, sync/async branching,
retry, and throttle all live in `connectcore`; `BinanceBase` only
supplies the two venue-specific seams — how Binance authenticates a
request (`.sign()`, delegating to
[`connectcore::hmac_query_sign()`](https://rdrr.io/pkg/connectcore/man/hmac_query_sign.html)
with the `X-MBX-APIKEY` header) and how it reports an error
(`.parse_envelope()`, which honours Binance's negative-`code` error
body). Binance carries signed parameters in the query string, so the
body is configured as `body_format = "query"`.

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

- `"local"` (default): uses the local UTC clock.

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

## Super class

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\> `BinanceBase`

## Methods

### Public methods

- [`BinanceBase$new()`](#method-BinanceBase-initialize)

- [`BinanceBase$clone()`](#method-BinanceBase-clone)

------------------------------------------------------------------------

### `BinanceBase$new()`

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

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/binance/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) API base URL. Defaults to
  [`get_base_url()`](https://dereckscompany.github.io/binance/reference/get_base_url.md).

- `async`:

  (scalar\<logical\>) if `TRUE`, methods return promises. Default
  `FALSE`.

- `time_source`:

  (scalar\<character in c("local", "server")\>) clock source for HMAC
  request signing. `"local"` (default) uses the local UTC clock.
  `"server"` fetches the Binance server time before each authenticated
  request, which adds latency but avoids clock-drift issues.

#### Returns

(class\<BinanceBase\>) invisibly, self.

------------------------------------------------------------------------

### `BinanceBase$clone()`

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
