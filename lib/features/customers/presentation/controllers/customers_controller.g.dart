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
    r'7ae1345751f1a5c542da4e8e0f7fe351910f9839';

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
