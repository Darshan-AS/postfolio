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
      final state = ref.watch(customersControllerProvider);
      displayCustomer = state.value
          ?.where((c) => c.id == initialCustomerId)
          .firstOrNull;
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
          Padding(
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
          ),
          Expanded(
            child: state.when(
              data: (customers) {
                final filtered = customers.where((c) {
                  final nameMatch = c.name.toLowerCase().contains(searchQuery.value);
                  final phoneMatch =
                      c.phone?.toLowerCase().contains(searchQuery.value) ?? false;
                  final cifMatch =
                      c.cifNumber?.toLowerCase().contains(searchQuery.value) ??
                      false;
                  return nameMatch || phoneMatch || cifMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(t.customers.noCustomersFound));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return EntityListTile(
                      leadingText: customer.name.isNotEmpty
                          ? customer.name.substring(0, 1).toUpperCase()
                          : '?',
                      title: customer.name,
                      subtitle: Text(
                        [
                          if (customer.cifNumber != null)
                            'CIF: ${customer.cifNumber}',
                          if (customer.phone != null) customer.phone,
                        ].join(' • '),
                      ),
                      onTap: () => Navigator.of(context).pop(customer),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorStateView(
                message: error.toString(),
                onRetry: () => ref.invalidate(customersControllerProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
