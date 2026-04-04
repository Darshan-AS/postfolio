import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/users/domain/user_model.dart';
import 'package:uuid/uuid.dart';

abstract class UserRepository {
  Future<Result<List<User>, String>> fetchUsers();
  Future<Result<void, String>> createUser(User user);
  Future<Result<void, String>> updateUser(User user);
  Future<Result<void, String>> deleteUser(String id);
}

class FakeUserRepository implements UserRepository {
  final List<User> _users = [
    const User(id: '1', name: 'Abdul Khalandar', phone: '9148173207'),
    const User(id: '2', name: 'Darshan A S', phone: '9876543210'),
    const User(id: '3', name: 'Jane Doe', email: 'jane@example.com'),
  ];

  @override
  Future<Result<List<User>, String>> fetchUsers() async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network latency
    return Success([..._users]);
  }

  @override
  Future<Result<void, String>> createUser(User user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newUser = user.copyWith(id: const Uuid().v4());
    _users.add(newUser);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateUser(User user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      return const Success(null);
    }
    return const Failure('User not found');
  }

  @override
  Future<Result<void, String>> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _users.length;
    _users.removeWhere((u) => u.id == id);
    if (_users.length < initialLength) {
      return const Success(null);
    }
    return const Failure('User not found');
  }
}

// Global Provider for the Repository.
// When we move to Firebase, we simply swap FakeUserRepository() for FirestoreUserRepository() here!
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FakeUserRepository();
});
