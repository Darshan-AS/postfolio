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
        id: id ?? transactionId ?? const Uuid().v4(),
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
    if (count <= 0) return const Failure('Nothing to deposit.');
    if (feeOverride != null && Paise.fromRupees(feeOverride).isNegative) {
      return const Failure('Counter fee cannot be negative.');
    }
    final day = (depositedOn ?? ref.read(clockProvider)()).toDateOnly();
    final RDLedgerFacts facts;
    try {
      facts = await _readFacts(rdId);
    } on RDLedgerException catch (e) {
      return Failure(e.message);
    }
    final remaining = facts.deposit.totalMonths -
        projectedDepositedThrough(facts);
    if (count > remaining) {
      return Failure('Only $remaining installment(s) remain on this account.');
    }
    // The Post Office ledger is sequential: a visit dated before an already-recorded visit
    // would re-assign which months earlier visits covered (and break "undo latest").
    final latest = facts.latestPoDeposit;
    if (latest != null && day.isBefore(latest.depositedOn.toDateOnly())) {
      return Failure(
        'Deposit date cannot be before the last recorded visit (${latest.depositedOn.toDateOnlyString()}).',
      );
    }
    final quote = ref
        .read(rdLedgerProjectorProvider)
        .quoteNextDeposit(facts, count: count, depositedOn: day);
    final effectiveFee =
        feeOverride != null ? Money.round(feeOverride) : quote.fee;
    final effectiveAmount = feeOverride != null
        ? Money.round(count * facts.deposit.installmentAmount + effectiveFee)
        : quote.amount;
    final event = RDPoDeposit(
      id: const Uuid().v4(),
      rdId: rdId,
      depositedOn: day,
      installmentCount: count,
      feePaid: effectiveFee,
      amount: effectiveAmount,
      batchId: batchId,
    );
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

  /// Validates every account upfront in Dart, inserts all PO events in a single atomic batch
  /// write, and bulk-upserts all updated Monthly Hub summaries in one roundtrip.
  Future<Result<String, String>> depositBatchToPo({
    required List<({String rdId, int count, double? feeOverride})> lines,
    DateTime? depositedOn,
    String? batchId,
  }) async {
    if (lines.isEmpty) return const Failure('Nothing to deposit.');
    if (state.isLoading) {
      return const Failure('Another ledger operation is still running.');
    }
    final day = (depositedOn ?? ref.read(clockProvider)()).toDateOnly();
    final resolvedBatchId = batchId ?? const Uuid().v4();

    state = const AsyncLoading();
    try {
      final projector = ref.read(rdLedgerProjectorProvider);
      final factsByRd = <String, RDLedgerFacts>{};
      final events = <RDPoDeposit>[];

      for (final line in lines) {
        if (line.count <= 0) {
          if (ref.mounted) state = const AsyncData(null);
          return const Failure('Nothing to deposit.');
        }
        if (line.feeOverride != null &&
            Paise.fromRupees(line.feeOverride!).isNegative) {
          if (ref.mounted) state = const AsyncData(null);
          return const Failure('Counter fee cannot be negative.');
        }
        final facts = await _readFacts(line.rdId);
        factsByRd[line.rdId] = facts;
        final remaining =
            facts.deposit.totalMonths - projectedDepositedThrough(facts);
        if (line.count > remaining) {
          if (ref.mounted) state = const AsyncData(null);
          return Failure(
            'Only $remaining installment(s) remain on account ${facts.deposit.serialNo ?? facts.deposit.accountNo ?? line.rdId}.',
          );
        }
        final latest = facts.latestPoDeposit;
        if (latest != null && day.isBefore(latest.depositedOn.toDateOnly())) {
          if (ref.mounted) state = const AsyncData(null);
          return Failure(
            'Deposit date cannot be before the last recorded visit (${latest.depositedOn.toDateOnlyString()}).',
          );
        }

        final quote = projector.quoteNextDeposit(
          facts,
          count: line.count,
          depositedOn: day,
        );
        final effectiveFee = line.feeOverride != null
            ? Money.round(line.feeOverride!)
            : quote.fee;
        final effectiveAmount = line.feeOverride != null
            ? Money.round(
                line.count * facts.deposit.installmentAmount + effectiveFee,
              )
            : quote.amount;
        events.add(
          RDPoDeposit(
            id: const Uuid().v4(),
            rdId: line.rdId,
            depositedOn: day,
            installmentCount: line.count,
            feePaid: effectiveFee,
            amount: effectiveAmount,
            batchId: resolvedBatchId,
          ),
        );
      }

      final repo = ref.read(rdLedgerRepositoryProvider);
      final writeResult = await repo.addPoDeposits(events);
      if (writeResult case Failure(:final error)) {
        if (ref.mounted) state = const AsyncData(null);
        return Failure(error);
      }

      final asOf = ref.read(clockProvider)().toDateOnly();
      final summaries = <RDLedgerSummary>[];
      for (final event in events) {
        final baseFacts = await _readFacts(event.rdId);
        final nextFacts = baseFacts.copyWith(
          poDeposits: [
            ...baseFacts.poDeposits.where((e) => e.id != event.id),
            event,
          ],
        );
        summaries.add(projector.project(nextFacts, asOf: asOf).summary);
      }
      await _upsertSummariesWithRetryTrack(summaries);

      if (ref.mounted) state = const AsyncData(null);
      return Success(resolvedBatchId);
    } on RDLedgerException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return Failure(e.message);
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return Failure(e.toString());
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
  Future<Result<void, String>> undoBatch(String batchId) async {
    if (state.isLoading) {
      return const Failure('Another ledger operation is still running.');
    }
    state = const AsyncLoading();
    try {
      final result = await ref.read(rdLedgerRepositoryProvider).deletePoDepositBatch(batchId);
      switch (result) {
        case Success(value: final affectedRdIds):
          final asOf = ref.read(clockProvider)().toDateOnly();
          final projector = ref.read(rdLedgerProjectorProvider);
          final summaries = <RDLedgerSummary>[];
          for (final rdId in affectedRdIds) {
            final baseFacts = await _readFacts(rdId);
            final nextFacts = baseFacts.copyWith(
              poDeposits: baseFacts.poDeposits
                  .where((e) => e.batchId != batchId)
                  .toList(),
            );
            summaries.add(projector.project(nextFacts, asOf: asOf).summary);
          }
          await _upsertSummariesWithRetryTrack(summaries);
          if (ref.mounted) state = const AsyncData(null);
          return const Success(null);
        case Failure(:final error):
          if (ref.mounted) state = const AsyncData(null);
          return Failure(error);
      }
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return Failure(e.toString());
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

  /// Months already deposited at the PO according to [facts] (baseline + all events).
  static int projectedDepositedThrough(RDLedgerFacts facts) {
    final n = facts.deposit.totalMonths;
    var through = facts.deposit.initialPaidInstallments.clamp(0, n);
    for (final ev in facts.poDeposits) {
      through = (through + ev.installmentCount).clamp(0, n);
    }
    return through;
  }

  /// Re-projects from the live facts and refreshes the hub cache (e.g. pull-to-refresh).
  Future<Result<void, String>> rebuildSummary(String rdId) async {
    try {
      final facts = await _readFacts(rdId);
      await _writeSummary(facts);
      return const Success(null);
    } on RDLedgerException catch (e) {
      return Failure(e.message);
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

  /// Re-projects and flushes any summaries whose earlier upsert failed transiently.
  Future<void> flushDirtySummaries() async {
    if (_dirtySummaryRdIds.isEmpty) return;
    final pending = [..._dirtySummaryRdIds];
    final asOf = ref.read(clockProvider)().toDateOnly();
    final projector = ref.read(rdLedgerProjectorProvider);
    final summaries = <RDLedgerSummary>[];
    for (final rdId in pending) {
      try {
        final facts = await _readFacts(rdId);
        summaries.add(projector.project(facts, asOf: asOf).summary);
      } catch (_) {
        // Leave in _dirtySummaryRdIds if facts couldn't be read yet.
      }
    }
    if (summaries.isEmpty) return;
    final res = await ref.read(rdLedgerRepositoryProvider).upsertSummaries(summaries);
    if (res case Success()) {
      for (final s in summaries) {
        _dirtySummaryRdIds.remove(s.rdId);
      }
    }
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
