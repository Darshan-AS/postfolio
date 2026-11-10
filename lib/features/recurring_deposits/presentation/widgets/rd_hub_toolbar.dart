import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Pinned toolbar of the Monthly Hub: search, due-window segments and the
/// group-by / select toggles. This is the only header widget that rebuilds on a keystroke.
class RDHubToolbar extends HookConsumerWidget {
  const RDHubToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final toolbar = ops.toolbar;

    final filtersNotifier = ref.read(rDHubFiltersProvider.notifier);
    final selectionNotifier = ref.read(rDHubSelectionProvider.notifier);
    final searchQuery = ref.watch(rDHubFiltersProvider.select((s) => s.searchQuery));
    final dueWindow = ref.watch(rDHubFiltersProvider.select((s) => s.dueWindow));
    final groupByCustomer = ref.watch(rDHubFiltersProvider.select((s) => s.groupByCustomer));
    final isSelectionMode = ref.watch(rDHubSelectionProvider.select((s) => s.isSelectionMode));
    final firstHalfCount = ref.watch(monthlyOperationsKpiProvider.select((k) => k.firstHalfCount));
    final secondHalfCount = ref.watch(monthlyOperationsKpiProvider.select((k) => k.secondHalfCount));

    final searchController = useTextEditingController(text: searchQuery);
    useListenable(searchController);

    // Keep the field in sync when the query is reset elsewhere (e.g. "Clear filters").
    useEffect(() {
      if (searchController.text != searchQuery) {
        searchController.text = searchQuery;
      }
      return null;
    }, [searchQuery]);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingXs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchBar(
              controller: searchController,
              hintText: ops.searchHint,
              onChanged: filtersNotifier.setSearchQuery,
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: theme.colorScheme.onSurfaceVariant,
                size: AppDimensions.iconMd,
              ),
              trailing: [
                if (searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: t.common.clear,
                    onPressed: () {
                      searchController.clear();
                      filtersNotifier.setSearchQuery('');
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: AppDimensions.iconMd,
                    ),
                  ),
              ],
            ),
            AppSpacings.gapXs,
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<RDDueWindowFilter>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: [
                      ButtonSegment(
                        value: RDDueWindowFilter.all,
                        label: Text(toolbar.windowAll),
                      ),
                      ButtonSegment(
                        value: RDDueWindowFilter.firstHalf,
                        label: Text(toolbar.window15th(count: firstHalfCount)),
                      ),
                      ButtonSegment(
                        value: RDDueWindowFilter.secondHalf,
                        label: Text(toolbar.windowEom(count: secondHalfCount)),
                      ),
                    ],
                    selected: {dueWindow},
                    onSelectionChanged: (set) {
                      final next = set.first;
                      // Notifier toggles: re-selecting the active window clears it,
                      // so only forward when the window actually changes.
                      if (next != dueWindow) filtersNotifier.toggleDueWindow(next);
                    },
                  ),
                ),
                AppSpacings.gapXs,
                IconButton(
                  tooltip: toolbar.groupByCustomer,
                  isSelected: groupByCustomer,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => filtersNotifier.toggleGroupByCustomer(),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUserGroup,
                    size: AppDimensions.iconSm,
                  ),
                  selectedIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedUserGroup,
                    size: AppDimensions.iconSm,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  tooltip: isSelectionMode ? toolbar.exitSelectMode : toolbar.selectMode,
                  isSelected: isSelectionMode,
                  visualDensity: VisualDensity.compact,
                  onPressed: isSelectionMode ? selectionNotifier.exit : selectionNotifier.enter,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckList,
                    size: AppDimensions.iconSm,
                  ),
                  selectedIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: AppDimensions.iconSm,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
