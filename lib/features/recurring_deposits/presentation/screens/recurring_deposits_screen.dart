import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:postfolio/core/widgets/feedback/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_section.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';

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
      appBar: ShellAppBar(title: t.recurringDeposits.title),
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
                  isLabelVisible: criteria.sortBy != RDSortOption.serialNoDesc,
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
              AsyncData(:final value) => _buildDataState(
                  context, ref, value),
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
          return RecurringDepositCard(deposit: deposit);
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
          return RecurringDepositCard.skeleton();
        },
      ),
    );
  }
}
