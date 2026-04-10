import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/nominees_detail_section.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositDetailScreen extends ConsumerWidget {
  final String depositId;

  const OneTimeDepositDetailScreen({super.key, required this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AsyncEntityBuilder<OneTimeDeposit>(
      state: ref.watch(oneTimeDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.oneTimeDeposits.depositNotFound,
      onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
      builder: (deposit) {
        return EntityDetailScaffold(
          appBarTitle: "Deposit Details",
          onEdit: () => OneTimeDepositEditRoute(depositId).push(context),
          deleteDialogTitle: t.oneTimeDeposits.deleteDeposit,
          deleteDialogContent: t.oneTimeDeposits.deleteDepositConfirmation,
          onDelete: () async {
            final result = await ref
                .read(oneTimeDepositsControllerProvider.notifier)
                .deleteOneTimeDeposit(depositId);
            return result is Failure ? t.oneTimeDeposits.failedToDeleteDeposit(error: (result as Failure).error.toString()) : null;
          },
          header: EntityDetailHeader(
            avatarChild: const Icon(Icons.account_balance_wallet_outlined, size: AppDimensions.iconLg),
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
                  title: t.oneTimeDeposits.fields.principalAmount,
                  amount: deposit.principalAmount,
                ),
                AppSpacings.gapLg,
                DetailAmountCard(
                  title: t.oneTimeDeposits.fields.maturityAmount,
                  amount: deposit.maturityAmount,
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  textColor: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ],
            ),
            AppSpacings.gapXxl,
            DetailSection(
              title: t.oneTimeDeposits.sections.investmentDetails,
              children: [
                DetailItem(
                  icon: Icons.calendar_today_outlined,
                  label: t.oneTimeDeposits.fields.termYears,
                  value: '${deposit.termYears} Years, ${deposit.termMonths} Months',
                ),
                const Divider(height: 1),
                DetailItem(
                  icon: Icons.percent_outlined,
                  label: t.oneTimeDeposits.fields.interestRate,
                  value: '${deposit.interestRate.toStringAsFixed(2)}%',
                ),
              ],
            ),
            AppSpacings.gapLg,
            DetailSection(
              title: t.oneTimeDeposits.sections.timeline,
              children: [
                DetailItem(
                  icon: Icons.date_range_outlined,
                  label: t.oneTimeDeposits.fields.depositDate,
                  value: dateFormat.format(deposit.startDate),
                ),
                const Divider(height: 1),
                DetailItem(
                  icon: Icons.event_available_outlined,
                  label: t.oneTimeDeposits.fields.maturityDate,
                  value: dateFormat.format(deposit.maturityDate),
                ),
              ],
            ),
            AppSpacings.gapLg,
            DetailSection(
              title: t.oneTimeDeposits.sections.accountInformation,
              children: [
                DetailItem(
                  icon: Icons.account_circle_outlined,
                  label: t.oneTimeDeposits.fields.customerId,
                  value: ref.watch(customersControllerProvider).value?.where((c) => c.id == deposit.customerId).firstOrNull?.name ?? deposit.customerId,
                ),
                if (deposit.linkedSavingsAccountNo != null && deposit.linkedSavingsAccountNo!.isNotEmpty) ...[
                  const Divider(height: 1),
                  DetailItem(
                    icon: Icons.account_balance_outlined,
                    label: t.oneTimeDeposits.fields.linkedSavingsAccount,
                    value: deposit.linkedSavingsAccountNo!,
                  ),
                ],
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
