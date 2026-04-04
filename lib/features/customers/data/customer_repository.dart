import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    const Customer(id: '1', name: 'Abdul Khalandar', phone: '9148173207'),
    const Customer(id: '2', name: 'Darshan A S', phone: '9876543210'),
    const Customer(id: '3', name: 'Jane Doe', email: 'jane@example.com'),
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
