import 'dart:collection';

import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

import 'package:uuid/uuid.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';

part 'recurring_deposits_controller.g.dart';

@riverpod
class RecurringListCriteria extends _$RecurringListCriteria {
  @override
  RDSearchCriteria build() => const RDSearchCriteria();

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);
  void updateSortField(RDSortField field) => state = state.copyWith(sortField: field);
  void updateSortDirection(SortDirection direction) => state = state.copyWith(sortDirection: direction);
  void toggleFilter(DepositStatus status) {
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

  void clearAll() => state = const RDSearchCriteria();

  void clearFilters() {
    state = state.copyWith(
      statusFilters: const [DepositStatus.active],
      urgencyFilters: const [],
    );
  }
}

@riverpod
Future<UnmodifiableListView<RecurringDeposit>> filteredRecurringDeposits(
  Ref ref,
) async {
  final criteria = ref.watch(recurringListCriteriaProvider);
  final asyncDeposits = await ref.watch(
    recurringDepositsControllerProvider.future,
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
          d.schemeType.displayName.toLowerCase().contains(query) ||
          (d.serialNo?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Sort
  final isAsc = criteria.sortDirection.isAscending;
  switch (criteria.sortField) {
    case RDSortField.serialNo:
      result.sort((a, b) {
        final sA = a.serialNo ?? '';
        final sB = b.serialNo ?? '';
        final numA = int.tryParse(sA);
        final numB = int.tryParse(sB);
        int comparison;
        if (numA != null && numB != null) {
          comparison = numA.compareTo(numB);
        } else {
          comparison = sA.compareTo(sB);
        }
        return isAsc ? comparison : -comparison;
      });
      break;
    case RDSortField.startDate:
      result.sort((a, b) {
        final comp = a.startDate.compareTo(b.startDate);
        return isAsc ? comp : -comp;
      });
      break;
    case RDSortField.amount:
      result.sort((a, b) {
        final comp = a.installmentAmount.compareTo(b.installmentAmount);
        return isAsc ? comp : -comp;
      });
      break;
    case RDSortField.maturityDate:
      result.sort((a, b) {
        final comp = a.maturityDate.compareTo(b.maturityDate);
        return isAsc ? comp : -comp;
      });
      break;
    case RDSortField.name:
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
class RecurringDepositsController extends _$RecurringDepositsController {
  @override
  Stream<UnmodifiableListView<RecurringDeposit>> build() {
    return _watchRecurringDeposits();
  }

  Stream<UnmodifiableListView<RecurringDeposit>> _watchRecurringDeposits() {
    final repository = ref.watch(recurringDepositRepositoryProvider);
    return repository.watchRecurringDeposits().map((result) {
      return switch (result) {
        Success(value: final deposits) => UnmodifiableListView(deposits),
        Failure(error: final error) => throw Exception(error),
      };
    });
  }

  Future<Result<void, String>> saveRecurringDeposit({
    String? id,
    String? serialNo,
    String? accountNo,
    required String installmentAmount,
    required int termYears,
    required int termMonths,
    required String interestRate,
    required String customerId,
    required RecurringSchemeType schemeType,
    DepositStatus status = DepositStatus.active,
    required DateTime startDate,
    List<Nominee> nominees = const [],
  }) async {
    final depositId = id ?? const Uuid().v4();

    final amount = double.tryParse(installmentAmount.trim()) ?? 0.0;
    final rate = double.tryParse(interestRate.trim()) ?? 0.0;

    final createResult = RecurringDeposit.create(
      id: depositId,
      serialNo: serialNo,
      accountNo: accountNo,
      installmentAmount: amount,
      termYears: termYears,
      termMonths: termMonths,
      interestRate: rate,
      customerId: customerId,
      schemeType: schemeType,
      status: status,
      startDate: startDate,
      nominees: nominees,
    );

    final RecurringDeposit deposit;
    switch (createResult) {
      case Failure(error: final err):
        return Failure(err);
      case Success(value: final d):
        deposit = d;
    }

    final repository = ref.read(recurringDepositRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateRecurringDeposit(deposit)
        : await repository.createRecurringDeposit(deposit);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    final repository = ref.read(recurringDepositRepositoryProvider);
    final result = await repository.deleteRecurringDeposit(id);

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
    final repository = ref.read(recurringDepositRepositoryProvider);
    return await repository.updateRecurringDeposit(updatedDeposit);
  }
}
