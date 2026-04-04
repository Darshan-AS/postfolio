import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.customers.deleteCustomer),
        content: Text(t.customers.deleteCustomerConfirmation),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(t.common.cancel)),
          TextButton(
            onPressed: () async {
              final result = await ref
                  .read(customersControllerProvider.notifier)
                  .deleteCustomer(customerId);

              if (!context.mounted) return;

              switch (result) {
                case Success():
                  ctx.pop(); // Dismiss dialog
                  context.pop(); // Pop back to customer list
                case Failure(error: final err):
                  ctx.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t.customers.failedToDeleteCustomer(error: err.toString()),
                      ),
                    ),
                  );
              }
            },
            child: Text(
              t.common.delete,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(RouteNames.customerEdit(customerId)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.error,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: customersState.when(
        data: (customers) {
          // Find the specific customer from the state
          final customer = customers.where((u) => u.id == customerId).firstOrNull;

          if (customer == null) {
            return Center(child: Text(t.customers.customerNotFound));
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              const CircleAvatar(
                radius: AppDimensions.iconXl,
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.surface,
                child: Icon(Icons.person, size: AppDimensions.iconXl),
              ),
              AppSpacings.gapLg,
              Text(
                customer.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapSm,
              if (customer.phone != null)
                Text(
                  customer.phone!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              if (customer.email != null)
                Text(
                  customer.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              AppSpacings.gapLg,
              const Divider(),
              if (customer.address != null) ...[
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(t.customers.fields.homeAddress),
                  subtitle: Text(customer.address!),
                ),
              ],
              if (customer.cifNumber != null) ...[
                ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: const Text('CIF'),
                  subtitle: Text(customer.cifNumber!),
                ),
              ],
              if (customer.dateOfBirth != null) ...[
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date of Birth'),
                  subtitle: Text(DateFormat.yMMMd().format(customer.dateOfBirth!)),
                ),
              ],
              if (customer.aadhaarNumber != null) ...[
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Aadhaar Number'),
                  subtitle: Text(customer.aadhaarNumber!),
                ),
              ],
              if (customer.panNumber != null) ...[
                ListTile(
                  leading: const Icon(Icons.credit_card_outlined),
                  title: const Text('PAN Number'),
                  subtitle: Text(customer.panNumber!),
                ),
              ],
              if (customer.savingsAccount?.accountNumber != null) ...[
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: const Text('SB Account No.'),
                  subtitle: Text(customer.savingsAccount!.accountNumber),
                ),
              ],
              if (customer.savingsAccount?.nominee?.name != null) ...[
                ListTile(
                  leading: const Icon(Icons.person_pin_outlined),
                  title: const Text('SB Nominee Name'),
                  subtitle: Text(customer.savingsAccount!.nominee!.name),
                ),
              ],
              if (customer.savingsAccount?.nominee?.relationship != null) ...[
                ListTile(
                  leading: const Icon(Icons.people_alt_outlined),
                  title: const Text('SB Nominee Relationship'),
                  subtitle: Text(customer.savingsAccount!.nominee!.relationship),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(customersControllerProvider),
        ),
      ),
    );
  }
}
