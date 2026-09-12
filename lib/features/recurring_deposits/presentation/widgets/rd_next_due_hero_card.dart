import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RDNextDueHeroCard extends StatelessWidget {
  final RecurringDeposit deposit;
  final List<RDInstallment> installments;

  const RDNextDueHeroCard({
    super.key,
    required this.deposit,
    required this.installments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = t.recurringDeposits.ledger.hero;
    final now = DateTime.now();

    // Find earliest unpaid or fee-pending installment
    final nextDueIndex = installments.indexWhere(
      (inst) =>
          !inst.isInstallmentPaid ||
          (!inst.isLateFeeWaived && inst.outstandingLateFeeAt(now) > 0),
    );

    // Case 1: All installments are fully settled
    if (nextDueIndex == -1) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                  size: AppDimensions.iconLg,
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSpacings.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.allSettled,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    AppSpacings.gapXs,
                    Text(
                      hero.allSettledSubtitle(
                        total: deposit.totalMonths.toString(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Case 2: There is a next due installment
    final inst = installments[nextDueIndex];
    final monthNum = nextDueIndex + 1;
    final isOverdue = inst.isOverdueAt(now);
    final dueDate = inst.dueDate;
    final principalOwed = inst.outstandingPrincipal;
    final lateFeeOwed =
        inst.isLateFeeWaived ? 0.0 : inst.outstandingLateFeeAt(now);
    final totalPayable = principalOwed + lateFeeOwed;

    final borderColor = isOverdue
        ? theme.colorScheme.error.withValues(alpha: 0.5)
        : theme.colorScheme.outlineVariant;
    final backgroundColor = isOverdue
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    final statusColor =
        isOverdue ? theme.colorScheme.error : theme.colorScheme.primary;

    // Urgency text
    final String urgencyLabel;
    final Color urgencyBg;
    final Color urgencyFg;

    if (isOverdue) {
      final days = now.difference(dueDate).inDays;
      urgencyLabel = hero.overdueDays(days: days > 0 ? days.toString() : '1');
      urgencyBg = theme.colorScheme.errorContainer;
      urgencyFg = theme.colorScheme.onErrorContainer;
    } else {
      final days = dueDate.difference(now).inDays;
      if (days == 0) {
        urgencyLabel = hero.dueToday;
        urgencyBg = theme.colorScheme.primaryContainer;
        urgencyFg = theme.colorScheme.onPrimaryContainer;
      } else {
        urgencyLabel = hero.dueInDays(days: days.toString());
        urgencyBg = theme.colorScheme.surfaceContainerHighest;
        urgencyFg = theme.colorScheme.onSurfaceVariant;
      }
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Title & Urgency Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: isOverdue
                            ? HugeIcons.strokeRoundedAlert01
                            : HugeIcons.strokeRoundedCalendar03,
                        size: AppDimensions.iconSm,
                        color: statusColor,
                      ),
                      AppSpacings.gapXs,
                      Flexible(
                        child: Text(
                          '${hero.title}: ${t.recurringDeposits.ledger.installmentDetails.month(month: monthNum.toString())}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacings.gapSm,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    urgencyLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: urgencyFg,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacings.gapMd,

            // Amount Display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totalPayable.toRupeeFormat(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                AppSpacings.gapSm,
                Expanded(
                  child: Text(
                    hero.dueOn(date: dueDate.toAppFormat()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            // Financial Breakdown (Only if fee is > 0)
            if (lateFeeOwed > 0) ...[
              AppSpacings.gapXs,
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCoins01,
                    size: AppDimensions.iconXs,
                    color: theme.colorScheme.error,
                  ),
                  AppSpacings.gapXs,
                  Expanded(
                    child: Text(
                      '${hero.installment(amount: principalOwed.toRupeeFormat())}  •  ${hero.defaultFee(amount: lateFeeOwed.toRupeeFormat())}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            AppSpacings.gapMd,

            // Action Button
            FilledButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => RDLogPaymentSheet(
                    deposit: deposit,
                    currentSchedule: installments,
                    initialAmount: totalPayable,
                  ),
                );
              },
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: AppDimensions.iconSm,
              ),
              label: Text(
                hero.logPayment(amount: totalPayable.toRupeeFormat()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

