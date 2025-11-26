import '../models/pine_conversion_model.dart';
import '../models/ohlc_data.dart';
import '../services/openrouter_service.dart';
import '../services/yahoo_finance_service.dart';

class PineScriptRepository {
  final OpenRouterService _openRouterService;
  final YahooFinanceService _yahooFinanceService;

  PineScriptRepository(this._openRouterService, this._yahooFinanceService);

  // Expose for provider reinitialization
  YahooFinanceService get yahooFinanceService => _yahooFinanceService;

  /// Convert PineScript to Dart code using AI
  Future<PineScriptConversion> convertPineScript(
    String pineScriptCode,
    String symbol,
  ) async {
    try {
      final dartCode = await _openRouterService.convertPineScriptToDart(pineScriptCode);
      
      // Extract indicator name from PineScript if possible
      String? indicatorName;
      final indicatorPattern = RegExp(r'''indicator\s*\(\s*["']([^"']+)["']''');
      final indicatorMatch = indicatorPattern.firstMatch(pineScriptCode);
      if (indicatorMatch != null) {
        indicatorName = indicatorMatch.group(1);
      }

      return PineScriptConversion.success(
        pineScript: pineScriptCode,
        symbol: symbol,
        dartCode: dartCode,
        indicatorName: indicatorName,
      );
    } catch (e) {
      return PineScriptConversion.error(
        pineScript: pineScriptCode,
        symbol: symbol,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetch OHLC data for a symbol
  Future<List<OHLCData>> getChartData(String symbol, {String timeframe = '1m'}) async {
    try {
      final data = await _yahooFinanceService.getOHLCData(symbol, timeframe: timeframe);
      return data.map((json) => OHLCData.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching chart data: $e');
      return [];
    }
  }

  /// Get close prices for indicator calculation
  Future<List<double>> getClosePrices(String symbol, {String timeframe = '1m'}) async {
    try {
      final ohlcData = await getChartData(symbol, timeframe: timeframe);
      return ohlcData.map((data) => data.close).toList();
    } catch (e) {
      print('Error fetching close prices: $e');
      return [];
    }
  }
}
