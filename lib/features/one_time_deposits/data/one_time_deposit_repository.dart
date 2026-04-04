import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:uuid/uuid.dart';

abstract class OneTimeDepositRepository {
  Future<Result<List<OneTimeDeposit>, String>> fetchOneTimeDeposits();
  Future<Result<void, String>> createOneTimeDeposit(OneTimeDeposit deposit);
  Future<Result<void, String>> updateOneTimeDeposit(OneTimeDeposit deposit);
  Future<Result<void, String>> deleteOneTimeDeposit(String id);
}

class FakeOneTimeDepositRepository implements OneTimeDepositRepository {
  final List<OneTimeDeposit> _deposits = [
    OneTimeDeposit(
      id: '101',
      rowId: 'OTD-001',
      accountNo: '3045678912',
      principalAmount: 50000.0,
      termYears: 1,
      termMonths: 6,
      interestRate: 6.5,
      customerId: '1', // Abdul Khalandar
      schemeType: OneTimeSchemeType.timeDeposit,
      maturityAmount: 55000.0,
      startDate: DateTime(2025, 1, 1),
      maturityDate: DateTime(2026, 7, 1),
    ),
    OneTimeDeposit(
      id: '102',
      rowId: 'OTD-002',
      accountNo: '3089123456',
      principalAmount: 25000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 7.0,
      customerId: '2', // Darshan A S
      schemeType: OneTimeSchemeType.nationalSavingsCertificate,
      maturityAmount: 35000.0,
      startDate: DateTime(2024, 6, 15),
      maturityDate: DateTime(2029, 6, 15),
    ),
  ];

  @override
  Future<Result<List<OneTimeDeposit>, String>> fetchOneTimeDeposits() async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network latency
    return Success([..._deposits]);
  }

  @override
  Future<Result<void, String>> createOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDeposit = deposit.copyWith(id: const Uuid().v4());
    _deposits.add(newDeposit);
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
      return const Success(null);
    }
    return const Failure('One Time Deposit not found');
  }
}

// Global Provider for the Repository.
final oneTimeDepositRepositoryProvider = Provider<OneTimeDepositRepository>((
  ref,
) {
  return FakeOneTimeDepositRepository();
});
