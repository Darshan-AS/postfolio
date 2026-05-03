import 'package:flutter/material.dart';

class AppDimensions {
  // Breakpoints
  static const double breakpointTablet = 600.0;

  // Padding & Margins
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 12.0;
  static const double paddingLg = 16.0;
  static const double paddingXl = 24.0;
  static const double paddingXxl = 32.0;

  // List Views
  static const double listBottomPaddingFAB = 88.0;

  // Buttons
  static const double buttonHeight = 56.0;

  // Radii
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 24.0;
  static const double radiusXxxl = 32.0;
  static const double radiusMax = 48.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
}

class AppSpacings {
  static const SizedBox gapXs = SizedBox(
    height: AppDimensions.paddingXs,
    width: AppDimensions.paddingXs,
  );
  static const SizedBox gapSm = SizedBox(
    height: AppDimensions.paddingSm,
    width: AppDimensions.paddingSm,
  );
  static const SizedBox gapMd = SizedBox(
    height: AppDimensions.paddingMd,
    width: AppDimensions.paddingMd,
  );
  static const SizedBox gapLg = SizedBox(
    height: AppDimensions.paddingLg,
    width: AppDimensions.paddingLg,
  );
  static const SizedBox gapXl = SizedBox(
    height: AppDimensions.paddingXl,
    width: AppDimensions.paddingXl,
  );
  static const SizedBox gapXxl = SizedBox(
    height: AppDimensions.paddingXxl,
    width: AppDimensions.paddingXxl,
  );
}
