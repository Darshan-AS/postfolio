import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Pinned toolbar of the Monthly Hub: the search pill, which carries the group-by and
/// select toggles the way the other list screens carry sort and filter, and the due-window
/// choice on its own row so its three labels are never cut.
/// This is the only header widget that rebuilds on a keystroke.
class RDHubToolbar extends HookConsumerWidget {
  const RDHubToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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

    // Opaque: the rows scroll underneath the pinned toolbar.
    return ColoredBox(
      color: scheme.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pageMargin,
          AppDimensions.paddingXs,
          AppDimensions.pageMargin,
          AppDimensions.paddingSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchBar(
              controller: searchController,
              hintText: ops.searchHint,
              onChanged: filtersNotifier.setSearchQuery,
              leading: AppIcon(
                HugeIcons.strokeRoundedSearch01,
                color: scheme.onSurfaceVariant,
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
                    icon: AppIcon(
                      HugeIcons.strokeRoundedCancel01,
                      color: scheme.onSurfaceVariant,
                      size: AppDimensions.iconMd,
                    ),
                  ),
                _ToolbarToggle(
                  tooltip: toolbar.groupByCustomer,
                  isSelected: groupByCustomer,
                  icon: HugeIcons.strokeRoundedUserGroup,
                  onPressed: filtersNotifier.toggleGroupByCustomer,
                ),
                _ToolbarToggle(
                  tooltip: isSelectionMode ? toolbar.exitSelectMode : toolbar.selectMode,
                  isSelected: isSelectionMode,
                  icon: HugeIcons.strokeRoundedCheckList,
                  selectedIcon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  onPressed: isSelectionMode ? selectionNotifier.exit : selectionNotifier.enter,
                ),
              ],
            ),
            AppSpacings.gapSm,
            AppButtonGroup<RDDueWindowFilter>(
              selected: dueWindow,
              // The notifier toggles: re-selecting the active window would clear it. The group
              // reports a tap only when the window actually changes.
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
          ],
        ),
      ),
    );
  }
}

/// An on/off icon button inside the search pill. Off it is a plain icon, like its
/// neighbours; on it sits on a filled container in the colours of a selected segment of
/// the due-window group below, so the state does not depend on the icon's colour alone.
class _ToolbarToggle extends StatelessWidget {
  const _ToolbarToggle({
    required this.tooltip,
    required this.isSelected,
    required this.icon,
    this.selectedIcon,
    required this.onPressed,
  });

  final String tooltip;
  final bool isSelected;
  final AppIconData icon;

  /// Shown instead of [icon] while selected.
  final AppIconData? selectedIcon;
  final VoidCallback onPressed;

  static const Size _minimumSize = Size.square(AppDimensions.minTapTarget);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glyph = AppIcon(
      isSelected ? selectedIcon ?? icon : icon,
      size: AppDimensions.iconMd,
    );

    return isSelected
        ? IconButton.filledTonal(
            tooltip: tooltip,
            isSelected: true,
            // The search bar wraps its trailing widgets in an `IconTheme`, and `IconButton`
            // takes that theme's colour as its foreground ahead of the variant's own
            // default, which would draw this icon in `onSurfaceVariant` on the fill.
            style: IconButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
              minimumSize: _minimumSize,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onPressed,
            icon: glyph,
          )
        : IconButton(
            tooltip: tooltip,
            isSelected: false,
            style: IconButton.styleFrom(
              minimumSize: _minimumSize,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onPressed,
            icon: glyph,
          );
  }
}
