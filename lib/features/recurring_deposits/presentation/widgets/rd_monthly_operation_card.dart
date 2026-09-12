import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RDMonthlyOperationCard extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final bool isSelected;
  final bool isSelectionMode;
  final ValueChanged<bool?>? onSelect;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onLogPayment;
  final VoidCallback onDepositToPo;
  final VoidCallback? onAdvanceToPo;
  final VoidCallback? onRevertPo;
  final VoidCallback? onToggleLateFeeWaiver;

  const RDMonthlyOperationCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isSelectionMode,
    this.onSelect,
    required this.onTap,
    this.onLongPress,
    required this.onLogPayment,
    required this.onDepositToPo,
    this.onAdvanceToPo,
    this.onRevertPo,
    this.onToggleLateFeeWaiver,
  });

  static Widget skeleton() {
    final dummy = RecurringDeposit.dummy;
    return EntityListTile(
      leadingIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar03,
        size: AppDimensions.iconMd,
      ),
      title: dummy.accountNo ?? 'Loading Customer...',
      subtitle: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account: 1234567890 • Sl #001'),
          AppSpacings.gapXs,
          Text('Due: 15 Sep 2026'),
        ],
      ),
      trailing: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹1,000'),
          Text('₹1,000 /mo'),
          AppSpacings.gapXs,
          Text('Log Payment'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final card = ops.card;
    final now = DateTime.now();

    final inst = item.installment;
    final deposit = item.deposit;

    final currentMonthStart = DateTime(now.year, now.month);
    final targetMonthStart = DateTime(inst.installmentDate.year, inst.installmentDate.month);
    final isFutureMonth = targetMonthStart.isAfter(currentMonthStart);

    final hasOverdueDebt = !isFutureMonth && item.hasOverdueDebt(now);
    final isCurrentMonthOverdue = !isFutureMonth && item.isOverdue(now) && item.isCustomerPending;
    final hasPriorArrears = !isFutureMonth && item.priorOverdueCount > 0;
    final dynamicLateFee = isFutureMonth ? 0.0 : inst.dynamicLateFeeAt(now);
    final totalDefaultFee = item.totalDefaultFee(now);
    final totalPayable = hasPriorArrears
        ? item.totalOutstandingPayable(now)
        : item.totalPayable(now);
    final hasDivergentPending = item.isCustomerPending &&
        (totalPayable != deposit.installmentAmount || hasPriorArrears || totalDefaultFee > 0);

    // Visual urgency indicator bar along the left edge
    Color? indicatorColor;
    if (hasOverdueDebt) {
      indicatorColor = theme.colorScheme.error;
    } else if (item.isPoAdvanced || item.isFeePending) {
      indicatorColor = theme.colorScheme.tertiary;
    } else if (item.isReadyForPo) {
      indicatorColor = theme.colorScheme.secondary;
    } else if (item.isSettled) {
      indicatorColor = theme.colorScheme.primary;
    }

    final pendingBtnBg = hasPriorArrears
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final pendingBtnFg = hasPriorArrears
        ? theme.colorScheme.onError
        : theme.colorScheme.onPrimary;

    final serialAccount = (deposit.serialNo?.isNotEmpty ?? false)
        ? '(${deposit.serialNo}) ${deposit.accountNo ?? t.common.notProvided}'
        : (deposit.accountNo ?? t.common.notProvided);

    return EntityListTile(
      indicatorColor: indicatorColor,
      isSelected: isSelected,
      leading: isSelectionMode
          ? SizedBox(
              width: AppDimensions.radiusXxl * 2,
              height: AppDimensions.radiusXxl * 2,
              child: Center(
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelect,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          : _buildInstallmentAvatar(context, inst, hasOverdueDebt),
      title: deposit.customerName ?? t.recurringDeposits.depositNotFound,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serialAccount,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacings.gapXs,
            Wrap(
              spacing: AppDimensions.paddingSm,
              runSpacing: AppDimensions.paddingXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDueDateText(context, inst.dueDate, isCurrentMonthOverdue),
                if (hasPriorArrears)
                  _buildPriorOverdueBadge(
                    context,
                    item.priorOverdueCount,
                    item.priorOverdueAmount,
                  ),
                if (dynamicLateFee > 0 && item.isCustomerPending)
                  Text(
                    card.defaultFee(amount: dynamicLateFee.toRupeeFormat()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (item.isPoAdvanced)
                  _buildPoAdvancedBadge(context),
                if (totalDefaultFee > 0 && item.isCustomerPending)
                if (totalDefaultFee > 0 && !inst.isLateFeeWaived)
                  _buildDefaultFeeBadge(context, totalDefaultFee),
                if (inst.isLateFeeWaived && item.isCustomerPending)
                if (inst.isLateFeeWaived)
                  _buildWaivedFeeBadge(context),
                if (inst.customerPaidAmount > 0 && !inst.isInstallmentPaid)
                  Text(
                    '${card.collected}: ${inst.customerPaidAmount.toRupeeFormat()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                deposit.installmentAmount.toRupeeFormat(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 2),
              Text(
                card.monthlySuffix,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (item.isFeePending) ...[
            const SizedBox(height: 2),
            Text(
              '${card.feeDue}: ${totalDefaultFee.toRupeeFormat()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else if (hasDivergentPending) ...[
            const SizedBox(height: 2),
            Text(
              '${card.totalDue}: ${totalPayable.toRupeeFormat()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasOverdueDebt
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          AppSpacings.gapXs,
          if (item.isPoAdvanced)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: AppDimensions.paddingXs,
                ),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onLogPayment,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: AppDimensions.iconXs,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              label: Text(
                card.collectPayment(amount: totalPayable.toRupeeFormat()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (item.isFeePending)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: AppDimensions.paddingXs,
                ),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onLogPayment,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedFlash,
                size: AppDimensions.iconXs,
                color: theme.colorScheme.onErrorContainer,
              ),
              label: Text(
                card.collectFee(amount: totalDefaultFee.toRupeeFormat()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (item.isCustomerPending)
            if (isFutureMonth)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onLogPayment,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCoins01,
                  size: AppDimensions.iconXs,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                label: Text(
                  card.advancePay,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: pendingBtnBg,
                  foregroundColor: pendingBtnFg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onLogPayment,
                icon: HugeIcon(
                  icon: hasPriorArrears
                      ? HugeIcons.strokeRoundedAlertCircle
                      : HugeIcons.strokeRoundedCoins01,
                  size: AppDimensions.iconXs,
                  color: pendingBtnFg,
                ),
                label: Text(
                  hasPriorArrears
                      ? card.payAll(amount: totalPayable.toRupeeFormat())
                      : card.logPayment,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: pendingBtnFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
          else if (item.isReadyForPo)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: AppDimensions.paddingXs,
                ),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onDepositToPo,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedBuilding03,
                size: AppDimensions.iconXs,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              label: Text(
                card.depositToPo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSm,
                vertical: AppDimensions.paddingXs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: AppDimensions.iconXs,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacings.gapXs,
                  Text(
                    t.recurringDeposits.monthlyOperations.kpis.settled,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        if (item.canDepositToPo && onAdvanceToPo != null && !item.isReadyForPo)
          EntityAction(
            label: card.advanceToPo,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedBuilding03,
              size: AppDimensions.iconMd,
            ),
            onTap: onAdvanceToPo!,
          ),
        if (item.isFeePending && onToggleLateFeeWaiver != null)
          EntityAction(
            label: card.forgiveFee,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              size: AppDimensions.iconMd,
            ),
            onTap: onToggleLateFeeWaiver!,
          ),
        if (item.canRevertPo && onRevertPo != null)
          EntityAction(
            label: card.revertPo,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowTurnBackward,
              size: AppDimensions.iconMd,
            ),
            isDestructive: true,
            onTap: onRevertPo!,
          ),
        EntityAction(
          label: card.viewLedger,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedFile01,
            size: AppDimensions.iconMd,
          ),
          onTap: onTap,
        ),
      ],
      onTap: isSelectionMode
          ? () => onSelect?.call(!isSelected)
          : onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildInstallmentAvatar(
    BuildContext context,
    RDInstallment inst,
    bool isOverdue,
  ) {
    final theme = Theme.of(context);
    final Color bgColor;
    final Color fgColor;

    if (item.isSettled) {
      bgColor = theme.colorScheme.primaryContainer;
      fgColor = theme.colorScheme.onPrimaryContainer;
    } else if (item.isPoAdvanced || item.isFeePending) {
      bgColor = theme.colorScheme.tertiaryContainer;
      fgColor = theme.colorScheme.onTertiaryContainer;
    } else if (isOverdue) {
      bgColor = theme.colorScheme.errorContainer;
      fgColor = theme.colorScheme.onErrorContainer;
    } else {
      bgColor = theme.colorScheme.surfaceContainerHighest;
      fgColor = theme.colorScheme.onSurfaceVariant;
    }

    final diffYears = inst.installmentDate.year - item.deposit.startDate.year;
    final diffMonths = inst.installmentDate.month - item.deposit.startDate.month;
    final monthNum = diffYears * 12 + diffMonths + 1;
    final label = monthNum > 0 ? '#$monthNum' : '#1';

    return CircleAvatar(
      radius: AppDimensions.radiusXxl,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      child: item.isSettled
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              size: AppDimensions.iconSm,
              color: fgColor,
            )
          : Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
    );
  }

  Widget _buildDueDateText(
    BuildContext context,
    DateTime dueDate,
    bool isOverdue,
  ) {
    final theme = Theme.of(context);
    final card = t.recurringDeposits.monthlyOperations.card;
    final now = DateTime.now();

    if (isOverdue) {
      final days = now.difference(dueDate).inDays;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            size: AppDimensions.iconXs,
            color: theme.colorScheme.error,
          ),
          AppSpacings.gapXs,
          Text(
            '${card.due(date: dueDate.toCompactFormat())} (${card.overdueDays(days: days < 1 ? 1 : days)})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    final isToday =
        dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
    if (isToday) {
      return Text(
        card.dueToday,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(
      card.due(date: dueDate.toCompactFormat()),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPriorOverdueBadge(
    BuildContext context,
    int count,
    double amount,
  ) {
    final theme = Theme.of(context);
    final card = t.recurringDeposits.monthlyOperations.card;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            size: AppDimensions.iconXs,
            color: theme.colorScheme.onErrorContainer,
          ),
          AppSpacings.gapXs,
          Text(
            card.pastDueBadge(count: count, amount: amount.toRupeeFormat()),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultFeeBadge(
    BuildContext context,
    double fee,
  ) {
    final theme = Theme.of(context);
    final card = t.recurringDeposits.monthlyOperations.card;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: AppDimensions.iconXs,
            color: theme.colorScheme.error,
          ),
          AppSpacings.gapXs,
          Text(
            card.defaultFeeBadge(amount: fee.toRupeeFormat()),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaivedFeeBadge(BuildContext context) {
    final theme = Theme.of(context);
    final card = t.recurringDeposits.monthlyOperations.card;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
      ),
      child: Text(
        card.feeWaived,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPoAdvancedBadge(BuildContext context) {
    final theme = Theme.of(context);
    final card = t.recurringDeposits.monthlyOperations.card;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedBuilding03,
            size: AppDimensions.iconXs,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          AppSpacings.gapXs,
          Text(
            card.advancedToPo,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
