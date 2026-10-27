import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Tenure matrix: one accessible cell per schedule month.
///
/// Pure presentation — status colour/icon/label come from `displayStatusAt(now).visual`,
/// selection state is owned by the parent.
class RDInstallmentHeatmap extends StatelessWidget {
  final List<RDInstallment> installments;
  final DateTime now;

  /// 1-based month currently shown in the inspector.
  final int selectedMonthNo;

  /// 1-based next-due month, or null when fully settled.
  final int? nextDueNo;
  final ValueChanged<int> onSelectMonth;

  /// Multi-select (Manage PO) support.
  final bool isSelectionMode;
  final Set<int> selectedNos;
  final ValueChanged<int>? onToggleSelection;

  const RDInstallmentHeatmap({
    super.key,
    required this.installments,
    required this.now,
    required this.selectedMonthNo,
    required this.nextDueNo,
    required this.onSelectMonth,
    this.isSelectionMode = false,
    this.selectedNos = const {},
    this.onToggleSelection,
  });

  static const int _columns = 6;

  /// Statuses that can appear in a matrix cell (baseline is rendered as a locked cell).
  static const List<RDInstallmentDisplayStatus> _legendStatuses = [
    RDInstallmentDisplayStatus.settled,
    RDInstallmentDisplayStatus.collectedPendingPo,
    RDInstallmentDisplayStatus.partiallyPaid,
    RDInstallmentDisplayStatus.pocketAdvanced,
    RDInstallmentDisplayStatus.feePending,
    RDInstallmentDisplayStatus.overdue,
    RDInstallmentDisplayStatus.upcoming,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heatmapI18n = t.recurringDeposits.ledger.heatmap;

    if (installments.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeatmapHeader(
              totalMonths: installments.length,
              selectedMonthNo: selectedMonthNo,
              nextDueNo: nextDueNo,
              onSelectMonth: onSelectMonth,
            ),
            if (isSelectionMode) ...[
              AppSpacings.gapXs,
              Text(
                heatmapI18n.selectionHint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            AppSpacings.gapSm,
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppDimensions.paddingXs;
                final cellWidth =
                    (constraints.maxWidth - spacing * (_columns - 1)) / _columns;
                final cellHeight = cellWidth < AppDimensions.minTapTarget
                    ? AppDimensions.minTapTarget
                    : cellWidth;
                return GridView.count(
                  crossAxisCount: _columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: cellWidth / cellHeight,
                  children: [
                    for (final inst in installments)
                      _HeatmapCell(
                        installment: inst,
                        now: now,
                        isInspected: inst.installmentNo == selectedMonthNo,
                        isNextDue: inst.installmentNo == nextDueNo,
                        isSelectionMode: isSelectionMode,
                        isChecked: selectedNos.contains(inst.installmentNo),
                        onTap: () {
                          final no = inst.installmentNo!;
                          if (isSelectionMode &&
                              onToggleSelection != null &&
                              !inst.isOpeningBaseline) {
                            onToggleSelection!(no);
                          }
                          onSelectMonth(no);
                        },
                      ),
                  ],
                );
              },
            ),
            AppSpacings.gapMd,
            const Divider(height: AppDimensions.dividerHeight),
            AppSpacings.gapSm,
            _HeatmapLegend(statuses: _legendStatuses),
          ],
        ),
      ),
    );
  }
}

class _HeatmapHeader extends StatelessWidget {
  final int totalMonths;
  final int selectedMonthNo;
  final int? nextDueNo;
  final ValueChanged<int> onSelectMonth;

  const _HeatmapHeader({
    required this.totalMonths,
    required this.selectedMonthNo,
    required this.nextDueNo,
    required this.onSelectMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heatmapI18n = t.recurringDeposits.ledger.heatmap;
    final nextDue = nextDueNo;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedGrid,
                size: AppDimensions.iconSm,
              ),
              AppSpacings.gapXs,
              Flexible(
                child: Text(
                  heatmapI18n.title(months: totalMonths.toString()),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        AppSpacings.gapSm,
        Text(
          t.recurringDeposits.ledger.installmentDetails.monthShort(
            month: selectedMonthNo.toString(),
          ),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (nextDue != null && nextDue != selectedMonthNo) ...[
          AppSpacings.gapSm,
          ActionChip(
            visualDensity: VisualDensity.compact,
            avatar: HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: AppDimensions.iconXs,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              heatmapI18n.resetToNextDue(month: nextDue.toString()),
              style: theme.textTheme.labelSmall,
            ),
            onPressed: () => onSelectMonth(nextDue),
          ),
        ],
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final RDInstallment installment;
  final DateTime now;
  final bool isInspected;
  final bool isNextDue;
  final bool isSelectionMode;
  final bool isChecked;
  final VoidCallback onTap;

  const _HeatmapCell({
    required this.installment,
    required this.now,
    required this.isInspected,
    required this.isNextDue,
    required this.isSelectionMode,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visual = installment.displayStatusAt(now).visual(scheme);
    final monthNo = installment.installmentNo!;
    final isHighlighted = isInspected || isChecked;

    final border = isHighlighted
        ? Border.all(color: scheme.onSurface, width: AppDimensions.borderMd)
        : isNextDue
            ? Border.all(color: scheme.primary, width: AppDimensions.borderSm)
            : Border.all(color: scheme.outlineVariant, width: AppDimensions.borderSm);

    return Semantics(
      label: t.recurringDeposits.ledger.heatmap.tooltip(
        month: monthNo.toString(),
        date: installment.dueDate.toAppFormat(),
        status: visual.label,
      ),
      button: true,
      selected: isHighlighted,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: visual.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: border,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: visual.icon,
                    size: AppDimensions.iconXs,
                    color: visual.foreground,
                  ),
                  AppSpacings.gapXxs,
                  Text(
                    '$monthNo',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                      color: visual.foreground,
                    ),
                  ),
                ],
              ),
              if (isSelectionMode && isChecked)
                Positioned(
                  top: AppDimensions.paddingXxs,
                  right: AppDimensions.paddingXxs,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: AppDimensions.iconXs,
                    color: scheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  final List<RDInstallmentDisplayStatus> statuses;

  const _HeatmapLegend({required this.statuses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Wrap(
      spacing: AppDimensions.paddingSm,
      runSpacing: AppDimensions.paddingXs,
      children: [
        for (final status in statuses)
          Builder(
            builder: (context) {
              final visual = status.visual(scheme);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingXxs),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: HugeIcon(
                      icon: visual.icon,
                      size: AppDimensions.iconXs,
                      color: visual.foreground,
                    ),
                  ),
                  AppSpacings.gapXs,
                  Text(
                    visual.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
