import 'dart:convert';
import '../services/openrouter_service.dart';
import '../services/yahoo_finance_service.dart';

class AiRepository {
  final YahooFinanceService _yahooService = YahooFinanceService();
  OpenRouterService? _aiService;

  void setApiKey(String key, {String model = 'z-ai/glm-4.5-air:free'}) {
    _aiService = OpenRouterService(key, model: model);
  }

  bool get hasKey => _aiService != null;

  Future<Map<String, dynamic>> analyzeStock(String symbol) async {
    if (_aiService == null) throw Exception('API Key not set');

    try {
      // 1. Get Data
      print('🤖 Fetching historical data for $symbol...');
      final history = await _yahooService.getHistoricalData(symbol);
      if (history.isEmpty) {
        print('❌ No historical data for $symbol');
        throw Exception('No data found for $symbol');
      }
      print('✅ Got ${history.length} data points');

      // 2. Call AI
      print('🤖 Calling AI for analysis...');
      final response = await _aiService!.analyzeMarket(symbol, history);
      print('✅ Got AI response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');

      // 3. Parse JSON from response (handling potential markdown wrapping)
      try {
        String jsonStr = response.trim();
        
        // Remove markdown code blocks if present
        if (jsonStr.contains('```json')) {
          final parts = jsonStr.split('```json');
          if (parts.length > 1) {
            jsonStr = parts[1].split('```')[0].trim();
          }
        } else if (jsonStr.contains('```')) {
          final parts = jsonStr.split('```');
          if (parts.length > 1) {
            jsonStr = parts[1].split('```')[0].trim();
          }
        }
        
        print('🤖 Parsing JSON: $jsonStr');
        final parsed = json.decode(jsonStr) as Map<String, dynamic>;
        
        // Validate required fields
        if (!parsed.containsKey('signal')) {
          print('❌ Missing signal field in response');
          throw Exception('Invalid response format: missing signal');
        }
        
        print('✅ Successfully parsed AI response');
        return parsed;
      } catch (e) {
        print('❌ Failed to parse JSON: $e');
        print('Raw response: $response');
        // Fallback with more info
        return {
          'signal': 'HOLD',
          'confidence': 0.0,
          'reasoning': 'Failed to parse AI response. Error: $e. Please check AI Desk logs.',
        };
      }
    } catch (e) {
      print('❌ Error in analyzeStock: $e');
      rethrow;
    }
  }

  Future<String> getTradingSystem({String? userPreferences}) async {
    if (_aiService == null) throw Exception('API Key not set');
    return await _aiService!.generateTradingSystem(userPreferences: userPreferences);
  }
}
