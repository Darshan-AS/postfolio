import 'dart:collection';

import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

import 'package:uuid/uuid.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';

part 'recurring_deposits_controller.g.dart';

@riverpod
class RecurringListCriteria extends _$RecurringListCriteria {
  @override
  RDSearchCriteria build() {
    final storage = ref.watch(storageServiceProvider);
    const defaults = RDSearchCriteria();
    return defaults.copyWith(
      sortField: storage.getRDSortField() ?? defaults.sortField,
      sortDirection: storage.getRDSortDirection() ?? defaults.sortDirection,
      statusFilters: storage.getRDStatusFilters() ?? defaults.statusFilters,
      urgencyFilters: storage.getRDUrgencyFilters() ?? defaults.urgencyFilters,
    );
  }

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);

  void updateSortField(RDSortField field) {
    state = state.copyWith(sortField: field);
    ref.read(storageServiceProvider).setRDSortField(field);
  }

  void updateSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
    ref.read(storageServiceProvider).setRDSortDirection(direction);
  }

  void toggleFilter(DepositStatus status) {
    final newFilters = state.statusFilters.contains(status)
        ? state.statusFilters.where((s) => s != status).toList()
        : [...state.statusFilters, status];

    state = state.copyWith(statusFilters: newFilters);
    ref.read(storageServiceProvider).setRDStatusFilters(newFilters);
  }

  void toggleUrgencyFilter(MaturityUrgency urgency) {
    final newFilters = state.urgencyFilters.contains(urgency)
        ? state.urgencyFilters.where((u) => u != urgency).toList()
        : [...state.urgencyFilters, urgency];

    state = state.copyWith(urgencyFilters: newFilters);
    ref.read(storageServiceProvider).setRDUrgencyFilters(newFilters);
  }

  void clearSort() {
    state = state.copyWith(
      sortField: RDSortField.serialNo,
      sortDirection: SortDirection.asc,
    );
    ref.read(storageServiceProvider).setRDSortField(RDSortField.serialNo);
    ref.read(storageServiceProvider).setRDSortDirection(SortDirection.asc);
  }

  void clearAll() {
    const defaults = RDSearchCriteria();
    state = defaults;
    final storage = ref.read(storageServiceProvider);
    storage.setRDSortField(defaults.sortField);
    storage.setRDSortDirection(defaults.sortDirection);
    storage.setRDStatusFilters(defaults.statusFilters);
    storage.setRDUrgencyFilters(defaults.urgencyFilters);
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilters: const [DepositStatus.active],
      urgencyFilters: const [],
    );
    ref.read(storageServiceProvider).setRDStatusFilters([DepositStatus.active]);
    ref.read(storageServiceProvider).setRDUrgencyFilters([]);
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

  final liveCustomers = ref.watch(customersControllerProvider).value;
  final Map<String, String> customerMap;
  if (liveCustomers != null) {
    customerMap = {for (final c in liveCustomers) c.id: c.name};
  } else if (asyncDeposits.any((d) => d.customerName == null)) {
    final asyncCustomers = await ref.watch(customersControllerProvider.future);
    customerMap = {for (final c in asyncCustomers) c.id: c.name};
  } else {
    customerMap = const {};
  }

  var result = customerMap.isNotEmpty
      ? asyncDeposits
          .map((d) {
            final liveName = customerMap[d.customerId];
            return (liveName != null && liveName != d.customerName)
                ? d.copyWith(customerName: liveName)
                : d;
          })
          .toList()
      : asyncDeposits.toList();

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
      final customerName = (d.customerName ?? customerMap[d.customerId])?.toLowerCase() ?? '';
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
        final comparison = RecurringDeposit.defaultCompare(a, b);
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
        final nameA = (a.customerName ?? customerMap[a.customerId])?.toLowerCase() ?? '';
        final nameB = (b.customerName ?? customerMap[b.customerId])?.toLowerCase() ?? '';
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
    ref.watch(activeSessionKeyProvider);
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
    required String customerId,
    required RecurringSchemeType schemeType,
    required DateTime startDate,
    int? termYears,
    int? termMonths,
    String? interestRate,
    DepositStatus status = DepositStatus.active,
    List<Nominee> nominees = const [],
    String initialPaidInstallments = '0',
    String openingReceivable = '0',
  }) async {
    final link = ref.keepAlive();
    try {
      final depositId = id ?? const Uuid().v7();
      final postalRateService = ref.read(postalRateServiceProvider);

      final amount = double.tryParse(installmentAmount.trim()) ?? 0.0;
      final rate = interestRate != null
          ? double.tryParse(interestRate.trim())
          : null;
      final initialPaid = int.tryParse(initialPaidInstallments.trim()) ?? 0;
      final openingReceivableAmount =
          double.tryParse(openingReceivable.trim()) ?? 0.0;

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
        postalRateService: postalRateService,
        initialPaidInstallments: initialPaid,
        openingReceivable: openingReceivableAmount,
      );

      final RecurringDeposit deposit;
      switch (createResult) {
        case Failure(error: final err):
          return Failure(err);
        case Success(value: final d):
          deposit = d;
      }

      final repository = ref.read(recurringDepositRepositoryProvider);

      RecurringDeposit? existing;
      var termsChangedOnExisting = false;
      if (id != null) {
        existing = state.value?.where((d) => d.id == id).firstOrNull;
        if (existing == null) {
          final existingResult =
              await repository.watchRecurringDepositById(id).first;
          if (existingResult case Success(value: final found)) {
            existing = found;
          }
        }
        if (existing != null) {
          final sub = ref.listen(rdIsFinancialTermsLockedProvider(id), (_, _) {});
          bool isLocked = false;
          try {
            isLocked = await ref.read(rdIsFinancialTermsLockedProvider(id).future);
          } catch (_) {
            isLocked = false;
          } finally {
            sub.close();
          }

          final lockCheck = RecurringDeposit.validateUpdate(
            existing: existing,
            updated: deposit,
            hasPayments: isLocked,
          );
          if (lockCheck case Failure(error: final err)) {
            return Failure(err);
          }
          termsChangedOnExisting = RecurringDeposit.validateUpdate(
            existing: existing,
            updated: deposit,
            hasPayments: true,
          ) is Failure;
        }
      }

      final saveResult = await repository.saveRecurringDeposit(deposit);
      if (saveResult case Success() when termsChangedOnExisting) {
        await ref
            .read(rDLedgerControllerProvider.notifier)
            .rebuildSummary(deposit.id);
      }
      return saveResult;
    } finally {
      link.close();
    }
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
    DepositStatus newStatus, {
    RecurringDeposit? deposit,
  }) {
    return ref
        .read(recurringDepositRepositoryProvider)
        .updateDepositStatus(id, newStatus);
  }
}

@riverpod
Stream<RecurringDeposit> recurringDepositById(Ref ref, String id) {
  final repository = ref.watch(recurringDepositRepositoryProvider);
  return repository.watchRecurringDepositById(id).map((result) {
    return switch (result) {
      Success(value: final deposit) => deposit,
      Failure(error: final error) => throw Exception(error),
    };
  });
}
