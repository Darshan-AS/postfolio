import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Everything the primary action button needs, resolved once per row.
typedef RDOperationActionSpec = ({
  String label,
  List<List<dynamic>> icon,
  Color background,
  Color foreground,
  VoidCallback? onPressed,
});

/// One row of the Monthly Hub. Strictly declarative — every colour/label is derived from
/// `item.displayStatus(evaluationDate).visual(scheme)`; every write goes through a callback.
class RDMonthlyOperationCard extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final bool isSelected;
  final bool isSelectionMode;

  /// True while the ledger controller is writing; disables every mutating control.
  final bool isBusy;
  final ValueChanged<bool?>? onSelect;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onLogPayment;
  final VoidCallback onDepositToPo;
  final VoidCallback? onDepositFromPocket;
  final VoidCallback? onRevertPo;
  final VoidCallback? onForgiveFee;

  const RDMonthlyOperationCard({
    super.key,
    required this.item,
    required this.evaluationDate,
    required this.isSelected,
    required this.isSelectionMode,
    this.isBusy = false,
    this.onSelect,
    required this.onTap,
    this.onLongPress,
    required this.onLogPayment,
    required this.onDepositToPo,
    this.onDepositFromPocket,
    this.onRevertPo,
    this.onForgiveFee,
  });

  static Widget skeleton() {
    final dummy = RecurringDeposit.dummy;
    return EntityListTile(
      leadingIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar03,
        size: AppDimensions.iconMd,
      ),
      title: dummy.customerName ?? BoneMock.name,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(BoneMock.words(3)),
          AppSpacings.gapXs,
          Text(BoneMock.date),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dummy.installmentAmount.toRupeeFormat()),
          Text(BoneMock.words(2)),
          AppSpacings.gapXs,
          Text(t.recurringDeposits.monthlyOperations.card.logPayment),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;
    final now = evaluationDate;

    final inst = item.installment;
    final deposit = item.deposit;
    final status = item.displayStatus(now);
    final visual = status.visual(scheme);

    final hasOverdueDebt = item.hasOverdueDebt(now);
    final hasPriorArrears = item.hasPriorArrears(now);
    final totalDefaultFee = item.totalDefaultFee(now);
    final totalPayable = item.effectiveTotalPayable(now);
    final hasDivergentPending = item.hasDivergentPending(now);

    // Nothing has happened yet this month → no pipeline pill, just the status pill.
    final isDefaultState = !hasPriorArrears &&
        (status == RDInstallmentDisplayStatus.upcoming ||
            status == RDInstallmentDisplayStatus.dueToday);

    final serialAccount = (deposit.serialNo?.isNotEmpty ?? false)
        ? '(${deposit.serialNo}) ${deposit.accountNo ?? t.common.notProvided}'
        : (deposit.accountNo ?? t.common.notProvided);

    return EntityListTile(
      indicatorColor: isDefaultState ? null : visual.background,
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
          : _InstallmentAvatar(
              installmentNumber: item.installmentNumber,
              status: status,
              visual: visual,
            ),
      title: deposit.customerName ?? t.recurringDeposits.depositNotFound,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppDimensions.paddingXs,
              runSpacing: AppDimensions.paddingXxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  serialAccount,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  t.format.bulletSeparator.trim(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
                _DueDateText(installment: inst, status: status, now: now),
              ],
            ),
            AppSpacings.gapXs,
            Wrap(
              spacing: AppDimensions.paddingXs,
              runSpacing: AppDimensions.paddingXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusPill(visual: visual),
                if (!isDefaultState)
                  RDCheckpointsRow(
                    item: item,
                    evaluationDate: now,
                    status: status,
                  ),
                if (hasPriorArrears)
                  _PriorOverdueBadge(
                    count: item.priorOverdueCount,
                    amount: item.priorOverdueAmount,
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
                  color: scheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapXxs,
              Text(
                card.monthlySuffix,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (item.isFeePending) ...[
            AppSpacings.gapXxs,
            Text(
              '${card.feeDue}: ${totalDefaultFee.toRupeeFormat()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else if (hasDivergentPending) ...[
            AppSpacings.gapXxs,
            Text(
              '${card.totalDue}: ${totalPayable.toRupeeFormat()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasOverdueDebt ? scheme.error : scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          AppSpacings.gapXs,
          RDOperationActionButton(
            item: item,
            evaluationDate: now,
            isBusy: isBusy,
            onLogPayment: onLogPayment,
            onDepositToPo: onDepositToPo,
          ),
        ],
      ),
      actions: [
        if (item.canDepositToPo && onDepositFromPocket != null && !item.isReadyForPo)
          EntityAction(
            label: card.advanceToPo,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedWallet02,
              size: AppDimensions.iconMd,
            ),
            onTap: onDepositFromPocket!,
          ),
        if (item.isFeePending && onForgiveFee != null)
          EntityAction(
            label: card.forgiveFee,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              size: AppDimensions.iconMd,
            ),
            onTap: onForgiveFee!,
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
      onTap: isSelectionMode ? () => onSelect?.call(!isSelected) : onTap,
      onLongPress: onLongPress,
    );
  }
}

class _InstallmentAvatar extends StatelessWidget {
  final int installmentNumber;
  final RDInstallmentDisplayStatus status;
  final RDStatusVisual visual;

  const _InstallmentAvatar({
    required this.installmentNumber,
    required this.status,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showIcon = status == RDInstallmentDisplayStatus.settled ||
        status == RDInstallmentDisplayStatus.baseline;

    return CircleAvatar(
      radius: AppDimensions.radiusXxl,
      backgroundColor: visual.background,
      foregroundColor: visual.foreground,
      child: showIcon
          ? HugeIcon(
              icon: visual.icon,
              size: AppDimensions.iconSm,
              color: visual.foreground,
            )
          : Text(
              '${t.format.countSymbol}$installmentNumber',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: visual.foreground,
              ),
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RDStatusVisual visual;

  const _StatusPill({required this.visual});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
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
            visual.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: visual.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDateText extends StatelessWidget {
  final RDInstallment installment;
  final RDInstallmentDisplayStatus status;
  final DateTime now;

  const _DueDateText({
    required this.installment,
    required this.status,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = t.recurringDeposits.monthlyOperations.card;
    final dueDate = installment.dueDate;

    if (status == RDInstallmentDisplayStatus.overdue) {
      final days = installment.overdueDaysAt(now);
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

    if (installment.isDueOn(now)) {
      return Text(
        card.dueToday,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final daysUntil = installment.daysUntilDueAt(now);
    final label = (status == RDInstallmentDisplayStatus.upcoming && daysUntil > 0)
        ? '${card.due(date: dueDate.toCompactFormat())} (${card.dueInDays(days: daysUntil)})'
        : card.due(date: dueDate.toCompactFormat());

    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PriorOverdueBadge extends StatelessWidget {
  final int count;
  final double amount;

  const _PriorOverdueBadge({required this.count, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = t.recurringDeposits.monthlyOperations.card;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
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
}

/// The single primary action for a row. Vocabulary: customer side = "Collect",
/// PO side = "Deposit", agent-funded = "From pocket".
class RDOperationActionButton extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final bool isBusy;
  final VoidCallback onLogPayment;
  final VoidCallback onDepositToPo;

  const RDOperationActionButton({
    super.key,
    required this.item,
    required this.evaluationDate,
    this.isBusy = false,
    required this.onLogPayment,
    required this.onDepositToPo,
  });

  RDOperationActionSpec _resolve(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;
    final status = item.displayStatus(evaluationDate);
    final visual = status.visual(scheme);
    final hasPriorArrears = item.hasPriorArrears(evaluationDate);
    final totalPayable = item.effectiveTotalPayable(evaluationDate);
    final totalDefaultFee = item.totalDefaultFee(evaluationDate);

    return switch (status) {
      RDInstallmentDisplayStatus.pocketAdvanced => (
          label: card.collectPayment(amount: totalPayable.toRupeeFormat()),
          icon: HugeIcons.strokeRoundedCoins01,
          background: visual.background,
          foreground: visual.foreground,
          onPressed: onLogPayment,
        ),
      RDInstallmentDisplayStatus.feePending => (
          label: card.collectFee(amount: totalDefaultFee.toRupeeFormat()),
          icon: HugeIcons.strokeRoundedFlash,
          background: visual.background,
          foreground: visual.foreground,
          onPressed: onLogPayment,
        ),
      RDInstallmentDisplayStatus.upcoming when item.isUpcoming(evaluationDate) => (
          label: card.advancePay,
          icon: HugeIcons.strokeRoundedCoins01,
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          onPressed: onLogPayment,
        ),
      RDInstallmentDisplayStatus.upcoming ||
      RDInstallmentDisplayStatus.dueToday ||
      RDInstallmentDisplayStatus.partiallyPaid ||
      RDInstallmentDisplayStatus.overdue =>
        hasPriorArrears
            ? (
                label: card.payAll(amount: totalPayable.toRupeeFormat()),
                icon: HugeIcons.strokeRoundedAlertCircle,
                background: scheme.error,
                foreground: scheme.onError,
                onPressed: onLogPayment,
              )
            : (
                label: card.logPayment,
                icon: HugeIcons.strokeRoundedCoins01,
                background: scheme.primary,
                foreground: scheme.onPrimary,
                onPressed: onLogPayment,
              ),
      RDInstallmentDisplayStatus.collectedPendingPo => (
          label: card.depositToPo,
          icon: HugeIcons.strokeRoundedBuilding03,
          background: visual.background,
          foreground: visual.foreground,
          onPressed: onDepositToPo,
        ),
      RDInstallmentDisplayStatus.settled ||
      RDInstallmentDisplayStatus.baseline =>
        (
          label: visual.label,
          icon: visual.icon,
          background: visual.background,
          foreground: visual.foreground,
          onPressed: null,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = _resolve(context);

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: spec.background,
        foregroundColor: spec.foreground,
        disabledBackgroundColor: spec.background,
        disabledForegroundColor: spec.foreground,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSm,
          vertical: AppDimensions.paddingXs,
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: isBusy ? null : spec.onPressed,
      icon: HugeIcon(
        icon: spec.icon,
        size: AppDimensions.iconXs,
        color: spec.foreground,
      ),
      label: Text(
        spec.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: spec.foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// `Customer → PO` pipeline pills plus an optional fee pill. Only shown once something has
/// happened for the month (the caller hides it in the default upcoming/due-today state).
class RDCheckpointsRow extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final RDInstallmentDisplayStatus status;

  const RDCheckpointsRow({
    super.key,
    required this.item,
    required this.evaluationDate,
    required this.status,
  });

  bool get _isCustomerOverdue =>
      status == RDInstallmentDisplayStatus.overdue || item.hasOverdueDebt(evaluationDate);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppDimensions.paddingXs,
      runSpacing: AppDimensions.paddingXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCustomerCheckpoint(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXxs),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: AppDimensions.iconXs,
                color: theme.colorScheme.outline,
              ),
            ),
            _buildPoCheckpoint(context),
          ],
        ),
        if (item.hasDefaultFee(evaluationDate)) _buildFeeCheckpoint(context),
      ],
    );
  }

  Widget _buildCustomerCheckpoint(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;
    final inst = item.installment;

    if (inst.isInstallmentPaid) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        label: card.checkpoints.pipelineCust,
        bgColor: scheme.primaryContainer.withValues(alpha: 0.5),
        fgColor: scheme.primary,
      );
    }
    if (inst.isPartiallyPaid) {
      final tone = _isCustomerOverdue ? scheme.error : scheme.primary;
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedCoins01,
        label: card.checkpoints.pipelineCustPartial(
          paid: inst.customerPaidAmount.toRupeeFormat(),
          total: inst.installmentAmount.toRupeeFormat(),
        ),
        bgColor: Colors.transparent,
        fgColor: tone,
        borderColor: tone,
        isOutlined: true,
      );
    }
    if (_isCustomerOverdue) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedAlert02,
        label: card.checkpoints.pipelineCust,
        bgColor: Colors.transparent,
        fgColor: scheme.error,
        borderColor: scheme.error,
        isOutlined: true,
      );
    }
    return _CheckpointBadge(
      icon: HugeIcons.strokeRoundedClock01,
      label: card.checkpoints.pipelineCust,
      bgColor: Colors.transparent,
      fgColor: scheme.onSurfaceVariant.withValues(alpha: 0.8),
      borderColor: scheme.outlineVariant,
      isOutlined: true,
    );
  }

  Widget _buildPoCheckpoint(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;

    if (status == RDInstallmentDisplayStatus.pocketAdvanced) {
      final visual = status.visual(scheme);
      return _CheckpointBadge(
        icon: visual.icon,
        label: card.checkpoints.poAdvanced,
        bgColor: visual.background,
        fgColor: visual.foreground,
      );
    }
    if (item.isPoPaid) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        label: card.checkpoints.pipelinePo,
        bgColor: scheme.primaryContainer.withValues(alpha: 0.5),
        fgColor: scheme.primary,
      );
    }
    if (status == RDInstallmentDisplayStatus.collectedPendingPo) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedBuilding03,
        label: card.checkpoints.pipelinePoReady,
        bgColor: scheme.secondaryContainer.withValues(alpha: 0.7),
        fgColor: scheme.onSecondaryContainer,
      );
    }
    return _CheckpointBadge(
      icon: HugeIcons.strokeRoundedClock01,
      label: card.checkpoints.pipelinePo,
      bgColor: Colors.transparent,
      fgColor: scheme.onSurfaceVariant.withValues(alpha: 0.8),
      borderColor: scheme.outlineVariant,
      isOutlined: true,
    );
  }

  Widget _buildFeeCheckpoint(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;
    final inst = item.installment;
    final totalFee = item.totalDefaultFee(evaluationDate);

    if (inst.isLateFeeWaived) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        label: card.checkpoints.feeWaived,
        bgColor: scheme.surfaceContainerHighest,
        fgColor: scheme.onSurfaceVariant,
      );
    }
    if (totalFee > 0 && inst.paidLateFee > 0) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedAlertCircle,
        label: card.checkpoints.fee(
          paid: inst.paidLateFee.toRupeeFormat(),
          total: (inst.paidLateFee + totalFee).toRupeeFormat(),
        ),
        bgColor: Colors.transparent,
        fgColor: scheme.error,
        borderColor: scheme.error,
        isOutlined: true,
      );
    }
    if (totalFee > 0) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedAlertCircle,
        label: card.checkpoints.feeDue(amount: totalFee.toRupeeFormat()),
        bgColor: Colors.transparent,
        fgColor: scheme.error,
        borderColor: scheme.error,
        isOutlined: true,
      );
    }
    if (inst.paidLateFee > 0) {
      return _CheckpointBadge(
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        label: card.checkpoints.feePaid,
        bgColor: scheme.primaryContainer.withValues(alpha: 0.5),
        fgColor: scheme.primary,
      );
    }
    return const SizedBox.shrink();
  }
}

class _CheckpointBadge extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final bool isOutlined;
  final Color? borderColor;

  const _CheckpointBadge({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    this.isOutlined = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
        border: isOutlined
            ? Border.all(
                color: borderColor ?? theme.colorScheme.outlineVariant,
                width: AppDimensions.borderSm,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: AppDimensions.iconXs, color: fgColor),
          AppSpacings.gapXs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: isOutlined ? FontWeight.w500 : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
