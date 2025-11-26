import 'dart:convert';

class AISignal {
  final String signal; // BUY, SELL, HOLD
  final double confidence;
  final String reasoning;
  final double? stopLoss;
  final double? takeProfit;

  AISignal({
    required this.signal,
    required this.confidence,
    required this.reasoning,
    this.stopLoss,
    this.takeProfit,
  });

  factory AISignal.fromJson(Map<String, dynamic> json) {
    return AISignal(
      signal: json['signal'] ?? 'HOLD',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? 'No reasoning provided',
      stopLoss: json['stopLoss'] != null ? (json['stopLoss'] as num).toDouble() : null,
      takeProfit: json['takeProfit'] != null ? (json['takeProfit'] as num).toDouble() : null,
    );
  }

  factory AISignal.fromString(String response) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[^}]*"signal"[^}]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = json.decode(jsonStr);
        return AISignal.fromJson(data);
      }
      
      // Fallback: parse text response
      String signal = 'HOLD';
      if (response.toUpperCase().contains('BUY')) signal = 'BUY';
      if (response.toUpperCase().contains('SELL')) signal = 'SELL';
      
      return AISignal(
        signal: signal,
        confidence: 0.5,
        reasoning: response.length > 200 ? '${response.substring(0, 200)}...' : response,
      );
    } catch (e) {
      return AISignal(
        signal: 'HOLD',
        confidence: 0.0,
        reasoning: 'Error parsing AI response: $e',
      );
    }
  }
}
