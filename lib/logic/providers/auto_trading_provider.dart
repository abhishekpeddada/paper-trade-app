import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider.dart';
import 'portfolio_provider.dart';
import 'watchlist_provider.dart';
import '../../data/models/ai_signal.dart';
import '../../data/models/ohlc_data.dart';
import '../../data/models/trading_strategy.dart';
import '../../data/services/yahoo_finance_service.dart';
import '../services/strategy_engine.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/services/firestore_service.dart';

class AutoTradingProvider extends ChangeNotifier {
  final YahooFinanceService _yahooService = YahooFinanceService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isRunning = false;
  List<String> _logs = [];
  double _progress = 0.0;

  bool get isRunning => _isRunning;
  List<String> get logs => _logs;
  double get progress => _progress;

  AutoTradingProvider() {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    // Auto-trading logs are local-only (not synced to Firebase)
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getStringList('auto_trading_logs');
    if (savedLogs != null) {
      _logs = savedLogs;
      notifyListeners();
    }
  }

  Future<void> _saveLogs() async {
    // Auto-trading logs are local-only (not synced to Firebase)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('auto_trading_logs', _logs);
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split('.')[0].split(' ')[1];
    _logs.add('[$timestamp] $message'); // Changed from insert(0) to add()
    if (_logs.length > 200) _logs.removeAt(0); // Remove oldest instead of newest
    _saveLogs();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _saveLogs();
    notifyListeners();
  }

  Future<void> runDailyScan(AIProvider ai, PortfolioProvider portfolio, WatchlistProvider watchlist) async {
    String? lastScan;
    if (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows) {
      final prefs = await SharedPreferences.getInstance();
      lastScan = prefs.getString('last_scan_date');
    } else {
      lastScan = await _firestoreService.loadLastScanDate();
    }
    
    final today = DateTime.now().toString().split(' ')[0];

    if (lastScan == today) {
      return;
    }

    _addLog('Starting Daily Portfolio Scan...');
    await analyzePortfolio(ai, portfolio, watchlist, force: true);
    
    if (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_scan_date', today);
    } else {
      await _firestoreService.saveLastScanDate(today);
    }
    _addLog('Daily scan completed.');
  }

  Future<void> analyzeWatchlist(AIProvider ai, PortfolioProvider portfolio, WatchlistProvider watchlist) async {
    if (_isRunning) return;
    _isRunning = true;
    _progress = 0.0;
    // Don't clear logs, append new session
    _addLog('--- Starting Watchlist Analysis ---');
    notifyListeners();

    final symbols = watchlist.watchlist.map((s) => s.symbol).toList();
    if (symbols.isEmpty) {
      _addLog('Watchlist is empty.');
      _isRunning = false;
      notifyListeners();
      return;
    }

    _addLog('Analyzing ${symbols.length} stocks...');
    await _processBatch(symbols, ai, portfolio);

    _isRunning = false;
    _progress = 1.0;
    _addLog('Watchlist Analysis Completed.');
    notifyListeners();
  }

  Future<void> analyzePortfolio(AIProvider ai, PortfolioProvider portfolio, WatchlistProvider watchlist, {bool force = false}) async {
    if (_isRunning) return;
    
    if (!force) {
      String? lastScan;
      if (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows) {
        final prefs = await SharedPreferences.getInstance();
        lastScan = prefs.getString('last_scan_date');
      } else {
        lastScan = await _firestoreService.loadLastScanDate();
      }
      
      final today = DateTime.now().toString().split(' ')[0];
      if (lastScan == today) {
        return;
      }
    }

    _isRunning = true;
    _progress = 0.0;
    _addLog('--- Starting Portfolio Analysis ---');
    notifyListeners();

    final symbols = portfolio.positions.map((p) => p.symbol).toList();
    if (symbols.isEmpty) {
      _addLog('Portfolio is empty.');
      _isRunning = false;
      notifyListeners();
      return;
    }

    _addLog('Analyzing ${symbols.length} positions...');
    await _processBatch(symbols, ai, portfolio);

    _isRunning = false;
    _progress = 1.0;
    _addLog('Portfolio Analysis Completed.');
    notifyListeners();
  }

  Future<void> _processBatch(List<String> symbols, AIProvider ai, PortfolioProvider portfolio) async {
    int completed = 0;
    final total = symbols.length;

    for (final symbol in symbols) {
      if (!_isRunning) break; // Allow cancellation

      _addLog('╔════════════════════════════════════════════╗');
      _addLog('║ 📊 Analyzing $symbol');
      _addLog('╚════════════════════════════════════════════╝');
      
      try {
        // Fetch OHLC data for indicator calculation
        final ohlcJson = await _yahooService.getOHLCData(symbol, timeframe: '1d');
        if (ohlcJson.isEmpty) {
          _addLog('❌ No data available for $symbol');
          completed++;
          _progress = completed / total;
          notifyListeners();
          continue;
        }

        final ohlcData = ohlcJson.map((json) => OHLCData.fromJson(json)).toList();
        if (ohlcData.length < 50) {
          _addLog('❌ Insufficient data for analysis (need at least 50 candles)');
          completed++;
          _progress = completed / total;
          notifyListeners();
          continue;
        }
        
        final currentPrice = ohlcData.last.close;
        final currencySymbol = CurrencyHelper.getCurrencySymbol(symbol);
        
        _addLog('💰 Current Price: $currencySymbol${currentPrice.toStringAsFixed(2)}');
        _addLog('');
        
        // Calculate all indicators
        _addLog('📈 Technical Indicators:');
        final indicatorContext = await _calculateIndicators(ohlcData, symbol);
        
        // Log indicator values
        for (final line in indicatorContext['logs']) {
          _addLog('  $line');
        }
        _addLog('');
        
        // Pass to AI with indicator context
        final signal = await ai.analyzeStockWithIndicators(
          symbol, 
          indicatorContext['data'],
        );
        
        if (signal != null) {
          _addLog('🤖 AI Analysis:');
          _addLog('  Signal: ${signal.signal}');
          _addLog('  Confidence: ${(signal.confidence * 100).toStringAsFixed(0)}%');
          if (signal.reasoning != null && signal.reasoning!.isNotEmpty) {
            _addLog('  Reasoning:');
            for (final line in signal.reasoning!.split('\n')) {
              if (line.trim().isNotEmpty) {
                _addLog('    $line');
              }
            }
          }
          _addLog('');

          if (signal.signal == 'BUY' || signal.signal == 'SELL') {
            if (signal.confidence > 0.7) {
              _addLog('⚖️ Decision: Execute ${signal.signal} order');
              await _executeAutoTrade(symbol, signal, portfolio);
            } else {
              _addLog('⚠️ Decision: Skip trade (low confidence)');
            }
          } else {
            _addLog('⚖️ Decision: ${signal.signal}');
          }
        } else {
          _addLog('❌ Analysis failed (No signal generated)');
        }
      } catch (e) {
        _addLog('❌ Error: $e');
      }

      _addLog('─────────────────────────────────────────────\n');
      
      completed++;
      _progress = completed / total;
      notifyListeners();
      
      // Delay to avoid rate limits
      await Future.delayed(const Duration(seconds: 2)); 
    }
  }

  Future<Map<String, dynamic>> _calculateIndicators(List<OHLCData> ohlcData, String symbol) async {
    final logs = <String>[];
    final data = <String, dynamic>{};
    final currencySymbol = CurrencyHelper.getCurrencySymbol(symbol);

    // PSAR
    try {
      final psarResult = StrategyEngine.calculatePSAR(ohlcData);
      final currentPSAR = psarResult.indicatorLine.last;
      final currentPrice = ohlcData.last.close;
      final isBullish = currentPrice > currentPSAR;
      
      logs.add('• PSAR: $currencySymbol${currentPSAR.toStringAsFixed(2)} ${isBullish ? "📈 (Bullish)" : "📉 (Bearish)"}');
      if (isBullish) {
        logs.add('  └─ Price above PSAR - Uptrend confirmed');
        logs.add('  └─ Stop Loss: $currencySymbol${currentPSAR.toStringAsFixed(2)}');
      } else {
        logs.add('  └─ Price below PSAR - Downtrend');
      }
      
      data['psar'] = {
        'value': currentPSAR,
        'signal': isBullish ? 'BUY' : 'SELL',
        'isBullish': isBullish,
      };
      
      // Check for PSAR signals
      final signals = psarResult.signals;
      if (signals.isNotEmpty) {
        final latestSignal = signals.last;
        if (latestSignal.index >= ohlcData.length - 5) { // Recent signal
          logs.add('  └─ ${latestSignal.type == SignalType.buy ? "✓" : "✗"} ${latestSignal.type == SignalType.buy ? "BUY" : "SELL"} signal detected');
        }
      }
    } catch (e) {
      logs.add('• PSAR: Error calculating');
    }

    // RSI
    try {
      final rsiResult = StrategyEngine.calculateRSI(ohlcData);
      final currentRSI = rsiResult.indicatorLine.last;
      String interpretation = '';
      if (currentRSI > 70) {
        interpretation = '🔴 Overbought';
      } else if (currentRSI < 30) {
        interpretation = '🟢 Oversold';
      } else if (currentRSI > 50) {
        interpretation = '🟡 Bullish momentum';
      } else {
        interpretation = '🟡 Bearish momentum';
      }
      
      logs.add('• RSI (14): ${currentRSI.toStringAsFixed(1)} - $interpretation');
      
      data['rsi'] = {
        'value': currentRSI,
        'signal': currentRSI < 30 ? 'BUY' : (currentRSI > 70 ? 'SELL' : 'NEUTRAL'),
        'overbought': currentRSI > 70,
        'oversold': currentRSI < 30,
      };
    } catch (e) {
      logs.add('• RSI: Error calculating');
    }

    // MACD
    try {
      final macdResult = StrategyEngine.calculateMACD(ohlcData);
      final macdLine = macdResult.indicatorLine.last;
      final signalLine = macdResult.secondaryLine!.last;
      
      if (!macdLine.isNaN && !signalLine.isNaN) {
        final histogram = macdLine - signalLine;
        final isBullish = histogram > 0;
        
        logs.add('• MACD (12,26,9):');
        logs.add('  └─ MACD Line: ${macdLine.toStringAsFixed(2)}');
        logs.add('  └─ Signal Line: ${signalLine.toStringAsFixed(2)}');
        logs.add('  └─ Histogram: ${histogram > 0 ? "+" : ""}${histogram.toStringAsFixed(2)} ${isBullish ? "📈" : "📉"}');
        logs.add('  └─ ${isBullish ? "Bullish crossover" : "Bearish crossover"}');
        
        data['macd'] = {
          'histogram': histogram,
          'signal': isBullish ? 'BUY' : 'SELL',
          'isBullish': isBullish,
        };
      } else {
        logs.add('• MACD: Calculation returned NaN (need 26+ candles with valid data)');
        logs.add('  └─ MACD Line: ${macdLine.isNaN ? "NaN" : macdLine.toStringAsFixed(2)}');
        logs.add('  └─ Signal Line: ${signalLine.isNaN ? "NaN" : signalLine.toStringAsFixed(2)}');
      }
    } catch (e) {
      logs.add('• MACD: Error calculating - $e');
    }

    // Bollinger Bands
    try {
      final bbResult = StrategyEngine.calculateBollingerBands(ohlcData);
      final upperBand = bbResult.indicatorLine.last;
      final lowerBand = bbResult.secondaryLine!.last;
      final middleBand = (upperBand + lowerBand) / 2;
      final currentPrice = ohlcData.last.close;
      
      String position = '';
      if (currentPrice > upperBand) {
        position = 'Above upper band (Overbought)';
      } else if (currentPrice < lowerBand) {
        position = 'Below lower band (Oversold)';
      } else if (currentPrice > middleBand) {
        position = 'Above middle (Bullish)';
      } else {
        position = 'Below middle (Bearish)';
      }
      
      logs.add('• Bollinger Bands:');
      logs.add('  └─ Upper: $currencySymbol${upperBand.toStringAsFixed(2)}');
      logs.add('  └─ Middle: $currencySymbol${middleBand.toStringAsFixed(2)}');
      logs.add('  └─ Lower: $currencySymbol${lowerBand.toStringAsFixed(2)}');
      logs.add('  └─ Position: $position');
      
      data['bollingerBands'] = {
        'upper': upperBand,
      'middle': middleBand,
      'lower': lowerBand,
      'position': position,
    };
  } catch (e) {
    logs.add('• Bollinger Bands: Error calculating');
  }

  // SMA (50-day)
  try {
    final smaResult = StrategyEngine.calculateSMA(ohlcData, period: 50);
    final currentSMA = smaResult.indicatorLine.last;
    final currentPrice = ohlcData.last.close;
    final isBullish = currentPrice > currentSMA;
    
    logs.add('• SMA (50): $currencySymbol${currentSMA.toStringAsFixed(2)} ${isBullish ? "📈 (Bullish)" : "📉 (Bearish)"}');
    logs.add('  └─ Price ${isBullish ? "above" : "below"} 50-day MA - ${isBullish ? "Uptrend" : "Downtrend"}');
    
    data['sma'] = {
      'value': currentSMA,
      'signal': isBullish ? 'BUY' : 'SELL',
      'isBullish': isBullish,
    };
  } catch (e) {
    logs.add('• SMA (50): Error calculating');
  }

  return {
    'logs': logs,
    'data': data,
  };
  }

  Future<void> _executeAutoTrade(String symbol, AISignal signal, PortfolioProvider portfolio) async {
    double currentPrice = portfolio.currentPrices[symbol] ?? 0.0;
    
    if (currentPrice == 0.0) {
      _addLog('Price not found for $symbol. Fetching...');
      currentPrice = await portfolio.fetchPrice(symbol);
    }

    if (currentPrice == 0.0) {
      _addLog('Skipping trade: Price not available for $symbol.');
      return;
    }

    _addLog('Executing ${signal.signal} order for $symbol...');
    try {
      await portfolio.placeAutomatedOrder(symbol, signal.signal, currentPrice);
      _addLog('Trade executed successfully!');
    } catch (e) {
      _addLog('Trade failed: $e');
    }
  }

  // Call this when user logs in
  Future<void> reloadData() async {
    await _loadLogs();
  }

  // Cancel ongoing analysis
  void cancelAnalysis() {
    if (_isRunning) {
      _isRunning = false;
      _addLog('⚠️ Analysis cancelled by user');
      notifyListeners();
    }
  }

  // Bulk analysis from CSV
  Future<void> analyzeBulkSymbols({
    required List<String> symbols,
    required AIProvider ai,
    required PortfolioProvider portfolio,
    required WatchlistProvider watchlist,
  }) async {
    if (_isRunning) return;
    
    _isRunning = true;
    _progress = 0.0;
    _addLog('═══════════════════════════════════════════════');
    _addLog('📊 BULK ANALYSIS STARTED');
    _addLog('   ${symbols.length} symbols to analyze');
    _addLog('   Rate limited: 3-4 seconds between calls');
    _addLog('═══════════════════════════════════════════════');
    notifyListeners();

    int completed = 0;
    int matched = 0;
    int traded = 0;
    int failed = 0;

    for (final symbol in symbols) {
      if (!_isRunning) {
        _addLog('Analysis stopped.');
        break;
      }

      _addLog('');
      _addLog('╔════════════════════════════════════════════╗');
      _addLog('║ 📊 Analyzing $symbol (${completed + 1}/${symbols.length})');
      _addLog('╚════════════════════════════════════════════╝');

      try {
        // Fetch OHLC data for indicator calculation
        final ohlcJson = await _yahooService.getOHLCData(symbol, timeframe: '1d');
        if (ohlcJson.isEmpty) {
          _addLog('❌ No data available for $symbol');
          failed++;
          completed++;
          _progress = completed / symbols.length;
          notifyListeners();
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }

        final ohlcData = ohlcJson.map((json) => OHLCData.fromJson(json)).toList();
        if (ohlcData.length < 50) {
          _addLog('❌ Insufficient data for analysis (need at least 50 candles)');
          failed++;
          completed++;
          _progress = completed / symbols.length;
          notifyListeners();
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }

        final currentPrice = ohlcData.last.close;
        final currencySymbol = CurrencyHelper.getCurrencySymbol(symbol);

        _addLog('💰 Current Price: $currencySymbol${currentPrice.toStringAsFixed(2)}');

        // Calculate all indicators
        final indicatorContext = await _calculateIndicators(ohlcData, symbol);

        final indicatorLogs = indicatorContext['logs'] as List<String>? ?? [];
        for (final log in indicatorLogs) {
          _addLog(log);
        }

        
        _addLog('');
        _addLog('🤖 Consulting AI with Trading System...');
        final signal = await ai.analyzeStockWithIndicators(
          symbol,
          indicatorContext['data'],
        );

        if (signal != null) {
          _addLog('🤖 AI Signal: ${signal.signal} (${(signal.confidence * 100).toInt()}%)');

          // Check if it matches trading system criteria
          if (signal.signal == 'BUY' && signal.confidence > 0.6) {
            matched++;
            
            // Add to watchlist
            _addLog('✓ Adding $symbol to watchlist');
            await watchlist.addToWatchlist(symbol);

            // Execute trade if high confidence
            if (signal.confidence > 0.7) {
              _addLog('✓ Executing BUY trade for $symbol');
              await _executeAutoTrade(symbol, signal, portfolio);
              traded++;
            }
          } else if (signal.signal == 'SELL') {
            _addLog('📉 SELL signal - checking positions...');
            final hasPosition = portfolio.positions.any((p) => p.symbol == symbol);
            if (hasPosition && signal.confidence > 0.7) {
              await _executeAutoTrade(symbol, signal, portfolio);
              traded++;
            }
          } else {
            _addLog('⚖️ HOLD signal or low confidence - skipping');
          }
        } else {
          _addLog('❌ No signal generated');
          failed++;
        }

      } catch (e) {
        _addLog('❌ Error: $e');
        failed++;
      }

      completed++;
      _progress = completed / symbols.length;
      notifyListeners();

      // Rate limiting: wait 3-4 seconds between API calls
      if (_isRunning && completed < symbols.length) {
        _addLog('⏳ Rate limit delay (3s)...');
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    // Summary
    _addLog('');
    _addLog('═══════════════════════════════════════════════');
    _addLog('📊 BULK ANALYSIS COMPLETE');
    _addLog('   Total: ${symbols.length}');
    _addLog('   Matched: $matched');
    _addLog('   Traded: $traded');
    _addLog('   Failed: $failed');
    _addLog('═══════════════════════════════════════════════');

    _isRunning = false;
    _progress = 1.0;
    notifyListeners();
  }
}

