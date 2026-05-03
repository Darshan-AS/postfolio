import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:postfolio/features/auth/domain/app_user.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@riverpod
GoogleSignIn googleSignIn(Ref ref) {
  // Return the singleton instance for GoogleSignIn 7.0.0+
  return GoogleSignIn.instance;
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      if (user == null) return null;
      return AppUser(
        id: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    });
  }

  Future<Result<AppUser, String>> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.addScope('email');
        // On web, use Firebase's native popup which avoids the UnimplementedError from google_sign_in's authenticate()
        userCredential = await _firebaseAuth.signInWithPopup(authProvider);
      } else {
        // Ensure GoogleSignIn is initialized (7.0.0+)
        // Android's Credential Manager requires the Web Client ID (serverClientId) to issue an idToken
        await _googleSignIn.initialize(
          serverClientId: AppConstants.webClientId,
        );

        final googleUser = await _googleSignIn.authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        String? accessToken;
        try {
          // On mobile, we might need access token, and it's fetched via authorizationClient.
          final authClient = await googleUser.authorizationClient
              .authorizationForScopes([]);
          accessToken = authClient?.accessToken;
        } catch (_) {
          // Ignore if access token fetching fails, idToken is usually enough.
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: accessToken,
        );

        userCredential = await _firebaseAuth
            .signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        return const Failure('Sign in failed, user is null');
      }

      return Success(AppUser(
        id: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      ));
    } catch (e) {
      return Failure('Failed to sign in with Google: $e');
    }
  }

  Future<Result<void, String>> signOut() async {
    try {
      if (!kIsWeb) {
         await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure('Failed to sign out: $e');
    }
  }
}
