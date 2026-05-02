// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_deposits_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecurringDepositsController)
final recurringDepositsControllerProvider =
    RecurringDepositsControllerProvider._();

final class RecurringDepositsControllerProvider
    extends
        $AsyncNotifierProvider<
          RecurringDepositsController,
          UnmodifiableListView<RecurringDeposit>
        > {
  RecurringDepositsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringDepositsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringDepositsControllerHash();

  @$internal
  @override
  RecurringDepositsController create() => RecurringDepositsController();
}

String _$recurringDepositsControllerHash() =>
    r'd64b7ee4a83fedabbc5be61e56b33843f64fdfbe';

abstract class _$RecurringDepositsController
    extends $AsyncNotifier<UnmodifiableListView<RecurringDeposit>> {
  FutureOr<UnmodifiableListView<RecurringDeposit>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<UnmodifiableListView<RecurringDeposit>>,
              UnmodifiableListView<RecurringDeposit>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<UnmodifiableListView<RecurringDeposit>>,
                UnmodifiableListView<RecurringDeposit>
              >,
              AsyncValue<UnmodifiableListView<RecurringDeposit>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
