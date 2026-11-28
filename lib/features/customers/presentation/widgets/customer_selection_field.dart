import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_sheet_header.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

class CustomerSelectionField extends HookConsumerWidget {
  final Customer? initialCustomer;
  final String? initialCustomerId;
  final void Function(Customer?) onCustomerSelected;
  final String? errorText;

  const CustomerSelectionField({
    super.key,
    this.initialCustomer,
    this.initialCustomerId,
    required this.onCustomerSelected,
    this.errorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCustomer = useState<Customer?>(initialCustomer);

    void showSelectionSheet() {
      AppAdaptiveSheet.show<Customer>(
        context,
        builder: (_) => const _CustomerSelectionSheet(),
      ).then((selected) {
        if (selected != null) {
          selectedCustomer.value = selected;
          onCustomerSelected(selected);
        }
      });
    }

    Customer? displayCustomer = selectedCustomer.value;

    if (displayCustomer == null && initialCustomerId != null) {
      final customerState = ref.watch(customerByIdProvider(initialCustomerId!));
      displayCustomer = customerState.value;
    }

    final secondaryIdentifier = displayCustomer == null
        ? null
        : (displayCustomer.cifNumber != null &&
                  displayCustomer.cifNumber!.trim().isNotEmpty
              ? displayCustomer.cifNumber!
              : displayCustomer.phone?.toPhoneFormat());

    return AppLabeledField(
      labelText: t.oneTimeDeposits.fields.customerId,
      isRequired: true,
      builder: (context, label) => InkWell(
        // The themed input corners, so the ripple stays inside the field.
        borderRadius: BorderRadius.circular(AppShapes.large),
        onTap: showSelectionSheet,
        child: InputDecorator(
          decoration: AppInputDecoration.m3(
            context,
            labelText: label,
            prefixIcon: const AppIcon(
              HugeIcons.strokeRoundedUser,
              size: AppDimensions.iconMd,
            ),
            errorText: errorText,
            isRequired: true,
          ),
          child: Builder(
            builder: (context) {
              final isLargeText = AppDimensions.isLargeText(context);
              final nameText = Text(
                displayCustomer?.name ?? t.customers.selectCustomer,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: displayCustomer == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              );
              final secondaryText =
                  secondaryIdentifier != null && secondaryIdentifier.isNotEmpty
                  ? Text(
                      secondaryIdentifier,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Wraps: a name cut with an ellipsis is not the name.
                    child: isLargeText
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              nameText,
                              if (secondaryText != null) ...[
                                AppSpacings.gapXxs,
                                secondaryText,
                              ],
                            ],
                          )
                        : nameText,
                  ),
                  if (!isLargeText && secondaryText != null) ...[
                    AppSpacings.gapSm,
                    secondaryText,
                  ],
                  AppSpacings.gapXs,
                  const AppIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    size: AppDimensions.iconMd,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CustomerSelectionSheet extends HookConsumerWidget {
  const _CustomerSelectionSheet();

  static const int _skeletonRowCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final state = ref.watch(customersControllerProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    void clearSearch() => searchQuery.value = '';

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pageMargin,
                AppDimensions.paddingSm,
                AppDimensions.pageMargin,
                0,
              ),
              child: AppSheetHeader(title: t.customers.selectCustomer),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pageMargin,
                AppDimensions.paddingSm,
                AppDimensions.pageMargin,
                AppDimensions.paddingMd,
              ),
              child: AppSearchBar(
                query: searchQuery.value,
                hintText: t.customers.searchHint,
                onChanged: (value) => searchQuery.value = value,
              ),
            ),
            Expanded(
              child: switch (state) {
                AsyncData(:final value) => _buildDataState(
                  context,
                  value,
                  searchQuery.value.trim().toLowerCase(),
                  onClearSearch: clearSearch,
                ),
                AsyncError(:final error) => _buildErrorState(
                  ref,
                  error.toString(),
                ),
                _ => _buildLoadingState(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final dummy = Customer.dummy;
    return Skeletonizer(
      enabled: true,
      child: AppGroupListView(
        itemCount: _skeletonRowCount,
        bottomPadding: AppDimensions.paddingLg,
        itemBuilder: (context, index, position) => EntityListTile(
          position: position,
          leadingText: dummy.name.substring(0, 1).toUpperCase(),
          leadingShape: AppAvatarShape.forPerson(dummy.name),
          title: dummy.name,
          subtitle: Text(dummy.phone ?? dummy.name),
        ),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    List<Customer> customers,
    String query, {
    required VoidCallback onClearSearch,
  }) {
    final filtered = _filterCustomers(customers, query);

    if (filtered.isEmpty) {
      final isSearching = query.isNotEmpty;
      return SingleChildScrollView(
        child: EmptyStateView(
          message: isSearching
              ? t.common.noResults
              : t.customers.noCustomersFound,
          icon: isSearching
              ? HugeIcons.strokeRoundedSearchRemove
              : HugeIcons.strokeRoundedUserMultiple,
          actionLabel: isSearching ? t.common.clearFilters : null,
          actionIcon: isSearching ? HugeIcons.strokeRoundedFilterRemove : null,
          onAction: isSearching ? onClearSearch : null,
        ),
      );
    }

    return _buildCustomerList(filtered);
  }

  List<Customer> _filterCustomers(List<Customer> customers, String query) {
    if (query.isEmpty) return customers;
    return customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(query);
      final phoneMatch = c.phone?.toLowerCase().contains(query) ?? false;
      final cifMatch = c.cifNumber?.toLowerCase().contains(query) ?? false;
      return nameMatch || phoneMatch || cifMatch;
    }).toList();
  }

  Widget _buildCustomerList(List<Customer> customers) {
    return AppGroupListView(
      itemCount: customers.length,
      bottomPadding: AppDimensions.paddingLg,
      itemBuilder: (context, index, position) {
        final customer = customers[index];
        final subtitleParts = <String>[
          if (customer.cifNumber != null &&
              customer.cifNumber!.trim().isNotEmpty)
            '${t.customers.fields.cif}: ${customer.cifNumber}',
          if (customer.phone != null && customer.phone!.trim().isNotEmpty)
            customer.phone!.toPhoneFormat(),
        ];
        return EntityListTile(
          position: position,
          leadingText: customer.name.isNotEmpty
              ? customer.name.substring(0, 1).toUpperCase()
              : '?',
          leadingShape: AppAvatarShape.forPerson(customer.name),
          title: customer.name,
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(
                  subtitleParts.join(t.format.bulletSeparator),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
          onTap: () => Navigator.of(context).pop(customer),
        );
      },
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return ErrorStateView(
      message: error,
      onRetry: () => ref.invalidate(customersControllerProvider),
    );
  }
}
