import 'package:intl/intl.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/i18n/strings.g.dart';

extension DoubleFormatExtension on double {
  static final _noDecimals = NumberFormat.currency(
    symbol: t.format.currencySymbol,
    locale: AppConstants.defaultLocale,
    decimalDigits: 0,
  );
  static final _twoDecimals = NumberFormat.currency(
    symbol: t.format.currencySymbol,
    locale: AppConstants.defaultLocale,
    decimalDigits: 2,
  );

  /// Formats double as Indian Rupee (e.g., ₹1,00,000)
  String toRupeeFormat({int decimalDigits = 0}) {
    if (decimalDigits == 0) return _noDecimals.format(this);
    if (decimalDigits == 2) return _twoDecimals.format(this);

    // Fallback for custom decimal sizes
    return NumberFormat.currency(
      symbol: t.format.currencySymbol,
      locale: AppConstants.defaultLocale,
      decimalDigits: decimalDigits,
    ).format(this);
  }
}
