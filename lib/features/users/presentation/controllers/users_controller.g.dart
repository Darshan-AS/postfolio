// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UsersController)
final usersControllerProvider = UsersControllerProvider._();

final class UsersControllerProvider
    extends
        $AsyncNotifierProvider<UsersController, UnmodifiableListView<User>> {
  UsersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usersControllerHash();

  @$internal
  @override
  UsersController create() => UsersController();
}

String _$usersControllerHash() => r'2bd2c087f60141beb5cbd3f209206c8c3bf68baf';

abstract class _$UsersController
    extends $AsyncNotifier<UnmodifiableListView<User>> {
  FutureOr<UnmodifiableListView<User>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<UnmodifiableListView<User>>,
              UnmodifiableListView<User>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<UnmodifiableListView<User>>,
                UnmodifiableListView<User>
              >,
              AsyncValue<UnmodifiableListView<User>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
