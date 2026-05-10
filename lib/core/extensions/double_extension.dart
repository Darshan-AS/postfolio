import 'package:intl/intl.dart';

extension DoubleFormatExtension on double {
  static final _noDecimals = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
  static final _twoDecimals = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 2);

  /// Formats double as Indian Rupee (e.g., ₹1,00,000)
  String toRupeeFormat({int decimalDigits = 0}) {
    if (decimalDigits == 0) return _noDecimals.format(this);
    if (decimalDigits == 2) return _twoDecimals.format(this);
    
    // Fallback for custom decimal sizes
    return NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: decimalDigits,
    ).format(this);
  }
}
