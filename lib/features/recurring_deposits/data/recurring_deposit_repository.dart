import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:uuid/uuid.dart';

abstract class RecurringDepositRepository {
  Future<Result<List<RecurringDeposit>, String>> fetchRecurringDeposits();
  Future<Result<void, String>> createRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> deleteRecurringDeposit(String id);
}

class FakeRecurringDepositRepository implements RecurringDepositRepository {
  final List<RecurringDeposit> _deposits = [
    RecurringDeposit(
      id: '201',
      accountNo: 'RD-9021345',
      installmentAmount: 5000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      customerId: '1', // Abdul Khalandar
      schemeType: RecurringSchemeType.recurringDeposit,
      maturityAmount: 350000.0,
      startDate: DateTime(2025, 2, 1),
      maturityDate: DateTime(2030, 2, 1),
    ),
    RecurringDeposit(
      id: '202',
      accountNo: 'RD-9025678',
      installmentAmount: 10000.0,
      termYears: 1,
      termMonths: 0,
      interestRate: 6.0,
      customerId: '2', // Darshan A S
      schemeType: RecurringSchemeType.recurringDeposit,
      maturityAmount: 124000.0,
      startDate: DateTime(2024, 11, 1),
      maturityDate: DateTime(2025, 11, 1),
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
final recurringDepositRepositoryProvider = Provider<RecurringDepositRepository>(
  (ref) {
    return FakeRecurringDepositRepository();
  },
);
