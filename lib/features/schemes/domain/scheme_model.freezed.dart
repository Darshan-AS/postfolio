// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheme_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Scheme {

 String get id; String get name; bool get isVariableTerm; int get termYears; int get termMonths; double get baseInterestRate;
/// Create a copy of Scheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchemeCopyWith<Scheme> get copyWith => _$SchemeCopyWithImpl<Scheme>(this as Scheme, _$identity);

  /// Serializes this Scheme to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Scheme&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVariableTerm, isVariableTerm) || other.isVariableTerm == isVariableTerm)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.baseInterestRate, baseInterestRate) || other.baseInterestRate == baseInterestRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVariableTerm,termYears,termMonths,baseInterestRate);

@override
String toString() {
  return 'Scheme(id: $id, name: $name, isVariableTerm: $isVariableTerm, termYears: $termYears, termMonths: $termMonths, baseInterestRate: $baseInterestRate)';
}


}

/// @nodoc
abstract mixin class $SchemeCopyWith<$Res>  {
  factory $SchemeCopyWith(Scheme value, $Res Function(Scheme) _then) = _$SchemeCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isVariableTerm, int termYears, int termMonths, double baseInterestRate
});




}
/// @nodoc
class _$SchemeCopyWithImpl<$Res>
    implements $SchemeCopyWith<$Res> {
  _$SchemeCopyWithImpl(this._self, this._then);

  final Scheme _self;
  final $Res Function(Scheme) _then;

/// Create a copy of Scheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isVariableTerm = null,Object? termYears = null,Object? termMonths = null,Object? baseInterestRate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVariableTerm: null == isVariableTerm ? _self.isVariableTerm : isVariableTerm // ignore: cast_nullable_to_non_nullable
as bool,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,baseInterestRate: null == baseInterestRate ? _self.baseInterestRate : baseInterestRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Scheme].
extension SchemePatterns on Scheme {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Scheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Scheme() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Scheme value)  $default,){
final _that = this;
switch (_that) {
case _Scheme():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Scheme value)?  $default,){
final _that = this;
switch (_that) {
case _Scheme() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isVariableTerm,  int termYears,  int termMonths,  double baseInterestRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Scheme() when $default != null:
return $default(_that.id,_that.name,_that.isVariableTerm,_that.termYears,_that.termMonths,_that.baseInterestRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isVariableTerm,  int termYears,  int termMonths,  double baseInterestRate)  $default,) {final _that = this;
switch (_that) {
case _Scheme():
return $default(_that.id,_that.name,_that.isVariableTerm,_that.termYears,_that.termMonths,_that.baseInterestRate);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isVariableTerm,  int termYears,  int termMonths,  double baseInterestRate)?  $default,) {final _that = this;
switch (_that) {
case _Scheme() when $default != null:
return $default(_that.id,_that.name,_that.isVariableTerm,_that.termYears,_that.termMonths,_that.baseInterestRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Scheme implements Scheme {
  const _Scheme({required this.id, required this.name, required this.isVariableTerm, this.termYears = 0, this.termMonths = 0, this.baseInterestRate = 0.0});
  factory _Scheme.fromJson(Map<String, dynamic> json) => _$SchemeFromJson(json);

@override final  String id;
@override final  String name;
@override final  bool isVariableTerm;
@override@JsonKey() final  int termYears;
@override@JsonKey() final  int termMonths;
@override@JsonKey() final  double baseInterestRate;

/// Create a copy of Scheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchemeCopyWith<_Scheme> get copyWith => __$SchemeCopyWithImpl<_Scheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SchemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Scheme&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVariableTerm, isVariableTerm) || other.isVariableTerm == isVariableTerm)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.baseInterestRate, baseInterestRate) || other.baseInterestRate == baseInterestRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVariableTerm,termYears,termMonths,baseInterestRate);

@override
String toString() {
  return 'Scheme(id: $id, name: $name, isVariableTerm: $isVariableTerm, termYears: $termYears, termMonths: $termMonths, baseInterestRate: $baseInterestRate)';
}


}

/// @nodoc
abstract mixin class _$SchemeCopyWith<$Res> implements $SchemeCopyWith<$Res> {
  factory _$SchemeCopyWith(_Scheme value, $Res Function(_Scheme) _then) = __$SchemeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isVariableTerm, int termYears, int termMonths, double baseInterestRate
});




}
/// @nodoc
class __$SchemeCopyWithImpl<$Res>
    implements _$SchemeCopyWith<$Res> {
  __$SchemeCopyWithImpl(this._self, this._then);

  final _Scheme _self;
  final $Res Function(_Scheme) _then;

/// Create a copy of Scheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isVariableTerm = null,Object? termYears = null,Object? termMonths = null,Object? baseInterestRate = null,}) {
  return _then(_Scheme(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVariableTerm: null == isVariableTerm ? _self.isVariableTerm : isVariableTerm // ignore: cast_nullable_to_non_nullable
as bool,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,baseInterestRate: null == baseInterestRate ? _self.baseInterestRate : baseInterestRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
