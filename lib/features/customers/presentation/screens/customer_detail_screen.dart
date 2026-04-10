import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
            onPressed: () => context.push(RouteNames.customerEdit(customerId)),
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
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingLg,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                ),
                child: Column(
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
                    if (customer.phone != null &&
                        customer.phone!.isNotEmpty) ...[
                      AppSpacings.gapLg,
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppDimensions.paddingSm,
                        runSpacing: AppDimensions.paddingSm,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                _launchUrl('tel:${customer.phone}'),
                            icon: const Icon(Icons.call_outlined),
                            label: Text(t.customers.actions.call),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _launchUrl('sms:${customer.phone}'),
                            icon: const Icon(Icons.message_outlined),
                            label: Text(t.customers.actions.sms),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _launchUrl(
                              'https://wa.me/${customer.phone!.replaceAll(RegExp(r'[^\d+]'), '')}',
                            ),
                            icon: const FaIcon(FontAwesomeIcons.whatsapp),
                            label: Text(t.customers.actions.whatsapp),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacings.gapXl,

              if (customer.address != null || customer.dateOfBirth != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  child: Text(
                    t.customers.sections.personalInfo,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacings.gapSm,
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (customer.address != null)
                        ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            t.customers.fields.homeAddress,
                            style: textTheme.bodySmall,
                          ),
                          subtitle: Text(
                            customer.address!,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      if (customer.address != null &&
                          customer.dateOfBirth != null)
                        const Divider(height: 1),
                      if (customer.dateOfBirth != null)
                        ListTile(
                          leading: Icon(
                            Icons.calendar_today_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(t.customers.fields.dateOfBirth),
                          subtitle: Text(
                            DateFormat.yMMMd().format(customer.dateOfBirth!),
                          ),
                        ),
                    ],
                  ),
                ),
                AppSpacings.gapLg,
              ],

              if (customer.cifNumber != null ||
                  customer.aadhaarNumber != null ||
                  customer.panNumber != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  child: Text(
                    t.customers.sections.identityDocuments,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacings.gapSm,
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (customer.cifNumber != null) ...[
                        ListTile(
                          leading: Icon(
                            Icons.confirmation_number_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            t.customers.fields.cif,
                            style: textTheme.bodySmall,
                          ),
                          subtitle: Text(
                            customer.cifNumber!,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      if (customer.cifNumber != null &&
                          (customer.aadhaarNumber != null ||
                              customer.panNumber != null))
                        const Divider(height: 1),
                      if (customer.aadhaarNumber != null) ...[
                        ListTile(
                          leading: Icon(
                            Icons.badge_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            t.customers.fields.aadhaarNumber,
                            style: textTheme.bodySmall,
                          ),
                          subtitle: Text(
                            customer.aadhaarNumber!,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      if (customer.aadhaarNumber != null &&
                          customer.panNumber != null)
                        const Divider(height: 1),
                      if (customer.panNumber != null) ...[
                        ListTile(
                          leading: Icon(
                            Icons.credit_card_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            t.customers.fields.panNumber,
                            style: textTheme.bodySmall,
                          ),
                          subtitle: Text(
                            customer.panNumber!,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacings.gapLg,
              ],

              if (customer.savingsAccount != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  child: Text(
                    t.customers.sections.savingsBank,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacings.gapSm,
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (customer.savingsAccount?.accountNumber != null) ...[
                        ListTile(
                          leading: Icon(
                            Icons.account_balance_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            t.customers.fields.sbAccountNumber,
                            style: textTheme.bodySmall,
                          ),
                          subtitle: Text(
                            customer.savingsAccount!.accountNumber,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      if (customer.savingsAccount?.nominees != null &&
                          customer.savingsAccount!.nominees.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(
                            AppDimensions.paddingLg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nominees', style: textTheme.titleSmall),
                              AppSpacings.gapSm,
                              ...customer.savingsAccount!.nominees.map((
                                nominee,
                              ) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.person_pin_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    nominee.name,
                                    style: textTheme.bodyLarge,
                                  ),
                                  subtitle: Text(
                                    '${nominee.relationship} • ${nominee.percentage}%',
                                    style: textTheme.bodyMedium,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacings.gapLg,
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
