import 'package:flutter/material.dart';
import '../../data/services/yahoo_finance_service.dart';
import '../../data/models/ohlc_data.dart';
import '../../data/models/trading_strategy.dart';
import '../services/strategy_engine.dart';

class StrategyProvider with ChangeNotifier {
  final YahooFinanceService _yahooService = YahooFinanceService();
  
  String _symbol = '';
  TradingStrategy? _selectedStrategy;
  String _timeframe = '1d';
 bool _isLoading = false;
  String? _errorMessage;
  int _maPeriod = 50; // Default 50-day MA
  
  List<OHLCData> _chartData = [];
  StrategyResult? _strategyResult;

  // Getters
  String get symbol => _symbol;
  TradingStrategy? get selectedStrategy => _selectedStrategy;
  String get timeframe => _timeframe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _chartData.isNotEmpty;
  List<OHLCData> get chartData => _chartData;
  StrategyResult? get strategyResult => _strategyResult;
  int get maPeriod => _maPeriod;

  // Setters
  void setSymbol(String value) {
    _symbol = value.toUpperCase();
    notifyListeners();
  }

  void setSelectedStrategy(TradingStrategy strategy) {
    _selectedStrategy = strategy;
    notifyListeners();
    
    // Auto-apply if we have data
    if (_chartData.isNotEmpty) {
      _applyStrategy();
    }
  }

  void setTimeframe(String value) {
    _timeframe = value;
    notifyListeners();
  }

  void setMAPeriod(int period) {
    _maPeriod = period;
    notifyListeners();
    
    // Re-apply strategy if SMA is selected
    if (_selectedStrategy?.id == 'sma' && _chartData.isNotEmpty) {
      _applyStrategy();
    }
  }

  Future<void> applyStrategy({required TradingStrategy strategy}) async {
    if (_symbol.isEmpty) {
      _errorMessage = 'Please enter a stock symbol';
      notifyListeners();
      return;
    }

    _selectedStrategy = strategy;
    _isLoading = true;
    _errorMessage = null;
    _strategyResult = null;
    notifyListeners();

    try {
      // 1. Fetch Stock Data
      final rawData = await _yahooService.getOHLCData(_symbol, timeframe: _timeframe);
      if (rawData.isEmpty) {
        throw Exception('No data found for $_symbol');
      }
      
      _chartData = rawData.map((json) => OHLCData.fromJson(json)).toList();

      // 2. Apply Strategy
      _applyStrategy();

    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyStrategy() {
    if (_selectedStrategy == null || _chartData.isEmpty) return;

    switch (_selectedStrategy!.id) {
      case 'psar':
        _strategyResult = StrategyEngine.calculatePSAR(_chartData);
        break;
      case 'rsi':
        _strategyResult = StrategyEngine.calculateRSI(_chartData);
        break;
      case 'macd':
        _strategyResult = StrategyEngine.calculateMACD(_chartData);
        break;
      case 'bollinger':
        _strategyResult = StrategyEngine.calculateBollingerBands(_chartData);
        break;
      case 'sma':
        _strategyResult = StrategyEngine.calculateSMA(_chartData, period: _maPeriod);
        break;
    }
    notifyListeners();
  }
  
  void clear() {
    _symbol = '';
    _selectedStrategy = null;
    _chartData = [];
    _strategyResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}

