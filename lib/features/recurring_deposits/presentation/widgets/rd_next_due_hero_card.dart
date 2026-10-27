import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// "Next Due" summary at the top of the schedule tab.
///
/// When the inspector is already showing the next-due month ([isCollapsed]) the card
/// shrinks to a one-line summary and the inspector owns the primary "Log Payment" CTA.
class RDNextDueHeroCard extends StatelessWidget {
  final String rdId;
  final RDLedgerProjection projection;
  final DateTime now;
  final bool isCollapsed;
  final bool isBusy;

  const RDNextDueHeroCard({
    super.key,
    required this.rdId,
    required this.projection,
    required this.now,
    required this.isCollapsed,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final nextDue = projection.nextDue;
    if (nextDue == null) {
      return _AllSettledCard(totalMonths: projection.installments.length);
    }
    if (isCollapsed) {
      return _CollapsedHero(installment: nextDue, now: now);
    }
    return _ExpandedHero(
      rdId: rdId,
      installment: nextDue,
      now: now,
      isBusy: isBusy,
    );
  }
}

class _AllSettledCard extends StatelessWidget {
  final int totalMonths;

  const _AllSettledCard({required this.totalMonths});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = t.recurringDeposits.ledger.hero;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: theme.colorScheme.tertiaryContainer,
      child: ListTile(
        leading: HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
          size: AppDimensions.iconLg,
          color: theme.colorScheme.onTertiaryContainer,
        ),
        title: Text(
          hero.allSettled,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onTertiaryContainer,
          ),
        ),
        subtitle: Text(
          hero.allSettledSubtitle(total: totalMonths.toString()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onTertiaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Urgency pill derived from the installment's display status.
class _UrgencyPill extends StatelessWidget {
  final RDInstallment installment;
  final DateTime now;

  const _UrgencyPill({required this.installment, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = t.recurringDeposits.ledger.hero;
    final visual = installment.displayStatusAt(now).visual(theme.colorScheme);

    final String label;
    if (installment.isOverdueAt(now)) {
      final days = installment.overdueDaysAt(now);
      label = hero.overdueDays(days: (days > 0 ? days : 1).toString());
    } else if (installment.isDueOn(now)) {
      label = hero.dueToday;
    } else {
      label = hero.dueInDays(days: installment.daysUntilDueAt(now).toString());
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: visual.icon,
            size: AppDimensions.iconXs,
            color: visual.foreground,
          ),
          AppSpacings.gapXs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: visual.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedHero extends StatelessWidget {
  final RDInstallment installment;
  final DateTime now;

  const _CollapsedHero({required this.installment, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = t.recurringDeposits.ledger.hero;
    final totalPayable = installment.outstandingAmountAt(now);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar03,
              size: AppDimensions.iconSm,
              color: theme.colorScheme.primary,
            ),
            AppSpacings.gapSm,
            Expanded(
              child: Text(
                hero.collapsedSummary(
                  month: installment.installmentNo.toString(),
                  amount: totalPayable.toRupeeFormat(),
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppSpacings.gapSm,
            _UrgencyPill(installment: installment, now: now),
          ],
        ),
      ),
    );
  }
}

class _ExpandedHero extends StatelessWidget {
  final String rdId;
  final RDInstallment installment;
  final DateTime now;
  final bool isBusy;

  const _ExpandedHero({
    required this.rdId,
    required this.installment,
    required this.now,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = t.recurringDeposits.ledger.hero;
    final visual = installment.displayStatusAt(now).visual(theme.colorScheme);
    final principalOwed = installment.outstandingPrincipal;
    final lateFeeOwed = installment.outstandingLateFeeAt(now);
    final totalPayable = installment.outstandingAmountAt(now);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: visual.foreground.withValues(alpha: AppDimensions.opacityDisabled)),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: visual.icon,
                  size: AppDimensions.iconSm,
                  color: visual.foreground,
                ),
                AppSpacings.gapXs,
                Expanded(
                  child: Text(
                    '${hero.title} · ${hero.dueLabel(
                      month: installment.installmentNo.toString(),
                      date: installment.dueDate.toAppFormat(),
                    )}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacings.gapSm,
                _UrgencyPill(installment: installment, now: now),
              ],
            ),
            AppSpacings.gapMd,
            Text(
              totalPayable.toRupeeFormat(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (lateFeeOwed > 0) ...[
              AppSpacings.gapXs,
              Text(
                '${hero.installment(amount: principalOwed.toRupeeFormat())}  •  ${hero.defaultFee(amount: lateFeeOwed.toRupeeFormat())}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            AppSpacings.gapMd,
            FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () => showRDLogPaymentSheet(
                        context,
                        rdId: rdId,
                        initialAmount: totalPayable,
                        initialSplitMode: lateFeeOwed > 0
                            ? PaymentSplitMode.includeFees
                            : PaymentSplitMode.installmentsOnly,
                      ),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: AppDimensions.iconSm,
              ),
              label: Text(hero.logPayment(amount: totalPayable.toRupeeFormat())),
            ),
          ],
        ),
      ),
    );
  }
}
