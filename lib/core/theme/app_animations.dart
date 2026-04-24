import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  AppAnimations._();

  // Durations
  static Duration get fast => 150.ms;
  static Duration get medium => 300.ms;
  static Duration get slow => 400.ms;

  // Intervals (for staggered animations like lists)
  static Duration get stagger => 50.ms;

  // Curves
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.easeOutBack;

  // Common Offsets
  static const double slideOffset = 0.1;
}
