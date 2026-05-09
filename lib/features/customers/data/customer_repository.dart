import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'customer_repository.g.dart';

abstract class CustomerRepository {
  Stream<Result<List<Customer>, String>> watchCustomers();
  Future<Result<void, String>> createCustomer(Customer customer);
  Future<Result<void, String>> updateCustomer(Customer customer);
  Future<Result<void, String>> deleteCustomer(String id);
}

class FirestoreCustomerRepository implements CustomerRepository {
  final firestore.FirebaseFirestore _firestore;

  FirestoreCustomerRepository(this._firestore);

  firestore.CollectionReference<Map<String, dynamic>> get _customers =>
      _firestore.collection('customers');

  @override
  Stream<Result<List<Customer>, String>> watchCustomers() {
    return _customers.snapshots().map((snapshot) {
      try {
        final customers = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Inject the document ID into the data
          return Customer.fromJson(data);
        }).toList();
        return Success(customers);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    try {
      final docRef = _customers.doc(customer.id);

      final data = customer.toJson();
      data.remove('id'); // Remove id from body as it's the doc key

      // We use .set() without awaiting the server sync.
      // This allows offline writes to resolve immediately to the UI, 
      // relying on Firestore's background syncing.
      docRef.set(data);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    try {
      final data = customer.toJson();
      data.remove('id');
      
      _customers.doc(customer.id).update(data);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> deleteCustomer(String id) async {
    try {
      _customers.doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

class FakeCustomerRepository implements CustomerRepository {
  final _controller =
      StreamController<Result<List<Customer>, String>>.broadcast();

  final List<Customer> _customers = FakeDataSource().customers.toList();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Success([..._customers]));
    }
  }

  @override
  Stream<Result<List<Customer>, String>> watchCustomers() async* {
    // Yield initial data immediately for new listeners
    yield Success([..._customers]);
    // Then yield any future updates
    yield* _controller.stream;
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _customers.add(customer);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _customers.indexWhere((u) => u.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      _emit();
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
      _emit();
      return const Success(null);
    }
    return const Failure('Customer not found');
  }
}

// Global Provider for the Repository.
@riverpod
CustomerRepository customerRepository(Ref ref) {
  const useFakeData = bool.fromEnvironment(
    'USE_FAKE_DATA',
    defaultValue: false,
  );
  if (useFakeData) {
    return FakeCustomerRepository();
  }
  return FirestoreCustomerRepository(firestore.FirebaseFirestore.instance);
}
