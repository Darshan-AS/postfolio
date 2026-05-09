import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'storage_service.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('Initialize sharedPreferences in main.dart');
}

@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
}

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const _demoModeKey = 'demo_mode_enabled';

  bool get isDemoMode => _prefs.getBool(_demoModeKey) ?? false;

  Future<void> setDemoMode(bool value) => _prefs.setBool(_demoModeKey, value);
}
