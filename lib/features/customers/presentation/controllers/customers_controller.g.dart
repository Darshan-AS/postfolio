// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomerListCriteria)
final customerListCriteriaProvider = CustomerListCriteriaProvider._();

final class CustomerListCriteriaProvider
    extends $NotifierProvider<CustomerListCriteria, CustomerSearchCriteria> {
  CustomerListCriteriaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerListCriteriaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerListCriteriaHash();

  @$internal
  @override
  CustomerListCriteria create() => CustomerListCriteria();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerSearchCriteria value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerSearchCriteria>(value),
    );
  }
}

String _$customerListCriteriaHash() =>
    r'7a4a607f06b86b5a57d3780065ab25b2a55677ca';

abstract class _$CustomerListCriteria
    extends $Notifier<CustomerSearchCriteria> {
  CustomerSearchCriteria build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<CustomerSearchCriteria, CustomerSearchCriteria>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CustomerSearchCriteria, CustomerSearchCriteria>,
              CustomerSearchCriteria,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredCustomers)
final filteredCustomersProvider = FilteredCustomersProvider._();

final class FilteredCustomersProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnmodifiableListView<Customer>>,
          UnmodifiableListView<Customer>,
          FutureOr<UnmodifiableListView<Customer>>
        >
    with
        $FutureModifier<UnmodifiableListView<Customer>>,
        $FutureProvider<UnmodifiableListView<Customer>> {
  FilteredCustomersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredCustomersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredCustomersHash();

  @$internal
  @override
  $FutureProviderElement<UnmodifiableListView<Customer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UnmodifiableListView<Customer>> create(Ref ref) {
    return filteredCustomers(ref);
  }
}

String _$filteredCustomersHash() => r'3a36d536372db049992e98cc6888b00fcbdfe043';

@ProviderFor(CustomersController)
final customersControllerProvider = CustomersControllerProvider._();

final class CustomersControllerProvider
    extends
        $StreamNotifierProvider<
          CustomersController,
          UnmodifiableListView<Customer>
        > {
  CustomersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customersControllerHash();

  @$internal
  @override
  CustomersController create() => CustomersController();
}

String _$customersControllerHash() =>
    r'66f167d1de442284b3d6d56a4177c100ec88a317';

abstract class _$CustomersController
    extends $StreamNotifier<UnmodifiableListView<Customer>> {
  Stream<UnmodifiableListView<Customer>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<UnmodifiableListView<Customer>>,
              UnmodifiableListView<Customer>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<UnmodifiableListView<Customer>>,
                UnmodifiableListView<Customer>
              >,
              AsyncValue<UnmodifiableListView<Customer>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(customerById)
final customerByIdProvider = CustomerByIdFamily._();

final class CustomerByIdProvider
    extends
        $FunctionalProvider<AsyncValue<Customer>, Customer, Stream<Customer>>
    with $FutureModifier<Customer>, $StreamProvider<Customer> {
  CustomerByIdProvider._({
    required CustomerByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerByIdHash();

  @override
  String toString() {
    return r'customerByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Customer> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Customer> create(Ref ref) {
    final argument = this.argument as String;
    return customerById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerByIdHash() => r'a5973a8e3130cf53db6487ef7817b4aad03fec04';

final class CustomerByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Customer>, String> {
  CustomerByIdFamily._()
    : super(
        retry: null,
        name: r'customerByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerByIdProvider call(String id) =>
      CustomerByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'customerByIdProvider';
}
