// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_time_deposits_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OneTimeDepositsController)
final oneTimeDepositsControllerProvider = OneTimeDepositsControllerProvider._();

final class OneTimeDepositsControllerProvider
    extends
        $AsyncNotifierProvider<
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
    r'93ebe19db2f5a3b72367b928d34b3438e9e67253';

abstract class _$OneTimeDepositsController
    extends $AsyncNotifier<UnmodifiableListView<OneTimeDeposit>> {
  FutureOr<UnmodifiableListView<OneTimeDeposit>> build();
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
