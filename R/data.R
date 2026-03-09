#' BTC-USDT 4-Hour OHLCV Data from Binance
#'
#' Historical candlestick (OHLCV) data for BTCUSDT on the Binance exchange
#' at 4-hour intervals. Contains 500 candles of sample data for demonstration
#' purposes. Produced by [binance_backfill_klines()].
#'
#' @format A [data.table::data.table] with 500 rows and 14 columns:
#' \describe{
#'   \item{open_time}{POSIXct. Candle open time in UTC.}
#'   \item{open}{Numeric. Opening price.}
#'   \item{high}{Numeric. Highest price during the interval.}
#'   \item{low}{Numeric. Lowest price during the interval.}
#'   \item{close}{Numeric. Closing price.}
#'   \item{volume}{Numeric. Trading volume in base currency (BTC).}
#'   \item{close_time}{POSIXct. Candle close time in UTC.}
#'   \item{quote_volume}{Numeric. Trading volume in quote currency (USDT).}
#'   \item{trades}{Integer. Number of trades during the interval.}
#'   \item{taker_buy_base_volume}{Numeric. Taker buy volume in base currency.}
#'   \item{taker_buy_quote_volume}{Numeric. Taker buy volume in quote currency.}
#'   \item{ignore}{Character. Unused field from Binance API.}
#'   \item{symbol}{Character. Trading pair identifier, `"BTCUSDT"`.}
#'   \item{interval}{Character. Candle interval, `"4h"`.}
#' }
#'
#' @source Binance API via [binance_backfill_klines()]
#' @examples
#' data(binance_btc_usdt_4h_ohlcv)
#' head(binance_btc_usdt_4h_ohlcv)
"binance_btc_usdt_4h_ohlcv"
