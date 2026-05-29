import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:uuid/uuid.dart';

import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurring_deposit_repository.g.dart';

abstract class RecurringDepositRepository {
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits();
  Future<Result<void, String>> createRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> deleteRecurringDeposit(String id);
}

class FirestoreRecurringDepositRepository
    implements RecurringDepositRepository {
  final firestore.FirebaseFirestore _firestore;
  final String _userId;

  FirestoreRecurringDepositRepository(this._firestore, this._userId);

  firestore.CollectionReference<Map<String, dynamic>> get _deposits =>
      _firestore.collection('users').doc(_userId).collection('recurring_deposits');

  @override
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() {
    return _deposits.snapshots().map((snapshot) {
      try {
        final deposits = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return RecurringDeposit.fromJson(data);
        }).toList();
        return Success(deposits);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Future<Result<void, String>> createRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    try {
      final docRef = _deposits.doc(deposit.id);

      final data = deposit.toJson();
      data.remove('id');

      docRef.set(data);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    try {
      final data = deposit.toJson();
      data.remove('id');

      _deposits.doc(deposit.id).update(data);
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

class FakeRecurringDepositRepository implements RecurringDepositRepository {
  final _controller =
      StreamController<Result<List<RecurringDeposit>, String>>.broadcast();

  final List<RecurringDeposit> _deposits = FakeDataSource().recurringDeposits
      .toList();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Success([..._deposits]));
    }
  }

  @override
  Stream<Result<List<RecurringDeposit>, String>>
  watchRecurringDeposits() async* {
    yield Success([..._deposits]);
    yield* _controller.stream;
  }

  @override
  Future<Result<void, String>> createRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDeposit = deposit.copyWith(
      id: deposit.id.isEmpty ? const Uuid().v4() : deposit.id,
    );
    _deposits.add(newDeposit);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _deposits.indexWhere((d) => d.id == deposit.id);
    if (index != -1) {
      _deposits[index] = deposit;
      _emit();
      return const Success(null);
    }
    return const Failure('Recurring Deposit not found');
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _deposits.length;
    _deposits.removeWhere((d) => d.id == id);
    if (_deposits.length < initialLength) {
      _emit();
      return const Success(null);
    }
    return const Failure('Recurring Deposit not found');
  }

  void dispose() {
    _controller.close();
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

  final authState = ref.watch(authControllerProvider);
  final userId = authState.mapOrNull(
    authenticated: (state) => state.user.id,
  );

  if (userId == null) {
    throw StateError('User is not authenticated. Cannot access RecurringDepositRepository.');
  }

  return FirestoreRecurringDepositRepository(
    firestore.FirebaseFirestore.instance,
    userId,
  );
}
