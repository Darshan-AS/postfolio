import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { system, light, dark, accessibleSystem }

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  AppThemeMode build() {
    return AppThemeMode.system;
  }

  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }

  void toggleAccessibleTheme() {
    state = state == AppThemeMode.accessibleSystem
        ? AppThemeMode.system
        : AppThemeMode.accessibleSystem;
  }
}
