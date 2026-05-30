import 'package:intl/intl.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/i18n/strings.g.dart';

extension DoubleFormatExtension on double {
  static final _noDecimals = NumberFormat.currency(
    symbol: t.format.currencySymbol,
    locale: AppConstants.defaultLocale,
    decimalDigits: 0,
  );

  /// Formats double as Indian Rupee (e.g., ₹1,00,000)
  String toRupeeFormat() {
    return _noDecimals.format(round());
  }
}
