import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/constants/firestore_keys.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:uuid/uuid.dart';

import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurring_deposit_repository.g.dart';

abstract class RecurringDepositRepository {
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits();
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(String id);
  Future<Result<void, String>> saveRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> deleteRecurringDeposit(String id);
}

class FirestoreRecurringDepositRepository
    implements RecurringDepositRepository {
  final firestore.FirebaseFirestore _firestore;
  final String _agentId;

  FirestoreRecurringDepositRepository(this._firestore, this._agentId);

  firestore.CollectionReference<RecurringDeposit> get _deposits => _firestore
      .collection(FirestoreCollections.users)
      .doc(_agentId)
      .collection(FirestoreCollections.recurringDeposits)
      .withConverter<RecurringDeposit>(
        fromFirestore: (snapshot, _) {
          final data = snapshot.data()!;
          data[FirestoreKeys.id] = snapshot.id;
          return RecurringDeposit.fromJson(data);
        },
        toFirestore: (deposit, _) {
          final data = deposit.toJson();
          data.remove(FirestoreKeys.id);
          if (deposit.createdAt == null) {
            data[FirestoreKeys.createdAt] =
                firestore.FieldValue.serverTimestamp();
          }
          data[FirestoreKeys.updatedAt] =
              firestore.FieldValue.serverTimestamp();
          return data;
        },
      );

  @override
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() {
    return _deposits.snapshots().map((snapshot) {
      try {
        final deposits = snapshot.docs.map((doc) => doc.data()).toList();
        return Success(deposits);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(
    String id,
  ) {
    return _deposits.doc(id).snapshots().map((snapshot) {
      try {
        if (!snapshot.exists) {
          return const Failure('Recurring Deposit not found');
        }
        return Success(snapshot.data()!);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Future<Result<void, String>> saveRecurringDeposit(RecurringDeposit deposit) async {
    try {
      _deposits.doc(deposit.id).set(deposit, firestore.SetOptions(merge: true));
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    try {
      _deposits.doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
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
        deposit.copyWith(id: deposit.id.isEmpty ? const Uuid().v4() : deposit.id),
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
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    final before = _deposits.length;
    _deposits.removeWhere((d) => d.id == id);
    if (_deposits.length == before) return const Failure('Recurring Deposit not found');
    _emit();
    return const Success(null);
  }
}

// Global Provider for the Repository.
@riverpod
RecurringDepositRepository recurringDepositRepository(Ref ref) {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    final repo = FakeRecurringDepositRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }

  if (Env.useSupabase) {
    return SupabaseRecurringDepositRepository(ref.watch(supabaseClientProvider));
  }

  final authState = ref.watch(authControllerProvider);
  final agentId = switch (authState) {
    AuthStateAuthenticated state => state.user.id,
    _ => null,
  };

  if (agentId == null) {
    throw StateError(
      'Agent is not authenticated. Cannot access RecurringDepositRepository.',
    );
  }

  return FirestoreRecurringDepositRepository(
    firestore.FirebaseFirestore.instance,
    agentId,
  );
}
