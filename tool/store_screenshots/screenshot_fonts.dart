import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Loads real `Roboto` and `MaterialIcons` fonts bundled with the Flutter SDK
/// so golden-test store screenshots render crisp typography instead of Ahem
/// fallback blocks, plus a macOS fallback font when available for `₹` (U+20B9).
class ScreenshotFonts {
  ScreenshotFonts._();

  static bool _loaded = false;
  static bool _hasRupeeFallback = false;

  static const _robotoFiles = <String>[
    'Roboto-Thin.ttf',
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
    'Roboto-Italic.ttf',
    'Roboto-LightItalic.ttf',
    'Roboto-MediumItalic.ttf',
    'Roboto-BoldItalic.ttf',
    'Roboto-BlackItalic.ttf',
    'Roboto-ThinItalic.ttf',
  ];

  static const _fallbackFontPaths = <String>[
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/NotoSansKannada-Regular.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ];

  /// Loads `Roboto`, `MaterialIcons`, and an optional fallback font into the
  /// test binding's [FontLoader]. Safe to call multiple times.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    final materialFontsDir = _findMaterialFontsDir();
    if (materialFontsDir == null) {
      throw StateError(
        'Could not locate Flutter SDK bin/cache/artifacts/material_fonts. '
        'Run via `flutter test` or set FLUTTER_ROOT.',
      );
    }

    final robotoLoader = FontLoader('Roboto');
    for (final filename in _robotoFiles) {
      final file = File('${materialFontsDir.path}/$filename');
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        robotoLoader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
    }
    await robotoLoader.load();

    final iconsFile = File(
      '${materialFontsDir.path}/MaterialIcons-Regular.otf',
    );
    if (iconsFile.existsSync()) {
      final bytes = await iconsFile.readAsBytes();
      final iconsLoader = FontLoader('MaterialIcons');
      iconsLoader.addFont(Future.value(ByteData.sublistView(bytes)));
      await iconsLoader.load();
    }

    // Load a system sans-serif fallback containing U+20B9 (Indian Rupee Sign)
    // in case the bundled 2017 Roboto TTF lacks the glyph.
    for (final path in _fallbackFontPaths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final fallbackLoader = FontLoader('ScreenshotFallback');
        fallbackLoader.addFont(Future.value(ByteData.sublistView(bytes)));
        await fallbackLoader.load();
        _hasRupeeFallback = true;
        break;
      }
    }
  }

  /// Applies `Roboto` (and fallback for symbols like `₹`) to every style in [theme].
  static ThemeData applyTo(ThemeData theme) {
    final fallback = _hasRupeeFallback ? const ['ScreenshotFallback'] : null;
    TextStyle? patch(TextStyle? style) =>
        style?.copyWith(fontFamily: 'Roboto', fontFamilyFallback: fallback);

    TextTheme patchTheme(TextTheme t) => t.copyWith(
      displayLarge: patch(t.displayLarge),
      displayMedium: patch(t.displayMedium),
      displaySmall: patch(t.displaySmall),
      headlineLarge: patch(t.headlineLarge),
      headlineMedium: patch(t.headlineMedium),
      headlineSmall: patch(t.headlineSmall),
      titleLarge: patch(t.titleLarge),
      titleMedium: patch(t.titleMedium),
      titleSmall: patch(t.titleSmall),
      bodyLarge: patch(t.bodyLarge),
      bodyMedium: patch(t.bodyMedium),
      bodySmall: patch(t.bodySmall),
      labelLarge: patch(t.labelLarge),
      labelMedium: patch(t.labelMedium),
      labelSmall: patch(t.labelSmall),
    );

    return theme.copyWith(
      textTheme: patchTheme(theme.textTheme),
      primaryTextTheme: patchTheme(theme.primaryTextTheme),
    );
  }

  static Directory? _findMaterialFontsDir() {
    final candidates = <Directory>[];
    final envRoot = Platform.environment['FLUTTER_ROOT'];
    if (envRoot != null && envRoot.isNotEmpty) {
      candidates.add(Directory(envRoot));
    }

    var cursor = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 8; i++) {
      candidates.add(cursor);
      final parent = cursor.parent;
      if (parent.path == cursor.path) break;
      cursor = parent;
    }

    candidates.add(Directory('/Users/darshanas/flutter'));

    for (final root in candidates) {
      final dir = Directory('${root.path}/bin/cache/artifacts/material_fonts');
      if (dir.existsSync()) return dir;
    }
    return null;
  }
}
