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
      
      address: '1007 Mountain Drive, Gotham City',
      cifNumber: 'CIF000001',
      dateOfBirth: DateTime(1980, 2, 19),
      aadhaarNumber: '1234 5678 9012',
      panNumber: 'ABCDE1234F',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA987654321',
        nominees: [
          Nominee(
            percentage: 50.0,
            name: 'Alfred Pennyworth',
            relationship: 'Butler',
            
          ),
          Nominee(
            percentage: 50.0,
            name: 'Dick Grayson',
            relationship: 'Ward',
            
          ),
        ],
      ),
    ),
    Customer(
      id: '2',
      name: 'Clark Kent',
      email: 'clark.kent@dailyplanet.com',
      
      address: '344 Clinton St, Metropolis',
      cifNumber: 'CIF000002',
      dateOfBirth: DateTime(1985, 6, 18),
      aadhaarNumber: '9876 5432 1098',
      panNumber: 'FGHIJ5678K',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA123456789',
        nominees: [
          Nominee(
            percentage: 60.0,
            name: 'Lois Lane',
            relationship: 'Spouse',
            
          ),
          Nominee(
            percentage: 40.0,
            name: 'Martha Kent',
            relationship: 'Mother',
            
          ),
        ],
      ),
    ),
    Customer(
      id: '3',
      name: 'Diana Prince',
      email: 'diana@themyscira.gov',
      
      address: 'Themyscira Embassy, Washington D.C.',
      cifNumber: 'CIF000003',
      dateOfBirth: DateTime(1985, 3, 22),
      aadhaarNumber: '4567 8901 2345',
      panNumber: 'LMNOP9012Q',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA456789123',
        nominees: [
          Nominee(
            percentage: 100.0,
            name: 'Hippolyta',
            relationship: 'Mother',
            
          ),
        ],
      ),
    ),
    Customer(
      id: '4',
      name: 'Barry Allen',
      email: 'barry@ccpd.gov',
      
      address: 'Central City Police Department, Central City',
      cifNumber: 'CIF000004',
      dateOfBirth: DateTime(1992, 9, 30),
      aadhaarNumber: '5678 9012 3456',
      panNumber: 'RSTUV3456W',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA567890123',
        nominees: [
          Nominee(
            percentage: 100.0,
            name: 'Iris West',
            relationship: 'Spouse',
            
          ),
        ],
      ),
    ),
    Customer(
      id: '5',
      name: 'Arthur Curry',
      email: 'arthur@atlantis.gov',
      
      address: 'Amnesty Bay, Maine',
      cifNumber: 'CIF000005',
      dateOfBirth: DateTime(1986, 1, 29),
      aadhaarNumber: '6789 0123 4567',
      panNumber: 'XYZAB7890C',
      savingsAccount: const SavingsAccount(
        accountNumber: 'SA678901234',
        nominees: [
          Nominee(
            percentage: 100.0,
            name: 'Mera',
            relationship: 'Spouse',
            
          ),
        ],
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
