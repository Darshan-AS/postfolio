import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/widgets/common/animated_figure.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_layout.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_po_visit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Scroll-away header of the Monthly Hub: the month switcher and one block of four KPI
/// tiles (To collect · In hand · Receivable · Arrears). Three tiles set a list filter;
/// "In hand" opens the Post Office visit planner. Rebuilds only on month / KPI changes —
/// never on a search keystroke.
class RDHubHeader extends ConsumerWidget {
  const RDHubHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(rDHubMonthProvider);
    final now = ref.watch(clockProvider)();
    final monthNotifier = ref.read(rDHubMonthProvider.notifier);
    final isLoading = ref.watch(
      monthlyOperationItemsProvider.select((a) => a.isLoading),
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
        // 12dp between the Hub's blocks: switcher, tiles, search, due window, rows.
        AppSpacings.gapMd,
        Skeletonizer(enabled: isLoading, child: const _KpiGrid()),
        AppSpacings.gapSm,
      ],
    );
  }
}

/// The four tiles: every tile's colours come from the matching `RDStatusVisual`, so the
/// header can never contradict the row pills.
///
/// Two across on a phone, four across once each tile would still be as wide as on a phone,
/// and one per row at large text sizes, where half the width cuts the labels.
class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();

  /// From this width the four tiles fit in one row.
  static const double _singleRowMinWidth = AppDimensions.maxFormWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ops = t.recurringDeposits.monthlyOperations;
    final strings = ops.kpis;

    final kpis = ref.watch(monthlyOperationsKpiProvider);
    final float = ref.watch(globalAgentFloatProvider);
    final statusFilter = ref.watch(
      rDHubFiltersProvider.select((s) => s.status),
    );
    final isBusy = ref.watch(
      rDLedgerControllerProvider.select((a) => a.isLoading),
    );
    final filters = ref.read(rDHubFiltersProvider.notifier);

    void toggle(RDMonthlyFilter filter) => filters.setStatus(
      statusFilter == filter ? RDMonthlyFilter.all : filter,
    );

    void planVisit() {
      ref.read(rDPoVisitPlannerProvider.notifier).start();
      showRDPoVisitPlanner(context);
    }

    // Nothing to report: a plain container resting on the page.
    final RDStatusVisual neutral = (
      foreground: scheme.onSurfaceVariant,
      background: scheme.raised,
      outline: null,
      emphasized: false,
      icon: HugeIcons.strokeRoundedCoins01,
      label: '',
    );

    // To collect: red only when something is actually overdue. Money that is merely
    // upcoming has nothing to flag, so its tile stays the plain container.
    final toCollectVisual = kpis.toCollectCount > 0 && kpis.overdueCount > 0
        ? RDInstallmentDisplayStatus.overdue.visualOf(context)
        : neutral;
    final inHandVisual = float.cashInHandAccounts > 0
        ? RDInstallmentDisplayStatus.collectedPendingPo.visualOf(context)
        : neutral;
    final receivableVisual = float.receivableAccounts > 0
        ? RDInstallmentDisplayStatus.frontedByAgent.visualOf(context)
        : neutral;
    final arrearsVisual = float.arrearsAccounts > 0
        ? RDInstallmentDisplayStatus.overdue.visualOf(context)
        : neutral;

    // A figure counts to its new value when something is collected or deposited. Another
    // month's figure is another quantity and is shown at once.
    final month = ref.watch(rDHubMonthProvider);
    String rupees(double value) => value.toRupeeFormat();

    final tiles = <Widget>[
      _KpiTile(
        label: strings.toCollect,
        amount: kpis.toCollectAmount.toRupeeFormat(),
        figure: (value: kpis.toCollectAmount, format: rupees, of: month),
        caption: strings.accountsCount(n: kpis.toCollectCount),
        count: kpis.toCollectCount,
        visual: toCollectVisual,
        isSelected: statusFilter == RDMonthlyFilter.toCollect,
        onTap: () => toggle(RDMonthlyFilter.toCollect),
        hint: strings.filterHint(label: strings.toCollect),
      ),
      _KpiTile(
        label: strings.inHand,
        amount: float.cashInHandTotal.toRupeeFormat(),
        figure: (value: float.cashInHandTotal, format: rupees, of: month),
        caption: float.cashInHandAccounts > 0
            ? strings.accountsReady(n: float.cashInHandAccounts)
            : strings.nothingToDeposit,
        detail: float.cashInHandAccounts > 0
            ? ops.visit.byMode(
                cash: float.cashInHandCash.toRupeeFormat(),
                digital: float.cashInHandDigital.toRupeeFormat(),
              )
            : null,
        count: float.cashInHandAccounts,
        visual: inHandVisual,
        isSelected: false,
        opensPlanner: true,
        // Always reachable: fronting from pocket is planned here even when
        // nothing has been collected yet.
        onTap: isBusy ? null : planVisit,
        hint: strings.plannerHint,
      ),
      _KpiTile(
        label: strings.receivable,
        amount: float.receivableAmount.toRupeeFormat(),
        figure: (value: float.receivableAmount, format: rupees, of: month),
        caption: strings.accountsCount(n: float.receivableAccounts),
        count: float.receivableAccounts,
        visual: receivableVisual,
        isSelected: statusFilter == RDMonthlyFilter.fronted,
        onTap: () => toggle(RDMonthlyFilter.fronted),
        hint: strings.filterHint(label: strings.receivable),
      ),
      _KpiTile(
        label: strings.arrears,
        amount: strings.accountsCount(n: float.arrearsAccounts),
        figure: (
          value: float.arrearsAccounts.toDouble(),
          format: (value) => strings.accountsCount(n: value.round()),
          of: month,
        ),
        caption: strings.arrearsCaption,
        visual: arrearsVisual,
        isSelected: statusFilter == RDMonthlyFilter.overdue,
        onTap: () => toggle(RDMonthlyFilter.overdue),
        hint: strings.filterHint(label: strings.arrears),
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

/// One tappable KPI tile: a tonal container in its status colours. Money is never
/// ellipsised — it shrinks to fit.
///
/// Two lines: the label with the number of accounts, then the figure. The header sits
/// above the list the agent works through, so it stays short; [caption] and [detail] are
/// read out with the tile but not drawn, and the cash / UPI split is in the visit planner.
/// The count is a number beside an icon: "125 accounts" would not fit beside "Receivable".
///
/// A selected filter swaps the tile's two colours, so the fill turns solid while the
/// contrast stays that of the tested pair, and gains a tick; it does not rely on a border.
class _KpiTile extends StatelessWidget {
  final String label;

  /// The figure as it is announced, and as it is drawn when [figure] is null.
  final String amount;

  /// The figure as a number, so that it counts to a new value (see [AnimatedFigure]).
  final ({double value, String Function(double value) format, Object? of})? figure;

  /// Announced after the figure.
  final String caption;

  /// Announced between the figure and the caption.
  final String? detail;

  /// Number of accounts behind the figure, shown at the end of the label's line. Null
  /// where the figure is itself a count.
  final int? count;
  final RDStatusVisual visual;
  final bool isSelected;

  /// The tile opens the Post Office visit planner instead of filtering the list.
  final bool opensPlanner;
  final VoidCallback? onTap;

  /// Screen-reader hint describing what a tap does (filter / open planner).
  final String? hint;

  const _KpiTile({
    required this.label,
    required this.amount,
    this.figure,
    required this.caption,
    this.detail,
    this.count,
    required this.visual,
    required this.isSelected,
    this.opensPlanner = false,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasized = AppTypography.emphasizedOf(context);
    final kpis = t.recurringDeposits.monthlyOperations.kpis;

    final background = isSelected ? visual.foreground : visual.background;
    final foreground = isSelected ? visual.background : visual.foreground;
    final trailingIcon = isSelected
        ? HugeIcons.strokeRoundedTick02
        : opensPlanner
        ? HugeIcons.strokeRoundedArrowRight01
        : null;

    // One node per tile: "<label>, <amount>[, <detail>], <caption>" + what a tap does.
    final semanticLabel = detail == null
        ? kpis.tileSemantics(label: label, amount: amount, caption: caption)
        : kpis.tileSemanticsDetail(
            label: label,
            amount: amount,
            detail: detail!,
            caption: caption,
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
            // 16dp at the sides, as in the rows below: a tile's text starts on the same
            // edge as a row's avatar and pill.
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
                    // The label gives way first; the count beside it is never cut.
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
                FittedBox(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
