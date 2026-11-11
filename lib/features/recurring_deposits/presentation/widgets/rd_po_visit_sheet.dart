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
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Opens the Post Office visit planner bound to `rDPoVisitPlannerProvider`.
Future<void> showRDPoVisitPlanner(BuildContext context) => AppAdaptiveSheet.show<void>(
      context,
      builder: (_) => _PoVisitPlannerSheet(hostContext: context),
    );

class _PoVisitPlannerSheet extends HookConsumerWidget {
  const _PoVisitPlannerSheet({required this.hostContext});

  final BuildContext hostContext;

  static const int _lookbackYears = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visit = t.recurringDeposits.monthlyOperations.visit;
    final plan = ref.watch(rDPoVisitPlannerProvider);
    final planner = ref.read(rDPoVisitPlannerProvider.notifier);
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final today = ref.watch(clockProvider)().toDateOnly();

    final includeUnready = useState<bool>(false);
    final failure = useState<String?>(null);

    final installmentCount = plan.installmentCount;
    final canRecord = installmentCount > 0 && !isBusy;

    Future<void> pickDate() async {
      final lookback = DateTime(today.year - _lookbackYears, today.month);
      final floor = plan.earliestAllowedDate;
      final firstDate = floor != null && floor.isAfter(lookback) ? floor : lookback;
      final selected = await showDatePicker(
        context: context,
        initialDate: plan.depositedOn.isBefore(firstDate) ? firstDate : plan.depositedOn,
        firstDate: firstDate.isAfter(today) ? today : firstDate,
        lastDate: today,
      );
      if (selected == null || !context.mounted) return;
      planner.setDate(selected);
    }

    Future<void> record() async {
      final successMessage = visit.success(
        installments: visit.installmentsCount(n: installmentCount),
        accounts: t.recurringDeposits.monthlyOperations.kpis.accountsCount(n: plan.accountCount),
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
              AppFeedback.showResult(hostContext, undone, successMessage: visit.undone);
            },
          );
        case Failure(:final error):
          failure.value = error;
          AppFeedback.showError(context, error);
      }
    }

    void toggleIncludeUnready(bool value) {
      includeUnready.value = value;
      planner.start(includeUnready: value, preserveEdits: true);
    }

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLg,
              AppDimensions.paddingSm,
              AppDimensions.paddingSm,
              AppDimensions.paddingNone,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    visit.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: t.common.close,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: AppDimensions.iconMd,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy ? null : pickDate,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconSm,
                  ),
                  label: Text(visit.date(date: plan.depositedOn.toAppFormat())),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: includeUnready.value,
                  onChanged: isBusy ? null : toggleIncludeUnready,
                  title: Text(visit.includeUnready, style: theme.textTheme.bodySmall),
                ),
                _TotalsCard(plan: plan),
                if (plan.exceedsSingleCashLot) ...[
                  AppSpacings.gapSm,
                  _CashLotsWarning(plan: plan),
                ],
                if (failure.value != null) ...[
                  AppSpacings.gapSm,
                  _FailureTile(message: failure.value!, onRetry: canRecord ? record : null),
                ],
              ],
            ),
          ),
          AppSpacings.gapSm,
          const Divider(height: AppDimensions.dividerHeight),
          Expanded(
            child: plan.lines.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLg),
                      child: Text(
                        visit.empty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: plan.lines.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: AppDimensions.dividerHeight),
                    itemBuilder: (context, index) => _VisitLineTile(
                      key: ValueKey(plan.lines[index].rdId),
                      line: plan.lines[index],
                      isBusy: isBusy,
                      onToggle: () => planner.toggleIncluded(plan.lines[index].rdId),
                      onFront: (n) => planner.setFronted(plan.lines[index].rdId, n),
                      onFeeOverride: (fee) =>
                          planner.setFeeOverride(plan.lines[index].rdId, fee),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLg,
              AppDimensions.paddingSm,
              AppDimensions.paddingLg,
              AppDimensions.paddingLg,
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, AppDimensions.minTapTarget),
              ),
              onPressed: canRecord ? record : null,
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: AppDimensions.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: AppDimensions.strokeWidthSm,
                      ),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedBuilding03,
                      size: AppDimensions.iconSm,
                    ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  visit.submit(
                    installments: visit.installmentsCount(n: installmentCount),
                    amount: plan.totalAmount.toRupeeFormat(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.plan});

  final RDPoVisitPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visit = t.recurringDeposits.monthlyOperations.visit;
    final kpis = t.recurringDeposits.monthlyOperations.kpis;

    final total = plan.totalAmount.toRupeeFormat();
    final totalLine = plan.totalFee > 0
        ? visit.totalWithFee(amount: total, fee: plan.totalFee.toRupeeFormat())
        : visit.total(amount: total);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            visit.summary(
              accounts: kpis.accountsCount(n: plan.accountCount),
              installments: visit.installmentsCount(n: plan.installmentCount),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          AppSpacings.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              totalLine,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),
          AppSpacings.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              visit.byMode(
                cash: plan.totalCash.toRupeeFormat(),
                digital: plan.totalDigital.toRupeeFormat(),
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 1,
            ),
          ),
          if (plan.totalFromPocket > 0) ...[
            AppSpacings.gapXs,
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet02,
                  size: AppDimensions.iconXs,
                  color: scheme.error,
                ),
                AppSpacings.gapXs,
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      visit.fromPocket(amount: plan.totalFromPocket.toRupeeFormat()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
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

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: warning.container,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: warning.onContainer,
                    fontWeight: FontWeight.bold,
                  ),
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
              style: theme.textTheme.bodySmall?.copyWith(color: warning.onContainer),
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
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: overdue.container,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: overdue.onContainer),
            ),
          ),
          AppSpacings.gapSm,
          TextButton(
            onPressed: onRetry,
            child: Text(
              t.common.retry,
              style: theme.textTheme.labelLarge?.copyWith(color: overdue.onContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitLineTile extends HookWidget {
  const _VisitLineTile({
    super.key,
    required this.line,
    required this.isBusy,
    required this.onToggle,
    required this.onFront,
    required this.onFeeOverride,
  });

  final RDPoVisitLine line;
  final bool isBusy;
  final VoidCallback onToggle;
  final ValueChanged<int> onFront;
  final ValueChanged<double?> onFeeOverride;

  static const int _accountTailLength = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visit = t.recurringDeposits.monthlyOperations.visit;
    final card = t.recurringDeposits.monthlyOperations.card;
    final deposit = line.item.deposit;

    final showFeeEditor = useState<bool>(line.feeOverride != null);
    final feeController = useTextEditingController(
      text: line.feeOverride != null ? line.feeOverride!.toStringAsFixed(0) : '',
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
    final customerName = deposit.customerName ?? t.recurringDeposits.depositNotFound;

    final stepperStyle = TextButton.styleFrom(
      minimumSize: const Size(AppDimensions.minTapTarget, AppDimensions.minTapTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSm),
    );

    final stepper = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: visit.counterFeeOverride,
          child: IconButton(
            key: ValueKey('visit_fee_override_${line.rdId}'),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPercent,
              size: AppDimensions.iconSm,
              color: line.feeOverride != null ? scheme.primary : scheme.onSurfaceVariant,
            ),
            onPressed: isBusy ? null : () => showFeeEditor.value = !showFeeEditor.value,
          ),
        ),
        Tooltip(
          message: visit.frontFewer,
          child: TextButton(
            style: stepperStyle,
            onPressed: isBusy || line.frontedCount == 0
                ? null
                : () => onFront(line.frontedCount - 1),
            child: Text(visit.frontLess),
          ),
        ),
        Tooltip(
          message: visit.frontMore,
          child: TextButton(
            style: stepperStyle,
            onPressed: isBusy || !line.canFrontMore
                ? null
                : () => onFront(line.frontedCount + 1),
            child: Text(visit.front),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.paddingXs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: line.included,
                semanticLabel: visit.includeLine(name: customerName),
                onChanged: isBusy ? null : (_) => onToggle(),
              ),
              AppSpacings.gapXs,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacings.gapSm,
                        Text(
                          visit.lineTrailing(
                            count: line.count,
                            amount: line.amount.toRupeeFormat(),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                visit.lineSubtitle(serial: serial, last4: last4),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (line.fromPocket > 0)
                                Text(
                                  visit.lineFromPocket(
                                    amount: line.fromPocket.toRupeeFormat(),
                                  ),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        stepper,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showFeeEditor.value)
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.paddingXl,
                right: AppDimensions.paddingSm,
                bottom: AppDimensions.paddingSm,
              ),
              child: TextFormField(
                key: ValueKey('visit_fee_input_${line.rdId}'),
                controller: feeController,
                enabled: !isBusy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: AppInputDecoration.m3(
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
    );
  }
}
