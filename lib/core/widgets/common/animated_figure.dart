import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_motion.dart';

/// A figure that counts to its new value when it changes, so that the change is seen: an
/// installment that is collected takes its amount off "To collect".
///
/// The first value is shown as it is. [of] names what is counted. When it changes (another
/// month) the figure is another quantity, not a change of this one, and is shown at once.
/// A device set to remove animations always gets the value at once.
class AnimatedFigure extends StatelessWidget {
  const AnimatedFigure({
    super.key,
    required this.value,
    required this.format,
    this.of,
    this.style,
  });

  final double value;

  /// Writes a value. On the way it is given whole numbers only, so an amount in rupees does
  /// not flicker through paise.
  final String Function(double value) format;

  /// What the figure counts.
  final Object? of;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(format(value), style: style, maxLines: 1);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(of),
      tween: Tween<double>(end: value),
      duration: AppMotion.effectsSlowDuration,
      // A figure never passes its new value on the way.
      curve: AppMotion.effectsSlowCurve,
      builder: (context, shown, _) => Text(
        format(shown == value ? value : shown.roundToDouble()),
        style: style,
        maxLines: 1,
      ),
    );
  }
}
