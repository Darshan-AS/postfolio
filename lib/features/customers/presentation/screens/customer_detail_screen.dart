import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/intent_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.customers.deleteCustomer),
        content: Text(t.customers.deleteCustomerConfirmation),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(t.common.cancel)),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
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
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        t.customers.failedToDeleteCustomer(
                          error: err.toString(),
                        ),
                      ),
                    ),
                  );
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.customers.customerDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => CustomerEditRoute(customerId).push(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: colorScheme.error,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: customersState.when(
        data: (customers) {
          // Find the specific customer from the state
          final customer = customers
              .where((u) => u.id == customerId)
              .firstOrNull;

          if (customer == null) {
            return Center(child: Text(t.customers.customerNotFound));
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: AppDimensions.iconXl * 1.5,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  AppSpacings.gapLg,
                  Text(
                    customer.name,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacings.gapSm,
                  if (customer.phone != null)
                    Text(
                      customer.phone!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (customer.email != null)
                    Text(
                      customer.email!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                    AppSpacings.gapLg,
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppDimensions.paddingSm,
                      runSpacing: AppDimensions.paddingSm,
                      children: [
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(intentServiceProvider)
                              .launchPhone(customer.phone!),
                          icon: const Icon(Icons.call_outlined),
                          label: Text(t.customers.actions.call),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => ref
                              .read(intentServiceProvider)
                              .launchSms(customer.phone!),
                          icon: const Icon(Icons.message_outlined),
                          label: Text(t.customers.actions.sms),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => ref
                              .read(intentServiceProvider)
                              .launchWhatsApp(customer.phone!),
                          icon: const FaIcon(FontAwesomeIcons.whatsapp),
                          label: Text(t.customers.actions.whatsapp),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              AppSpacings.gapXl,

              if (customer.address != null || customer.dateOfBirth != null) ...[
                DetailSection(
                  title: t.customers.sections.personalInfo,
                  children: [
                    if (customer.address != null)
                      DetailItem(
                        icon: Icons.location_on_outlined,
                        label: t.customers.fields.homeAddress,
                        value: customer.address!,
                      ),
                    if (customer.address != null &&
                        customer.dateOfBirth != null)
                      const Divider(height: 1),
                    if (customer.dateOfBirth != null)
                      DetailItem(
                        icon: Icons.calendar_today_outlined,
                        label: t.customers.fields.dateOfBirth,
                        value: DateFormat.yMMMd().format(customer.dateOfBirth!),
                      ),
                  ],
                ),
                AppSpacings.gapLg,
              ],

              if (customer.cifNumber != null ||
                  customer.aadhaarNumber != null ||
                  customer.panNumber != null) ...[
                DetailSection(
                  title: t.customers.sections.identityDocuments,
                  children: [
                    if (customer.cifNumber != null)
                      DetailItem(
                        icon: Icons.confirmation_number_outlined,
                        label: t.customers.fields.cif,
                        value: customer.cifNumber!,
                      ),
                    if (customer.cifNumber != null &&
                        (customer.aadhaarNumber != null ||
                            customer.panNumber != null))
                      const Divider(height: 1),
                    if (customer.aadhaarNumber != null)
                      DetailItem(
                        icon: Icons.badge_outlined,
                        label: t.customers.fields.aadhaarNumber,
                        value: customer.aadhaarNumber!,
                      ),
                    if (customer.aadhaarNumber != null &&
                        customer.panNumber != null)
                      const Divider(height: 1),
                    if (customer.panNumber != null)
                      DetailItem(
                        icon: Icons.credit_card_outlined,
                        label: t.customers.fields.panNumber,
                        value: customer.panNumber!,
                      ),
                  ],
                ),
                AppSpacings.gapLg,
              ],

              if (customer.savingsAccount != null) ...[
                DetailSection(
                  title: t.customers.sections.savingsBank,
                  children: [
                    if (customer.savingsAccount?.accountNumber != null)
                      DetailItem(
                        icon: Icons.account_balance_outlined,
                        label: t.customers.fields.sbAccountNumber,
                        value: customer.savingsAccount!.accountNumber,
                      ),
                  ],
                ),
                AppSpacings.gapLg,
                if (customer.savingsAccount?.nominees != null &&
                    customer.savingsAccount!.nominees.isNotEmpty) ...[
                  DetailSection(
                    title: 'Nominees',
                    children: [
                      for (
                        int i = 0;
                        i < customer.savingsAccount!.nominees.length;
                        i++
                      ) ...[
                        DetailItem(
                          icon: Icons.person_outline,
                          label:
                              customer.savingsAccount!.nominees[i].relationship,
                          value:
                              '${customer.savingsAccount!.nominees[i].name} (${customer.savingsAccount!.nominees[i].percentage}%)',
                        ),
                        if (i < customer.savingsAccount!.nominees.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                  AppSpacings.gapLg,
                ],
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
