import 'package:material_3_expressive/components/loading_indicator/m3e_loading_indicator.dart';
import 'package:material_3_expressive/components/progress_indicators/m3e_progress_indicators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The Material 3 Expressive loading indicator: a shape that morphs while it turns.
///
/// Use it for waits of unknown length (the role `CircularProgressIndicator` had). For
/// progress with a known fraction use [AppLinearProgress].
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = defaultSize,
    this.contained = false,
    this.color,
  });

  /// Sized to sit where a 24dp icon would: app bar actions, inside a button.
  const AppLoadingIndicator.inline({super.key, this.color})
    : size = inlineSize,
      contained = false;

  static const double defaultSize = 48;

  /// The smallest size the Expressive spec allows.
  static const double inlineSize = 24;

  /// Outer size in dp; values under [inlineSize] are raised to it.
  final double size;

  /// Draws the indicator on a tonal disc, for use over busy content.
  final bool contained;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return M3ELoadingIndicator(
      variant: contained
          ? M3ELoadingIndicatorVariant.contained
          : M3ELoadingIndicatorVariant.defaultStyle,
      size: size < inlineSize ? inlineSize : size,
      color: color,
      semanticLabel: t.common.loading,
    );
  }
}

/// A linear progress bar for a known fraction ([value] in 0..1), or an indeterminate one
/// when [value] is null.
///
/// [wavy] draws the Expressive wavy track, which reads as "in motion". Keep the flat track
/// where the bar is a static measure (an allocation, a completed share).
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    required this.value,
    this.wavy = false,
    this.color,
    this.trackColor,
    this.semanticsLabel,
  });

  final double? value;
  final bool wavy;
  final Color? color;
  final Color? trackColor;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value?.clamp(0.0, 1.0);
    if (wavy) {
      return M3EProgressIndicator.linearWavy(
        value: clamped,
        color: color,
        trackColor: trackColor,
        semanticsLabel: semanticsLabel,
      );
    }
    return M3EProgressIndicator.linear(
      value: clamped,
      color: color,
      trackColor: trackColor,
      semanticsLabel: semanticsLabel,
    );
  }
}
