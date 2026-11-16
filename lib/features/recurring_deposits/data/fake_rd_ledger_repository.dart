import 'dart:async';

import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

/// In-memory facts store for demo mode and tests.
///
/// Deliberately has **no** ledger logic: it stores lists and re-emits them. All behaviour
/// comes from `RDLedgerProjector`, so the fake cannot drift from production. Its write
/// semantics mirror the database function: one all-or-nothing [applyChange] whose parts are
/// upserts, insert-if-absent and delete-if-present.
class FakeRDLedgerRepository implements RDLedgerRepository {
  FakeRDLedgerRepository({
    Map<String, List<RDTransaction>>? transactions,
    Map<String, List<RDPoDeposit>>? poDeposits,
    Map<String, List<RDFeeAbsorption>>? absorptions,
    this.failWith,
  })  : _transactions = {for (final e in (transactions ?? {}).entries) e.key: [...e.value]},
        _poDeposits = {for (final e in (poDeposits ?? {}).entries) e.key: [...e.value]},
        _absorptions = {for (final e in (absorptions ?? {}).entries) e.key: [...e.value]};

  /// When set, every write fails with this message and stores nothing.
  String? failWith;

  /// When set, storing a summary fails. Because a change and its summaries are one
  /// transaction, an [applyChange] that carries summaries then stores nothing at all.
  String? failSummaryWith;

  /// When set, every read fails with this message: fact streams opened from now on emit a
  /// `Failure`, and the batch reads return one (simulates going offline).
  String? failReadsWith;

  /// When set, the next [applyChange] stores everything and then reports this failure once
  /// (simulates a response lost after the server committed).
  String? failApplyAfterCommitOnce;

  /// Called right after an [applyChange] has stored its change.
  void Function()? onChangeApplied;

  /// Simulated network round-trip time for [applyChange] (tests only).
  Duration? writeLatency;

  final Map<String, List<RDTransaction>> _transactions;
  final Map<String, List<RDPoDeposit>> _poDeposits;
  final Map<String, List<RDFeeAbsorption>> _absorptions;
  final Map<String, RDLedgerSummary> _summaries = {};

  final _txControllers = <String, StreamController<Result<List<RDTransaction>, String>>>{};
  final _poControllers = <String, StreamController<Result<List<RDPoDeposit>, String>>>{};
  final _absorptionControllers = <String, StreamController<Result<List<RDFeeAbsorption>, String>>>{};
  final _summaryController =
      StreamController<Result<List<RDLedgerSummary>, String>>.broadcast();

  /// Test telemetry.
  int batchFactFetchCount = 0;
  int upsertSummariesCallCount = 0;
  int applyChangeCallCount = 0;

  /// Number of per-account fact streams opened so far.
  int streamOpenCount = 0;

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
  Future<Result<Map<String, RDRawFactsBundle>, String>> fetchRawFactsForRds(
    List<String> rdIds,
  ) async {
    if (failReadsWith != null) return Failure(failReadsWith!);
    batchFactFetchCount++;
    return Success({
      for (final id in rdIds)
        id: (
          transactions: List<RDTransaction>.unmodifiable(_transactions[id] ?? const []),
          poDeposits: List<RDPoDeposit>.unmodifiable(_poDeposits[id] ?? const []),
          absorptions: List<RDFeeAbsorption>.unmodifiable(_absorptions[id] ?? const []),
        ),
    });
  }

  @override
  Future<Result<List<RDPoDeposit>, String>> fetchPoDepositsByBatch(String batchId) async {
    if (failReadsWith != null) return Failure(failReadsWith!);
    return Success([
      for (final events in _poDeposits.values)
        for (final e in events)
          if (e.batchId == batchId) e,
    ]);
  }

  @override
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries() async* {
    yield Success(_summaries.values.toList(growable: false));
    yield* _summaryController.stream;
  }

  // --- Writes -------------------------------------------------------------------------------

  @override
  Future<Result<void, String>> upsertSummaries(List<RDLedgerSummary> summaries) async {
    if (failWith != null) return Failure(failWith!);
    if (failSummaryWith != null) return Failure(failSummaryWith!);
    if (summaries.isEmpty) return const Success(null);
    upsertSummariesCallCount++;
    _storeSummaries(summaries);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> applyChange(
    RDLedgerChange change, {
    List<RDLedgerSummary> summaries = const [],
  }) async {
    if (failWith != null) return Failure(failWith!);
    final latency = writeLatency;
    if (latency != null) await Future<void>.delayed(latency);
    // One transaction: if any part cannot be stored, nothing is.
    if (summaries.isNotEmpty && failSummaryWith != null) return Failure(failSummaryWith!);
    applyChangeCallCount++;

    final now = DateTime.now();
    final txTouched = <String>{};
    final poTouched = <String>{};
    final absorptionTouched = <String>{};

    for (final d in change.deleteTransactions) {
      _transactions[d.rdId]?.removeWhere((t) => t.id == d.transactionId);
      txTouched.add(d.rdId);
    }
    for (final d in change.deletePoDeposits) {
      _poDeposits[d.rdId]?.removeWhere((e) => e.id == d.eventId);
      poTouched.add(d.rdId);
    }
    for (final d in change.deleteFeeAbsorptions) {
      _absorptions[d.rdId]?.removeWhere((a) => a.installmentNo == d.installmentNo);
      absorptionTouched.add(d.rdId);
    }
    for (final t in change.upsertTransactions) {
      final list = _transactions.putIfAbsent(t.rdId, () => []);
      final index = list.indexWhere((x) => x.id == t.id);
      if (index >= 0) {
        list[index] = t.copyWith(createdAt: list[index].createdAt);
      } else {
        list.add(t.copyWith(createdAt: t.createdAt ?? now));
      }
      txTouched.add(t.rdId);
    }
    for (final e in change.insertPoDeposits) {
      final list = _poDeposits.putIfAbsent(e.rdId, () => []);
      if (!list.any((x) => x.id == e.id)) {
        list.add(e.copyWith(createdAt: e.createdAt ?? now));
      }
      poTouched.add(e.rdId);
    }
    for (final a in change.upsertFeeAbsorptions) {
      final list = _absorptions.putIfAbsent(a.rdId, () => []);
      list
        ..removeWhere((x) => x.installmentNo == a.installmentNo)
        ..add(a);
      absorptionTouched.add(a.rdId);
    }

    for (final rdId in txTouched) {
      _txControllers[rdId]?.add(Success(List.unmodifiable(_transactions[rdId] ?? const [])));
    }
    for (final rdId in poTouched) {
      _poControllers[rdId]?.add(Success(List.unmodifiable(_poDeposits[rdId] ?? const [])));
    }
    for (final rdId in absorptionTouched) {
      _absorptionControllers[rdId]
          ?.add(Success(List.unmodifiable(_absorptions[rdId] ?? const [])));
    }
    if (summaries.isNotEmpty) _storeSummaries(summaries);

    onChangeApplied?.call();
    final lostResponse = failApplyAfterCommitOnce;
    if (lostResponse != null) {
      failApplyAfterCommitOnce = null;
      return Failure(lostResponse);
    }
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

  void _storeSummaries(List<RDLedgerSummary> summaries) {
    for (final summary in summaries) {
      _summaries[summary.rdId] = summary;
    }
    _summaryController.add(Success(_summaries.values.toList(growable: false)));
  }

  Stream<Result<List<T>, String>> _watch<T>(
    Map<String, StreamController<Result<List<T>, String>>> controllers,
    String rdId,
    List<T> Function() current,
  ) async* {
    final controller = controllers.putIfAbsent(
      rdId,
      () => StreamController<Result<List<T>, String>>.broadcast(),
    );
    streamOpenCount++;
    final readFailure = failReadsWith;
    if (readFailure != null) {
      yield Failure(readFailure);
    } else {
      yield Success(List.unmodifiable(current()));
    }
    yield* controller.stream;
  }
}
