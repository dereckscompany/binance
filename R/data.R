#' BTC-USDT 4-Hour OHLCV Data from Binance
#'
#' Historical candlestick (OHLCV) data for BTCUSDT on the Binance exchange
#' at 4-hour intervals. Contains 500 candles of sample data for demonstration
#' purposes. Produced by [binance_backfill_klines()].
#'
#' @format A [data.table::data.table] with 500 rows and 14 columns:
#' - `datetime` (POSIXct): Candle open time in UTC (the bar-reference time).
#' - `open` (Numeric): Opening price.
#' - `high` (Numeric): Highest price during the interval.
#' - `low` (Numeric): Lowest price during the interval.
#' - `close` (Numeric): Closing price.
#' - `volume` (Numeric): Trading volume in base currency (BTC).
#' - `close_time` (POSIXct): Candle close time in UTC.
#' - `quote_volume` (Numeric): Trading volume in quote currency (USDT).
#' - `trades` (Integer): Number of trades during the interval.
#' - `taker_buy_base_volume` (Numeric): Taker buy volume in base currency.
#' - `taker_buy_quote_volume` (Numeric): Taker buy volume in quote currency.
#' - `ignore` (Character): Unused field from Binance API.
#' - `symbol` (Character): Trading pair identifier, `"BTCUSDT"`.
#' - `interval` (Character): Candle interval, `"4h"`.
#'
#' @source Binance API via [binance_backfill_klines()]
#' @examples
#' data(binance_btc_usdt_4h_ohlcv)
#' head(binance_btc_usdt_4h_ohlcv)
"binance_btc_usdt_4h_ohlcv"
