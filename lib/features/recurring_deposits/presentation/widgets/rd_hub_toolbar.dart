import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/feedback/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Pinned toolbar of the Monthly Hub: shared search pill carrying the sort toggle, plus the
/// due-window choice on its own row so its three labels are never cut.
/// This is the only header widget that rebuilds on a keystroke.
class RDHubToolbar extends ConsumerWidget {
  const RDHubToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ops = t.recurringDeposits.monthlyOperations;
    final toolbar = ops.toolbar;

    final filtersNotifier = ref.read(rDHubFiltersProvider.notifier);
    final searchQuery = ref.watch(
      rDHubFiltersProvider.select((s) => s.searchQuery),
    );
    final dueWindow = ref.watch(
      rDHubFiltersProvider.select((s) => s.dueWindow),
    );
    final sortField = ref.watch(
      rDHubFiltersProvider.select((s) => s.sortField),
    );
    final sortDirection = ref.watch(
      rDHubFiltersProvider.select((s) => s.sortDirection),
    );
    final isCustomSort =
        sortField != RDHubSortField.serialNo ||
        sortDirection != SortDirection.asc;

    final firstHalfCount = ref.watch(
      monthlyOperationsKpiProvider.select((k) => k.firstHalfCount),
    );
    final secondHalfCount = ref.watch(
      monthlyOperationsKpiProvider.select((k) => k.secondHalfCount),
    );

    void openSortSheet() {
      AppSortBottomSheet.show<RDHubSortField>(
        context: context,
        builder: (context) => Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(rDHubFiltersProvider);
            final notifier = ref.read(rDHubFiltersProvider.notifier);
            return AppSortBottomSheet<RDHubSortField>(
              title: t.sorting.title,
              fields: RDHubSortField.values,
              selectedField: filters.sortField,
              selectedDirection: filters.sortDirection,
              fieldLabelBuilder: (field) => switch (field) {
                RDHubSortField.serialNo => toolbar.sortBySerial,
                RDHubSortField.overdueFirst => toolbar.sortByOverdue,
                RDHubSortField.customerName => toolbar.sortByName,
              },
              directionLabelBuilder: (field, direction) => switch (field) {
                RDHubSortField.serialNo =>
                  direction == SortDirection.asc
                      ? toolbar.sortAscSerial
                      : toolbar.sortDescSerial,
                RDHubSortField.overdueFirst =>
                  direction == SortDirection.asc
                      ? toolbar.sortUrgentFirst
                      : toolbar.sortUrgentLast,
                RDHubSortField.customerName =>
                  direction == SortDirection.asc
                      ? toolbar.sortAscName
                      : toolbar.sortDescName,
              },
              onSelected: notifier.setSort,
              onReset: notifier.resetSort,
            );
          },
        ),
      );
    }

    // Opaque: the rows scroll underneath the pinned toolbar.
    // AppSearchBar already applies `AppDimensions.pageMargin` horizontal padding.
    return ColoredBox(
      color: scheme.page,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppDimensions.paddingXs,
          bottom: AppDimensions.paddingSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchBar(
              query: searchQuery,
              hintText: ops.searchHint,
              onChanged: filtersNotifier.setSearchQuery,
              trailing: [
                IconButton(
                  tooltip: toolbar.sort,
                  icon: Badge(
                    isLabelVisible: isCustomSort,
                    smallSize: AppDimensions.badgeSizeSm,
                    child: const AppIcon(
                      HugeIcons.strokeRoundedSorting01,
                      size: AppDimensions.iconMd,
                    ),
                  ),
                  onPressed: openSortSheet,
                ),
              ],
            ),
            AppSpacings.gapSm,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageMargin,
              ),
              child: AppButtonGroup<RDDueWindowFilter>(
                selected: dueWindow,
                onChanged: filtersNotifier.toggleDueWindow,
                segments: [
                  AppSegment(
                    value: RDDueWindowFilter.all,
                    label: toolbar.windowAll,
                  ),
                  AppSegment(
                    value: RDDueWindowFilter.firstHalf,
                    label: toolbar.window15th(count: firstHalfCount),
                  ),
                  AppSegment(
                    value: RDDueWindowFilter.secondHalf,
                    label: toolbar.windowEom(count: secondHalfCount),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
