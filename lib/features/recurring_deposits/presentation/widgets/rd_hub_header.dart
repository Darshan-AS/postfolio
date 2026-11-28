import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/widgets/common/animated_figure.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_layout.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_month_progress.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Scroll-away header of the Monthly Hub: the month switcher and four uniform,
/// non-overlapping KPI filter tiles (To collect · In hand · Paid to PO · Receivable).
/// Rebuilds only on month / KPI changes — never on a search keystroke.
class RDHubHeader extends ConsumerWidget {
  const RDHubHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(rDHubMonthProvider);
    final now = ref.watch(currentDateProvider);
    final monthNotifier = ref.read(rDHubMonthProvider.notifier);
    final isLoading = ref.watch(
      monthlyOperationItemsProvider.select((a) => a.isLoading),
    );
    final progress = ref.watch(
      monthlyOperationsKpiProvider.select(
        (k) => (settled: k.settledCount, total: k.totalCount),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacings.gapXs,
        RDMonthSwitcher(
          selectedMonth: month,
          isCurrentMonth: month == now.toMonthStart(),
          onPrevious: monthNotifier.previousMonth,
          onNext: monthNotifier.nextMonth,
          onResetToCurrent: monthNotifier.resetToCurrentMonth,
          onPickMonth: monthNotifier.setMonth,
        ),
        AppSpacings.gapMd,
        if (!isLoading)
          RDHubMonthProgress(
            key: ValueKey(month),
            month: month,
            settled: progress.settled,
            total: progress.total,
            isPast: month.isBefore(now.toMonthStart()),
          ),
        Skeletonizer(enabled: isLoading, child: const _KpiGrid()),
        AppSpacings.gapSm,
      ],
    );
  }
}

/// Four uniform filter tiles: every tile filters the Hub list when tapped and resets
/// when tapped again.
class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();

  /// From this width the four tiles fit in one row.
  static const double _singleRowMinWidth = AppDimensions.maxFormWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final financial = AppFinancialColors.of(context);
    final strings = t.recurringDeposits.monthlyOperations.kpis;

    final kpis = ref.watch(monthlyOperationsKpiProvider);
    final statusFilter = ref.watch(
      rDHubFiltersProvider.select((s) => s.status),
    );
    final now = ref.watch(currentDateProvider);
    final month = ref.watch(rDHubMonthProvider);
    final isFutureMonth = month.isAfter(now.toMonthStart());
    final filters = ref.read(rDHubFiltersProvider.notifier);

    void toggle(RDMonthlyFilter filter) => filters.setStatus(
      statusFilter == filter ? RDMonthlyFilter.all : filter,
    );

    ({Color background, Color foreground}) colorsOf(
      RDInstallmentDisplayStatus status,
      bool active,
    ) {
      if (!active) {
        return (background: scheme.raised, foreground: scheme.onSurfaceVariant);
      }
      final visual = status.visualOf(context);
      return (background: visual.background, foreground: visual.foreground);
    }

    String rupees(double value) => value.toRupeeFormat();
    final overdueBadge = !isFutureMonth && kpis.overdueCount > 0
        ? strings.overdueBadge(n: kpis.overdueCount)
        : null;

    final tiles = <Widget>[
      _KpiTile(
        label: strings.toCollect,
        amount: kpis.toCollectAmount.toRupeeFormat(),
        figure: (value: kpis.toCollectAmount, format: rupees, of: month),
        caption: strings.accountsCount(n: kpis.toCollectCount),
        detail: overdueBadge,
        count: kpis.toCollectCount,
        badgeText: overdueBadge,
        badgeBackground: financial.overdue.accent,
        badgeForeground: financial.overdue.onAccent,
        badgeSelectedBackground: financial.overdue.container,
        badgeSelectedForeground: financial.overdue.onContainer,
        colors: kpis.toCollectCount > 0
            ? (
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
              )
            : (background: scheme.raised, foreground: scheme.onSurfaceVariant),
        isSelected: statusFilter == RDMonthlyFilter.toCollect,
        onTap: () => toggle(RDMonthlyFilter.toCollect),
        hint: strings.filterHint(label: strings.toCollect),
      ),
      _KpiTile(
        label: strings.inHand,
        amount: kpis.readyForPoAmount.toRupeeFormat(),
        figure: (value: kpis.readyForPoAmount, format: rupees, of: month),
        caption: kpis.readyForPoCount > 0
            ? strings.accountsReady(n: kpis.readyForPoCount)
            : strings.nothingToDeposit,
        count: kpis.readyForPoCount,
        colors: colorsOf(
          RDInstallmentDisplayStatus.collectedPendingPo,
          kpis.readyForPoCount > 0,
        ),
        isSelected: statusFilter == RDMonthlyFilter.readyForPo,
        onTap: () => toggle(RDMonthlyFilter.readyForPo),
        hint: strings.filterHint(label: strings.inHand),
      ),
      _KpiTile(
        label: strings.paidToPo,
        amount: kpis.settledAmount.toRupeeFormat(),
        figure: (value: kpis.settledAmount, format: rupees, of: month),
        caption: strings.accountsCount(n: kpis.settledCount),
        count: kpis.settledCount,
        colors: colorsOf(
          RDInstallmentDisplayStatus.settled,
          kpis.settledCount > 0,
        ),
        isSelected: statusFilter == RDMonthlyFilter.settled,
        onTap: () => toggle(RDMonthlyFilter.settled),
        hint: strings.filterHint(label: strings.paidToPo),
      ),
      _KpiTile(
        label: strings.receivable,
        amount: kpis.receivableAmount.toRupeeFormat(),
        figure: (value: kpis.receivableAmount, format: rupees, of: month),
        caption: strings.accountsCount(n: kpis.receivableCount),
        count: kpis.receivableCount,
        colors: colorsOf(
          RDInstallmentDisplayStatus.paidFromPocket,
          kpis.receivableCount > 0,
        ),
        isSelected: statusFilter == RDMonthlyFilter.receivable,
        onTap: () => toggle(RDMonthlyFilter.receivable),
        hint: strings.filterHint(label: strings.receivable),
      ),
    ];

    final largeText = RDHubLayout.isLargeText(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageMargin),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = largeText
              ? 1
              : constraints.maxWidth >= _singleRowMinWidth
              ? tiles.length
              : 2;
          return _TileRows(columns: columns, tiles: tiles);
        },
      ),
    );
  }
}

/// Lays [tiles] out [columns] across; tiles that share a row share its height.
class _TileRows extends StatelessWidget {
  const _TileRows({required this.columns, required this.tiles});

  final int columns;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) AppSpacings.gapSm,
            tiles[i],
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var start = 0; start < tiles.length; start += columns) ...[
          if (start > 0) AppSpacings.gapSm,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (
                  var i = start;
                  i < start + columns && i < tiles.length;
                  i++
                ) ...[
                  if (i > start) AppSpacings.gapSm,
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One tappable KPI filter tile: a tonal container in its status colours.
class _KpiTile extends StatelessWidget {
  static const int _kpiAmountFlex = 5;
  static const int _kpiBadgeFlex = 4;

  final String label;
  final String amount;
  final ({double value, String Function(double value) format, Object? of})?
  figure;
  final String caption;
  final String? detail;
  final int? count;
  final String? badgeText;
  final Color? badgeBackground;
  final Color? badgeForeground;
  final Color? badgeSelectedBackground;
  final Color? badgeSelectedForeground;
  final ({Color background, Color foreground}) colors;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? hint;

  const _KpiTile({
    required this.label,
    required this.amount,
    this.figure,
    required this.caption,
    this.detail,
    this.count,
    this.badgeText,
    this.badgeBackground,
    this.badgeForeground,
    this.badgeSelectedBackground,
    this.badgeSelectedForeground,
    required this.colors,
    required this.isSelected,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final kpis = t.recurringDeposits.monthlyOperations.kpis;
    final largeText = RDHubLayout.isLargeText(context);

    final background = isSelected ? colors.foreground : colors.background;
    final foreground = isSelected ? colors.background : colors.foreground;
    final trailingIcon = isSelected ? HugeIcons.strokeRoundedTick02 : null;

    final semanticLabel = detail == null
        ? kpis.tileSemantics(label: label, amount: amount, caption: caption)
        : kpis.tileSemanticsDetail(
            label: label,
            amount: amount,
            detail: detail!,
            caption: caption,
          );

    final figureWidget = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: switch (figure) {
        null => Text(
          amount,
          style: emphasized.titleLarge?.copyWith(color: foreground),
          maxLines: 1,
        ),
        final figure => AnimatedFigure(
          value: figure.value,
          format: figure.format,
          of: figure.of,
          style: emphasized.titleLarge?.copyWith(color: foreground),
        ),
      },
    );

    final badgePill = badgeText == null
        ? null
        : Material(
            color: isSelected
                ? (badgeSelectedBackground ?? colors.background)
                : (badgeBackground ?? scheme.error),
            shape: AppShapes.pill,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSm,
                vertical: AppDimensions.paddingXxs,
              ),
              child: Text(
                badgeText!,
                maxLines: 1,
                style: emphasized.labelSmall?.copyWith(
                  color: isSelected
                      ? (badgeSelectedForeground ?? colors.foreground)
                      : (badgeForeground ?? scheme.onError),
                ),
              ),
            ),
          );

    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      selected: isSelected,
      label: semanticLabel,
      hint: hint,
      child: ExcludeSemantics(
        child: AppGroupTile(
          color: background,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
              vertical: AppDimensions.paddingSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style:
                            (isSelected
                                    ? emphasized.labelLarge
                                    : theme.textTheme.labelLarge)
                                ?.copyWith(color: foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count != null) ...[
                      AppSpacings.gapXs,
                      AppIcon(
                        HugeIcons.strokeRoundedUser,
                        size: AppDimensions.iconXs,
                        color: foreground,
                      ),
                      AppSpacings.gapXxs,
                      Text(
                        '$count',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                        ),
                        maxLines: 1,
                      ),
                    ],
                    if (trailingIcon != null) ...[
                      AppSpacings.gapXs,
                      AppIcon(
                        trailingIcon,
                        size: AppDimensions.iconSm,
                        color: foreground,
                        emphasized: isSelected,
                      ),
                    ],
                  ],
                ),
                if (badgePill == null)
                  figureWidget
                else if (largeText) ...[
                  figureWidget,
                  AppSpacings.gapXxs,
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: badgePill,
                  ),
                ] else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: _kpiAmountFlex, child: figureWidget),
                      AppSpacings.gapXs,
                      Flexible(
                        flex: _kpiBadgeFlex,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: badgePill,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
