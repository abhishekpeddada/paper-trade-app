class PineScriptConversion {
  final String originalPineScript;
  final String symbol;
  final String convertedDartCode;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime timestamp;
  final String? indicatorName;

  PineScriptConversion({
    required this.originalPineScript,
    required this.symbol,
    required this.convertedDartCode,
    required this.isSuccess,
    this.errorMessage,
    required this.timestamp,
    this.indicatorName,
  });

  factory PineScriptConversion.success({
    required String pineScript,
    required String symbol,
    required String dartCode,
    String? indicatorName,
  }) {
    return PineScriptConversion(
      originalPineScript: pineScript,
      symbol: symbol,
      convertedDartCode: dartCode,
      isSuccess: true,
      timestamp: DateTime.now(),
      indicatorName: indicatorName,
    );
  }

  factory PineScriptConversion.error({
    required String pineScript,
    required String symbol,
    required String errorMessage,
  }) {
    return PineScriptConversion(
      originalPineScript: pineScript,
      symbol: symbol,
      convertedDartCode: '',
      isSuccess: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalPineScript': originalPineScript,
      'symbol': symbol,
      'convertedDartCode': convertedDartCode,
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'indicatorName': indicatorName,
    };
  }

  factory PineScriptConversion.fromJson(Map<String, dynamic> json) {
    return PineScriptConversion(
      originalPineScript: json['originalPineScript'],
      symbol: json['symbol'],
      convertedDartCode: json['convertedDartCode'],
      isSuccess: json['isSuccess'],
      errorMessage: json['errorMessage'],
      timestamp: DateTime.parse(json['timestamp']),
      indicatorName: json['indicatorName'],
    );
  }
}
