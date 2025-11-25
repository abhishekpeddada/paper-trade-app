import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/stock_repository.dart';

class WatchlistProvider extends ChangeNotifier {
  final StockRepository _repository = StockRepository();
  List<Stock> _watchlist = [];
  List<String> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<Stock> get watchlist => _watchlist;
  List<String> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stored symbol list
  List<String> _symbols = [];

  WatchlistProvider() {
    _loadAndFetchWatchlist();
  }

  Future<void> _loadAndFetchWatchlist() async {
    // Load saved symbols
    final prefs = await SharedPreferences.getInstance();
    _symbols = prefs.getStringList('watchlist_symbols') ?? 
               ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA'];
    
    print('📋 Loaded ${_symbols.length} symbols from storage');
    await fetchWatchlist();
  }

  Future<void> _saveSymbols() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('watchlist_symbols', _symbols);
    print('💾 Saved ${_symbols.length} symbols to storage');
  }

  Future<void> fetchWatchlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Fetching watchlist for ${_symbols.length} symbols...');
      _watchlist = await _repository.getWatchlist(_symbols);
      print('✅ Loaded ${_watchlist.length} stocks');
    } catch (e) {
      print('❌ Error fetching watchlist: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchStocks(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _repository.search(query);
      notifyListeners();
    } catch (e) {
      print('Search error: $e');
    }
  }

  Future<void> addToWatchlist(String symbol) async {
    if (_symbols.contains(symbol)) {
      print('⚠️ Symbol $symbol already in watchlist');
      return;
    }
    
    print('➕ Adding $symbol to watchlist');
    _symbols.add(symbol);
    await _saveSymbols();
    
    // Only fetch the new stock, don't refresh entire list
    try {
      _isLoading = true;
      notifyListeners();
      
      final newStock = await _repository.getStock(symbol);
      _watchlist.add(newStock);
      print('✅ Added $symbol successfully');
    } catch (e) {
      print('❌ Error adding $symbol: $e');
      _error = e.toString();
      // Remove from symbols if fetch failed
      _symbols.remove(symbol);
      await _saveSymbols();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromWatchlist(String symbol) async {
    _symbols.remove(symbol);
    _watchlist.removeWhere((stock) => stock.symbol == symbol);
    await _saveSymbols();
    notifyListeners();
    print('🗑️ Removed $symbol from watchlist');
  }
}
