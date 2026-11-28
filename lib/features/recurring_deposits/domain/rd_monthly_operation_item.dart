import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

part 'rd_monthly_operation_item.freezed.dart';

/// Color emphasis for the primary figure shown on a Monthly Hub card.
enum RDHeadlineMoneyTone { overdue, neutral, settled, muted }

/// Resolved primary figure and base comparison amount for a Monthly Hub card.
typedef RDHeadlineMoney = ({
  double amount,
  double baseAmount,
  RDHeadlineMoneyTone tone,
});

/// Customer-side step of the 2-step flipbook track.
sealed class RDCustomerStep {
  const RDCustomerStep();
}

final class RDCustomerOverdue extends RDCustomerStep {
  const RDCustomerOverdue({required this.months});
  final int months;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RDCustomerOverdue && months == other.months;

  @override
  int get hashCode => months.hashCode;
}

final class RDCustomerDueToday extends RDCustomerStep {
  const RDCustomerDueToday();

  @override
  bool operator ==(Object other) => other is RDCustomerDueToday;

  @override
  int get hashCode => (RDCustomerDueToday).hashCode;
}

final class RDCustomerUpcoming extends RDCustomerStep {
  const RDCustomerUpcoming();

  @override
  bool operator ==(Object other) => other is RDCustomerUpcoming;

  @override
  int get hashCode => (RDCustomerUpcoming).hashCode;
}

final class RDCustomerPartial extends RDCustomerStep {
  const RDCustomerPartial();

  @override
  bool operator ==(Object other) => other is RDCustomerPartial;

  @override
  int get hashCode => (RDCustomerPartial).hashCode;
}

final class RDCustomerReceivable extends RDCustomerStep {
  const RDCustomerReceivable();

  @override
  bool operator ==(Object other) => other is RDCustomerReceivable;

  @override
  int get hashCode => (RDCustomerReceivable).hashCode;
}

final class RDCustomerPaid extends RDCustomerStep {
  const RDCustomerPaid();

  @override
  bool operator ==(Object other) => other is RDCustomerPaid;

  @override
  int get hashCode => (RDCustomerPaid).hashCode;
}

/// Post Office deposit step of the 2-step flipbook track (strictly binary).
enum RDPoStep { pending, deposited }

/// Unified flipbook track descriptor: either a pre-onboarding baseline month or an active
/// 2-step `Customer | PO` track.
sealed class RDHubStepTrack {
  const RDHubStepTrack();
}

final class RDHubBaselineTrack extends RDHubStepTrack {
  const RDHubBaselineTrack();

  @override
  bool operator ==(Object other) => other is RDHubBaselineTrack;

  @override
  int get hashCode => (RDHubBaselineTrack).hashCode;
}

final class RDHubTwoStepTrack extends RDHubStepTrack {
  const RDHubTwoStepTrack({required this.customer, required this.po});
  final RDCustomerStep customer;
  final RDPoStep po;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RDHubTwoStepTrack &&
          customer == other.customer &&
          po == other.po;

  @override
  int get hashCode => Object.hash(customer, po);
}

/// Optional contextual caption below a Monthly Hub row's action footer.
sealed class RDHubRowCaption {
  const RDHubRowCaption();
}

final class RDHubPendingChargesCaption extends RDHubRowCaption {
  const RDHubPendingChargesCaption({
    required this.feeDue,
    required this.priorOverdueCount,
  });

  final double feeDue;
  final int priorOverdueCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RDHubPendingChargesCaption &&
          feeDue == other.feeDue &&
          priorOverdueCount == other.priorOverdueCount;

  @override
  int get hashCode => Object.hash(feeDue, priorOverdueCount);
}

final class RDHubPartialCaption extends RDHubRowCaption {
  const RDHubPartialCaption({required this.paid, required this.due});
  final double paid;
  final double due;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RDHubPartialCaption && paid == other.paid && due == other.due;

  @override
  int get hashCode => Object.hash(paid, due);
}

final class RDHubFromPocketCaption extends RDHubRowCaption {
  const RDHubFromPocketCaption();

  @override
  bool operator ==(Object other) => other is RDHubFromPocketCaption;

  @override
  int get hashCode => (RDHubFromPocketCaption).hashCode;
}

final class RDHubReadyForPoCaption extends RDHubRowCaption {
  const RDHubReadyForPoCaption({required this.count});
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RDHubReadyForPoCaption && count == other.count;

  @override
  int get hashCode => count.hashCode;
}

/// One row of the Monthly Hub: an account's installment for the selected month plus the
/// account-level counters the agent needs to act on it. Built from `RDLedgerSummary`.
@freezed
sealed class RDMonthlyOperationItem with _$RDMonthlyOperationItem {
  const RDMonthlyOperationItem._();

  const factory RDMonthlyOperationItem({
    required RecurringDeposit deposit,
    required RDInstallment installment,
    required RDLedgerSummary summary,

    /// Months before this one the customer still owes on (arrears carried into this month).
    @Default(<RDInstallment>[]) List<RDInstallment> priorOpen,
    @Default(true) bool hasSummary,
  }) = _RDMonthlyOperationItem;

  int get installmentNumber => installment.installmentNo;

  RDInstallmentDisplayStatus displayStatus(DateTime now) =>
      installment.displayStatusAt(now);

  bool get isSettled => installment.isFullySettled;
  bool get isReadyForPo => installment.isReadyForPo;
  bool get isPaidFromPocket => installment.isPaidFromPocket;
  bool get isCustomerPending =>
      !installment.isCustomerSettled && !installment.isOpeningBaseline;
  bool isOverdue(DateTime now) => installment.isOverdueAt(now);

  int get priorOverdueCount => priorOpen.length;
  double get priorOverdueAmount =>
      priorOpen.fold(0.0, (s, p) => s + p.outstandingAmount);
  bool get hasPriorArrears => priorOpen.isNotEmpty;

  /// What the customer must pay to bring the account up to date through this month.
  double get totalOutstanding =>
      priorOverdueAmount +
      installment.outstandingAmount +
      summary.openingReceivableLeft;

  /// Fee component of [totalOutstanding] (informational).
  double get totalFeeDue =>
      priorOpen.fold(0.0, (s, p) => s + p.customerFeeDue) +
      installment.customerFeeDue;

  bool hasOverdueDebt(DateTime now) =>
      hasPriorArrears || (installment.isOverdueAt(now) && isCustomerPending);

  bool isUpcoming(DateTime now) {
    final m = DateTime(now.year, now.month);
    final t = DateTime(
      installment.installmentDate.year,
      installment.installmentDate.month,
    );
    return t.isAfter(m);
  }

  /// Whether this account falls into the 1st-to-15th India Post statutory deadline window.
  bool get isFirstHalfDue =>
      installment.dueDate.day <= RDLedgerRules.standard.dueDayCutoff;

  /// Number of contiguous months that can be deposited on the next PO visit.
  int get readyForPoCount => summary.readyForPoCount;

  /// Total cash in hand awaiting deposit for this account, falling back to this month's due.
  double get readyForPoAmount =>
      summary.cashInHand > 0 ? summary.cashInHand : installment.dueAmount;

  /// Total agent receivable for this account, falling back to this month's due.
  double get receivableAmount =>
      summary.receivable > 0 ? summary.receivable : installment.dueAmount;

  /// Can deposit something at the PO: ready months, or pay this month from pocket.
  bool get canDepositToPo =>
      !installment.isOpeningBaseline && !installment.isPoDeposited;

  /// Can undo the latest PO event only if this month is the most recently deposited one.
  bool get isLatestDeposited =>
      installment.isPoDeposited &&
      !installment.isOpeningBaseline &&
      installment.installmentNo == summary.depositedThroughNo;

  /// Prefilled payment amount when logging a customer payment from the Monthly Hub.
  double get initialPaymentAmount => totalOutstanding;

  /// Total unpaid overdue months counting carried priors plus this month if overdue.
  int arrearsMonthsAt(DateTime now) =>
      priorOverdueCount + (isOverdue(now) && isCustomerPending ? 1 : 0);

  /// Earliest due date among unresolved overdue obligations for [now], if any.
  DateTime? oldestOverdueDueDateAt(DateTime now) => hasPriorArrears
      ? priorOpen.first.dueDate
      : (isOverdue(now) && isCustomerPending ? installment.dueDate : null);

  /// Number of contiguous installments needed at PO to include this month.
  int get fromPocketInstallmentCount =>
      summary.depositedThroughNo < installment.installmentNo
      ? installment.installmentNo - summary.depositedThroughNo
      : 1;

  bool get hasReadyForPo => isReadyForPo || readyForPoCount > 0;

  bool get hasReceivable => isPaidFromPocket || summary.receivable > 0;

  bool get canDepositFromPocket => canDepositToPo && isCustomerPending;

  /// Primary headline figure, base installment comparison, and semantic tone for a row.
  RDHeadlineMoney headlineMoneyAt(DateTime now) {
    final baseAmount = deposit.installmentAmount;
    if (isCustomerPending && totalOutstanding > 0) {
      return (
        amount: totalOutstanding,
        baseAmount: baseAmount,
        tone: hasOverdueDebt(now)
            ? RDHeadlineMoneyTone.overdue
            : RDHeadlineMoneyTone.neutral,
      );
    }
    if (!isCustomerPending && readyForPoCount > 0) {
      return (
        amount: readyForPoAmount,
        baseAmount: baseAmount,
        tone: RDHeadlineMoneyTone.neutral,
      );
    }
    final paid = installment.customerPaidAmount > 0
        ? installment.customerPaidAmount
        : baseAmount;
    final isSettled = displayStatus(now) == RDInstallmentDisplayStatus.settled;
    return (
      amount: paid,
      baseAmount: baseAmount,
      tone: isSettled ? RDHeadlineMoneyTone.settled : RDHeadlineMoneyTone.muted,
    );
  }

  /// Unified flipbook track (`Baseline` or `Customer | PO`) derived cleanly in domain.
  RDHubStepTrack stepTrackAt(DateTime now) {
    final status = displayStatus(now);
    if (status == RDInstallmentDisplayStatus.baseline) {
      return const RDHubBaselineTrack();
    }

    final inArrears = hasPriorArrears && status.isCustomerPending;
    final overdueMonths = arrearsMonthsAt(now);

    final customer = inArrears
        ? RDCustomerOverdue(months: overdueMonths < 1 ? 1 : overdueMonths)
        : switch (status) {
            RDInstallmentDisplayStatus.baseline => throw StateError(
              'Baseline handled above',
            ),
            RDInstallmentDisplayStatus.overdue => RDCustomerOverdue(
              months: overdueMonths < 1 ? 1 : overdueMonths,
            ),
            RDInstallmentDisplayStatus.dueToday => const RDCustomerDueToday(),
            RDInstallmentDisplayStatus.upcoming => const RDCustomerUpcoming(),
            RDInstallmentDisplayStatus.partiallyPaid =>
              const RDCustomerPartial(),
            RDInstallmentDisplayStatus.paidFromPocket =>
              const RDCustomerReceivable(),
            RDInstallmentDisplayStatus.collectedPendingPo ||
            RDInstallmentDisplayStatus.settled => const RDCustomerPaid(),
          };

    final po = switch (status) {
      RDInstallmentDisplayStatus.settled ||
      RDInstallmentDisplayStatus.paidFromPocket => RDPoStep.deposited,
      _ => RDPoStep.pending,
    };

    return RDHubTwoStepTrack(customer: customer, po: po);
  }

  /// Contextual caption descriptor below the card's footer actions, or `null` when calm.
  RDHubRowCaption? captionAt(DateTime now) {
    if (isCustomerPending) {
      if (totalFeeDue > 0 || hasPriorArrears) {
        return RDHubPendingChargesCaption(
          feeDue: totalFeeDue,
          priorOverdueCount: priorOverdueCount,
        );
      }
      final status = displayStatus(now);
      if (status == RDInstallmentDisplayStatus.partiallyPaid) {
        return RDHubPartialCaption(
          paid: installment.customerPaidAmount,
          due: installment.dueAmount,
        );
      }
      if (status == RDInstallmentDisplayStatus.paidFromPocket) {
        return const RDHubFromPocketCaption();
      }
      return null;
    }
    if (readyForPoCount > 0) {
      return RDHubReadyForPoCaption(count: readyForPoCount);
    }
    return null;
  }
}
