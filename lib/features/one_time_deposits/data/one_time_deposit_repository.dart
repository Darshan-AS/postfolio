import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:uuid/uuid.dart';

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

  FirestoreOneTimeDepositRepository(this._firestore);

  firestore.CollectionReference<Map<String, dynamic>> get _deposits =>
      _firestore.collection('one_time_deposits');

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
  Future<Result<void, String>> createOneTimeDeposit(OneTimeDeposit deposit) async {
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
  Future<Result<void, String>> updateOneTimeDeposit(OneTimeDeposit deposit) async {
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

  final List<OneTimeDeposit> _deposits = [
    OneTimeDeposit(
      id: '101',
      accountNo: '3045678912',
      principalAmount: 50000.0,
      termYears: 1,
      termMonths: 0,
      interestRate: 6.5,
      customerId: '1', // Bruce Wayne
      schemeType: OneTimeSchemeType.timeDeposit,
      startDate: DateTime(2025, 1, 1),
      linkedSavingsAccountNo: 'SA987654321',
      status: DepositStatus.active,
      nominees: const [
        Nominee(
          name: 'Alfred Pennyworth',
          relationship: NomineeRelationship.other,
          customRelationship: 'Butler',
          percentage: 50.0,
        ),
        Nominee(name: 'Dick Grayson', relationship: NomineeRelationship.other, customRelationship: 'Ward', percentage: 50.0),
      ],
    ),
    OneTimeDeposit(
      id: '102',
      accountNo: '3089123456',
      principalAmount: 25000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 7.0,
      customerId: '2', // Clark Kent
      schemeType: OneTimeSchemeType.nationalSavingsCertificate,
      startDate: DateTime(2024, 6, 15),
      linkedSavingsAccountNo: 'SA123456789',
      status: DepositStatus.active,
      nominees: const [
        Nominee(name: 'Lois Lane', relationship: NomineeRelationship.wife, percentage: 60.0),
        Nominee(name: 'Martha Kent', relationship: NomineeRelationship.mother, percentage: 40.0),
      ],
    ),
    OneTimeDeposit(
      id: '103',
      accountNo: '3099887766',
      principalAmount: 100000.0,
      termYears: 3,
      termMonths: 0,
      interestRate: 6.8,
      customerId: '3', // Diana Prince
      schemeType: OneTimeSchemeType.timeDeposit,
      startDate: DateTime(2025, 3, 1),
      linkedSavingsAccountNo: 'SA456789123',
      status: DepositStatus.matured,
      nominees: const [
        Nominee(name: 'Hippolyta', relationship: NomineeRelationship.mother, percentage: 100.0),
      ],
    ),
    OneTimeDeposit(
      id: '104',
      accountNo: '3077665544',
      principalAmount: 15000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 5.5,
      customerId: '4', // Barry Allen
      schemeType: OneTimeSchemeType.monthlyIncomeScheme,
      startDate: DateTime(2024, 10, 10),
      linkedSavingsAccountNo: 'SA567890123',
      status: DepositStatus.closed,
      nominees: const [
        Nominee(name: 'Iris West', relationship: NomineeRelationship.wife, percentage: 100.0),
      ],
    ),
    OneTimeDeposit(
      id: '105',
      accountNo: '3055443322',
      principalAmount: 75000.0,
      termYears: 9,
      termMonths: 7,
      interestRate: 6.2,
      customerId: '5', // Arthur Curry
      schemeType: OneTimeSchemeType.kisanVikasPatra,
      startDate: DateTime(2025, 4, 1),
      linkedSavingsAccountNo: 'SA678901234',
      status: DepositStatus.active,
      nominees: const [
        Nominee(name: 'Mera', relationship: NomineeRelationship.wife, percentage: 100.0),
      ],
    ),
  ];

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
    final newDeposit = deposit.copyWith(id: deposit.id.isEmpty ? const Uuid().v4() : deposit.id);
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
}

// Global Provider for the Repository.
@riverpod
OneTimeDepositRepository oneTimeDepositRepository(Ref ref) {
  const useFakeData = bool.fromEnvironment(
    'USE_FAKE_DATA',
    defaultValue: false,
  );
  if (useFakeData) {
    return FakeOneTimeDepositRepository();
  }
  return FirestoreOneTimeDepositRepository(firestore.FirebaseFirestore.instance);
}
