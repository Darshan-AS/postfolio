import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Visual vocabulary for an installment month. Every heatmap cell, tile, inspector row and
/// hub pill derives colour/icon/label from here so they can never disagree.
///
/// Colour semantics:
/// * primary   — money is with the agent / collected (`collectedPendingPo`)
/// * tertiary  — settled at the PO (`settled`)
/// * secondary — partial progress (`partiallyPaid`, `frontedByAgent`)
/// * error     — customer is in default (`overdue`)
/// * outline   — nothing to do yet (`upcoming`, `dueToday`, `baseline`)
typedef RDStatusVisual = ({
  Color foreground,
  Color background,
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
          icon: HugeIcons.strokeRoundedLockKey,
          label: s.baseline,
        ),
      RDInstallmentDisplayStatus.settled => (
          foreground: scheme.onTertiaryContainer,
          background: scheme.tertiaryContainer,
          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
          label: s.settled,
        ),
      RDInstallmentDisplayStatus.collectedPendingPo => (
          foreground: scheme.onPrimaryContainer,
          background: scheme.primaryContainer,
          icon: HugeIcons.strokeRoundedCoins01,
          label: s.collectedPendingPo,
        ),
      RDInstallmentDisplayStatus.partiallyPaid => (
          foreground: scheme.onSecondaryContainer,
          background: scheme.secondaryContainer,
          icon: HugeIcons.strokeRoundedChartRing,
          label: s.partiallyPaid,
        ),
      RDInstallmentDisplayStatus.frontedByAgent => (
          foreground: scheme.onSecondaryContainer,
          background: scheme.secondaryContainer,
          icon: HugeIcons.strokeRoundedWallet02,
          label: s.frontedByAgent,
        ),
      RDInstallmentDisplayStatus.overdue => (
          foreground: scheme.onErrorContainer,
          background: scheme.errorContainer,
          icon: HugeIcons.strokeRoundedAlert01,
          label: s.overdue,
        ),
      RDInstallmentDisplayStatus.dueToday => (
          foreground: scheme.onSurface,
          background: scheme.surfaceContainerHighest,
          icon: HugeIcons.strokeRoundedTimer02,
          label: s.dueToday,
        ),
      RDInstallmentDisplayStatus.upcoming => (
          foreground: scheme.onSurfaceVariant,
          background: scheme.surfaceContainerLow,
          icon: HugeIcons.strokeRoundedCalendar02,
          label: s.upcoming,
        ),
    };
  }

  /// Flat accent colour (for heatmap cells, indicator bars) — the container colour above.
  Color accent(ColorScheme scheme) => visual(scheme).background;
}
