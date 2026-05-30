// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_time_deposits_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OneTimeListCriteria)
final oneTimeListCriteriaProvider = OneTimeListCriteriaProvider._();

final class OneTimeListCriteriaProvider
    extends $NotifierProvider<OneTimeListCriteria, OTDSearchCriteria> {
  OneTimeListCriteriaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oneTimeListCriteriaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oneTimeListCriteriaHash();

  @$internal
  @override
  OneTimeListCriteria create() => OneTimeListCriteria();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OTDSearchCriteria value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OTDSearchCriteria>(value),
    );
  }
}

String _$oneTimeListCriteriaHash() =>
    r'59a470cacdda0dc9fec66e7b92cd96714abb92ca';

abstract class _$OneTimeListCriteria extends $Notifier<OTDSearchCriteria> {
  OTDSearchCriteria build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OTDSearchCriteria, OTDSearchCriteria>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OTDSearchCriteria, OTDSearchCriteria>,
              OTDSearchCriteria,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredOneTimeDeposits)
final filteredOneTimeDepositsProvider = FilteredOneTimeDepositsProvider._();

final class FilteredOneTimeDepositsProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnmodifiableListView<OneTimeDeposit>>,
          UnmodifiableListView<OneTimeDeposit>,
          FutureOr<UnmodifiableListView<OneTimeDeposit>>
        >
    with
        $FutureModifier<UnmodifiableListView<OneTimeDeposit>>,
        $FutureProvider<UnmodifiableListView<OneTimeDeposit>> {
  FilteredOneTimeDepositsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredOneTimeDepositsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredOneTimeDepositsHash();

  @$internal
  @override
  $FutureProviderElement<UnmodifiableListView<OneTimeDeposit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UnmodifiableListView<OneTimeDeposit>> create(Ref ref) {
    return filteredOneTimeDeposits(ref);
  }
}

String _$filteredOneTimeDepositsHash() =>
    r'6657773e188995bbf2a0753edd38294e87c76427';

@ProviderFor(OneTimeDepositsController)
final oneTimeDepositsControllerProvider = OneTimeDepositsControllerProvider._();

final class OneTimeDepositsControllerProvider
    extends
        $StreamNotifierProvider<
          OneTimeDepositsController,
          UnmodifiableListView<OneTimeDeposit>
        > {
  OneTimeDepositsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oneTimeDepositsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oneTimeDepositsControllerHash();

  @$internal
  @override
  OneTimeDepositsController create() => OneTimeDepositsController();
}

String _$oneTimeDepositsControllerHash() =>
    r'e9f08f356b17e99b8a8b2d0418d5d8722be141be';

abstract class _$OneTimeDepositsController
    extends $StreamNotifier<UnmodifiableListView<OneTimeDeposit>> {
  Stream<UnmodifiableListView<OneTimeDeposit>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<UnmodifiableListView<OneTimeDeposit>>,
              UnmodifiableListView<OneTimeDeposit>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<UnmodifiableListView<OneTimeDeposit>>,
                UnmodifiableListView<OneTimeDeposit>
              >,
              AsyncValue<UnmodifiableListView<OneTimeDeposit>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
