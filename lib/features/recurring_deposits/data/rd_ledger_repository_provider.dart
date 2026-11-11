import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rd_ledger_repository_provider.g.dart';

/// Resolves the RD ledger backend: Demo Mode uses deterministic in-memory fixtures;
/// live mode uses the RLS-protected Supabase fact tables.
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
  return SupabaseRDLedgerRepository(ref.watch(supabaseClientProvider));
}
