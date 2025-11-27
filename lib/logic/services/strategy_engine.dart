import 'dart:math';
import '../../data/models/ohlc_data.dart';
import '../../data/models/trading_strategy.dart';

class StrategyEngine {
  static StrategyResult calculatePSAR(List<OHLCData> candles) {
    final double start = 0.02;
    final double increment = 0.02;
    final double maximum = 0.2;
    
    List<double> psar = List.filled(candles.length, double.nan);
    List<SignalPoint> signals = [];
    
    if (candles.length < 2) return StrategyResult(
      indicatorLine: psar,
      signals: signals,
      indicatorName: 'PSAR',
    );

    bool isLong = candles[1].close > candles[0].close;
    double af = start;
    double ep = isLong ? candles[0].high : candles[0].low;
    psar[0] = isLong ? candles[0].low : candles[0].high;

    for (int i = 1; i < candles.length; i++) {
      // Calculate PSAR
      psar[i] = psar[i - 1] + af * (ep - psar[i - 1]);

      // Check for reversal
      bool reverse = false;
      if (isLong) {
        if (candles[i].low < psar[i]) reverse = true;
        if (candles[i].high > ep) {
          ep = candles[i].high;
          af = min(af + increment, maximum);
        }
      } else {
        if (candles[i].high > psar[i]) reverse = true;
        if (candles[i].low < ep) {
          ep = candles[i].low;
          af = min(af + increment, maximum);
        }
      }

      if (reverse) {
        isLong = !isLong;
        af = start;
        psar[i] = ep;
        ep = isLong ? candles[i].high : candles[i].low;
        
        // Generate signal
        if (isLong) {
          double stopLoss = psar[i];
          double target = candles[i].close + 2 * (candles[i].close - psar[i]);
          signals.add(SignalPoint(
            index: i,
            type: SignalType.buy,
            price: candles[i].close,
            stopLoss: stopLoss,
            target: target,
          ));
        } else {
          signals.add(SignalPoint(
            index: i,
            type: SignalType.sell,
            price: candles[i].close,
          ));
        }
      }
    }

    return StrategyResult(
      indicatorLine: psar,
      signals: signals,
      indicatorName: 'PSAR',
    );
  }

  static StrategyResult calculateRSI(List<OHLCData> candles, {int period = 14}) {
    List<double> rsi = List.filled(candles.length, double.nan);
    List<SignalPoint> signals = [];

    if (candles.length <= period) return StrategyResult(
      indicatorLine: rsi,
      signals: signals,
      indicatorName: 'RSI',
    );

    List<double> gains = [];
    List<double> losses = [];

    for (int i = 1; i < candles.length; i++) {
      final change = candles[i].close - candles[i - 1].close;
      gains.add(max(0, change));
      losses.add(max(0, -change));
    }

    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    rsi[period] = 100 - (100 / (1 + (avgGain / (avgLoss == 0 ? 1 : avgLoss))));

    for (int i = period + 1; i < candles.length; i++) {
      avgGain = ((avgGain * (period - 1)) + gains[i - 1]) / period;
      avgLoss = ((avgLoss * (period - 1)) + losses[i - 1]) / period;
      
      rsi[i] = 100 - (100 / (1 + (avgGain / (avgLoss == 0 ? 1 : avgLoss))));

      // Generate signals: RSI < 30 = oversold (buy), RSI > 70 = overbought (sell)
      if (i > period + 1) {
        if (rsi[i - 1] < 30 && rsi[i] >= 30) {
          signals.add(SignalPoint(
            index: i,
            type: SignalType.buy,
            price: candles[i].close,
          ));
        } else if (rsi[i - 1] > 70 && rsi[i] <= 70) {
          signals.add(SignalPoint(
            index: i,
            type: SignalType.sell,
            price: candles[i].close,
          ));
        }
      }
    }

    return StrategyResult(
      indicatorLine: rsi,
      signals: signals,
      indicatorName: 'RSI (14)',
    );
  }

  static StrategyResult calculateMACD(List<OHLCData> candles) {
    List<double> macd = List.filled(candles.length, double.nan);
    List<double> signal = List.filled(candles.length, double.nan);
    List<SignalPoint> signals = [];

    if (candles.length < 26) return StrategyResult(
      indicatorLine: macd,
      secondaryLine: signal,
      signals: signals,
      indicatorName: 'MACD',
      secondaryName: 'Signal',
    );

    // Calculate EMA 12 and EMA 26
    List<double> ema12 = _calculateEMA(candles.map((c) => c.close).toList(), 12);
    List<double> ema26 = _calculateEMA(candles.map((c) => c.close).toList(), 26);

    // MACD = EMA12 - EMA26
    for (int i = 0; i < candles.length; i++) {
      if (!ema12[i].isNaN && !ema26[i].isNaN) {
        macd[i] = ema12[i] - ema26[i];
      }
    }

    // Signal line = EMA 9 of MACD
    signal = _calculateEMA(macd, 9);

    // Generate crossover signals
    for (int i = 1; i < candles.length; i++) {
      if (!macd[i].isNaN && !signal[i].isNaN && !macd[i - 1].isNaN && !signal[i - 1].isNaN) {
        // Bullish crossover
        if (macd[i - 1] < signal[i - 1] && macd[i] > signal[i]) {
          signals.add(SignalPoint(
            index: i,
            type: SignalType.buy,
            price: candles[i].close,
          ));
        }
        // Bearish crossover
        else if (macd[i - 1] > signal[i - 1] && macd[i] < signal[i]) {
          signals.add(SignalPoint(
            index: i,
            type: SignalType.sell,
            price: candles[i].close,
          ));
        }
      }
    }

    return StrategyResult(
      indicatorLine: macd,
      secondaryLine: signal,
      signals: signals,
      indicatorName: 'MACD',
      secondaryName: 'Signal',
    );
  }

  static StrategyResult calculateBollingerBands(List<OHLCData> candles, {int period = 20, double stdDev = 2.0}) {
    List<double> middle = List.filled(candles.length, double.nan);
    List<double> upper = List.filled(candles.length, double.nan);
    List<double> lower = List.filled(candles.length, double.nan);
    List<SignalPoint> signals = [];

    if (candles.length < period) return StrategyResult(
      indicatorLine: middle,
      secondaryLine: upper,
      signals: signals,
      indicatorName: 'BB Middle',
      secondaryName: 'BB Upper/Lower',
    );

    final closes = candles.map((c) => c.close).toList();

    for (int i = period - 1; i < candles.length; i++) {
      // Calculate SMA (middle band)
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += closes[i - j];
      }
      middle[i] = sum / period;

      // Calculate standard deviation
      double variance = 0;
      for (int j = 0; j < period; j++) {
        variance += pow(closes[i - j] - middle[i], 2);
      }
      double sd = sqrt(variance / period);

      upper[i] = middle[i] + (stdDev * sd);
      lower[i] = middle[i] - (stdDev * sd);

      // Generate signals: price breaks above upper = sell, below lower = buy
      if (i > period) {
        if (candles[i].close < lower[i] && candles[i - 1].close >= lower[i - 1]) {
          signals.add(SignalPoint(
            index: i,
            type: SignalType.buy,
            price: candles[i].close,
          ));
        } else if (candles[i].close > upper[i] && candles[i - 1].close <= upper[i - 1]) {
          signals.add(SignalPoint(
            index: i,
            type: SignalType.sell,
            price: candles[i].close,
          ));
        }
      }
    }

    return StrategyResult(
      indicatorLine: middle,
      secondaryLine: upper,
      signals: signals,
      indicatorName: 'BB Middle',
      secondaryName: 'BB Bands',
    );
  }

  static List<double> _calculateEMA(List<double> data, int period) {
    List<double> ema = List.filled(data.length, double.nan);
    if (data.length < period) return ema;

    final k = 2 / (period + 1);

    // Find the first index where we have enough consecutive non-NaN values
    int startIndex = -1;
    for (int i = 0; i <= data.length - period; i++) {
      bool hasEnoughData = true;
      for (int j = 0; j < period; j++) {
        if (data[i + j].isNaN) {
          hasEnoughData = false;
          break;
        }
      }
      if (hasEnoughData) {
        startIndex = i;
        break;
      }
    }
    
    // If we found a valid starting point, calculate SMA and then EMA
    if (startIndex >= 0) {
      // Calculate initial SMA
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += data[startIndex + j];
      }
      ema[startIndex + period - 1] = sum / period;
      
      // Calculate EMA for remaining values
      for (int i = startIndex + period; i < data.length; i++) {
        if (!data[i].isNaN && !ema[i - 1].isNaN) {
          ema[i] = (data[i] - ema[i - 1]) * k + ema[i - 1];
        }
      }
    }

    return ema;
  }
}
