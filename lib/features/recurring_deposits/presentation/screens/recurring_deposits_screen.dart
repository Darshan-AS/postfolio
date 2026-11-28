import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_fab.dart';
import 'package:postfolio/core/widgets/layout/entity_list_body.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/i18n/strings.g.dart';

import 'package:postfolio/core/widgets/feedback/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_section.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operations_view.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

class RecurringDepositsScreen extends HookConsumerWidget {
  const RecurringDepositsScreen({
    super.key,
    this.initialView,
    this.initialMonth,
  });

  final String? initialView;
  final String? initialMonth;

  static final RegExp _yearMonthPattern = RegExp(r'^(\d{4})-(\d{2})$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      if (initialView != null || initialMonth != null) {
        Future.microtask(() {
          if (initialView == RDViewMode.monthlyHub.queryValue) {
            ref
                .read(rDViewModeControllerProvider.notifier)
                .setMode(RDViewMode.monthlyHub);
          } else if (initialView == RDViewMode.accounts.queryValue) {
            ref
                .read(rDViewModeControllerProvider.notifier)
                .setMode(RDViewMode.accounts);
          }
          if (initialMonth != null) {
            final match = _yearMonthPattern.firstMatch(initialMonth!.trim());
            if (match != null) {
              final year = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              if (month >= 1 && month <= 12) {
                ref
                    .read(rDHubMonthProvider.notifier)
                    .setMonth(DateTime(year, month));
              }
            }
          }
        });
      }
      return null;
    }, [initialView, initialMonth]);

    final viewMode = ref.watch(rDViewModeControllerProvider);
    final depositsState = ref.watch(filteredRecurringDepositsProvider);
    final criteria = ref.watch(recurringListCriteriaProvider);
    final fab = useAppExtendedFabController(resetOn: criteria);

    int statusModifications = 0;
    if (!criteria.statusFilters.contains(DepositStatus.active)) {
      statusModifications++;
    }
    if (criteria.statusFilters.contains(DepositStatus.closed)) {
      statusModifications++;
    }

    final activeFilterCount =
        statusModifications + criteria.urgencyFilters.length;

    // The "New Deposit" FAB belongs to the Accounts view only; the Hub has its own
    // batch bar (see RDHubBatchBar) and must never be covered by a FAB.
    final showFab = viewMode == RDViewMode.accounts;

    return Scaffold(
      appBar: ShellAppBar(
        title: t.recurringDeposits.title,
        // The Accounts ⇄ Hub switch is the way into the app's main workflow, so it says
        // what it switches to. It sits where the title was, which the navigation bar
        // repeats, so it takes no height from the list.
        titleControl: AppButtonGroup<RDViewMode>(
          expand: false,
          selected: viewMode,
          onChanged: (mode) =>
              ref.read(rDViewModeControllerProvider.notifier).setMode(mode),
          segments: [
            AppSegment(
              value: RDViewMode.accounts,
              label: t.recurringDeposits.views.accounts,
            ),
            AppSegment(
              value: RDViewMode.monthlyHub,
              label: t.recurringDeposits.views.monthlyHub,
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: viewMode == RDViewMode.accounts
              ? _buildAccountsView(
                  context,
                  ref,
                  depositsState,
                  criteria,
                  activeFilterCount,
                  fab,
                )
              : const RDMonthlyOperationsView(),
        ),
      ),
      floatingActionButton: showFab
          ? AppExtendedFab(
              controller: fab,
              label: t.recurringDeposits.newDeposit,
              icon: HugeIcons.strokeRoundedAdd01,
              onPressed: () =>
                  const RecurringDepositCreateRoute().push(context),
            )
          : null,
    );
  }

  Widget _buildAccountsView(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RecurringDeposit>> depositsState,
    RDSearchCriteria criteria,
    int activeFilterCount,
    AppExtendedFabController fab,
  ) {
    return Column(
      children: [
        AppSpacings.gapSm,
        AppSearchBar(
          query: criteria.searchQuery,
          hintText: t.recurringDeposits.searchHint,
          onChanged: (val) => ref
              .read(recurringListCriteriaProvider.notifier)
              .updateSearch(val),
          trailing: [
            IconButton(
              tooltip: t.sorting.title,
              icon: Badge(
                isLabelVisible:
                    criteria.sortField != RDSortField.serialNo ||
                    criteria.sortDirection != SortDirection.asc,
                smallSize: AppDimensions.badgeSizeSm,
                child: const AppIcon(
                  HugeIcons.strokeRoundedSorting01,
                  size: AppDimensions.iconMd,
                ),
              ),
              onPressed: () {
                AppSortBottomSheet.show(
                  context: context,
                  builder: (context) => Consumer(
                    builder: (context, ref, _) {
                      final criteria = ref.watch(recurringListCriteriaProvider);
                      return AppSortBottomSheet<RDSortField>(
                        title: t.sorting.title,
                        fields: RDSortField.values,
                        selectedField: criteria.sortField,
                        selectedDirection: criteria.sortDirection,
                        fieldLabelBuilder: (f) => f.label,
                        directionLabelBuilder: (f, d) => f.directionLabel(d),
                        onSelected: (field, direction) {
                          ref
                              .read(recurringListCriteriaProvider.notifier)
                              .updateSortField(field);
                          ref
                              .read(recurringListCriteriaProvider.notifier)
                              .updateSortDirection(direction);
                        },
                        onReset: () => ref
                            .read(recurringListCriteriaProvider.notifier)
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
                child: const AppIcon(
                  HugeIcons.strokeRoundedFilter,
                  size: AppDimensions.iconMd,
                ),
              ),
              onPressed: () {
                AppFilterBottomSheet.show(
                  context: context,
                  builder: (context) => Consumer(
                    builder: (context, ref, child) {
                      final criteria = ref.watch(recurringListCriteriaProvider);
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
          child: AppExtendedFabScrollArea(
            controller: fab,
            child: EntityListBody<RecurringDeposit>(
              state: depositsState,
              emptyMessage: t.recurringDeposits.noDepositsFound,
              hasActiveFilters:
                  criteria.searchQuery.isNotEmpty || activeFilterCount > 0,
              onClearFilters: () =>
                  ref.read(recurringListCriteriaProvider.notifier).clearAll(),
              onRetry: () =>
                  ref.invalidate(recurringDepositsControllerProvider),
              onRefresh: () =>
                  ref.refresh(recurringDepositsControllerProvider.future),
              itemBuilder: (context, deposit, position) =>
                  RecurringDepositCard(deposit: deposit, position: position),
              skeletonBuilder: (position) =>
                  RecurringDepositCard.skeleton(position: position),
            ),
          ),
        ),
      ],
    );
  }
}
