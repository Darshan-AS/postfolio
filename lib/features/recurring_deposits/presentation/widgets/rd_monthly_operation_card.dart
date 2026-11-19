import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_selection_flip.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_account_identity.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_layout.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_status_pill.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Everything the primary action button needs, resolved once per row.
///
/// The button's colour says how much the action matters, not what state the account is
/// in: the pill and the indicator bar say that. Collecting is the main action whether or
/// not the account is overdue, and a solid red button reads as "this deletes something".
typedef RDOperationActionSpec = ({
  String label,
  AppIconData icon,
  AppButtonVariant variant,
  VoidCallback? onPressed,
});

/// The money a row should headline, resolved once per row.
typedef _RowMoney = ({String headline, Color color, List<String> captionParts});

/// Last digits of the account number shown on a row (`A/c …7890`).

/// Day + short month, e.g. "15 Mar" (the hub already says which year).
const String _dueDatePattern = 'd MMM';

/// The most of a row's width the status pill may take; the rest belongs to the money.
const double _pillMaxWidthFraction = 0.55;

/// One row of the Monthly Hub. Strictly declarative — every colour/label is derived from
/// `item.displayStatus(evaluationDate).visual(scheme)`; every write goes through a callback.
///
/// Hierarchy (top → bottom): a status-shaped avatar and the customer **name** ·
/// `Sl · A/c · due` · the status pill with the row's one action at the end of its line:
/// * customer still owes → **Collect ₹X**
/// * collected months waiting → **Deposit N**
/// * settled → no action; the figure (`₹X paid`) takes the action's place
///
/// The figure is shown once. "Collect ₹X" carries it; under a Deposit button, which has
/// none, it sits in the caption line with what the figure is made of.
///
/// The row is a grouped tile: pass its [position] among its neighbours.
class RDMonthlyOperationCard extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final bool isSelected;
  final bool isSelectionMode;

  /// Where this row sits in its group (see [EntityListTile.position]).
  final AppGroupPosition position;

  /// Title the row by its serial and account instead of the customer's name. For rows
  /// under a customer's group header, which already says the name.
  final bool titleByAccount;

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
    this.position = AppGroupPosition.single,
    this.titleByAccount = false,
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

  static Widget skeleton({
    AppGroupPosition position = AppGroupPosition.single,
  }) {
    final dummy = RecurringDeposit.dummy;
    final card = t.recurringDeposits.monthlyOperations.card;
    return EntityListTile(
      position: position,
      leadingIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar03,
        size: AppDimensions.iconMd,
      ),
      title: dummy.customerName ?? BoneMock.name,
      subtitle: Text(BoneMock.words(4)),
      // Laid out like a real row: a status on the left, the action at the end of its line.
      footer: Row(
        children: [
          Expanded(
            child: Text(
              BoneMock.words(2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacings.gapSm,
          Flexible(
            child: AppButton(
              onPressed: null,
              label: card.collect(amount: dummy.installmentAmount.toRupeeFormat()),
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
    // The pill describes the *account* the agent is standing in front of, not just this
    // month: carried-over arrears outrank "Upcoming" / "Due today".
    final arrearsMonths =
        item.priorOverdueCount + (item.isOverdue(now) && item.isCustomerPending ? 1 : 0);
    final financial = AppFinancialColors.of(context);
    final inArrears = item.hasPriorArrears && status.isCustomerPending;
    final RDStatusVisual visual;
    if (inArrears) {
      final overdue = RDInstallmentDisplayStatus.overdue.visual(
        scheme,
        financial: financial,
      );
      visual = (
        foreground: overdue.foreground,
        background: overdue.background,
        icon: overdue.icon,
        label: t.recurringDeposits.monthlyOperations.card.arrearsPill(n: arrearsMonths),
        outline: overdue.outline,
        emphasized: true,
      );
    } else {
      visual = status.visual(scheme, financial: financial);
    }
    final money = _money(scheme);
    final emphasized = AppTypography.emphasizedOf(context);

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

    final largeText = RDHubLayout.isLargeText(context);
    final action = RDOperationActionButton(
      item: item,
      evaluationDate: now,
      isBusy: isBusy,
      // Beside the pill the button hugs its label; on a line of its own it fills the line.
      compact: !largeText,
      onCollect: onCollect,
      onDeposit: onDeposit,
    );
    final hasAction = action.resolve(context) != null;

    // "Collect ₹X" is the figure. A Deposit button has none, so there the figure leads
    // the caption; a row with no action shows it where the action would be.
    final figureInCaption = hasAction && !item.isCustomerPending && money != null;
    final captionParts = [
      if (figureInCaption) money.headline,
      ...?money?.captionParts,
    ];
    final caption = captionParts.isEmpty
        ? null
        : captionParts.join(t.format.bulletSeparator);

    final headline = money == null || hasAction
        ? null
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              money.headline,
              style: emphasized.titleLarge?.copyWith(color: money.color),
              maxLines: 1,
            ),
          );

    return EntityListTile(
      position: position,
      indicatorColor: isDefaultState
          ? null
          : status.accent(scheme, financial: financial),
      isSelected: isSelected,
      // In selection mode the avatar turns over into the row's selection mark, and that
      // mark turns over again when the row is selected.
      leading: AppSelectionFlip(
        selected: isSelectionMode,
        selectedChild: Semantics(
          container: true,
          checked: isSelected,
          enabled: onSelect != null,
          label: selectSemanticLabel,
          onTap: onSelect == null ? null : () => onSelect!(!isSelected),
          excludeSemantics: true,
          child: AppSelectionFlip(
            selected: isSelected,
            selectedChild: _SelectionMark(shape: deposit.schemeType.avatarShape, isSelected: true),
            child: _SelectionMark(shape: deposit.schemeType.avatarShape, isSelected: false),
          ),
        ),
        child: _InstallmentAvatar(
          installmentNumber: item.installmentNumber,
          status: status,
          // The scheme's shape, as on the Accounts list. The status is the avatar's
          // colour and the pill; eight shapes for eight statuses, three of them the
          // shapes of other schemes, was a second code nobody could learn.
          shape: deposit.schemeType.avatarShape,
          visual: visual,
        ),
      ),
      title: titleByAccount
          ? _identityOf(deposit)
          : deposit.customerName ?? t.recurringDeposits.unnamedCustomer,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXxs),
        child: _IdentityLine(
          deposit: deposit,
          installment: inst,
          status: status,
          now: now,
          showIdentity: !titleByAccount,
        ),
      ),
      // A button brings 4dp of touch padding above and below, and the pill is centred on
      // it. Without this the pill of a row with a button sat 8dp lower than the pill of a
      // row without one, and the two kinds are mixed in every month.
      footerSpacing: hasAction && !largeText
          ? AppDimensions.paddingNone
          : AppDimensions.paddingSm,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status on the left; the action, or the figure of a row that has none, at the
          // end of the same line. Neither is ellipsised: the pill keeps up to its share of
          // the line and the other shrinks into the rest. At large text sizes each takes
          // a line of its own.
          if (largeText) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: RDStatusPill(visual: visual),
            ),
            if (hasAction)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.buttonMaxWidth,
                  ),
                  child: action,
                ),
              ),
            ?headline,
          ] else
            LayoutBuilder(
              builder: (context, rowConstraints) {
                final maxPillWidth = rowConstraints.maxWidth.isFinite
                    ? rowConstraints.maxWidth * _pillMaxWidthFraction
                    : double.infinity;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxPillWidth),
                      child: RDStatusPill(visual: visual),
                    ),
                    AppSpacings.gapSm,
                    Expanded(
                      child: hasAction
                          ? Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: action,
                            )
                          : headline ?? const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
          // What the figure is made of, on its own line so it has the row's full width;
          // it wraps instead of being cut, because it carries the fee.
          if (caption != null)
            Text(
              caption,
              textAlign: TextAlign.end,
              // Neutral: the pill above already says the account is overdue.
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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

/// What stands in the avatar's place in selection mode: the scheme's shape, empty until the
/// row is selected and then filled with a tick.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.shape, required this.isSelected});

  final AppAvatarShape shape;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppShapeAvatar(
      size: AppDimensions.avatarMd,
      shape: shape,
      backgroundColor: isSelected ? scheme.primary : scheme.inset,
      foregroundColor: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
      child: AppIcon(
        isSelected ? HugeIcons.strokeRoundedTick02 : HugeIcons.strokeRoundedCircle,
        size: AppDimensions.iconMd,
      ),
    );
  }
}

/// The row's avatar: a Material shape in the status colours, holding the status icon once
/// the month is done and the installment number while it is still open.
class _InstallmentAvatar extends StatelessWidget {
  final int installmentNumber;
  final RDInstallmentDisplayStatus status;
  final AppAvatarShape shape;
  final RDStatusVisual visual;

  const _InstallmentAvatar({
    required this.installmentNumber,
    required this.status,
    required this.shape,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final showIcon =
        status == RDInstallmentDisplayStatus.settled ||
        status == RDInstallmentDisplayStatus.baseline;

    // A status drawn as an outline in pills ("due today") has no fill of its own. A shape
    // has no outline to draw, so the avatar is filled with that outline colour instead.
    final background = visual.outline ?? visual.background;
    final foreground = visual.outline == null
        ? visual.foreground
        : visual.background;

    return AppShapeAvatar(
      size: AppDimensions.avatarMd,
      shape: shape,
      backgroundColor: background,
      foregroundColor: foreground,
      child: showIcon
          ? AppIcon(visual.icon, size: AppDimensions.iconMd)
          : Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSm),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t.recurringDeposits.monthlyOperations.card.monthNo(n: installmentNumber.toString()),
                  maxLines: 1,
                  style: AppTypography.emphasizedOf(context).labelLarge
                      ?.copyWith(color: foreground),
                ),
              ),
            ),
    );
  }
}

/// `Sl 12 · A/c …7890`, or the account alone when the deposit has no serial number.
String _identityOf(RecurringDeposit deposit) => rdAccountIdentity(deposit);

/// `Sl 12 · A/c …7890 · due 15 Mar` on one line where it fits; only the account may be
/// ellipsised. The due date moves to a line of its own, and wraps, rather than being cut.
class _IdentityLine extends StatelessWidget {
  final RecurringDeposit deposit;
  final RDInstallment installment;
  final RDInstallmentDisplayStatus status;
  final DateTime now;

  /// False when the row's title already is the serial and account: only the due date shows.
  final bool showIdentity;

  const _IdentityLine({
    required this.deposit,
    required this.installment,
    required this.status,
    required this.now,
    this.showIdentity = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final (dueText, dueStyle) = _dueText(context);

    // Serial + account share one span so, when space runs out, the ellipsis eats the
    // account tail first; the due date is never cut.
    return Wrap(
      spacing: AppDimensions.paddingXs,
      runSpacing: AppDimensions.paddingXxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showIdentity)
          Text(
            _identityOf(deposit),
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(dueText, style: dueStyle),
      ],
    );
  }

  (String, TextStyle?) _dueText(BuildContext context) {
    final theme = Theme.of(context);
    final emphasized = AppTypography.emphasizedOf(context);
    final card = t.recurringDeposits.monthlyOperations.card;
    final due = card.due(
      date: DateFormat(_dueDatePattern, resolvedDateLocale()).format(installment.dueDate),
    );
    final alert = emphasized.bodySmall?.copyWith(
      color: theme.colorScheme.error,
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
        emphasized.bodySmall?.copyWith(color: theme.colorScheme.primary),
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

/// The single primary action for a row. Vocabulary: customer side = "Collect ₹X",
/// PO side = "Deposit N". Settled rows have no action.
class RDOperationActionButton extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final bool isBusy;

  /// Hug the label and drop the icon, for a button that shares a line with the status
  /// pill. Otherwise the button fills its line.
  final bool compact;
  final VoidCallback onCollect;
  final VoidCallback onDeposit;

  const RDOperationActionButton({
    super.key,
    required this.item,
    required this.evaluationDate,
    this.isBusy = false,
    this.compact = false,
    required this.onCollect,
    required this.onDeposit,
  });

  RDOperationActionSpec? resolve(BuildContext context) {
    final card = t.recurringDeposits.monthlyOperations.card;

    if (item.isCustomerPending) {
      return (
        label: card.collect(amount: item.totalOutstanding.toRupeeFormat()),
        icon: HugeIcons.strokeRoundedCoins01,
        variant: AppButtonVariant.filled,
        onPressed: onCollect,
      );
    }
    if (item.readyForPoCount > 0) {
      return (
        label: card.deposit(count: item.readyForPoCount),
        icon: HugeIcons.strokeRoundedBuilding03,
        variant: AppButtonVariant.tonal,
        onPressed: onDeposit,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final spec = resolve(context);
    if (spec == null) return const SizedBox.shrink();

    return AppButton(
      label: spec.label,
      icon: compact ? null : spec.icon,
      variant: spec.variant,
      expand: !compact,
      onPressed: isBusy ? null : spec.onPressed,
    );
  }
}
