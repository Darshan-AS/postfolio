import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/domain/nominees_detail_section.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:postfolio/core/extensions/string_extension.dart';

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
                Text(
                  customer.phone?.toPhoneFormat() ?? t.common.notProvided,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  customer.email ?? t.common.notProvided,
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
          floatingActionButton: SpeedDial(
            heroTag: null,
            spacing: AppDimensions.paddingSm,
            spaceBetweenChildren: AppDimensions.paddingSm,
            backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
            foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
            activeChild: const HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: AppDimensions.iconMd,
            ),
            children: [
              SpeedDialChild(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                label: t.recurringDeposits.title,
                onTap: () => RecurringDepositCreateRoute(
                  customerId: customerId,
                ).push(context),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTransaction,
                  size: AppDimensions.iconMd,
                ),
              ),
              SpeedDialChild(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                label: t.oneTimeDeposits.title,
                onTap: () => OneTimeDepositCreateRoute(
                  customerId: customerId,
                ).push(context),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
                  size: AppDimensions.iconMd,
                ),
              ),
            ],
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: AppDimensions.iconMd,
            ),
          ),
          body: [
            _buildPersonalInfo(customer),
            AppSpacings.gapLg,
            _buildIdentityDocuments(customer),
            AppSpacings.gapLg,
            _buildSavingsBank(customer),
            AppSpacings.gapLg,
            if (customer.savingsAccount?.nominees != null) ...[
              NomineesDetailSection(
                nominees: customer.savingsAccount!.nominees,
              ),
              AppSpacings.gapLg,
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
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedLocation01,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.homeAddress,
        value: customer.address ?? t.common.notProvided,
      ),
      const Divider(height: AppDimensions.dividerHeight),
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedCalendar01,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.dateOfBirth,
        value: customer.dateOfBirth?.toAppFormat() ?? t.common.notProvided,
      ),
    ],
  );
}

Widget _buildIdentityDocuments(Customer customer) {
  return DetailSection(
    title: t.customers.sections.identityDocuments,
    children: [
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedTicket01,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.cif,
        value: customer.cifNumber ?? t.common.notProvided,
      ),
      const Divider(height: AppDimensions.dividerHeight),
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedId,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.aadhaarNumber,
        value:
            customer.aadhaarNumber?.toAadhaarFormat() ?? t.common.notProvided,
      ),
      const Divider(height: AppDimensions.dividerHeight),
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedCreditCard,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.panNumber,
        value: customer.panNumber?.toPanFormat() ?? t.common.notProvided,
      ),
    ],
  );
}

Widget _buildSavingsBank(Customer customer) {
  return DetailSection(
    title: t.customers.sections.savingsBank,
    children: [
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedBank,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.sbAccountNumber,
        value: customer.savingsAccount?.accountNumber ?? t.common.notProvided,
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
    final recurringDepositsAsync = ref.watch(
      recurringDepositsControllerProvider,
    );

    final oneTimeDeposits =
        oneTimeDepositsAsync.value
            ?.where((d) => d.customerId == customerId)
            .toList() ??
        [];

    final activeOneTime =
        oneTimeDeposits.where((d) => d.status == DepositStatus.active).toList()
          ..sort(OneTimeDeposit.defaultCompare);

    final closedOneTime =
        oneTimeDeposits.where((d) => d.status == DepositStatus.closed).toList()
          ..sort(OneTimeDeposit.defaultCompare);

    final recurringDeposits =
        recurringDepositsAsync.value
            ?.where((d) => d.customerId == customerId)
            .toList() ??
        [];

    final activeRecurring =
        recurringDeposits
            .where((d) => d.status == DepositStatus.active)
            .toList()
          ..sort(RecurringDeposit.defaultCompare);

    final closedRecurring =
        recurringDeposits
            .where((d) => d.status == DepositStatus.closed)
            .toList()
          ..sort(RecurringDeposit.defaultCompare);

    if (oneTimeDeposits.isEmpty && recurringDeposits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (oneTimeDeposits.isNotEmpty)
          _DepositCategorySection(
            title: t.oneTimeDeposits.title,
            activeDeposits: activeOneTime,
            closedDeposits: closedOneTime,
            itemBuilder: (deposit) => OneTimeDepositCard(
              deposit: deposit,
              overrideTitle: deposit.schemeType.displayName,
            ),
          ),
        if (recurringDeposits.isNotEmpty)
          _DepositCategorySection(
            title: t.recurringDeposits.title,
            activeDeposits: activeRecurring,
            closedDeposits: closedRecurring,
            itemBuilder: (deposit) => RecurringDepositCard(
              deposit: deposit,
              overrideTitle: (deposit.serialNo?.isNotEmpty ?? false)
                  ? '(${deposit.serialNo}) ${deposit.accountNo ?? t.common.notProvided}'
                  : (deposit.accountNo ?? t.common.notProvided),
              overrideSubtitle: '',
            ),
          ),
      ],
    );
  }
}

class _DepositCategorySection<T> extends StatelessWidget {
  final String title;
  final List<T> activeDeposits;
  final List<T> closedDeposits;
  final Widget Function(T deposit) itemBuilder;

  const _DepositCategorySection({
    required this.title,
    required this.activeDeposits,
    required this.closedDeposits,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (activeDeposits.isEmpty && closedDeposits.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSection(
          title: title,
          children: [
            ...activeDeposits
                .asMap()
                .map(
                  (index, deposit) => MapEntry(
                    index,
                    Column(
                      children: [
                        itemBuilder(deposit),
                        if (index < activeDeposits.length - 1 ||
                            closedDeposits.isNotEmpty)
                          const Divider(height: AppDimensions.dividerHeight),
                      ],
                    ),
                  ),
                )
                .values,
            if (closedDeposits.isNotEmpty)
              ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                collapsedIconColor: colorScheme.onSurfaceVariant,
                iconColor: colorScheme.primary,
                title: Text(
                  t.common.countWithLabel(
                    label: DepositStatus.closed.displayName,
                    count: closedDeposits.length,
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                children: closedDeposits
                    .asMap()
                    .map(
                      (index, deposit) => MapEntry(
                        index,
                        Column(
                          children: [
                            Opacity(
                              opacity: AppDimensions.opacityMuted,
                              child: itemBuilder(deposit),
                            ),
                            if (index < closedDeposits.length - 1)
                              const Divider(
                                height: AppDimensions.dividerHeight,
                              ),
                          ],
                        ),
                      ),
                    )
                    .values
                    .toList(),
              ),
          ],
        ),
        AppSpacings.gapLg,
      ],
    );
  }
}
