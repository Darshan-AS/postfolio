import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Loads pinned `Roboto` v3.016 fonts (which include `₹` U+20B9 natively) from
/// `tool/store_screenshots/fonts/` and `MaterialIcons` from the Flutter SDK so
/// golden-test store screenshots render identically across macOS and Linux CI.
class ScreenshotFonts {
  ScreenshotFonts._();

  static bool _loaded = false;

  static const _plusJakartaFiles = <String>[
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-Medium.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
  ];

  static const _robotoFiles = <String>[
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ];

  /// Loads `PlusJakartaSans`, `Roboto`, and `MaterialIcons` into the test binding's
  /// [FontLoader]. Safe to call multiple times.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    final assetsFontsDir = _findRelativeDir('assets/fonts');
    if (assetsFontsDir != null) {
      final jakartaLoader = FontLoader('PlusJakartaSans');
      for (final filename in _plusJakartaFiles) {
        final file = File('${assetsFontsDir.path}/$filename');
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          jakartaLoader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
      }
      await jakartaLoader.load();
    }

    final robotoDir = _findBundledFontsDir();
    if (robotoDir == null) {
      throw StateError(
        'Could not locate tool/store_screenshots/fonts. '
        'Run `flutter test` from the repository root.',
      );
    }

    final robotoLoader = FontLoader('Roboto');
    for (final filename in _robotoFiles) {
      final file = File('${robotoDir.path}/$filename');
      if (!file.existsSync()) {
        throw StateError('Missing bundled font: ${file.path}');
      }
      final bytes = await file.readAsBytes();
      robotoLoader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await robotoLoader.load();

    final materialFontsDir = _findMaterialFontsDir();
    if (materialFontsDir == null) {
      throw StateError(
        'Could not locate Flutter SDK bin/cache/artifacts/material_fonts. '
        'Run via `flutter test` or set FLUTTER_ROOT.',
      );
    }

    final iconsFile = File(
      '${materialFontsDir.path}/MaterialIcons-Regular.otf',
    );
    if (iconsFile.existsSync()) {
      final bytes = await iconsFile.readAsBytes();
      final iconsLoader = FontLoader('MaterialIcons');
      iconsLoader.addFont(Future.value(ByteData.sublistView(bytes)));
      await iconsLoader.load();
    }
  }

  /// Applies bundled `PlusJakartaSans` (with `Roboto` fallback) to [theme].
  static ThemeData applyTo(ThemeData theme) {
    TextStyle? patch(TextStyle? style) => style?.copyWith(
      fontFamily: style.fontFamily ?? 'PlusJakartaSans',
      fontFamilyFallback: const ['Roboto'],
    );

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

  static Directory? _findBundledFontsDir() =>
      _findRelativeDir('tool/store_screenshots/fonts');

  static Directory? _findRelativeDir(String relativePath) {
    var cursor = Directory.current;
    for (var i = 0; i < 6; i++) {
      final candidate = Directory('${cursor.path}/$relativePath');
      if (candidate.existsSync()) return candidate;
      final parent = cursor.parent;
      if (parent.path == cursor.path) break;
      cursor = parent;
    }
    return null;
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

    for (final root in candidates) {
      final dir = Directory('${root.path}/bin/cache/artifacts/material_fonts');
      if (dir.existsSync()) return dir;
    }
    return null;
  }
}
