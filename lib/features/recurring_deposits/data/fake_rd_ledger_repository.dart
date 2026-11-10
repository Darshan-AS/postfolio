import 'dart:async';

import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

/// In-memory facts store for demo mode and tests.
///
/// Deliberately has **no** ledger logic: it stores lists and re-emits them. All behaviour
/// comes from `RDLedgerProjector`, so the fake cannot drift from production.
class FakeRDLedgerRepository implements RDLedgerRepository {
  FakeRDLedgerRepository({
    Map<String, List<RDTransaction>>? transactions,
    Map<String, List<RDPoDeposit>>? poDeposits,
    Map<String, List<RDFeeAbsorption>>? absorptions,
    this.failWith,
  })  : _transactions = {for (final e in (transactions ?? {}).entries) e.key: [...e.value]},
        _poDeposits = {for (final e in (poDeposits ?? {}).entries) e.key: [...e.value]},
        _absorptions = {for (final e in (absorptions ?? {}).entries) e.key: [...e.value]};

  /// When set, every write fails with this message (for error-path tests).
  String? failWith;

  final Map<String, List<RDTransaction>> _transactions;
  final Map<String, List<RDPoDeposit>> _poDeposits;
  final Map<String, List<RDFeeAbsorption>> _absorptions;
  final Map<String, RDLedgerSummary> _summaries = {};

  final _txControllers = <String, StreamController<Result<List<RDTransaction>, String>>>{};
  final _poControllers = <String, StreamController<Result<List<RDPoDeposit>, String>>>{};
  final _absorptionControllers = <String, StreamController<Result<List<RDFeeAbsorption>, String>>>{};
  final _summaryController =
      StreamController<Result<List<RDLedgerSummary>, String>>.broadcast();

  // --- Test inspection ----------------------------------------------------------------------
  List<RDTransaction> transactionsOf(String rdId) => List.unmodifiable(_transactions[rdId] ?? const []);
  List<RDPoDeposit> poDepositsOf(String rdId) => List.unmodifiable(_poDeposits[rdId] ?? const []);
  List<RDFeeAbsorption> absorptionsOf(String rdId) => List.unmodifiable(_absorptions[rdId] ?? const []);
  RDLedgerSummary? summaryOf(String rdId) => _summaries[rdId];

  // --- Reads --------------------------------------------------------------------------------

  @override
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId) =>
      _watch(_txControllers, rdId, () => _transactions[rdId] ?? const []);

  @override
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId) =>
      _watch(_poControllers, rdId, () => _poDeposits[rdId] ?? const []);

  @override
  Stream<Result<List<RDFeeAbsorption>, String>> watchFeeAbsorptions(String rdId) =>
      _watch(_absorptionControllers, rdId, () => _absorptions[rdId] ?? const []);

  @override
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries() async* {
    yield Success(_summaries.values.toList(growable: false));
    yield* _summaryController.stream;
  }

  // --- Writes -------------------------------------------------------------------------------

  @override
  Future<Result<void, String>> upsertSummary(RDLedgerSummary summary) async {
    if (failWith != null) return Failure(failWith!);
    _summaries[summary.rdId] = summary;
    _summaryController.add(Success(_summaries.values.toList(growable: false)));
    return const Success(null);
  }

  @override
  Future<Result<void, String>> addTransaction(RDTransaction transaction) async {
    if (failWith != null) return Failure(failWith!);
    final list = _transactions.putIfAbsent(transaction.rdId, () => []);
    if (list.any((t) => t.id == transaction.id)) {
      return const Failure('This payment has already been recorded.');
    }
    list.add(transaction.copyWith(createdAt: transaction.createdAt ?? DateTime.now()));
    _emitTx(transaction.rdId);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateTransaction(RDTransaction transaction) async {
    if (failWith != null) return Failure(failWith!);
    final list = _transactions[transaction.rdId];
    final idx = list?.indexWhere((t) => t.id == transaction.id) ?? -1;
    if (list == null || idx < 0) return const Failure('Payment not found.');
    list[idx] = transaction.copyWith(createdAt: list[idx].createdAt);
    _emitTx(transaction.rdId);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> deleteTransaction({
    required String rdId,
    required String transactionId,
  }) async {
    if (failWith != null) return Failure(failWith!);
    final list = _transactions[rdId];
    if (list == null || !list.any((t) => t.id == transactionId)) {
      return const Failure('Payment not found.');
    }
    list.removeWhere((t) => t.id == transactionId);
    _emitTx(rdId);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> addPoDeposit(RDPoDeposit event) async {
    if (failWith != null) return Failure(failWith!);
    final list = _poDeposits.putIfAbsent(event.rdId, () => []);
    if (list.any((e) => e.id == event.id)) {
      return const Failure('This entry has already been recorded.');
    }
    list.add(event.copyWith(createdAt: event.createdAt ?? DateTime.now()));
    _poControllers[event.rdId]?.add(Success(List.unmodifiable(list)));
    return const Success(null);
  }

  @override
  Future<Result<void, String>> deletePoDeposit({
    required String rdId,
    required String eventId,
  }) async {
    if (failWith != null) return Failure(failWith!);
    final list = _poDeposits[rdId];
    if (list == null || !list.any((e) => e.id == eventId)) {
      return const Failure('Deposit not found.');
    }
    list.removeWhere((e) => e.id == eventId);
    _poControllers[rdId]?.add(Success(List.unmodifiable(list)));
    return const Success(null);
  }

  @override
  Future<Result<void, String>> deletePoDepositBatch(String batchId) async {
    if (failWith != null) return Failure(failWith!);
    for (final e in _poDeposits.entries) {
      final before = e.value.length;
      e.value.removeWhere((d) => d.batchId == batchId);
      if (e.value.length != before) {
        _poControllers[e.key]?.add(Success(List.unmodifiable(e.value)));
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void, String>> upsertFeeAbsorption(RDFeeAbsorption absorption) async {
    if (failWith != null) return Failure(failWith!);
    final list = _absorptions.putIfAbsent(absorption.rdId, () => []);
    list.removeWhere((a) => a.installmentNo == absorption.installmentNo);
    list.add(absorption);
    _absorptionControllers[absorption.rdId]?.add(Success(List.unmodifiable(list)));
    return const Success(null);
  }

  @override
  Future<Result<void, String>> removeFeeAbsorption({
    required String rdId,
    required int installmentNo,
  }) async {
    if (failWith != null) return Failure(failWith!);
    _absorptions[rdId]?.removeWhere((a) => a.installmentNo == installmentNo);
    _absorptionControllers[rdId]?.add(Success(List.unmodifiable(_absorptions[rdId] ?? const [])));
    return const Success(null);
  }

  void dispose() {
    for (final c in _txControllers.values) {
      c.close();
    }
    for (final c in _poControllers.values) {
      c.close();
    }
    for (final c in _absorptionControllers.values) {
      c.close();
    }
    _summaryController.close();
  }

  // --- Internals ----------------------------------------------------------------------------

  Stream<Result<List<T>, String>> _watch<T>(
    Map<String, StreamController<Result<List<T>, String>>> controllers,
    String rdId,
    List<T> Function() current,
  ) async* {
    final controller = controllers.putIfAbsent(
      rdId,
      () => StreamController<Result<List<T>, String>>.broadcast(),
    );
    yield Success(List.unmodifiable(current()));
    yield* controller.stream;
  }

  void _emitTx(String rdId) =>
      _txControllers[rdId]?.add(Success(List.unmodifiable(_transactions[rdId] ?? const [])));
}
