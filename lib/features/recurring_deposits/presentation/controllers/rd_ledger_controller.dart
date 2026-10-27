import 'dart:async';

import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
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
Stream<List<RDFeeWaiver>> rdFeeWaiversStream(Ref ref, String rdId) =>
    ref.watch(rdLedgerRepositoryProvider).watchFeeWaivers(rdId).map(_unwrap);

/// All facts for one RD. Re-emits whenever any underlying stream changes.
@riverpod
Future<RDLedgerFacts> rdLedgerFacts(Ref ref, String rdId) async {
  final deposit = await ref.watch(recurringDepositByIdProvider(rdId).future);
  final transactions = await ref.watch(rdTransactionsStreamProvider(rdId).future);
  final poDeposits = await ref.watch(rdPoDepositsStreamProvider(rdId).future);
  final waivers = await ref.watch(rdFeeWaiversStreamProvider(rdId).future);
  return RDLedgerFacts(
    deposit: deposit,
    transactions: transactions,
    poDeposits: poDeposits,
    waivers: waivers,
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

/// What the payment sheet collects. The controller turns it into an `RDTransaction` fact.
typedef RDPaymentDraft = ({
  String rdId,
  String? transactionId,
  double amount,
  DateTime paidDate,
  RDPaymentMode paymentMode,
  PaymentSplitMode splitMode,
  double installmentComponent,
  double lateFeeComponent,
});

extension RDPaymentDraftX on RDPaymentDraft {
  RDTransaction toTransaction({String? id}) => RDTransaction(
        id: id ?? transactionId ?? const Uuid().v4(),
        rdId: rdId,
        paidDate: paidDate.toDateOnly(),
        amount: amount,
        paymentMode: paymentMode,
        splitMode: splitMode,
        installmentAmount: splitMode == PaymentSplitMode.custom ? installmentComponent : 0.0,
        lateFeeAmount: splitMode == PaymentSplitMode.custom ? lateFeeComponent : 0.0,
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
    final tx = draft.toTransaction();
    final invalid = RDLedgerProjector.validateSplit(tx);
    if (invalid != null) return Future.value(Failure(invalid));
    return _mutate(
      tx.rdId,
      () => ref.read(rdLedgerRepositoryProvider).addTransaction(tx),
      (f) => f.copyWith(transactions: [...f.transactions, tx]),
    );
  }

  Future<Result<void, String>> updatePayment(RDTransaction tx) {
    final normalised = tx.copyWith(paidDate: tx.paidDate.toDateOnly());
    final invalid = RDLedgerProjector.validateSplit(normalised);
    if (invalid != null) return Future.value(Failure(invalid));
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

  /// Marks [installmentNos] as deposited at the PO on today's date.
  Future<Result<void, String>> depositToPo({
    required String rdId,
    required Set<int> installmentNos,
    String? batchId,
  }) {
    if (installmentNos.isEmpty) return Future.value(const Success(null));
    final today = ref.read(clockProvider)().toDateOnly();
    final deposits = [
      for (final no in installmentNos)
        RDPoDeposit(rdId: rdId, installmentNo: no, depositedOn: today, batchId: batchId),
    ];
    return _mutate(
      rdId,
      () => ref.read(rdLedgerRepositoryProvider).addPoDeposits(deposits),
      (f) => f.copyWith(poDeposits: [...f.poDeposits, ...deposits]),
    );
  }

  Future<Result<void, String>> revertPoDeposit({
    required String rdId,
    required Set<int> installmentNos,
  }) {
    if (installmentNos.isEmpty) return Future.value(const Success(null));
    return _mutate(
      rdId,
      () => ref
          .read(rdLedgerRepositoryProvider)
          .removePoDeposits(rdId: rdId, installmentNos: installmentNos),
      (f) => f.copyWith(
        poDeposits:
            f.poDeposits.where((d) => !installmentNos.contains(d.installmentNo)).toList(),
      ),
    );
  }

  Future<Result<void, String>> setFeeWaiver({
    required String rdId,
    required int installmentNo,
    required bool waived,
  }) {
    final repo = ref.read(rdLedgerRepositoryProvider);
    if (waived) {
      final waiver = RDFeeWaiver(
        rdId: rdId,
        installmentNo: installmentNo,
        waivedOn: ref.read(clockProvider)().toDateOnly(),
      );
      return _mutate(
        rdId,
        () => repo.addFeeWaiver(waiver),
        (f) => f.copyWith(waivers: [...f.waivers, waiver]),
      );
    }
    return _mutate(
      rdId,
      () => repo.removeFeeWaiver(rdId: rdId, installmentNo: installmentNo),
      (f) => f.copyWith(
        waivers: f.waivers.where((w) => w.installmentNo != installmentNo).toList(),
      ),
    );
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
