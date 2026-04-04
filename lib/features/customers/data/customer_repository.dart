import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:uuid/uuid.dart';

abstract class CustomerRepository {
  Future<Result<List<Customer>, String>> fetchCustomers();
  Future<Result<void, String>> createCustomer(Customer customer);
  Future<Result<void, String>> updateCustomer(Customer customer);
  Future<Result<void, String>> deleteCustomer(String id);
}

class FakeCustomerRepository implements CustomerRepository {
  final List<Customer> _customers = [
    Customer(
      id: '1',
      name: 'Bruce Wayne',
      email: 'bruce@wayneenterprises.com',
      phone: '9148173207',
      address: '1007 Mountain Drive, Gotham City',
      cifNumber: 'CIF000001',
      dateOfBirth: DateTime(1980, 2, 19),
      aadhaarNumber: '1234 5678 9012',
      panNumber: 'ABCDE1234F',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA987654321',
        nominee: Nominee(
          name: 'Alfred Pennyworth',
          relationship: 'Butler',
          phone: '9876543211',
        ),
      ),
    ),
    Customer(
      id: '2',
      name: 'Clark Kent',
      email: 'clark.kent@dailyplanet.com',
      phone: '9876543210',
      address: '344 Clinton St, Metropolis',
      cifNumber: 'CIF000002',
      dateOfBirth: DateTime(1985, 6, 18),
      aadhaarNumber: '9876 5432 1098',
      panNumber: 'FGHIJ5678K',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA123456789',
        nominee: Nominee(
          name: 'Lois Lane',
          relationship: 'Spouse',
          phone: '9876543212',
        ),
      ),
    ),
    Customer(
      id: '3',
      name: 'Diana Prince',
      email: 'diana@themyscira.gov',
      phone: '9123456780',
      address: 'Themyscira Embassy, Washington D.C.',
      cifNumber: 'CIF000003',
      dateOfBirth: DateTime(1985, 3, 22),
      aadhaarNumber: '4567 8901 2345',
      panNumber: 'LMNOP9012Q',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA456789123',
        nominee: Nominee(
          name: 'Hippolyta',
          relationship: 'Mother',
          phone: '9123456781',
        ),
      ),
    ),
    Customer(
      id: '4',
      name: 'Barry Allen',
      email: 'barry@ccpd.gov',
      phone: '9988776655',
      address: 'Central City Police Department, Central City',
      cifNumber: 'CIF000004',
      dateOfBirth: DateTime(1992, 9, 30),
      aadhaarNumber: '5678 9012 3456',
      panNumber: 'RSTUV3456W',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA567890123',
        nominee: Nominee(
          name: 'Iris West',
          relationship: 'Spouse',
          phone: '9988776656',
        ),
      ),
    ),
    Customer(
      id: '5',
      name: 'Arthur Curry',
      email: 'arthur@atlantis.gov',
      phone: '9876543210',
      address: 'Amnesty Bay, Maine',
      cifNumber: 'CIF000005',
      dateOfBirth: DateTime(1986, 1, 29),
      aadhaarNumber: '6789 0123 4567',
      panNumber: 'XYZAB7890C',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA678901234',
        nominee: Nominee(
          name: 'Mera',
          relationship: 'Spouse',
          phone: '9876543213',
        ),
      ),
    ),
  ];

  @override
  Future<Result<List<Customer>, String>> fetchCustomers() async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network latency
    return Success([..._customers]);
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newCustomer = customer.copyWith(id: const Uuid().v4());
    _customers.add(newCustomer);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _customers.indexWhere((u) => u.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      return const Success(null);
    }
    return const Failure('Customer not found');
  }

  @override
  Future<Result<void, String>> deleteCustomer(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _customers.length;
    _customers.removeWhere((u) => u.id == id);
    if (_customers.length < initialLength) {
      return const Success(null);
    }
    return const Failure('Customer not found');
  }
}

// Global Provider for the Repository.
// When we move to Firebase, we simply swap FakeUserRepository() for FirestoreUserRepository() here!
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return FakeCustomerRepository();
});
