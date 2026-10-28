import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// One schedule year, bucketed once per projection.
typedef _YearBucket = ({
  int yearIndex,
  List<RDInstallment> months,
  int settledCount,
  bool isSettled,
});

/// Passbook month list: one `ExpansionTile` per schedule year in chronological order.
///
/// The year holding the next due month starts expanded; years made only of opening
/// baseline months (and fully settled/upcoming years) start collapsed.
class RDYearlyAccordion extends HookWidget {
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

  static List<_YearBucket> _bucket(List<RDInstallment> installments, DateTime now) {
    final numYears = (installments.length / _monthsPerYear).ceil();
    final buckets = <_YearBucket>[];
    for (var y = 0; y < numYears; y++) {
      final months = installments.sublist(
        y * _monthsPerYear,
        ((y + 1) * _monthsPerYear).clamp(0, installments.length),
      );
      final settledCount = months.where((inst) {
        final status = inst.displayStatusAt(now);
        return status == RDInstallmentDisplayStatus.settled ||
            status == RDInstallmentDisplayStatus.baseline;
      }).length;
      buckets.add((
        yearIndex: y,
        months: months,
        settledCount: settledCount,
        isSettled: settledCount == months.length,
      ));
    }
    return List.unmodifiable(buckets);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Bucketing walks every month; do it once per projection / clock tick, not per frame.
    final years = useMemoized(() => _bucket(installments, now), [installments, now]);
    final numYears = years.length;
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
          for (final year in years) ...[
            _YearSection(
              rdId: rdId,
              bucket: year,
              now: now,
              initiallyExpanded: year.yearIndex == currentYearIndex,
              onTapMonth: onTapMonth,
            ),
            if (year.yearIndex < numYears - 1)
              const Divider(height: AppDimensions.dividerHeight),
          ],
        ],
      ),
    );
  }
}

class _YearSection extends StatelessWidget {
  final String rdId;
  final _YearBucket bucket;
  final DateTime now;
  final bool initiallyExpanded;
  final ValueChanged<RDInstallment> onTapMonth;

  const _YearSection({
    required this.rdId,
    required this.bucket,
    required this.now,
    required this.initiallyExpanded,
    required this.onTapMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final installments = bucket.months;
    final isYearSettled = bucket.isSettled;
    final titleColor = isYearSettled ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return ExpansionTile(
      key: PageStorageKey<String>('rd_${rdId}_year_${bucket.yearIndex}'),
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
          year: (bucket.yearIndex + 1).toString(),
          settled: bucket.settledCount.toString(),
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
