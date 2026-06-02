import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:postfolio/core/widgets/feedback/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_section.dart';
import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';

class OneTimeDepositsScreen extends HookConsumerWidget {
  const OneTimeDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(filteredOneTimeDepositsProvider);
    final criteria = ref.watch(oneTimeListCriteriaProvider);

    int statusModifications = 0;
    if (!criteria.statusFilters.contains(DepositStatus.active)) {
      statusModifications++;
    }
    if (criteria.statusFilters.contains(DepositStatus.closed)) {
      statusModifications++;
    }

    final activeFilterCount =
        statusModifications +
        criteria.urgencyFilters.length +
        criteria.schemeFilters.length;

    return Scaffold(
      appBar: ShellAppBar(title: t.oneTimeDeposits.title),
      body: Column(
        children: [
          AppSpacings.gapSm,
          AppSearchBar(
            hintText: t.oneTimeDeposits.searchHint,
            onChanged: (val) => ref
                .read(oneTimeListCriteriaProvider.notifier)
                .updateSearch(val),
            trailing: [
              IconButton(
                icon: Badge(
                  isLabelVisible: criteria.sortBy != OTDSortOption.maturityDateAsc,
                  smallSize: AppDimensions.badgeSizeSm,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSorting01,
                    size: AppDimensions.iconMd,
                  ),
                ),
                onPressed: () {
                  AppSortBottomSheet.show<OTDSortOption>(
                    context: context,
                    title: t.sorting.title,
                    options: OTDSortOption.values,
                    selectedOption: criteria.sortBy,
                    labelBuilder: (option) =>
                        t.sorting.options[option.name] ?? option.name,
                    onSelected: (option) => ref
                        .read(oneTimeListCriteriaProvider.notifier)
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
                        final criteria = ref.watch(oneTimeListCriteriaProvider);
                        return AppFilterBottomSheet(
                          title: t.filters.title,
                          onClearAll: () => ref
                              .read(oneTimeListCriteriaProvider.notifier)
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
                                  .read(oneTimeListCriteriaProvider.notifier)
                                  .toggleUrgencyFilter(urgency),
                            ),
                            AppFilterSection<DepositStatus>(
                              title: t.filters.sections.status,
                              options: DepositStatus.values,
                              selectedOptions: criteria.statusFilters,
                              labelBuilder: (status) => status.displayName,
                              onSelected: (status) => ref
                                  .read(oneTimeListCriteriaProvider.notifier)
                                  .toggleStatusFilter(status),
                            ),
                            AppFilterSection<OneTimeSchemeType>(
                              title: t.filters.sections.scheme,
                              options: OneTimeSchemeType.values,
                              selectedOptions: criteria.schemeFilters,
                              labelBuilder: (type) => type.shortName,
                              onSelected: (type) => ref
                                  .read(oneTimeListCriteriaProvider.notifier)
                                  .toggleSchemeFilter(type),
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
                    ref.invalidate(oneTimeDepositsControllerProvider),
              ),
              _ => _buildLoadingState(),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => const OneTimeDepositCreateRoute().push(context),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          size: AppDimensions.iconMd,
        ),
        label: Text(t.oneTimeDeposits.newDeposit),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    WidgetRef ref,
    List<OneTimeDeposit> deposits,
  ) {
    if (deposits.isEmpty) {
      final criteria = ref.read(oneTimeListCriteriaProvider);
      final isDefaultStatus =
          criteria.statusFilters.length == 1 &&
          criteria.statusFilters.contains(DepositStatus.active);
      final hasFilters =
          criteria.searchQuery.isNotEmpty ||
          !isDefaultStatus ||
          criteria.urgencyFilters.isNotEmpty ||
          criteria.schemeFilters.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasFilters
                  ? t.common.noResults
                  : t.oneTimeDeposits.noDepositsFound,
            ),
            if (hasFilters) ...[
              AppSpacings.gapMd,
              TextButton.icon(
                onPressed: () =>
                    ref.read(oneTimeListCriteriaProvider.notifier).clearAll(),
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
      onRefresh: () => ref.refresh(oneTimeDepositsControllerProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.listBottomPaddingFAB,
        ),
        itemCount: deposits.length,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final deposit = deposits[index];
          return OneTimeDepositCard(deposit: deposit);
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
          return OneTimeDepositCard.skeleton();
        },
      ),
    );
  }
}
