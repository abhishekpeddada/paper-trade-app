class TradingStrategy {
  final String id;
  final String name;
  final String description;
  final String iconName;

  const TradingStrategy({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });

  static const List<TradingStrategy> allStrategies = [
    TradingStrategy(
      id: 'psar',
      name: 'PSAR Indicator',
      description: 'Parabolic SAR with 1:2 risk-reward ratio',
      iconName: 'trending_up',
    ),
    TradingStrategy(
      id: 'rsi',
      name: 'RSI Indicator',
      description: 'Relative Strength Index momentum oscillator',
      iconName: 'show_chart',
    ),
    TradingStrategy(
      id: 'macd',
      name: 'MACD Signals',
      description: 'Moving Average Convergence Divergence',
      iconName: 'waterfall_chart',
    ),
    TradingStrategy(
      id: 'bollinger',
      name: 'Bollinger Bands',
      description: 'Volatility-based breakout strategy',
      iconName: 'analytics',
    ),
    TradingStrategy(
      id: 'sma',
      name: 'Moving Average',
      description: 'Simple Moving Average trend indicator',
      iconName: 'stacked_line_chart',
    ),
    TradingStrategy(
      id: 'support_resistance',
      name: 'Support & Resistance',
      description: 'Pivot-based S/R levels with volume breakout',
      iconName: 'layers',
    ),
  ];
}

class StrategyResult {
  final List<double> indicatorLine;
  final List<double>? secondaryLine;
  final List<SignalPoint> signals;
  final String indicatorName;
  final String? secondaryName;

  StrategyResult({
    required this.indicatorLine,
    this.secondaryLine,
    required this.signals,
    required this.indicatorName,
    this.secondaryName,
  });
}

class SignalPoint {
  final int index;
  final SignalType type;
  final double price;
  final double? stopLoss;
  final double? target;

  SignalPoint({
    required this.index,
    required this.type,
    required this.price,
    this.stopLoss,
    this.target,
  });
}

enum SignalType {
  buy,
  sell,
  stopLoss,
  target,
}
