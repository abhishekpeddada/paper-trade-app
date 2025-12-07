class BacktestTrade {
  final DateTime entryDate;
  final DateTime exitDate;
  final double entryPrice;
  final double exitPrice;
  final String signal; 
  final double profitLoss;
  final double profitLossPct;
  final bool isWin;

  BacktestTrade({
    required this.entryDate,
    required this.exitDate,
    required this.entryPrice,
    required this.exitPrice,
    required this.signal,
    required this.profitLoss,
    required this.profitLossPct,
    required this.isWin,
  });
}

class BacktestResult {
  final String symbol;
  final String strategy;
  final DateTime startDate;
  final DateTime endDate;
  final int totalCandles;
  
  final List<BacktestTrade> trades;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  
  final double winRate;
  final double totalReturn;
  final double totalReturnPct;
  final double maxDrawdown;
  final double maxDrawdownPct;
  final double avgWin;
  final double avgLoss;
  final double profitFactor;
  final double avgHoldingPeriodDays;
  
  final double initialCapital;
  final double finalCapital;
  
  final List<double> equityCurve;
  final List<DateTime> equityDates;

  BacktestResult({
    required this.symbol,
    required this.strategy,
    required this.startDate,
    required this.endDate,
    required this.totalCandles,
    required this.trades,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.winRate,
    required this.totalReturn,
    required this.totalReturnPct,
    required this.maxDrawdown,
    required this.maxDrawdownPct,
    required this.avgWin,
    required this.avgLoss,
    required this.profitFactor,
    required this.avgHoldingPeriodDays,
    required this.initialCapital,
    required this.finalCapital,
    required this.equityCurve,
    required this.equityDates,
  });
}
