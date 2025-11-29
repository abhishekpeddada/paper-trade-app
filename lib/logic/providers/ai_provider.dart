import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/openrouter_service.dart';
import '../../data/services/yahoo_finance_service.dart';
import '../../data/models/ai_signal.dart';
import '../../data/models/trade_models.dart';
import '../../core/services/firestore_service.dart';
import 'portfolio_provider.dart';

class AIProvider extends ChangeNotifier {
  OpenRouterService _aiService;
  final YahooFinanceService _financeService = YahooFinanceService();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _apiKey;
  String _selectedModel;
  bool _isAnalyzing = false;
  AISignal? _lastSignal;
  String? _error;
  final List<Map<String, dynamic>> _activityLog = [];
  String _tradingSystem = '# Trading System\n\nNo trading system generated yet.\n\nClick "Generate New System" to create one.';

  bool get isAnalyzing => _isAnalyzing;
  AISignal? get lastSignal => _lastSignal;
  String? get error => _error;
  String get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  List<Map<String, dynamic>> get activityLog => _activityLog;
  String get tradingSystem => _tradingSystem;

  AIProvider({required String apiKey, String? model})
      : _apiKey = apiKey,
        _selectedModel = model ?? 'z-ai/glm-4.5-air:free',
        _aiService = OpenRouterService(apiKey, model: model ?? 'z-ai/glm-4.5-air:free') {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('ai_api_key') ?? _apiKey;
    _selectedModel = prefs.getString('ai_model') ?? _selectedModel;
    
    // Load trading system from Firebase first, fallback to local
    if (defaultTargetPlatform != TargetPlatform.linux && defaultTargetPlatform != TargetPlatform.windows) {
      final firebaseSystem = await _firestoreService.loadTradingSystem();
      if (firebaseSystem != null) {
        _tradingSystem = firebaseSystem;
      } else {
        _tradingSystem = prefs.getString('ai_trading_system') ?? _tradingSystem;
      }
    } else {
      _tradingSystem = prefs.getString('ai_trading_system') ?? _tradingSystem;
    }
    
    // AI logs remain local-only (not synced to Firebase)
    final logsJson = prefs.getString('ai_activity_log');
    if (logsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _activityLog.clear();
        _activityLog.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      } catch (e) {
        debugPrint('Error loading logs: $e');
      }
    }
    
    _aiService = OpenRouterService(_apiKey, model: _selectedModel);
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save trading system to both local and Firebase
    await prefs.setString('ai_trading_system', _tradingSystem);
    if (defaultTargetPlatform != TargetPlatform.linux && defaultTargetPlatform != TargetPlatform.windows) {
      await _firestoreService.saveTradingSystem(_tradingSystem);
    }
    
    // AI logs stay local-only (not synced to Firebase)
    // Convert DateTime objects to strings for JSON serialization
    final logsToSave = _activityLog.map((log) {
      final Map<String, dynamic> copy = Map.from(log);
      if (copy['timestamp'] is DateTime) {
        copy['timestamp'] = (copy['timestamp'] as DateTime).toIso8601String();
      }
      return copy;
    }).toList();
    
    await prefs.setString('ai_activity_log', jsonEncode(logsToSave));
  }

  Future<void> setApiKey(String newApiKey) async {
    _apiKey = newApiKey;
    _aiService = OpenRouterService(_apiKey, model: _selectedModel);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', _apiKey);
    notifyListeners();
  }

  Future<void> setModel(String modelId) async {
    _selectedModel = modelId;
    _aiService = OpenRouterService(_apiKey, model: _selectedModel);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_model', _selectedModel);
    notifyListeners();
  }

  void clearLogs() {
    _activityLog.clear();
    _saveState();
    notifyListeners();
  }

  Future<AISignal?> analyzeStock(String symbol) async {
    _isAnalyzing = true;
    _error = null;
    _lastSignal = null;
    notifyListeners();

    try {
      // Get historical data
      final history = await _financeService.getHistoricalData(symbol, days: 30);
      
      if (history.isEmpty) {
        throw Exception('No historical data available');
      }

      // Call AI for analysis
      final response = await _aiService.analyzeMarket(symbol, history);
      _lastSignal = AISignal.fromString(response);
      
      _addToLog('Analyzed $symbol', _lastSignal!.signal);
      
      return _lastSignal;
    } catch (e) {
      _error = e.toString();
      _addToLog('Analysis failed for $symbol', 'ERROR');
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<AISignal?> analyzeStockWithIndicators(String symbol, Map<String, dynamic> indicators) async {
    _isAnalyzing = true;
    _error = null;
    _lastSignal = null;
    notifyListeners();

    try {
      // Get historical data
      final history = await _financeService.getHistoricalData(symbol, days: 30);
      
      if (history.isEmpty) {
        throw Exception('No historical data available');
      }

      // Call AI for analysis with indicators and trading system
      final response = await _aiService.analyzeMarketWithIndicators(
        symbol, 
        history, 
        indicators,
        tradingSystem: _tradingSystem, // Pass user's trading system
      );
      _lastSignal = AISignal.fromString(response);
      
      _addToLog('Analyzed $symbol with indicators', _lastSignal!.signal);
      
      return _lastSignal;
    } catch (e) {
      _error = e.toString();
      _addToLog('Analysis failed for $symbol', 'ERROR');
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> analyzeAndTrade(String symbol, double currentPrice, {PortfolioProvider? portfolio}) async {
    final signal = await analyzeStock(symbol);
    
    if (signal != null && portfolio != null) {
      try {
        if (signal.signal == 'BUY' && signal.confidence > 0.6) {
          // Calculate quantity based on risk (e.g., $1000 worth or 1% of balance)
          final investAmount = portfolio.balance * 0.01; // 1% of balance
          final quantity = (investAmount / currentPrice).floorToDouble();
          
          if (quantity >= 1) {
            await portfolio.executeOrder(symbol, quantity, currentPrice, OrderType.buy);
            _addToLog('Auto-bought $quantity shares of $symbol at \$${currentPrice.toStringAsFixed(2)}', 'BUY');
          }
        } else if (signal.signal == 'SELL' && signal.confidence > 0.6) {
          final quantity = portfolio.getQuantity(symbol);
          if (quantity > 0) {
            await portfolio.executeOrder(symbol, quantity, currentPrice, OrderType.sell);
            _addToLog('Auto-sold $quantity shares of $symbol at \$${currentPrice.toStringAsFixed(2)}', 'SELL');
          }
        }
      } catch (e) {
        _addToLog('Trade execution failed for $symbol: $e', 'ERROR');
      }
    }
  }

  void _addToLog(String action, String result) {
    _activityLog.insert(0, {
      'timestamp': DateTime.now().toIso8601String(), // Store as string directly
      'action': action,
      'result': result,
    });
    // Keep only last 50 entries
    if (_activityLog.length > 50) {
      _activityLog.removeLast();
    }
    _saveState();
  }

  Future<void> generateSystem({String? userPreferences}) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final response = await _aiService.generateTradingSystem(userPreferences: userPreferences);
      _tradingSystem = response;
      _addToLog('Generated new trading system${userPreferences?.isNotEmpty == true ? ' with preferences' : ''}', 'SUCCESS');
    } catch (e) {
      _error = e.toString();
      _addToLog('Failed to generate trading system', 'ERROR');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
  
  void clearSignal() {
    _lastSignal = null;
    _error = null;
    notifyListeners();
  }

  void clearTradingSystem() {
    _tradingSystem = '# Trading System\n\nNo trading system generated yet.\n\nClick "Generate New System" to create one.';
    _saveState();
    notifyListeners();
  }
}
