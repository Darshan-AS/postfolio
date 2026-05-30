import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/app_search_bar.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/app_dialogs.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

import 'package:postfolio/core/widgets/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/app_filter_chip_bar.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

class RecurringDepositsScreen extends HookConsumerWidget {
  const RecurringDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(filteredRecurringDepositsProvider);
    final criteria = ref.watch(recurringListCriteriaProvider);
    final searchVisible = useState(false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01,
            size: AppDimensions.iconMd,
          ),
          onPressed: () {},
        ),
        title: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTransaction,
              size: AppDimensions.iconMd,
              color: Theme.of(context).colorScheme.secondary,
            ),
            AppSpacings.gapSm,
            Text(
              t.recurringDeposits.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: AppDimensions.iconMd,
            ),
            onPressed: () {
              searchVisible.value = !searchVisible.value;
              if (!searchVisible.value) {
                ref
                    .read(recurringListCriteriaProvider.notifier)
                    .updateSearch('');
              }
            },
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSorting01,
              size: AppDimensions.iconMd,
            ),
            onPressed: () {
              AppSortBottomSheet.show<RDSortOption>(
                context: context,
                title: t.sorting.title,
                options: RDSortOption.values,
                selectedOption: criteria.sortBy,
                labelBuilder: (option) =>
                    t.sorting.options[option.name] ?? option.name,
                onSelected: (option) => ref
                    .read(recurringListCriteriaProvider.notifier)
                    .updateSort(option),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (searchVisible.value) ...[
            AppSpacings.gapSm,
            AppSearchBar(
              hintText: t.recurringDeposits.searchHint,
              onChanged: (val) => ref
                  .read(recurringListCriteriaProvider.notifier)
                  .updateSearch(val),
              onClose: () {
                searchVisible.value = false;
                ref
                    .read(recurringListCriteriaProvider.notifier)
                    .updateSearch('');
              },
            ),
            AppSpacings.gapMd,
          ],
          AppFilterChipBar<DepositStatus>(
            options: DepositStatus.values,
            selectedOptions: criteria.activeFilters,
            labelBuilder: (status) => status.displayName,
            onSelected: (status) => ref
                .read(recurringListCriteriaProvider.notifier)
                .toggleFilter(status),
          ),
          AppSpacings.gapSm,
          Expanded(
            child: switch (depositsState) {
              AsyncData(:final value) => _buildDataState(context, ref, value),
              AsyncError(:final error) => ErrorStateView(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(recurringDepositsControllerProvider),
              ),
              _ => _buildLoadingState(),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => const RecurringDepositCreateRoute().push(context),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          size: AppDimensions.iconMd,
        ),
        label: Text(t.recurringDeposits.newDeposit),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    WidgetRef ref,
    List<RecurringDeposit> deposits,
  ) {
    if (deposits.isEmpty) {
      final criteria = ref.read(recurringListCriteriaProvider);
      final hasFilters =
          criteria.searchQuery.isNotEmpty || criteria.activeFilters.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasFilters
                  ? t.common.noResults
                  : t.recurringDeposits.noDepositsFound,
            ),
            if (hasFilters) ...[
              AppSpacings.gapMd,
              TextButton.icon(
                onPressed: () =>
                    ref.read(recurringListCriteriaProvider.notifier).clearAll(),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFilterRemove,
                  size: AppDimensions.iconSm,
                ),
                label: Text(t.common.clearFilters),
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(recurringDepositsControllerProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.listBottomPaddingFAB,
        ),
        itemCount: deposits.length,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final deposit = deposits[index];
          return Consumer(
            builder: (context, ref, child) {
              final customerAsync = ref.watch(
                customerByIdProvider(deposit.customerId),
              );
              final customerName =
                  customerAsync.value?.name ?? deposit.accountNo;

              return RecurringDepositCard(
                title: customerName,
                subtitle: (deposit.serialNo?.isNotEmpty ?? false)
                    ? '(${deposit.serialNo}) ${deposit.accountNo}'
                    : deposit.accountNo,
                installmentAmount: deposit.installmentAmount,
                status: deposit.status,
                onTap: () =>
                    RecurringDepositDetailRoute(deposit.id).push(context),
                onEdit: () =>
                    RecurringDepositEditRoute(deposit.id).push(context),
                onDelete: () async {
                  final confirmed = await AppDialogs.confirmDelete(
                    context,
                    title: t.recurringDeposits.deleteDeposit,
                    content: t.recurringDeposits.deleteDepositConfirmation,
                  );
                  if (confirmed == true) {
                    final result = await ref
                        .read(recurringDepositsControllerProvider.notifier)
                        .deleteRecurringDeposit(deposit.id);

                    if (result is Failure && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t.recurringDeposits.failedToDeleteDeposit(
                              error: (result as Failure).error.toString(),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.listBottomPaddingFAB,
        ),
        itemCount: 5,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final dummy = RecurringDeposit.dummy;
          return RecurringDepositCard(
            title: dummy.accountNo,
            subtitle: dummy.accountNo,
            installmentAmount: dummy.installmentAmount,
            status: dummy.status,
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
          );
        },
      ),
    );
  }
}
