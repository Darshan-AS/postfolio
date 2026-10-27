import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_schedule_actions.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Cash-in-hand / pocket-advance KPI strip (values come from the projection summary).
class RDInstallmentKpiRow extends StatelessWidget {
  final double pendingPoAmount;
  final double advancedPoAmount;

  const RDInstallmentKpiRow({
    super.key,
    required this.pendingPoAmount,
    required this.advancedPoAmount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kpis = t.recurringDeposits.ledger.kpis;

    return Row(
      children: [
        if (pendingPoAmount > 0)
          Expanded(
            child: _KpiCard(
              label: kpis.pendingAtPo,
              amount: pendingPoAmount,
              foreground: scheme.onPrimaryContainer,
              background: scheme.primaryContainer,
            ),
          ),
        if (pendingPoAmount > 0 && advancedPoAmount > 0) AppSpacings.gapSm,
        if (advancedPoAmount > 0)
          Expanded(
            child: _KpiCard(
              label: kpis.advancedPo,
              amount: advancedPoAmount,
              foreground: scheme.onSecondaryContainer,
              background: scheme.secondaryContainer,
            ),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color foreground;
  final Color background;

  const _KpiCard({
    required this.label,
    required this.amount,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacings.gapXs,
          Text(
            amount.toRupeeFormat(),
            style: theme.textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Log Payment / Manage PO toolbar shared by Matrix and Yearly List modes.
class RDInstallmentActionBar extends ConsumerWidget {
  final String rdId;
  final bool isSelectionMode;
  final int selectedCount;
  final List<RDInstallment> depositable;
  final List<RDInstallment> revertible;
  final bool isBusy;
  final ValueChanged<bool> onToggleSelectionMode;

  const RDInstallmentActionBar({
    super.key,
    required this.rdId,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.depositable,
    required this.revertible,
    required this.isBusy,
    required this.onToggleSelectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    if (!isSelectionMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: isBusy ? null : () => showRDLogPaymentSheet(context, rdId: rdId),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCoins01,
              size: AppDimensions.iconSm,
            ),
            label: Text(ledger.logPayment),
          ),
          AppSpacings.gapSm,
          OutlinedButton.icon(
            onPressed: isBusy ? null : () => onToggleSelectionMode(true),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              size: AppDimensions.iconSm,
            ),
            label: Text(ledger.managePo),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                selectedCount == 0
                    ? ledger.actions.selectionHint
                    : ledger.kpis.selectedForPo(count: selectedCount.toString()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: selectedCount == 0
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => onToggleSelectionMode(false),
              child: Text(t.common.cancel),
            ),
          ],
        ),
        if (depositable.isNotEmpty || revertible.isNotEmpty)
          Wrap(
            spacing: AppDimensions.paddingSm,
            runSpacing: AppDimensions.paddingXs,
            alignment: WrapAlignment.end,
            children: [
              if (depositable.isNotEmpty)
                FilledButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          final ok = await RDScheduleActions.confirmAndDepositToPo(
                            context,
                            ref,
                            rdId: rdId,
                            installments: depositable,
                          );
                          if (ok) onToggleSelectionMode(false);
                        },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedBuilding03,
                    size: AppDimensions.iconSm,
                  ),
                  label: Text(
                    ledger.actions.deposit(count: depositable.length.toString()),
                  ),
                ),
              if (revertible.isNotEmpty)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                  onPressed: isBusy
                      ? null
                      : () async {
                          final ok = await RDScheduleActions.confirmAndRevertPo(
                            context,
                            ref,
                            rdId: rdId,
                            installments: revertible,
                          );
                          if (ok) onToggleSelectionMode(false);
                        },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowTurnBackward,
                    size: AppDimensions.iconSm,
                  ),
                  label: Text(
                    ledger.actions.revert(count: revertible.length.toString()),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
