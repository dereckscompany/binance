# Build and Execute a Binance API Request

Constructs an
[httr2::request](https://httr2.r-lib.org/reference/request.html),
optionally signs it, performs it via the supplied `.perform` function,
and parses the JSON response. This is the single point through which all
Binance API calls flow.

## Usage

``` r
binance_build_request(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  timeout = 10,
  .get_timestamp_ms = NULL
)
```

## Arguments

- base_url:

  Character; the API base URL.

- endpoint:

  Character; the API path.

- method:

  Character; HTTP method. Default `"GET"`.

- query:

  Named list; query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- body:

  Named list or NULL; request body (for POST). Default `NULL`.

- keys:

  List or NULL; API credentials. Default `NULL`.

- .perform:

  Function; the httr2 perform function. Default
  [`httr2::req_perform`](https://httr2.r-lib.org/reference/req_perform.html).

- .parser:

  Function; post-processing function applied to parsed response. Default
  `identity`.

- is_async:

  Logical; whether `.perform` returns promises. Default `FALSE`.

- timeout:

  Numeric; request timeout in seconds. Default `10`.

- .get_timestamp_ms:

  Function or NULL; zero-argument function returning epoch milliseconds
  for HMAC signing.

## Value

Parsed and post-processed API response data, or a promise thereof.
