// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'savings_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavingsAccount {

 String get accountNumber; Nominee? get nominee;
/// Create a copy of SavingsAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavingsAccountCopyWith<SavingsAccount> get copyWith => _$SavingsAccountCopyWithImpl<SavingsAccount>(this as SavingsAccount, _$identity);

  /// Serializes this SavingsAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavingsAccount&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.nominee, nominee) || other.nominee == nominee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountNumber,nominee);

@override
String toString() {
  return 'SavingsAccount(accountNumber: $accountNumber, nominee: $nominee)';
}


}

/// @nodoc
abstract mixin class $SavingsAccountCopyWith<$Res>  {
  factory $SavingsAccountCopyWith(SavingsAccount value, $Res Function(SavingsAccount) _then) = _$SavingsAccountCopyWithImpl;
@useResult
$Res call({
 String accountNumber, Nominee? nominee
});


$NomineeCopyWith<$Res>? get nominee;

}
/// @nodoc
class _$SavingsAccountCopyWithImpl<$Res>
    implements $SavingsAccountCopyWith<$Res> {
  _$SavingsAccountCopyWithImpl(this._self, this._then);

  final SavingsAccount _self;
  final $Res Function(SavingsAccount) _then;

/// Create a copy of SavingsAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountNumber = null,Object? nominee = freezed,}) {
  return _then(_self.copyWith(
accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,nominee: freezed == nominee ? _self.nominee : nominee // ignore: cast_nullable_to_non_nullable
as Nominee?,
  ));
}
/// Create a copy of SavingsAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NomineeCopyWith<$Res>? get nominee {
    if (_self.nominee == null) {
    return null;
  }

  return $NomineeCopyWith<$Res>(_self.nominee!, (value) {
    return _then(_self.copyWith(nominee: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavingsAccount].
extension SavingsAccountPatterns on SavingsAccount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavingsAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavingsAccount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavingsAccount value)  $default,){
final _that = this;
switch (_that) {
case _SavingsAccount():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavingsAccount value)?  $default,){
final _that = this;
switch (_that) {
case _SavingsAccount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountNumber,  Nominee? nominee)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavingsAccount() when $default != null:
return $default(_that.accountNumber,_that.nominee);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountNumber,  Nominee? nominee)  $default,) {final _that = this;
switch (_that) {
case _SavingsAccount():
return $default(_that.accountNumber,_that.nominee);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountNumber,  Nominee? nominee)?  $default,) {final _that = this;
switch (_that) {
case _SavingsAccount() when $default != null:
return $default(_that.accountNumber,_that.nominee);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavingsAccount extends SavingsAccount {
  const _SavingsAccount({required this.accountNumber, this.nominee}): super._();
  factory _SavingsAccount.fromJson(Map<String, dynamic> json) => _$SavingsAccountFromJson(json);

@override final  String accountNumber;
@override final  Nominee? nominee;

/// Create a copy of SavingsAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavingsAccountCopyWith<_SavingsAccount> get copyWith => __$SavingsAccountCopyWithImpl<_SavingsAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavingsAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavingsAccount&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.nominee, nominee) || other.nominee == nominee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountNumber,nominee);

@override
String toString() {
  return 'SavingsAccount(accountNumber: $accountNumber, nominee: $nominee)';
}


}

/// @nodoc
abstract mixin class _$SavingsAccountCopyWith<$Res> implements $SavingsAccountCopyWith<$Res> {
  factory _$SavingsAccountCopyWith(_SavingsAccount value, $Res Function(_SavingsAccount) _then) = __$SavingsAccountCopyWithImpl;
@override @useResult
$Res call({
 String accountNumber, Nominee? nominee
});


@override $NomineeCopyWith<$Res>? get nominee;

}
/// @nodoc
class __$SavingsAccountCopyWithImpl<$Res>
    implements _$SavingsAccountCopyWith<$Res> {
  __$SavingsAccountCopyWithImpl(this._self, this._then);

  final _SavingsAccount _self;
  final $Res Function(_SavingsAccount) _then;

/// Create a copy of SavingsAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountNumber = null,Object? nominee = freezed,}) {
  return _then(_SavingsAccount(
accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,nominee: freezed == nominee ? _self.nominee : nominee // ignore: cast_nullable_to_non_nullable
as Nominee?,
  ));
}

/// Create a copy of SavingsAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NomineeCopyWith<$Res>? get nominee {
    if (_self.nominee == null) {
    return null;
  }

  return $NomineeCopyWith<$Res>(_self.nominee!, (value) {
    return _then(_self.copyWith(nominee: value));
  });
}
}

// dart format on
