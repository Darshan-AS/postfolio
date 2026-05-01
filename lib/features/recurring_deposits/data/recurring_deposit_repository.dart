import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:uuid/uuid.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurring_deposit_repository.g.dart';

abstract class RecurringDepositRepository {
  Future<Result<List<RecurringDeposit>, String>> fetchRecurringDeposits();
  Future<Result<void, String>> createRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> deleteRecurringDeposit(String id);
}

class FakeRecurringDepositRepository implements RecurringDepositRepository {
  static final List<RecurringDeposit> _deposits = [
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
      maturityAmount: 350000.0,
      startDate: DateTime(2025, 2, 1),
      maturityDate: DateTime(2030, 2, 1),
      linkedAutoDebitAccountNo: 'SA987654321',
      status: DepositStatus.active,
      nominees: const [
        Nominee(
          name: 'Alfred Pennyworth',
          relationship: 'Butler',

          percentage: 50.0,
        ),
        Nominee(name: 'Dick Grayson', relationship: 'Ward', percentage: 50.0),
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
      maturityAmount: 124000.0,
      startDate: DateTime(2024, 11, 1),
      maturityDate: DateTime(2025, 11, 1),
      linkedAutoDebitAccountNo: 'SA123456789',
      status: DepositStatus.matured,
      nominees: const [
        Nominee(name: 'Lois Lane', relationship: 'Spouse', percentage: 60.0),
        Nominee(name: 'Martha Kent', relationship: 'Mother', percentage: 40.0),
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
      maturityAmount: 78000.0,
      startDate: DateTime(2025, 1, 15),
      maturityDate: DateTime(2028, 1, 15),
      linkedAutoDebitAccountNo: 'SA456789123',
      status: DepositStatus.closed,
      nominees: const [
        Nominee(name: 'Hippolyta', relationship: 'Mother', percentage: 100.0),
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
      maturityAmount: 390000.0,
      startDate: DateTime(2024, 8, 1),
      maturityDate: DateTime(2026, 8, 1),
      linkedAutoDebitAccountNo: 'SA567890123',
      status: DepositStatus.active,
      nominees: const [
        Nominee(name: 'Iris West', relationship: 'Spouse', percentage: 100.0),
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
      maturityAmount: 210000.0,
      startDate: DateTime(2025, 4, 10),
      maturityDate: DateTime(2030, 4, 10),
      linkedAutoDebitAccountNo: 'SA678901234',
      status: DepositStatus.active,
      nominees: const [
        Nominee(name: 'Mera', relationship: 'Spouse', percentage: 100.0),
      ],
    ),
  ];

  @override
  Future<Result<List<RecurringDeposit>, String>>
  fetchRecurringDeposits() async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network latency
    return Success([..._deposits]);
  }

  @override
  Future<Result<void, String>> createRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDeposit = deposit.copyWith(id: const Uuid().v4());
    _deposits.add(newDeposit);
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
      return const Success(null);
    }
    return const Failure('Recurring Deposit not found');
  }
}

// Global Provider for the Repository.
@riverpod
RecurringDepositRepository recurringDepositRepository(Ref ref) {
  return FakeRecurringDepositRepository();
}
