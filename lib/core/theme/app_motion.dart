import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

/// A [Curve] that follows [spring] from 0 to 1 over [duration].
///
/// Material 3 Expressive specifies motion as springs, while implicit animations
/// (`AnimatedContainer`, `flutter_animate`) take a curve and a duration. This samples the
/// spring so both describe the same movement. [duration] must be long enough for the spring
/// to come to rest, otherwise the last frame jumps to 1.
class SpringCurve extends Curve {
  const SpringCurve(this.spring, {required this.duration});

  final SpringDescription spring;
  final Duration duration;

  @override
  double transformInternal(double t) {
    final seconds =
        t * duration.inMicroseconds / Duration.microsecondsPerSecond;
    return SpringSimulation(spring, 0, 1, 0).x(seconds);
  }
}

/// Material 3 Expressive motion tokens, taken from the official `material_ui` [Springs].
///
/// *Spatial* springs move, resize and reshape things and overshoot slightly. *Effects*
/// springs change colour and opacity and never overshoot, so they are safe for values that
/// must stay inside a range (opacity, corner radius).
abstract final class AppMotion {
  static const SpringDescription spatial = Springs.expressiveDefaultSpatial;
  static const SpringDescription spatialFast = Springs.expressiveFastSpatial;
  static const SpringDescription effects = Springs.expressiveDefaultEffects;
  static const SpringDescription effectsFast = Springs.expressiveFastEffects;

  static const Duration spatialDuration = Duration(milliseconds: 500);
  static const Duration spatialFastDuration = Duration(milliseconds: 350);
  static const Duration effectsDuration = Duration(milliseconds: 200);
  static const Duration effectsFastDuration = Duration(milliseconds: 150);

  /// For position, size and scale. Overshoots: do not use for opacity or radii.
  static const Curve spatialCurve = SpringCurve(
    spatial,
    duration: spatialDuration,
  );
  static const Curve spatialFastCurve = SpringCurve(
    spatialFast,
    duration: spatialFastDuration,
  );

  /// For colour, opacity and corner radius.
  static const Curve effectsCurve = SpringCurve(
    effects,
    duration: effectsDuration,
  );
  static const Curve effectsFastCurve = SpringCurve(
    effectsFast,
    duration: effectsFastDuration,
  );
}
