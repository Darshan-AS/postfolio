import 'package:material_ui/material_ui.dart';

/// Material 3 Expressive type roles backed by Google's reference `RobotoFlex` variable
/// font.
///
/// Expressive keeps the Material 3 sizes, binds per-role optical sizes (`opsz`) and
/// variable weights (`wght`) alongside tabular figures (`tnum` by default in `RobotoFlex`),
/// and exposes an *emphasized* set via [AppTypography.emphasizedOf].
abstract final class AppTypography {
  static const String fontFamily = 'RobotoFlex';
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle? _applyRole(
    TextStyle? style, {
    required double opsz,
    required FontWeight weight,
    bool withTabular = false,
    double? letterSpacing,
  }) => style?.copyWith(
    fontWeight: weight,
    fontFeatures: withTabular ? _tabular : null,
    letterSpacing: letterSpacing,
    fontVariations: [
      FontVariation('wght', weight.value.toDouble()),
      FontVariation('opsz', opsz),
    ],
  );

  /// Wires variable `wght` / `opsz` axes, tabular figures, and M3 Expressive optical
  /// tracking (`display*` -0.25, `headline*` -0.15) across all 15 roles.
  static TextTheme withTabularFigures(TextTheme base) {
    const regular = FontWeight.w400;
    const medium = FontWeight.w500;
    TextStyle? role(
      TextStyle? style, {
      required double opsz,
      FontWeight weight = regular,
      double? letterSpacing,
    }) => _applyRole(
      style,
      opsz: opsz,
      weight: weight,
      withTabular: true,
      letterSpacing: letterSpacing,
    );

    return base.copyWith(
      displayLarge: role(base.displayLarge, opsz: 57, letterSpacing: -0.25),
      displayMedium: role(base.displayMedium, opsz: 45, letterSpacing: -0.25),
      displaySmall: role(base.displaySmall, opsz: 36, letterSpacing: -0.25),
      headlineLarge: role(base.headlineLarge, opsz: 32, letterSpacing: -0.15),
      headlineMedium: role(base.headlineMedium, opsz: 28, letterSpacing: -0.15),
      headlineSmall: role(base.headlineSmall, opsz: 24, letterSpacing: -0.15),
      titleLarge: role(base.titleLarge, opsz: 22),
      titleMedium: role(base.titleMedium, opsz: 16, weight: medium),
      titleSmall: role(base.titleSmall, opsz: 14, weight: medium),
      bodyLarge: role(base.bodyLarge, opsz: 16),
      bodyMedium: role(base.bodyMedium, opsz: 14),
      bodySmall: role(base.bodySmall, opsz: 12),
      labelLarge: role(base.labelLarge, opsz: 14, weight: medium),
      labelMedium: role(base.labelMedium, opsz: 12, weight: medium),
      labelSmall: role(base.labelSmall, opsz: 11, weight: medium),
    );
  }

  /// The emphasized counterpart of [base]: same sizes and optical sizes, heavier `wght`.
  static TextTheme emphasized(TextTheme base) {
    const medium = FontWeight.w500;
    const semiBold = FontWeight.w600;
    TextStyle? role(
      TextStyle? style, {
      required double opsz,
      FontWeight weight = medium,
    }) => _applyRole(style, opsz: opsz, weight: weight);

    return base.copyWith(
      displayLarge: role(base.displayLarge, opsz: 57),
      displayMedium: role(base.displayMedium, opsz: 45),
      displaySmall: role(base.displaySmall, opsz: 36),
      headlineLarge: role(base.headlineLarge, opsz: 32),
      headlineMedium: role(base.headlineMedium, opsz: 28),
      headlineSmall: role(base.headlineSmall, opsz: 24),
      titleLarge: role(base.titleLarge, opsz: 22),
      titleMedium: role(base.titleMedium, opsz: 16, weight: semiBold),
      titleSmall: role(base.titleSmall, opsz: 14, weight: semiBold),
      bodyLarge: role(base.bodyLarge, opsz: 16),
      bodyMedium: role(base.bodyMedium, opsz: 14),
      bodySmall: role(base.bodySmall, opsz: 12),
      labelLarge: role(base.labelLarge, opsz: 14, weight: semiBold),
      labelMedium: role(base.labelMedium, opsz: 12, weight: semiBold),
      labelSmall: role(base.labelSmall, opsz: 11, weight: semiBold),
    );
  }

  static final Expando<TextTheme> _emphasizedCache = Expando<TextTheme>();

  /// The emphasized type roles of the ambient theme.
  ///
  /// Built from `Theme.of(context).textTheme`, which already carries the sizes for the
  /// current locale, and cached per text theme.
  static TextTheme emphasizedOf(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _emphasizedCache[textTheme] ??= emphasized(textTheme);
  }
}
