import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';

class CustomerSelectionField extends ConsumerStatefulWidget {
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
  ConsumerState<CustomerSelectionField> createState() =>
      _CustomerSelectionFieldState();
}

class _CustomerSelectionFieldState
    extends ConsumerState<CustomerSelectionField> {
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;
  }

  void _showSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return const _CustomerSelectionSheet();
      },
    ).then((selected) {
      if (selected != null && selected is Customer) {
        setState(() {
          _selectedCustomer = selected;
        });
        widget.onCustomerSelected(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we only have ID but no initialCustomer, we might want to watch the controller
    // However, it's better if the parent passes the initialCustomer directly,
    // or we resolve it here.
    if (_selectedCustomer == null && widget.initialCustomerId != null) {
      final state = ref.watch(customersControllerProvider);
      state.whenData((customers) {
        final cust = customers
            .where((c) => c.id == widget.initialCustomerId)
            .firstOrNull;
        if (cust != null && _selectedCustomer?.id != cust.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCustomer = cust;
              });
            }
          });
        }
      });
    }

    return InkWell(
      onTap: _showSelectionSheet,
      child: InputDecorator(
        decoration: AppInputDecoration.m3(
          context,
          labelText: t.oneTimeDeposits.fields.customerId,
          prefixIcon: Icons.person_outline,
          errorText: widget.errorText,
          isRequired: true,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedCustomer?.name ?? 'Select a customer',
                style: TextStyle(
                  color: _selectedCustomer == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (_selectedCustomer != null)
              Text(
                _selectedCustomer!.cifNumber ?? _selectedCustomer!.id,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _CustomerSelectionSheet extends ConsumerStatefulWidget {
  const _CustomerSelectionSheet();

  @override
  ConsumerState<_CustomerSelectionSheet> createState() =>
      _CustomerSelectionSheetState();
}

class _CustomerSelectionSheetState
    extends ConsumerState<_CustomerSelectionSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Customer'),
        leading: const CloseButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: TextField(
              decoration: AppInputDecoration.m3(
                context,
                hintText: 'Search by name, phone or CIF...',
                prefixIcon: Icons.search,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: state.when(
              data: (customers) {
                final filtered = customers.where((c) {
                  final nameMatch = c.name.toLowerCase().contains(_searchQuery);
                  final phoneMatch =
                      c.phone?.toLowerCase().contains(_searchQuery) ?? false;
                  final cifMatch =
                      c.cifNumber?.toLowerCase().contains(_searchQuery) ??
                      false;
                  return nameMatch || phoneMatch || cifMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          customer.name.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(customer.name),
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
