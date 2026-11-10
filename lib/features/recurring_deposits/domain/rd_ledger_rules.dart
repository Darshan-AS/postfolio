import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';

/// India Post RD business rules as explicit constants.
///
/// These are the only "magic numbers" in the ledger and live here so a rule change
/// (e.g. a revised default-fee rate) is a one-line edit with an `effectiveFrom` extension point.
final class RDLedgerRules {
  const RDLedgerRules({
    this.dueDayCutoff = 15,
    this.defaultFeeRupeesPer100PerMonth = 1,
  });

  /// Accounts opened on or before this day of month are due on the same day every month;
  /// later openings are due on the last day of the month.
  final int dueDayCutoff;

  /// Statutory default fee: `₹1 per ₹100 (or part thereof) per month of default`.
  final int defaultFeeRupeesPer100PerMonth;

  static const standard = RDLedgerRules();

  /// Resolves the statutory due date for an installment falling in [installmentMonth].
  DateTime dueDateFor(DateTime startDate, DateTime installmentMonth) {
    if (startDate.day <= dueDayCutoff) {
      return DateTime(installmentMonth.year, installmentMonth.month, dueDayCutoff);
    }
    return DateTime(installmentMonth.year, installmentMonth.month + 1, 0);
  }

  /// Whether an installment with [dueDate] is in default on calendar day [asOf].
  /// Paying *on* the due date is never late.
  bool isInDefault(DateTime dueDate, DateTime asOf) =>
      asOf.toDateOnly().isAfter(dueDate.toDateOnly());

  /// Number of (whole or partial) calendar months of default accrued by [asOf].
  /// Returns 0 when not in default; the first late day already counts as one month.
  int defaultedMonths(DateTime dueDate, DateTime asOf) {
    if (!isInDefault(dueDate, asOf)) return 0;
    final due = dueDate.toDateOnly();
    final eval = asOf.toDateOnly();
    final months = (eval.year - due.year) * 12 + (eval.month - due.month);
    return months < 1 ? 1 : months;
  }

  /// Default fee in rupees for [installmentAmount] after [months] of default,
  /// computed exactly in paise and rounded up to the next whole rupee.
  double defaultFeeFor(double installmentAmount, int months) {
    if (months <= 0) return 0.0;
    final amountPaise = Money.toPaise(installmentAmount);
    // (amount / 100) * ratePer100 * months, expressed in paise, then ceil to whole rupees.
    final feePaise = amountPaise * defaultFeeRupeesPer100PerMonth * months ~/ 100;
    final remainder = amountPaise * defaultFeeRupeesPer100PerMonth * months % 100;
    final exactPaise = feePaise + (remainder > 0 ? 1 : 0);
    return Money.ceilToRupees(exactPaise).toDouble();
  }
}
