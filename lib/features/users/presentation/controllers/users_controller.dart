import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/features/users/domain/user_model.dart';
import 'package:postfolio/features/users/data/user_repository.dart';

part 'users_controller.g.dart';

@riverpod
class UsersController extends _$UsersController {
  @override
  FutureOr<List<User>> build() async {
    return _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    final repository = ref.read(userRepositoryProvider);
    return repository.fetchUsers();
  }

  Future<void> createUser(User user) async {
    // Set state to loading while we perform the network request
    state = const AsyncValue.loading();
    // guard safely catches any errors and sets state to AsyncError if it fails
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      await repository.createUser(user);
      // Re-fetch the list to ensure our state matches the database exactly
      return _fetchUsers();
    });
  }

  Future<void> updateUser(User user) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      await repository.updateUser(user);
      return _fetchUsers();
    });
  }

  Future<void> deleteUser(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      await repository.deleteUser(id);
      return _fetchUsers();
    });
  }
}
