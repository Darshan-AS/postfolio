import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';

/// Component themes that give the official `material_ui` widgets the Material 3 Expressive
/// look: tonal surfaces instead of outlines, pill buttons that square off when pressed,
/// larger corner radii, emphasized type on titles and labels.
///
/// `IconButton` and `ElevatedButton` opt into the official Expressive variant. The other
/// official widgets have no Expressive variant yet (or the spec leaves them unchanged), so
/// they are styled here with the same tokens.
class AppWidgetThemes {
  AppWidgetThemes._();

  static AppBarTheme appBarTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => AppBarTheme(
    backgroundColor: colorScheme.page,
    foregroundColor: colorScheme.onSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    toolbarHeight: AppDimensions.appBarHeight,
    titleTextStyle: emphasized.titleLarge?.copyWith(
      color: colorScheme.onSurface,
    ),
  );

  static DividerThemeData dividerTheme(ColorScheme colorScheme) =>
      DividerThemeData(
        color: colorScheme.outlineVariant,
        space: AppDimensions.dividerHeight,
        thickness: AppDimensions.dividerThickness,
      );

  static IconButtonThemeData iconButtonTheme(ColorScheme colorScheme) =>
      IconButtonThemeData(
        variant: StyleVariant.material3Expressive,
        style: IconButton.styleFrom(iconSize: AppDimensions.iconMd),
      );

  static FloatingActionButtonThemeData floatingActionButtonTheme(
    ColorScheme colorScheme,
  ) => FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primaryContainer,
    foregroundColor: colorScheme.onPrimaryContainer,
    elevation: 3,
    shape: AppShapes.rounded(AppShapes.large),
  );

  static CardThemeData cardTheme(ColorScheme colorScheme) => CardThemeData(
    color: colorScheme.raised,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: AppShapes.rounded(AppShapes.groupOuter),
  );

  /// Shared by the official text-style buttons: a pill that pulls its corners in while
  /// pressed, with an emphasized label.
  static ButtonStyle _pillStyle(TextTheme emphasized) => ButtonStyle(
    shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
      (states) => states.contains(WidgetState.pressed)
          ? AppShapes.rounded(AppShapes.pressed)
          : AppShapes.pill,
    ),
    textStyle: WidgetStatePropertyAll(emphasized.labelLarge),
    minimumSize: const WidgetStatePropertyAll(
      Size(AppDimensions.actionButtonSize, AppDimensions.buttonHeightSm),
    ),
    animationDuration: AppMotion.effectsDuration,
  );

  static ElevatedButtonThemeData elevatedButtonTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => ElevatedButtonThemeData(
    variant: StyleVariant.material3Expressive,
    style: ButtonStyle(
      textStyle: WidgetStatePropertyAll(emphasized.labelLarge),
    ),
  );

  static FilledButtonThemeData filledButtonTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => FilledButtonThemeData(style: _pillStyle(emphasized));

  static OutlinedButtonThemeData outlinedButtonTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => OutlinedButtonThemeData(
    style: _pillStyle(emphasized).copyWith(
      side: WidgetStatePropertyAll(
        BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
  );

  static TextButtonThemeData textButtonTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => TextButtonThemeData(style: _pillStyle(emphasized));

  static SegmentedButtonThemeData segmentedButtonTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => SegmentedButtonThemeData(
    style: ButtonStyle(
      textStyle: WidgetStatePropertyAll(emphasized.labelLarge),
      side: WidgetStatePropertyAll(
        BorderSide(color: colorScheme.outlineVariant),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.secondaryContainer;
        }
        return Colors.transparent;
      }),
    ),
  );

  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) {
    OutlineInputBorder border(
      Color color, [
      double width = AppDimensions.borderSm,
    ]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.large),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.inset,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingLg,
      ),
      border: border(colorScheme.outlineVariant),
      enabledBorder: border(colorScheme.outlineVariant),
      disabledBorder: border(colorScheme.outlineVariant.withValues(alpha: 0.5)),
      focusedBorder: border(colorScheme.primary, AppDimensions.borderMd),
      errorBorder: border(colorScheme.error),
      focusedErrorBorder: border(colorScheme.error, AppDimensions.borderMd),
    );
  }

  static SearchBarThemeData searchBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) => SearchBarThemeData(
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(colorScheme.raised),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shape: const WidgetStatePropertyAll(AppShapes.pill),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
    ),
    constraints: const BoxConstraints(minHeight: AppDimensions.buttonHeight),
    textStyle: WidgetStatePropertyAll(
      textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
    ),
    hintStyle: WidgetStatePropertyAll(
      textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
    ),
  );

  /// Chips are suggestions and choices that sit in a line and wrap, such as the quick amounts
  /// on the collect sheet.
  ///
  /// A chosen chip takes the colours of a selected segment or toggle, and no tick: the tick
  /// widens the chip, which on a narrow phone pushes the next chip to a new line and moves
  /// everything under the chips.
  static ChipThemeData chipTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => ChipThemeData(
    backgroundColor: Colors.transparent,
    selectedColor: colorScheme.secondary,
    secondarySelectedColor: colorScheme.secondary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.paddingSm,
      vertical: AppDimensions.paddingXs,
    ),
    labelStyle: emphasized.labelLarge?.copyWith(
      color: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colorScheme.onSecondary
            : colorScheme.onSurfaceVariant,
      ),
    ),
    secondaryLabelStyle: emphasized.labelLarge?.copyWith(
      color: colorScheme.onSecondary,
    ),
    brightness: colorScheme.brightness,
    shape: AppShapes.rounded(AppShapes.small),
    // The outline stays under the fill of a chosen chip, in the fill's colour: without
    // it the chip would be 2dp smaller and nudge its neighbours.
    side: WidgetStateBorderSide.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.selected)
            ? colorScheme.secondary
            : colorScheme.outlineVariant,
      ),
    ),
    showCheckmark: false,
    checkmarkColor: colorScheme.onSecondary,
  );

  static ExpansionTileThemeData expansionTileTheme(ColorScheme colorScheme) =>
      ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        shape: const Border(),
        collapsedShape: const Border(),
      );

  static SnackBarThemeData snackBarTheme(ColorScheme colorScheme) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
        shape: AppShapes.rounded(AppShapes.large),
      );

  static DialogThemeData dialogTheme(
    ColorScheme colorScheme,
    TextTheme emphasized,
  ) => DialogThemeData(
    backgroundColor: colorScheme.surfaceContainerHigh,
    surfaceTintColor: Colors.transparent,
    shape: AppShapes.rounded(AppShapes.extraLarge),
    titleTextStyle: emphasized.headlineSmall?.copyWith(
      color: colorScheme.onSurface,
    ),
  );

  static BottomSheetThemeData bottomSheetTheme(ColorScheme colorScheme) =>
      BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: AppShapes.sheet,
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant,
        dragHandleSize: const Size(
          AppDimensions.bottomSheetHandleWidth,
          AppDimensions.bottomSheetHandleHeight,
        ),
      );

  /// Menus: a rounded container whose items are themselves rounded, inset by a small gap.
  static MenuThemeData menuTheme(ColorScheme colorScheme) => MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerLow),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(3),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.all(AppDimensions.paddingXs),
      ),
      shape: WidgetStatePropertyAll(AppShapes.rounded(AppShapes.large)),
    ),
  );

  static MenuButtonThemeData menuButtonTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) => MenuButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(AppShapes.rounded(AppShapes.medium)),
      minimumSize: const WidgetStatePropertyAll(
        Size(AppDimensions.menuItemMinWidth, AppDimensions.actionButtonSize),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      ),
      textStyle: WidgetStatePropertyAll(textTheme.bodyLarge),
    ),
  );

  static DatePickerThemeData datePickerTheme(ColorScheme colorScheme) =>
      DatePickerThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: AppShapes.rounded(AppShapes.extraLarge),
      );

  static MaterialBannerThemeData bannerTheme(ColorScheme colorScheme) =>
      MaterialBannerThemeData(
        backgroundColor: colorScheme.tertiaryContainer,
        surfaceTintColor: Colors.transparent,
        dividerColor: Colors.transparent,
        elevation: 0,
      );

  static RadioThemeData radioTheme(ColorScheme colorScheme) => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary;
      }
      if (states.contains(WidgetState.disabled)) {
        return colorScheme.onSurface.withValues(alpha: 0.38);
      }
      return colorScheme.onSurfaceVariant;
    }),
  );
}
