import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

/// Persistence boundary for RD ledger **facts**.
///
/// Reads are bounded per RD except [watchSummaries] (one row per RD, feeds the Monthly Hub).
/// Writes are plain inserts/updates/deletes guarded by RLS — no server-side business logic.
abstract interface class RDLedgerRepository {
  // --- Facts (per RD) ---------------------------------------------------------------------
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId);
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId);
  Stream<Result<List<RDFeeAbsorption>, String>> watchFeeAbsorptions(String rdId);

  // --- Cache (agent-wide, one row per RD) -------------------------------------------------
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries();
  Future<Result<void, String>> upsertSummary(RDLedgerSummary summary);

  // --- Customer payments ------------------------------------------------------------------
  Future<Result<void, String>> addTransaction(RDTransaction transaction);
  Future<Result<void, String>> updateTransaction(RDTransaction transaction);
  Future<Result<void, String>> deleteTransaction({
    required String rdId,
    required String transactionId,
  });

  // --- Post Office deposits (sequential events) -------------------------------------------
  Future<Result<void, String>> addPoDeposit(RDPoDeposit event);

  /// Deletes one event. Callers must only pass the latest event for the RD.
  Future<Result<void, String>> deletePoDeposit({
    required String rdId,
    required String eventId,
  });

  // --- Fee absorptions --------------------------------------------------------------------
  Future<Result<void, String>> upsertFeeAbsorption(RDFeeAbsorption absorption);
  Future<Result<void, String>> removeFeeAbsorption({
    required String rdId,
    required int installmentNo,
  });
}
