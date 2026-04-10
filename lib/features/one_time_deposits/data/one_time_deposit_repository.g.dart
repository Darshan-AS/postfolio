// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_time_deposit_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(oneTimeDepositRepository)
final oneTimeDepositRepositoryProvider = OneTimeDepositRepositoryProvider._();

final class OneTimeDepositRepositoryProvider
    extends
        $FunctionalProvider<
          OneTimeDepositRepository,
          OneTimeDepositRepository,
          OneTimeDepositRepository
        >
    with $Provider<OneTimeDepositRepository> {
  OneTimeDepositRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oneTimeDepositRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oneTimeDepositRepositoryHash();

  @$internal
  @override
  $ProviderElement<OneTimeDepositRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OneTimeDepositRepository create(Ref ref) {
    return oneTimeDepositRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OneTimeDepositRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OneTimeDepositRepository>(value),
    );
  }
}

String _$oneTimeDepositRepositoryHash() =>
    r'31beb732731999dfe4dcbcefed719cc12e5b9290';
