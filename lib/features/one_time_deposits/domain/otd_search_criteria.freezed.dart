// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otd_search_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OTDSearchCriteria {

 String get searchQuery; OTDSortOption get sortBy; List<DepositStatus> get statusFilters; List<MaturityUrgency> get urgencyFilters; List<OneTimeSchemeType> get schemeFilters;
/// Create a copy of OTDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OTDSearchCriteriaCopyWith<OTDSearchCriteria> get copyWith => _$OTDSearchCriteriaCopyWithImpl<OTDSearchCriteria>(this as OTDSearchCriteria, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OTDSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other.statusFilters, statusFilters)&&const DeepCollectionEquality().equals(other.urgencyFilters, urgencyFilters)&&const DeepCollectionEquality().equals(other.schemeFilters, schemeFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy,const DeepCollectionEquality().hash(statusFilters),const DeepCollectionEquality().hash(urgencyFilters),const DeepCollectionEquality().hash(schemeFilters));

@override
String toString() {
  return 'OTDSearchCriteria(searchQuery: $searchQuery, sortBy: $sortBy, statusFilters: $statusFilters, urgencyFilters: $urgencyFilters, schemeFilters: $schemeFilters)';
}


}

/// @nodoc
abstract mixin class $OTDSearchCriteriaCopyWith<$Res>  {
  factory $OTDSearchCriteriaCopyWith(OTDSearchCriteria value, $Res Function(OTDSearchCriteria) _then) = _$OTDSearchCriteriaCopyWithImpl;
@useResult
$Res call({
 String searchQuery, OTDSortOption sortBy, List<DepositStatus> statusFilters, List<MaturityUrgency> urgencyFilters, List<OneTimeSchemeType> schemeFilters
});




}
/// @nodoc
class _$OTDSearchCriteriaCopyWithImpl<$Res>
    implements $OTDSearchCriteriaCopyWith<$Res> {
  _$OTDSearchCriteriaCopyWithImpl(this._self, this._then);

  final OTDSearchCriteria _self;
  final $Res Function(OTDSearchCriteria) _then;

/// Create a copy of OTDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? sortBy = null,Object? statusFilters = null,Object? urgencyFilters = null,Object? schemeFilters = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as OTDSortOption,statusFilters: null == statusFilters ? _self.statusFilters : statusFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,urgencyFilters: null == urgencyFilters ? _self.urgencyFilters : urgencyFilters // ignore: cast_nullable_to_non_nullable
as List<MaturityUrgency>,schemeFilters: null == schemeFilters ? _self.schemeFilters : schemeFilters // ignore: cast_nullable_to_non_nullable
as List<OneTimeSchemeType>,
  ));
}

}



/// @nodoc


class _OTDSearchCriteria implements OTDSearchCriteria {
  const _OTDSearchCriteria({this.searchQuery = '', this.sortBy = OTDSortOption.maturityDateAsc, final  List<DepositStatus> statusFilters = const [DepositStatus.active], final  List<MaturityUrgency> urgencyFilters = const [], final  List<OneTimeSchemeType> schemeFilters = const []}): _statusFilters = statusFilters,_urgencyFilters = urgencyFilters,_schemeFilters = schemeFilters;
  

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  OTDSortOption sortBy;
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

 final  List<OneTimeSchemeType> _schemeFilters;
@override@JsonKey() List<OneTimeSchemeType> get schemeFilters {
  if (_schemeFilters is EqualUnmodifiableListView) return _schemeFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_schemeFilters);
}


/// Create a copy of OTDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OTDSearchCriteriaCopyWith<_OTDSearchCriteria> get copyWith => __$OTDSearchCriteriaCopyWithImpl<_OTDSearchCriteria>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OTDSearchCriteria&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other._statusFilters, _statusFilters)&&const DeepCollectionEquality().equals(other._urgencyFilters, _urgencyFilters)&&const DeepCollectionEquality().equals(other._schemeFilters, _schemeFilters));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,sortBy,const DeepCollectionEquality().hash(_statusFilters),const DeepCollectionEquality().hash(_urgencyFilters),const DeepCollectionEquality().hash(_schemeFilters));

@override
String toString() {
  return 'OTDSearchCriteria(searchQuery: $searchQuery, sortBy: $sortBy, statusFilters: $statusFilters, urgencyFilters: $urgencyFilters, schemeFilters: $schemeFilters)';
}


}

/// @nodoc
abstract mixin class _$OTDSearchCriteriaCopyWith<$Res> implements $OTDSearchCriteriaCopyWith<$Res> {
  factory _$OTDSearchCriteriaCopyWith(_OTDSearchCriteria value, $Res Function(_OTDSearchCriteria) _then) = __$OTDSearchCriteriaCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, OTDSortOption sortBy, List<DepositStatus> statusFilters, List<MaturityUrgency> urgencyFilters, List<OneTimeSchemeType> schemeFilters
});




}
/// @nodoc
class __$OTDSearchCriteriaCopyWithImpl<$Res>
    implements _$OTDSearchCriteriaCopyWith<$Res> {
  __$OTDSearchCriteriaCopyWithImpl(this._self, this._then);

  final _OTDSearchCriteria _self;
  final $Res Function(_OTDSearchCriteria) _then;

/// Create a copy of OTDSearchCriteria
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? sortBy = null,Object? statusFilters = null,Object? urgencyFilters = null,Object? schemeFilters = null,}) {
  return _then(_OTDSearchCriteria(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as OTDSortOption,statusFilters: null == statusFilters ? _self._statusFilters : statusFilters // ignore: cast_nullable_to_non_nullable
as List<DepositStatus>,urgencyFilters: null == urgencyFilters ? _self._urgencyFilters : urgencyFilters // ignore: cast_nullable_to_non_nullable
as List<MaturityUrgency>,schemeFilters: null == schemeFilters ? _self._schemeFilters : schemeFilters // ignore: cast_nullable_to_non_nullable
as List<OneTimeSchemeType>,
  ));
}


}

// dart format on
