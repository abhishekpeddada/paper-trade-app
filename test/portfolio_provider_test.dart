import 'package:flutter_test/flutter_test.dart';
import 'package:paper_trade_app/logic/providers/portfolio_provider.dart';
import 'package:paper_trade_app/data/models/trade_models.dart';

void main() {
  group('PortfolioProvider Tests', () {
    late PortfolioProvider provider;

    setUp(() {
      provider = PortfolioProvider();
    });

    test('Initial balance should be 100,000', () {
      expect(provider.balance, 100000.0);
    });

    test('Buy order should decrease balance and add position', () {
      provider.executeOrder('AAPL', 10, 150.0, OrderType.buy);

      expect(provider.balance, 100000.0 - (10 * 150.0));
      expect(provider.positions.length, 1);
      expect(provider.positions.first.symbol, 'AAPL');
      expect(provider.positions.first.quantity, 10);
      expect(provider.orders.length, 1);
    });

    test('Sell order should increase balance and decrease position', () {
      // First buy
      provider.executeOrder('AAPL', 10, 150.0, OrderType.buy);
      
      // Then sell half
      provider.executeOrder('AAPL', 5, 160.0, OrderType.sell);

      expect(provider.balance, 100000.0 - 1500.0 + (5 * 160.0)); // 98500 + 800 = 99300
      expect(provider.positions.first.quantity, 5);
      expect(provider.orders.length, 2);
    });

    test('Sell order with insufficient quantity should throw exception', () {
      provider.executeOrder('AAPL', 10, 150.0, OrderType.buy);

      expect(
        () => provider.executeOrder('AAPL', 15, 160.0, OrderType.sell),
        throwsException,
      );
    });

    test('Buy order with insufficient funds should throw exception', () {
      expect(
        () => provider.executeOrder('BRK.A', 1, 200000.0, OrderType.buy),
        throwsException,
      );
    });
  });
}
