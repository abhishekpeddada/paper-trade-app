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

  Future<String> analyzeMarketWithIndicators(
    String symbol, 
    List<Map<String, dynamic>> history,
    Map<String, dynamic> indicators, {
    String? tradingSystem,
  }) async {
    // Limit history to last 30 days
    final recentHistory = history.length > 30 ? history.sublist(history.length - 30) : history;
    
    // Extract indicator values
    final psar = indicators['psar'];
    final rsi = indicators['rsi'];
    final macd = indicators['macd'];
    final bb = indicators['bollingerBands'];
    
    // Determine currency symbol
    String currencySymbol = '\$';
    if (symbol.endsWith('.NS') || symbol.endsWith('.BO')) {
      currencySymbol = '₹';
    }
    
    // Include trading system if available and not default
    String systemContext = '';
    if (tradingSystem != null && !tradingSystem.contains('No trading system generated yet')) {
      systemContext = '''

USER'S TRADING SYSTEM:
$tradingSystem

IMPORTANT: Consider the user's trading system above when making your recommendation. Align your analysis with their defined rules and preferences.
''';
    }
    
    final prompt = '''
You are an expert stock analyst. Analyze $symbol using technical indicators and provide a detailed trading recommendation.

PRICE DATA (Last 30 Days):
${json.encode(recentHistory)}

TECHNICAL INDICATORS (Current Values):

PSAR (Parabolic SAR):
- Value: $currencySymbol${psar?['value']?.toStringAsFixed(2) ?? 'N/A'}
- Signal: ${psar?['signal'] ?? 'N/A'}
- Trend: ${psar?['isBullish'] == true ? 'Bullish (price above PSAR)' : 'Bearish (price below PSAR)'}

RSI (14-period):
- Value: ${rsi?['value']?.toStringAsFixed(1) ?? 'N/A'}
- Signal: ${rsi?['signal'] ?? 'N/A'}
- Status: ${rsi?['overbought'] == true ? 'Overbought (>70)' : (rsi?['oversold'] == true ? 'Oversold (<30)' : 'Neutral')}

MACD (12,26,9):
- Histogram: ${macd?['histogram'] > 0 ? '+' : ''}${macd?['histogram']?.toStringAsFixed(2) ?? 'N/A'}
- Signal: ${macd?['signal'] ?? 'N/A'}
- Trend: ${macd?['isBullish'] == true ? 'Bullish crossover' : 'Bearish crossover'}

Bollinger Bands:
- Upper: $currencySymbol${bb?['upper']?.toStringAsFixed(2) ?? 'N/A'}
- Middle: $currencySymbol${bb?['middle']?.toStringAsFixed(2) ?? 'N/A'}
- Lower: $currencySymbol${bb?['lower']?.toStringAsFixed(2) ?? 'N/A'}
- Position: ${bb?['position'] ?? 'N/A'}
$systemContext
REQUIREMENTS:
1. Analyze ALL indicators (PSAR, RSI, MACD, Bollinger Bands)
2. Identify agreements and conflicts between signals
3. Consider overbought/oversold conditions
4. Evaluate trend strength and momentum
5. Provide DETAILED reasoning (3-5 sentences minimum)
6. Use $currencySymbol for all price references in your reasoning

Output format: JSON only, no markdown. Fields:
- signal: "BUY", "SELL", or "HOLD"
- confidence: 0.0 to 1.0 (based on indicator agreement)
- reasoning: Detailed multi-sentence explanation covering:
  * What each indicator is showing
  * How they agree or conflict
  * Why you chose this signal
  * Any warnings or caveats
- stopLoss: Suggested stop loss price (use PSAR value for active trades)
- takeProfit: Suggested take profit price

Be thorough in your reasoning - explain your thinking process!
''';

    return _callAI(prompt);
  }

  Future<String> generateTradingSystem({String? userPreferences}) async {
    String prompt = '''
Generate a comprehensive trading system based on the following technical indicators that are actively used in the platform:

CORE INDICATORS:
1. **PAR (Parabolic SAR)**: Trend-following indicator
   - Buy when price crosses above PSAR
   - Sell when price crosses below PSAR
   - Use PSAR value as trailing stop loss

2. **RSI (Relative Strength Index, 14-period)**: Momentum oscillator
   - Oversold: RSI < 30 (potential buy)
   - Overbought: RSI > 70 (potential sell)
   - Neutral: 30 ≤ RSI ≤ 70

3. **MACD (12,26,9)**: Trend and momentum
   - Bullish crossover: MACD line crosses above Signal line
   - Bearish crossover: MACD line crosses below Signal line
   - Histogram shows momentum strength

4. **Bollinger Bands (20, 2)**: Volatility and price extremes
   - Price above upper band: Overbought
   - Price below lower band: Oversold
   - Price near middle band: Neutral

${userPreferences != null && userPreferences.isNotEmpty ? '''
USER PREFERENCES:
$userPreferences

IMPORTANT: Incorporate the user's preferences above into the trading system design.
''' : ''}

Generate a detailed trading system that:
1. **Entry Rules**: Clear conditions using indicator agreement (e.g., "Buy when PSAR is bullish AND RSI < 50 AND MACD shows bullish crossover")
2. **Exit Rules**: When to close positions (e.g., "Sell when 2 or more indicators turn bearish")
3. **Risk Management**: Position sizing, stop loss (use PSAR), take profit targets
4. **Timeframes**: Recommended timeframes for each indicator
5. **Conflict Resolution**: How to handle disagreeing indicators
6. **Confidence Scoring**: How to rate trade confidence (0-100%) based on indicator alignment

Format the system in clean markdown with:
- Clear headers (## for sections)
- Bullet points for rules
- **Bold** for important criteria
- Code blocks for specific conditions

Make it actionable and specific - not generic advice!
''';

    return _callAI(prompt);
  }

  Future<String> convertPineScriptToDart(String pineScriptCode) async {
    final prompt = '''
You are an expert in both PineScript and Dart programming. Convert the following PineScript indicator code to Dart.

PineScript Code:
```pinescript
$pineScriptCode
```

Requirements:
1. Create a Dart function that calculates the indicator values
2. The function should accept List<double> for price data (close, open, high, low as needed)
3. Return a List<double> with the indicator values (use double.nan for undefined values)
4. Include all necessary calculations (SMA, EMA, RSI, MACD, Bollinger Bands, etc.)
5. Use clear variable names and add comments
6. Do NOT include any imports or package dependencies
7. Make the function pure and stateless

Output ONLY the Dart function code, nothing else. Start with the function signature.

Example format:
```dart
List<double> calculateIndicator(List<double> closes, {int period = 14}) {
  // Your implementation here
  return result;
}
```
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
