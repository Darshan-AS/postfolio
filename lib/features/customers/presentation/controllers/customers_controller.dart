import 'dart:collection';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/domain/customer_search_criteria.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:uuid/uuid.dart';

part 'customers_controller.g.dart';

typedef CustomerDepositsSummary = ({
  List<OneTimeDeposit> activeOneTime,
  List<OneTimeDeposit> closedOneTime,
  List<RecurringDeposit> activeRecurring,
  List<RecurringDeposit> closedRecurring,
});

@riverpod
class CustomerListCriteria extends _$CustomerListCriteria {
  @override
  CustomerSearchCriteria build() {
    final storage = ref.watch(storageServiceProvider);
    const defaults = CustomerSearchCriteria();
    return defaults.copyWith(
      sortField: storage.getCustomerSortField() ?? defaults.sortField,
      sortDirection:
          storage.getCustomerSortDirection() ?? defaults.sortDirection,
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
    ref.watch(activeSessionKeyProvider);
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
    String? notes,
  }) async {
    final customerId = id ?? const Uuid().v7();

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
      notes: notes,
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

/// The list's record of a customer, once the list has loaded it.
///
/// It is what the customer's row is built from: the customer's own details, without the
/// savings account and its nominees, which only [customerById] fetches. A screen opened
/// from the list shows its head from this record until the full one arrives.
@riverpod
Customer? customerInList(Ref ref, String id) => ref
    .watch(customersControllerProvider)
    .value
    ?.where((customer) => customer.id == id)
    .firstOrNull;

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

@riverpod
CustomerDepositsSummary customerDeposits(Ref ref, String customerId) {
  final otds =
      ref
          .watch(oneTimeDepositsControllerProvider)
          .value
          ?.where((d) => d.customerId == customerId)
          .toList() ??
      const <OneTimeDeposit>[];
  final rds =
      ref
          .watch(recurringDepositsControllerProvider)
          .value
          ?.where((d) => d.customerId == customerId)
          .toList() ??
      const <RecurringDeposit>[];

  final activeOneTime =
      otds.where((d) => d.status == DepositStatus.active).toList()
        ..sort(OneTimeDeposit.defaultCompare);
  final closedOneTime =
      otds.where((d) => d.status == DepositStatus.closed).toList()
        ..sort(OneTimeDeposit.defaultCompare);
  final activeRecurring =
      rds.where((d) => d.status == DepositStatus.active).toList()
        ..sort(RecurringDeposit.defaultCompare);
  final closedRecurring =
      rds.where((d) => d.status == DepositStatus.closed).toList()
        ..sort(RecurringDeposit.defaultCompare);

  return (
    activeOneTime: List.unmodifiable(activeOneTime),
    closedOneTime: List.unmodifiable(closedOneTime),
    activeRecurring: List.unmodifiable(activeRecurring),
    closedRecurring: List.unmodifiable(closedRecurring),
  );
}
