import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

/// Persistence boundary for RD ledger **facts**.
///
/// Reads are bounded per RD (an RD has at most a few hundred facts over its life) except
/// [watchSummaries], which is one row per RD and feeds the Monthly Hub.
/// Writes are plain inserts/updates/deletes guarded by RLS — there is no server-side
/// business logic to call.
abstract interface class RDLedgerRepository {
  // --- Facts (per RD) ---------------------------------------------------------------------
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId);
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId);
  Stream<Result<List<RDFeeWaiver>, String>> watchFeeWaivers(String rdId);

  // --- Cache (agent-wide, one row per RD) -------------------------------------------------
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries();
  Future<Result<void, String>> upsertSummary(RDLedgerSummary summary);

  // --- Writes -----------------------------------------------------------------------------
  Future<Result<void, String>> addTransaction(RDTransaction transaction);
  Future<Result<void, String>> updateTransaction(RDTransaction transaction);
  Future<Result<void, String>> deleteTransaction({
    required String rdId,
    required String transactionId,
  });

  Future<Result<void, String>> addPoDeposits(List<RDPoDeposit> deposits);
  Future<Result<void, String>> removePoDeposits({
    required String rdId,
    required Set<int> installmentNos,
  });

  Future<Result<void, String>> addFeeWaiver(RDFeeWaiver waiver);
  Future<Result<void, String>> removeFeeWaiver({
    required String rdId,
    required int installmentNo,
  });
}
