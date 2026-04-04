import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';

part 'customers_controller.g.dart';

@riverpod
class CustomersController extends _$CustomersController {
  @override
  FutureOr<UnmodifiableListView<Customer>> build() async {
    return _fetchCustomers();
  }

  Future<UnmodifiableListView<Customer>> _fetchCustomers() async {
    final repository = ref.read(customerRepositoryProvider);
    final result = await repository.fetchCustomers();

    return switch (result) {
      Success(value: final customers) => UnmodifiableListView(customers),
      Failure(error: final error) => throw Exception(error),
    };
  }

  Future<Result<void, String>> saveCustomer({
    String? id,
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    final (error, customer) = Customer.create(
      id: id ?? '', // FakeRepo will assign a real ID if creating
      name: name,
      email: email,
      phone: phone,
      address: address,
    );

    if (error != null || customer == null) {
      return Failure(error ?? 'Invalid customer data provided');
    }

    final repository = ref.read(customerRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateCustomer(customer)
        : await repository.createCustomer(customer);

    return switch (result) {
      Success() => () {
        ref.invalidateSelf(); // Triggers a re-fetch and rebuild
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteCustomer(String id) async {
    final repository = ref.read(customerRepositoryProvider);
    final result = await repository.deleteCustomer(id);

    return switch (result) {
      Success() => () {
        ref.invalidateSelf();
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }
}
