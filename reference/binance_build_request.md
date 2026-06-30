# Build and Execute a Binance API Request

Constructs an
[httr2::request](https://httr2.r-lib.org/reference/request.html),
optionally signs it, performs it via the supplied `.perform` function,
and parses the JSON response. This is the single point through which all
Binance API calls flow. A thin wrapper over
[`connectcore::build_request()`](https://rdrr.io/pkg/connectcore/man/build_request.html)
that injects Binance's signer and error envelope and carries signed
parameters in the query string (`body_format = "query"`).

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

  (scalar\<character\>) the API base URL.

- endpoint:

  (scalar\<character\>) the API path.

- method:

  (scalar\<character\>) HTTP method. Default `"GET"`.

- query:

  (list) query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- body:

  (list \| NULL) request body (for POST). Default `NULL`.

- keys:

  (list \| NULL) API credentials. Default `NULL`.

- .perform:

  (function) the httr2 perform function. Default
  [`httr2::req_perform`](https://httr2.r-lib.org/reference/req_perform.html).

- .parser:

  (function) post-processing function applied to parsed response.
  Default `identity`.

- is_async:

  (scalar\<logical\>) whether `.perform` returns promises. Default
  `FALSE`.

- timeout:

  (scalar\<numeric in \]0, Inf\[\>) request timeout in seconds. Default
  `10`.

- .get_timestamp_ms:

  (function?) zero-argument function returning epoch milliseconds for
  HMAC signing.

## Value

(promise\<any\>) parsed and post-processed API response data, or a
promise thereof.
