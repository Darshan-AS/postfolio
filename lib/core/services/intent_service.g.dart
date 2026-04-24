// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intent_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(intentService)
final intentServiceProvider = IntentServiceProvider._();

final class IntentServiceProvider
    extends $FunctionalProvider<IntentService, IntentService, IntentService>
    with $Provider<IntentService> {
  IntentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intentServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intentServiceHash();

  @$internal
  @override
  $ProviderElement<IntentService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IntentService create(Ref ref) {
    return intentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntentService>(value),
    );
  }
}

String _$intentServiceHash() => r'5834a7f6bee1e6f9f0d8908b80591174007cee27';
