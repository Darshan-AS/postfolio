import 'package:material_ui/material_ui.dart';

class AppDimensions {
  // Breakpoints & Constrained Widths
  static const double breakpointTablet = 600.0;
  static const double maxLoginWidth = 420.0;
  static const double maxFormWidth = 720.0;

  // Components
  static const double chartHeight = 250.0;
  static const double chartBarWidth = 20.0;
  static const double chartYAxisReservedSize = 40.0;
  static const double chartXAxisReservedSize = 32.0;
  static const double chartXAxisSlantedExtraSpace = 24.0;
  static const double chartTooltipReservedHeight = 38.0;

  // Text scaling
  /// The system text scale past which a phone-width row can no longer hold two things side
  /// by side. Above it, such rows give each part a line of its own, and labels in chrome of
  /// fixed size (navigation, FAB, chart axes) stop growing.
  static const double largeTextScale = 1.3;

  /// Whether the ambient text scale is past [largeTextScale].
  static bool isLargeText(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > largeTextScale;

  // Padding & Margins
  static const double paddingNone = 0.0;
  static const double paddingXxs = 2.0;
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 12.0;
  static const double paddingLg = 16.0;
  static const double paddingXl = 24.0;
  static const double paddingXxl = 32.0;

  // Page
  /// Space between the window edge and page content.
  static const double pageMargin = 16.0;

  // List Views
  /// Material's two-line list row: a 48dp touch target with 12dp above and below.
  static const double rowMinHeight = 72.0;

  /// Clears the extended FAB (56) and its margins at the end of a list.
  static const double listBottomPaddingFAB = 96.0;

  // App bars & menus
  /// Material 3 small top app bar.
  static const double appBarHeight = 64.0;
  static const double menuItemMinWidth = 112.0;

  // Buttons
  static const double buttonHeight = 56.0;
  static const double buttonHeightSm = 40.0;
  static const double actionButtonSize = 48.0;

  /// The widest a full-width button grows. In a phone-wide row it fills the row; in a wider
  /// one it stays a button instead of becoming a bar.
  static const double buttonMaxWidth = 360.0;

  /// Minimum interactive target size (Material accessibility guideline).
  static const double minTapTarget = 48.0;

  // Borders & Dividers
  static const double borderSm = 1.0;
  static const double borderMd = 2.0;
  static const double borderLg = 4.0;
  static const double dividerThickness = 1.0;
  static const double dividerHeight = 1.0;
  static const double bottomSheetHandleWidth = 40.0;
  static const double bottomSheetHandleHeight = 4.0;

  // Typography metrics
  static const double fontXs = 10.0;
  static const double lineHeightTight = 1.0;

  // Avatars
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 120.0;

  // Icon Sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  // Badges
  static const double badgeSizeSm = 8.0;
  static const double stepChipMinHeight = 28.0;

  // Opacities
  static const double opacityDisabled = 0.5;
  static const double opacityMuted = 0.7;
}

class AppSpacings {
  static const SizedBox gapXxs = SizedBox(
    height: AppDimensions.paddingXxs,
    width: AppDimensions.paddingXxs,
  );
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
