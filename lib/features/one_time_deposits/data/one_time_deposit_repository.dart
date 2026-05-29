import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:uuid/uuid.dart';

import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'one_time_deposit_repository.g.dart';

abstract class OneTimeDepositRepository {
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits();
  Future<Result<void, String>> createOneTimeDeposit(OneTimeDeposit deposit);
  Future<Result<void, String>> updateOneTimeDeposit(OneTimeDeposit deposit);
  Future<Result<void, String>> deleteOneTimeDeposit(String id);
}

class FirestoreOneTimeDepositRepository implements OneTimeDepositRepository {
  final firestore.FirebaseFirestore _firestore;
  final String _userId;

  FirestoreOneTimeDepositRepository(this._firestore, this._userId);

  firestore.CollectionReference<Map<String, dynamic>> get _deposits =>
      _firestore.collection('users').doc(_userId).collection('one_time_deposits');

  @override
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits() {
    return _deposits.snapshots().map((snapshot) {
      try {
        final deposits = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return OneTimeDeposit.fromJson(data);
        }).toList();
        return Success(deposits);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Future<Result<void, String>> createOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    try {
      final docRef = _deposits.doc(deposit.id);

      final data = deposit.toJson();
      data.remove('id');

      // We use .set() without awaiting the server sync.
      docRef.set(data);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateOneTimeDeposit(
    OneTimeDeposit deposit,
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
  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    try {
      _deposits.doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

class FakeOneTimeDepositRepository implements OneTimeDepositRepository {
  final _controller =
      StreamController<Result<List<OneTimeDeposit>, String>>.broadcast();

  final List<OneTimeDeposit> _deposits = FakeDataSource().oneTimeDeposits
      .toList();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Success([..._deposits]));
    }
  }

  @override
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits() async* {
    yield Success([..._deposits]);
    yield* _controller.stream;
  }

  @override
  Future<Result<void, String>> createOneTimeDeposit(
    OneTimeDeposit deposit,
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
  Future<Result<void, String>> updateOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _deposits.indexWhere((d) => d.id == deposit.id);
    if (index != -1) {
      _deposits[index] = deposit;
      _emit();
      return const Success(null);
    }
    return const Failure('One Time Deposit not found');
  }

  @override
  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _deposits.length;
    _deposits.removeWhere((d) => d.id == id);
    if (_deposits.length < initialLength) {
      _emit();
      return const Success(null);
    }
    return const Failure('One Time Deposit not found');
  }

  void dispose() {
    _controller.close();
  }
}

// Global Provider for the Repository.
@riverpod
OneTimeDepositRepository oneTimeDepositRepository(Ref ref) {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    final repo = FakeOneTimeDepositRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }

  final authState = ref.watch(authControllerProvider);
  final userId = authState.mapOrNull(
    authenticated: (state) => state.user.id,
  );

  if (userId == null) {
    throw StateError('User is not authenticated. Cannot access OneTimeDepositRepository.');
  }

  return FirestoreOneTimeDepositRepository(
    firestore.FirebaseFirestore.instance,
    userId,
  );
}
