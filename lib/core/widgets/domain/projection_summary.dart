import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';

/// One input of a projection: a label with its amount, optionally led by the arithmetic sign
/// that joins it to the line above.
class ProjectionLine {
  const ProjectionLine({
    required this.label,
    required this.amount,
    this.sign,
    this.color,
    this.onColor,
    this.heroTag,
  });

  final String label;
  final double amount;

  /// Set on the line whose amount is the one on the deposit's row: it travels here from
  /// the row that opened the screen (`EntityHero.tagFrom`).
  final Object? heroTag;

  /// The sign in front of the label, e.g. a plus.
  final AppIconData? sign;

  /// Tints the row; both default to the group's neutral surface and text colours.
  final Color? color;
  final Color? onColor;
}

/// A projection shown as one grouped block: the input [lines] on top, read like the lines of
/// a sum, and the outcome below them as the largest and most saturated tile.
///
/// Every amount stays on one line. An input row gives its amount the width it needs and lets
/// the label wrap; with large text the amount moves under its label instead.
class ProjectionSummary extends StatelessWidget {
  const ProjectionSummary({
    super.key,
    required this.lines,
    required this.resultLabel,
    required this.resultAmount,
    this.resultSign,
    this.resultDescription,
  });

  final List<ProjectionLine> lines;
  final String resultLabel;
  final double resultAmount;

  /// The sign in front of the result, e.g. an equals sign.
  final AppIconData? resultSign;

  /// A sentence under the result amount.
  final String? resultDescription;

  /// Above this text scale an input row puts its amount under the label.
  static const double _stackAboveTextScale = AppDimensions.largeTextScale;

  /// Share of an input row the amount may take before it is scaled down.
  static const double _amountMaxShare = 0.6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // When any row carries a sign, every row keeps the slot so the labels line up.
    final hasSigns = resultSign != null || lines.any((l) => l.sign != null);
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          AppGroupTile(
            position: AppGroupPosition.at(i, lines.length + 1),
            color: lines[i].color,
            child: _LineRow(
              line: lines[i],
              reserveSignSlot: hasSigns,
              stacked: stacked,
              amountMaxShare: _amountMaxShare,
            ),
          ),
          const SizedBox(height: AppShapes.groupGap),
        ],
        AppGroupTile(
          position: AppGroupPosition.at(lines.length, lines.length + 1),
          color: scheme.primary,
          child: _ResultRow(
            label: resultLabel,
            amount: resultAmount,
            sign: resultSign,
            description: resultDescription,
            reserveSignSlot: hasSigns,
            color: scheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

/// The leading slot that holds a row's arithmetic sign, or keeps its place when the row has
/// none.
class _SignSlot extends StatelessWidget {
  const _SignSlot({required this.sign, required this.color});

  final AppIconData? sign;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppDimensions.paddingMd),
      child: SizedBox.square(
        dimension: AppDimensions.iconMd,
        child: sign == null
            ? null
            : AppIcon(
                sign!,
                size: AppDimensions.iconMd,
                color: color,
                emphasized: true,
              ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.reserveSignSlot,
    required this.stacked,
    required this.amountMaxShare,
  });

  final ProjectionLine line;
  final bool reserveSignSlot;
  final bool stacked;
  final double amountMaxShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelColor = line.onColor ?? scheme.onSurfaceVariant;
    final amountColor = line.onColor ?? scheme.onSurface;

    final label = Text(
      line.label,
      style: theme.textTheme.bodyLarge?.copyWith(color: labelColor),
    );

    Widget amount(AlignmentGeometry alignment) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: EntityHero(
        tag: line.heroTag,
        part: EntityHeroPart.amount,
        child: Text(
          line.amount.toRupeeFormat(),
          maxLines: 1,
          style: AppTypography.emphasizedOf(
            context,
          ).titleLarge?.copyWith(color: amountColor),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingMd,
      ),
      child: Row(
        children: [
          if (reserveSignSlot) _SignSlot(sign: line.sign, color: labelColor),
          Expanded(
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      label,
                      AppSpacings.gapXs,
                      amount(AlignmentDirectional.centerStart),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) => Row(
                      children: [
                        Expanded(child: label),
                        AppSpacings.gapMd,
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * amountMaxShare,
                          ),
                          child: amount(AlignmentDirectional.centerEnd),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.amount,
    required this.sign,
    required this.description,
    required this.reserveSignSlot,
    required this.color,
  });

  final String label;
  final double amount;
  final AppIconData? sign;
  final String? description;
  final bool reserveSignSlot;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final emphasized = AppTypography.emphasizedOf(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reserveSignSlot) _SignSlot(sign: sign, color: color),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: emphasized.titleSmall?.copyWith(color: color),
                ),
                AppSpacings.gapXs,
                // Amounts must stay on one line; shrink rather than wrap.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    amount.toRupeeFormat(),
                    maxLines: 1,
                    style: emphasized.displaySmall?.copyWith(color: color),
                  ),
                ),
                if (description != null) ...[
                  AppSpacings.gapXs,
                  Text(
                    description!,
                    style: textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
