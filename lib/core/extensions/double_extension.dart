import 'package:intl/intl.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/i18n/strings.g.dart';

extension DoubleFormatExtension on double {
  static final _wholeRupees = NumberFormat.currency(
    symbol: t.format.currencySymbol,
    locale: AppConstants.defaultLocale,
    decimalDigits: 0,
  );

  static final _exactPaise = NumberFormat.currency(
    symbol: t.format.currencySymbol,
    locale: AppConstants.defaultLocale,
    decimalDigits: 2,
  );

  /// Formats an amount in Indian Rupees (`en_IN`):
  /// - Whole rupees render compactly (`₹5,000`, `₹1,00,000`).
  /// - Amounts with non-zero paise preserve exact 2-decimal paise (`₹2.50`, `₹616.67`).
  String toRupeeFormat() {
    final paise = Paise.fromRupees(this);
    if (paise.hasSubRupeePaise) {
      return _exactPaise.format(paise.toRupees());
    }
    return _wholeRupees.format(paise.value ~/ Paise.perRupee);
  }
}
