import 'package:intl/intl.dart';

class CurrencyHelper {
  static const double usdToInrRate = 84.50;

  /// Returns true if the symbol represents an Indian stock (NSE/BSE)
  static bool isIndianStock(String symbol) {
    final s = symbol.toUpperCase();
    return s.endsWith('.NS') || s.endsWith('.BO');
  }

  /// Returns the currency symbol for a given stock symbol
  static String getCurrencySymbol(String symbol) {
    return isIndianStock(symbol) ? '₹' : '\$';
  }

  /// Converts a price from its native currency to INR
  /// If it's already an Indian stock, returns the price as is.
  /// If it's a US/Global stock, converts USD to INR.
  static double convertToInr(double price, String symbol) {
    if (isIndianStock(symbol)) {
      return price;
    } else {
      return price * usdToInrRate;
    }
  }

  /// Formats a price with the correct currency symbol
  static String formatPrice(double price, String symbol, {int decimalPlaces = 2}) {
    final currency = getCurrencySymbol(symbol);
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: decimalPlaces);
    return formatter.format(price);
  }
  
  /// Formats a value strictly in INR (for portfolio totals)
  static String formatInr(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    return formatter.format(amount);
  }
}
