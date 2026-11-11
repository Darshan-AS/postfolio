import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

void main() {
  const rdId = 'rd-1';
  RDTransaction tx(String id) => RDTransaction(
        id: id,
        rdId: rdId,
        paidDate: DateTime(2026, 1, 10),
        amount: 1000,
        paymentMode: RDPaymentMode.cash,
      );

  group('FakeRDLedgerRepository', () {
    late FakeRDLedgerRepository repo;
    setUp(() => repo = FakeRDLedgerRepository());
    tearDown(() => repo.dispose());

    test('streams start with current facts and emit on every write', () async {
      final emissions = <int>[];
      final sub = repo.watchTransactions(rdId).listen((r) {
        if (r case Success(:final value)) emissions.add(value.length);
      });
      await Future<void>.delayed(Duration.zero);
      expect(await repo.addTransaction(tx('a')), isA<Success<void, String>>());
      expect(await repo.addTransaction(tx('b')), isA<Success<void, String>>());
      expect(await repo.deleteTransaction(rdId: rdId, transactionId: 'a'),
          isA<Success<void, String>>());
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [0, 1, 2, 1]);
      await sub.cancel();
    });

    test('duplicate transaction id and duplicate PO event id are rejected', () async {
      await repo.addTransaction(tx('a'));
      expect(await repo.addTransaction(tx('a')), isA<Failure<void, String>>());

      final d = RDPoDeposit(id: 'e1', rdId: rdId, depositedOn: DateTime(2026, 3, 1), installmentCount: 2);
      expect(await repo.addPoDeposit(d), isA<Success<void, String>>());
      expect(await repo.addPoDeposit(d), isA<Failure<void, String>>());
      expect(repo.poDepositsOf(rdId), hasLength(1));
      expect(await repo.deletePoDeposit(rdId: rdId, eventId: 'e1'), isA<Success<void, String>>());
      expect(repo.poDepositsOf(rdId), isEmpty);
    });

    test('fee absorptions upsert per month and remove', () async {
      final a = RDFeeAbsorption(rdId: rdId, installmentNo: 2, amount: 10, absorbedOn: DateTime(2026, 2, 1));
      expect(await repo.upsertFeeAbsorption(a), isA<Success<void, String>>());
      expect(await repo.upsertFeeAbsorption(a.copyWith(amount: 20)), isA<Success<void, String>>());
      expect(repo.absorptionsOf(rdId).single.amount, 20);
      expect(await repo.removeFeeAbsorption(rdId: rdId, installmentNo: 2),
          isA<Success<void, String>>());
      expect(repo.absorptionsOf(rdId), isEmpty);
    });

    test('deletePoDepositBatch returns affected RDs and blocks out-of-order batch undo', () async {
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

      final blocked = await repo.deletePoDepositBatch('batch-1');
      expect(blocked, isA<Failure<List<String>, String>>());
      expect(repo.poDepositsOf('rd-1'), hasLength(1), reason: 'atomic: rd-1 untouched when rd-2 blocks');
      expect(repo.poDepositsOf('rd-2'), hasLength(2));

      await repo.deletePoDeposit(rdId: 'rd-2', eventId: 'later');
      final ok = await repo.deletePoDepositBatch('batch-1');
      expect(ok, isA<Success<List<String>, String>>());
      expect((ok as Success<List<String>, String>).value, containsAll(['rd-1', 'rd-2']));
      expect(repo.poDepositsOf('rd-1'), isEmpty);
      expect(repo.poDepositsOf('rd-2'), isEmpty);
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
