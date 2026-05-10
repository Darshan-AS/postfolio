import 'package:intl/intl.dart';

extension DoubleFormatExtension on double {
  /// Formats double as Indian Rupee (e.g., ₹1,00,000)
  String toRupeeFormat({int decimalDigits = 0}) {
    final formatCurrency = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: decimalDigits,
    );
    return formatCurrency.format(this);
  }
}
