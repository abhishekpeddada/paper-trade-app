import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider.dart';
import 'portfolio_provider.dart';
import 'watchlist_provider.dart';
import '../../data/models/ai_signal.dart';
import '../../core/utils/currency_helper.dart';

class AutoTradingProvider extends ChangeNotifier {
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
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getStringList('auto_trading_logs');
    if (savedLogs != null) {
      _logs = savedLogs;
      notifyListeners();
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('auto_trading_logs', _logs);
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split('.')[0].split(' ')[1];
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > 100) _logs.removeLast(); // Limit logs
    _saveLogs();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _saveLogs();
    notifyListeners();
  }

  Future<void> runDailyScan(AIProvider ai, PortfolioProvider portfolio, WatchlistProvider watchlist) async {
    final prefs = await SharedPreferences.getInstance();
    final lastScan = prefs.getString('last_scan_date');
    final today = DateTime.now().toString().split(' ')[0];

    if (lastScan == today) {
      _addLog('Daily scan already completed for today.');
      return;
    }

    _addLog('Starting Daily Portfolio Scan...');
    await analyzePortfolio(ai, portfolio, watchlist, force: true);
    
    await prefs.setString('last_scan_date', today);
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
      final prefs = await SharedPreferences.getInstance();
      final lastScan = prefs.getString('last_scan_date');
      final today = DateTime.now().toString().split(' ')[0];
      if (lastScan == today) {
        _addLog('Daily scan already completed. Use "Analyze Portfolio" to force run.');
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

      _addLog('Analyzing $symbol...');
      try {
        final signal = await ai.analyzeStock(symbol);
        
        if (signal != null) {
          _addLog('$symbol: ${signal.signal} (${(signal.confidence * 100).toStringAsFixed(0)}%)');

          if (signal.signal == 'BUY' || signal.signal == 'SELL') {
            if (signal.confidence > 0.7) { // Confidence threshold
               await _executeAutoTrade(symbol, signal, portfolio);
            } else {
              _addLog('Skipping trade: Low confidence.');
            }
          }
        } else {
          _addLog('Analysis failed for $symbol (No signal generated)');
        }
      } catch (e) {
        _addLog('Error analyzing $symbol: $e');
      }

      completed++;
      _progress = completed / total;
      notifyListeners();
      
      // Small delay to avoid rate limits
      await Future.delayed(const Duration(seconds: 2)); 
    }
  }

  Future<void> _executeAutoTrade(String symbol, AISignal signal, PortfolioProvider portfolio) async {
    final currentPrice = portfolio.currentPrices[symbol] ?? 0.0;
    if (currentPrice == 0.0) {
      _addLog('Skipping trade: Price not available.');
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
}
