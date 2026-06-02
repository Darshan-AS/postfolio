import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/services/storage_service.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { system, light, dark, accessibleSystem }

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  AppThemeMode build() {
    return ref.watch(storageServiceProvider).getThemeMode();
  }

  void setThemeMode(AppThemeMode mode) {
    state = mode;
    ref.read(storageServiceProvider).setThemeMode(mode);
  }

  void toggleAccessibleTheme() {
    final newMode = state == AppThemeMode.accessibleSystem
        ? AppThemeMode.system
        : AppThemeMode.accessibleSystem;
    state = newMode;
    ref.read(storageServiceProvider).setThemeMode(newMode);
  }
}
