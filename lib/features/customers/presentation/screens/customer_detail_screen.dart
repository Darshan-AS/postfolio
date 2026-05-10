import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/nominees_detail_section.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/widgets/app_dialogs.dart';
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
      dummyEntity: Customer.dummy,
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
            return result is Failure
                ? t.customers.failedToDeleteCustomer(
                    error: (result as Failure).error.toString(),
                  )
                : null;
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
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (customer.email != null)
                  Text(
                    customer.email!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            bottomActions: [
              if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: () => ref
                      .read(intentServiceProvider)
                      .launchPhone(customer.phone!),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCall02,
                    size: AppDimensions.iconMd,
                  ),
                  label: Text(t.customers.actions.call),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ref
                      .read(intentServiceProvider)
                      .launchSms(customer.phone!),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedComment01,
                    size: AppDimensions.iconMd,
                  ),
                  label: Text(t.customers.actions.sms),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ref
                      .read(intentServiceProvider)
                      .launchWhatsApp(customer.phone!),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedWhatsapp,
                    size: AppDimensions.iconMd,
                  ),
                  label: Text(t.customers.actions.whatsapp),
                ),
              ],
            ],
          ),
          body: [
            if (customer.address != null || customer.dateOfBirth != null) ...[
              _buildPersonalInfo(customer),
              AppSpacings.gapLg,
            ],
            if (customer.cifNumber != null ||
                customer.aadhaarNumber != null ||
                customer.panNumber != null) ...[
              _buildIdentityDocuments(customer),
              AppSpacings.gapLg,
            ],
            if (customer.savingsAccount != null) ...[
              _buildSavingsBank(customer),
              AppSpacings.gapLg,
              if (customer.savingsAccount?.nominees != null) ...[
                NomineesDetailSection(
                  nominees: customer.savingsAccount!.nominees,
                ),
                AppSpacings.gapLg,
              ],
            ],
            _CustomerDepositsSection(customerId: customerId),
          ],
        );
      },
    );
  }
}

Widget _buildPersonalInfo(Customer customer) {
  return DetailSection(
    title: t.customers.sections.personalInfo,
    children: [
      if (customer.address != null)
        DetailItem(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedLocation01,
            size: AppDimensions.iconMd,
          ),
          label: t.customers.fields.homeAddress,
          value: customer.address!,
        ),
      if (customer.address != null && customer.dateOfBirth != null)
        const Divider(height: AppDimensions.dividerHeight),
      if (customer.dateOfBirth != null)
        DetailItem(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCalendar01,
            size: AppDimensions.iconMd,
          ),
          label: t.customers.fields.dateOfBirth,
          value: customer.dateOfBirth!.toAppFormat(),
        ),
    ],
  );
}

Widget _buildIdentityDocuments(Customer customer) {
  return DetailSection(
    title: t.customers.sections.identityDocuments,
    children: [
      if (customer.cifNumber != null)
        DetailItem(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedTicket01,
            size: AppDimensions.iconMd,
          ),
          label: t.customers.fields.cif,
          value: customer.cifNumber!,
        ),
      if (customer.cifNumber != null &&
          (customer.aadhaarNumber != null || customer.panNumber != null))
        const Divider(height: AppDimensions.dividerHeight),
      if (customer.aadhaarNumber != null)
        DetailItem(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedId,
            size: AppDimensions.iconMd,
          ),
          label: t.customers.fields.aadhaarNumber,
          value: customer.aadhaarNumber!,
        ),
      if (customer.aadhaarNumber != null && customer.panNumber != null)
        const Divider(height: AppDimensions.dividerHeight),
      if (customer.panNumber != null)
        DetailItem(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCreditCard,
            size: AppDimensions.iconMd,
          ),
          label: t.customers.fields.panNumber,
          value: customer.panNumber!,
        ),
    ],
  );
}

Widget _buildSavingsBank(Customer customer) {
  return DetailSection(
    title: t.customers.sections.savingsBank,
    children: [
      if (customer.savingsAccount?.accountNumber != null)
        DetailItem(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedBank,
            size: AppDimensions.iconMd,
          ),
          label: t.customers.fields.sbAccountNumber,
          value: customer.savingsAccount!.accountNumber,
        ),
    ],
  );
}

class _CustomerDepositsSection extends ConsumerWidget {
  final String customerId;

  const _CustomerDepositsSection({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oneTimeDepositsAsync = ref.watch(oneTimeDepositsControllerProvider);
    final recurringDepositsAsync = ref.watch(recurringDepositsControllerProvider);

    final oneTimeDeposits = oneTimeDepositsAsync.value
            ?.where((d) => d.customerId == customerId)
            .toList() ??
        [];
    final recurringDeposits = recurringDepositsAsync.value
            ?.where((d) => d.customerId == customerId)
            .toList() ??
        [];

    if (oneTimeDeposits.isEmpty && recurringDeposits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (oneTimeDeposits.isNotEmpty) ...[
          DetailSection(
            title: t.oneTimeDeposits.title,
            children: oneTimeDeposits
                .asMap()
                .map((index, deposit) => MapEntry(
                      index,
                      Column(
                        children: [
                          OneTimeDepositCard(
                            title: deposit.accountNo,
                            subtitle: deposit.maturityDate.toAppFormat(),
                            principalAmount: deposit.principalAmount,
                            status: deposit.status,
                            onTap: () =>
                                OneTimeDepositDetailRoute(deposit.id).push(context),
                            onEdit: () =>
                                OneTimeDepositEditRoute(deposit.id).push(context),
                            onDelete: () async {
                              final confirmed = await AppDialogs.confirmDelete(
                                context,
                                title: t.oneTimeDeposits.deleteDeposit,
                                content: t.oneTimeDeposits.deleteDepositConfirmation,
                              );
                              if (confirmed == true && context.mounted) {
                                await ref
                                    .read(oneTimeDepositsControllerProvider.notifier)
                                    .deleteOneTimeDeposit(deposit.id);
                              }
                            },
                          ),
                          if (index < oneTimeDeposits.length - 1)
                            const Divider(height: AppDimensions.dividerHeight),
                        ],
                      ),
                    ))
                .values
                .toList(),
          ),
          AppSpacings.gapLg,
        ],
        if (recurringDeposits.isNotEmpty) ...[
          DetailSection(
            title: t.recurringDeposits.title,
            children: recurringDeposits
                .asMap()
                .map((index, deposit) => MapEntry(
                      index,
                      Column(
                        children: [
                          RecurringDepositCard(
                            title: deposit.serialNo.isNotEmpty
                                ? '(${deposit.serialNo}) ${deposit.accountNo}'
                                : deposit.accountNo,
                            subtitle: deposit.maturityDate.toAppFormat(),
                            installmentAmount: deposit.installmentAmount,
                            status: deposit.status,
                            onTap: () =>
                                RecurringDepositDetailRoute(deposit.id).push(context),
                            onEdit: () =>
                                RecurringDepositEditRoute(deposit.id).push(context),
                            onDelete: () async {
                              final confirmed = await AppDialogs.confirmDelete(
                                context,
                                title: t.recurringDeposits.deleteDeposit,
                                content: t.recurringDeposits.deleteDepositConfirmation,
                              );
                              if (confirmed == true && context.mounted) {
                                await ref
                                    .read(recurringDepositsControllerProvider.notifier)
                                    .deleteRecurringDeposit(deposit.id);
                              }
                            },
                          ),
                          if (index < recurringDeposits.length - 1)
                            const Divider(height: AppDimensions.dividerHeight),
                        ],
                      ),
                    ))
                .values
                .toList(),
          ),
          AppSpacings.gapLg,
        ],
      ],
    );
  }
}

