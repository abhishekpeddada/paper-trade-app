import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_model.dart';
import 'package:fl_chart/fl_chart.dart';

class YahooFinanceService {
  static const String baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  
  // Get historical data for AI analysis
  Future<List<Map<String, dynamic>>> getHistoricalData(String symbol, {int days = 30}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$symbol?interval=1d&range=${days}d'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final timestamps = result['timestamp'] as List<dynamic>?;
        final indicators = result['indicators']['quote'][0];
        final opens = indicators['open'] as List<dynamic>?;
        final highs = indicators['high'] as List<dynamic>?;
        final lows = indicators['low'] as List<dynamic>?;
        final closes = indicators['close'] as List<dynamic>?;
        final volumes = indicators['volume'] as List<dynamic>?;
        
        List<Map<String, dynamic>> history = [];
        if (timestamps != null && closes != null) {
          for (int i = 0; i < timestamps.length; i++) {
            if (closes[i] != null) {
              history.add({
                'timestamp': timestamps[i],
                'date': DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000).toIso8601String(),
                'open': opens?[i],
                'high': highs?[i],
                'low': lows?[i],
                'close': (closes[i] as num).toDouble(),
                'volume': volumes?[i],
              });
            }
          }
        }
        return history;
      }
      return [];
    } catch (e) {
      print('Error fetching historical data: $e');
      return [];
    }
  }

  // Get OHLC (candlestick) data for charting
  Future<List<Map<String, dynamic>>> getOHLCData(String symbol, {String timeframe = '1d'}) async {
    try {
      // Map timeframes to Yahoo Finance parameters
      // interval = candle period, range = how much historical data
      final rangeMap = {
        '1d': {'interval': '1d', 'range': '1y'},    // Daily candles, 1 year of data
        '1w': {'interval': '1wk', 'range': '2y'},   // Weekly candles, 2 years of data
        '1mo': {'interval': '1mo', 'range': '5y'},  // Monthly candles, 5 years of data
        '3mo': {'interval': '3mo', 'range': '10y'}, // Quarterly candles, 10 years of data
        '1y': {'interval': '1mo', 'range': 'max'},  // Monthly candles, all available data
      };
      
      final params = rangeMap[timeframe] ?? rangeMap['1d']!;
      final url = '$baseUrl/$symbol?interval=${params['interval']}&range=${params['range']}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final timestamps = result['timestamp'] as List<dynamic>?;
        final indicators = result['indicators']['quote'][0];
        final opens = indicators['open'] as List<dynamic>?;
        final highs = indicators['high'] as List<dynamic>?;
        final lows = indicators['low'] as List<dynamic>?;
        final closes = indicators['close'] as List<dynamic>?;
        final volumes = indicators['volume'] as List<dynamic>?;
        
        List<Map<String, dynamic>> ohlcData = [];
        if (timestamps != null && opens != null && highs != null && lows != null && closes != null) {
          for (int i = 0; i < timestamps.length; i++) {
            if (opens[i] != null && highs[i] != null && lows[i] != null && closes[i] != null) {
              ohlcData.add({
                'date': DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000).toIso8601String(),
                'open': (opens[i] as num).toDouble(),
                'high': (highs[i] as num).toDouble(),
                'low': (lows[i] as num).toDouble(),
                'close': (closes[i] as num).toDouble(),
                'volume': (volumes != null && volumes[i] != null) ? (volumes[i] as num).toDouble() : 0.0,
              });
            }
          }
        }
        return ohlcData;
      }
      return [];
    } catch (e) {
      print('Error fetching OHLC data: $e');
      return [];
    }
  }

  // Get OHLC data with specific candle intervals (for full chart view)
  Future<List<Map<String, dynamic>>> getOHLCDataWithInterval({
    required String symbol,
    required String interval, // 1m, 5m, 15m, 30m, 1h, 1d, 1wk, 1mo
  }) async {
    try {
      // Map intervals to appropriate data ranges
      // Key: interval, Value: range to fetch
      final intervalRangeMap = {
        '1m': '1d',      // 1-minute candles: show 1 day
        '5m': '5d',      // 5-minute candles: show 5 days
        '15m': '5d',     // 15-minute candles: show 5 days
        '30m': '1mo',    // 30-minute candles: show 1 month
        '1h': '1mo',     // 1-hour candles: show 1 month
        '1d': '1y',      // 1-day candles: show 1 year
        '1wk': '2y',     // 1-week candles: show 2 years
        '1mo': '5y',     // 1-month candles: show 5 years
      };

      final range = intervalRangeMap[interval] ?? '1mo';
      final url = '$baseUrl/$symbol?interval=$interval&range=$range';
      
      print('📊 Fetching OHLC data: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final timestamps = result['timestamp'] as List<dynamic>?;
        final indicators = result['indicators']['quote'][0];
        final opens = indicators['open'] as List<dynamic>?;
        final highs = indicators['high'] as List<dynamic>?;
        final lows = indicators['low'] as List<dynamic>?;
        final closes = indicators['close'] as List<dynamic>?;
        final volumes = indicators['volume'] as List<dynamic>?;
        
        List<Map<String, dynamic>> ohlcData = [];
        if (timestamps != null && opens != null && highs != null && lows != null && closes != null) {
          for (int i = 0; i < timestamps.length; i++) {
            if (opens[i] != null && highs[i] != null && lows[i] != null && closes[i] != null) {
              ohlcData.add({
                'date': DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000).toIso8601String(),
                'open': (opens[i] as num).toDouble(),
                'high': (highs[i] as num).toDouble(),
                'low': (lows[i] as num).toDouble(),
                'close': (closes[i] as num).toDouble(),
                'volume': (volumes != null && volumes[i] != null) ? (volumes[i] as num).toDouble() : 0.0,
              });
            }
          }
        }
        print('✅ Loaded ${ohlcData.length} candles for $symbol with interval $interval');
        return ohlcData;
      }
      print('❌ Failed to fetch OHLC data: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error fetching OHLC data with interval: $e');
      return [];
    }
  }

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
}
