import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Passbook month list: one `ExpansionTile` per schedule year in chronological order.
///
/// The year holding the next due month starts expanded; years made only of opening
/// baseline months (and fully settled/upcoming years) start collapsed.
class RDYearlyAccordion extends StatelessWidget {
  final String rdId;
  final List<RDInstallment> installments;
  final DateTime now;

  /// The month the customer owes on next (`null` when everything is paid).
  final int? nextDueNo;
  final ValueChanged<RDInstallment> onTapMonth;

  const RDYearlyAccordion({
    super.key,
    required this.rdId,
    required this.installments,
    required this.now,
    required this.nextDueNo,
    required this.onTapMonth,
  });

  static const int _monthsPerYear = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numYears = (installments.length / _monthsPerYear).ceil();
    // With nothing due, the final year (where the last activity sits) is the "current" one.
    final currentYearIndex = nextDueNo == null
        ? numYears - 1
        : ((nextDueNo! - 1) ~/ _monthsPerYear).clamp(0, numYears - 1);

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
              initiallyExpanded: y == currentYearIndex,
              onTapMonth: onTapMonth,
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
  final bool initiallyExpanded;
  final ValueChanged<RDInstallment> onTapMonth;

  const _YearSection({
    required this.rdId,
    required this.yearIndex,
    required this.installments,
    required this.now,
    required this.initiallyExpanded,
    required this.onTapMonth,
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
      initiallyExpanded: initiallyExpanded,
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
            installment: inst,
            now: now,
            onTap: () => onTapMonth(inst),
          ),
          if (i < installments.length - 1)
            const Divider(height: AppDimensions.dividerHeight),
        ],
      ],
    );
  }
}
