enum OrderType { buy, sell }

class Position {
  final String symbol;
  double quantity;
  double averagePrice;

  Position({
    required this.symbol,
    required this.quantity,
    required this.averagePrice,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'quantity': quantity,
    'averagePrice': averagePrice,
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    symbol: json['symbol'],
    quantity: (json['quantity'] as num).toDouble(),
    averagePrice: (json['averagePrice'] as num).toDouble(),
  );
}

class Order {
  final String id;
  final String symbol;
  final OrderType type;
  final double quantity;
  final double price;
  final DateTime timestamp;

  Order({
    required this.id,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'type': type.toString(),
    'quantity': quantity,
    'price': price,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    symbol: json['symbol'],
    type: json['type'] == 'OrderType.buy' ? OrderType.buy : OrderType.sell,
    quantity: (json['quantity'] as num).toDouble(),
    price: (json['price'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
  );
}
