import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

    return Scaffold(
      appBar: ShellAppBar(title: t.nav.customers),
      // 2. Handle the AsyncValue UI states smoothly
      body: Column(
        children: [
          AppSpacings.gapSm,
          AppSearchBar(
            hintText: t.customers.searchHint,
            onChanged: (val) => ref
                .read(customerListCriteriaProvider.notifier)
                .updateSearch(val),
            trailing: [
              IconButton(
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
            child: switch (customersState) {
              AsyncData(:final value) => _buildDataState(context, ref, value),
              AsyncError(:final error) => ErrorStateView(
                message: error.toString(),
                onRetry: () => ref.invalidate(customersControllerProvider),
              ),
              _ => _buildLoadingState(),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => const CustomerCreateRoute().push(context),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          size: AppDimensions.iconMd,
        ),
        label: Text(t.customers.newCustomer),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    WidgetRef ref,
    List<Customer> customers,
  ) {
    if (customers.isEmpty) {
      final hasFilters = ref
          .read(customerListCriteriaProvider)
          .searchQuery
          .isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasFilters ? t.common.noResults : t.customers.noCustomersFound,
            ),
            if (hasFilters) ...[
              AppSpacings.gapMd,
              TextButton.icon(
                onPressed: () =>
                    ref.read(customerListCriteriaProvider.notifier).clearAll(),
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
      onRefresh: () async {
        ref.invalidate(customersControllerProvider);
        await ref.read(customersControllerProvider.future);
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.listBottomPaddingFAB,
        ),
        itemCount: customers.length,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return CustomerCard(customer: customer);
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
          return CustomerCard.skeleton();
        },
      ),
    );
  }
}
