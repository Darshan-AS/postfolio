// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rd_search_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RDSearchCriteria {

 String get searchQuery; RDSortOption get sortBy; List<DepositStatus> get statusFilters;
/// Create a copy of RDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RDSearchCriteriaCopyWith<RDSearchCriteria> get copyWith => _$RDSearchCriteriaCopyWithImpl<RDSearchCriteria>(this as RDSearchCriteria, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RDSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other.statusFilters, statusFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy,const DeepCollectionEquality().hash(statusFilters));

@override
String toString() {
  return 'RDSearchCriteria(searchQuery: $searchQuery, sortBy: $sortBy, statusFilters: $statusFilters)';
}


}

/// @nodoc
abstract mixin class $RDSearchCriteriaCopyWith<$Res>  {
  factory $RDSearchCriteriaCopyWith(RDSearchCriteria value, $Res Function(RDSearchCriteria) _then) = _$RDSearchCriteriaCopyWithImpl;
@useResult
$Res call({
 String searchQuery, RDSortOption sortBy, List<DepositStatus> statusFilters
});




}
/// @nodoc
class _$RDSearchCriteriaCopyWithImpl<$Res>
    implements $RDSearchCriteriaCopyWith<$Res> {
  _$RDSearchCriteriaCopyWithImpl(this._self, this._then);

  final RDSearchCriteria _self;
  final $Res Function(RDSearchCriteria) _then;

/// Create a copy of RDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? sortBy = null,Object? statusFilters = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as RDSortOption,statusFilters: null == statusFilters ? _self.statusFilters : statusFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,
  ));
}

}


/// Adds pattern-matching-related methods to [RDSearchCriteria].
extension RDSearchCriteriaPatterns on RDSearchCriteria {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RDSearchCriteria value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RDSearchCriteria() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RDSearchCriteria value)  $default,){
final _that = this;
switch (_that) {
case _RDSearchCriteria():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RDSearchCriteria value)?  $default,){
final _that = this;
switch (_that) {
case _RDSearchCriteria() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String searchQuery,  RDSortOption sortBy,  List<DepositStatus> statusFilters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RDSearchCriteria() when $default != null:
return $default(_that.searchQuery,_that.sortBy,_that.statusFilters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String searchQuery,  RDSortOption sortBy,  List<DepositStatus> statusFilters)  $default,) {final _that = this;
switch (_that) {
case _RDSearchCriteria():
return $default(_that.searchQuery,_that.sortBy,_that.statusFilters);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String searchQuery,  RDSortOption sortBy,  List<DepositStatus> statusFilters)?  $default,) {final _that = this;
switch (_that) {
case _RDSearchCriteria() when $default != null:
return $default(_that.searchQuery,_that.sortBy,_that.statusFilters);case _:
  return null;

}
}

}

/// @nodoc


class _RDSearchCriteria implements RDSearchCriteria {
  const _RDSearchCriteria({this.searchQuery = '', this.sortBy = RDSortOption.maturityAsc, final  List<DepositStatus> statusFilters = const []}): _statusFilters = statusFilters;
  

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  RDSortOption sortBy;
 final  List<DepositStatus> _statusFilters;
@override@JsonKey() List<DepositStatus> get statusFilters {
  if (_statusFilters is EqualUnmodifiableListView) return _statusFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statusFilters);
}


/// Create a copy of RDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RDSearchCriteriaCopyWith<_RDSearchCriteria> get copyWith => __$RDSearchCriteriaCopyWithImpl<_RDSearchCriteria>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RDSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other._statusFilters, _statusFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy,const DeepCollectionEquality().hash(_statusFilters));

@override
String toString() {
  return 'RDSearchCriteria(searchQuery: $searchQuery, sortBy: $sortBy, statusFilters: $statusFilters)';
}


}

/// @nodoc
abstract mixin class _$RDSearchCriteriaCopyWith<$Res> implements $RDSearchCriteriaCopyWith<$Res> {
  factory _$RDSearchCriteriaCopyWith(_RDSearchCriteria value, $Res Function(_RDSearchCriteria) _then) = __$RDSearchCriteriaCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, RDSortOption sortBy, List<DepositStatus> statusFilters
});




}
/// @nodoc
class __$RDSearchCriteriaCopyWithImpl<$Res>
    implements _$RDSearchCriteriaCopyWith<$Res> {
  __$RDSearchCriteriaCopyWithImpl(this._self, this._then);

  final _RDSearchCriteria _self;
  final $Res Function(_RDSearchCriteria) _then;

/// Create a copy of RDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? sortBy = null,Object? statusFilters = null,}) {
  return _then(_RDSearchCriteria(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as RDSortOption,statusFilters: null == statusFilters ? _self._statusFilters : statusFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,
  ));
}


}

// dart format on
