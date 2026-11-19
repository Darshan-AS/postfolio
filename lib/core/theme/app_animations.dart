import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_motion.dart';

class AppAnimations {
  AppAnimations._();

  // Durations
  static Duration get fast => AppMotion.effectsFastDuration;
  static Duration get medium => AppMotion.spatialFastDuration;
  static Duration get slow => AppMotion.spatialDuration;
  static Duration get debounce => 300.ms;

  // Intervals (for staggered animations like lists)
  static Duration get stagger => 50.ms;

  // Curves
  /// For fades: never leaves 0..1, so opacity stays valid.
  static const Curve defaultCurve = AppMotion.effectsCurve;

  /// For slides and scales that run for [medium]: an Expressive spring with a slight overshoot.
  static const Curve spatialCurve = AppMotion.spatialFastCurve;

  /// For slides and scales that run for [slow].
  static const Curve bounceCurve = AppMotion.spatialCurve;

  // Common Offsets
  static const double slideOffset = 0.1;
}
