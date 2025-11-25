import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  final String apiKey;
  String model;

  OpenRouterService(this.apiKey, {this.model = 'z-ai/glm-4.5-air:free'});

  // Popular OpenRouter models
  static final List<Map<String, String>> popularModels = [
    {'id': 'z-ai/glm-4.5-air:free', 'name': 'GLM-4.5 Air (Free)'},
    {'id': 'meta-llama/llama-3.1-70b-instruct:free', 'name': 'Llama 3.1 70B (Free)'},
    {'id': 'google/gemini-flash-1.5', 'name': 'Gemini Flash 1.5'},
    {'id': 'anthropic/claude-3.5-sonnet', 'name': 'Claude 3.5 Sonnet'},
    {'id': 'openai/gpt-4o', 'name': 'GPT-4o'},
    {'id': 'openai/gpt-4o-mini', 'name': 'GPT-4o Mini'},
    {'id': 'anthropic/claude-3-haiku', 'name': 'Claude 3 Haiku'},
    {'id': 'google/gemini-pro-1.5', 'name': 'Gemini Pro 1.5'},
    {'id': 'mistralai/mistral-large', 'name': 'Mistral Large'},
    {'id': 'tngtech/deepseek-r1t2-chimera:free', 'name': 'DeepSeek R1T2 Chimera (free)'},
    {'id': 'x-ai/grok-4.1-fast:free', 'name': 'xAI: Grok 4.1 Fast (Free)'},
    {'id': 'kwaipilot/kat-coder-pro:free', 'name': 'Kwaipilot: KAT-Coder-Pro V1 (free)'},
    {'id': 'openai/gpt-oss-20b:free', 'name': 'OpenAI: gpt-oss-20b (free)'},
    {'id': 'microsoft/mai-ds-r1:free', 'name': 'Microsoft: MAI DS R1 (free)'},
    {'id': 'cognitivecomputations/dolphin-mistral-24b-venice-edition:free', 'name': 'Venice: Uncensored (free)'},
    {'id': 'arliai/qwq-32b-arliai-rpr-v1:free', 'name': 'ArliAI: QwQ 32B RpR v1 (free)'}
  ];

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

  Future<String> generateTradingSystem({String? userPreferences}) async {
    String prompt = '''
    Generate a robust algorithmic trading system description based on technical analysis.
    Include:
    1. Strategy Name
    2. Key Indicators (e.g., RSI, MACD, Bollinger Bands)
    3. Entry Rules
    4. Exit Rules
    5. Risk Management
    
    Keep it concise and actionable.
    ''';
    
    if (userPreferences != null && userPreferences.isNotEmpty) {
      prompt += '\n\nUser Preferences/Requirements:\n$userPreferences\n\nIncorporate these preferences into the trading system.';
    }
    
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
          'model': model,
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
