import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/services/storage_service.dart';

part 'demo_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class DemoMode extends _$DemoMode {
  @override
  bool build() {
    return ref.watch(storageServiceProvider).isDemoMode;
  }

  Future<void> toggle() async {
    final newValue = !state;
    await ref.read(storageServiceProvider).setDemoMode(newValue);
    state = newValue;
  }

  Future<void> enable() async {
    await ref.read(storageServiceProvider).setDemoMode(true);
    state = true;
  }

  Future<void> disable() async {
    await ref.read(storageServiceProvider).setDemoMode(false);
    state = false;
  }
}
