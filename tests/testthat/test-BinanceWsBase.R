# Tests for the WebSocket stream clients (BinanceWsBase / BinanceMarketStream).
# Pure helpers + connection-free behaviour are tested without a live socket; the
# live end-to-end test is skip-guarded behind BINANCE_LIVE_TESTS.

# ---- Pure helpers -----------------------------------------------------------

test_that("ws_control_message encodes params as a JSON array even for one stream", {
  msg <- ws_control_message("SUBSCRIBE", "btcusdt@depth", 1L)
  parsed <- jsonlite::fromJSON(msg, simplifyVector = FALSE)
  expect_equal(parsed$method, "SUBSCRIBE")
  expect_equal(parsed$id, 1L)
  expect_true(is.list(parsed$params)) # array, not unboxed scalar
  expect_equal(parsed$params[[1]], "btcusdt@depth")

  multi <- jsonlite::fromJSON(ws_control_message("UNSUBSCRIBE", c("a@depth", "b@depth"), 2L), simplifyVector = FALSE)
  expect_equal(length(multi$params), 2L)
})

test_that("ws_depth_stream lower-cases and applies the speed suffix", {
  expect_equal(ws_depth_stream("BTCUSDT"), "btcusdt@depth")
  expect_equal(ws_depth_stream("BTCUSDT", "1000ms"), "btcusdt@depth")
  expect_equal(ws_depth_stream("BTCUSDT", "100ms"), "btcusdt@depth@100ms")
  expect_error(ws_depth_stream("BTCUSDT", "50ms"))
})

test_that("ws_backoff_delay grows but stays bounded and >= 1", {
  set.seed(1)
  for (attempt in 1:12) {
    d <- ws_backoff_delay(attempt, cap_seconds = 60)
    expect_gte(d, 1)
    expect_lte(d, 61) # cap (60) * jitter (<=1) + 1
  }
})

# ---- Connection-free class behaviour ----------------------------------------

test_that("BinanceMarketStream tracks subscriptions and builds depth stream names", {

  stream <- BinanceMarketStream$new()
  expect_false(stream$is_open())
  expect_length(stream$subscriptions(), 0L)

  stream$depth("BTCUSDT", speed = "100ms")
  stream$depth("ETHUSDT") # default 1000ms
  expect_setequal(stream$subscriptions(), c("btcusdt@depth@100ms", "ethusdt@depth"))

  stream$subscribe("SOLUSDT@trade") # arbitrary stream, lower-cased
  expect_true("solusdt@trade" %in% stream$subscriptions())

  stream$unsubscribe("ethusdt@depth")
  expect_false("ethusdt@depth" %in% stream$subscriptions())
})

test_that("$on validates the event name and requires a function", {
  stream <- BinanceMarketStream$new()
  expect_error(stream$on("nope", function(x) x))
  expect_error(stream$on("message", "not a function"))
  expect_invisible(stream$on("message", function(x) x))
})

test_that("dispatch sends raw messages to global and per-stream handlers correctly", {

  global <- list()
  per_stream <- list()
  stream <- BinanceMarketStream$new()
  stream$on("message", function(m) global[[length(global) + 1L]] <<- m)
  stream$depth("BTCUSDT", handler = function(m) per_stream[[length(per_stream) + 1L]] <<- m)

  priv <- stream$.__enclos_env__$private
  priv$.dispatch('{"stream":"btcusdt@depth","data":{"e":"depthUpdate"}}')
  expect_length(global, 1L) # global handler sees it
  expect_length(per_stream, 1L) # per-stream handler sees it

  priv$.dispatch('{"stream":"ethusdt@depth","data":{}}')
  expect_length(global, 2L) # global sees every message
  expect_length(per_stream, 1L) # per-stream handler not called for eth
})

test_that("control responses are filtered from messages; errors reach the error handler", {
  msgs <- list()
  errs <- list()
  stream <- BinanceMarketStream$new()
  stream$on("message", function(m) msgs[[length(msgs) + 1L]] <<- m)
  stream$on("error", function(e) errs[[length(errs) + 1L]] <<- e)
  priv <- stream$.__enclos_env__$private

  priv$.dispatch('{"result":null,"id":1}') # a SUBSCRIBE ack
  expect_length(msgs, 0L) # never delivered as a message
  expect_length(errs, 0L) # a success ack is not an error

  priv$.dispatch('{"error":{"code":2,"msg":"Invalid request"},"id":1}')
  expect_length(msgs, 0L) # a failed control response never reaches message handlers
  expect_length(errs, 1L) # it surfaces to the error handler instead
  expect_equal(errs[[1L]]$error$msg, "Invalid request")
})

test_that("$send errors when the socket is not open", {
  stream <- BinanceMarketStream$new()
  expect_error(stream$send('{"method":"PING"}'), "not open")
})

test_that("a throwing handler warns but does not propagate", {
  stream <- BinanceMarketStream$new()
  stream$on("message", function(m) stop("boom"))
  priv <- stream$.__enclos_env__$private
  expect_warning(priv$.dispatch('{"stream":"x","data":{}}'), "handler error")
})

test_that("close() is safe before any connection", {
  stream <- BinanceMarketStream$new()
  expect_invisible(stream$close())
  expect_false(stream$is_open())
})

# ---- Live integration (skip-guarded) ----------------------------------------

test_that("live: depth stream connects and delivers depthUpdate messages", {
  if (!nzchar(Sys.getenv("BINANCE_LIVE_TESTS"))) {
    skip("Set BINANCE_LIVE_TESTS to run live WebSocket tests")
  }

  msgs <- list()
  stream <- BinanceMarketStream$new()
  stream$on("message", function(m) {
    msgs[[length(msgs) + 1L]] <<- m
    if (length(msgs) >= 3L) stream$close()
    return(invisible(NULL))
  })
  stream$depth("BTCUSDT", speed = "100ms")

  guard <- later::later(function() return(stream$close()), 20) # backstop so the test can never hang
  stream$run()
  guard() # cancel the backstop (later::later returns a cancel function)

  expect_gte(length(msgs), 1L)
  parsed <- jsonlite::fromJSON(msgs[[1L]])
  expect_equal(parsed$stream, "btcusdt@depth@100ms")
  expect_equal(parsed$data$e, "depthUpdate")
})
