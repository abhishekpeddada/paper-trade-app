import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/repositories/ai_repository.dart';
import 'portfolio_provider.dart';

class AiProvider extends ChangeNotifier {
  final AiRepository _repository = AiRepository();
  final PortfolioProvider _portfolioProvider;
  final _secureStorage = const FlutterSecureStorage();
  
  String? _apiKey;
  String _tradingSystem = "No system generated yet.";
  List<String> _activityLog = [];
  bool _isAnalyzing = false;

  String? get apiKey => _apiKey;
  String get tradingSystem => _tradingSystem;
  List<String> get activityLog => _activityLog;
  bool get isAnalyzing => _isAnalyzing;

  AiProvider(this._portfolioProvider) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = await _secureStorage.read(key: 'openrouter_api_key');
    _tradingSystem = prefs.getString('trading_system') ?? "No system generated yet.";
    _activityLog = prefs.getStringList('ai_activity_log') ?? [];
    
    if (_apiKey != null) {
      _repository.setApiKey(_apiKey!);
    }
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    _repository.setApiKey(key);
    await _secureStorage.write(key: 'openrouter_api_key', value: key);
    notifyListeners();
  }

  Future<void> generateSystem() async {
    if (_apiKey == null) return;
    
    _isAnalyzing = true;
    notifyListeners();

    // Enable wake lock to keep screen on
    try {
      await WakelockPlus.enable();
      print('🔒 Wake lock enabled');
    } catch (e) {
      print('⚠️ Failed to enable wake lock: $e');
    }

    try {
      final system = await _repository.getTradingSystem();
      _tradingSystem = system;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('trading_system', system);
      
      _log("Generated new trading system.");
    } catch (e) {
      _log("Error generating system: $e");
    } finally {
      _isAnalyzing = false;
      
      // Disable wake lock
      try {
        await WakelockPlus.disable();
        print('🔓 Wake lock disabled');
      } catch (e) {
        print('⚠️ Failed to disable wake lock: $e');
      }
      
      notifyListeners();
    }
  }

  Future<void> analyzeAndTrade(String symbol, double currentPrice) async {
    if (_apiKey == null) return;

    _isAnalyzing = true;
    notifyListeners();

    // Enable wake lock to keep screen on
    try {
      await WakelockPlus.enable();
      print('🔒 Wake lock enabled for analysis');
    } catch (e) {
      print('⚠️ Failed to enable wake lock: $e');
    }

    try {
      _log("Analyzing $symbol...");
      final result = await _repository.analyzeStock(symbol);
      
      final signal = result['signal'] as String;
      final confidence = result['confidence'];
      final reasoning = result['reasoning'];

      _log("Analysis for $symbol: $signal (Confidence: $confidence). $reasoning");

      if (confidence > 0.7) { // Threshold for action
        if (signal == 'BUY' || signal == 'SELL') {
          _log("Executing automated $signal order for $symbol");
          await _portfolioProvider.placeAutomatedOrder(symbol, signal, currentPrice);
        }
      }
    } catch (e) {
      _log("Error analyzing $symbol: $e");
    } finally {
      _isAnalyzing = false;
      
      // Disable wake lock
      try {
        await WakelockPlus.disable();
        print('🔓 Wake lock disabled after analysis');
      } catch (e) {
        print('⚠️ Failed to disable wake lock: $e');
      }
      
      notifyListeners();
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    _activityLog.insert(0, "[$timestamp] $message");
    
    // Persist log
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('ai_activity_log', _activityLog);
    });
    
    notifyListeners();
  }
  
  Future<void> clearLogs() async {
    _activityLog.clear();
     final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_activity_log');
    notifyListeners();
  }
}
