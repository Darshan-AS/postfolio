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
    r'83d4f23abc87e3a8758fbe7c373a96d4fb8d7f87';

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
