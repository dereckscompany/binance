# File: R/BinanceBase.R
# Abstract R6 base class for all Binance API client classes.

#' BinanceBase: Abstract Base Class for Binance API Clients
#'
#' Provides shared infrastructure for all Binance R6 classes, including API
#' credential management, sync/async execution mode, timestamp source
#' configuration, and a standardised method for calling implementation
#' functions.
#'
#' ### Transport
#' This class is a thin Binance specialisation of [connectcore::RestClient], the
#' shared transport base. The request funnel, sync/async branching, retry, and
#' throttle all live in `connectcore`; `BinanceBase` only supplies the two
#' venue-specific seams — how Binance authenticates a request (`.sign()`,
#' delegating to [connectcore::hmac_query_sign()] with the `X-MBX-APIKEY` header)
#' and how it reports an error (`.parse_envelope()`, which honours Binance's
#' negative-`code` error body). Binance carries signed parameters in the query
#' string, so the body is configured as `body_format = "query"`.
#'
#' ### Sync vs Async
#' The `async` parameter controls execution mode for all API methods:
#' - `async = FALSE` (default): methods return results directly (`data.table`, character, etc.).
#' - `async = TRUE`: methods return [promises::promise] objects that resolve to the same types.
#'
#' When async, use [coro::async()] and `await()` or [promises::then()] to consume results.
#' The `promises` package must be installed for async mode (`Suggests` dependency).
#'
#' ### Timestamp Source
#' The `time_source` parameter controls which clock is used for HMAC request
#' signing:
#' - `"local"` (default): uses the local UTC clock.
#' - `"server"`: fetches the Binance server time via `GET /api/v3/time`
#'   before each authenticated request. This is slower (one extra HTTP round
#'   trip) but ensures signing works even when the local clock is out of sync.
#'
#' ### Retries
#' `max_tries > 1` opts every GET this client makes into automatic retry on a
#' transient failure (HTTP 408/429/5xx or a dropped connection) with jittered
#' backoff, delegated to [connectcore::build_request()]. Retry is a hard
#' **GET-only** carve-out: a non-idempotent verb (an order `POST`, a cancel
#' `DELETE`) is never auto-retried, so a resend can never double-submit an order.
#' Leave it at the default `1` for live trading — there the trader layer is the
#' single retry authority (it routes by typed error class and manages cooldowns);
#' raise it only for research and backfill reads.
#'
#' ### Design
#' This class is not meant to be instantiated directly. Subclasses (e.g.,
#' [BinanceMarketData], [BinanceTrading]) inherit from it and define their
#' own public methods that delegate to `private$.request()`.
#'
#' @examples
#' \dontrun{
#' # Not instantiated directly; use subclasses:
#' market <- BinanceMarketData$new()          # sync
#' market_async <- BinanceMarketData$new(async = TRUE)  # async
#'
#' # Use server time for HMAC signing (avoids clock-drift issues):
#' trading <- BinanceTrading$new(time_source = "server")
#' }
#'
#' @importFrom R6 R6Class
#' @export
BinanceBase <- R6::R6Class(
  "BinanceBase",
  inherit = connectcore::RestClient,
  public = list(
    #' @description
    #' Initialise a BinanceBase Object
    #'
    #' @param keys (list) API credentials from [get_api_keys()].
    #'   Defaults to `get_api_keys()`.
    #' @param base_url (scalar<character>) API base URL. Defaults to
    #'   `get_base_url()`.
    #' @param async (scalar<logical>) if `TRUE`, methods return promises. Default
    #'   `FALSE`.
    #' @param time_source (scalar<character in c("local", "server")>) clock source
    #'   for HMAC request signing. `"local"` (default) uses the local UTC clock.
    #'   `"server"` fetches the Binance server time before each authenticated
    #'   request, which adds latency but avoids clock-drift issues.
    #' @param max_tries (scalar<integer in [1, 10]>) for idempotent GET requests
    #'   only, retry up to this many times on a transient failure. Default `1`
    #'   (no retry). See the class **Retries** section for the write-safety
    #'   carve-out and why live trading should leave this at `1`.
    #' @return (class<BinanceBase>) invisibly, self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE,
      time_source = c("local", "server"),
      max_tries = 1L
    ) {
      time_source <- match.arg(time_source)
      assert_args_BinanceBase__initialize(keys, base_url, async, time_source, max_tries)
      assert::assert_nonempty_strings(base_url)
      super$initialize(
        keys = keys,
        base_url = base_url,
        async = async,
        time_source = time_source,
        time_endpoint = "/api/v3/time",
        time_field = "serverTime",
        body_format = "query",
        max_tries = max_tries
      )
      return(invisible(assert_return_BinanceBase__initialize(self)))
    }
  ),
  private = list(
    # Authenticate a Binance request: append `timestamp` + HMAC-SHA256 `signature`
    # query params and the `X-MBX-APIKEY` header, signing against the configured
    # (local or server) clock exposed via `ctx$get_timestamp_ms`.
    .sign = function(req, keys, ctx) {
      return(connectcore::hmac_query_sign(
        req,
        keys,
        get_timestamp_ms = ctx$get_timestamp_ms,
        api_key_header = "X-MBX-APIKEY"
      ))
    },

    # Parse a Binance response, honouring its error envelope (a negative `code`
    # in the JSON body signals an API error even on a non-200 status).
    .parse_envelope = function(resp) {
      return(parse_binance_response(resp))
    }
  )
)
