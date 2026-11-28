import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/core/widgets/domain/nominees_detail_section.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/core/widgets/domain/wealth_accumulation_grid.dart';
import 'package:postfolio/core/widgets/domain/income_generation_grid.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

class OneTimeDepositDetailScreen extends ConsumerWidget {
  final String depositId;

  /// Where the row that opened the screen is, when a row did (`EntityHero.tagFrom`).
  final String? openedFrom;

  const OneTimeDepositDetailScreen({
    super.key,
    required this.depositId,
    this.openedFrom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDateProvider);
    final record = ref.watch(oneTimeDepositByIdProvider(depositId));

    return AsyncSingleEntityBuilder<OneTimeDeposit>(
      state: record,
      // Opened from a row, the screen has the list's record of the deposit at once. It
      // lacks only the nominees, so nothing here is a placeholder meanwhile: their section
      // arrives with the full record.
      seed: ref.watch(oneTimeDepositInListProvider(depositId)),
      notFoundMessage: t.oneTimeDeposits.depositNotFound,
      onRetry: () => ref.invalidate(oneTimeDepositByIdProvider(depositId)),
      dummyEntity: OneTimeDeposit.dummy,
      builder: (deposit) {
        // The list's record or the full one. The placeholder of a cold start is neither.
        final isKnown = deposit.id == depositId;
        // The avatar, the customer's name, the account number and the amount travel here
        // from the row.
        final heroTag = isKnown
            ? EntityHero.tagFrom(openedFrom, depositId)
            : null;
        final accountNo = deposit.accountNo ?? t.common.notProvided;
        final customerName = (deposit.customerName?.isNotEmpty ?? false)
            ? deposit.customerName!
            : ref.watch(customerByIdProvider(deposit.customerId)).value?.name;
        final supporting = Theme.of(context).colorScheme.onSurfaceVariant;

        return EntityDetailScaffold(
          appBarTitle: t.common.depositDetails,
          onRefresh: () =>
              ref.refresh(oneTimeDepositByIdProvider(depositId).future),
          // In the menu, with its label, as on the deposit's row in the list. It was a bare
          // seal icon in the app bar.
          menuActions: [
            EntityAction(
              icon: HugeIcon(
                icon: deposit.status == DepositStatus.active
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedArrowTurnBackward,
                size: AppDimensions.iconSm,
              ),
              label: deposit.status == DepositStatus.active
                  ? t.common.closeDeposit
                  : t.common.reopenDeposit,
              onTap: () async {
                final isActive = deposit.status == DepositStatus.active;
                final confirmed = await AppDialogs.confirmAction(
                  context,
                  title: isActive
                      ? t.common.closeDeposit
                      : t.common.reopenDeposit,
                  content: isActive
                      ? t.oneTimeDeposits.closeDepositConfirmation
                      : t.oneTimeDeposits.reopenDepositConfirmation,
                  confirmText: isActive ? t.common.close : t.common.reopen,
                );
                if (confirmed == true && context.mounted) {
                  final newStatus = isActive
                      ? DepositStatus.closed
                      : DepositStatus.active;
                  final result = await ref
                      .read(oneTimeDepositsControllerProvider.notifier)
                      .toggleDepositStatus(
                        depositId,
                        newStatus,
                        deposit: deposit,
                      );

                  if (result is Failure && context.mounted) {
                    AppFeedback.showError(
                      context,
                      (result as Failure).error.toString(),
                    );
                  }
                }
              },
            ),
          ],
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
            heroTag: heroTag,
            avatarText: deposit.schemeType.shortName,
            avatarSubtext: deposit.schemeTermLabel,
            avatarShape: deposit.schemeType.avatarShape,
            // Headed as its row in the list is: whose deposit it is, then which. A deposit
            // without a named customer is titled by its number there too.
            title: customerName ?? accountNo,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // An account number broken across two lines reads as two numbers.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: EntityHero(
                    tag: heroTag,
                    part: EntityHeroPart.subtitle,
                    child: Text(
                      accountNo,
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: supporting),
                    ),
                  ),
                ),
                Text(
                  deposit.schemeType.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: supporting),
                ),
                // The date the screen is most often opened for; it was only in the
                // Timeline group, half a screen down.
                _MaturityLine(deposit: deposit, now: today),
              ],
            ),
            badge: StatusBadge(
              status: deposit.status.displayName,
              depositStatus: deposit.status,
              urgency: deposit.maturityUrgencyAt(today),
              relativeTimeText: deposit.maturityRelativeTimeAt(today),
            ),
          ),
          body: [
            switch (deposit.projection) {
              WealthAccumulation(
                :final totalInvested,
                :final maturityAmount,
                :final totalInterestEarned,
                :final note,
              ) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (note != null && note.isNotEmpty)
                      KvpMultiplierBanner(doublesInText: note),
                    WealthAccumulationGrid(
                      totalInvested: totalInvested,
                      projectedInterest: totalInterestEarned,
                      maturityAmount: maturityAmount,
                      investedHeroTag: heroTag,
                    ),
                  ],
                ),
              IncomeGeneration(
                :final totalInterestEarned,
                :final payoutFrequency,
                :final periodicPayoutAmount,
              ) =>
                IncomeGenerationGrid(
                  principal: deposit.principalAmount,
                  periodicPayout: periodicPayoutAmount,
                  payoutFrequency: payoutFrequency.displayName,
                  totalInterestEarned: totalInterestEarned,
                  principalHeroTag: heroTag,
                ),
            },
            // 16dp, the gap between any two blocks of a detail screen; the figures were
            // followed by 32dp.
            AppSpacings.gapLg,
            DetailSection(
              title: t.oneTimeDeposits.sections.investmentDetails,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.oneTimeDeposits.fields.termYears,
                  value: t.recurringDeposits.fields.termDisplay(
                    years: deposit.termYears.toString(),
                    months: deposit.termMonths.toString(),
                  ),
                ),
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
                if (deposit.accountNo != null &&
                    deposit.accountNo!.isNotEmpty) ...[
                  DetailItem(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedTicket01,
                      size: AppDimensions.iconMd,
                    ),
                    label: t.oneTimeDeposits.fields.accountNo,
                    value: deposit.accountNo,
                    copyValue: deposit.accountNo,
                  ),
                ],
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.oneTimeDeposits.fields.customerId,
                  value: (deposit.customerName?.isNotEmpty ?? false)
                      ? deposit.customerName!
                      : (ref
                                .watch(customerByIdProvider(deposit.customerId))
                                .value
                                ?.name ??
                            deposit.customerId),
                  onTap: () =>
                      CustomerDetailRoute(deposit.customerId).push(context),
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

/// "Matures 10 May 2029", in the colour the list uses for a deposit that is close to
/// maturity or past it.
class _MaturityLine extends StatelessWidget {
  final OneTimeDeposit deposit;
  final DateTime now;

  const _MaturityLine({required this.deposit, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final financial = AppFinancialColors.of(context);
    final isActive = deposit.status == DepositStatus.active;
    final urgency = deposit.maturityUrgencyAt(now);
    final date = deposit.maturityDate.toAppFormat();

    final color = switch (urgency) {
      MaturityUrgency.matured when isActive => financial.overdue.onContainer,
      MaturityUrgency.maturingSoon when isActive =>
        financial.warning.onContainer,
      _ => scheme.onSurfaceVariant,
    };
    return Text(
      urgency == MaturityUrgency.matured
          ? t.common.maturedOn(date: date)
          : t.common.maturesOn(date: date),
      style: AppTypography.emphasizedOf(
        context,
      ).bodyMedium?.copyWith(color: color),
    );
  }
}
