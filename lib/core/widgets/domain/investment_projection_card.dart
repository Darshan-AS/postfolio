import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The live projection under a deposit form: a tonal hero card whose figures follow the
/// form as it is filled in.
///
/// Three blocks, set apart by spacing and tone instead of divider lines: what goes in and
/// what it earns, the total on its own lighter tile as the largest figure, and the dates.
/// Every amount ends on the card's right edge.
class InvestmentProjectionCard extends StatelessWidget {
  final InvestmentProjection? projection;

  const InvestmentProjectionCard({super.key, this.projection});

  /// The card's padding around the total tile. The rows add [_rowInset] to it, which is
  /// also the tile's own padding, so labels and amounts line up down both edges.
  static const double _tileInset = AppDimensions.paddingSm;
  static const double _rowInset = AppDimensions.paddingLg;

  /// Above this text scale a label and its amount no longer fit side by side on a phone,
  /// so the amount moves to its own line under the label.
  static const double _stackAboveTextScale = AppDimensions.largeTextScale;

  static bool _stacksRows(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final proj = projection;

    if (proj == null) {
      return const SizedBox.shrink();
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final onCard = scheme.onPrimaryContainer;
    final valueStyle = emphasized.titleMedium?.copyWith(color: onCard);

    Widget fadeIn(Widget child, {bool slide = false}) {
      if (disableAnimations) return child;
      final faded = child.animate().fade(
        duration: AppAnimations.medium,
        curve: AppAnimations.defaultCurve,
      );
      return slide
          ? faded.slideY(
              begin: AppAnimations.slideOffset,
              end: 0,
              duration: AppAnimations.medium,
              curve: AppAnimations.spatialCurve,
            )
          : faded;
    }

    Widget amountRow(String label, double value, {String prefix = ''}) =>
        _AnimatedStatRow(
          label: label,
          value: value,
          labelColor: onCard,
          valueStyle: valueStyle,
          prefix: prefix,
        );

    final ({String label, double value}) total = switch (proj) {
      WealthAccumulation w => (
        label: t.projection.estimatedMaturity,
        value: w.maturityAmount,
      ),
      IncomeGeneration i => (
        label: t.projection.totalReturn,
        value: i.totalInvested + i.totalInterestEarned,
      ),
    };

    final card = Padding(
      padding: const EdgeInsets.only(top: AppDimensions.paddingLg),
      child: Material(
        color: scheme.primaryContainer,
        shape: AppShapes.rounded(AppShapes.extraLarge),
        child: Padding(
          padding: const EdgeInsets.all(_tileInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // What goes in and what it earns.
              Padding(
                padding: const EdgeInsets.all(_rowInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.projection.title,
                      style: emphasized.titleMedium?.copyWith(color: onCard),
                    ),
                    AppSpacings.gapMd,
                    amountRow(t.projection.totalInvested, proj.totalInvested),
                    AppSpacings.gapSm,
                    amountRow(
                      t.projection.totalInterestEarned,
                      proj.totalInterestEarned,
                      prefix: '+ ',
                    ),
                    if (proj case final IncomeGeneration i) ...[
                      AppSpacings.gapSm,
                      fadeIn(
                        amountRow(
                          t.projection.payout(
                            frequency: i.payoutFrequency.displayName,
                          ),
                          i.periodicPayoutAmount,
                        ),
                        slide: true,
                      ),
                    ],
                  ],
                ),
              ),
              // The total.
              _ProjectionTotalTile(label: total.label, value: total.value),
              // When it is paid.
              Padding(
                padding: const EdgeInsets.all(_rowInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (proj case final IncomeGeneration i) ...[
                      amountRow(t.projection.estimatedMaturity, i.maturityAmount),
                      AppSpacings.gapSm,
                    ],
                    _ProjectionKeyValueRow(
                      label: t.projection.maturityDate,
                      labelColor: onCard,
                      valueChild: Text(
                        proj.maturityDate.toAppFormat(),
                        style: valueStyle,
                      ),
                    ),
                    if (proj.note case final String note)
                      ...switch (proj) {
                        WealthAccumulation() => [
                          AppSpacings.gapSm,
                          fadeIn(
                            _ProjectionKeyValueRow(
                              label: t.projection.doublesIn,
                              labelColor: onCard,
                              valueChild: Text(note, style: valueStyle),
                            ),
                          ),
                        ],
                        IncomeGeneration() => [
                          AppSpacings.gapMd,
                          fadeIn(
                            Text(
                              note,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: onCard,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ],
                      },
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return disableAnimations
        ? card
        : card
              .animate()
              .fade(
                duration: AppAnimations.medium,
                curve: AppAnimations.defaultCurve,
              )
              .slideY(
                begin: AppAnimations.slideOffset / 2,
                end: 0,
                duration: AppAnimations.medium,
                curve: AppAnimations.spatialCurve,
              );
  }
}

/// The projection's headline figure on a lighter tile inside the card.
///
/// On a phone the amount takes its own line under the label, so it keeps its full size
/// whatever its length. A wide window has room for both on one line.
class _ProjectionTotalTile extends StatelessWidget {
  final String label;
  final double value;

  const _ProjectionTotalTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inline =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet &&
        !InvestmentProjectionCard._stacksRows(context);

    final labelText = Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
    // Amounts never wrap: shrink the figure when the tile is narrower than it.
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: _AnimatedAmount(
        value: value,
        style: AppTypography.emphasizedOf(
          context,
        ).headlineMedium?.copyWith(color: scheme.onSurface),
      ),
    );

    return Material(
      color: scheme.raised,
      // Concentric with the card: its radius less the gap between the two edges.
      shape: AppShapes.rounded(AppShapes.largeIncreased),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: InvestmentProjectionCard._rowInset,
          vertical: AppDimensions.paddingMd,
        ),
        child: inline
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: labelText),
                  AppSpacings.gapSm,
                  Flexible(child: amount),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [labelText, AppSpacings.gapXs, amount],
              ),
      ),
    );
  }
}

/// A rupee amount that counts to [value] when it changes, or shows it at once when
/// animations are disabled.
class _AnimatedAmount extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;

  const _AnimatedAmount({required this.value, this.style, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text('$prefix${value.toRupeeFormat()}', maxLines: 1, style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: AppAnimations.slow,
      // An effects curve: a spatial one would overshoot and show a figure above the result.
      curve: AppAnimations.defaultCurve,
      builder: (context, val, child) {
        return Text('$prefix${val.toRupeeFormat()}', maxLines: 1, style: style);
      },
    );
  }
}

class _AnimatedStatRow extends StatelessWidget {
  final String label;
  final double value;
  final Color labelColor;
  final TextStyle? valueStyle;
  final String prefix;

  const _AnimatedStatRow({
    required this.label,
    required this.value,
    required this.labelColor,
    this.valueStyle,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return _ProjectionKeyValueRow(
      label: label,
      labelColor: labelColor,
      valueChild: _AnimatedAmount(
        value: value,
        style: valueStyle,
        prefix: prefix,
      ),
    );
  }
}

class _ProjectionKeyValueRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Widget valueChild;

  const _ProjectionKeyValueRow({
    required this.label,
    required this.labelColor,
    required this.valueChild,
  });

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: labelColor),
    );

    if (InvestmentProjectionCard._stacksRows(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          labelText,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: valueChild,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxValueWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth * 0.55
            : double.infinity;
        return Row(
          children: [
            Expanded(child: labelText),
            AppSpacings.gapSm,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxValueWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: valueChild,
              ),
            ),
          ],
        );
      },
    );
  }
}
