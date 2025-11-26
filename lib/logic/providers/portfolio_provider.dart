import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/trade_models.dart';
import '../../data/repositories/stock_repository.dart';

class PortfolioProvider extends ChangeNotifier {
  final StockRepository _repository = StockRepository();
  double _balance = 100000.0; // Initial virtual cash
  List<Position> _positions = [];
  List<Order> _orders = [];
  Map<String, double> _currentPrices = {}; // Track current prices for P&L
  Timer? _refreshTimer;
  DateTime? _lastRefresh;
  bool _isRefreshing = false;

  double get balance => _balance;
  List<Position> get positions => _positions;
  List<Order> get orders => _orders;
  Map<String, double> get currentPrices => _currentPrices;
  DateTime? get lastRefresh => _lastRefresh;
  bool get isRefreshing => _isRefreshing;


  PortfolioProvider() {
    _loadData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Refresh every 10 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (_isWeekday() && _positions.isNotEmpty) {
        refreshPrices();
      }
    });
  }

  bool _isWeekday() {
    final now = DateTime.now();
    return now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getDouble('balance') ?? 100000.0;
    
    final positionsJson = prefs.getStringList('positions') ?? [];
    _positions = positionsJson.map((e) => Position.fromJson(json.decode(e))).toList();

    final ordersJson = prefs.getStringList('orders') ?? [];
    _orders = ordersJson.map((e) => Order.fromJson(json.decode(e))).toList();
    
    notifyListeners();
    
    // Refresh prices if we have positions
    if (_positions.isNotEmpty) {
      refreshPrices();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', _balance);
    
    final positionsJson = _positions.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('positions', positionsJson);

    final ordersJson = _orders.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('orders', ordersJson);
  }

  Future<void> executeOrder(String symbol, double quantity, double price, OrderType type) async {
    if (type == OrderType.buy) {
      _buy(symbol, quantity, price);
    } else {
      _sell(symbol, quantity, price);
    }
    await _saveData();
  }

  // For AI to call
  Future<void> placeAutomatedOrder(String symbol, String signal, double price) async {
    // Simple logic: Buy 1 share if BUY, Sell all if SELL
    if (signal == 'BUY') {
      // Check if we already have it? Maybe buy more?
      // For safety, let's just buy 1 qty for now or \$1000 worth
      double qty = (1000 / price).floorToDouble();
      if (qty < 1) qty = 1;
      
      try {
        await executeOrder(symbol, qty, price, OrderType.buy);
      } catch (e) {
        print('Auto trade failed: $e');
      }
    } else if (signal == 'SELL') {
      final qty = getQuantity(symbol);
      if (qty > 0) {
        await executeOrder(symbol, qty, price, OrderType.sell);
      }
    }
  }

  void _buy(String symbol, double quantity, double price) {
    final totalCost = quantity * price;
    if (totalCost > _balance) {
      throw Exception('Insufficient funds');
    }

    _balance -= totalCost;

    // Update or add position
    final index = _positions.indexWhere((p) => p.symbol == symbol);
    if (index != -1) {
      final position = _positions[index];
      final newQuantity = position.quantity + quantity;
      final newAvgPrice = ((position.quantity * position.averagePrice) + totalCost) / newQuantity;
      
      position.quantity = newQuantity;
      position.averagePrice = newAvgPrice;
    } else {
      _positions.add(Position(symbol: symbol, quantity: quantity, averagePrice: price));
    }

    _addOrder(symbol, OrderType.buy, quantity, price);
    notifyListeners();
  }

  void _sell(String symbol, double quantity, double price) {
    final index = _positions.indexWhere((p) => p.symbol == symbol);
    if (index == -1) {
      throw Exception('Position not found');
    }

    final position = _positions[index];
    if (position.quantity < quantity) {
      throw Exception('Insufficient quantity');
    }

    final totalProceeds = quantity * price;
    _balance += totalProceeds;

    position.quantity -= quantity;
    if (position.quantity <= 0) {
      _positions.removeAt(index);
    }

    _addOrder(symbol, OrderType.sell, quantity, price);
    notifyListeners();
  }

  void _addOrder(String symbol, OrderType type, double quantity, double price) {
    _orders.insert(0, Order(
      id: const Uuid().v4(),
      symbol: symbol,
      type: type,
      quantity: quantity,
      price: price,
      timestamp: DateTime.now(),
    ));
  }
  
  
  // Helper to get current quantity for a symbol
  double getQuantity(String symbol) {
    final index = _positions.indexWhere((p) => p.symbol == symbol);
    return index != -1 ? _positions[index].quantity : 0.0;
  }

  // Refresh current prices for all positions
  Future<void> refreshPrices() async {
    if (_positions.isEmpty) return;
    
    _isRefreshing = true;
    notifyListeners();

    try {
      final symbols = _positions.map((p) => p.symbol).toList();
      final stocks = await _repository.getWatchlist(symbols);
      
      for (var stock in stocks) {
        _currentPrices[stock.symbol] = stock.price;
      }
      
      _lastRefresh = DateTime.now();
    } catch (e) {
      print('Error refreshing portfolio prices: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Calculate profit/loss for a position
  double getProfitLoss(Position position) {
    if (!_currentPrices.containsKey(position.symbol)) {
      return 0.0;
    }
    final currentPrice = _currentPrices[position.symbol]!;
    final currentValue = currentPrice * position.quantity;
    final costBasis = position.averagePrice * position.quantity;
    return currentValue - costBasis;
  }

  // Calculate profit/loss percentage
  double getProfitLossPercent(Position position) {
    if (!_currentPrices.containsKey(position.symbol)) {
      return 0.0;
    }
    final currentPrice = _currentPrices[position.symbol]!;
    return ((currentPrice - position.averagePrice) / position.averagePrice) * 100;
  }

  // Get total portfolio value
  double getTotalPortfolioValue() {
    double totalValue = _balance;
    for (var position in _positions) {
      if (_currentPrices.containsKey(position.symbol)) {
        totalValue += _currentPrices[position.symbol]! * position.quantity;
      } else {
        totalValue += position.averagePrice * position.quantity; // Use avg price if current not available
      }
    }
    return totalValue;
  }

  // Get total P&L
  double getTotalProfitLoss() {
    double totalPL = 0.0;
    for (var position in _positions) {
      totalPL += getProfitLoss(position);
    }
    return totalPL;
  }
}
