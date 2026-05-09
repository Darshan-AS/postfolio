import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:uuid/uuid.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurring_deposit_repository.g.dart';

abstract class RecurringDepositRepository {
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits();
  Future<Result<void, String>> createRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> deleteRecurringDeposit(String id);
}

class FirestoreRecurringDepositRepository implements RecurringDepositRepository {
  final firestore.FirebaseFirestore _firestore;

  FirestoreRecurringDepositRepository(this._firestore);

  firestore.CollectionReference<Map<String, dynamic>> get _deposits =>
      _firestore.collection('recurring_deposits');

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
  Future<Result<void, String>> createRecurringDeposit(RecurringDeposit deposit) async {
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
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit) async {
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

  final List<RecurringDeposit> _deposits = [
    RecurringDeposit(
      id: '201',
      serialNo: 'RD-001',
      accountNo: 'RD-9021345',
      installmentAmount: 5000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      customerId: '1', // Bruce Wayne
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2025, 2, 1),
      linkedAutoDebitAccountNo: 'SA987654321',
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
    RecurringDeposit(
      id: '202',
      serialNo: 'RD-002',
      accountNo: 'RD-9025678',
      installmentAmount: 10000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.0,
      customerId: '2', // Clark Kent
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2024, 11, 1),
      linkedAutoDebitAccountNo: 'SA123456789',
      status: DepositStatus.matured,
      nominees: const [
        Nominee(name: 'Lois Lane', relationship: NomineeRelationship.wife, percentage: 60.0),
        Nominee(name: 'Martha Kent', relationship: NomineeRelationship.mother, percentage: 40.0),
      ],
    ),
    RecurringDeposit(
      id: '203',
      serialNo: 'RD-003',
      accountNo: 'RD-9029988',
      installmentAmount: 2000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.5,
      customerId: '3', // Diana Prince
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2025, 1, 15),
      linkedAutoDebitAccountNo: 'SA456789123',
      status: DepositStatus.closed,
      nominees: const [
        Nominee(name: 'Hippolyta', relationship: NomineeRelationship.mother, percentage: 100.0),
      ],
    ),
    RecurringDeposit(
      id: '204',
      serialNo: 'RD-004',
      accountNo: 'RD-9027766',
      installmentAmount: 15000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.8,
      customerId: '4', // Barry Allen
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2024, 8, 1),
      linkedAutoDebitAccountNo: 'SA567890123',
      status: DepositStatus.active,
      nominees: const [
        Nominee(name: 'Iris West', relationship: NomineeRelationship.wife, percentage: 100.0),
      ],
    ),
    RecurringDeposit(
      id: '205',
      serialNo: 'RD-005',
      accountNo: 'RD-9025544',
      installmentAmount: 3000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 7.0,
      customerId: '5', // Arthur Curry
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2025, 4, 10),
      linkedAutoDebitAccountNo: 'SA678901234',
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
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() async* {
    yield Success([..._deposits]);
    yield* _controller.stream;
  }

  @override
  Future<Result<void, String>> createRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDeposit = deposit.copyWith(id: deposit.id.isEmpty ? const Uuid().v4() : deposit.id);
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
}

// Global Provider for the Repository.
@riverpod
RecurringDepositRepository recurringDepositRepository(Ref ref) {
  const useFakeData = bool.fromEnvironment(
    'USE_FAKE_DATA',
    defaultValue: false,
  );
  if (useFakeData) {
    return FakeRecurringDepositRepository();
  }
  return FirestoreRecurringDepositRepository(firestore.FirebaseFirestore.instance);
}
