import '../models/stock_model.dart';
import '../services/yahoo_finance_service.dart';

class StockRepository {
  final YahooFinanceService _service;

  StockRepository({YahooFinanceService? service}) 
      : _service = service ?? YahooFinanceService();

  Future<Stock> getStock(String symbol, {String timeframe = '1d'}) async {
    return await _service.getStockData(symbol, timeframe: timeframe);
  }

  Future<List<Stock>> getWatchlist(List<String> symbols) async {
    return await _service.getBatchStockData(symbols);
  }
  
  Future<List<String>> search(String query) async {
    return await _service.searchSymbols(query);
  }
}
