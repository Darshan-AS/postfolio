import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Visual vocabulary for an installment month. Every heatmap cell, tile, inspector row, hub
/// pill and hub KPI tile derives colour/icon/label from here so they can never disagree.
///
/// Colour semantics — no two statuses share a container colour:
/// * primaryContainer        — settled at the PO (`settled`), muted success
/// * secondaryContainer      — money is with the agent, waiting for the PO (`collectedPendingPo`)
/// * secondaryFixedDim       — partial progress (`partiallyPaid`)
/// * tertiaryContainer       — agent's own money is out (`frontedByAgent`)
/// * errorContainer          — customer is in default (`overdue`)
/// * surface + outline, bold — due today (`dueToday`)
/// * surfaceContainerLow     — nothing to do yet (`upcoming`)
/// * surfaceContainerHigh    — immutable history (`baseline`)
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
  RDStatusVisual visual(ColorScheme scheme) {
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
        foreground: scheme.onPrimaryContainer,
        background: scheme.primaryContainer,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        label: s.settled,
      ),
      RDInstallmentDisplayStatus.collectedPendingPo => (
        foreground: scheme.onSecondaryContainer,
        background: scheme.secondaryContainer,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedCoins01,
        label: s.collectedPendingPo,
      ),
      RDInstallmentDisplayStatus.partiallyPaid => (
        foreground: scheme.onSecondaryFixedVariant,
        background: scheme.secondaryFixedDim,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedChartRing,
        label: s.partiallyPaid,
      ),
      RDInstallmentDisplayStatus.frontedByAgent => (
        foreground: scheme.onTertiaryContainer,
        background: scheme.tertiaryContainer,
        outline: null,
        emphasized: false,
        icon: HugeIcons.strokeRoundedWallet02,
        label: s.frontedByAgent,
      ),
      RDInstallmentDisplayStatus.overdue => (
        foreground: scheme.onErrorContainer,
        background: scheme.errorContainer,
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

  /// Flat accent colour (for heatmap cells, indicator bars) — the container colour above,
  /// or the outline when the status is drawn as an outlined pill.
  Color accent(ColorScheme scheme) {
    final v = visual(scheme);
    return v.outline ?? v.background;
  }
}
