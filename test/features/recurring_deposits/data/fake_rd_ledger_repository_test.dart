import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

void main() {
  const rdId = 'rd-1';
  RDTransaction tx(String id, {double amount = 1000}) => RDTransaction(
        id: id,
        rdId: rdId,
        paidDate: DateTime(2026, 1, 10),
        amount: amount,
        paymentMode: RDPaymentMode.cash,
      );
  RDLedgerSummary summary(String id) =>
      RDLedgerSummary(rdId: id, factsVersion: 1, projectedOn: DateTime(2026, 1, 10));

  group('FakeRDLedgerRepository', () {
    late FakeRDLedgerRepository repo;
    setUp(() => repo = FakeRDLedgerRepository());
    tearDown(() => repo.dispose());

    test('streams start with current facts and emit on every change', () async {
      final emissions = <int>[];
      final sub = repo.watchTransactions(rdId).listen((r) {
        if (r case Success(:final value)) emissions.add(value.length);
      });
      await Future<void>.delayed(Duration.zero);
      expect(await repo.addTransaction(tx('a')), isA<Success<void, String>>());
      expect(await repo.addTransaction(tx('b')), isA<Success<void, String>>());
      expect(
        await repo.applyChange(
          const RDLedgerChange(deleteTransactions: [(rdId: rdId, transactionId: 'a')]),
        ),
        isA<Success<void, String>>(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [0, 1, 2, 1]);
      await sub.cancel();
    });

    test('a re-sent payment replaces the stored one; a re-sent PO event changes nothing', () async {
      await repo.addTransaction(tx('a'));
      expect(await repo.addTransaction(tx('a', amount: 1500)), isA<Success<void, String>>());
      expect(repo.transactionsOf(rdId).single.amount, 1500, reason: 'payments are upserts by id');

      final d = RDPoDeposit(id: 'e1', rdId: rdId, depositedOn: DateTime(2026, 3, 1), installmentCount: 2);
      expect(await repo.addPoDeposit(d), isA<Success<void, String>>());
      expect(await repo.addPoDeposit(d.copyWith(installmentCount: 5)), isA<Success<void, String>>());
      expect(repo.poDepositsOf(rdId).single.installmentCount, 2,
          reason: 'a PO event is a fact: an id that exists is left alone');

      expect(
        await repo.applyChange(
          const RDLedgerChange(deletePoDeposits: [(rdId: rdId, eventId: 'e1')]),
        ),
        isA<Success<void, String>>(),
      );
      expect(repo.poDepositsOf(rdId), isEmpty);
      expect(
        await repo.applyChange(
          const RDLedgerChange(deletePoDeposits: [(rdId: rdId, eventId: 'e1')]),
        ),
        isA<Success<void, String>>(),
        reason: 'deleting something already gone is not an error',
      );
    });

    test('fee absorptions upsert per month and remove', () async {
      final a = RDFeeAbsorption(rdId: rdId, installmentNo: 2, amount: 10, absorbedOn: DateTime(2026, 2, 1));
      expect(await repo.upsertFeeAbsorption(a), isA<Success<void, String>>());
      expect(await repo.upsertFeeAbsorption(a.copyWith(amount: 20)), isA<Success<void, String>>());
      expect(repo.absorptionsOf(rdId).single.amount, 20);
      expect(
        await repo.applyChange(
          const RDLedgerChange(deleteFeeAbsorptions: [(rdId: rdId, installmentNo: 2)]),
        ),
        isA<Success<void, String>>(),
      );
      expect(repo.absorptionsOf(rdId), isEmpty);
    });

    test('fetchPoDepositsByBatch returns every event of one visit, across accounts', () async {
      await repo.addPoDeposit(RDPoDeposit(
        id: 'b1',
        rdId: 'rd-1',
        depositedOn: DateTime(2026, 3, 1),
        installmentCount: 1,
        batchId: 'batch-1',
      ));
      await repo.addPoDeposit(RDPoDeposit(
        id: 'b2',
        rdId: 'rd-2',
        depositedOn: DateTime(2026, 3, 1),
        installmentCount: 1,
        batchId: 'batch-1',
      ));
      await repo.addPoDeposit(RDPoDeposit(
        id: 'later',
        rdId: 'rd-2',
        depositedOn: DateTime(2026, 3, 15),
        installmentCount: 1,
      ));

      final events = await repo.fetchPoDepositsByBatch('batch-1');
      expect((events as Success<List<RDPoDeposit>, String>).value.map((e) => e.id), {'b1', 'b2'});
    });

    test('a change and its summaries are stored together or not at all', () async {
      repo.failSummaryWith = 'summary rejected';
      final refused = await repo.applyChange(
        RDLedgerChange(upsertTransactions: [tx('a')]),
        summaries: [summary(rdId)],
      );
      expect(refused, isA<Failure<void, String>>());
      expect(repo.transactionsOf(rdId), isEmpty, reason: 'the payment must not be stored alone');
      expect(repo.summaryOf(rdId), isNull);

      repo.failSummaryWith = null;
      final stored = await repo.applyChange(
        RDLedgerChange(upsertTransactions: [tx('a')]),
        summaries: [summary(rdId)],
      );
      expect(stored, isA<Success<void, String>>());
      expect(repo.transactionsOf(rdId), hasLength(1));
      expect(repo.summaryOf(rdId), isNotNull);
    });

    test('failWith turns every write into a Failure', () async {
      repo.failWith = 'offline';
      final r = await repo.addTransaction(tx('a'));
      expect(r, isA<Failure<void, String>>());
      expect((r as Failure).error, 'offline');
      expect(repo.transactionsOf(rdId), isEmpty);
    });
  });
}
