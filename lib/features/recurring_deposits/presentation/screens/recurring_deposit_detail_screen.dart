import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/nominees_detail_section.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RecurringDepositDetailScreen extends ConsumerWidget {
  final String depositId;

  const RecurringDepositDetailScreen({super.key, required this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AsyncEntityBuilder<RecurringDeposit>(
      state: ref.watch(recurringDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
      dummyEntity: RecurringDeposit.dummy,
      builder: (deposit) {
        return EntityDetailScaffold(
          appBarTitle: "Deposit Details",
          onEdit: () => RecurringDepositEditRoute(depositId).push(context),
          deleteDialogTitle: t.recurringDeposits.deleteDeposit,
          deleteDialogContent: t.recurringDeposits.deleteDepositConfirmation,
          onDelete: () async {
            final result = await ref
                .read(recurringDepositsControllerProvider.notifier)
                .deleteRecurringDeposit(depositId);
            return result is Failure
                ? t.recurringDeposits.failedToDeleteDeposit(
                    error: (result as Failure).error.toString(),
                  )
                : null;
          },
          header: EntityDetailHeader(
            avatarBackgroundColor: Theme.of(
              context,
            ).colorScheme.secondaryContainer,
            avatarForegroundColor: Theme.of(
              context,
            ).colorScheme.onSecondaryContainer,
            avatarChild: const HugeIcon(
              icon: HugeIcons.strokeRoundedTransaction,
              size: AppDimensions.iconLg,
            ),
            title: deposit!.accountNo,
            subtitle: Text(
              deposit.schemeType.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            badge: StatusBadge(status: deposit.status.displayName),
          ),
          body: [
            Row(
              children: [
                DetailAmountCard(
                  title: t.recurringDeposits.fields.installmentAmount,
                  amount: deposit.installmentAmount,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                AppSpacings.gapLg,
                DetailAmountCard(
                  title: t.recurringDeposits.fields.maturityAmount,
                  amount: deposit.maturityAmount,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer,
                  textColor: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ],
            ),
            AppSpacings.gapXxl,
            DetailSection(
              title: t.recurringDeposits.sections.investmentDetails,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.termYears,
                  value:
                      '${deposit.termYears} Years, ${deposit.termMonths} Months',
                ),
                const Divider(height: 1),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPercent,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.interestRate,
                  value: '${deposit.interestRate.toStringAsFixed(2)}%',
                ),
              ],
            ),
            AppSpacings.gapLg,
            DetailSection(
              title: t.recurringDeposits.sections.timeline,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar02,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.startDate,
                  value: dateFormat.format(deposit.startDate),
                ),
                const Divider(height: 1),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.maturityDate,
                  value: dateFormat.format(deposit.maturityDate),
                ),
              ],
            ),
            AppSpacings.gapLg,
            DetailSection(
              title: t.recurringDeposits.sections.accountInformation,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedTag01,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.serialNo,
                  value: deposit.serialNo,
                ),
                const Divider(height: 1),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.customerId,
                  value:
                      ref
                          .watch(customersControllerProvider)
                          .value
                          ?.where((c) => c.id == deposit.customerId)
                          .firstOrNull
                          ?.name ??
                      deposit.customerId,
                ),
              ],
            ),
            AppSpacings.gapLg,
            if (deposit.nominees.isNotEmpty)
              NomineesDetailSection(nominees: deposit.nominees),
          ],
        );
      },
    );
  }
}
