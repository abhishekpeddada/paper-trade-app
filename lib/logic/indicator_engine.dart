import 'dart:math';

/// Engine for executing indicator calculations
/// Supports common technical indicators like SMA, EMA, RSI, MACD, Bollinger Bands
class IndicatorEngine {
  
  /// Calculate Simple Moving Average
  static List<double> calculateSMA(List<double> prices, int period) {
    List<double> sma = [];
    for (int i = 0; i < prices.length; i++) {
      if (i < period - 1) {
        sma.add(double.nan);
      } else {
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += prices[i - j];
        }
        sma.add(sum / period);
      }
    }
    return sma;
  }

  /// Calculate Exponential Moving Average
  static List<double> calculateEMA(List<double> prices, int period) {
    List<double> ema = [];
    if (prices.isEmpty) return ema;

    double multiplier = 2.0 / (period + 1);
    
    // First EMA is SMA
    double sum = 0;
    for (int i = 0; i < period && i < prices.length; i++) {
      sum += prices[i];
    }
    double previousEMA = sum / period;
    
    for (int i = 0; i < prices.length; i++) {
      if (i < period - 1) {
        ema.add(double.nan);
      } else if (i == period - 1) {
        ema.add(previousEMA);
      } else {
        double currentEMA = (prices[i] - previousEMA) * multiplier + previousEMA;
        ema.add(currentEMA);
        previousEMA = currentEMA;
      }
    }
    return ema;
  }

  /// Calculate Relative Strength Index
  static List<double> calculateRSI(List<double> prices, int period) {
    List<double> rsi = [];
    if (prices.length < period + 1) {
      return List.filled(prices.length, double.nan);
    }

    List<double> gains = [];
    List<double> losses = [];

    // Calculate price changes
    for (int i = 1; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    // First period values
    double avgGain = gains.sublist(0, period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.sublist(0, period).reduce((a, b) => a + b) / period;

    rsi.add(double.nan); // First value is undefined
    for (int i = 0; i < period; i++) {
      rsi.add(double.nan);
    }

    // Calculate RSI
    for (int i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;

      if (avgLoss == 0) {
        rsi.add(100);
      } else {
        double rs = avgGain / avgLoss;
        rsi.add(100 - (100 / (1 + rs)));
      }
    }

    return rsi;
  }

  /// Calculate MACD (returns [MACD line, Signal line, Histogram])
  static Map<String, List<double>> calculateMACD(
    List<double> prices, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    List<double> fastEMA = calculateEMA(prices, fastPeriod);
    List<double> slowEMA = calculateEMA(prices, slowPeriod);

    List<double> macdLine = [];
    for (int i = 0; i < prices.length; i++) {
      if (fastEMA[i].isNaN || slowEMA[i].isNaN) {
        macdLine.add(double.nan);
      } else {
        macdLine.add(fastEMA[i] - slowEMA[i]);
      }
    }

    List<double> signalLine = calculateEMA(
      macdLine.where((v) => !v.isNaN).toList(),
      signalPeriod,
    );

    // Pad signal line to match macdLine length
    int nanCount = macdLine.where((v) => v.isNaN).length;
    signalLine = List.filled(nanCount, double.nan) + signalLine;

    List<double> histogram = [];
    for (int i = 0; i < macdLine.length; i++) {
      if (macdLine[i].isNaN || signalLine[i].isNaN) {
        histogram.add(double.nan);
      } else {
        histogram.add(macdLine[i] - signalLine[i]);
      }
    }

    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': histogram,
    };
  }

  /// Calculate Bollinger Bands (returns [Upper, Middle, Lower])
  static Map<String, List<double>> calculateBollingerBands(
    List<double> prices,
    int period,
    double stdDevMultiplier,
  ) {
    List<double> sma = calculateSMA(prices, period);
    List<double> upper = [];
    List<double> lower = [];

    for (int i = 0; i < prices.length; i++) {
      if (sma[i].isNaN) {
        upper.add(double.nan);
        lower.add(double.nan);
      } else {
        // Calculate standard deviation for the period
        double sumSquaredDiff = 0;
        for (int j = 0; j < period; j++) {
          double diff = prices[i - j] - sma[i];
          sumSquaredDiff += diff * diff;
        }
        double stdDev = sqrt(sumSquaredDiff / period);

        upper.add(sma[i] + stdDevMultiplier * stdDev);
        lower.add(sma[i] - stdDevMultiplier * stdDev);
      }
    }

    return {
      'upper': upper,
      'middle': sma,
      'lower': lower,
    };
  }

  /// Parse and extract indicator function from AI-generated Dart code
  static String extractFunctionCode(String aiResponse) {
    // Remove markdown code blocks if present
    String code = aiResponse.trim();
    
    // Remove ```dart and ``` markers
    code = code.replaceAll(RegExp(r'^```dart\s*'), '');
    code = code.replaceAll(RegExp(r'^```\s*'), '');
    code = code.replaceAll(RegExp(r'\s*```$'), '');
    
    return code.trim();
  }

  /// Execute indicator calculation based on AI-converted code
  /// This is a simplified version - in production, you'd want more robust parsing
  static List<double>? executeIndicator(
    String dartCode,
    List<double> prices, {
    Map<String, dynamic>? parameters,
  }) {
    try {
      // For safety, we'll match common indicator patterns and execute pre-built functions
      final cleanCode = extractFunctionCode(dartCode).toLowerCase();
      
      if (cleanCode.contains('sma') || cleanCode.contains('simple moving average')) {
        int period = parameters?['period'] ?? 20;
        return calculateSMA(prices, period);
      } else if (cleanCode.contains('ema') || cleanCode.contains('exponential moving average')) {
        int period = parameters?['period'] ?? 20;
        return calculateEMA(prices, period);
      } else if (cleanCode.contains('rsi') || cleanCode.contains('relative strength')) {
        int period = parameters?['period'] ?? 14;
        return calculateRSI(prices, period);
      }
      
      // Default: return the prices (no indicator)
      return prices;
    } catch (e) {
      print('Error executing indicator: $e');
      return null;
    }
  }
}
