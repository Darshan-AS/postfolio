// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nominee.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Nominee {

 String get name; String get relationship;// e.g., "Spouse", "Son"
 double get percentage;
/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NomineeCopyWith<Nominee> get copyWith => _$NomineeCopyWithImpl<Nominee>(this as Nominee, _$identity);

  /// Serializes this Nominee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nominee&&(identical(other.name, name) || other.name == name)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.percentage, percentage) || other.percentage == percentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,relationship,percentage);

@override
String toString() {
  return 'Nominee(name: $name, relationship: $relationship, percentage: $percentage)';
}


}

/// @nodoc
abstract mixin class $NomineeCopyWith<$Res>  {
  factory $NomineeCopyWith(Nominee value, $Res Function(Nominee) _then) = _$NomineeCopyWithImpl;
@useResult
$Res call({
 String name, String relationship, double percentage
});




}
/// @nodoc
class _$NomineeCopyWithImpl<$Res>
    implements $NomineeCopyWith<$Res> {
  _$NomineeCopyWithImpl(this._self, this._then);

  final Nominee _self;
  final $Res Function(Nominee) _then;

/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? relationship = null,Object? percentage = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Nominee].
extension NomineePatterns on Nominee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Nominee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Nominee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Nominee value)  $default,){
final _that = this;
switch (_that) {
case _Nominee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Nominee value)?  $default,){
final _that = this;
switch (_that) {
case _Nominee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String relationship,  double percentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Nominee() when $default != null:
return $default(_that.name,_that.relationship,_that.percentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String relationship,  double percentage)  $default,) {final _that = this;
switch (_that) {
case _Nominee():
return $default(_that.name,_that.relationship,_that.percentage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String relationship,  double percentage)?  $default,) {final _that = this;
switch (_that) {
case _Nominee() when $default != null:
return $default(_that.name,_that.relationship,_that.percentage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Nominee extends Nominee {
  const _Nominee({required this.name, required this.relationship, required this.percentage}): super._();
  factory _Nominee.fromJson(Map<String, dynamic> json) => _$NomineeFromJson(json);

@override final  String name;
@override final  String relationship;
// e.g., "Spouse", "Son"
@override final  double percentage;

/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NomineeCopyWith<_Nominee> get copyWith => __$NomineeCopyWithImpl<_Nominee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NomineeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Nominee&&(identical(other.name, name) || other.name == name)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.percentage, percentage) || other.percentage == percentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,relationship,percentage);

@override
String toString() {
  return 'Nominee(name: $name, relationship: $relationship, percentage: $percentage)';
}


}

/// @nodoc
abstract mixin class _$NomineeCopyWith<$Res> implements $NomineeCopyWith<$Res> {
  factory _$NomineeCopyWith(_Nominee value, $Res Function(_Nominee) _then) = __$NomineeCopyWithImpl;
@override @useResult
$Res call({
 String name, String relationship, double percentage
});




}
/// @nodoc
class __$NomineeCopyWithImpl<$Res>
    implements _$NomineeCopyWith<$Res> {
  __$NomineeCopyWithImpl(this._self, this._then);

  final _Nominee _self;
  final $Res Function(_Nominee) _then;

/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? relationship = null,Object? percentage = null,}) {
  return _then(_Nominee(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
