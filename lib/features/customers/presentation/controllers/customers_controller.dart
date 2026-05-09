import 'dart:collection';

import 'package:postfolio/core/models/nominee.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:uuid/uuid.dart';

part 'customers_controller.g.dart';

@riverpod
class CustomersController extends _$CustomersController {
  @override
  Stream<UnmodifiableListView<Customer>> build() {
    return _watchCustomers();
  }

  Stream<UnmodifiableListView<Customer>> _watchCustomers() {
    final repository = ref.watch(customerRepositoryProvider);
    return repository.watchCustomers().map((result) {
      return switch (result) {
        Success(value: final customers) => UnmodifiableListView(customers),
        Failure(error: final error) => throw Exception(error),
      };
    });
  }

  Future<Result<void, String>> saveCustomer({
    String? id,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? cifNumber,
    DateTime? dateOfBirth,
    String? aadhaarNumber,
    String? panNumber,
    String? savingsAccountNumber,
    List<Nominee>? savingsNominees,
  }) async {
    final customerId = id ?? const Uuid().v4();

    final createResult = Customer.create(
      id: customerId,
      name: name,
      email: email,
      phone: phone,
      address: address,
      cifNumber: cifNumber,
      dateOfBirth: dateOfBirth,
      aadhaarNumber: aadhaarNumber,
      panNumber: panNumber,
      savingsAccountNumber: savingsAccountNumber,
      savingsNominees: savingsNominees,
    );

    final Customer customer;
    switch (createResult) {
      case Failure(error: final err):
        return Failure(err);
      case Success(value: final c):
        customer = c;
    }

    final repository = ref.read(customerRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateCustomer(customer)
        : await repository.createCustomer(customer);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteCustomer(String id) async {
    final repository = ref.read(customerRepositoryProvider);
    final result = await repository.deleteCustomer(id);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }
}

@riverpod
Customer? customerById(Ref ref, String id) {
  final customersState = ref.watch(customersControllerProvider);
  return customersState.value?.where((c) => c.id == id).firstOrNull;
}
