import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projector.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'rd_ledger_controller.g.dart';

/// Thrown into Riverpod's `AsyncError` when a fact stream reports a repository failure,
/// so the UI can render the message without `Exception:` prefixes.
class RDLedgerException implements Exception {
  const RDLedgerException(this.message);
  final String message;
  @override
  String toString() => message;
}

T _unwrap<T>(Result<T, String> result) => switch (result) {
      Success(:final value) => value,
      Failure(:final error) => throw RDLedgerException(error),
    };

/// Injected projector (lets tests swap rules).
@Riverpod(keepAlive: true)
RDLedgerProjector rdLedgerProjector(Ref ref) => RDLedgerProjector.standard;

// --- Facts & projection (per RD) -------------------------------------------------------------

@riverpod
Stream<List<RDTransaction>> rdTransactionsStream(Ref ref, String rdId) =>
    ref.watch(rdLedgerRepositoryProvider).watchTransactions(rdId).map(_unwrap);

@riverpod
Stream<List<RDPoDeposit>> rdPoDepositsStream(Ref ref, String rdId) =>
    ref.watch(rdLedgerRepositoryProvider).watchPoDeposits(rdId).map(_unwrap);

@riverpod
Stream<List<RDFeeAbsorption>> rdFeeAbsorptionsStream(Ref ref, String rdId) =>
    ref.watch(rdLedgerRepositoryProvider).watchFeeAbsorptions(rdId).map(_unwrap);

/// All facts for one RD. Re-emits whenever any underlying stream changes.
@riverpod
Future<RDLedgerFacts> rdLedgerFacts(Ref ref, String rdId) async {
  final deposit = await ref.watch(recurringDepositByIdProvider(rdId).future);
  final transactions = await ref.watch(rdTransactionsStreamProvider(rdId).future);
  final poDeposits = await ref.watch(rdPoDepositsStreamProvider(rdId).future);
  final absorptions = await ref.watch(rdFeeAbsorptionsStreamProvider(rdId).future);
  return RDLedgerFacts(
    deposit: deposit,
    transactions: transactions,
    poDeposits: poDeposits,
    absorptions: absorptions,
  );
}

/// The projected ledger for one RD, as of today's reactive calendar date.
@riverpod
Future<RDLedgerProjection> rdLedgerProjection(Ref ref, String rdId) async {
  final facts = await ref.watch(rdLedgerFactsProvider(rdId).future);
  final asOf = ref.watch(currentDateProvider);
  return ref.watch(rdLedgerProjectorProvider).project(facts, asOf: asOf);
}

/// Convenience view: the 60-month schedule.
@riverpod
Future<List<RDInstallment>> rdInstallments(Ref ref, String rdId) async =>
    (await ref.watch(rdLedgerProjectionProvider(rdId).future)).installments;

/// Financial terms are frozen once the ledger has activity.
@riverpod
Future<bool> rdIsFinancialTermsLocked(Ref ref, String rdId) async =>
    (await ref.watch(rdLedgerFactsProvider(rdId).future)).isFinancialTermsLocked;

/// Agent-wide summary cache (one row per RD) powering the Monthly Hub.
@Riverpod(keepAlive: true)
Stream<Map<String, RDLedgerSummary>> rdLedgerSummaries(Ref ref) {
  ref.watch(activeSessionKeyProvider);
  return ref.watch(rdLedgerRepositoryProvider).watchSummaries().map(
        (r) => {for (final s in _unwrap(r)) s.rdId: s},
      );
}

// --- Payment draft ----------------------------------------------------------------------------

/// What the payment sheet collects. A payment is just money; the projector applies it.
typedef RDPaymentDraft = ({
  String rdId,
  String? transactionId,
  double amount,
  DateTime paidDate,
  RDPaymentMode paymentMode,
});

extension RDPaymentDraftX on RDPaymentDraft {
  RDTransaction toTransaction({String? id}) => RDTransaction(
        id: id ?? transactionId ?? const Uuid().v7(),
        rdId: rdId,
        paidDate: paidDate.toDateOnly(),
        amount: amount,
        paymentMode: paymentMode,
      );
}

// --- Mutations --------------------------------------------------------------------------------

/// All ledger writes. `state` is the busy flag for the currently running operation so
/// buttons can disable themselves and a double-tap can never record a payment twice.
/// Kept alive: it is a stateless façade and in-flight writes must outlive any one screen.
@Riverpod(keepAlive: true)
class RDLedgerController extends _$RDLedgerController {
  final Set<String> _dirtySummaryRdIds = <String>{};

  @override
  AsyncValue<void> build() {
    ref.watch(activeSessionKeyProvider);
    _dirtySummaryRdIds.clear();
    return const AsyncData(null);
  }

  bool get isBusy => state.isLoading;
  Set<String> get dirtySummaryRdIds => Set.unmodifiable(_dirtySummaryRdIds);

  Future<Result<void, String>> recordPayment(RDPaymentDraft draft) {
    if (Money.toPaise(draft.amount) <= 0) {
      return Future.value(const Failure('Amount must be greater than zero.'));
    }
    final tx = draft.toTransaction();
    return _mutate(
      tx.rdId,
      () => ref.read(rdLedgerRepositoryProvider).addTransaction(tx),
      (f) => f.copyWith(
        transactions: [
          ...f.transactions.where((t) => t.id != tx.id),
          tx,
        ],
      ),
    );
  }

  Future<Result<void, String>> updatePayment(RDTransaction tx) {
    if (Money.toPaise(tx.amount) <= 0) {
      return Future.value(const Failure('Amount must be greater than zero.'));
    }
    final normalised = tx.copyWith(paidDate: tx.paidDate.toDateOnly());
    return _mutate(
      tx.rdId,
      () => ref.read(rdLedgerRepositoryProvider).updateTransaction(normalised),
      (f) => f.copyWith(
        transactions: [for (final t in f.transactions) t.id == tx.id ? normalised : t],
      ),
    );
  }

  Future<Result<void, String>> deletePayment({
    required String rdId,
    required String transactionId,
  }) =>
      _mutate(
        rdId,
        () => ref
            .read(rdLedgerRepositoryProvider)
            .deleteTransaction(rdId: rdId, transactionId: transactionId),
        (f) => f.copyWith(
          transactions: f.transactions.where((t) => t.id != transactionId).toList(),
        ),
      );

  /// Records a Post Office visit: the next [count] installments of [rdId] deposited on
  /// [depositedOn] (default today). Pass [feeOverride] when the counter charged a different
  /// fee than the statutory formula (e.g. `0` when a Sunday/holiday due date was extended).
  Future<Result<void, String>> depositNextToPo({
    required String rdId,
    required int count,
    DateTime? depositedOn,
    String? batchId,
    double? feeOverride,
  }) async {
    final RDLedgerFacts facts;
    try {
      facts = await _readFacts(rdId);
    } on RDLedgerException catch (e) {
      return Failure(e.message);
    }
    final planned = ref.read(rdLedgerProjectorProvider).planPoDeposit(
          facts,
          id: const Uuid().v7(),
          count: count,
          depositedOn: depositedOn ?? ref.read(clockProvider)(),
          feeOverride: feeOverride,
          batchId: batchId,
        );
    final RDPoDeposit event;
    switch (planned) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        event = value;
    }
    return _mutate(
      rdId,
      () => ref.read(rdLedgerRepositoryProvider).addPoDeposit(event),
      (f) => f.copyWith(
        poDeposits: [
          ...f.poDeposits.where((e) => e.id != event.id),
          event,
        ],
      ),
    );
  }

  /// The id of the PO event that visit [batchId] records on account [rdId]. Deterministic,
  /// so re-sending the same visit targets the same rows instead of creating new ones.
  static String poVisitEventId(String batchId, String rdId) =>
      const Uuid().v5(Namespace.url.value, 'postfolio:po-visit:$batchId:$rdId');

  /// Records one Post Office visit across several accounts.
  ///
  /// * Facts for every account are read once, in one batch, and every line is validated in
  ///   Dart **before** anything is written; all events then go in one atomic insert.
  /// * After the insert nothing is read again: summaries are projected from the facts already
  ///   in hand, and a failed summary write only marks those accounts dirty. A saved visit is
  ///   therefore never reported as failed.
  /// * Re-sending the same [batchId] is safe: an account whose event for this visit already
  ///   exists is skipped, so a retry after a lost response deposits nothing twice.
  Future<Result<String, String>> depositBatchToPo({
    required List<({String rdId, int count, double? feeOverride})> lines,
    DateTime? depositedOn,
    String? batchId,
  }) async {
    if (lines.isEmpty) return const Failure('Nothing to deposit.');
    if (state.isLoading) {
      return const Failure('Another ledger operation is still running.');
    }
    final rdIds = {for (final line in lines) line.rdId};
    if (rdIds.length != lines.length) {
      return const Failure('An account appears more than once in this visit.');
    }
    final day = (depositedOn ?? ref.read(clockProvider)()).toDateOnly();
    final resolvedBatchId = batchId ?? const Uuid().v7();

    state = const AsyncLoading();
    try {
      final projector = ref.read(rdLedgerProjectorProvider);
      final factsByRd = await _fetchFactsFor(rdIds);

      // Plan every line before writing anything.
      final events = <RDPoDeposit>[];
      final factsAfter = <RDLedgerFacts>[];
      for (final line in lines) {
        final facts = factsByRd[line.rdId];
        if (facts == null) {
          return const Failure('An account in this visit no longer exists.');
        }
        final eventId = poVisitEventId(resolvedBatchId, line.rdId);
        if (facts.poDeposits.any((e) => e.id == eventId)) {
          // Already saved by an earlier attempt of this same visit.
          factsAfter.add(facts);
          continue;
        }
        final planned = projector.planPoDeposit(
          facts,
          id: eventId,
          count: line.count,
          depositedOn: day,
          feeOverride: line.feeOverride,
          batchId: resolvedBatchId,
        );
        switch (planned) {
          case Failure(:final error):
            final label = facts.deposit.serialNo ?? facts.deposit.accountNo;
            return Failure(label == null ? error : 'Account $label: $error');
          case Success(value: final event):
            events.add(event);
            factsAfter.add(facts.copyWith(poDeposits: [...facts.poDeposits, event]));
        }
      }

      if (events.isNotEmpty) {
        final written =
            await ref.read(rdLedgerRepositoryProvider).addPoDeposits(events);
        if (written case Failure(:final error)) return Failure(error);
      }

      // The visit is saved. From here on nothing may turn it into a Failure.
      final asOf = ref.read(clockProvider)().toDateOnly();
      await _upsertSummariesWithRetryTrack([
        for (final facts in factsAfter) projector.project(facts, asOf: asOf).summary,
      ]);
      return Success(resolvedBatchId);
    } on RDLedgerException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure(e.toString());
    } finally {
      if (ref.mounted) state = const AsyncData(null);
    }
  }

  /// Undoes the most recent PO visit for [rdId]. Earlier visits are immutable because the
  /// Post Office ledger is sequential.
  Future<Result<void, String>> undoLatestPoDeposit(String rdId) async {
    final RDLedgerFacts facts;
    try {
      facts = await _readFacts(rdId);
    } on RDLedgerException catch (e) {
      return Failure(e.message);
    }
    final latest = facts.latestPoDeposit;
    if (latest == null) return const Failure('No Post Office deposit to undo.');
    return _mutate(
      rdId,
      () => ref
          .read(rdLedgerRepositoryProvider)
          .deletePoDeposit(rdId: rdId, eventId: latest.id),
      (f) => f.copyWith(poDeposits: f.poDeposits.where((e) => e.id != latest.id).toList()),
    );
  }

  /// Deletes every PO event recorded under one visit (`batchId`) and refreshes only the
  /// touched accounts' summaries. Used by "Undo visit".
  ///
  /// Once the delete has gone through, the undo is done: a summary refresh that cannot read
  /// marks those accounts dirty (healed by [flushDirtySummaries]) instead of failing the undo.
  Future<Result<void, String>> undoBatch(String batchId) async {
    if (state.isLoading) {
      return const Failure('Another ledger operation is still running.');
    }
    state = const AsyncLoading();
    try {
      final result = await ref.read(rdLedgerRepositoryProvider).deletePoDepositBatch(batchId);
      switch (result) {
        case Failure(:final error):
          return Failure(error);
        case Success(value: final affectedRdIds):
          await _refreshSummariesFromFacts(affectedRdIds.toSet());
          return const Success(null);
      }
    } catch (e) {
      return Failure(e.toString());
    } finally {
      if (ref.mounted) state = const AsyncData(null);
    }
  }

  /// Records that the agent paid [amount] of month [installmentNo]'s default fee from pocket
  /// (pass `0` / use [clearAbsorbedFee] to revert).
  Future<Result<void, String>> absorbFee({
    required String rdId,
    required int installmentNo,
    required double amount,
  }) {
    if (Money.toPaise(amount) <= 0) {
      return clearAbsorbedFee(rdId: rdId, installmentNo: installmentNo);
    }
    final absorption = RDFeeAbsorption(
      rdId: rdId,
      installmentNo: installmentNo,
      amount: amount,
      absorbedOn: ref.read(clockProvider)().toDateOnly(),
    );
    return _mutate(
      rdId,
      () => ref.read(rdLedgerRepositoryProvider).upsertFeeAbsorption(absorption),
      (f) => f.copyWith(absorptions: [
        ...f.absorptions.where((a) => a.installmentNo != installmentNo),
        absorption,
      ]),
    );
  }

  Future<Result<void, String>> clearAbsorbedFee({
    required String rdId,
    required int installmentNo,
  }) =>
      _mutate(
        rdId,
        () => ref
            .read(rdLedgerRepositoryProvider)
            .removeFeeAbsorption(rdId: rdId, installmentNo: installmentNo),
        (f) => f.copyWith(
          absorptions: f.absorptions.where((a) => a.installmentNo != installmentNo).toList(),
        ),
      );

  /// Re-projects from the live facts and refreshes the hub cache (e.g. single-account update).
  Future<Result<void, String>> rebuildSummary(String rdId) async {
    try {
      final facts = await _readFacts(rdId);
      await _writeSummary(facts);
      return const Success(null);
    } on RDLedgerException catch (e) {
      return Failure(e.message);
    }
  }

  /// Batch-rebuilds hub summaries for [deposits] in 1 batch fact fetch + 1 bulk upsert
  /// (instead of opening `3 * N` per-RD Realtime streams).
  Future<Result<void, String>> rebuildSummaries(
    List<RecurringDeposit> deposits,
  ) async {
    if (deposits.isEmpty) return const Success(null);
    final repo = ref.read(rdLedgerRepositoryProvider);
    final rawResult = await repo.fetchRawFactsForRds([
      for (final d in deposits) d.id,
    ]);
    switch (rawResult) {
      case Failure(:final error):
        return Failure(error);
      case Success(value: final bundles):
        final asOf = ref.read(clockProvider)().toDateOnly();
        final projector = ref.read(rdLedgerProjectorProvider);
        final summaries = <RDLedgerSummary>[];
        for (final deposit in deposits) {
          final raw = bundles[deposit.id];
          final facts = RDLedgerFacts(
            deposit: deposit,
            transactions: raw?.transactions ?? const [],
            poDeposits: raw?.poDeposits ?? const [],
            absorptions: raw?.absorptions ?? const [],
          );
          summaries.add(projector.project(facts, asOf: asOf).summary);
        }
        await _upsertSummariesWithRetryTrack(summaries);
        return const Success(null);
    }
  }

  /// Reads the latest facts for [rdId] while holding a subscription, so an autoDispose
  /// family that nobody is watching is not torn down mid-load and rebuilding streams settle.
  Future<RDLedgerFacts> _readFacts(String rdId) async {
    final sub = ref.listen(rdLedgerFactsProvider(rdId), (_, _) {});
    try {
      return await ref.read(rdLedgerFactsProvider(rdId).future);
    } finally {
      sub.close();
    }
  }

  /// Facts for many accounts in one batch read (one request per fact table, not a set of
  /// live streams per account). Accounts that no longer exist are absent from the result.
  /// Throws [RDLedgerException] when either the deposits or the facts cannot be read.
  Future<Map<String, RDLedgerFacts>> _fetchFactsFor(Set<String> rdIds) async {
    if (rdIds.isEmpty) return const {};
    final List<RecurringDeposit> deposits;
    final sub = ref.listen(recurringDepositsControllerProvider, (_, _) {});
    try {
      deposits = await ref.read(recurringDepositsControllerProvider.future);
    } catch (_) {
      throw const RDLedgerException(
        'Accounts could not be loaded. Check your connection and try again.',
      );
    } finally {
      sub.close();
    }
    final depositById = {
      for (final d in deposits)
        if (rdIds.contains(d.id)) d.id: d,
    };
    final raw = _unwrap(
      await ref
          .read(rdLedgerRepositoryProvider)
          .fetchRawFactsForRds(depositById.keys.toList(growable: false)),
    );
    return {
      for (final entry in depositById.entries)
        entry.key: RDLedgerFacts(
          deposit: entry.value,
          transactions: raw[entry.key]?.transactions ?? const [],
          poDeposits: raw[entry.key]?.poDeposits ?? const [],
          absorptions: raw[entry.key]?.absorptions ?? const [],
        ),
    };
  }

  /// Re-projects [rdIds] from freshly read facts and writes their summaries. Never throws:
  /// if the facts cannot be read or the write fails, the accounts are marked dirty.
  Future<void> _refreshSummariesFromFacts(Set<String> rdIds) async {
    if (rdIds.isEmpty) return;
    try {
      final factsByRd = await _fetchFactsFor(rdIds);
      final asOf = ref.read(clockProvider)().toDateOnly();
      final projector = ref.read(rdLedgerProjectorProvider);
      await _upsertSummariesWithRetryTrack([
        for (final facts in factsByRd.values) projector.project(facts, asOf: asOf).summary,
      ]);
      // An account that no longer exists has no summary left to repair.
      _dirtySummaryRdIds.removeWhere(
        (id) => rdIds.contains(id) && !factsByRd.containsKey(id),
      );
    } catch (_) {
      _dirtySummaryRdIds.addAll(rdIds);
    }
  }

  // --- internals --------------------------------------------------------------------------

  /// Runs a fact write, then (best-effort) re-projects with the optimistic fact change applied
  /// and upserts the hub summary. The summary is a cache: if it fails, the write still stands.
  Future<Result<void, String>> _mutate(
    String rdId,
    Future<Result<void, String>> Function() write,
    RDLedgerFacts Function(RDLedgerFacts) apply,
  ) async {
    if (state.isLoading) {
      return const Failure('Another ledger operation is still running.');
    }
    state = const AsyncLoading();
    try {
      final result = await write();
      if (result case Success()) {
        await _refreshSummary(rdId, apply);
      }
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return Failure(e.toString());
    }
  }

  /// Re-projects and flushes any summaries whose earlier refresh failed, from one batch read.
  Future<void> flushDirtySummaries() async {
    if (_dirtySummaryRdIds.isEmpty) return;
    await _refreshSummariesFromFacts({..._dirtySummaryRdIds});
  }

  Future<void> _refreshSummary(
    String rdId,
    RDLedgerFacts Function(RDLedgerFacts) apply,
  ) async {
    final hadOtherDirty = _dirtySummaryRdIds.any((id) => id != rdId);
    try {
      await _writeSummary(apply(await _readFacts(rdId)));
      if (hadOtherDirty && !_dirtySummaryRdIds.contains(rdId)) {
        await flushDirtySummaries();
      }
    } catch (_) {
      _dirtySummaryRdIds.add(rdId);
    }
  }

  Future<void> _writeSummary(RDLedgerFacts facts) async {
    final asOf = ref.read(clockProvider)().toDateOnly();
    final projection = ref.read(rdLedgerProjectorProvider).project(facts, asOf: asOf);
    await _upsertSummariesWithRetryTrack([projection.summary]);
  }

  Future<void> _upsertSummariesWithRetryTrack(List<RDLedgerSummary> summaries) async {
    if (summaries.isEmpty) return;
    final res = await ref.read(rdLedgerRepositoryProvider).upsertSummaries(summaries);
    switch (res) {
      case Success():
        for (final s in summaries) {
          _dirtySummaryRdIds.remove(s.rdId);
        }
      case Failure():
        for (final s in summaries) {
          _dirtySummaryRdIds.add(s.rdId);
        }
    }
  }
}
