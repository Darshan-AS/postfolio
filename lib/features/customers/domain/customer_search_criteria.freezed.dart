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

 String get searchQuery; CustomerSortField get sortField; SortDirection get sortDirection;
/// Create a copy of CustomerSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerSearchCriteriaCopyWith<CustomerSearchCriteria> get copyWith => _$CustomerSearchCriteriaCopyWithImpl<CustomerSearchCriteria>(this as CustomerSearchCriteria, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortField, sortField) || other.sortField == sortField)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortField,sortDirection);

@override
String toString() {
  return 'CustomerSearchCriteria(searchQuery: $searchQuery, sortField: $sortField, sortDirection: $sortDirection)';
}


}

/// @nodoc
abstract mixin class $CustomerSearchCriteriaCopyWith<$Res>  {
  factory $CustomerSearchCriteriaCopyWith(CustomerSearchCriteria value, $Res Function(CustomerSearchCriteria) _then) = _$CustomerSearchCriteriaCopyWithImpl;
@useResult
$Res call({
 String searchQuery, CustomerSortField sortField, SortDirection sortDirection
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
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? sortField = null,Object? sortDirection = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortField: null == sortField ? _self.sortField : sortField // ignore: cast_nullable_to_non_nullable
as CustomerSortField,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,
  ));
}

}



/// @nodoc


class _CustomerSearchCriteria implements CustomerSearchCriteria {
  const _CustomerSearchCriteria({this.searchQuery = '', this.sortField = CustomerSortField.name, this.sortDirection = SortDirection.asc});
  

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  CustomerSortField sortField;
@override@JsonKey() final  SortDirection sortDirection;

/// Create a copy of CustomerSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerSearchCriteriaCopyWith<_CustomerSearchCriteria> get copyWith => __$CustomerSearchCriteriaCopyWithImpl<_CustomerSearchCriteria>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortField, sortField) || other.sortField == sortField)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortField,sortDirection);

@override
String toString() {
  return 'CustomerSearchCriteria(searchQuery: $searchQuery, sortField: $sortField, sortDirection: $sortDirection)';
}


}

/// @nodoc
abstract mixin class _$CustomerSearchCriteriaCopyWith<$Res> implements $CustomerSearchCriteriaCopyWith<$Res> {
  factory _$CustomerSearchCriteriaCopyWith(_CustomerSearchCriteria value, $Res Function(_CustomerSearchCriteria) _then) = __$CustomerSearchCriteriaCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, CustomerSortField sortField, SortDirection sortDirection
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
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? sortField = null,Object? sortDirection = null,}) {
  return _then(_CustomerSearchCriteria(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortField: null == sortField ? _self.sortField : sortField // ignore: cast_nullable_to_non_nullable
as CustomerSortField,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,
  ));
}


}

// dart format on
