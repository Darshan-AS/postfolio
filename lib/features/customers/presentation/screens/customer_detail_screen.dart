import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/nominees_detail_section.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AsyncEntityBuilder<Customer>(
      state: ref.watch(customersControllerProvider),
      entityId: customerId,
      idSelector: (c) => c.id,
      notFoundMessage: t.customers.customerNotFound,
      onRetry: () => ref.invalidate(customersControllerProvider),
      builder: (customer) {
        return EntityDetailScaffold(
          appBarTitle: t.customers.customerDetails,
          onEdit: () => CustomerEditRoute(customerId).push(context),
          deleteDialogTitle: t.customers.deleteCustomer,
          deleteDialogContent: t.customers.deleteCustomerConfirmation,
          onDelete: () async {
            final result = await ref
                .read(customersControllerProvider.notifier)
                .deleteCustomer(customerId);
            return result is Failure ? t.customers.failedToDeleteCustomer(error: (result as Failure).error.toString()) : null;
          },
          header: EntityDetailHeader(
            avatarChild: Text(
              customer!.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: customer.name,
            subtitle: Column(
              children: [
                if (customer.phone != null)
                  Text(
                    customer.phone!,
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                if (customer.email != null)
                  Text(
                    customer.email!,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            bottomActions: [
              if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: () => ref.read(intentServiceProvider).launchPhone(customer.phone!),
                  icon: const Icon(Icons.call_outlined),
                  label: Text(t.customers.actions.call),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ref.read(intentServiceProvider).launchSms(customer.phone!),
                  icon: const Icon(Icons.message_outlined),
                  label: Text(t.customers.actions.sms),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ref.read(intentServiceProvider).launchWhatsApp(customer.phone!),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 24),
                  label: Text(t.customers.actions.whatsapp),
                ),
              ]
            ],
          ),
          body: [
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
                  if (customer.address != null && customer.dateOfBirth != null)
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
            if (customer.cifNumber != null || customer.aadhaarNumber != null || customer.panNumber != null) ...[
              DetailSection(
                title: t.customers.sections.identityDocuments,
                children: [
                  if (customer.cifNumber != null)
                    DetailItem(
                      icon: Icons.confirmation_number_outlined,
                      label: t.customers.fields.cif,
                      value: customer.cifNumber!,
                    ),
                  if (customer.cifNumber != null && (customer.aadhaarNumber != null || customer.panNumber != null))
                    const Divider(height: 1),
                  if (customer.aadhaarNumber != null)
                    DetailItem(
                      icon: Icons.badge_outlined,
                      label: t.customers.fields.aadhaarNumber,
                      value: customer.aadhaarNumber!,
                    ),
                  if (customer.aadhaarNumber != null && customer.panNumber != null)
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
              if (customer.savingsAccount?.nominees != null)
                NomineesDetailSection(nominees: customer.savingsAccount!.nominees),
            ],
          ],
        );
      },
    );
  }
}
