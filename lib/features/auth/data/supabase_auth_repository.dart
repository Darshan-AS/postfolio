import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/auth/domain/app_user.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  SupabaseAuthRepository({
    required SupabaseClient supabaseClient,
    required GoogleSignIn googleSignIn,
  })  : _supabaseClient = supabaseClient,
        _googleSignIn = googleSignIn;

  @override
  Stream<AppUser?> get authStateChanges {
    return _supabaseClient.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session == null) return null;
      final user = session.user;
      return AppUser(
        id: user.id,
        email: user.email,
        displayName: user.userMetadata?['full_name'] as String?,
        photoUrl: user.userMetadata?['avatar_url'] as String?,
      );
    });
  }

  @override
  Future<Result<AppUser, String>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Read USE_EMULATOR to determine if we are running locally
        const bool useEmulator = bool.fromEnvironment(
          'USE_EMULATOR',
          defaultValue: false,
        );
        
        // Only override redirectTo in local emulator, otherwise let Supabase use its configured site_url (Prod)
        // We redirect directly to '/login' so GoRouter doesn't strip the '?code=' parameter in an intermediate redirect.
        final String? redirectTo = useEmulator ? 'http://127.0.0.1:3000/login' : null;

        final success = await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
        if (!success) {
          return const Failure('Failed to initiate Google Sign In on Web.');
        }
        // The browser will redirect away. If we reach here on desktop/web,
        // we can just wait for the auth stream to emit the user, so we don't
        // prematurely return anything that might stop a loading indicator.
        await Future.delayed(const Duration(hours: 1));
        return const Failure('Redirecting...');
      }

      // Ensure GoogleSignIn is initialized with the Web Client ID
      await _googleSignIn.initialize(
        clientId: kIsWeb ? Env.googleWebClientId : null,
        serverClientId: Env.googleWebClientId,
      );

      final googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return const Failure('No ID token found from Google Sign-In.');
      }

      String? accessToken;
      try {
        final scopesClient = await googleUser.authorizationClient.authorizationForScopes([]);
        accessToken = scopesClient?.accessToken;
      } catch (_) {}

      final AuthResponse response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        return const Failure('Sign in failed, Supabase user is null');
      }

      return Success(
        AppUser(
          id: user.id,
          email: user.email,
          displayName: user.userMetadata?['full_name'] as String?,
          photoUrl: user.userMetadata?['avatar_url'] as String?,
        ),
      );
    } catch (e) {
      return Failure('Failed to sign in with Google (Supabase): $e');
    }
  }

  @override
  Future<Result<void, String>> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _supabaseClient.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure('Failed to sign out (Supabase): $e');
    }
  }
}
