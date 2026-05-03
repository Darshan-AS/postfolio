import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/auth/domain/app_user.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.authenticated({required AppUser user}) = AuthStateAuthenticated;
  const factory AuthState.error(String message) = AuthStateError;
}
