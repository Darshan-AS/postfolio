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
    extends $NotifierProvider<RecurringListCriteria, RDSearchCriteria> {
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
  Override overrideWithValue(RDSearchCriteria value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RDSearchCriteria>(value),
    );
  }
}

String _$recurringListCriteriaHash() =>
    r'ec80ae244e29a7499cb936e2c7f9f1038eb13282';

abstract class _$RecurringListCriteria extends $Notifier<RDSearchCriteria> {
  RDSearchCriteria build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RDSearchCriteria, RDSearchCriteria>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RDSearchCriteria, RDSearchCriteria>,
              RDSearchCriteria,
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
    r'93985229e17eadade49342ab5835c02dd4d267f6';

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
    r'5332d1108f8f35511381fba0cea4daeaa18e696b';

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
