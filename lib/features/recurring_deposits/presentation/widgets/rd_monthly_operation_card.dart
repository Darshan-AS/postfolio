import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
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

/// The money a row should headline, resolved once per row.
typedef _RowMoney = ({String headline, Color color, List<String> captionParts});

/// Last digits of the account number shown on a row (`A/c …7890`).
const int _accountTailLength = 4;

/// Day + short month, e.g. "15 Mar" (the hub already says which year).
const String _dueDatePattern = 'd MMM';

/// One row of the Monthly Hub. Strictly declarative — every colour/label is derived from
/// `item.displayStatus(evaluationDate).visual(scheme)`; every write goes through a callback.
///
/// Hierarchy (top → bottom): customer **name** · `Sl · A/c · due` · status pill with the
/// money that matters on its right (`owes ₹X` / `₹X paid` / `collected ₹X`) · one
/// full-width primary action:
/// * customer still owes → **Collect ₹X**
/// * collected months waiting → **Deposit N**
/// * settled → nothing
class RDMonthlyOperationCard extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final bool isSelected;
  final bool isSelectionMode;

  /// True while the ledger controller is writing; disables every mutating control.
  final bool isBusy;
  final ValueChanged<bool?>? onSelect;

  /// Screen-reader label for the selection checkbox (e.g. "Select Ramesh").
  final String? selectSemanticLabel;
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
    this.selectSemanticLabel,
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
    final card = t.recurringDeposits.monthlyOperations.card;
    return EntityListTile(
      leadingIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar03,
        size: AppDimensions.iconMd,
      ),
      title: dummy.customerName ?? BoneMock.name,
      subtitle: Text(BoneMock.words(4)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(BoneMock.words(2)),
              const Spacer(),
              Text(card.owes(amount: dummy.installmentAmount.toRupeeFormat())),
            ],
          ),
          AppSpacings.gapSm,
          FilledButton(
            onPressed: null,
            child: Text(
              card.collect(amount: dummy.installmentAmount.toRupeeFormat()),
            ),
          ),
        ],
      ),
    );
  }

  _RowMoney? _money(ColorScheme scheme) {
    final card = t.recurringDeposits.monthlyOperations.card;
    final now = evaluationDate;
    if (item.isCustomerPending && item.totalOutstanding > 0) {
      return (
        headline: card.owes(amount: item.totalOutstanding.toRupeeFormat()),
        color: item.hasOverdueDebt(now) ? scheme.error : scheme.onSurface,
        captionParts: [
          if (item.totalFeeDue > 0)
            card.inclFee(amount: item.totalFeeDue.toRupeeFormat()),
          if (item.hasPriorArrears) card.arrears(n: item.priorOverdueCount),
        ],
      );
    }
    if (item.isSettled) {
      return (
        headline: card.paid(
          amount: item.installment.customerPaidAmount.toRupeeFormat(),
        ),
        color: scheme.onSurfaceVariant,
        captionParts: const [],
      );
    }
    if (item.readyForPoCount > 0) {
      return (
        headline: card.collected(
          amount: item.summary.cashInHand.toRupeeFormat(),
        ),
        color: scheme.onSurface,
        captionParts: const [],
      );
    }
    return null;
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
    final money = _money(scheme);

    // Nothing has happened yet this month → no indicator bar, just the status pill.
    final isDefaultState =
        !item.hasPriorArrears &&
        (status == RDInstallmentDisplayStatus.upcoming ||
            status == RDInstallmentDisplayStatus.dueToday);

    final canFrontFromPocket =
        item.canDepositToPo &&
        item.isCustomerPending &&
        onDepositFromPocket != null;
    final canAbsorbFee = inst.absorbableFee > 0 && onAbsorbFee != null;
    final canUndoLatest = item.isLatestDeposited && onUndoLatestDeposit != null;

    final caption = money == null || money.captionParts.isEmpty
        ? null
        : money.captionParts.join(t.format.bulletSeparator);

    final action = RDOperationActionButton(
      item: item,
      evaluationDate: now,
      isBusy: isBusy,
      onCollect: onCollect,
      onDeposit: onDeposit,
    );
    final hasAction = action.resolve(context) != null;

    return EntityListTile(
      indicatorColor: isDefaultState ? null : status.accent(scheme),
      isSelected: isSelected,
      leading: isSelectionMode
          ? SizedBox(
              width: AppDimensions.radiusXxl * 2,
              height: AppDimensions.radiusXxl * 2,
              child: Center(
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelect,
                  semanticLabel: selectSemanticLabel,
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
        padding: const EdgeInsets.only(top: AppDimensions.paddingXxs),
        child: _IdentityLine(
          deposit: deposit,
          installment: inst,
          status: status,
          now: now,
        ),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status on the left; the money that matters on the right (never ellipsised —
          // it shrinks), with its caption underneath.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusPill(visual: visual),
              AppSpacings.gapSm,
              Expanded(
                child: money == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              money.headline,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: money.color,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (caption != null)
                            Text(
                              caption,
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: item.hasOverdueDebt(now)
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
          if (hasAction) ...[AppSpacings.gapSm, action],
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
    final showIcon =
        status == RDInstallmentDisplayStatus.settled ||
        status == RDInstallmentDisplayStatus.baseline;

    return Container(
      width: AppDimensions.radiusXxl * 2,
      height: AppDimensions.radiusXxl * 2,
      decoration: BoxDecoration(
        color: visual.background,
        shape: BoxShape.circle,
        border: visual.outline == null
            ? null
            : Border.all(color: visual.outline!, width: AppDimensions.borderSm),
      ),
      alignment: Alignment.center,
      child: showIcon
          ? HugeIcon(
              icon: visual.icon,
              size: AppDimensions.iconSm,
              color: visual.foreground,
            )
          : Text(
              t.recurringDeposits.monthlyOperations.card.monthNo(n: installmentNumber.toString()),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: visual.foreground,
              ),
            ),
    );
  }
}

/// `Sl 12 · A/c …7890 · due 15 Mar` on one line; only the account may be ellipsised.
class _IdentityLine extends StatelessWidget {
  final RecurringDeposit deposit;
  final RDInstallment installment;
  final RDInstallmentDisplayStatus status;
  final DateTime now;

  const _IdentityLine({
    required this.deposit,
    required this.installment,
    required this.status,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;
    final separator = t.format.bulletSeparator;

    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final accountNo = deposit.accountNo ?? '';
    final last4 = accountNo.length > _accountTailLength
        ? accountNo.substring(accountNo.length - _accountTailLength)
        : (accountNo.isEmpty ? t.common.notProvided : accountNo);
    final serial = (deposit.serialNo?.isNotEmpty ?? false)
        ? card.serial(serialNo: deposit.serialNo!)
        : null;

    final (dueText, dueStyle) = _dueText(theme);

    // Serial + account share one flexible span so, when space runs out, the ellipsis eats the
    // account tail first; the due date is never cut.
    final account = card.accountTail(last4: last4);
    final identity = serial == null ? account : card.identity(serial: serial, account: account);

    return Row(
      children: [
        Flexible(
          child: Text(
            identity,
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(separator, style: muted, maxLines: 1),
        Text(dueText, style: dueStyle, maxLines: 1),
      ],
    );
  }

  (String, TextStyle?) _dueText(ThemeData theme) {
    final card = t.recurringDeposits.monthlyOperations.card;
    final locale = LocaleSettings.currentLocale.languageTag;
    final due = card.due(
      date: DateFormat(_dueDatePattern, locale).format(installment.dueDate),
    );
    final alert = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.error,
      fontWeight: FontWeight.bold,
    );

    if (status == RDInstallmentDisplayStatus.overdue) {
      final days = installment.overdueDaysAt(now);
      return (
        card.dueOverdue(due: due, late: card.overdueDays(days: days < 1 ? 1 : days)),
        alert,
      );
    }
    if (installment.isDueOn(now) && status.isCustomerPending) {
      return (
        card.dueToday,
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return (
      due,
      theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
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
        border: visual.outline == null
            ? null
            : Border.all(color: visual.outline!, width: AppDimensions.borderSm),
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
              fontWeight: visual.emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The single primary action for a row. Vocabulary: customer side = "Collect ₹X",
/// PO side = "Deposit N". Settled rows have no action.
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

  RDOperationActionSpec? resolve(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = t.recurringDeposits.monthlyOperations.card;
    final status = item.displayStatus(evaluationDate);
    final visual = status.visual(scheme);

    if (item.isCustomerPending) {
      final urgent = item.hasOverdueDebt(evaluationDate);
      return (
        label: card.collect(amount: item.totalOutstanding.toRupeeFormat()),
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
    final spec = resolve(context);
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
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingXs,
        ),
        // Primary row action must stay a comfortable tap target.
        minimumSize: const Size(double.infinity, AppDimensions.minTapTarget),
      ),
      onPressed: isBusy ? null : spec.onPressed,
      icon: HugeIcon(
        icon: spec.icon,
        size: AppDimensions.iconSm,
        color: spec.foreground,
      ),
      label: Text(
        spec.label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: spec.foreground,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
