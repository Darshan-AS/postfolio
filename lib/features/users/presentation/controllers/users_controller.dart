import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/users/domain/user_model.dart';
import 'package:postfolio/features/users/data/user_repository.dart';

part 'users_controller.g.dart';

@riverpod
class UsersController extends _$UsersController {
  @override
  FutureOr<UnmodifiableListView<User>> build() async {
    return _fetchUsers();
  }

  Future<UnmodifiableListView<User>> _fetchUsers() async {
    final repository = ref.read(userRepositoryProvider);
    final result = await repository.fetchUsers();
    
    return switch (result) {
      Success(value: final users) => UnmodifiableListView(users),
      Failure(error: final error) => throw Exception(error),
    };
  }

  Future<Result<void, String>> saveUser({
    String? id,
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    final (error, user) = User.create(
      id: id ?? '', // FakeRepo will assign a real ID if creating
      name: name,
      email: email,
      phone: phone,
      address: address,
    );

    if (error != null || user == null) {
      return Failure(error ?? 'Invalid user data provided');
    }

    final repository = ref.read(userRepositoryProvider);
    final Result<void, String> result = id != null 
        ? await repository.updateUser(user) 
        : await repository.createUser(user);

    return switch (result) {
      Success() => () {
        ref.invalidateSelf(); // Triggers a re-fetch and rebuild
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteUser(String id) async {
    final repository = ref.read(userRepositoryProvider);
    final result = await repository.deleteUser(id);
    
    return switch (result) {
      Success() => () {
        ref.invalidateSelf();
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }
}
