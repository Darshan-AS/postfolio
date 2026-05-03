import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/nominees_detail_section.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

class OneTimeDepositDetailScreen extends ConsumerWidget {
  final String depositId;

  const OneTimeDepositDetailScreen({super.key, required this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<OneTimeDeposit>(
      state: ref.watch(oneTimeDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.oneTimeDeposits.depositNotFound,
      onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
      dummyEntity: OneTimeDeposit.dummy,
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
            return result is Failure
                ? t.oneTimeDeposits.failedToDeleteDeposit(
                    error: (result as Failure).error.toString(),
                  )
                : null;
          },
          header: EntityDetailHeader(
            avatarChild: const HugeIcon(
              icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
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
            deposit.projection.when(
              wealthAccumulation: (
                totalInvested,
                maturityAmount,
                totalInterestEarned,
                _,
                note,
              ) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (note != null && note.isNotEmpty)
                    KvpMultiplierBanner(doublesInText: note),
                  WealthAccumulationGrid(
                    totalInvested: totalInvested,
                    projectedInterest: totalInterestEarned,
                    maturityAmount: maturityAmount,
                  ),
                ],
              ),
              incomeGeneration: (
                totalInvested,
                _,
                totalInterestEarned,
                _,
                _,
                payoutFrequency,
                _,
              ) => IncomeGenerationGrid(
                principal: deposit.principalAmount,
                periodicPayout: deposit.projection.whenOrNull(
                      incomeGeneration: (
                        _,
                        _,
                        _,
                        _,
                        periodicPayoutAmount,
                        _,
                        _,
                      ) => periodicPayoutAmount,
                    ) ??
                    0,
                payoutFrequency: payoutFrequency.displayName,
                totalInterestEarned: totalInterestEarned,
              ),
            ),
            AppSpacings.gapXxl,
            DetailSection(
              title: t.oneTimeDeposits.sections.investmentDetails,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.oneTimeDeposits.fields.termYears,
                  value:
                      '${deposit.termYears} Years, ${deposit.termMonths} Months',
                ),
                const Divider(height: 1),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPercent,
                    size: AppDimensions.iconMd,
                  ),
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
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar02,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.oneTimeDeposits.fields.depositDate,
                  value: deposit.startDate.toAppFormat(),
                ),
                const Divider(height: 1),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.oneTimeDeposits.fields.maturityDate,
                  value: deposit.maturityDate.toAppFormat(),
                ),
              ],
            ),
            AppSpacings.gapLg,
            DetailSection(
              title: t.oneTimeDeposits.sections.accountInformation,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.oneTimeDeposits.fields.customerId,
                  value:
                      ref
                          .watch(customersControllerProvider)
                          .value
                          ?.where((c) => c.id == deposit.customerId)
                          .firstOrNull
                          ?.name ??
                      deposit.customerId,
                ),
                if (deposit.linkedSavingsAccountNo != null &&
                    deposit.linkedSavingsAccountNo!.isNotEmpty) ...[
                  const Divider(height: 1),
                  DetailItem(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedBank,
                      size: AppDimensions.iconMd,
                    ),
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
