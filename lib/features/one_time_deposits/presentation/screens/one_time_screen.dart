import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/expressive/app_fab.dart';
import 'package:postfolio/core/widgets/layout/entity_list_body.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/i18n/strings.g.dart';

import 'package:postfolio/core/widgets/feedback/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_section.dart';
import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/sort_direction.dart';

class OneTimeDepositsScreen extends HookConsumerWidget {
  const OneTimeDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(filteredOneTimeDepositsProvider);
    final criteria = ref.watch(oneTimeListCriteriaProvider);
    final fab = useAppExtendedFabController(resetOn: criteria);

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
            query: criteria.searchQuery,
            hintText: t.oneTimeDeposits.searchHint,
            onChanged: (val) => ref
                .read(oneTimeListCriteriaProvider.notifier)
                .updateSearch(val),
            trailing: [
              IconButton(
                tooltip: t.sorting.title,
                icon: Badge(
                  isLabelVisible:
                      criteria.sortField != OTDSortField.maturityDate ||
                      criteria.sortDirection != SortDirection.asc,
                  smallSize: AppDimensions.badgeSizeSm,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSorting01,
                    size: AppDimensions.iconMd,
                  ),
                ),
                onPressed: () {
                  AppSortBottomSheet.show(
                    context: context,
                    builder: (context) => Consumer(
                      builder: (context, ref, _) {
                        final criteria = ref.watch(oneTimeListCriteriaProvider);
                        return AppSortBottomSheet<OTDSortField>(
                          title: t.sorting.title,
                          fields: OTDSortField.values,
                          selectedField: criteria.sortField,
                          selectedDirection: criteria.sortDirection,
                          fieldLabelBuilder: (f) => f.label,
                          directionLabelBuilder: (f, d) => f.directionLabel(d),
                          onSelected: (field, direction) {
                            ref
                                .read(oneTimeListCriteriaProvider.notifier)
                                .updateSortField(field);
                            ref
                                .read(oneTimeListCriteriaProvider.notifier)
                                .updateSortDirection(direction);
                          },
                          onReset: () => ref
                              .read(oneTimeListCriteriaProvider.notifier)
                              .clearSort(),
                        );
                      },
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: t.filters.title,
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
            child: AppExtendedFabScrollArea(
              controller: fab,
              child: EntityListBody<OneTimeDeposit>(
                state: depositsState,
                emptyMessage: t.oneTimeDeposits.noDepositsFound,
                hasActiveFilters:
                    criteria.searchQuery.isNotEmpty || activeFilterCount > 0,
                onClearFilters: () =>
                    ref.read(oneTimeListCriteriaProvider.notifier).clearAll(),
                onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
                onRefresh: () => ref.refresh(oneTimeDepositsControllerProvider.future),
                itemBuilder: (context, deposit, position) =>
                    OneTimeDepositCard(deposit: deposit, position: position),
                skeletonBuilder: (position) =>
                    OneTimeDepositCard.skeleton(position: position),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AppExtendedFab(
        controller: fab,
        label: t.oneTimeDeposits.newDeposit,
        icon: HugeIcons.strokeRoundedAdd01,
        onPressed: () => const OneTimeDepositCreateRoute().push(context),
      ),
    );
  }
}
