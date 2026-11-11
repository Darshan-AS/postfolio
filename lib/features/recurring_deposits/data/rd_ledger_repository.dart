import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

typedef RDRawFactsBundle = ({
  List<RDTransaction> transactions,
  List<RDPoDeposit> poDeposits,
  List<RDFeeAbsorption> absorptions,
});

/// Persistence boundary for RD ledger **facts**.
///
/// Reads are bounded per RD except [watchSummaries] (one row per RD, feeds the Monthly Hub)
/// and the batch reads [fetchRawFactsForRds] / [fetchPoDepositsByBatch].
///
/// There is exactly one way to write facts: [applyChange]. It stores a change and the
/// summaries projected from it in a single database transaction, so the Monthly Hub cache
/// can never disagree with the facts it was computed from. No business rule runs on the
/// server; the change is computed and validated in Dart.
abstract interface class RDLedgerRepository {
  // --- Facts (per RD & batch reads) -------------------------------------------------------
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId);
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId);
  Stream<Result<List<RDFeeAbsorption>, String>> watchFeeAbsorptions(String rdId);
  Future<Result<Map<String, RDRawFactsBundle>, String>> fetchRawFactsForRds(
    List<String> rdIds,
  );

  /// Every PO event recorded under one visit (`batch_id`), across accounts.
  Future<Result<List<RDPoDeposit>, String>> fetchPoDepositsByBatch(String batchId);

  // --- Cache (agent-wide, one row per RD) -------------------------------------------------
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries();

  /// Rewrites cached summaries without changing any fact (first-run backfill, rebuild).
  Future<Result<void, String>> upsertSummaries(List<RDLedgerSummary> summaries);

  // --- The single fact write --------------------------------------------------------------

  /// Stores [change] and [summaries] together: either every fact and every summary is
  /// written, or nothing is. Safe to call again with the same change (see [RDLedgerChange]).
  Future<Result<void, String>> applyChange(
    RDLedgerChange change, {
    List<RDLedgerSummary> summaries = const [],
  });
}

/// Single-fact shorthands over [RDLedgerRepository.applyChange], for seeding and tests.
/// They write the fact only; the caller is responsible for the summary.
extension RDLedgerRepositoryShorthands on RDLedgerRepository {
  Future<Result<void, String>> addTransaction(RDTransaction transaction) =>
      applyChange(RDLedgerChange(upsertTransactions: [transaction]));

  Future<Result<void, String>> addPoDeposit(RDPoDeposit event) =>
      applyChange(RDLedgerChange(insertPoDeposits: [event]));

  Future<Result<void, String>> upsertFeeAbsorption(RDFeeAbsorption absorption) =>
      applyChange(RDLedgerChange(upsertFeeAbsorptions: [absorption]));
}
