import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/auth/data/supabase_auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
GoogleSignIn googleSignIn(Ref ref) => GoogleSignIn.instance;

@riverpod
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(
    supabaseClient: ref.watch(supabaseClientProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<Result<AuthUser, String>> signInWithGoogle();
  Future<Result<void, String>> signOut();
}

/// Deterministic in-memory auth repository for unit and router tests (zero Mockito).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  String? signInError;
  String? signOutError;
  int signOutCount = 0;

  void emit(AuthUser? user) {
    _currentUser = user;
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<Result<AuthUser, String>> signInWithGoogle() async {
    if (signInError != null) return Failure(signInError!);
    final user = _currentUser ??
        const AuthUser(
          id: 'fake-agent-1',
          email: 'agent@postfolio.com',
          displayName: 'Fake Agent',
        );
    _currentUser = user;
    return Success(user);
  }

  @override
  Future<Result<void, String>> signOut() async {
    if (signOutError != null) return Failure(signOutError!);
    signOutCount++;
    emit(null);
    return const Success(null);
  }

  void dispose() {
    _controller.close();
  }
}
