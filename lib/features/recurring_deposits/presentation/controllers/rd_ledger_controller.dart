import 'package:flutter/foundation.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
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
/// buttons can disable themselves and a double-tap can never run an action twice.
/// Kept alive: it is a stateless façade and in-flight writes must outlive any one screen.
///
/// Every write follows the same shape:
/// 1. read the facts of the accounts involved, once, in one batch;
/// 2. decide the [RDLedgerChange] in Dart (all rules live in the domain);
/// 3. project the summaries of the facts *as they will be* after the change;
/// 4. send the change and those summaries in a single transaction.
/// Nothing is read after the write, and the Monthly Hub cache cannot be left behind the
/// facts: either both are stored or neither is.
@Riverpod(keepAlive: true)
class RDLedgerController extends _$RDLedgerController {
  @override
  AsyncValue<void> build() {
    ref.watch(activeSessionKeyProvider);
    return const AsyncData(null);
  }

  bool get isBusy => state.isLoading;

  // --- Customer payments -------------------------------------------------------------------

  /// Records a payment. The draft's `transactionId` identifies the payment: sending the same
  /// draft again (a retry after a lost response) updates that payment instead of adding one.
  Future<Result<void, String>> recordPayment(RDPaymentDraft draft) {
    if (Money.toPaise(draft.amount) <= 0) {
      return Future.value(const Failure('Amount must be greater than zero.'));
    }
    final tx = draft.toTransaction();
    return _commitFor(
      tx.rdId,
      (_) => Success(RDLedgerChange(upsertTransactions: [tx])),
    );
  }

  Future<Result<void, String>> updatePayment(RDTransaction tx) {
    if (Money.toPaise(tx.amount) <= 0) {
      return Future.value(const Failure('Amount must be greater than zero.'));
    }
    final normalised = tx.copyWith(paidDate: tx.paidDate.toDateOnly());
    return _commitFor(
      tx.rdId,
      (_) => Success(RDLedgerChange(upsertTransactions: [normalised])),
    );
  }

  Future<Result<void, String>> deletePayment({
    required String rdId,
    required String transactionId,
  }) =>
      _commitFor(
        rdId,
        (_) => Success(
          RDLedgerChange(
            deleteTransactions: [(rdId: rdId, transactionId: transactionId)],
          ),
        ),
      );

  // --- Post Office deposits ----------------------------------------------------------------

  /// Records a Post Office visit: the next [count] installments of [rdId] deposited on
  /// [depositedOn] (default today). Pass [feeOverride] when the counter charged a different
  /// fee than the statutory formula (e.g. `0` when a Sunday/holiday due date was extended).
  ///
  /// [eventId] identifies this deposit. A caller that may retry (a sheet with a Retry
  /// button) passes the same id each time: if that event is already stored, nothing more is
  /// deposited.
  Future<Result<void, String>> depositNextToPo({
    required String rdId,
    required int count,
    DateTime? depositedOn,
    String? batchId,
    double? feeOverride,
    String? eventId,
  }) =>
      _commitFor(rdId, (facts) {
        final id = eventId ?? const Uuid().v7();
        if (facts.poDeposits.any((e) => e.id == id)) {
          // Already saved by an earlier attempt; only the summary is refreshed.
          return const Success(RDLedgerChange());
        }
        final planned = ref.read(rdLedgerProjectorProvider).planPoDeposit(
              facts,
              id: id,
              count: count,
              depositedOn: depositedOn ?? ref.read(clockProvider)(),
              feeOverride: feeOverride,
              batchId: batchId,
            );
        return switch (planned) {
          Failure(:final error) => Failure(error),
          Success(value: final event) => Success(RDLedgerChange(insertPoDeposits: [event])),
        };
      });

  /// The id of the PO event that visit [batchId] records on account [rdId]. Deterministic,
  /// so re-sending the same visit targets the same rows instead of creating new ones.
  static String poVisitEventId(String batchId, String rdId) =>
      const Uuid().v5(Namespace.url.value, 'postfolio:po-visit:$batchId:$rdId');

  /// Records one Post Office visit across several accounts.
  ///
  /// Every line is validated in Dart before anything is written, and all events and their
  /// summaries go in one transaction. Re-sending the same [batchId] is safe: an account whose
  /// event for this visit already exists is skipped, so a retry after a lost response
  /// deposits nothing twice.
  Future<Result<String, String>> depositBatchToPo({
    required List<({String rdId, int count, double? feeOverride})> lines,
    DateTime? depositedOn,
    String? batchId,
  }) {
    if (lines.isEmpty) return Future.value(const Failure('Nothing to deposit.'));
    final rdIds = {for (final line in lines) line.rdId};
    if (rdIds.length != lines.length) {
      return Future.value(
        const Failure('An account appears more than once in this visit.'),
      );
    }
    return _exclusive(() async {
      final day = (depositedOn ?? ref.read(clockProvider)()).toDateOnly();
      final resolvedBatchId = batchId ?? const Uuid().v7();
      final projector = ref.read(rdLedgerProjectorProvider);
      final factsByRd = await _fetchFactsFor(rdIds);

      final events = <RDPoDeposit>[];
      for (final line in lines) {
        final facts = factsByRd[line.rdId];
        if (facts == null) {
          return const Failure('An account in this visit no longer exists.');
        }
        final eventId = poVisitEventId(resolvedBatchId, line.rdId);
        if (facts.poDeposits.any((e) => e.id == eventId)) continue; // saved by an earlier attempt
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
        }
      }

      final written = await _commit(
        RDLedgerChange(insertPoDeposits: events),
        factsByRd.values,
      );
      return switch (written) {
        Failure(:final error) => Failure(error),
        Success() => Success(resolvedBatchId),
      };
    });
  }

  /// Undoes the most recent PO visit for [rdId]. Earlier visits are immutable because the
  /// Post Office ledger is sequential.
  Future<Result<void, String>> undoLatestPoDeposit(String rdId) => _commitFor(rdId, (facts) {
        final latest = facts.latestPoDeposit;
        if (latest == null) return const Failure('No Post Office deposit to undo.');
        return Success(
          RDLedgerChange(deletePoDeposits: [(rdId: rdId, eventId: latest.id)]),
        );
      });

  /// Deletes every PO event recorded under one visit (`batchId`) and rewrites the touched
  /// accounts' summaries, in one transaction. Used by "Undo visit".
  ///
  /// The visit can only be undone while it is still the latest deposit on every account it
  /// covers ([RDLedgerFacts.validateBatchUndo]). Undoing a visit that is already gone is a
  /// success.
  Future<Result<void, String>> undoBatch(String batchId) => _exclusive(() async {
        final events = _unwrap(
          await ref.read(rdLedgerRepositoryProvider).fetchPoDepositsByBatch(batchId),
        );
        if (events.isEmpty) return const Success(null);

        final rdIds = {for (final e in events) e.rdId};
        final factsByRd = await _fetchFactsFor(rdIds);
        if (factsByRd.length != rdIds.length) {
          return const Failure('An account in this visit could not be loaded. Please try again.');
        }
        final error = RDLedgerFacts.validateBatchUndo(
          batchId: batchId,
          deposits: [for (final facts in factsByRd.values) ...facts.poDeposits],
        );
        if (error != null) return Failure(error);

        return _commit(
          RDLedgerChange(
            deletePoDeposits: [for (final e in events) (rdId: e.rdId, eventId: e.id)],
          ),
          factsByRd.values,
        );
      });

  // --- Absorbed fees -----------------------------------------------------------------------

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
    return _commitFor(
      rdId,
      (_) => Success(RDLedgerChange(upsertFeeAbsorptions: [absorption])),
    );
  }

  Future<Result<void, String>> clearAbsorbedFee({
    required String rdId,
    required int installmentNo,
  }) =>
      _commitFor(
        rdId,
        (_) => Success(
          RDLedgerChange(
            deleteFeeAbsorptions: [(rdId: rdId, installmentNo: installmentNo)],
          ),
        ),
      );

  // --- Summary cache rebuilds (no fact changes) --------------------------------------------

  /// Re-projects one account from freshly read facts and rewrites its cached summary
  /// (e.g. after its financial terms changed).
  Future<Result<void, String>> rebuildSummary(String rdId) async {
    try {
      final facts = (await _fetchFactsFor({rdId}))[rdId];
      if (facts == null) return const Failure('This account no longer exists.');
      return await ref.read(rdLedgerRepositoryProvider).upsertSummaries([_summaryOf(facts)]);
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
        return repo.upsertSummaries([
          for (final deposit in deposits)
            _summaryOf(
              RDLedgerFacts(
                deposit: deposit,
                transactions: bundles[deposit.id]?.transactions ?? const [],
                poDeposits: bundles[deposit.id]?.poDeposits ?? const [],
                absorptions: bundles[deposit.id]?.absorptions ?? const [],
              ),
            ),
        ]);
    }
  }

  // --- internals --------------------------------------------------------------------------

  RDLedgerSummary _summaryOf(RDLedgerFacts facts) => ref
      .read(rdLedgerProjectorProvider)
      .project(facts, asOf: ref.read(clockProvider)().toDateOnly())
      .summary;

  /// A write on one account: read its facts, let [plan] decide the change (or refuse), and
  /// commit it with the account's new summary.
  Future<Result<void, String>> _commitFor(
    String rdId,
    Result<RDLedgerChange, String> Function(RDLedgerFacts facts) plan,
  ) =>
      _exclusive(() async {
        final facts = (await _fetchFactsFor({rdId}))[rdId];
        if (facts == null) return const Failure('This account no longer exists.');
        switch (plan(facts)) {
          case Failure(:final error):
            return Failure(error);
          case Success(value: final change):
            return _commit(change, [facts]);
        }
      });

  /// Stores [change] together with the summaries of [factsBefore] as they will be once the
  /// change is applied. An empty change still rewrites the summaries, which is how a retry
  /// of an already-saved write repairs a summary nobody got to see.
  Future<Result<void, String>> _commit(
    RDLedgerChange change,
    Iterable<RDLedgerFacts> factsBefore,
  ) =>
      ref.read(rdLedgerRepositoryProvider).applyChange(
        change,
        summaries: [for (final facts in factsBefore) _summaryOf(change.applyTo(facts))],
      );

  /// Runs [operation] as the one ledger write in flight. A second write started meanwhile is
  /// refused rather than queued: queueing would turn a double-tapped "Undo" into two undos.
  Future<Result<T, String>> _exclusive<T>(
    Future<Result<T, String>> Function() operation,
  ) async {
    if (state.isLoading) {
      return const Failure('Another ledger operation is still running.');
    }
    state = const AsyncLoading();
    try {
      return await operation();
    } on RDLedgerException catch (e) {
      return Failure(e.message);
    } catch (error, stackTrace) {
      // A bug, not an expected failure: report it, and still give the caller a Result so the
      // sheet can show an error and offer a retry.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RD ledger',
          context: ErrorDescription('while writing to the RD ledger'),
        ),
      );
      return const Failure('The ledger could not be updated. Please try again.');
    } finally {
      if (ref.mounted) state = const AsyncData(null);
    }
  }

  /// Facts for [rdIds] from one batch read (one request per fact table, not a set of live
  /// streams per account). Accounts that no longer exist are absent from the result.
  /// Throws [RDLedgerException] when the accounts or their facts cannot be read.
  Future<Map<String, RDLedgerFacts>> _fetchFactsFor(Set<String> rdIds) async {
    if (rdIds.isEmpty) return const {};
    final depositById = await _depositsFor(rdIds);
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

  /// The accounts themselves. Uses the deposits list when a screen already has it loaded;
  /// otherwise reads the single account, or loads the list for a multi-account write.
  Future<Map<String, RecurringDeposit>> _depositsFor(Set<String> rdIds) async {
    Map<String, RecurringDeposit> pick(Iterable<RecurringDeposit> deposits) => {
          for (final d in deposits)
            if (rdIds.contains(d.id)) d.id: d,
        };

    if (ref.exists(recurringDepositsControllerProvider)) {
      final loaded = ref.read(recurringDepositsControllerProvider).value;
      if (loaded != null) return pick(loaded);
    }
    if (rdIds.length == 1) {
      final result = await ref
          .read(recurringDepositRepositoryProvider)
          .watchRecurringDepositById(rdIds.single)
          .first;
      return pick([_unwrap(result)]);
    }
    final sub = ref.listen(recurringDepositsControllerProvider, (_, _) {});
    try {
      return pick(await ref.read(recurringDepositsControllerProvider.future));
    } catch (_) {
      throw const RDLedgerException(
        'Accounts could not be loaded. Check your connection and try again.',
      );
    } finally {
      sub.close();
    }
  }
}
