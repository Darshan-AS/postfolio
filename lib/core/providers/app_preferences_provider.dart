import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/start_tab.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_preferences_provider.freezed.dart';
part 'app_preferences_provider.g.dart';

@freezed
sealed class AppPreferences with _$AppPreferences {
  const factory AppPreferences({
    @Default(true) bool useDynamicColor,
    @Default(AppStartTab.customers) AppStartTab startTab,
    @Default(true) bool hapticsEnabled,
    @Default(false) bool maskSensitiveIds,
  }) = _AppPreferences;
}

@Riverpod(keepAlive: true)
class AppPreferencesNotifier extends _$AppPreferencesNotifier {
  StorageService? _tryStorage() {
    try {
      return ref.read(storageServiceProvider);
    } catch (_) {
      // Isolated unit tests may omit SharedPreferences overrides.
      return null;
    }
  }

  @override
  AppPreferences build() {
    final storage = _tryStorage();
    if (storage == null) return const AppPreferences();
    return AppPreferences(
      useDynamicColor: storage.getUseDynamicColor(),
      startTab: storage.getStartTab(),
      hapticsEnabled: storage.getHapticsEnabled(),
      maskSensitiveIds: storage.getMaskSensitiveIds(),
    );
  }

  Future<void> setUseDynamicColor(bool value) async {
    state = state.copyWith(useDynamicColor: value);
    await _tryStorage()?.setUseDynamicColor(value);
  }

  Future<void> setStartTab(AppStartTab tab) async {
    state = state.copyWith(startTab: tab);
    await _tryStorage()?.setStartTab(tab);
  }

  Future<void> setHapticsEnabled(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    await _tryStorage()?.setHapticsEnabled(value);
  }

  Future<void> setMaskSensitiveIds(bool value) async {
    state = state.copyWith(maskSensitiveIds: value);
    await _tryStorage()?.setMaskSensitiveIds(value);
  }
}
