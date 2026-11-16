import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Visual vocabulary for an installment month. Every heatmap cell, tile, inspector row, hub
/// pill and hub KPI tile derives colour/icon/label from here so they can never disagree.
///
/// Active financial statuses resolve from [AppFinancialColors] so no two statuses share a
/// container colour and OS wallpaper dynamic colors never invert status semantics.
typedef RDStatusVisual = ({
  Color foreground,
  Color background,

  /// Drawn as a border when set (used to separate "due today" from "upcoming").
  Color? outline,

  /// Label weight hint for pills.
  bool emphasized,
  List<List<dynamic>> icon,
  String label,
});

extension RDInstallmentDisplayStatusTheme on RDInstallmentDisplayStatus {
  RDStatusVisual visualOf(BuildContext context) {
    final theme = Theme.of(context);
    return visual(
      theme.colorScheme,
      financial: AppFinancialColors.of(context),
    );
  }

  RDStatusVisual visual(
    ColorScheme scheme, {
    AppFinancialColors? financial,
  }) {
    final palette = financial ?? AppFinancialColors.forBrightness(scheme.brightness);
    final s = t.recurringDeposits.ledger.statuses;
    return switch (this) {
      RDInstallmentDisplayStatus.baseline => (
        foreground: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHigh,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedLockKey,
        label: s.baseline,
      ),
      RDInstallmentDisplayStatus.settled => (
        foreground: palette.settled.onContainer,
        background: palette.settled.container,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        label: s.settled,
      ),
      RDInstallmentDisplayStatus.collectedPendingPo => (
        foreground: palette.inHand.onContainer,
        background: palette.inHand.container,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedCoins01,
        label: s.collectedPendingPo,
      ),
      RDInstallmentDisplayStatus.partiallyPaid => (
        foreground: palette.partial.onContainer,
        background: palette.partial.container,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedChartRing,
        label: s.partiallyPaid,
      ),
      RDInstallmentDisplayStatus.frontedByAgent => (
        foreground: palette.fronted.onContainer,
        background: palette.fronted.container,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedWallet02,
        label: s.frontedByAgent,
      ),
      RDInstallmentDisplayStatus.overdue => (
        foreground: palette.overdue.onContainer,
        background: palette.overdue.container,
        outline: null,
        emphasized: true,
        icon: HugeIcons.strokeRoundedAlert01,
        label: s.overdue,
      ),
      RDInstallmentDisplayStatus.dueToday => (
        foreground: scheme.primary,
        background: scheme.surface,
        outline: scheme.primary,
        emphasized: true,
        icon: HugeIcons.strokeRoundedTimer02,
        label: s.dueToday,
      ),
      RDInstallmentDisplayStatus.upcoming => (
        foreground: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerLow,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedCalendar02,
        label: s.upcoming,
      ),
    };
  }

  /// High-contrast solid accent colour (`>= 3:1` against surface) for left-edge indicator bars
  /// and active status markers.
  Color accent(
    ColorScheme scheme, {
    AppFinancialColors? financial,
  }) {
    final palette = financial ?? AppFinancialColors.forBrightness(scheme.brightness);
    return switch (this) {
      RDInstallmentDisplayStatus.settled => palette.settled.accent,
      RDInstallmentDisplayStatus.collectedPendingPo => palette.inHand.accent,
      RDInstallmentDisplayStatus.partiallyPaid => palette.partial.accent,
      RDInstallmentDisplayStatus.frontedByAgent => palette.fronted.accent,
      RDInstallmentDisplayStatus.overdue => palette.overdue.accent,
      RDInstallmentDisplayStatus.dueToday => scheme.primary,
      RDInstallmentDisplayStatus.baseline => scheme.outline,
      RDInstallmentDisplayStatus.upcoming => scheme.outlineVariant,
    };
  }
}
