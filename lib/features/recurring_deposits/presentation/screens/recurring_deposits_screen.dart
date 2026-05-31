import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/app_search_bar.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/app_dialogs.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

import 'package:postfolio/core/widgets/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/app_filter_bottom_sheet.dart';
import 'package:postfolio/core/widgets/app_filter_section.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/models/base_deposit.dart';

class RecurringDepositsScreen extends HookConsumerWidget {
  const RecurringDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(filteredRecurringDepositsProvider);
    final criteria = ref.watch(recurringListCriteriaProvider);

    int statusModifications = 0;
    if (!criteria.statusFilters.contains(DepositStatus.active)) {
      statusModifications++;
    }
    if (criteria.statusFilters.contains(DepositStatus.closed)) {
      statusModifications++;
    }

    final activeFilterCount =
        statusModifications + criteria.urgencyFilters.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01,
            size: AppDimensions.iconMd,
          ),
          onPressed: () {},
        ),
        title: Text(t.recurringDeposits.title),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isAccessibleTheme =
                  ref.watch(themeModeProvider) == AppThemeMode.accessibleSystem;
              return IconButton(
                isSelected: isAccessibleTheme,
                icon: Icon(
                  Icons.contrast,
                  size: AppDimensions.iconMd,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(
                  Icons.contrast,
                  size: AppDimensions.iconMd,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isAccessibleTheme
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleAccessibleTheme();
                },
                tooltip: t.common.toggleAccessibleTheme,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AppSpacings.gapSm,
          AppSearchBar(
            hintText: t.recurringDeposits.searchHint,
            onChanged: (val) => ref
                .read(recurringListCriteriaProvider.notifier)
                .updateSearch(val),
            trailing: [
              IconButton(
                icon: Badge(
                  isLabelVisible: criteria.sortBy != RDSortOption.maturityAsc,
                  smallSize: AppDimensions.badgeSizeSm,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSorting01,
                    size: AppDimensions.iconMd,
                  ),
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
              IconButton(
                icon: Badge(
                  isLabelVisible: activeFilterCount > 0,
                  label: Text('$activeFilterCount'),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFilter,
                    size: AppDimensions.iconMd,
                  ),
                ),
                onPressed: () {
                  AppFilterBottomSheet.show(
                    context: context,
                    builder: (context) => Consumer(
                      builder: (context, ref, child) {
                        final criteria = ref.watch(
                          recurringListCriteriaProvider,
                        );
                        return AppFilterBottomSheet(
                          title: t.filters.title,
                          onClearAll: () => ref
                              .read(recurringListCriteriaProvider.notifier)
                              .clearFilters(),
                          filterSections: [
                            AppFilterSection<MaturityUrgency>(
                              title: t.filters.sections.urgency,
                              options: const [
                                MaturityUrgency.matured,
                                MaturityUrgency.maturingSoon,
                              ],
                              selectedOptions: criteria.urgencyFilters,
                              labelBuilder: (urgency) => urgency.displayName,
                              onSelected: (urgency) => ref
                                  .read(recurringListCriteriaProvider.notifier)
                                  .toggleUrgencyFilter(urgency),
                            ),
                            AppFilterSection<DepositStatus>(
                              title: t.filters.sections.status,
                              options: DepositStatus.values,
                              selectedOptions: criteria.statusFilters,
                              labelBuilder: (status) => status.displayName,
                              onSelected: (status) => ref
                                  .read(recurringListCriteriaProvider.notifier)
                                  .toggleFilter(status),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          AppSpacings.gapMd,
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
      final isDefaultStatus =
          criteria.statusFilters.length == 1 &&
          criteria.statusFilters.contains(DepositStatus.active);
      final hasFilters =
          criteria.searchQuery.isNotEmpty ||
          !isDefaultStatus ||
          criteria.urgencyFilters.isNotEmpty;
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
                  customerAsync.value?.name ??
                  (deposit.accountNo ?? t.common.notProvided);

              return RecurringDepositCard(
                title: customerName,
                subtitle: (deposit.serialNo?.isNotEmpty ?? false)
                    ? '(${deposit.serialNo}) ${deposit.accountNo ?? t.common.notProvided}'
                    : (deposit.accountNo ?? t.common.notProvided),
                installmentAmount: deposit.installmentAmount,
                status: deposit.status,
                urgency: deposit.maturityUrgency,
                relativeTimeText: deposit.maturityRelativeTime,
                maturityDate: deposit.maturityDate,
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
                onToggleStatus: () async {
                  final isActive = deposit.status == DepositStatus.active;
                  final confirmed = await AppDialogs.confirmAction(
                    context,
                    title: isActive ? t.common.close : t.common.reopen,
                    content: isActive
                        ? t.recurringDeposits.closeDepositConfirmation
                        : t.recurringDeposits.reopenDepositConfirmation,
                    confirmText: isActive ? t.common.close : t.common.reopen,
                  );
                  if (confirmed == true && context.mounted) {
                    final newStatus = isActive
                        ? DepositStatus.closed
                        : DepositStatus.active;
                    final result = await ref
                        .read(recurringDepositsControllerProvider.notifier)
                        .toggleDepositStatus(deposit.id, newStatus);

                    if (result is Failure && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text((result as Failure).error.toString()),
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
            title: dummy.accountNo ?? t.common.notProvided,
            subtitle: dummy.accountNo ?? t.common.notProvided,
            installmentAmount: dummy.installmentAmount,
            status: dummy.status,
            urgency: MaturityUrgency.normal,
            relativeTimeText: null,
            maturityDate: dummy.maturityDate,
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
            onToggleStatus: null,
          );
        },
      ),
    );
  }
}
