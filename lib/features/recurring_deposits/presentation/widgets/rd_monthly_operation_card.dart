import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_capsule.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_layout.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Primary action descriptor resolved once per row.
typedef RDOperationActionSpec = ({
  String label,
  AppButtonVariant variant,
  VoidCallback? onPressed,
});

const int _accountTailLength = 4;

/// One row of the Monthly Hub. Strictly declarative — reads domain properties
/// from [RDMonthlyOperationItem].
///
/// Layout:
/// * Leading avatar: `#<serial>` inside the scheme shape + status colour.
/// * Title / subtitle: Customer name, `Inst <installment> · A/c …XXXX · <due date>`.
/// * Top-right money column: headline amount + base `/mo` sub-label.
/// * Footer left: uniform-tonal 2-step flipbook track (`Customer | PO`).
/// * Footer right: filled `Collect` on unpaid rows, tonal `Deposit` on
///   collected rows, or clean empty edge when paid to PO.
class RDMonthlyOperationCard extends StatelessWidget {
  final RDMonthlyOperationItem item;
  final DateTime evaluationDate;
  final AppGroupPosition position;
  final Object? heroTag;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onCollect;
  final VoidCallback onDeposit;
  final VoidCallback? onDepositFromPocket;
  final VoidCallback? onUndoLatestDeposit;
  final VoidCallback? onAbsorbFee;

  const RDMonthlyOperationCard({
    super.key,
    required this.item,
    required this.evaluationDate,
    this.position = AppGroupPosition.single,
    this.heroTag,
    this.isBusy = false,
    required this.onTap,
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
    final statusVisual = RDInstallmentDisplayStatus.upcoming;
    return Builder(
      builder: (context) {
        final visual = statusVisual.visualOf(context);
        return EntityListTile(
          position: position,
          leadingText: dummy.avatarLabel,
          leadingShape: dummy.schemeType.avatarShape,
          leadingBackgroundColor: visual.background,
          leadingForegroundColor: visual.foreground,
          title: dummy.customerName ?? BoneMock.name,
          subtitle: Text(BoneMock.words(3)),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dummy.installmentAmount.toRupeeFormat()),
              Text(card.perMonth),
            ],
          ),
          footer: RDHubLayout.isLargeText(context)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: RDHubStageCapsule(
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerPaid(),
                          po: RDPoStep.deposited,
                        ),
                      ),
                    ),
                    AppSpacings.gapSm,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppButton(
                        onPressed: null,
                        label: card.collectShort,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: RDHubStageCapsule(
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerPaid(),
                          po: RDPoStep.deposited,
                        ),
                      ),
                    ),
                    AppSpacings.gapSm,
                    AppButton(onPressed: null, label: card.collectShort),
                  ],
                ),
        );
      },
    );
  }

  String? _formatCaption() {
    final card = t.recurringDeposits.monthlyOperations.card;
    return switch (item.captionAt(evaluationDate)) {
      null => null,
      RDHubPendingChargesCaption(:final feeDue, :final priorOverdueCount) => [
        if (feeDue > 0) card.inclFee(amount: feeDue.toRupeeFormat()),
        if (priorOverdueCount > 0) card.arrears(n: priorOverdueCount),
      ].join(t.format.bulletSeparator),
      RDHubPartialCaption(:final paid, :final due) => card.partialCaption(
        paid: paid.toRupeeFormat(),
        due: due.toRupeeFormat(),
      ),
      RDHubFromPocketCaption() => card.fromPocketCaption,
      RDHubReadyForPoCaption(:final count) => card.readyForPoCaption(n: count),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final financial = AppFinancialColors.of(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final card = ops.card;
    final emphasized = AppTypography.emphasizedOf(context);
    final now = evaluationDate;

    final inst = item.installment;
    final deposit = item.deposit;
    final status = item.displayStatus(now);
    final inArrears = item.hasPriorArrears && status.isCustomerPending;

    final effectiveStatus = inArrears
        ? RDInstallmentDisplayStatus.overdue
        : status;
    final avatarColors = effectiveStatus.avatarColors(
      scheme,
      financial: financial,
    );

    final isDefaultState =
        !item.hasPriorArrears &&
        (status == RDInstallmentDisplayStatus.upcoming ||
            status == RDInstallmentDisplayStatus.dueToday);

    final canDepositFromPocket =
        item.canDepositFromPocket && onDepositFromPocket != null;
    final canAbsorbFee = inst.absorbableFee > 0 && onAbsorbFee != null;
    final canUndoLatest = item.isLatestDeposited && onUndoLatestDeposit != null;

    final money = item.headlineMoneyAt(now);
    final moneyColor = switch (money.tone) {
      RDHeadlineMoneyTone.overdue => financial.overdue.onContainer,
      RDHeadlineMoneyTone.neutral => scheme.onSurface,
      RDHeadlineMoneyTone.settled => financial.settled.onContainer,
      RDHeadlineMoneyTone.muted => scheme.onSurfaceVariant,
    };
    final moneySubLabel = Money.equals(money.amount, money.baseAmount)
        ? card.perMonth
        : card.basePerMonth(amount: money.baseAmount.toRupeeFormat());

    final caption = _formatCaption();
    final largeText = RDHubLayout.isLargeText(context);
    final actionSpec = RDOperationActionButton.resolveSpec(
      item: item,
      onCollect: onCollect,
      onDeposit: onDeposit,
    );

    final actionWidget = actionSpec == null
        ? null
        : RDOperationActionButton(spec: actionSpec, isBusy: isBusy);

    final trailingMoney = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            money.amount.toRupeeFormat(),
            style: emphasized.titleMedium?.copyWith(color: moneyColor),
            maxLines: 1,
          ),
        ),
        Text(
          moneySubLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          maxLines: 1,
        ),
      ],
    );

    final capsule = RDHubStageCapsule(track: item.stepTrackAt(now));

    return EntityListTile(
      position: position,
      heroTag: heroTag,
      indicatorColor: isDefaultState
          ? null
          : effectiveStatus.accent(scheme, financial: financial),
      leadingText: deposit.avatarLabel,
      leadingShape: deposit.schemeType.avatarShape,
      leadingBackgroundColor: avatarColors.background,
      leadingForegroundColor: avatarColors.foreground,
      title: deposit.customerName ?? t.recurringDeposits.unnamedCustomer,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXxs),
        child: _IdentityLine(
          deposit: deposit,
          installment: inst,
          status: status,
          now: now,
        ),
      ),
      trailing: trailingMoney,
      footerSpacing: AppDimensions.paddingSm,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (largeText) ...[
            Align(alignment: AlignmentDirectional.centerStart, child: capsule),
            if (actionWidget != null) ...[
              AppSpacings.gapSm,
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: actionWidget,
              ),
            ],
          ] else
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppDimensions.paddingSm,
              runSpacing: AppDimensions.paddingSm,
              children: [capsule, ?actionWidget],
            ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.paddingXxs),
              child: Text(
                caption,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (canDepositFromPocket)
          EntityAction(
            label: card.depositFromPocket,
            icon: const AppIcon(
              HugeIcons.strokeRoundedWallet02,
              size: AppDimensions.iconMd,
            ),
            onTap: onDepositFromPocket!,
          ),
        if (canAbsorbFee)
          EntityAction(
            label: card.absorbFee(amount: inst.absorbableFee.toRupeeFormat()),
            icon: const AppIcon(
              HugeIcons.strokeRoundedCheckmarkBadge01,
              size: AppDimensions.iconMd,
            ),
            onTap: onAbsorbFee!,
          ),
        if (canUndoLatest)
          EntityAction(
            label: card.undoLatestDeposit,
            icon: const AppIcon(
              HugeIcons.strokeRoundedArrowTurnBackward,
              size: AppDimensions.iconMd,
            ),
            isDestructive: true,
            onTap: onUndoLatestDeposit!,
          ),
        EntityAction(
          label: card.viewLedger,
          icon: const AppIcon(
            HugeIcons.strokeRoundedFile01,
            size: AppDimensions.iconMd,
          ),
          onTap: onTap,
        ),
      ],
      onTap: onTap,
    );
  }
}

/// `Inst 10 · A/c …7890 · due 15 Nov` (since `#serial` lives in the avatar).
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
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final accountNo = deposit.accountNo ?? '';
    final last4 = accountNo.length > _accountTailLength
        ? accountNo.substring(accountNo.length - _accountTailLength)
        : (accountNo.isEmpty ? t.common.notProvided : accountNo);
    final identityText = card.installmentIdentity(
      installment: installment.installmentNo.toString(),
      account: card.accountTail(last4: last4),
    );

    final (dueText, dueStyle) = _dueText(context);

    return Wrap(
      spacing: AppDimensions.paddingXs,
      runSpacing: AppDimensions.paddingXxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          identityText,
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
    final financial = AppFinancialColors.of(context);
    final emphasized = AppTypography.emphasizedOf(context);
    final card = t.recurringDeposits.monthlyOperations.card;
    final due = card.due(date: installment.dueDate.toDayMonthFormat());
    final alert = emphasized.bodySmall?.copyWith(
      color: financial.overdue.onContainer,
    );

    if (status == RDInstallmentDisplayStatus.overdue) {
      final days = installment.overdueDaysAt(now);
      return (
        card.dueOverdue(
          due: due,
          late: card.overdueDays(days: days < 1 ? 1 : days),
        ),
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

/// Primary action on a Hub row:
/// * Customer pending -> filled `Collect` (`Deposit from pocket` lives in `⋮` & sheet footer).
/// * Collected & waiting for PO -> tonal `Deposit`.
/// * Settled / Baseline -> omitted (`null` spec).
class RDOperationActionButton extends StatelessWidget {
  final RDOperationActionSpec spec;
  final bool isBusy;

  const RDOperationActionButton({
    super.key,
    required this.spec,
    this.isBusy = false,
  });

  static RDOperationActionSpec? resolveSpec({
    required RDMonthlyOperationItem item,
    required VoidCallback onCollect,
    required VoidCallback onDeposit,
  }) {
    final card = t.recurringDeposits.monthlyOperations.card;
    if (item.isCustomerPending) {
      return (
        label: card.collectShort,
        variant: AppButtonVariant.filled,
        onPressed: onCollect,
      );
    }
    if (item.readyForPoCount > 0) {
      return (
        label: card.deposit,
        variant: AppButtonVariant.tonal,
        onPressed: onDeposit,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: spec.label,
      variant: spec.variant,
      onPressed: isBusy ? null : spec.onPressed,
    );
  }
}
