import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_model.dart';
import 'package:fl_chart/fl_chart.dart';

class YahooFinanceService {
  static const String baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';

  Future<Stock> getStockData(String symbol, {String timeframe = '1d'}) async {
    try {
      // Map timeframes to Yahoo Finance parameters
      final rangeMap = {
        '1d': {'interval': '5m', 'range': '1d'},
        '1w': {'interval': '1h', 'range': '5d'},
        '1m': {'interval': '1d', 'range': '1mo'},
        '3m': {'interval': '1d', 'range': '3mo'},
        '1y': {'interval': '1d', 'range': '1y'},
        'all': {'interval': '1wk', 'range': 'max'},
      };
      
      final params = rangeMap[timeframe] ?? rangeMap['1d']!;
      final url = '$baseUrl/$symbol?interval=${params['interval']}&range=${params['range']}';
      
      print('📊 Fetching stock data: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      print('📊 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['chart']['result'] == null || data['chart']['result'].isEmpty) {
          print('❌ No data in response for $symbol');
          throw Exception('No data available for $symbol');
        }
        
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final timestamp = result['timestamp'] as List<dynamic>?;
        final indicators = result['indicators']['quote'][0];
        final closes = indicators['close'] as List<dynamic>?;

        List<FlSpot> spots = [];
        if (timestamp != null && closes != null) {
          for (int i = 0; i < timestamp.length; i++) {
            if (closes[i] != null) {
              spots.add(FlSpot(i.toDouble(), (closes[i] as num).toDouble()));
            }
          }
        }
        
        print('✅ Loaded ${spots.length} data points for $symbol');
        
        return Stock(
          symbol: meta['symbol'],
          name: meta['symbol'], 
          price: (meta['regularMarketPrice'] ?? 0.0).toDouble(),
          change: (meta['regularMarketPrice'] - meta['chartPreviousClose']).toDouble(),
          changePercent: ((meta['regularMarketPrice'] - meta['chartPreviousClose']) / meta['chartPreviousClose'] * 100).toDouble(),
          chartSpots: spots,
        );
      } else {
        print('❌ HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Failed to load stock data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching $symbol: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  Future<List<Stock>> getBatchStockData(List<String> symbols) async {
    // Yahoo Finance doesn't have a free simple batch endpoint for this chart data easily accessible without keys sometimes.
    // We will fetch them individually for this demo or use a different endpoint if needed.
    // For better performance in a real app, we would use a proper batch endpoint or WebSocket.
    
    List<Stock> stocks = [];
    for (var symbol in symbols) {
      try {
        final stock = await getStockData(symbol);
        stocks.add(stock);
      } catch (e) {
        print('Error fetching $symbol: $e');
      }
    }
    return stocks;
  }
  
  // Search autocomplete (using a different endpoint usually)
  Future<List<String>> searchSymbols(String query) async {
     try {
       final response = await http.get(
         Uri.parse('https://query1.finance.yahoo.com/v1/finance/search?q=$query'),
         headers: {
           'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
         },
       );
       
       if (response.statusCode == 200) {
         final data = json.decode(response.body);
         final quotes = data['quotes'] as List;
         return quotes
             .where((q) => q['symbol'] != null)
             .map((q) => q['symbol'] as String)
             .toList();
       }
     } catch (e) {
       print('Search error: $e');
     }
     return [];
  }

  // Fetch historical candle data for AI analysis
  Future<List<Map<String, dynamic>>> getHistoricalData(String symbol, {String range = '1mo', String interval = '1d'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$symbol?interval=$interval&range=$range'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final timestamp = result['timestamp'] as List<dynamic>?;
        final indicators = result['indicators']['quote'][0];
        
        final opens = indicators['open'] as List<dynamic>?;
        final highs = indicators['high'] as List<dynamic>?;
        final lows = indicators['low'] as List<dynamic>?;
        final closes = indicators['close'] as List<dynamic>?;
        final volumes = indicators['volume'] as List<dynamic>?;

        List<Map<String, dynamic>> candles = [];
        if (timestamp != null && closes != null) {
          for (int i = 0; i < timestamp.length; i++) {
            if (closes[i] != null) {
              candles.add({
                'date': DateTime.fromMillisecondsSinceEpoch(timestamp[i] * 1000).toIso8601String(),
                'open': opens?[i],
                'high': highs?[i],
                'low': lows?[i],
                'close': closes[i],
                'volume': volumes?[i],
              });
            }
          }
        }
        return candles;
      } else {
        throw Exception('Failed to load historical data');
      }
    } catch (e) {
      print('Error fetching history for $symbol: $e');
      return [];
    }
  }
}
