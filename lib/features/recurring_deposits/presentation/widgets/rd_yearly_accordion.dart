import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Yearly List mode: one `ExpansionTile` per schedule year.
class RDYearlyAccordion extends StatelessWidget {
  final String rdId;
  final List<RDInstallment> installments;
  final DateTime now;
  final bool isSelectionMode;
  final Set<int> selectedNos;
  final bool isBusy;
  final ValueChanged<int> onToggleSelection;

  const RDYearlyAccordion({
    super.key,
    required this.rdId,
    required this.installments,
    required this.now,
    required this.isSelectionMode,
    required this.selectedNos,
    required this.isBusy,
    required this.onToggleSelection,
  });

  static const int _monthsPerYear = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numYears = (installments.length / _monthsPerYear).ceil();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          for (var y = 0; y < numYears; y++) ...[
            _YearSection(
              rdId: rdId,
              yearIndex: y,
              installments: installments.sublist(
                y * _monthsPerYear,
                ((y + 1) * _monthsPerYear).clamp(0, installments.length),
              ),
              now: now,
              isSelectionMode: isSelectionMode,
              selectedNos: selectedNos,
              isBusy: isBusy,
              onToggleSelection: onToggleSelection,
            ),
            if (y < numYears - 1) const Divider(height: AppDimensions.dividerHeight),
          ],
        ],
      ),
    );
  }
}

class _YearSection extends StatelessWidget {
  final String rdId;
  final int yearIndex;
  final List<RDInstallment> installments;
  final DateTime now;
  final bool isSelectionMode;
  final Set<int> selectedNos;
  final bool isBusy;
  final ValueChanged<int> onToggleSelection;

  const _YearSection({
    required this.rdId,
    required this.yearIndex,
    required this.installments,
    required this.now,
    required this.isSelectionMode,
    required this.selectedNos,
    required this.isBusy,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    final settledCount = installments.where((inst) {
      final status = inst.displayStatusAt(now);
      return status == RDInstallmentDisplayStatus.settled ||
          status == RDInstallmentDisplayStatus.baseline;
    }).length;
    final isYearSettled = settledCount == installments.length;
    final titleColor = isYearSettled ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return ExpansionTile(
      key: PageStorageKey<String>('rd_${rdId}_year_$yearIndex'),
      initiallyExpanded: isSelectionMode || !isYearSettled,
      leading: HugeIcon(
        icon: isYearSettled
            ? HugeIcons.strokeRoundedCheckmarkBadge01
            : HugeIcons.strokeRoundedCalendar03,
        size: AppDimensions.iconSm,
        color: isYearSettled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        ledger.schedule.yearSummary(
          year: (yearIndex + 1).toString(),
          settled: settledCount.toString(),
          total: installments.length.toString(),
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
      ),
      children: [
        for (final (i, inst) in installments.indexed) ...[
          RDInstallmentTile(
            rdId: rdId,
            installment: inst,
            now: now,
            isSelectionMode: isSelectionMode,
            isSelected: selectedNos.contains(inst.installmentNo),
            isBusy: isBusy,
            onSelectionChanged: inst.isOpeningBaseline
                ? null
                : (_) => onToggleSelection(inst.installmentNo!),
          ),
          if (i < installments.length - 1)
            const Divider(height: AppDimensions.dividerHeight),
        ],
      ],
    );
  }
}
