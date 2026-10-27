import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
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

    test('duplicate transaction id and duplicate PO month are rejected', () async {
      await repo.addTransaction(tx('a'));
      expect(await repo.addTransaction(tx('a')), isA<Failure<void, String>>());

      final d = RDPoDeposit(rdId: rdId, installmentNo: 3, depositedOn: DateTime(2026, 3, 1));
      expect(await repo.addPoDeposits([d]), isA<Success<void, String>>());
      expect(await repo.addPoDeposits([d]), isA<Failure<void, String>>());
      expect(repo.poDepositsOf(rdId), hasLength(1));
    });

    test('waivers add and remove', () async {
      final w = RDFeeWaiver(rdId: rdId, installmentNo: 2, waivedOn: DateTime(2026, 2, 1));
      expect(await repo.addFeeWaiver(w), isA<Success<void, String>>());
      expect(repo.waiversOf(rdId), hasLength(1));
      expect(await repo.removeFeeWaiver(rdId: rdId, installmentNo: 2),
          isA<Success<void, String>>());
      expect(repo.waiversOf(rdId), isEmpty);
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
