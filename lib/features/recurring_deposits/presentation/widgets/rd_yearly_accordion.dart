import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Passbook month list: one group per schedule year in chronological order. A group is a
/// header row and, while the year is open, its months as grouped tiles below it.
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

  @override
  Widget build(BuildContext context) {
    // Bucketing walks every month; do it once per projection / clock tick, not per frame.
    final years = useMemoized(
      () => RDLedgerProjection.yearlyBucketsAt(installments, now),
      [installments, now],
    );
    final numYears = years.length;
    // With nothing due, the final year (where the last activity sits) is the "current" one.
    final currentYearIndex = nextDueNo == null
        ? numYears - 1
        : ((nextDueNo! - 1) ~/ _monthsPerYear).clamp(0, numYears - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final year in years) ...[
          if (year.yearIndex > 0) AppSpacings.gapSm,
          _YearSection(
            // Keeps each year's open/closed state while the passbook tab is rebuilt.
            key: PageStorageKey<String>('rd_${rdId}_year_${year.yearIndex}'),
            bucket: year,
            now: now,
            initiallyExpanded: year.yearIndex == currentYearIndex,
            onTapMonth: onTapMonth,
          ),
        ],
      ],
    );
  }
}

/// A year of the schedule: the header row toggles the month rows below it.
class _YearSection extends HookWidget {
  final RDScheduleYearBucket bucket;
  final DateTime now;
  final bool initiallyExpanded;
  final ValueChanged<RDInstallment> onTapMonth;

  const _YearSection({
    super.key,
    required this.bucket,
    required this.now,
    required this.initiallyExpanded,
    required this.onTapMonth,
  });

  /// Half a turn: the chevron points up while the year is open.
  static const double _openChevronTurns = 0.5;

  @override
  Widget build(BuildContext context) {
    final storage = PageStorage.maybeOf(context);
    final isExpanded = useState(
      (storage?.readState(context) as bool?) ?? initiallyExpanded,
    );

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settledColor = AppFinancialColors.of(context).settled.onContainer;
    final ledger = t.recurringDeposits.ledger;
    final localizations = MaterialLocalizations.of(context);
    final installments = bucket.months;
    final isYearSettled = bucket.isSettled;
    final isOpen = isExpanded.value;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    void toggle() {
      isExpanded.value = !isOpen;
      storage?.writeState(context, !isOpen);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          expanded: isOpen,
          onTapHint: isOpen
              ? localizations.expansionTileExpandedTapHint
              : localizations.expansionTileCollapsedTapHint,
          child: AppGroupTile(
            position: isOpen ? AppGroupPosition.first : AppGroupPosition.single,
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
                vertical: AppDimensions.paddingMd,
              ),
              child: Row(
                children: [
                  AppIcon(
                    isYearSettled
                        ? HugeIcons.strokeRoundedCheckmarkBadge01
                        : HugeIcons.strokeRoundedCalendar03,
                    size: AppDimensions.iconMd,
                    color: isYearSettled
                        ? settledColor
                        : scheme.onSurfaceVariant,
                  ),
                  AppSpacings.gapMd,
                  Expanded(
                    child: Text(
                      ledger.schedule.yearSummary(
                        year: (bucket.yearIndex + 1).toString(),
                        settled: bucket.settledCount.toString(),
                        total: installments.length.toString(),
                      ),
                      style: AppTypography.emphasizedOf(context).titleSmall
                          ?.copyWith(
                            color: isYearSettled
                                ? settledColor
                                : scheme.onSurface,
                          ),
                    ),
                  ),
                  AppSpacings.gapSm,
                  AnimatedRotation(
                    turns: isOpen ? _openChevronTurns : 0,
                    duration: disableAnimations
                        ? Duration.zero
                        : AppMotion.spatialFastDuration,
                    curve: AppMotion.spatialFastCurve,
                    child: AppIcon(
                      HugeIcons.strokeRoundedArrowDown01,
                      size: AppDimensions.iconMd,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The months unroll from under the header and roll back up into it; a closed year
        // builds none of its rows.
        AnimatedSwitcher(
          duration: disableAnimations
              ? Duration.zero
              : AppMotion.spatialFastDuration,
          switchInCurve: AppMotion.spatialFastCurve,
          switchOutCurve: AppMotion.spatialFastCurve.flipped,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            fit: StackFit.passthrough,
            children: [...previousChildren, ?currentChild],
          ),
          child: isOpen
              ? Column(
                  key: const ValueKey(true),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, inst) in installments.indexed) ...[
                      const SizedBox(height: AppShapes.groupGap),
                      RDInstallmentTile(
                        installment: inst,
                        now: now,
                        // The header is the group's first row, so a month is never first.
                        position: i == installments.length - 1
                            ? AppGroupPosition.last
                            : AppGroupPosition.middle,
                        onTap: () => onTapMonth(inst),
                      ),
                    ],
                  ],
                )
              : const SizedBox(key: ValueKey(false), width: double.infinity),
        ),
      ],
    );
  }
}
