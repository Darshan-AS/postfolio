// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomersController)
final customersControllerProvider = CustomersControllerProvider._();

final class CustomersControllerProvider
    extends
        $AsyncNotifierProvider<
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
    r'e8eb91387b645d5eb3f3e4e23669a316fa9b0777';

abstract class _$CustomersController
    extends $AsyncNotifier<UnmodifiableListView<Customer>> {
  FutureOr<UnmodifiableListView<Customer>> build();
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
    extends $FunctionalProvider<Customer?, Customer?, Customer?>
    with $Provider<Customer?> {
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
  $ProviderElement<Customer?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Customer? create(Ref ref) {
    final argument = this.argument as String;
    return customerById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Customer? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Customer?>(value),
    );
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

String _$customerByIdHash() => r'6808e6a3fff55554e13fc6c2055aea4f70bead37';

final class CustomerByIdFamily extends $Family
    with $FunctionalFamilyOverride<Customer?, String> {
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
