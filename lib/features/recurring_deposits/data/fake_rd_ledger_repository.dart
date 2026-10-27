import 'dart:async';

import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
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
    Map<String, List<RDFeeWaiver>>? waivers,
    this.failWith,
  })  : _transactions = {for (final e in (transactions ?? {}).entries) e.key: [...e.value]},
        _poDeposits = {for (final e in (poDeposits ?? {}).entries) e.key: [...e.value]},
        _waivers = {for (final e in (waivers ?? {}).entries) e.key: [...e.value]};

  /// When set, every write fails with this message (for error-path tests).
  String? failWith;

  final Map<String, List<RDTransaction>> _transactions;
  final Map<String, List<RDPoDeposit>> _poDeposits;
  final Map<String, List<RDFeeWaiver>> _waivers;
  final Map<String, RDLedgerSummary> _summaries = {};

  final _txControllers = <String, StreamController<Result<List<RDTransaction>, String>>>{};
  final _poControllers = <String, StreamController<Result<List<RDPoDeposit>, String>>>{};
  final _waiverControllers = <String, StreamController<Result<List<RDFeeWaiver>, String>>>{};
  final _summaryController =
      StreamController<Result<List<RDLedgerSummary>, String>>.broadcast();

  // --- Test inspection ----------------------------------------------------------------------
  List<RDTransaction> transactionsOf(String rdId) => List.unmodifiable(_transactions[rdId] ?? const []);
  List<RDPoDeposit> poDepositsOf(String rdId) => List.unmodifiable(_poDeposits[rdId] ?? const []);
  List<RDFeeWaiver> waiversOf(String rdId) => List.unmodifiable(_waivers[rdId] ?? const []);
  RDLedgerSummary? summaryOf(String rdId) => _summaries[rdId];

  // --- Reads --------------------------------------------------------------------------------

  @override
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId) =>
      _watch(_txControllers, rdId, () => _transactions[rdId] ?? const []);

  @override
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId) =>
      _watch(_poControllers, rdId, () => _poDeposits[rdId] ?? const []);

  @override
  Stream<Result<List<RDFeeWaiver>, String>> watchFeeWaivers(String rdId) =>
      _watch(_waiverControllers, rdId, () => _waivers[rdId] ?? const []);

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
  Future<Result<void, String>> addPoDeposits(List<RDPoDeposit> deposits) async {
    if (failWith != null) return Failure(failWith!);
    if (deposits.isEmpty) return const Success(null);
    final touched = <String>{};
    for (final d in deposits) {
      final list = _poDeposits.putIfAbsent(d.rdId, () => []);
      if (list.any((e) => e.installmentNo == d.installmentNo)) {
        return const Failure('This month has already been recorded.');
      }
      list.add(d);
      touched.add(d.rdId);
    }
    for (final rdId in touched) {
      _poControllers[rdId]?.add(Success(List.unmodifiable(_poDeposits[rdId]!)));
    }
    return const Success(null);
  }

  @override
  Future<Result<void, String>> removePoDeposits({
    required String rdId,
    required Set<int> installmentNos,
  }) async {
    if (failWith != null) return Failure(failWith!);
    _poDeposits[rdId]?.removeWhere((d) => installmentNos.contains(d.installmentNo));
    _poControllers[rdId]?.add(Success(List.unmodifiable(_poDeposits[rdId] ?? const [])));
    return const Success(null);
  }

  @override
  Future<Result<void, String>> addFeeWaiver(RDFeeWaiver waiver) async {
    if (failWith != null) return Failure(failWith!);
    final list = _waivers.putIfAbsent(waiver.rdId, () => []);
    if (list.any((w) => w.installmentNo == waiver.installmentNo)) {
      return const Failure('This month has already been recorded.');
    }
    list.add(waiver);
    _waiverControllers[waiver.rdId]?.add(Success(List.unmodifiable(list)));
    return const Success(null);
  }

  @override
  Future<Result<void, String>> removeFeeWaiver({
    required String rdId,
    required int installmentNo,
  }) async {
    if (failWith != null) return Failure(failWith!);
    _waivers[rdId]?.removeWhere((w) => w.installmentNo == installmentNo);
    _waiverControllers[rdId]?.add(Success(List.unmodifiable(_waivers[rdId] ?? const [])));
    return const Success(null);
  }

  void dispose() {
    for (final c in _txControllers.values) {
      c.close();
    }
    for (final c in _poControllers.values) {
      c.close();
    }
    for (final c in _waiverControllers.values) {
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
