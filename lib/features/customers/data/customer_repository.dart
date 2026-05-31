import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/constants/firestore_keys.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'customer_repository.g.dart';

abstract class CustomerRepository {
  Stream<Result<List<Customer>, String>> watchCustomers();
  Stream<Result<Customer, String>> watchCustomerById(String id);
  Future<Result<void, String>> createCustomer(Customer customer);
  Future<Result<void, String>> updateCustomer(Customer customer);
  Future<Result<void, String>> deleteCustomer(String id);
}

class FirestoreCustomerRepository implements CustomerRepository {
  final firestore.FirebaseFirestore _firestore;
  final String _userId;

  FirestoreCustomerRepository(this._firestore, this._userId);

  firestore.CollectionReference<Customer> get _customers => _firestore
      .collection(FirestoreCollections.users)
      .doc(_userId)
      .collection(FirestoreCollections.customers)
      .withConverter<Customer>(
        fromFirestore: (snapshot, _) {
          final data = snapshot.data()!;
          data[FirestoreKeys.id] = snapshot.id;
          return Customer.fromJson(data);
        },
        toFirestore: (customer, _) {
          final data = customer.toJson();
          data.remove(FirestoreKeys.id); // ID is part of the doc metadata
          if (customer.createdAt == null) {
            data[FirestoreKeys.createdAt] =
                firestore.FieldValue.serverTimestamp();
          }
          data[FirestoreKeys.updatedAt] =
              firestore.FieldValue.serverTimestamp();
          return data;
        },
      );

  @override
  Stream<Result<List<Customer>, String>> watchCustomers() {
    return _customers.snapshots().map((snapshot) {
      try {
        final customers = snapshot.docs.map((doc) => doc.data()).toList();
        return Success(customers);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Stream<Result<Customer, String>> watchCustomerById(String id) {
    return _customers.doc(id).snapshots().map((snapshot) {
      try {
        if (!snapshot.exists) {
          return const Failure('Customer not found');
        }
        return Success(snapshot.data()!);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    try {
      // We use .set() without awaiting the server sync.
      // This allows offline writes to resolve immediately to the UI,
      // relying on Firestore's background syncing.
      _customers.doc(customer.id).set(customer);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    try {
      _customers
          .doc(customer.id)
          .set(customer, firestore.SetOptions(merge: true));
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
  Stream<Result<Customer, String>> watchCustomerById(String id) async* {
    final customer = _customers.where((c) => c.id == id).firstOrNull;
    if (customer != null) {
      yield Success(customer);
    } else {
      yield const Failure('Customer not found');
    }

    yield* _controller.stream.map((result) {
      return switch (result) {
        Success(value: final customers) => () {
          final c = customers.where((c) => c.id == id).firstOrNull;
          if (c != null) {
            return Success<Customer, String>(c);
          }
          return const Failure<Customer, String>('Customer not found');
        }(),
        Failure(error: final error) => Failure(error),
      };
    });
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

  void dispose() {
    _controller.close();
  }
}

// Global Provider for the Repository.
@riverpod
CustomerRepository customerRepository(Ref ref) {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    final repo = FakeCustomerRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }

  final authState = ref.watch(authControllerProvider);
  final userId = authState.mapOrNull(authenticated: (state) => state.user.id);

  if (userId == null) {
    throw StateError(
      'User is not authenticated. Cannot access CustomerRepository.',
    );
  }

  return FirestoreCustomerRepository(
    firestore.FirebaseFirestore.instance,
    userId,
  );
}
