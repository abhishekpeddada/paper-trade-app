import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  final String apiKey;

  OpenRouterService(this.apiKey);

  Future<String> analyzeMarket(String symbol, List<Map<String, dynamic>> history) async {
    // Limit history to last 30 days to save tokens
    final recentHistory = history.length > 30 ? history.sublist(history.length - 30) : history;
    
    final prompt = '''
    Analyze the following stock data for $symbol and provide a trading signal.
    Data (last 30 days): ${json.encode(recentHistory)}
    
    Output format: JSON with fields:
    - signal: "BUY", "SELL", or "HOLD"
    - confidence: 0.0 to 1.0
    - reasoning: Short explanation (max 2 sentences)
    - stopLoss: Suggested stop loss price
    - takeProfit: Suggested take profit price
    ''';

    return _callAI(prompt);
  }

  Future<String> generateTradingSystem() async {
    const prompt = '''
    Generate a robust algorithmic trading system description based on technical analysis.
    Include:
    1. Strategy Name
    2. Key Indicators (e.g., RSI, MACD, Bollinger Bands)
    3. Entry Rules
    4. Exit Rules
    5. Risk Management
    
    Keep it concise and actionable.
    ''';
    
    return _callAI(prompt);
  }

  Future<String> _callAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Gemini-Antigravity', 
          'X-Title': 'Paper Trade App',
        },
        body: json.encode({
          'model': 'z-ai/glm-4.5-air:free', // Using a free model for now
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to call AI: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('AI Service Error: $e');
    }
  }
}
