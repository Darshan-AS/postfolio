import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/expressive/app_fab.dart';
import 'package:postfolio/core/widgets/layout/entity_list_body.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/i18n/strings.g.dart';

import 'package:postfolio/features/customers/domain/customer_search_criteria.dart';
import 'package:postfolio/core/widgets/feedback/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/enums/sort_direction.dart';

class CustomersScreen extends HookConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the derived filtered provider state
    final customersState = ref.watch(filteredCustomersProvider);
    final criteria = ref.watch(customerListCriteriaProvider);
    final fab = useAppExtendedFabController(resetOn: criteria);

    return Scaffold(
      appBar: ShellAppBar(title: t.nav.customers),
      // 2. Handle the AsyncValue UI states smoothly
      body: Column(
        children: [
          AppSpacings.gapSm,
          AppSearchBar(
            query: criteria.searchQuery,
            hintText: t.customers.searchHint,
            onChanged: (val) => ref
                .read(customerListCriteriaProvider.notifier)
                .updateSearch(val),
            trailing: [
              IconButton(
                tooltip: t.sorting.title,
                icon: Badge(
                  isLabelVisible:
                      criteria.sortField != CustomerSortField.name ||
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
                        final criteria = ref.watch(
                          customerListCriteriaProvider,
                        );
                        return AppSortBottomSheet<CustomerSortField>(
                          title: t.sorting.title,
                          fields: CustomerSortField.values,
                          selectedField: criteria.sortField,
                          selectedDirection: criteria.sortDirection,
                          fieldLabelBuilder: (f) => f.label,
                          directionLabelBuilder: (f, d) => f.directionLabel(d),
                          onSelected: (field, direction) {
                            ref
                                .read(customerListCriteriaProvider.notifier)
                                .updateSortField(field);
                            ref
                                .read(customerListCriteriaProvider.notifier)
                                .updateSortDirection(direction);
                          },
                          onReset: () => ref
                              .read(customerListCriteriaProvider.notifier)
                              .clearSort(),
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
              child: EntityListBody<Customer>(
                state: customersState,
                emptyMessage: t.customers.noCustomersFound,
                hasActiveFilters: criteria.searchQuery.isNotEmpty,
                onClearFilters: () =>
                    ref.read(customerListCriteriaProvider.notifier).clearAll(),
                onRetry: () => ref.invalidate(customersControllerProvider),
                onRefresh: () async {
                  ref.invalidate(customersControllerProvider);
                  await ref.read(customersControllerProvider.future);
                },
                itemBuilder: (context, customer, position) =>
                    CustomerCard(customer: customer, position: position),
                skeletonBuilder: (position) =>
                    CustomerCard.skeleton(position: position),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AppExtendedFab(
        controller: fab,
        label: t.customers.newCustomer,
        icon: HugeIcons.strokeRoundedAdd01,
        onPressed: () => const CustomerCreateRoute().push(context),
      ),
    );
  }
}
