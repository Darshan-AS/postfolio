import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

/// The ledger brain: a pure, deterministic fold from facts to a passbook.
///
/// Model (mirrors how the Post Office and the DOP agent portal behave):
/// * **Both sides are sequential.** Customer money fills months in order; PO deposit events
///   cover the next N months in order. A month is never skipped.
/// * **One due amount per month** = installment + default fee − fee absorbed by the agent.
///   The fee is fixed at the PO deposit date once deposited, otherwise estimated as of [asOf].
/// * **Money is never dropped.** Customer payments first repay the opening receivable, then
///   months in order (a partial lands on the earliest open month); anything beyond the
///   schedule becomes credit.
/// * **Agent float.** Collected-but-undeposited money is cash in hand (split cash/digital);
///   deposited-but-uncollected money is a receivable from the customer.
final class RDLedgerProjector {
  const RDLedgerProjector({this.rules = RDLedgerRules.standard});

  final RDLedgerRules rules;

  static const standard = RDLedgerProjector();

  RDLedgerProjection project(RDLedgerFacts facts, {required DateTime asOf}) {
    final deposit = facts.deposit;
    final asOfDay = asOf.toDateOnly();
    final n = deposit.totalMonths;
    final baselineCount = deposit.initialPaidInstallments.clamp(0, n);
    final warnings = <String>[];

    if (n <= 0) {
      return RDLedgerProjection(
        asOf: asOfDay,
        installments: const [],
        allocationsByTransaction: const {},
        summary: RDLedgerSummary.pristine(deposit, asOfDay),
        poReadiness: const RDPoReadiness(),
      );
    }

    final schedule = RDScheduleFactory.baselineSchedule(deposit, rules: rules);
    final amountP = Money.toPaise(deposit.installmentAmount);

    // --- PO side: sequential events ------------------------------------------------------
    final depositedOn = List<DateTime?>.filled(n + 1, null);
    final batchOf = List<String?>.filled(n + 1, null);
    var depositedThrough = baselineCount;
    for (final ev in facts.poDepositsInOrder) {
      for (var k = 0; k < ev.installmentCount; k++) {
        if (depositedThrough >= n) {
          warnings.add('PO deposit ${ev.id} exceeds the schedule; extra installments ignored');
          break;
        }
        depositedThrough++;
        depositedOn[depositedThrough] = ev.depositedOn.toDateOnly();
        batchOf[depositedThrough] = ev.batchId;
      }
    }

    // --- Per-month fees ---------------------------------------------------------------------
    // poFee: what the counter charges (fixed at deposit date, else estimated as of asOf).
    // customerFee: what the customer owes — fixed on the day they finish paying the month,
    //              or at the PO deposit date if the agent fronted it first.
    final poFeeP = List<int>.filled(n + 1, 0);
    final absorbedP = List<int>.filled(n + 1, 0);
    for (final a in facts.absorptions) {
      if (a.installmentNo >= 1 && a.installmentNo <= n) {
        absorbedP[a.installmentNo] += Money.toPaise(a.amount);
      } else {
        warnings.add('Fee absorption for #${a.installmentNo} is outside the schedule');
      }
    }
    int feeAt(int no, DateTime day) => Money.toPaise(rules.defaultFeeFor(
        deposit.installmentAmount, rules.defaultedMonths(schedule[no - 1].dueDate, day)));
    for (var no = baselineCount + 1; no <= n; no++) {
      poFeeP[no] = feeAt(no, depositedOn[no] ?? asOfDay);
    }

    // --- Customer side: sequential allocation ---------------------------------------------
    final paidP = List<int>.filled(n + 1, 0);
    final customerFeeP = List<int>.filled(n + 1, 0);
    final settledAt = List<bool>.filled(n + 1, false);
    for (var no = 1; no <= baselineCount; no++) {
      paidP[no] = amountP;
      settledAt[no] = true;
    }
    var openingLeft = Money.toPaise(deposit.openingReceivable);
    var creditP = 0;
    var cashInHandCash = 0;
    var cashInHandDigital = 0;
    var pointer = baselineCount + 1;
    final allocations = <String, List<RDAllocationSlice>>{};

    int customerDueAt(int no, DateTime day) {
      final d = depositedOn[no];
      final feeDay = (d != null && d.isBefore(day)) ? d : day;
      final fee = feeAt(no, feeDay);
      final absorbed = absorbedP[no] > fee ? fee : absorbedP[no];
      return amountP + fee - absorbed;
    }

    final txs = [...facts.transactions]..sort(_chronological);
    for (final tx in txs) {
      final day = tx.paidDate.toDateOnly();
      var pool = Money.toPaise(tx.amount);
      final slices = <RDAllocationSlice>[];

      if (openingLeft > 0 && pool > 0) {
        final r = pool < openingLeft ? pool : openingLeft;
        openingLeft -= r;
        pool -= r;
        slices.add(RDAllocationSlice(installmentNo: 0, amount: Money.toRupees(r)));
      }

      while (pool > 0 && pointer <= n) {
        final due = customerDueAt(pointer, day);
        final need = due - paidP[pointer];
        if (need <= 0) {
          pointer++;
          continue;
        }
        final applied = pool < need ? pool : need;
        paidP[pointer] += applied;
        pool -= applied;
        slices.add(RDAllocationSlice(installmentNo: pointer, amount: Money.toRupees(applied)));
        if (depositedOn[pointer] == null) {
          if (tx.paymentMode.isCash) {
            cashInHandCash += applied;
          } else {
            cashInHandDigital += applied;
          }
        }
        if (paidP[pointer] >= due) {
          settledAt[pointer] = true;
          final d = depositedOn[pointer];
          customerFeeP[pointer] = feeAt(pointer, (d != null && d.isBefore(day)) ? d : day);
          pointer++;
        }
      }

      if (pool > 0) {
        creditP += pool;
        if (tx.paymentMode.isCash) {
          cashInHandCash += pool;
        } else {
          cashInHandDigital += pool;
        }
        slices.add(RDAllocationSlice(installmentNo: 0, amount: Money.toRupees(pool), isCredit: true));
      }
      allocations[tx.id] = slices;
    }

    // Unsettled months keep accruing until the PO deposit date (or today).
    for (var no = baselineCount + 1; no <= n; no++) {
      if (!settledAt[no]) customerFeeP[no] = feeAt(no, depositedOn[no] ?? asOfDay);
      if (absorbedP[no] > customerFeeP[no]) absorbedP[no] = customerFeeP[no];
    }
    int dueOf(int no) => amountP + customerFeeP[no] - absorbedP[no];

    // --- Materialise -------------------------------------------------------------------
    final installments = <RDInstallment>[];
    final openItems = <RDOpenItem>[];
    var paidThrough = baselineCount;
    var consecutive = true;
    int? nextDueNo;
    var receivableP = openingLeft;
    var owedP = openingLeft;
    var feeDueP = 0;
    var absorbedTotal = 0;
    var delayCost = 0;
    var arrears = 0;

    for (var no = 1; no <= n; no++) {
      final base = schedule[no - 1];
      if (base.isOpeningBaseline) {
        installments.add(base);
        continue;
      }
      final inst = base.copyWith(
        lateFee: Money.toRupees(customerFeeP[no]),
        poLateFee: Money.toRupees(poFeeP[no]),
        absorbedFee: Money.toRupees(absorbedP[no]),
        customerPaidAmount: Money.toRupees(paidP[no]),
        poDepositedOn: depositedOn[no],
        poBatchId: batchOf[no],
      );
      installments.add(inst);

      final settled = paidP[no] >= dueOf(no);
      if (consecutive && settled) {
        paidThrough = no;
      } else {
        consecutive = false;
      }
      nextDueNo ??= settled ? null : no;

      final outstanding = dueOf(no) - paidP[no];
      final isDeposited = depositedOn[no] != null;
      final isPastDue = base.dueDate.isBefore(asOfDay);
      if (!settled && isDeposited) receivableP += outstanding;
      if (!settled && (isDeposited || isPastDue)) {
        owedP += outstanding;
        final feePart = customerFeeP[no] - absorbedP[no];
        feeDueP += feePart < outstanding ? feePart : outstanding;
      }
      if (!settled && isPastDue) arrears++;
      absorbedTotal += absorbedP[no];
      if (isDeposited && poFeeP[no] > customerFeeP[no]) {
        delayCost += poFeeP[no] - customerFeeP[no];
      }

      if (paidP[no] > 0 || isDeposited || absorbedP[no] > 0) {
        openItems.add(RDOpenItem(
          installmentNo: no,
          paid: Money.toRupees(paidP[no]),
          customerFee: Money.toRupees(customerFeeP[no]),
          isSettled: settled,
          poFee: isDeposited ? Money.toRupees(poFeeP[no]) : 0.0,
          absorbedFee: Money.toRupees(absorbedP[no]),
          poDepositedOn: depositedOn[no],
          poBatchId: batchOf[no],
        ));
      }
    }
    owedP = (owedP - creditP).clamp(0, 1 << 62);

    // --- What the next PO visit can carry ------------------------------------------------
    var readyCount = 0;
    var readyAmount = 0;
    var readyFee = 0;
    for (var no = depositedThrough + 1; no <= n; no++) {
      if (paidP[no] < dueOf(no)) break;
      readyCount++;
      readyAmount += amountP + poFeeP[no];
      readyFee += poFeeP[no];
    }
    final nextUndeposited = depositedThrough < n ? depositedThrough + 1 : null;
    final partialShortfall = (nextUndeposited != null && readyCount == 0)
        ? (dueOf(nextUndeposited) - paidP[nextUndeposited]).clamp(0, 1 << 62)
        : 0;

    final summary = RDLedgerSummary(
      rdId: deposit.id,
      factsVersion: facts.version,
      projectedOn: asOfDay,
      paidThroughNo: paidThrough,
      depositedThroughNo: depositedThrough,
      nextDueNo: nextDueNo,
      customerCredit: Money.toRupees(creditP),
      openingReceivableLeft: Money.toRupees(openingLeft),
      owedByCustomer: Money.toRupees(owedP),
      receivable: Money.toRupees(receivableP),
      cashInHandCash: Money.toRupees(cashInHandCash),
      cashInHandDigital: Money.toRupees(cashInHandDigital),
      absorbedTotal: Money.toRupees(absorbedTotal),
      delayCostTotal: Money.toRupees(delayCost),
      arrearsCount: arrears,
      feeDue: Money.toRupees(feeDueP),
      openItems: openItems,
    );

    return RDLedgerProjection(
      asOf: asOfDay,
      installments: installments,
      allocationsByTransaction: allocations,
      summary: summary,
      poReadiness: RDPoReadiness(
        readyCount: readyCount,
        readyAmount: Money.toRupees(readyAmount),
        readyFee: Money.toRupees(readyFee),
        nextInstallmentNo: nextUndeposited,
        partialShortfall: Money.toRupees(partialShortfall),
      ),
      warnings: warnings,
    );
  }

  /// Amount (installment + fee) the PO will charge to deposit the next [count] months on
  /// [depositedOn], given the current facts. Used by the "Deposit next N" sheet.
  ({double amount, double fee}) quoteNextDeposit(
    RDLedgerFacts facts, {
    required int count,
    required DateTime depositedOn,
  }) {
    final deposit = facts.deposit;
    final n = deposit.totalMonths;
    var through = deposit.initialPaidInstallments.clamp(0, n);
    for (final ev in facts.poDepositsInOrder) {
      through = (through + ev.installmentCount).clamp(0, n);
    }
    var amount = 0;
    var fee = 0;
    final amountP = Money.toPaise(deposit.installmentAmount);
    for (var k = 0; k < count && through + 1 + k <= n; k++) {
      final no = through + 1 + k;
      final due = rules.dueDateFor(
          deposit.startDate, RDScheduleFactory.installmentDateFor(deposit.startDate, no));
      final f = Money.toPaise(
          rules.defaultFeeFor(deposit.installmentAmount, rules.defaultedMonths(due, depositedOn)));
      amount += amountP + f;
      fee += f;
    }
    return (amount: Money.toRupees(amount), fee: Money.toRupees(fee));
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
