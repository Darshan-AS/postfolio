import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_payment_allocation_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:uuid/uuid.dart';

/// The ledger brain: a pure, deterministic fold from facts to a fully derived schedule.
///
/// Guarantees:
/// * **One path.** Preview, record, edit and delete all call [project]; there is no separate
///   "live" allocator, so what the agent previews is exactly what later re-projection shows.
/// * **Money in paise.** All arithmetic is on integers; doubles only appear at the boundary.
/// * **Calendar days.** `paidDate` and `asOf` are truncated to dates before any comparison.
/// * **Fees accrue until settlement.** A month's default fee grows every month until its
///   principal is cleared, then freezes at the settlement date.
/// * **Money is never dropped.** Anything that cannot be allocated becomes `customerCredit`.
final class RDLedgerProjector {
  const RDLedgerProjector({this.rules = RDLedgerRules.standard});

  final RDLedgerRules rules;

  static const standard = RDLedgerProjector();

  RDLedgerProjection project(RDLedgerFacts facts, {required DateTime asOf}) {
    final deposit = facts.deposit;
    final asOfDay = asOf.toDateOnly();
    final n = deposit.totalMonths;
    final warnings = <String>[];

    if (n <= 0) {
      return RDLedgerProjection(
        asOf: asOfDay,
        installments: const [],
        allocationsByTransaction: const {},
        customerCredit: 0.0,
        summary: RDLedgerSummary.pristine(deposit, asOfDay),
      );
    }

    final schedule = RDScheduleFactory.baselineSchedule(deposit, rules: rules);
    final amountPaise = Money.toPaise(deposit.installmentAmount);

    // Mutable working state (1-based index; slot 0 unused).
    final paidP = List<int>.filled(n + 1, 0);
    final paidF = List<int>.filled(n + 1, 0);
    final feeP = List<int>.filled(n + 1, 0);
    final settledOn = List<DateTime?>.filled(n + 1, null);
    final waived = List<bool>.filled(n + 1, false);
    final poByNo = <int, RDPoDeposit>{};

    for (var no = 1; no <= deposit.initialPaidInstallments && no <= n; no++) {
      paidP[no] = amountPaise;
      settledOn[no] = schedule[no - 1].dueDate;
    }
    for (final RDFeeWaiver w in facts.waivers) {
      if (w.installmentNo >= 1 && w.installmentNo <= n) {
        waived[w.installmentNo] = true;
      } else {
        warnings.add('Waiver for installment #${w.installmentNo} is outside the schedule');
      }
    }
    for (final RDPoDeposit d in facts.poDeposits) {
      if (d.installmentNo >= 1 && d.installmentNo <= n) {
        poByNo[d.installmentNo] = d;
      } else {
        warnings.add('PO deposit for installment #${d.installmentNo} is outside the schedule');
      }
    }

    void accrueFees(DateTime day) {
      for (var no = 1; no <= n; no++) {
        if (paidP[no] >= amountPaise) continue;
        final due = schedule[no - 1].dueDate;
        final months = rules.defaultedMonths(due, day);
        if (months == 0) continue;
        final fee = Money.toPaise(rules.defaultFeeFor(deposit.installmentAmount, months));
        if (fee > feeP[no]) feeP[no] = fee;
      }
    }

    final allocationsByTx = <String, List<RDPaymentAllocation>>{};
    var creditPaise = 0;

    final txs = [...facts.transactions]..sort(_chronological);
    for (final tx in txs) {
      final day = tx.paidDate.toDateOnly();
      accrueFees(day);

      final (principalPool, feePool, mode) = _resolvePools(
        tx,
        amountPaise: amountPaise,
        pendingFeesPaise: _pendingFees(n, feeP, paidF, waived),
      );

      final perMonth = <int, ({int principal, int fee})>{};

      int allocatePrincipal(int pool) {
        var remaining = pool;
        for (var no = 1; no <= n && remaining > 0; no++) {
          final needed = amountPaise - paidP[no];
          if (needed <= 0) continue;
          final applied = remaining >= needed ? needed : remaining;
          paidP[no] += applied;
          remaining -= applied;
          if (paidP[no] >= amountPaise) settledOn[no] = day;
          final prev = perMonth[no] ?? (principal: 0, fee: 0);
          perMonth[no] = (principal: prev.principal + applied, fee: prev.fee);
        }
        return remaining;
      }

      int allocateFees(int pool) {
        var remaining = pool;
        for (var no = 1; no <= n && remaining > 0; no++) {
          if (waived[no]) continue;
          final needed = feeP[no] - paidF[no];
          if (needed <= 0) continue;
          final applied = remaining >= needed ? needed : remaining;
          paidF[no] += applied;
          remaining -= applied;
          final prev = perMonth[no] ?? (principal: 0, fee: 0);
          perMonth[no] = (principal: prev.principal, fee: prev.fee + applied);
        }
        return remaining;
      }

      var principalLeft = allocatePrincipal(principalPool);
      var feeLeft = allocateFees(feePool);

      // Overflow: never let money sit idle while the other bucket is still owed,
      // unless the agent explicitly restricted the payment to one bucket.
      if (feeLeft > 0 && mode != PaymentSplitMode.feesOnly) {
        feeLeft = allocatePrincipal(feeLeft);
      }
      if (principalLeft > 0 && mode != PaymentSplitMode.installmentsOnly) {
        principalLeft = allocateFees(principalLeft);
      }
      creditPaise += principalLeft + feeLeft;

      final nos = perMonth.keys.toList()..sort();
      allocationsByTx[tx.id] = [
        for (final no in nos)
          RDPaymentAllocation(
            id: const Uuid().v5(Namespace.url.value, 'postfolio:tx:${tx.id}:inst:$no'),
            transactionId: tx.id,
            rdId: deposit.id,
            installmentNo: no,
            principalAmount: Money.toRupees(perMonth[no]!.principal),
            lateFeeAmount: Money.toRupees(perMonth[no]!.fee),
          ),
      ];
    }

    // Fees keep accruing on anything still unpaid up to the evaluation day.
    accrueFees(asOfDay);

    // Materialise the read model.
    final installments = <RDInstallment>[];
    final openItems = <RDOpenItem>[];
    var paidThroughNo = 0;
    var consecutive = true;
    int? nextDueNo;
    var cashInHandPaise = 0;
    var pocketAdvancePaise = 0;

    for (var no = 1; no <= n; no++) {
      final base = schedule[no - 1];
      final po = poByNo[no];
      final isBaseline = base.isOpeningBaseline;
      final principalPaid = paidP[no] >= amountPaise;
      final isDeposited = isBaseline || po != null;
      final feeOutstanding = !waived[no] && feeP[no] > paidF[no];

      final status = paidP[no] <= 0
          ? RDInstallmentStatus.unpaid
          : (principalPaid
              ? RDInstallmentStatus.fullyPaid
              : RDInstallmentStatus.partiallyPaid);

      installments.add(base.copyWith(
        customerPaidAmount: Money.toRupees(paidP[no]),
        customerStatus: status,
        poStatus: isDeposited ? RDPoStatus.paid : RDPoStatus.unpaid,
        poPaidDate: isBaseline ? base.dueDate : po?.depositedOn,
        poBatchId: po?.batchId,
        lateFee: Money.toRupees(feeP[no]),
        paidLateFee: Money.toRupees(paidF[no]),
        isLateFeeWaived: waived[no],
      ));

      if (consecutive && principalPaid) {
        paidThroughNo = no;
      } else {
        consecutive = false;
      }
      if (nextDueNo == null && (!principalPaid || feeOutstanding)) {
        nextDueNo = no;
      }

      if (!isBaseline) {
        final touched = paidP[no] > 0 || paidF[no] > 0 || po != null || waived[no] || feeP[no] > 0;
        if (touched) {
          openItems.add(RDOpenItem(
            installmentNo: no,
            paidPrincipal: Money.toRupees(paidP[no]),
            paidFee: Money.toRupees(paidF[no]),
            // Only freeze the fee once principal is settled; unpaid months stay dynamic.
            frozenLateFee: principalPaid ? Money.toRupees(feeP[no]) : 0.0,
            isWaived: waived[no],
            poDepositedOn: po?.depositedOn,
            poBatchId: po?.batchId,
          ));
        }
        if (po == null) {
          cashInHandPaise += paidP[no] + paidF[no];
        } else if (!principalPaid) {
          pocketAdvancePaise += amountPaise - paidP[no];
        }
      }
    }

    final summary = RDLedgerSummary(
      rdId: deposit.id,
      factsVersion: facts.version,
      projectedOn: asOfDay,
      paidThroughNo: paidThroughNo,
      nextDueNo: nextDueNo,
      customerCredit: Money.toRupees(creditPaise),
      cashInHand: Money.toRupees(cashInHandPaise),
      pocketAdvance: Money.toRupees(pocketAdvancePaise),
      openItems: openItems,
    );

    return RDLedgerProjection(
      asOf: asOfDay,
      installments: installments,
      allocationsByTransaction: allocationsByTx,
      customerCredit: Money.toRupees(creditPaise),
      summary: summary,
      warnings: warnings,
    );
  }

  /// Validates a transaction's explicit split against its amount.
  /// Returns null when valid, otherwise a human-readable reason.
  static String? validateSplit(RDTransaction tx) {
    if (tx.splitMode != PaymentSplitMode.custom) return null;
    final total = Money.toPaise(tx.installmentAmount) + Money.toPaise(tx.lateFeeAmount);
    if (total != Money.toPaise(tx.amount)) {
      return 'Custom split (${tx.installmentAmount} + ${tx.lateFeeAmount}) must equal the amount ${tx.amount}';
    }
    return null;
  }

  // --- helpers -----------------------------------------------------------------------------

  static int _pendingFees(int n, List<int> feeP, List<int> paidF, List<bool> waived) {
    var sum = 0;
    for (var no = 1; no <= n; no++) {
      if (waived[no]) continue;
      final due = feeP[no] - paidF[no];
      if (due > 0) sum += due;
    }
    return sum;
  }

  /// Resolves `(principalPool, feePool, effectiveMode)` in paise.
  static (int, int, PaymentSplitMode) _resolvePools(
    RDTransaction tx, {
    required int amountPaise,
    required int pendingFeesPaise,
  }) {
    final total = Money.toPaise(tx.amount);
    final instComp = Money.toPaise(tx.installmentAmount);
    final feeComp = Money.toPaise(tx.lateFeeAmount);
    final hasExplicitComponents =
        (instComp > 0 || feeComp > 0) && instComp + feeComp == total;

    switch (tx.splitMode) {
      case PaymentSplitMode.installmentsOnly:
        return (total, 0, tx.splitMode);
      case PaymentSplitMode.feesOnly:
        return (0, total, tx.splitMode);
      case PaymentSplitMode.custom:
        if (hasExplicitComponents) return (instComp, feeComp, tx.splitMode);
        // Mismatched custom split: honour the fee component, send the rest to principal
        // so no rupee is lost. (Validated upstream; this is a safety net.)
        final fee = feeComp.clamp(0, total);
        return (total - fee, fee, tx.splitMode);
      case PaymentSplitMode.includeFees:
        if (hasExplicitComponents) return (instComp, feeComp, tx.splitMode);
        final (principal, fee) = _autoSplit(total, amountPaise, pendingFeesPaise);
        return (principal, fee, tx.splitMode);
    }
  }

  /// Heuristic for an unannotated payment: whole installment multiples clear principal;
  /// the remainder (capped at pending fees) clears fees. Small payments go to fees first.
  static (int, int) _autoSplit(int total, int amountPaise, int pendingFees) {
    if (pendingFees <= 0 || amountPaise <= 0) return (total, 0);
    if (total >= amountPaise) {
      final whole = (total ~/ amountPaise) * amountPaise;
      final remainder = total - whole;
      final fee = remainder.clamp(0, pendingFees);
      return (total - fee, fee);
    }
    final fee = total.clamp(0, pendingFees);
    return (total - fee, fee);
  }

  static int _chronological(RDTransaction a, RDTransaction b) {
    final byDay = a.paidDate.toDateOnly().compareTo(b.paidDate.toDateOnly());
    if (byDay != 0) return byDay;
    if (a.createdAt != null && b.createdAt != null) {
      final byCreated = a.createdAt!.compareTo(b.createdAt!);
      if (byCreated != 0) return byCreated;
    }
    return a.id.compareTo(b.id);
  }
}
