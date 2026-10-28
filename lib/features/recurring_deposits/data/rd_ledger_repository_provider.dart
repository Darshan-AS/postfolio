import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rd_ledger_repository_provider.g.dart';

/// Resolves the ledger backend. Demo mode gets a seeded in-memory store; Supabase gets the
/// facts tables; the legacy Firestore backend gets an explicit "unsupported" implementation
/// (never silent `Success([])` stubs) so the UI can show a real error state.
@Riverpod(keepAlive: true)
RDLedgerRepository rdLedgerRepository(Ref ref) {
  if (ref.watch(demoModeProvider)) {
    final source = FakeDataSource();
    final repo = FakeRDLedgerRepository(
      transactions: source.rdTransactions,
      poDeposits: source.rdPoDeposits,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  if (Env.useSupabase) {
    return SupabaseRDLedgerRepository(ref.watch(supabaseClientProvider));
  }
  return const UnsupportedRDLedgerRepository();
}

/// Returned when the active backend cannot host the ledger. Every call fails loudly.
class UnsupportedRDLedgerRepository implements RDLedgerRepository {
  const UnsupportedRDLedgerRepository();

  static const _message = 'The RD ledger requires the Supabase backend.';
  static const Failure<void, String> _failure = Failure(_message);

  @override
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId) =>
      Stream.value(const Failure(_message));
  @override
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId) =>
      Stream.value(const Failure(_message));
  @override
  Stream<Result<List<RDFeeAbsorption>, String>> watchFeeAbsorptions(String rdId) =>
      Stream.value(const Failure(_message));
  @override
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries() =>
      Stream.value(const Failure(_message));
  @override
  Future<Result<void, String>> upsertSummary(RDLedgerSummary summary) async => _failure;
  @override
  Future<Result<void, String>> addTransaction(RDTransaction transaction) async => _failure;
  @override
  Future<Result<void, String>> updateTransaction(RDTransaction transaction) async => _failure;
  @override
  Future<Result<void, String>> deleteTransaction({
    required String rdId,
    required String transactionId,
  }) async =>
      _failure;
  @override
  Future<Result<void, String>> addPoDeposit(RDPoDeposit event) async => _failure;
  @override
  Future<Result<void, String>> deletePoDeposit({
    required String rdId,
    required String eventId,
  }) async =>
      _failure;
  @override
  Future<Result<void, String>> deletePoDepositBatch(String batchId) async => _failure;
  @override
  Future<Result<void, String>> upsertFeeAbsorption(RDFeeAbsorption absorption) async => _failure;
  @override
  Future<Result<void, String>> removeFeeAbsorption({
    required String rdId,
    required int installmentNo,
  }) async =>
      _failure;
}
