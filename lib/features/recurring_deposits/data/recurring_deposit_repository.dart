import 'dart:async';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'recurring_deposit_repository.g.dart';

abstract class RecurringDepositRepository {
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits();
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(String id);
  Future<Result<void, String>> saveRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> updateDepositStatus(
    String id,
    DepositStatus status,
  );
  Future<Result<void, String>> deleteRecurringDeposit(String id);
}

/// In-memory deposits store for demo mode and tests. Ledger facts live in
/// `FakeRDLedgerRepository`; this class only knows about deposits.
class FakeRecurringDepositRepository implements RecurringDepositRepository {
  FakeRecurringDepositRepository({List<RecurringDeposit>? deposits})
      : _deposits = [...(deposits ?? FakeDataSource().recurringDeposits)];

  final List<RecurringDeposit> _deposits;
  final _controller =
      StreamController<Result<List<RecurringDeposit>, String>>.broadcast();

  /// Hook for tests that need the "financial terms locked" rule to apply.
  bool Function(String rdId) hasLedgerActivity = (_) => false;

  List<RecurringDeposit> get deposits => List.unmodifiable(_deposits);

  void _emit() {
    if (!_controller.isClosed) _controller.add(Success([..._deposits]));
  }

  void dispose() => _controller.close();

  @override
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() async* {
    yield Success([..._deposits]);
    yield* _controller.stream;
  }

  @override
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(String id) async* {
    Result<RecurringDeposit, String> lookup(List<RecurringDeposit> list) {
      final d = list.where((d) => d.id == id).firstOrNull;
      return d == null ? const Failure('Recurring Deposit not found') : Success(d);
    }

    yield lookup(_deposits);
    yield* _controller.stream.map(
      (r) => switch (r) {
        Success(value: final list) => lookup(list),
        Failure(error: final e) => Failure<RecurringDeposit, String>(e),
      },
    );
  }

  @override
  Future<Result<void, String>> saveRecurringDeposit(RecurringDeposit deposit) async {
    final index = _deposits.indexWhere((d) => d.id == deposit.id);
    if (index == -1) {
      _deposits.add(
        deposit.copyWith(id: deposit.id.isEmpty ? const Uuid().v7() : deposit.id),
      );
    } else {
      final validation = RecurringDeposit.validateUpdate(
        existing: _deposits[index],
        updated: deposit,
        hasPayments: hasLedgerActivity(deposit.id),
      );
      if (validation case Failure(error: final err)) return Failure(err);
      _deposits[index] = deposit;
    }
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateDepositStatus(
    String id,
    DepositStatus status,
  ) async {
    final index = _deposits.indexWhere((d) => d.id == id);
    if (index == -1) return const Failure('Recurring Deposit not found');
    _deposits[index] = _deposits[index].copyWith(status: status);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    if (hasLedgerActivity(id)) {
      return const Failure(
        'Cannot delete this record while linked accounts or transactions exist.',
      );
    }
    final before = _deposits.length;
    _deposits.removeWhere((d) => d.id == id);
    if (_deposits.length == before) return const Failure('Recurring Deposit not found');
    _emit();
    return const Success(null);
  }
}

@riverpod
RecurringDepositRepository recurringDepositRepository(Ref ref) {
  if (ref.watch(demoModeProvider)) {
    final repo = FakeRecurringDepositRepository()
      ..hasLedgerActivity = (rdId) {
        final ledger = ref.read(rdLedgerRepositoryProvider);
        return ledger is FakeRDLedgerRepository &&
            (ledger.transactionsOf(rdId).isNotEmpty ||
                ledger.poDepositsOf(rdId).isNotEmpty ||
                ledger.absorptionsOf(rdId).isNotEmpty);
      };
    ref.onDispose(repo.dispose);
    return repo;
  }
  return SupabaseRecurringDepositRepository(ref.watch(supabaseClientProvider));
}
