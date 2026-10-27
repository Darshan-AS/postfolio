import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:uuid/uuid.dart';

/// Pure calendar arithmetic for an RD schedule. No money logic lives here.
abstract final class RDScheduleFactory {
  static const _uuid = Uuid();

  /// Deterministic UUIDv5 for `(rdId, installmentNo)` so virtual (never-persisted) months
  /// are still addressable by a stable identifier.
  static String installmentId(String rdId, int installmentNo) =>
      _uuid.v5(Namespace.url.value, 'postfolio:rd:$rdId:inst:$installmentNo');

  /// Adds calendar months without day overflow (Jan 31 + 1 month = Feb 28/29).
  static DateTime addMonths(DateTime start, int months) {
    final targetYear = start.year + (start.month + months - 1) ~/ 12;
    final targetMonth = (start.month + months - 1) % 12 + 1;
    final maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = start.day > maxDays ? maxDays : start.day;
    return DateTime(targetYear, targetMonth, targetDay);
  }

  /// 1-based installment number for the calendar month containing [date].
  /// May be `< 1` (before start) or `> totalMonths` (after maturity); callers bound-check.
  static int installmentNoFor(DateTime startDate, DateTime date) =>
      (date.year - startDate.year) * 12 + (date.month - startDate.month) + 1;

  /// Calendar month (1st of month) for [installmentNo].
  static DateTime installmentDateFor(DateTime startDate, int installmentNo) =>
      addMonths(startDate, installmentNo - 1);

  /// Builds an untouched installment row: either an opening-baseline month (already paid and
  /// deposited before onboarding) or a pristine unpaid month.
  static RDInstallment baselineInstallment({
    required RecurringDeposit deposit,
    required int installmentNo,
    RDLedgerRules rules = RDLedgerRules.standard,
  }) {
    final installmentDate = installmentDateFor(deposit.startDate, installmentNo);
    final dueDate = rules.dueDateFor(deposit.startDate, installmentDate);
    final isOpeningBaseline = installmentNo <= deposit.initialPaidInstallments;

    return RDInstallment(
      id: installmentId(deposit.id, installmentNo),
      rdId: deposit.id,
      installmentNo: installmentNo,
      installmentDate: installmentDate,
      dueDate: dueDate,
      installmentAmount: deposit.installmentAmount,
      isOpeningBaseline: isOpeningBaseline,
      customerPaidAmount: isOpeningBaseline ? deposit.installmentAmount : 0.0,
      customerStatus: isOpeningBaseline
          ? RDInstallmentStatus.fullyPaid
          : RDInstallmentStatus.unpaid,
      poStatus: isOpeningBaseline ? RDPoStatus.paid : RDPoStatus.unpaid,
      poPaidDate: isOpeningBaseline ? dueDate : null,
    );
  }

  /// Full untouched schedule for [deposit].
  static List<RDInstallment> baselineSchedule(
    RecurringDeposit deposit, {
    RDLedgerRules rules = RDLedgerRules.standard,
  }) =>
      [
        for (var no = 1; no <= deposit.totalMonths; no++)
          baselineInstallment(deposit: deposit, installmentNo: no, rules: rules),
      ];

  /// Whether [deposit] has an installment falling in the calendar month of [month].
  static bool coversMonth(RecurringDeposit deposit, DateTime month) {
    final no = installmentNoFor(deposit.startDate, month.toMonthStart());
    return no >= 1 && no <= deposit.totalMonths;
  }
}
