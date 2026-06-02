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

 String get searchQuery; RDSortField get sortField; SortDirection get sortDirection; List<DepositStatus> get statusFilters; List<MaturityUrgency> get urgencyFilters;
/// Create a copy of RDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RDSearchCriteriaCopyWith<RDSearchCriteria> get copyWith => _$RDSearchCriteriaCopyWithImpl<RDSearchCriteria>(this as RDSearchCriteria, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RDSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortField, sortField) || other.sortField == sortField)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection)&&const DeepCollectionEquality().equals(other.statusFilters, statusFilters)&&const DeepCollectionEquality().equals(other.urgencyFilters, urgencyFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortField,sortDirection,const DeepCollectionEquality().hash(statusFilters),const DeepCollectionEquality().hash(urgencyFilters));

@override
String toString() {
  return 'RDSearchCriteria(searchQuery: $searchQuery, sortField: $sortField, sortDirection: $sortDirection, statusFilters: $statusFilters, urgencyFilters: $urgencyFilters)';
}


}

/// @nodoc
abstract mixin class $RDSearchCriteriaCopyWith<$Res>  {
  factory $RDSearchCriteriaCopyWith(RDSearchCriteria value, $Res Function(RDSearchCriteria) _then) = _$RDSearchCriteriaCopyWithImpl;
@useResult
$Res call({
 String searchQuery, RDSortField sortField, SortDirection sortDirection, List<DepositStatus> statusFilters, List<MaturityUrgency> urgencyFilters
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
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? sortField = null,Object? sortDirection = null,Object? statusFilters = null,Object? urgencyFilters = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortField: null == sortField ? _self.sortField : sortField // ignore: cast_nullable_to_non_nullable
as RDSortField,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,statusFilters: null == statusFilters ? _self.statusFilters : statusFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,urgencyFilters: null == urgencyFilters ? _self.urgencyFilters : urgencyFilters // ignore: cast_nullable_to_non_nullable
as List<MaturityUrgency>,
  ));
}

}



/// @nodoc


class _RDSearchCriteria implements RDSearchCriteria {
  const _RDSearchCriteria({this.searchQuery = '', this.sortField = RDSortField.serialNo, this.sortDirection = SortDirection.asc, final  List<DepositStatus> statusFilters = const [DepositStatus.active], final  List<MaturityUrgency> urgencyFilters = const []}): _statusFilters = statusFilters,_urgencyFilters = urgencyFilters;
  

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  RDSortField sortField;
@override@JsonKey() final  SortDirection sortDirection;
 final  List<DepositStatus> _statusFilters;
@override@JsonKey() List<DepositStatus> get statusFilters {
  if (_statusFilters is EqualUnmodifiableListView) return _statusFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statusFilters);
}

 final  List<MaturityUrgency> _urgencyFilters;
@override@JsonKey() List<MaturityUrgency> get urgencyFilters {
  if (_urgencyFilters is EqualUnmodifiableListView) return _urgencyFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_urgencyFilters);
}


/// Create a copy of RDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RDSearchCriteriaCopyWith<_RDSearchCriteria> get copyWith => __$RDSearchCriteriaCopyWithImpl<_RDSearchCriteria>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RDSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortField, sortField) || other.sortField == sortField)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection)&&const DeepCollectionEquality().equals(other._statusFilters, _statusFilters)&&const DeepCollectionEquality().equals(other._urgencyFilters, _urgencyFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortField,sortDirection,const DeepCollectionEquality().hash(_statusFilters),const DeepCollectionEquality().hash(_urgencyFilters));

@override
String toString() {
  return 'RDSearchCriteria(searchQuery: $searchQuery, sortField: $sortField, sortDirection: $sortDirection, statusFilters: $statusFilters, urgencyFilters: $urgencyFilters)';
}


}

/// @nodoc
abstract mixin class _$RDSearchCriteriaCopyWith<$Res> implements $RDSearchCriteriaCopyWith<$Res> {
  factory _$RDSearchCriteriaCopyWith(_RDSearchCriteria value, $Res Function(_RDSearchCriteria) _then) = __$RDSearchCriteriaCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, RDSortField sortField, SortDirection sortDirection, List<DepositStatus> statusFilters, List<MaturityUrgency> urgencyFilters
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
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? sortField = null,Object? sortDirection = null,Object? statusFilters = null,Object? urgencyFilters = null,}) {
  return _then(_RDSearchCriteria(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortField: null == sortField ? _self.sortField : sortField // ignore: cast_nullable_to_non_nullable
as RDSortField,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,statusFilters: null == statusFilters ? _self._statusFilters : statusFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,urgencyFilters: null == urgencyFilters ? _self._urgencyFilters : urgencyFilters // ignore: cast_nullable_to_non_nullable
as List<MaturityUrgency>,
  ));
}


}

// dart format on
