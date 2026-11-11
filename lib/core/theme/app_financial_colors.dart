import 'package:material_ui/material_ui.dart';

/// Semantic color tuple for a single financial or operational status.
///
/// Every `(container, onContainer)` pair satisfies WCAG 2.1 AA text contrast (`>= 4.5:1`),
/// and every `accent` satisfies WCAG 2.1 non-text contrast (`>= 3.0:1`) against `surface`.
@immutable
class FinancialStatusPalette {
  final Color container;
  final Color onContainer;
  final Color border;
  final Color accent;

  const FinancialStatusPalette({
    required this.container,
    required this.onContainer,
    required this.border,
    required this.accent,
  });

  FinancialStatusPalette copyWith({
    Color? container,
    Color? onContainer,
    Color? border,
    Color? accent,
  }) => FinancialStatusPalette(
    container: container ?? this.container,
    onContainer: onContainer ?? this.onContainer,
    border: border ?? this.border,
    accent: accent ?? this.accent,
  );

  static FinancialStatusPalette lerp(
    FinancialStatusPalette a,
    FinancialStatusPalette b,
    double t,
  ) => FinancialStatusPalette(
    container: Color.lerp(a.container, b.container, t)!,
    onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialStatusPalette &&
          container == other.container &&
          onContainer == other.onContainer &&
          border == other.border &&
          accent == other.accent;

  @override
  int get hashCode => Object.hash(container, onContainer, border, accent);
}

/// Dedicated semantic financial status colors insulated from OS wallpaper Monet shifts.
///
/// Guarantees that Settled, Cash-in-Hand, Partial, Fronted Receivable, Maturing Warning, and
/// Overdue never share a container hue or lose WCAG 2.1 AA contrast in Light, Dark, or
/// Color-Blind Accessible themes.
@immutable
class AppFinancialColors extends ThemeExtension<AppFinancialColors> {
  final FinancialStatusPalette settled;
  final FinancialStatusPalette inHand;
  final FinancialStatusPalette partial;
  final FinancialStatusPalette fronted;
  final FinancialStatusPalette warning;
  final FinancialStatusPalette overdue;

  const AppFinancialColors({
    required this.settled,
    required this.inHand,
    required this.partial,
    required this.fronted,
    required this.warning,
    required this.overdue,
  });

  static const AppFinancialColors light = AppFinancialColors(
    settled: FinancialStatusPalette(
      container: Color(0xFFD8F3E5),
      onContainer: Color(0xFF0A4D2C),
      border: Color(0xFF66BB8A),
      accent: Color(0xFF157F4B),
    ),
    inHand: FinancialStatusPalette(
      container: Color(0xFFFEF0C7),
      onContainer: Color(0xFF693B00),
      border: Color(0xFFE5A93B),
      accent: Color(0xFFB36200),
    ),
    partial: FinancialStatusPalette(
      container: Color(0xFFE0F2FE),
      onContainer: Color(0xFF0C4A6E),
      border: Color(0xFF5AB4E8),
      accent: Color(0xFF0277BD),
    ),
    fronted: FinancialStatusPalette(
      container: Color(0xFFEDE9FE),
      onContainer: Color(0xFF3B1D8F),
      border: Color(0xFFA78BFA),
      accent: Color(0xFF6D28D9),
    ),
    warning: FinancialStatusPalette(
      container: Color(0xFFFFE4D6),
      onContainer: Color(0xFF7C2D12),
      border: Color(0xFFF98F62),
      accent: Color(0xFFC2410C),
    ),
    overdue: FinancialStatusPalette(
      container: Color(0xFFFEE2E2),
      onContainer: Color(0xFF7F1D1D),
      border: Color(0xFFF87171),
      accent: Color(0xFFDC2626),
    ),
  );

  static const AppFinancialColors dark = AppFinancialColors(
    settled: FinancialStatusPalette(
      container: Color(0xFF0F3D26),
      onContainer: Color(0xFFBDF2D5),
      border: Color(0xFF2E7D56),
      accent: Color(0xFF4ADE80),
    ),
    inHand: FinancialStatusPalette(
      container: Color(0xFF4A2E00),
      onContainer: Color(0xFFFDE293),
      border: Color(0xFFB87914),
      accent: Color(0xFFFBBF24),
    ),
    partial: FinancialStatusPalette(
      container: Color(0xFF0C3854),
      onContainer: Color(0xFFBAE6FD),
      border: Color(0xFF2B79A8),
      accent: Color(0xFF38BDF8),
    ),
    fronted: FinancialStatusPalette(
      container: Color(0xFF2E1A66),
      onContainer: Color(0xFFE4D9FF),
      border: Color(0xFF7C5CE0),
      accent: Color(0xFFA78BFA),
    ),
    warning: FinancialStatusPalette(
      container: Color(0xFF54200B),
      onContainer: Color(0xFFFFD6C2),
      border: Color(0xFFC2582B),
      accent: Color(0xFFFB923C),
    ),
    overdue: FinancialStatusPalette(
      container: Color(0xFF5C1414),
      onContainer: Color(0xFFFECACA),
      border: Color(0xFFC83E3E),
      accent: Color(0xFFF87171),
    ),
  );

  /// Wong/Tol color-blind safe light palette (avoids red-green confusion via cerulean blue,
  /// gold, indigo, reddish-purple, vermilion, and high-contrast magenta-crimson).
  static const AppFinancialColors accessibleLight = AppFinancialColors(
    settled: FinancialStatusPalette(
      container: Color(0xFFD6ECFA),
      onContainer: Color(0xFF003B64),
      border: Color(0xFF4BA3E3),
      accent: Color(0xFF0066AD),
    ),
    inHand: FinancialStatusPalette(
      container: Color(0xFFFFF3BF),
      onContainer: Color(0xFF5C4000),
      border: Color(0xFFD9A300),
      accent: Color(0xFF946300),
    ),
    partial: FinancialStatusPalette(
      container: Color(0xFFE6E6FA),
      onContainer: Color(0xFF28205E),
      border: Color(0xFF7B6FD6),
      accent: Color(0xFF493BA8),
    ),
    fronted: FinancialStatusPalette(
      container: Color(0xFFF7E1F3),
      onContainer: Color(0xFF59114D),
      border: Color(0xFFC86AB6),
      accent: Color(0xFF8F247A),
    ),
    warning: FinancialStatusPalette(
      container: Color(0xFFFFE2CC),
      onContainer: Color(0xFF6B2900),
      border: Color(0xFFE67E33),
      accent: Color(0xFFB84A00),
    ),
    overdue: FinancialStatusPalette(
      container: Color(0xFFFCE4EC),
      onContainer: Color(0xFF7A0938),
      border: Color(0xFFE05288),
      accent: Color(0xFFB80F57),
    ),
  );

  /// Wong/Tol color-blind safe dark palette.
  static const AppFinancialColors accessibleDark = AppFinancialColors(
    settled: FinancialStatusPalette(
      container: Color(0xFF003559),
      onContainer: Color(0xFFCFE8FC),
      border: Color(0xFF3894D8),
      accent: Color(0xFF56B4E9),
    ),
    inHand: FinancialStatusPalette(
      container: Color(0xFF473300),
      onContainer: Color(0xFFFFEC99),
      border: Color(0xFFC79200),
      accent: Color(0xFFF0E442),
    ),
    partial: FinancialStatusPalette(
      container: Color(0xFF261E57),
      onContainer: Color(0xFFE0DCFF),
      border: Color(0xFF7468C9),
      accent: Color(0xFFA59BFF),
    ),
    fronted: FinancialStatusPalette(
      container: Color(0xFF4A1040),
      onContainer: Color(0xFFF9D8F2),
      border: Color(0xFFB85CA6),
      accent: Color(0xFFCC79A7),
    ),
    warning: FinancialStatusPalette(
      container: Color(0xFF522100),
      onContainer: Color(0xFFFFD8BD),
      border: Color(0xFFD46A1F),
      accent: Color(0xFFE69F00),
    ),
    overdue: FinancialStatusPalette(
      container: Color(0xFF5E092C),
      onContainer: Color(0xFFFDD5E5),
      border: Color(0xFFD1477D),
      accent: Color(0xFFF472B6),
    ),
  );

  static AppFinancialColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static AppFinancialColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppFinancialColors>() ??
        forBrightness(theme.colorScheme.brightness);
  }

  @override
  AppFinancialColors copyWith({
    FinancialStatusPalette? settled,
    FinancialStatusPalette? inHand,
    FinancialStatusPalette? partial,
    FinancialStatusPalette? fronted,
    FinancialStatusPalette? warning,
    FinancialStatusPalette? overdue,
  }) => AppFinancialColors(
    settled: settled ?? this.settled,
    inHand: inHand ?? this.inHand,
    partial: partial ?? this.partial,
    fronted: fronted ?? this.fronted,
    warning: warning ?? this.warning,
    overdue: overdue ?? this.overdue,
  );

  @override
  AppFinancialColors lerp(ThemeExtension<AppFinancialColors>? other, double t) {
    if (other is! AppFinancialColors) return this;
    return AppFinancialColors(
      settled: FinancialStatusPalette.lerp(settled, other.settled, t),
      inHand: FinancialStatusPalette.lerp(inHand, other.inHand, t),
      partial: FinancialStatusPalette.lerp(partial, other.partial, t),
      fronted: FinancialStatusPalette.lerp(fronted, other.fronted, t),
      warning: FinancialStatusPalette.lerp(warning, other.warning, t),
      overdue: FinancialStatusPalette.lerp(overdue, other.overdue, t),
    );
  }
}
