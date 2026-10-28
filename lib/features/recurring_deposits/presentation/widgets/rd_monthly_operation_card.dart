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
///
/// One primary action per row, following the sequential ledger:
/// * customer still owes → **Collect**
/// * collected months waiting → **Deposit (N)**
/// * settled → nothing
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
  final VoidCallback onCollect;
  final VoidCallback onDeposit;
  final VoidCallback? onDepositFromPocket;
  final VoidCallback? onUndoLatestDeposit;
  final VoidCallback? onAbsorbFee;

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
    required this.onCollect,
    required this.onDeposit,
    this.onDepositFromPocket,
    this.onUndoLatestDeposit,
    this.onAbsorbFee,
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
          Text(t.recurringDeposits.monthlyOperations.card.collect),
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

    // Nothing has happened yet this month → no indicator bar, just the status pill.
    final isDefaultState = !item.hasPriorArrears &&
        (status == RDInstallmentDisplayStatus.upcoming ||
            status == RDInstallmentDisplayStatus.dueToday);

    final serialAccount = (deposit.serialNo?.isNotEmpty ?? false)
        ? '(${deposit.serialNo}) ${deposit.accountNo ?? t.common.notProvided}'
        : (deposit.accountNo ?? t.common.notProvided);

    final canFrontFromPocket =
        item.canDepositToPo && item.isCustomerPending && onDepositFromPocket != null;
    final canAbsorbFee = inst.absorbableFee > 0 && onAbsorbFee != null;
    final canUndoLatest = item.isLatestDeposited && onUndoLatestDeposit != null;

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
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
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
                if (item.isCustomerPending && item.totalOutstanding > 0)
                  _InfoBadge(
                    icon: HugeIcons.strokeRoundedCoins01,
                    label: card.owes(amount: item.totalOutstanding.toRupeeFormat()),
                    color: item.hasOverdueDebt(now) ? scheme.error : scheme.onSurfaceVariant,
                  ),
                if (item.readyForPoCount > 0)
                  _InfoBadge(
                    icon: HugeIcons.strokeRoundedBuilding03,
                    label: card.ready(count: item.readyForPoCount),
                    color: scheme.primary,
                  ),
                if (item.hasPriorArrears)
                  _InfoBadge(
                    icon: HugeIcons.strokeRoundedAlert02,
                    label: card.arrears(n: item.priorOverdueCount),
                    color: scheme.error,
                    isFilled: true,
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
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          AppSpacings.gapXs,
          RDOperationActionButton(
            item: item,
            evaluationDate: now,
            isBusy: isBusy,
            onCollect: onCollect,
            onDeposit: onDeposit,
          ),
        ],
      ),
      actions: [
        if (canFrontFromPocket)
          EntityAction(
            label: card.depositFromPocket,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedWallet02,
              size: AppDimensions.iconMd,
            ),
            onTap: onDepositFromPocket!,
          ),
        if (canAbsorbFee)
          EntityAction(
            label: card.absorbFee(amount: inst.absorbableFee.toRupeeFormat()),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              size: AppDimensions.iconMd,
            ),
            onTap: onAbsorbFee!,
          ),
        if (canUndoLatest)
          EntityAction(
            label: card.undoLatestDeposit,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowTurnBackward,
              size: AppDimensions.iconMd,
            ),
            isDestructive: true,
            onTap: onUndoLatestDeposit!,
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

/// Small secondary fact next to the status pill ("owes ₹X", "ready: 2", "+2 months arrears").
class _InfoBadge extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final bool isFilled;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = isFilled ? scheme.errorContainer : Colors.transparent;
    final foreground = isFilled ? scheme.onErrorContainer : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
        border: isFilled ? null : Border.all(color: color, width: AppDimensions.borderSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: AppDimensions.iconXs, color: foreground),
          AppSpacings.gapXs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: isFilled ? FontWeight.bold : FontWeight.w500,
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
      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

/// The single primary action for a row. Vocabulary: customer side = "Collect",
/// PO side = "Deposit". Settled rows have no action.
class RDOperationActionButton extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final bool isBusy;
  final VoidCallback onCollect;
  final VoidCallback onDeposit;

  const RDOperationActionButton({
    super.key,
    required this.item,
    required this.evaluationDate,
    this.isBusy = false,
    required this.onCollect,
    required this.onDeposit,
  });

  RDOperationActionSpec? _resolve(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;
    final status = item.displayStatus(evaluationDate);
    final visual = status.visual(scheme);

    if (item.isCustomerPending) {
      final urgent = item.hasOverdueDebt(evaluationDate);
      return (
        label: card.collect,
        icon: HugeIcons.strokeRoundedCoins01,
        background: urgent ? scheme.error : scheme.primary,
        foreground: urgent ? scheme.onError : scheme.onPrimary,
        onPressed: onCollect,
      );
    }
    if (item.readyForPoCount > 0) {
      return (
        label: card.deposit(count: item.readyForPoCount),
        icon: HugeIcons.strokeRoundedBuilding03,
        background: visual.background,
        foreground: visual.foreground,
        onPressed: onDeposit,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = _resolve(context);
    if (spec == null) return const SizedBox.shrink();

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: spec.background,
        foregroundColor: spec.foreground,
        disabledBackgroundColor: spec.background.withValues(
          alpha: AppDimensions.opacityDisabled,
        ),
        disabledForegroundColor: spec.foreground,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSm,
          vertical: AppDimensions.paddingXs,
        ),
        // Primary row action must stay a comfortable tap target.
        minimumSize: const Size(0, AppDimensions.minTapTarget),
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
