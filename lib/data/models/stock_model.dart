import 'package:fl_chart/fl_chart.dart';

class Stock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final List<FlSpot> chartSpots;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    this.chartSpots = const [],
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    // This parsing logic will depend on the exact API response structure
    // For now, this is a placeholder structure
    return Stock(
      symbol: json['symbol'] ?? '',
      name: json['shortName'] ?? '',
      price: (json['regularMarketPrice'] ?? 0.0).toDouble(),
      change: (json['regularMarketChange'] ?? 0.0).toDouble(),
      changePercent: (json['regularMarketChangePercent'] ?? 0.0).toDouble(),
      chartSpots: [],
    );
  }
}
