import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

RecurringDeposit _deposit(String id) => RecurringDeposit(
      id: id,
      customerId: 'c1',
      schemeType: RecurringSchemeType.recurringDeposit,
      status: DepositStatus.active,
      installmentAmount: 1000,
      interestRate: 6.7,
      termYears: 5,
      termMonths: 0,
      startDate: DateTime(2026, 1, 10),
    );

RDTransaction _tx(String id, double amount, {String rdId = 'rd1', DateTime? createdAt}) =>
    RDTransaction(
      id: id,
      rdId: rdId,
      paidDate: DateTime(2026, 1, 10),
      amount: amount,
      paymentMode: RDPaymentMode.cash,
      createdAt: createdAt,
    );

RDPoDeposit _po(String id, int count, {String rdId = 'rd1'}) => RDPoDeposit(
      id: id,
      rdId: rdId,
      depositedOn: DateTime(2026, 2, 1),
      installmentCount: count,
      amount: count * 1000.0,
    );

RDFeeAbsorption _absorb(int no, double amount, {String rdId = 'rd1'}) => RDFeeAbsorption(
      rdId: rdId,
      installmentNo: no,
      amount: amount,
      absorbedOn: DateTime(2026, 3, 1),
    );

void main() {
  final stored = DateTime(2026, 1, 10, 9);
  final facts = RDLedgerFacts(
    deposit: _deposit('rd1'),
    transactions: [_tx('t1', 1000, createdAt: stored), _tx('t2', 500)],
    poDeposits: [_po('e1', 1)],
    absorptions: [_absorb(2, 10)],
  );

  group('RDLedgerChange.applyTo', () {
    test('an empty change leaves the facts as they are', () {
      const change = RDLedgerChange();
      expect(change.isEmpty, isTrue);
      expect(change.applyTo(facts), facts);
    });

    test('a new payment is appended; an existing one is replaced and keeps its stored timestamp', () {
      final after = RDLedgerChange(
        upsertTransactions: [_tx('t3', 250), _tx('t1', 1200)],
      ).applyTo(facts);

      expect(after.transactions.map((t) => t.id), ['t1', 't2', 't3']);
      expect(after.transactions.first.amount, 1200);
      expect(after.transactions.first.createdAt, stored,
          reason: 'ordering within a day depends on when the payment was first stored');
    });

    test('deletes remove payments, PO events and absorptions by identity', () {
      final after = const RDLedgerChange(
        deleteTransactions: [(rdId: 'rd1', transactionId: 't2')],
        deletePoDeposits: [(rdId: 'rd1', eventId: 'e1')],
        deleteFeeAbsorptions: [(rdId: 'rd1', installmentNo: 2)],
      ).applyTo(facts);

      expect(after.transactions.map((t) => t.id), ['t1']);
      expect(after.poDeposits, isEmpty);
      expect(after.absorptions, isEmpty);
    });

    test('a PO event that is already stored is not added again', () {
      final after = RDLedgerChange(
        insertPoDeposits: [_po('e1', 3), _po('e2', 2)],
      ).applyTo(facts);

      expect(after.poDeposits.map((e) => e.id), ['e1', 'e2']);
      expect(after.poDeposits.first.installmentCount, 1,
          reason: 'PO events are facts: inserting an existing id changes nothing');
    });

    test('an absorption replaces the one already recorded for that month', () {
      final after = RDLedgerChange(
        upsertFeeAbsorptions: [_absorb(2, 30), _absorb(3, 10)],
      ).applyTo(facts);

      expect({for (final a in after.absorptions) a.installmentNo: a.amount}, {2: 30.0, 3: 10.0});
    });

    test('parts addressed to another account are ignored', () {
      final change = RDLedgerChange(
        upsertTransactions: [_tx('x1', 999, rdId: 'rd2')],
        insertPoDeposits: [_po('y1', 4, rdId: 'rd2')],
        upsertFeeAbsorptions: [_absorb(1, 5, rdId: 'rd2')],
        deleteTransactions: const [(rdId: 'rd2', transactionId: 't1')],
      );

      expect(change.applyTo(facts), facts);
      expect(change.rdIds, {'rd2'});
    });

    test('applying a change twice gives the same facts as applying it once', () {
      final change = RDLedgerChange(
        upsertTransactions: [_tx('t3', 250), _tx('t1', 1200)],
        insertPoDeposits: [_po('e2', 2)],
        upsertFeeAbsorptions: [_absorb(3, 10)],
        deleteTransactions: const [(rdId: 'rd1', transactionId: 't2')],
      );

      final once = change.applyTo(facts);
      expect(change.applyTo(once), once, reason: 'a re-sent change must be harmless');
    });

    test('rdIds lists every account the change touches', () {
      final change = RDLedgerChange(
        upsertTransactions: [_tx('a', 1)],
        insertPoDeposits: [_po('b', 1, rdId: 'rd2')],
        deleteFeeAbsorptions: const [(rdId: 'rd3', installmentNo: 1)],
      );
      expect(change.rdIds, {'rd1', 'rd2', 'rd3'});
      expect(change.isEmpty, isFalse);
    });
  });
}
