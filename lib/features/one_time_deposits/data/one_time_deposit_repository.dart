import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/nominee.dart';
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
      customerId: '1', // Bruce Wayne
      schemeType: OneTimeSchemeType.timeDeposit,
      maturityAmount: 55000.0,
      startDate: DateTime(2025, 1, 1),
      maturityDate: DateTime(2026, 7, 1),
      linkedSavingsAccountNo: 'SA987654321',
      nominees: const [
        Nominee(
          name: 'Alfred Pennyworth',
          relationship: 'Butler',
          phone: '9876543211',
          percentage: 50.0,
        ),
        Nominee(
          name: 'Dick Grayson',
          relationship: 'Ward',
          phone: '9876543210',
          percentage: 50.0,
        ),
      ],
    ),
    OneTimeDeposit(
      id: '102',
      rowId: 'OTD-002',
      accountNo: '3089123456',
      principalAmount: 25000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 7.0,
      customerId: '2', // Clark Kent
      schemeType: OneTimeSchemeType.nationalSavingsCertificate,
      maturityAmount: 35000.0,
      startDate: DateTime(2024, 6, 15),
      maturityDate: DateTime(2029, 6, 15),
      linkedSavingsAccountNo: 'SA123456789',
      nominees: const [
        Nominee(
          name: 'Lois Lane',
          relationship: 'Spouse',
          phone: '9876543212',
          percentage: 60.0,
        ),
        Nominee(
          name: 'Martha Kent',
          relationship: 'Mother',
          phone: '9876543213',
          percentage: 40.0,
        ),
      ],
    ),
    OneTimeDeposit(
      id: '103',
      rowId: 'OTD-003',
      accountNo: '3099887766',
      principalAmount: 100000.0,
      termYears: 3,
      termMonths: 0,
      interestRate: 6.8,
      customerId: '3', // Diana Prince
      schemeType: OneTimeSchemeType.timeDeposit,
      maturityAmount: 122000.0,
      startDate: DateTime(2025, 3, 1),
      maturityDate: DateTime(2028, 3, 1),
      linkedSavingsAccountNo: 'SA456789123',
      nominees: const [
        Nominee(
          name: 'Hippolyta',
          relationship: 'Mother',
          phone: '9123456781',
          percentage: 100.0,
        ),
      ],
    ),
    OneTimeDeposit(
      id: '104',
      rowId: 'OTD-004',
      accountNo: '3077665544',
      principalAmount: 15000.0,
      termYears: 1,
      termMonths: 0,
      interestRate: 5.5,
      customerId: '4', // Barry Allen
      schemeType: OneTimeSchemeType.monthlyIncomeScheme,
      maturityAmount: 15000.0,
      startDate: DateTime(2024, 10, 10),
      maturityDate: DateTime(2025, 10, 10),
      linkedSavingsAccountNo: 'SA567890123',
      nominees: const [
        Nominee(
          name: 'Iris West',
          relationship: 'Spouse',
          phone: '9988776656',
          percentage: 100.0,
        ),
      ],
    ),
    OneTimeDeposit(
      id: '105',
      rowId: 'OTD-005',
      accountNo: '3055443322',
      principalAmount: 75000.0,
      termYears: 2,
      termMonths: 6,
      interestRate: 6.2,
      customerId: '5', // Arthur Curry
      schemeType: OneTimeSchemeType.kisanVikasPatra,
      maturityAmount: 90000.0,
      startDate: DateTime(2025, 4, 1),
      maturityDate: DateTime(2027, 10, 1),
      linkedSavingsAccountNo: 'SA678901234',
      nominees: const [
        Nominee(
          name: 'Mera',
          relationship: 'Spouse',
          phone: '9876543213',
          percentage: 100.0,
        ),
      ],
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
