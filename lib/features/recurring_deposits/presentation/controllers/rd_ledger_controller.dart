import 'dart:async';

import 'package:postfolio/core/providers/clock_provider.dart';
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

/// The projected ledger for one RD, as of today's date.
@riverpod
Future<RDLedgerProjection> rdLedgerProjection(Ref ref, String rdId) async {
  final facts = await ref.watch(rdLedgerFactsProvider(rdId).future);
  final asOf = ref.watch(clockProvider)().toDateOnly();
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
Stream<Map<String, RDLedgerSummary>> rdLedgerSummaries(Ref ref) =>
    ref.watch(rdLedgerRepositoryProvider).watchSummaries().map(
          (r) => {for (final s in _unwrap(r)) s.rdId: s},
        );

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
  @override
  AsyncValue<void> build() => const AsyncData(null);

  bool get isBusy => state.isLoading;

  Future<Result<void, String>> recordPayment(RDPaymentDraft draft) {
    if (Money.toPaise(draft.amount) <= 0) {
      return Future.value(const Failure('Amount must be greater than zero.'));
    }
    final tx = draft.toTransaction();
    return _mutate(
      tx.rdId,
      () => ref.read(rdLedgerRepositoryProvider).addTransaction(tx),
      (f) => f.copyWith(transactions: [...f.transactions, tx]),
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
  /// [depositedOn] (default today). The amount/fee are quoted from the current facts so the
  /// event carries exactly what the counter charged.
  Future<Result<void, String>> depositNextToPo({
    required String rdId,
    required int count,
    DateTime? depositedOn,
    String? batchId,
  }) async {
    if (count <= 0) return const Failure('Nothing to deposit.');
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
    final quote = ref
        .read(rdLedgerProjectorProvider)
        .quoteNextDeposit(facts, count: count, depositedOn: day);
    final event = RDPoDeposit(
      id: const Uuid().v4(),
      rdId: rdId,
      depositedOn: day,
      installmentCount: count,
      feePaid: quote.fee,
      amount: quote.amount,
      batchId: batchId,
    );
    return _mutate(
      rdId,
      () => ref.read(rdLedgerRepositoryProvider).addPoDeposit(event),
      (f) => f.copyWith(poDeposits: [...f.poDeposits, event]),
    );
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

  /// Reads the facts for [rdId] while holding a subscription, so an autoDispose family
  /// that nobody is watching is not torn down mid-load.
  Future<RDLedgerFacts> _readFacts(String rdId) async {
    final cached = ref.read(rdLedgerFactsProvider(rdId)).value;
    if (cached != null) return cached;
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
        unawaited(_refreshSummary(rdId, apply));
      }
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return Failure(e.toString());
    }
  }

  Future<void> _refreshSummary(
    String rdId,
    RDLedgerFacts Function(RDLedgerFacts) apply,
  ) async {
    try {
      await _writeSummary(apply(await _readFacts(rdId)));
    } catch (_) {
      // Cache refresh is best-effort; the next successful write or rebuild will repair it.
    }
  }

  Future<void> _writeSummary(RDLedgerFacts facts) async {
    final asOf = ref.read(clockProvider)().toDateOnly();
    final projection = ref.read(rdLedgerProjectorProvider).project(facts, asOf: asOf);
    await ref.read(rdLedgerRepositoryProvider).upsertSummary(projection.summary);
  }
}
