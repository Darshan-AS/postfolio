// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_deposits_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecurringListCriteria)
final recurringListCriteriaProvider = RecurringListCriteriaProvider._();

final class RecurringListCriteriaProvider
    extends $NotifierProvider<RecurringListCriteria, ListCriteria> {
  RecurringListCriteriaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringListCriteriaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringListCriteriaHash();

  @$internal
  @override
  RecurringListCriteria create() => RecurringListCriteria();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListCriteria value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListCriteria>(value),
    );
  }
}

String _$recurringListCriteriaHash() =>
    r'2d8010e3b286767a96101025e3ea96df90ea5704';

abstract class _$RecurringListCriteria extends $Notifier<ListCriteria> {
  ListCriteria build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ListCriteria, ListCriteria>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ListCriteria, ListCriteria>,
              ListCriteria,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredRecurringDeposits)
final filteredRecurringDepositsProvider = FilteredRecurringDepositsProvider._();

final class FilteredRecurringDepositsProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnmodifiableListView<RecurringDeposit>>,
          UnmodifiableListView<RecurringDeposit>,
          FutureOr<UnmodifiableListView<RecurringDeposit>>
        >
    with
        $FutureModifier<UnmodifiableListView<RecurringDeposit>>,
        $FutureProvider<UnmodifiableListView<RecurringDeposit>> {
  FilteredRecurringDepositsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredRecurringDepositsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredRecurringDepositsHash();

  @$internal
  @override
  $FutureProviderElement<UnmodifiableListView<RecurringDeposit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UnmodifiableListView<RecurringDeposit>> create(Ref ref) {
    return filteredRecurringDeposits(ref);
  }
}

String _$filteredRecurringDepositsHash() =>
    r'0b1be624b466c2496ed0f1e6fc2b2a7bc1b8a233';

@ProviderFor(RecurringDepositsController)
final recurringDepositsControllerProvider =
    RecurringDepositsControllerProvider._();

final class RecurringDepositsControllerProvider
    extends
        $StreamNotifierProvider<
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
    r'9db5c1c4ae7feccae2e771edb14e09a356e49fa4';

abstract class _$RecurringDepositsController
    extends $StreamNotifier<UnmodifiableListView<RecurringDeposit>> {
  Stream<UnmodifiableListView<RecurringDeposit>> build();
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
