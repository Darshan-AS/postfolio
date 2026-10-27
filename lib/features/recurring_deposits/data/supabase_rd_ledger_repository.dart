import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation: three fact tables + one cache table, all under RLS.
///
/// Every stream is a direct realtime subscription on a single table filtered server-side,
/// so a payment on one RD never triggers a refetch for another.
class SupabaseRDLedgerRepository implements RDLedgerRepository {
  SupabaseRDLedgerRepository(this._client);

  final SupabaseClient _client;

  static const _transactions = 'rd_transactions';
  static const _poDeposits = 'rd_po_deposits';
  static const _feeWaivers = 'rd_fee_waivers';
  static const _summaries = 'rd_ledger_summary';

  String get _agentId {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Agent not authenticated');
    return user.id;
  }

  // --- Reads ------------------------------------------------------------------------------

  @override
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId) =>
      _client
          .from(_transactions)
          .stream(primaryKey: ['id'])
          .eq('rd_id', rdId)
          .map((rows) => _mapRows(rows, RDTransaction.fromJson));

  @override
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId) =>
      _client
          .from(_poDeposits)
          .stream(primaryKey: ['rd_id', 'installment_no'])
          .eq('rd_id', rdId)
          .map((rows) => _mapRows(rows, RDPoDeposit.fromJson));

  @override
  Stream<Result<List<RDFeeWaiver>, String>> watchFeeWaivers(String rdId) =>
      _client
          .from(_feeWaivers)
          .stream(primaryKey: ['rd_id', 'installment_no'])
          .eq('rd_id', rdId)
          .map((rows) => _mapRows(rows, RDFeeWaiver.fromJson));

  @override
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries() => _client
      .from(_summaries)
      .stream(primaryKey: ['rd_id'])
      .eq('agent_id', _agentId)
      .map((rows) => _mapRows(rows, RDLedgerSummary.fromJson));

  // --- Writes -----------------------------------------------------------------------------

  @override
  Future<Result<void, String>> upsertSummary(RDLedgerSummary summary) =>
      _guard(() => _client.from(_summaries).upsert(
            _withAgent(summary.toJson()..remove('updated_at')),
            onConflict: 'rd_id',
          ));

  @override
  Future<Result<void, String>> addTransaction(RDTransaction transaction) =>
      _guard(() => _client.from(_transactions).insert(_transactionRow(transaction)));

  @override
  Future<Result<void, String>> updateTransaction(RDTransaction transaction) =>
      _guard(() => _client
          .from(_transactions)
          .update(_transactionRow(transaction)..remove('id')..remove('rd_id'))
          .eq('id', transaction.id)
          .eq('rd_id', transaction.rdId));

  @override
  Future<Result<void, String>> deleteTransaction({
    required String rdId,
    required String transactionId,
  }) =>
      _guard(() => _client
          .from(_transactions)
          .delete()
          .eq('id', transactionId)
          .eq('rd_id', rdId));

  @override
  Future<Result<void, String>> addPoDeposits(List<RDPoDeposit> deposits) {
    if (deposits.isEmpty) return Future.value(const Success(null));
    return _guard(() => _client.from(_poDeposits).insert([
          for (final d in deposits) _withAgent(d.toJson()..remove('created_at')),
        ]));
  }

  @override
  Future<Result<void, String>> removePoDeposits({
    required String rdId,
    required Set<int> installmentNos,
  }) {
    if (installmentNos.isEmpty) return Future.value(const Success(null));
    return _guard(() => _client
        .from(_poDeposits)
        .delete()
        .eq('rd_id', rdId)
        .inFilter('installment_no', installmentNos.toList()));
  }

  @override
  Future<Result<void, String>> addFeeWaiver(RDFeeWaiver waiver) => _guard(
      () => _client.from(_feeWaivers).insert(_withAgent(waiver.toJson()..remove('created_at'))));

  @override
  Future<Result<void, String>> removeFeeWaiver({
    required String rdId,
    required int installmentNo,
  }) =>
      _guard(() => _client
          .from(_feeWaivers)
          .delete()
          .eq('rd_id', rdId)
          .eq('installment_no', installmentNo));

  // --- Helpers ----------------------------------------------------------------------------

  Map<String, dynamic> _transactionRow(RDTransaction tx) {
    final json = tx.toJson()
      ..remove('created_at')
      ..remove('updated_at');
    // DATE column: strip any time component the generic converter may have produced.
    json['paid_date'] = tx.paidDate.toIso8601String().split('T').first;
    return _withAgent(json);
  }

  Map<String, dynamic> _withAgent(Map<String, dynamic> json) =>
      json..['agent_id'] = _agentId;

  static Result<List<T>, String> _mapRows<T>(
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return Success(rows.map(fromJson).toList(growable: false));
    } catch (e) {
      return Failure(_describe(e));
    }
  }

  static Future<Result<void, String>> _guard(Future<void> Function() op) async {
    try {
      await op();
      return const Success(null);
    } catch (e) {
      return Failure(_describe(e));
    }
  }

  /// Maps database errors to short, non-leaky messages. Raw SQL text never reaches the UI.
  static String _describe(Object e) {
    if (e is PostgrestException) {
      switch (e.code) {
        case '23505':
          return 'This month has already been recorded.';
        case '23514':
          return 'The entry does not satisfy the ledger rules.';
        case '42501':
          return 'You do not have permission to modify this account.';
        case '23503':
          return 'The account no longer exists.';
      }
      return 'The ledger could not be updated. Please try again.';
    }
    if (e is StateError) return e.message;
    return 'Something went wrong while talking to the server.';
  }
}
