import 'dart:collection';

import 'package:postfolio/features/customers/domain/customer_search_criteria.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:uuid/uuid.dart';

part 'customers_controller.g.dart';

@riverpod
class CustomerListCriteria extends _$CustomerListCriteria {
  @override
  CustomerSearchCriteria build() {
    final storage = ref.watch(storageServiceProvider);
    return CustomerSearchCriteria(
      sortField: storage.getCustomerSortField(),
      sortDirection: storage.getCustomerSortDirection(),
    );
  }

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);

  void updateSortField(CustomerSortField field) {
    state = state.copyWith(sortField: field);
    ref.read(storageServiceProvider).setCustomerSortField(field);
  }

  void updateSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
    ref.read(storageServiceProvider).setCustomerSortDirection(direction);
  }

  void clearSort() {
    state = state.copyWith(
      sortField: CustomerSortField.name,
      sortDirection: SortDirection.asc,
    );
    ref
        .read(storageServiceProvider)
        .setCustomerSortField(CustomerSortField.name);
    ref
        .read(storageServiceProvider)
        .setCustomerSortDirection(SortDirection.asc);
  }

  void clearAll() {
    state = const CustomerSearchCriteria();
    ref
        .read(storageServiceProvider)
        .setCustomerSortField(CustomerSortField.name);
    ref
        .read(storageServiceProvider)
        .setCustomerSortDirection(SortDirection.asc);
  }
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
  final isAsc = criteria.sortDirection.isAscending;
  switch (criteria.sortField) {
    case CustomerSortField.name:
      result.sort((a, b) {
        final comp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return isAsc ? comp : -comp;
      });
      break;
    case CustomerSortField.createdAt:
      result.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final comp = dateA.compareTo(dateB);
        return isAsc ? comp : -comp;
      });
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
