import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_fab.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
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

import 'package:postfolio/core/extensions/string_extension.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AsyncSingleEntityBuilder<Customer>(
      state: ref.watch(customerByIdProvider(customerId)),
      notFoundMessage: t.customers.customerNotFound,
      onRetry: () => ref.invalidate(customerByIdProvider(customerId)),
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
            avatarText: customer.name.isNotEmpty
                ? customer.name[0].toUpperCase()
                : t.common.notProvided,
            avatarShape: AppAvatarShape.forSeed(customer.name),
            title: customer.name,
            // A number or an address broken across two lines reads as two things, so each
            // stays on one line and shrinks when it has to.
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    customer.phone?.toPhoneFormat() ?? t.common.notProvided,
                    maxLines: 1,
                    softWrap: false,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    customer.email ?? t.common.notProvided,
                    maxLines: 1,
                    softWrap: false,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            bottomActions: [
              if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                AppButton(
                  label: t.customers.actions.call,
                  icon: HugeIcons.strokeRoundedCall02,
                  onPressed: () => ref
                      .read(intentServiceProvider)
                      .launchPhone(customer.phone!),
                ),
                AppButton.tonal(
                  label: t.customers.actions.sms,
                  icon: HugeIcons.strokeRoundedComment01,
                  onPressed: () => ref
                      .read(intentServiceProvider)
                      .launchSms(customer.phone!),
                ),
                AppButton.tonal(
                  label: t.customers.actions.whatsapp,
                  icon: HugeIcons.strokeRoundedWhatsapp,
                  onPressed: () => ref
                      .read(intentServiceProvider)
                      .launchWhatsApp(customer.phone!),
                ),
              ],
            ],
          ),
          floatingActionButton: AppFabMenu(
            icon: HugeIcons.strokeRoundedAdd01,
            closeIcon: HugeIcons.strokeRoundedCancel01,
            actions: [
              AppFabMenuAction(
                label: t.recurringDeposits.title,
                icon: HugeIcons.strokeRoundedTransaction,
                onPressed: () => RecurringDepositCreateRoute(
                  customerId: customerId,
                ).push(context),
              ),
              AppFabMenuAction(
                label: t.oneTimeDeposits.title,
                icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
                onPressed: () => OneTimeDepositCreateRoute(
                  customerId: customerId,
                ).push(context),
              ),
            ],
          ),
          body: [
            _buildPersonalInfo(context, ref, customer),
            if (customer.cifNumber != null ||
                customer.aadhaarNumber != null ||
                customer.panNumber != null) ...[
              AppSpacings.gapLg,
              _buildIdentityDocuments(customer),
            ],
            if (customer.savingsAccount != null) ...[
              AppSpacings.gapLg,
              _buildSavingsBank(customer),
            ],
            if (customer.savingsAccount != null &&
                customer.savingsAccount!.nominees.isNotEmpty) ...[
              AppSpacings.gapLg,
              NomineesDetailSection(
                nominees: customer.savingsAccount!.nominees,
              ),
            ],
            if (customer.notes != null && customer.notes!.trim().isNotEmpty) ...[
              AppSpacings.gapLg,
              _buildNotes(customer),
            ],
            AppSpacings.gapLg,
            _CustomerDepositsSection(customerId: customerId),
          ],
        );
      },
    );
  }
}

Widget _buildPersonalInfo(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
) {
  final hasAddress = customer.address != null && customer.address!.trim().isNotEmpty;
  final items = <Widget>[
    DetailItem(
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedLocation01,
        size: AppDimensions.iconMd,
      ),
      label: t.customers.fields.homeAddress,
      value: customer.address ?? t.common.notProvided,
      onTap: hasAddress
          ? () => ref.read(intentServiceProvider).launchMapSearch(customer.address!)
          : null,
    ),
    if (customer.dateOfBirth != null)
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedCalendar01,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.dateOfBirth,
        value: customer.dateOfBirth!.toAppFormat(),
      ),
  ];

  return DetailSection(
    title: t.customers.sections.personalInfo,
    children: items,
  );
}

Widget _buildNotes(Customer customer) {
  return Builder(
    builder: (context) {
      return DetailSection(
        title: t.customers.fields.notes,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
              vertical: AppDimensions.paddingMd,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                (customer.notes != null && customer.notes!.isNotEmpty) 
                    ? customer.notes! 
                    : t.common.notProvided,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (customer.notes != null && customer.notes!.isNotEmpty)
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: (customer.notes != null && customer.notes!.isNotEmpty)
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      );
    }
  );
}

Widget _buildIdentityDocuments(Customer customer) {
  final items = <Widget>[
    if (customer.cifNumber != null && customer.cifNumber!.isNotEmpty)
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedTicket01,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.cif,
        value: customer.cifNumber,
        copyValue: customer.cifNumber,
        hideIfNull: true,
      ),
    if (customer.aadhaarNumber != null && customer.aadhaarNumber!.isNotEmpty)
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedId,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.aadhaarNumber,
        value: customer.aadhaarNumber!.toAadhaarFormat(),
        copyValue: customer.aadhaarNumber,
        hideIfNull: true,
      ),
    if (customer.panNumber != null && customer.panNumber!.isNotEmpty)
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedCreditCard,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.panNumber,
        value: customer.panNumber!.toPanFormat(),
        copyValue: customer.panNumber,
        hideIfNull: true,
      ),
  ];

  return DetailSection(
    title: t.customers.sections.identityDocuments,
    children: items,
  );
}

Widget _buildSavingsBank(Customer customer) {
  final sbAccountNo = customer.savingsAccount?.accountNumber;
  return DetailSection(
    title: t.customers.sections.savingsBank,
    children: [
      DetailItem(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedBank,
          size: AppDimensions.iconMd,
        ),
        label: t.customers.fields.sbAccountNumber,
        value: sbAccountNo ?? t.common.notProvided,
        copyValue: sbAccountNo,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (oneTimeDeposits.isNotEmpty)
          _DepositCategorySection(
            title: t.oneTimeDeposits.title,
            activeDeposits: activeOneTime,
            closedDeposits: closedOneTime,
            itemBuilder: (deposit, position) => OneTimeDepositCard(
              deposit: deposit,
              overrideTitle: deposit.schemeType.displayName,
              position: position,
            ),
          ),
        if (recurringDeposits.isNotEmpty)
          _DepositCategorySection(
            title: t.recurringDeposits.title,
            activeDeposits: activeRecurring,
            closedDeposits: closedRecurring,
            itemBuilder: (deposit, position) => RecurringDepositCard(
              deposit: deposit,
              overrideTitle: deposit.schemeType.displayName,
              position: position,
            ),
          ),
      ],
    );
  }
}

/// One kind of deposit held by the customer: the active accounts as a group of rows, and
/// the closed ones behind a toggle so they do not crowd the list.
class _DepositCategorySection<T> extends HookWidget {
  final String title;
  final List<T> activeDeposits;
  final List<T> closedDeposits;
  final Widget Function(T deposit, AppGroupPosition position) itemBuilder;

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

    final showClosed = useState(false);

    List<Widget> rows(List<T> deposits) => [
      for (var i = 0; i < deposits.length; i++) ...[
        if (i > 0) const SizedBox(height: AppShapes.groupGap),
        itemBuilder(deposits[i], AppGroupPosition.at(i, deposits.length)),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailSectionTitle(title),
        ...rows(activeDeposits),
        if (closedDeposits.isNotEmpty) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton.text(
              label: t.common.countWithLabel(
                label: DepositStatus.closed.displayName,
                count: closedDeposits.length,
              ),
              icon: showClosed.value
                  ? HugeIcons.strokeRoundedArrowUp01
                  : HugeIcons.strokeRoundedArrowDown01,
              onPressed: () => showClosed.value = !showClosed.value,
            ),
          ),
          if (showClosed.value)
            Opacity(
              opacity: AppDimensions.opacityMuted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows(closedDeposits),
              ),
            ),
        ],
        AppSpacings.gapLg,
      ],
    );
  }
}
