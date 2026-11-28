import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_sheet_parts.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Opens the Post Office visit planner bound to `rDPoVisitPlannerProvider`.
Future<void> showRDPoVisitPlanner(BuildContext context) =>
    AppAdaptiveSheet.show<void>(
      context,
      builder: (_) => _PoVisitPlannerSheet(hostContext: context),
    );

class _PoVisitPlannerSheet extends HookConsumerWidget {
  const _PoVisitPlannerSheet({required this.hostContext});

  final BuildContext hostContext;

  static const int _lookbackYears = 1;

  /// The sheet never covers more than this share of the window's height.
  static const double _maxHeightFraction = 0.85;

  /// Sheet height, at 1.0x text, from which the totals are pinned above the action. It
  /// leaves the lines more than half of the sheet once the header, totals and action are
  /// placed; the threshold grows with the text size.
  static const double _pinTotalsMinHeight = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visit = t.recurringDeposits.monthlyOperations.visit;
    final plan = ref.watch(rDPoVisitPlannerProvider);
    final planner = ref.read(rDPoVisitPlannerProvider.notifier);
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final today = ref.watch(clockProvider)().toDateOnly();

    final failure = useState<String?>(null);

    final installmentCount = plan.installmentCount;
    final canRecord = installmentCount > 0 && !isBusy;

    Future<void> pickDate() async {
      final lookback = DateTime(today.year - _lookbackYears, today.month);
      final floor = plan.earliestAllowedDate;
      final firstDate = floor != null && floor.isAfter(lookback)
          ? floor
          : lookback;
      final selected = await showDatePicker(
        context: context,
        initialDate: plan.depositedOn.isBefore(firstDate)
            ? firstDate
            : plan.depositedOn,
        firstDate: firstDate.isAfter(today) ? today : firstDate,
        lastDate: today,
      );
      if (selected == null || !context.mounted) return;
      planner.setDate(selected);
    }

    Future<void> record() async {
      final successMessage = visit.success(
        installments: visit.installmentsCount(n: installmentCount),
        accounts: t.recurringDeposits.monthlyOperations.kpis.accountsCount(
          n: plan.accountCount,
        ),
      );
      failure.value = null;
      final result = await planner.record();
      if (!context.mounted) return;
      switch (result) {
        case Success(:final value):
          final batchId = value;
          Navigator.of(context).pop();
          if (!hostContext.mounted) return;
          AppFeedback.showResult(
            hostContext,
            const Success<void, String>(null),
            successMessage: successMessage,
            undoLabel: visit.undoVisit,
            onUndo: () async {
              final undone = await planner.undoVisit(batchId);
              if (!hostContext.mounted) return;
              AppFeedback.showResult(
                hostContext,
                undone,
                successMessage: visit.undone,
              );
            },
          );
        case Failure(:final error):
          failure.value = error;
          AppFeedback.showError(context, error);
      }
    }

    final maxHeight = MediaQuery.sizeOf(context).height * _maxHeightFraction;

    final totals = _TotalsBlock(plan: plan);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // With room to spare the totals stay pinned above the action, always in view
          // while the agent ticks lines. On a short window, with the keyboard up or at a
          // large text size they would crowd the lines out, so they end the list instead.
          final pinTotals =
              constraints.maxHeight >=
              MediaQuery.textScalerOf(context).scale(_pinTotalsMinHeight);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RDSheetHeader(
                title: visit.title,
                onClose: () => Navigator.of(context).maybePop(),
              ),
              // Everything that can grow scrolls together: the visit's settings, the
              // cash-lot notice (one line per lot) and the account lines.
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.pageMargin,
                        AppDimensions.paddingSm,
                        AppDimensions.pageMargin,
                        AppDimensions.paddingMd,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RDSheetPickerTile(
                              icon: HugeIcons.strokeRoundedCalendar01,
                              label: visit.date(
                                date: plan.depositedOn.toAppFormat(),
                              ),
                              onTap: isBusy ? null : pickDate,
                              position: AppGroupPosition.first,
                            ),
                            const SizedBox(height: AppShapes.groupGap),
                            AppGroupTile(
                              position: AppGroupPosition.last,
                              child: SwitchListTile(
                                value: plan.includeUnready,
                                onChanged: isBusy
                                    ? null
                                    : planner.setIncludeUnready,
                                title: Text(
                                  visit.includeUnready,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            if (plan.exceedsSingleCashLot) ...[
                              AppSpacings.gapMd,
                              _CashLotsWarning(plan: plan),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (plan.lines.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.all(AppDimensions.paddingXl),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            visit.empty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.pageMargin,
                        ),
                        sliver: SliverList.separated(
                          itemCount: plan.lines.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppShapes.groupGap),
                          itemBuilder: (context, index) => _VisitLineTile(
                            key: ValueKey(plan.lines[index].rdId),
                            line: plan.lines[index],
                            position: AppGroupPosition.at(
                              index,
                              plan.lines.length,
                            ),
                            isBusy: isBusy,
                            onToggle: () =>
                                planner.toggleIncluded(plan.lines[index].rdId),
                            onFromPocketChanged: (n) => planner
                                .setFromPocketCount(plan.lines[index].rdId, n),
                            onFeeOverride: (fee) => planner.setFeeOverride(
                              plan.lines[index].rdId,
                              fee,
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.pageMargin,
                        AppDimensions.paddingMd,
                        AppDimensions.pageMargin,
                        AppDimensions.paddingSm,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: pinTotals ? const SizedBox.shrink() : totals,
                      ),
                    ),
                  ],
                ),
              ),
              RDSheetFooter(
                children: [
                  // Next to the action that failed: the error toast is hidden behind the
                  // sheet on a phone.
                  if (failure.value != null) ...[
                    _FailureTile(
                      message: failure.value!,
                      onRetry: canRecord ? record : null,
                    ),
                    AppSpacings.gapSm,
                  ],
                  if (pinTotals) ...[totals, AppSpacings.gapMd],
                  RDSheetPrimaryAction(
                    label: visit.submit(
                      installments: visit.installmentsCount(
                        n: installmentCount,
                      ),
                      amount: plan.totalAmount.toRupeeFormat(),
                    ),
                    icon: HugeIcons.strokeRoundedBuilding03,
                    isLoading: isBusy,
                    onPressed: canRecord ? record : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// What the visit adds up to: accounts and installments, the total the counter will ask
/// for, how it splits into cash and UPI, and how much of it is the agent's own money.
class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.plan});

  final RDPoVisitPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final visit = t.recurringDeposits.monthlyOperations.visit;
    final kpis = t.recurringDeposits.monthlyOperations.kpis;

    final total = plan.totalAmount.toRupeeFormat();
    final totalLine = plan.totalFee > 0
        ? visit.totalWithFee(amount: total, fee: plan.totalFee.toRupeeFormat())
        : visit.total(amount: total);
    final caption = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return RDSheetBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            visit.summary(
              accounts: kpis.accountsCount(n: plan.accountCount),
              installments: visit.installmentsCount(n: plan.installmentCount),
            ),
            style: caption,
          ),
          RDSheetFigure(
            totalLine,
            style: emphasized.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            figure: total,
            figureStyle: emphasized.headlineMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          RDSheetFigure(
            visit.byMode(
              cash: plan.totalCash.toRupeeFormat(),
              digital: plan.totalDigital.toRupeeFormat(),
            ),
            style: caption,
          ),
          if (plan.totalFromPocket > 0) ...[
            AppSpacings.gapXs,
            Row(
              children: [
                // The agent's own money takes the receivable colour, not the overdue red.
                HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet02,
                  size: AppDimensions.iconSm,
                  color: AppFinancialColors.of(context).receivable.onContainer,
                ),
                AppSpacings.gapXs,
                Flexible(
                  child: RDSheetFigure(
                    visit.fromPocket(
                      amount: plan.totalFromPocket.toRupeeFormat(),
                    ),
                    style: emphasized.bodyMedium?.copyWith(
                      color: AppFinancialColors.of(
                        context,
                      ).receivable.onContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CashLotsWarning extends StatelessWidget {
  const _CashLotsWarning({required this.plan});

  final RDPoVisitPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = AppFinancialColors.of(context).warning;
    final visit = t.recurringDeposits.monthlyOperations.visit;
    final kpis = t.recurringDeposits.monthlyOperations.kpis;

    return RDSheetBlock(
      color: warning.container,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                size: AppDimensions.iconSm,
                color: warning.onContainer,
              ),
              AppSpacings.gapSm,
              Expanded(
                child: Text(
                  visit.cashLotWarning,
                  style: AppTypography.emphasizedOf(
                    context,
                  ).bodyMedium?.copyWith(color: warning.onContainer),
                ),
              ),
            ],
          ),
          AppSpacings.gapXs,
          for (final lot in plan.cashLots)
            Text(
              visit.cashLot(
                index: lot.index,
                amount: lot.cashAmount.toRupeeFormat(),
                count: kpis.accountsCount(n: lot.rdIds.length),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: warning.onContainer,
              ),
            ),
        ],
      ),
    );
  }
}

class _FailureTile extends StatelessWidget {
  const _FailureTile({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = AppFinancialColors.of(context).overdue;
    return RDSheetBlock(
      color: overdue.container,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: overdue.onContainer,
              ),
            ),
          ),
          AppSpacings.gapSm,
          AppButton.text(
            label: t.common.retry,
            foregroundColor: overdue.onContainer,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// One account of the visit: a row of the grouped list of lines.
class _VisitLineTile extends HookWidget {
  const _VisitLineTile({
    super.key,
    required this.line,
    required this.position,
    required this.isBusy,
    required this.onToggle,
    required this.onFromPocketChanged,
    required this.onFeeOverride,
  });

  final RDPoVisitLine line;
  final AppGroupPosition position;
  final bool isBusy;
  final VoidCallback onToggle;
  final ValueChanged<int> onFromPocketChanged;
  final ValueChanged<double?> onFeeOverride;

  static const int _accountTailLength = 4;

  /// A long name wraps once at large text sizes before it is cut.
  static const int _nameMaxLines = 2;

  /// Width, at 1.0x text, that the account line and the three controls need side by side.
  /// With less (a 360dp phone, or larger text) the controls take a row of their own.
  static const double _inlineControlsMinWidth = 290;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final visit = t.recurringDeposits.monthlyOperations.visit;
    final card = t.recurringDeposits.monthlyOperations.card;
    final deposit = line.item.deposit;

    final showFeeEditor = useState<bool>(line.feeOverride != null);
    final feeController = useTextEditingController(
      text: line.feeOverride != null
          ? line.feeOverride!.toStringAsFixed(0)
          : '',
    );

    final accountNo = deposit.accountNo ?? '';
    final last4 = accountNo.length > _accountTailLength
        ? accountNo.substring(accountNo.length - _accountTailLength)
        : (accountNo.isEmpty ? t.common.notProvided : accountNo);
    final serial = (deposit.serialNo?.isNotEmpty ?? false)
        ? card.serial(serialNo: deposit.serialNo!)
        : t.common.notProvided;

    final muted = !line.included;
    final titleColor = muted ? scheme.onSurfaceVariant : scheme.onSurface;
    final customerName =
        deposit.customerName ?? t.recurringDeposits.depositNotFound;

    // Counter-fee toggle, then "deposit one month less from pocket" / "one more".
    final controls = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          key: ValueKey('visit_fee_override_${line.rdId}'),
          tooltip: visit.counterFeeOverride,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedPercent,
            size: AppDimensions.iconMd,
            color: line.feeOverride != null
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          onPressed: isBusy
              ? null
              : () => showFeeEditor.value = !showFeeEditor.value,
        ),
        AppButton.text(
          label: visit.fromPocketLess,
          tooltip: visit.fromPocketFewer,
          onPressed: isBusy || line.fromPocketCount == 0
              ? null
              : () => onFromPocketChanged(line.fromPocketCount - 1),
        ),
        AppButton.tonal(
          label: visit.fromPocketAdd,
          tooltip: visit.fromPocketMore,
          onPressed: isBusy || !line.canAddFromPocket
              ? null
              : () => onFromPocketChanged(line.fromPocketCount + 1),
        ),
      ],
    );

    // Serial and account tail identify the account at the counter: they wrap, never cut.
    final account = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          visit.lineSubtitle(serial: serial, last4: last4),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (line.fromPocket > 0)
          RDSheetFigure(
            visit.lineFromPocket(amount: line.fromPocket.toRupeeFormat()),
            style: emphasized.labelMedium?.copyWith(
              color: AppFinancialColors.of(context).receivable.onContainer,
            ),
          ),
      ],
    );

    return AppGroupTile(
      position: position,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDimensions.paddingXs,
          AppDimensions.paddingSm,
          AppDimensions.paddingSm,
          AppDimensions.paddingXs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  value: line.included,
                  semanticLabel: visit.includeLine(name: customerName),
                  onChanged: isBusy ? null : (_) => onToggle(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and amount share a line while both fit; otherwise the amount
                      // moves below the name. Neither is cut to make room for the other.
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppDimensions.paddingXs,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppDimensions.paddingSm,
                          children: [
                            Text(
                              customerName,
                              style: emphasized.titleSmall?.copyWith(
                                color: titleColor,
                              ),
                              maxLines: _nameMaxLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                            RDSheetFigure(
                              visit.lineTrailing(
                                count: line.count,
                                amount: line.amount.toRupeeFormat(),
                              ),
                              style: emphasized.titleSmall?.copyWith(
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // The account line sits beside the controls where both fit, and above
                      // them where they do not.
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final inline =
                              constraints.maxWidth >=
                              MediaQuery.textScalerOf(
                                context,
                              ).scale(_inlineControlsMinWidth);
                          return inline
                              ? Row(
                                  children: [
                                    Expanded(child: account),
                                    controls,
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [account, controls],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showFeeEditor.value)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppDimensions.paddingMd,
                  end: AppDimensions.paddingXs,
                  top: AppDimensions.paddingSm,
                  bottom: AppDimensions.paddingXs,
                ),
                child: TextFormField(
                  key: ValueKey('visit_fee_input_${line.rdId}'),
                  controller: feeController,
                  enabled: !isBusy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration:
                      AppInputDecoration.m3(
                        context,
                        labelText: visit.counterFeeLabel,
                        prefixText: t.format.currencySymbol,
                      ).copyWith(
                        isDense: true,
                        suffixIcon: line.feeOverride != null
                            ? IconButton(
                                tooltip: t.common.clear,
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedCancel01,
                                  size: AppDimensions.iconSm,
                                ),
                                onPressed: () {
                                  feeController.clear();
                                  onFeeOverride(null);
                                },
                              )
                            : null,
                      ),
                  onChanged: (raw) {
                    final trimmed = raw.trim();
                    if (trimmed.isEmpty) {
                      onFeeOverride(null);
                      return;
                    }
                    final parsed = double.tryParse(trimmed);
                    if (parsed != null) {
                      onFeeOverride(parsed);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
