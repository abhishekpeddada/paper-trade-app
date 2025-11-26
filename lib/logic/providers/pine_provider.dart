import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/pine_conversion_model.dart';
import '../../data/models/ohlc_data.dart';
import '../../data/repositories/pine_repository.dart';
import '../../data/services/openrouter_service.dart';
import '../indicator_engine.dart';

class PineScriptProvider with ChangeNotifier {
  PineScriptRepository _repository;

  PineScriptProvider(this._repository) {
    _loadSettings();
  }

  // State
  bool _isLoading = false;
  bool _apiKeyLoaded = false;
  String _symbol = '';
  String _pineScriptCode = '';
  String _timeframe = '1m';
  PineScriptConversion? _conversion;
  List<OHLCData> _chartData = [];
  List<double> _indicatorValues = [];
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get apiKeyLoaded => _apiKeyLoaded;
  String get symbol => _symbol;
  String get pineScriptCode => _pineScriptCode;
  String get timeframe => _timeframe;
  PineScriptConversion? get conversion => _conversion;
  List<OHLCData> get chartData => _chartData;
  List<double> get indicatorValues => _indicatorValues;
  String? get errorMessage => _errorMessage;
  bool get hasData => _chartData.isNotEmpty;
  bool get hasConversion => _conversion != null && _conversion!.isSuccess;

  /// Load API key from SharedPreferences (same as AIProvider)
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('ai_api_key');
      final model = prefs.getString('ai_model') ?? 'z-ai/glm-4.5-air:free';
      
      print('🔑 PineScript Provider: Loading API key...');
      print('🔑 API Key found: ${apiKey != null && apiKey.isNotEmpty ? "YES (${apiKey.substring(0, 10)}...)" : "NO"}');
      
      if (apiKey != null && apiKey.isNotEmpty) {
        // Recreate repository with the stored API key
        final openRouterService = OpenRouterService(apiKey, model: model);
        final yahooFinanceService = _repository.yahooFinanceService;
        _repository = PineScriptRepository(openRouterService, yahooFinanceService);
        _apiKeyLoaded = true;
        print('✅ PineScript Provider: API key loaded successfully');
        notifyListeners();
      } else {
        print('❌ PineScript Provider: No API key found in SharedPreferences');
        _errorMessage = 'API key not configured. Please set it in Account screen.';
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading PineScript provider settings: $e');
      _errorMessage = 'Error loading API settings: $e';
      notifyListeners();
    }
  }

  // Setters
  void setSymbol(String value) {
    _symbol = value.toUpperCase();
    notifyListeners();
  }

  void setPineScriptCode(String value) {
    _pineScriptCode = value;
    notifyListeners();
  }

  void setTimeframe(String value) {
    _timeframe = value;
    notifyListeners();
  }

  /// Convert PineScript and fetch chart data
  Future<void> convertAndPlot({Map<String, dynamic>? indicatorParams}) async {
    if (_symbol.isEmpty || _pineScriptCode.isEmpty) {
      _errorMessage = 'Please enter both symbol and PineScript code';
      notifyListeners();
      return;
    }

    // Check if API key is loaded
    if (!_apiKeyLoaded) {
      _errorMessage = 'API key not loaded. Please configure it in Account screen and restart the app.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Convert PineScript to Dart
      _conversion = await _repository.convertPineScript(_pineScriptCode, _symbol);
      
      if (!_conversion!.isSuccess) {
        _errorMessage = _conversion!.errorMessage ?? 'Conversion failed';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2: Fetch chart data
      _chartData = await _repository.getChartData(_symbol, timeframe: _timeframe);
      
      if (_chartData.isEmpty) {
        _errorMessage = 'No chart data available for $_symbol';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 3: Calculate indicator values
      final closePrices = _chartData.map((d) => d.close).toList();
      _indicatorValues = IndicatorEngine.executeIndicator(
        _conversion!.convertedDartCode,
        closePrices,
        parameters: indicatorParams,
      ) ?? [];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh chart data with new timeframe
  Future<void> refreshChartData() async {
    if (_symbol.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _chartData = await _repository.getChartData(_symbol, timeframe: _timeframe);
      
      if (_chartData.isNotEmpty && _conversion != null && _conversion!.isSuccess) {
        final closePrices = _chartData.map((d) => d.close).toList();
        _indicatorValues = IndicatorEngine.executeIndicator(
          _conversion!.convertedDartCode,
          closePrices,
        ) ?? [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error refreshing data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clear() {
    _symbol = '';
    _pineScriptCode = '';
    _conversion = null;
    _chartData = [];
    _indicatorValues = [];
    _errorMessage = null;
    notifyListeners();
  }
}
