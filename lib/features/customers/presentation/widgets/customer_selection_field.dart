import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/entity_list_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return const _CustomerSelectionSheet();
        },
      ).then((selected) {
        if (selected != null && selected is Customer) {
          selectedCustomer.value = selected;
          onCustomerSelected(selected);
        }
      });
    }

    Customer? displayCustomer = selectedCustomer.value;

    if (displayCustomer == null && initialCustomerId != null) {
      displayCustomer = ref.watch(customerByIdProvider(initialCustomerId!));
    }

    return InkWell(
      onTap: showSelectionSheet,
      child: InputDecorator(
        decoration: AppInputDecoration.m3(
          context,
          labelText: t.oneTimeDeposits.fields.customerId,
          prefixIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedUser,
            size: AppDimensions.iconMd,
          ),
          errorText: errorText,
          isRequired: true,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayCustomer?.name ?? t.customers.selectCustomer,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: displayCustomer == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (displayCustomer != null)
              Text(
                displayCustomer.cifNumber ?? displayCustomer.id,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: AppDimensions.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSelectionSheet extends HookConsumerWidget {
  const _CustomerSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final state = ref.watch(customersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.customers.selectCustomer),
        leading: const CloseButton(),
      ),
      body: Column(
        children: [
          _buildSearchBar(context, searchQuery),
          Expanded(
            child: switch (state) {
              AsyncData(:final value) => _buildDataState(
                context,
                value,
                searchQuery.value,
              ),
              AsyncError(:final error) => _buildErrorState(
                ref,
                error.toString(),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    ValueNotifier<String> searchQuery,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: TextField(
        decoration: AppInputDecoration.m3(
          context,
          hintText: t.customers.searchHint,
          prefixIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: AppDimensions.iconMd,
          ),
        ),
        onChanged: (value) => searchQuery.value = value.toLowerCase(),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    List<Customer> customers,
    String query,
  ) {
    final filtered = _filterCustomers(customers, query);

    if (filtered.isEmpty) {
      return Center(child: Text(t.customers.noCustomersFound));
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
    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return EntityListTile(
          leadingText: customer.name.isNotEmpty
              ? customer.name.substring(0, 1).toUpperCase()
              : '?',
          title: customer.name,
          subtitle: Text(
            [
              if (customer.cifNumber != null) 'CIF: ${customer.cifNumber}',
              if (customer.phone != null) customer.phone,
            ].join(' • '),
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
