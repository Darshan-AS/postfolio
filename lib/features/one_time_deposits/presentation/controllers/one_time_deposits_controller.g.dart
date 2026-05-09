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
    r'a35637d63c7eecc3d8ed17ba526b30871ce99a1a';

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
