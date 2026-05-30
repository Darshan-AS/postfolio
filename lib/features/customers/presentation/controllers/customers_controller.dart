import 'dart:collection';

import 'package:postfolio/core/models/list_criteria.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:uuid/uuid.dart';

part 'customers_controller.g.dart';

@riverpod
class CustomerListCriteria extends _$CustomerListCriteria {
  @override
  ListCriteria build() => const ListCriteria();

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);
  void updateSort(SortOption sort) => state = state.copyWith(sortBy: sort);
  void clearAll() => state = const ListCriteria();
}

@riverpod
Future<UnmodifiableListView<Customer>> filteredCustomers(Ref ref) async {
  final criteria = ref.watch(customerListCriteriaProvider);
  final asyncCustomers = await ref.watch(customersControllerProvider.future);

  var result = asyncCustomers.toList();

  // Search
  if (criteria.searchQuery.isNotEmpty) {
    final query = criteria.searchQuery.toLowerCase().trim();
    result = result.where((c) {
      return c.name.toLowerCase().contains(query) ||
             (c.phone?.contains(query) ?? false) ||
             (c.cifNumber?.toLowerCase().contains(query) ?? false) ||
             (c.aadhaarNumber?.contains(query) ?? false) ||
             (c.panNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Sort
  switch (criteria.sortBy) {
    case SortOption.nameAsc:
      result.sort((a, b) => a.name.compareTo(b.name));
      break;
    case SortOption.nameDesc:
      result.sort((a, b) => b.name.compareTo(a.name));
      break;
    case SortOption.newest:
    case SortOption.oldest:
    case SortOption.highestAmount:
    case SortOption.maturityProximity:
      // Customers don't have these by default, fallback to nameAsc or just keep as is
      break;
  }

  return UnmodifiableListView(result);
}

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
Stream<Customer> customerById(Ref ref, String id) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomerById(id).map((result) {
    return switch (result) {
      Success(value: final customer) => customer,
      Failure(error: final error) => throw Exception(error),
    };
  });
}
