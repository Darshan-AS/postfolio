import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

@freezed
sealed class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    String? email,
    String? displayName,
    String? photoUrl,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
