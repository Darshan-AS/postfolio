import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    final authRepository = ref.watch(authRepositoryProvider);
    
    // Listen to Firebase auth state changes
    final authStream = authRepository.authStateChanges;
    final subscription = authStream.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user: user);
      } else {
        state = const AuthState.unauthenticated();
      }
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return const AuthState.initial();
  }

  Future<Result<void, String>> signInWithGoogle() async {
    state = const AuthState.loading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    
    switch (result) {
      case Success():
        // The authStream listener will automatically update the state
        return const Success(null);
      case Failure(error: final error):
        state = AuthState.error(error);
        return Failure(error);
    }
  }

  Future<Result<void, String>> signOut() async {
    state = const AuthState.loading();
    final result = await ref.read(authRepositoryProvider).signOut();
    
    switch (result) {
      case Success():
        // The authStream listener will automatically update the state
        return const Success(null);
      case Failure(error: final error):
        state = AuthState.error(error);
        return Failure(error);
    }
  }
}
