// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_search_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerSearchCriteria {

 String get searchQuery; CustomerSortOption get sortBy;
/// Create a copy of CustomerSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerSearchCriteriaCopyWith<CustomerSearchCriteria> get copyWith => _$CustomerSearchCriteriaCopyWithImpl<CustomerSearchCriteria>(this as CustomerSearchCriteria, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy);

@override
String toString() {
  return 'CustomerSearchCriteria(searchQuery: $searchQuery, sortBy: $sortBy)';
}


}

/// @nodoc
abstract mixin class $CustomerSearchCriteriaCopyWith<$Res>  {
  factory $CustomerSearchCriteriaCopyWith(CustomerSearchCriteria value, $Res Function(CustomerSearchCriteria) _then) = _$CustomerSearchCriteriaCopyWithImpl;
@useResult
$Res call({
 String searchQuery, CustomerSortOption sortBy
});




}
/// @nodoc
class _$CustomerSearchCriteriaCopyWithImpl<$Res>
    implements $CustomerSearchCriteriaCopyWith<$Res> {
  _$CustomerSearchCriteriaCopyWithImpl(this._self, this._then);

  final CustomerSearchCriteria _self;
  final $Res Function(CustomerSearchCriteria) _then;

/// Create a copy of CustomerSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? sortBy = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as CustomerSortOption,
  ));
}

}



/// @nodoc


class _CustomerSearchCriteria implements CustomerSearchCriteria {
  const _CustomerSearchCriteria({this.searchQuery = '', this.sortBy = CustomerSortOption.nameAsc});
  

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  CustomerSortOption sortBy;

/// Create a copy of CustomerSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerSearchCriteriaCopyWith<_CustomerSearchCriteria> get copyWith => __$CustomerSearchCriteriaCopyWithImpl<_CustomerSearchCriteria>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy);

@override
String toString() {
  return 'CustomerSearchCriteria(searchQuery: $searchQuery, sortBy: $sortBy)';
}


}

/// @nodoc
abstract mixin class _$CustomerSearchCriteriaCopyWith<$Res> implements $CustomerSearchCriteriaCopyWith<$Res> {
  factory _$CustomerSearchCriteriaCopyWith(_CustomerSearchCriteria value, $Res Function(_CustomerSearchCriteria) _then) = __$CustomerSearchCriteriaCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, CustomerSortOption sortBy
});




}
/// @nodoc
class __$CustomerSearchCriteriaCopyWithImpl<$Res>
    implements _$CustomerSearchCriteriaCopyWith<$Res> {
  __$CustomerSearchCriteriaCopyWithImpl(this._self, this._then);

  final _CustomerSearchCriteria _self;
  final $Res Function(_CustomerSearchCriteria) _then;

/// Create a copy of CustomerSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? sortBy = null,}) {
  return _then(_CustomerSearchCriteria(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as CustomerSortOption,
  ));
}


}

// dart format on
