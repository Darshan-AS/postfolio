import 'dart:collection';

import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

import 'package:uuid/uuid.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';

part 'one_time_deposits_controller.g.dart';

@riverpod
class OneTimeListCriteria extends _$OneTimeListCriteria {
  @override
  OTDSearchCriteria build() {
    final storage = ref.watch(storageServiceProvider);
    return OTDSearchCriteria(
      sortField: storage.getOTDSortField(),
      sortDirection: storage.getOTDSortDirection(),
      statusFilters: storage.getOTDStatusFilters(),
      urgencyFilters: storage.getOTDUrgencyFilters(),
      schemeFilters: storage.getOTDSchemeFilters(),
    );
  }

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);
  
  void updateSortField(OTDSortField field) {
    state = state.copyWith(sortField: field);
    ref.read(storageServiceProvider).setOTDSortField(field);
  }
  
  void updateSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
    ref.read(storageServiceProvider).setOTDSortDirection(direction);
  }
  
  void toggleStatusFilter(DepositStatus status) {
    final newFilters = state.statusFilters.contains(status)
        ? state.statusFilters.where((s) => s != status).toList()
        : [...state.statusFilters, status];
        
    state = state.copyWith(statusFilters: newFilters);
    ref.read(storageServiceProvider).setOTDStatusFilters(newFilters);
  }

  void toggleUrgencyFilter(MaturityUrgency urgency) {
    final newFilters = state.urgencyFilters.contains(urgency)
        ? state.urgencyFilters.where((u) => u != urgency).toList()
        : [...state.urgencyFilters, urgency];
        
    state = state.copyWith(urgencyFilters: newFilters);
    ref.read(storageServiceProvider).setOTDUrgencyFilters(newFilters);
  }

  void toggleSchemeFilter(OneTimeSchemeType type) {
    final newFilters = state.schemeFilters.contains(type)
        ? state.schemeFilters.where((t) => t != type).toList()
        : [...state.schemeFilters, type];
        
    state = state.copyWith(schemeFilters: newFilters);
    ref.read(storageServiceProvider).setOTDSchemeFilters(newFilters);
  }

  void clearSort() {
    state = state.copyWith(
      sortField: OTDSortField.maturityDate,
      sortDirection: SortDirection.asc,
    );
    ref.read(storageServiceProvider).setOTDSortField(OTDSortField.maturityDate);
    ref.read(storageServiceProvider).setOTDSortDirection(SortDirection.asc);
  }

  void clearAll() {
    state = const OTDSearchCriteria();
    ref.read(storageServiceProvider).setOTDSortField(OTDSortField.maturityDate);
    ref.read(storageServiceProvider).setOTDSortDirection(SortDirection.asc);
    ref.read(storageServiceProvider).setOTDStatusFilters([]);
    ref.read(storageServiceProvider).setOTDUrgencyFilters([]);
    ref.read(storageServiceProvider).setOTDSchemeFilters([]);
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilters: const [DepositStatus.active],
      urgencyFilters: const [],
      schemeFilters: const [],
    );
    ref.read(storageServiceProvider).setOTDStatusFilters([DepositStatus.active]);
    ref.read(storageServiceProvider).setOTDUrgencyFilters([]);
    ref.read(storageServiceProvider).setOTDSchemeFilters([]);
  }
}

@riverpod
Future<UnmodifiableListView<OneTimeDeposit>> filteredOneTimeDeposits(
  Ref ref,
) async {
  final criteria = ref.watch(oneTimeListCriteriaProvider);
  final asyncDeposits = await ref.watch(
    oneTimeDepositsControllerProvider.future,
  );

  // We may also need customer names to search by them
  final asyncCustomers = await ref.watch(customersControllerProvider.future);
  final customerMap = {for (var c in asyncCustomers) c.id: c.name};

  var result = asyncDeposits.toList();

  // Filters
  if (criteria.statusFilters.isNotEmpty) {
    result = result
        .where((d) => criteria.statusFilters.contains(d.status))
        .toList();
  }

  if (criteria.schemeFilters.isNotEmpty) {
    result = result
        .where((d) => criteria.schemeFilters.contains(d.schemeType))
        .toList();
  }

  if (criteria.urgencyFilters.isNotEmpty) {
    result = result
        .where((d) => criteria.urgencyFilters.contains(d.maturityUrgency))
        .toList();
  }

  // Search
  if (criteria.searchQuery.isNotEmpty) {
    final query = criteria.searchQuery.toLowerCase().trim();
    result = result.where((d) {
      final customerName = customerMap[d.customerId]?.toLowerCase() ?? '';
      return (d.accountNo?.toLowerCase().contains(query) ?? false) ||
          customerName.contains(query) ||
          d.schemeType.displayName.toLowerCase().contains(query);
    }).toList();
  }

  // Sort
  final isAsc = criteria.sortDirection.isAscending;
  switch (criteria.sortField) {
    case OTDSortField.startDate:
      result.sort((a, b) {
        final comp = a.startDate.compareTo(b.startDate);
        return isAsc ? comp : -comp;
      });
      break;
    case OTDSortField.amount:
      result.sort((a, b) {
        final comp = a.principalAmount.compareTo(b.principalAmount);
        return isAsc ? comp : -comp;
      });
      break;
    case OTDSortField.maturityDate:
      result.sort((a, b) {
        final comp = a.maturityDate.compareTo(b.maturityDate);
        return isAsc ? comp : -comp;
      });
      break;
    case OTDSortField.name:
      result.sort((a, b) {
        final nameA = customerMap[a.customerId]?.toLowerCase() ?? '';
        final nameB = customerMap[b.customerId]?.toLowerCase() ?? '';
        final comp = nameA.compareTo(nameB);
        return isAsc ? comp : -comp;
      });
      break;
  }

  return UnmodifiableListView(result);
}

@riverpod
class OneTimeDepositsController extends _$OneTimeDepositsController {
  @override
  Stream<UnmodifiableListView<OneTimeDeposit>> build() {
    return _watchOneTimeDeposits();
  }

  Stream<UnmodifiableListView<OneTimeDeposit>> _watchOneTimeDeposits() {
    final repository = ref.watch(oneTimeDepositRepositoryProvider);
    return repository.watchOneTimeDeposits().map((result) {
      return switch (result) {
        Success(value: final deposits) => UnmodifiableListView(deposits),
        Failure(error: final error) => throw Exception(error),
      };
    });
  }

  Future<Result<void, String>> saveOneTimeDeposit({
    String? id,
    String? accountNo,
    required String principalAmount,
    required int termYears,
    required int termMonths,
    String interestRate = '0.0',
    required String customerId,
    required OneTimeSchemeType schemeType,
    DepositStatus status = DepositStatus.active,
    required DateTime startDate,
    List<Nominee> nominees = const [],
  }) async {
    final depositId = id ?? const Uuid().v4();

    final amount = double.tryParse(principalAmount.trim()) ?? 0.0;
    final rate = double.tryParse(interestRate.trim()) ?? 0.0;

    final createResult = OneTimeDeposit.create(
      id: depositId,
      accountNo: accountNo,
      principalAmount: amount,
      termYears: termYears,
      termMonths: termMonths,
      interestRate: rate,
      customerId: customerId,
      schemeType: schemeType,
      status: status,
      startDate: startDate,
      nominees: nominees,
    );

    final OneTimeDeposit deposit;
    switch (createResult) {
      case Failure(error: final err):
        return Failure(err);
      case Success(value: final d):
        deposit = d;
    }

    final repository = ref.read(oneTimeDepositRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateOneTimeDeposit(deposit)
        : await repository.createOneTimeDeposit(deposit);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    final repository = ref.read(oneTimeDepositRepositoryProvider);
    final result = await repository.deleteOneTimeDeposit(id);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> toggleDepositStatus(
    String id,
    DepositStatus newStatus,
  ) async {
    final deposits = state.value;
    if (deposits == null) {
      return const Failure('Deposits not loaded');
    }

    final deposit = deposits.where((d) => d.id == id).firstOrNull;
    if (deposit == null) {
      return const Failure('Deposit not found');
    }

    final updatedDeposit = deposit.copyWith(status: newStatus);
    final repository = ref.read(oneTimeDepositRepositoryProvider);
    return await repository.updateOneTimeDeposit(updatedDeposit);
  }
}
