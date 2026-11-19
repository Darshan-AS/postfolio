import 'package:postfolio/core/mocks/demo_data_source_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rd_ledger_repository_provider.g.dart';

/// Resolves the RD ledger backend: Demo Mode uses deterministic in-memory fixtures;
/// live mode uses the RLS-protected Supabase fact tables.
@Riverpod(keepAlive: true)
RDLedgerRepository rdLedgerRepository(Ref ref) {
  ref.watch(activeSessionKeyProvider);
  if (ref.watch(demoModeProvider)) {
    final source = ref.watch(demoDataSourceProvider);
    final repo = FakeRDLedgerRepository(
      transactions: source.rdTransactions,
      poDeposits: source.rdPoDeposits,
      absorptions: source.rdFeeAbsorptions,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  final repo = SupabaseRDLedgerRepository(
    ref.watch(supabaseClientProvider),
    effectiveAgentId: ref.watch(effectiveAgentIdProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
}
