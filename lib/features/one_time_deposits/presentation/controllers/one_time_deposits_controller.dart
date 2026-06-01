import 'dart:collection';

import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
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
  OTDSearchCriteria build() => const OTDSearchCriteria();

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);
  void updateSort(OTDSortOption sort) => state = state.copyWith(sortBy: sort);
  void toggleStatusFilter(DepositStatus status) {
    if (state.statusFilters.contains(status)) {
      state = state.copyWith(
        statusFilters: state.statusFilters.where((s) => s != status).toList(),
      );
    } else {
      state = state.copyWith(statusFilters: [...state.statusFilters, status]);
    }
  }

  void toggleUrgencyFilter(MaturityUrgency urgency) {
    if (state.urgencyFilters.contains(urgency)) {
      state = state.copyWith(
        urgencyFilters: state.urgencyFilters
            .where((u) => u != urgency)
            .toList(),
      );
    } else {
      state = state.copyWith(
        urgencyFilters: [...state.urgencyFilters, urgency],
      );
    }
  }

  void toggleSchemeFilter(OneTimeSchemeType type) {
    if (state.schemeFilters.contains(type)) {
      state = state.copyWith(
        schemeFilters: state.schemeFilters.where((t) => t != type).toList(),
      );
    } else {
      state = state.copyWith(schemeFilters: [...state.schemeFilters, type]);
    }
  }

  void clearAll() => state = const OTDSearchCriteria();

  void clearFilters() {
    state = state.copyWith(
      statusFilters: const [DepositStatus.active],
      urgencyFilters: const [],
      schemeFilters: const [],
    );
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
  switch (criteria.sortBy) {
    case OTDSortOption.newest:
      result.sort((a, b) => b.startDate.compareTo(a.startDate));
      break;
    case OTDSortOption.oldest:
      result.sort((a, b) => a.startDate.compareTo(b.startDate));
      break;
    case OTDSortOption.highestAmount:
      result.sort((a, b) => b.principalAmount.compareTo(a.principalAmount));
      break;
    case OTDSortOption.maturityAsc:
      result.sort((a, b) => a.maturityDate.compareTo(b.maturityDate));
      break;
    case OTDSortOption.maturityDesc:
      result.sort((a, b) => b.maturityDate.compareTo(a.maturityDate));
      break;
    case OTDSortOption.nameAsc:
    case OTDSortOption.nameDesc:
      result.sort((a, b) {
        final nameA = customerMap[a.customerId]?.toLowerCase() ?? '';
        final nameB = customerMap[b.customerId]?.toLowerCase() ?? '';
        return criteria.sortBy == OTDSortOption.nameAsc
            ? nameA.compareTo(nameB)
            : nameB.compareTo(nameA);
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
