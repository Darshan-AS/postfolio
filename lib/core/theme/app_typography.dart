import 'package:material_ui/material_ui.dart';

/// Material 3 Expressive type roles.
///
/// Expressive keeps the Material 3 sizes and adds an *emphasized* set of the same fifteen
/// roles with heavier weights, for selection, actions and headlines. The baseline set stays
/// the default [ThemeData.textTheme]; the emphasized set is reached through
/// [AppTypography.emphasizedOf].
abstract final class AppTypography {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Amounts line up in columns throughout the app, so every role uses tabular figures.
  static TextTheme withTabularFigures(TextTheme base) {
    TextStyle? tabular(TextStyle? style) =>
        style?.copyWith(fontFeatures: _tabular);

    return base.copyWith(
      displayLarge: tabular(base.displayLarge),
      displayMedium: tabular(base.displayMedium),
      displaySmall: tabular(base.displaySmall),
      headlineLarge: tabular(base.headlineLarge),
      headlineMedium: tabular(base.headlineMedium),
      headlineSmall: tabular(base.headlineSmall),
      titleLarge: tabular(base.titleLarge),
      titleMedium: tabular(base.titleMedium),
      titleSmall: tabular(base.titleSmall),
      bodyLarge: tabular(base.bodyLarge),
      bodyMedium: tabular(base.bodyMedium),
      bodySmall: tabular(base.bodySmall),
      labelLarge: tabular(base.labelLarge),
      labelMedium: tabular(base.labelMedium),
      labelSmall: tabular(base.labelSmall),
    );
  }

  /// The emphasized counterpart of [base]: same sizes, heavier weights.
  static TextTheme emphasized(TextTheme base) {
    TextStyle? weight(TextStyle? style, FontWeight w) =>
        style?.copyWith(fontWeight: w);
    const medium = FontWeight.w500;
    const semiBold = FontWeight.w600;

    return base.copyWith(
      displayLarge: weight(base.displayLarge, medium),
      displayMedium: weight(base.displayMedium, medium),
      displaySmall: weight(base.displaySmall, medium),
      headlineLarge: weight(base.headlineLarge, medium),
      headlineMedium: weight(base.headlineMedium, medium),
      headlineSmall: weight(base.headlineSmall, medium),
      titleLarge: weight(base.titleLarge, medium),
      titleMedium: weight(base.titleMedium, semiBold),
      titleSmall: weight(base.titleSmall, semiBold),
      bodyLarge: weight(base.bodyLarge, medium),
      bodyMedium: weight(base.bodyMedium, medium),
      bodySmall: weight(base.bodySmall, medium),
      labelLarge: weight(base.labelLarge, semiBold),
      labelMedium: weight(base.labelMedium, semiBold),
      labelSmall: weight(base.labelSmall, semiBold),
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
