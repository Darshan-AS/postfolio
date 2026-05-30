// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListCriteria {

 String get searchQuery; SortOption get sortBy; List<DepositStatus> get activeFilters;
/// Create a copy of ListCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListCriteriaCopyWith<ListCriteria> get copyWith => _$ListCriteriaCopyWithImpl<ListCriteria>(this as ListCriteria, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other.activeFilters, activeFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy,const DeepCollectionEquality().hash(activeFilters));

@override
String toString() {
  return 'ListCriteria(searchQuery: $searchQuery, sortBy: $sortBy, activeFilters: $activeFilters)';
}


}

/// @nodoc
abstract mixin class $ListCriteriaCopyWith<$Res>  {
  factory $ListCriteriaCopyWith(ListCriteria value, $Res Function(ListCriteria) _then) = _$ListCriteriaCopyWithImpl;
@useResult
$Res call({
 String searchQuery, SortOption sortBy, List<DepositStatus> activeFilters
});




}
/// @nodoc
class _$ListCriteriaCopyWithImpl<$Res>
    implements $ListCriteriaCopyWith<$Res> {
  _$ListCriteriaCopyWithImpl(this._self, this._then);

  final ListCriteria _self;
  final $Res Function(ListCriteria) _then;

/// Create a copy of ListCriteria
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? sortBy = null,Object? activeFilters = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortOption,activeFilters: null == activeFilters ? _self.activeFilters : activeFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,
  ));
}

}


/// Adds pattern-matching-related methods to [ListCriteria].
extension ListCriteriaPatterns on ListCriteria {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListCriteria value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListCriteria() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListCriteria value)  $default,){
final _that = this;
switch (_that) {
case _ListCriteria():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListCriteria value)?  $default,){
final _that = this;
switch (_that) {
case _ListCriteria() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String searchQuery,  SortOption sortBy,  List<DepositStatus> activeFilters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListCriteria() when $default != null:
return $default(_that.searchQuery,_that.sortBy,_that.activeFilters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String searchQuery,  SortOption sortBy,  List<DepositStatus> activeFilters)  $default,) {final _that = this;
switch (_that) {
case _ListCriteria():
return $default(_that.searchQuery,_that.sortBy,_that.activeFilters);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String searchQuery,  SortOption sortBy,  List<DepositStatus> activeFilters)?  $default,) {final _that = this;
switch (_that) {
case _ListCriteria() when $default != null:
return $default(_that.searchQuery,_that.sortBy,_that.activeFilters);case _:
  return null;

}
}

}

/// @nodoc


class _ListCriteria implements ListCriteria {
  const _ListCriteria({this.searchQuery = '', this.sortBy = SortOption.newest, final  List<DepositStatus> activeFilters = const []}): _activeFilters = activeFilters;
  

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  SortOption sortBy;
 final  List<DepositStatus> _activeFilters;
@override@JsonKey() List<DepositStatus> get activeFilters {
  if (_activeFilters is EqualUnmodifiableListView) return _activeFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeFilters);
}


/// Create a copy of ListCriteria
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListCriteriaCopyWith<_ListCriteria> get copyWith => __$ListCriteriaCopyWithImpl<_ListCriteria>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other._activeFilters, _activeFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy,const DeepCollectionEquality().hash(_activeFilters));

@override
String toString() {
  return 'ListCriteria(searchQuery: $searchQuery, sortBy: $sortBy, activeFilters: $activeFilters)';
}


}

/// @nodoc
abstract mixin class _$ListCriteriaCopyWith<$Res> implements $ListCriteriaCopyWith<$Res> {
  factory _$ListCriteriaCopyWith(_ListCriteria value, $Res Function(_ListCriteria) _then) = __$ListCriteriaCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, SortOption sortBy, List<DepositStatus> activeFilters
});




}
/// @nodoc
class __$ListCriteriaCopyWithImpl<$Res>
    implements _$ListCriteriaCopyWith<$Res> {
  __$ListCriteriaCopyWithImpl(this._self, this._then);

  final _ListCriteria _self;
  final $Res Function(_ListCriteria) _then;

/// Create a copy of ListCriteria
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? sortBy = null,Object? activeFilters = null,}) {
  return _then(_ListCriteria(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortOption,activeFilters: null == activeFilters ? _self._activeFilters : activeFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,
  ));
}


}

// dart format on
