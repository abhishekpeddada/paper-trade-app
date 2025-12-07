import '../../data/models/ohlc_data.dart';
import '../../data/models/trading_strategy.dart';
import '../../data/models/backtest_result.dart';
import 'strategy_engine.dart';

class BacktestEngine {
  static const double defaultCapital = 100000.0;

  static BacktestResult runBacktest({
    required List<OHLCData> candles,
    required String strategyId,
    required String symbol,
    double initialCapital = defaultCapital,
  }) {
    if (candles.isEmpty) {
      return _emptyResult(symbol, strategyId, initialCapital);
    }

    final strategyResult = _calculateStrategy(candles, strategyId);
    final signals = strategyResult.signals;

    final trades = <BacktestTrade>[];
    double capital = initialCapital;
    double position = 0; 
    double entryPrice = 0;
    DateTime? entryDate;
    
    final equityCurve = <double>[initialCapital];
    final equityDates = <DateTime>[candles.first.timestamp];
    
    double peak = initialCapital;
    double maxDrawdown = 0;
    double maxDrawdownPct = 0;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final currentPrice = candle.close;
      
      final signalsAtIndex = signals.where((s) => s.index == i).toList();
      
      for (final signal in signalsAtIndex) {
        if (signal.type == SignalType.buy && position == 0) {
          position = capital / currentPrice;
          entryPrice = currentPrice;
          entryDate = candle.timestamp;
        } else if (signal.type == SignalType.sell && position > 0) {
          final exitPrice = currentPrice;
          final profitLoss = (exitPrice - entryPrice) * position;
          final profitLossPct = (exitPrice - entryPrice) / entryPrice * 100;
          
          trades.add(BacktestTrade(
            entryDate: entryDate!,
            exitDate: candle.timestamp,
            entryPrice: entryPrice,
            exitPrice: exitPrice,
            signal: 'LONG',
            profitLoss: profitLoss,
            profitLossPct: profitLossPct,
            isWin: profitLoss > 0,
          ));
          
          capital += profitLoss;
          position = 0;
          entryPrice = 0;
          entryDate = null;
        }
      }
      
      double currentEquity = capital;
      if (position > 0) {
        currentEquity = position * currentPrice;
      }
      
      equityCurve.add(currentEquity);
      equityDates.add(candle.timestamp);
      
      if (currentEquity > peak) {
        peak = currentEquity;
      }
      final drawdown = peak - currentEquity;
      final drawdownPct = (drawdown / peak) * 100;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
        maxDrawdownPct = drawdownPct;
      }
    }
    
    if (position > 0) {
      final lastPrice = candles.last.close;
      final profitLoss = (lastPrice - entryPrice) * position;
      final profitLossPct = (lastPrice - entryPrice) / entryPrice * 100;
      
      trades.add(BacktestTrade(
        entryDate: entryDate!,
        exitDate: candles.last.timestamp,
        entryPrice: entryPrice,
        exitPrice: lastPrice,
        signal: 'LONG (Open)',
        profitLoss: profitLoss,
        profitLossPct: profitLossPct,
        isWin: profitLoss > 0,
      ));
      
      capital += profitLoss;
    }

    final winningTrades = trades.where((t) => t.isWin).toList();
    final losingTrades = trades.where((t) => !t.isWin).toList();
    
    final winRate = trades.isEmpty ? 0.0 : (winningTrades.length / trades.length) * 100;
    final totalReturn = capital - initialCapital;
    final totalReturnPct = (totalReturn / initialCapital) * 100;
    
    final avgWin = winningTrades.isEmpty 
        ? 0.0 
        : winningTrades.map((t) => t.profitLossPct).reduce((a, b) => a + b) / winningTrades.length;
    final avgLoss = losingTrades.isEmpty 
        ? 0.0 
        : losingTrades.map((t) => t.profitLossPct).reduce((a, b) => a + b) / losingTrades.length;
    
    final grossProfit = winningTrades.isEmpty 
        ? 0.0 
        : winningTrades.map((t) => t.profitLoss).reduce((a, b) => a + b);
    final grossLoss = losingTrades.isEmpty 
        ? 0.0 
        : losingTrades.map((t) => t.profitLoss.abs()).reduce((a, b) => a + b);
    final profitFactor = grossLoss == 0 ? double.infinity : grossProfit / grossLoss;
    
    double totalDays = 0;
    for (final trade in trades) {
      totalDays += trade.exitDate.difference(trade.entryDate).inDays;
    }
    final avgHoldingDays = trades.isEmpty ? 0.0 : totalDays / trades.length;

    return BacktestResult(
      symbol: symbol,
      strategy: strategyId,
      startDate: candles.first.timestamp,
      endDate: candles.last.timestamp,
      totalCandles: candles.length,
      trades: trades,
      totalTrades: trades.length,
      winningTrades: winningTrades.length,
      losingTrades: losingTrades.length,
      winRate: winRate,
      totalReturn: totalReturn,
      totalReturnPct: totalReturnPct,
      maxDrawdown: maxDrawdown,
      maxDrawdownPct: maxDrawdownPct,
      avgWin: avgWin,
      avgLoss: avgLoss,
      profitFactor: profitFactor.isFinite ? profitFactor : 0,
      avgHoldingPeriodDays: avgHoldingDays,
      initialCapital: initialCapital,
      finalCapital: capital,
      equityCurve: equityCurve,
      equityDates: equityDates,
    );
  }

  static StrategyResult _calculateStrategy(List<OHLCData> candles, String strategyId) {
    switch (strategyId) {
      case 'psar':
        return StrategyEngine.calculatePSAR(candles);
      case 'rsi':
        return StrategyEngine.calculateRSI(candles);
      case 'macd':
        return StrategyEngine.calculateMACD(candles);
      case 'bollinger':
        return StrategyEngine.calculateBollingerBands(candles);
      case 'sma':
        return StrategyEngine.calculateSMA(candles);
      default:
        return StrategyEngine.calculatePSAR(candles);
    }
  }

  static BacktestResult _emptyResult(String symbol, String strategy, double capital) {
    return BacktestResult(
      symbol: symbol,
      strategy: strategy,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      totalCandles: 0,
      trades: [],
      totalTrades: 0,
      winningTrades: 0,
      losingTrades: 0,
      winRate: 0,
      totalReturn: 0,
      totalReturnPct: 0,
      maxDrawdown: 0,
      maxDrawdownPct: 0,
      avgWin: 0,
      avgLoss: 0,
      profitFactor: 0,
      avgHoldingPeriodDays: 0,
      initialCapital: capital,
      finalCapital: capital,
      equityCurve: [capital],
      equityDates: [DateTime.now()],
    );
  }
}
