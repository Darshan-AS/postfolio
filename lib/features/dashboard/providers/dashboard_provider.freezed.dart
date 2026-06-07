// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DashboardMetrics {

 int get totalCustomers; int get activeCustomers; int get totalRds; int get activeRds; int get totalOtds; int get activeOtds; Map<OneTimeSchemeType, int> get activeOtdsByScheme; Map<OneTimeSchemeType, int> get totalOtdsByScheme;
/// Create a copy of DashboardMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardMetricsCopyWith<DashboardMetrics> get copyWith => _$DashboardMetricsCopyWithImpl<DashboardMetrics>(this as DashboardMetrics, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardMetrics&&(identical(other.totalCustomers, totalCustomers) || other.totalCustomers == totalCustomers)&&(identical(other.activeCustomers, activeCustomers) || other.activeCustomers == activeCustomers)&&(identical(other.totalRds, totalRds) || other.totalRds == totalRds)&&(identical(other.activeRds, activeRds) || other.activeRds == activeRds)&&(identical(other.totalOtds, totalOtds) || other.totalOtds == totalOtds)&&(identical(other.activeOtds, activeOtds) || other.activeOtds == activeOtds)&&const DeepCollectionEquality().equals(other.activeOtdsByScheme, activeOtdsByScheme)&&const DeepCollectionEquality().equals(other.totalOtdsByScheme, totalOtdsByScheme));
}


@override
int get hashCode => Object.hash(runtimeType,totalCustomers,activeCustomers,totalRds,activeRds,totalOtds,activeOtds,const DeepCollectionEquality().hash(activeOtdsByScheme),const DeepCollectionEquality().hash(totalOtdsByScheme));

@override
String toString() {
  return 'DashboardMetrics(totalCustomers: $totalCustomers, activeCustomers: $activeCustomers, totalRds: $totalRds, activeRds: $activeRds, totalOtds: $totalOtds, activeOtds: $activeOtds, activeOtdsByScheme: $activeOtdsByScheme, totalOtdsByScheme: $totalOtdsByScheme)';
}


}

/// @nodoc
abstract mixin class $DashboardMetricsCopyWith<$Res>  {
  factory $DashboardMetricsCopyWith(DashboardMetrics value, $Res Function(DashboardMetrics) _then) = _$DashboardMetricsCopyWithImpl;
@useResult
$Res call({
 int totalCustomers, int activeCustomers, int totalRds, int activeRds, int totalOtds, int activeOtds, Map<OneTimeSchemeType, int> activeOtdsByScheme, Map<OneTimeSchemeType, int> totalOtdsByScheme
});




}
/// @nodoc
class _$DashboardMetricsCopyWithImpl<$Res>
    implements $DashboardMetricsCopyWith<$Res> {
  _$DashboardMetricsCopyWithImpl(this._self, this._then);

  final DashboardMetrics _self;
  final $Res Function(DashboardMetrics) _then;

/// Create a copy of DashboardMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCustomers = null,Object? activeCustomers = null,Object? totalRds = null,Object? activeRds = null,Object? totalOtds = null,Object? activeOtds = null,Object? activeOtdsByScheme = null,Object? totalOtdsByScheme = null,}) {
  return _then(_self.copyWith(
totalCustomers: null == totalCustomers ? _self.totalCustomers : totalCustomers // ignore: cast_nullable_to_non_nullable
as int,activeCustomers: null == activeCustomers ? _self.activeCustomers : activeCustomers // ignore: cast_nullable_to_non_nullable
as int,totalRds: null == totalRds ? _self.totalRds : totalRds // ignore: cast_nullable_to_non_nullable
as int,activeRds: null == activeRds ? _self.activeRds : activeRds // ignore: cast_nullable_to_non_nullable
as int,totalOtds: null == totalOtds ? _self.totalOtds : totalOtds // ignore: cast_nullable_to_non_nullable
as int,activeOtds: null == activeOtds ? _self.activeOtds : activeOtds // ignore: cast_nullable_to_non_nullable
as int,activeOtdsByScheme: null == activeOtdsByScheme ? _self.activeOtdsByScheme : activeOtdsByScheme // ignore: cast_nullable_to_non_nullable
as Map<OneTimeSchemeType, int>,totalOtdsByScheme: null == totalOtdsByScheme ? _self.totalOtdsByScheme : totalOtdsByScheme // ignore: cast_nullable_to_non_nullable
as Map<OneTimeSchemeType, int>,
  ));
}

}



/// @nodoc


class _DashboardMetrics implements DashboardMetrics {
  const _DashboardMetrics({required this.totalCustomers, required this.activeCustomers, required this.totalRds, required this.activeRds, required this.totalOtds, required this.activeOtds, required final  Map<OneTimeSchemeType, int> activeOtdsByScheme, required final  Map<OneTimeSchemeType, int> totalOtdsByScheme}): _activeOtdsByScheme = activeOtdsByScheme,_totalOtdsByScheme = totalOtdsByScheme;
  

@override final  int totalCustomers;
@override final  int activeCustomers;
@override final  int totalRds;
@override final  int activeRds;
@override final  int totalOtds;
@override final  int activeOtds;
 final  Map<OneTimeSchemeType, int> _activeOtdsByScheme;
@override Map<OneTimeSchemeType, int> get activeOtdsByScheme {
  if (_activeOtdsByScheme is EqualUnmodifiableMapView) return _activeOtdsByScheme;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_activeOtdsByScheme);
}

 final  Map<OneTimeSchemeType, int> _totalOtdsByScheme;
@override Map<OneTimeSchemeType, int> get totalOtdsByScheme {
  if (_totalOtdsByScheme is EqualUnmodifiableMapView) return _totalOtdsByScheme;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_totalOtdsByScheme);
}


/// Create a copy of DashboardMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardMetricsCopyWith<_DashboardMetrics> get copyWith => __$DashboardMetricsCopyWithImpl<_DashboardMetrics>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardMetrics&&(identical(other.totalCustomers, totalCustomers) || other.totalCustomers == totalCustomers)&&(identical(other.activeCustomers, activeCustomers) || other.activeCustomers == activeCustomers)&&(identical(other.totalRds, totalRds) || other.totalRds == totalRds)&&(identical(other.activeRds, activeRds) || other.activeRds == activeRds)&&(identical(other.totalOtds, totalOtds) || other.totalOtds == totalOtds)&&(identical(other.activeOtds, activeOtds) || other.activeOtds == activeOtds)&&const DeepCollectionEquality().equals(other._activeOtdsByScheme, _activeOtdsByScheme)&&const DeepCollectionEquality().equals(other._totalOtdsByScheme, _totalOtdsByScheme));
}


@override
int get hashCode => Object.hash(runtimeType,totalCustomers,activeCustomers,totalRds,activeRds,totalOtds,activeOtds,const DeepCollectionEquality().hash(_activeOtdsByScheme),const DeepCollectionEquality().hash(_totalOtdsByScheme));

@override
String toString() {
  return 'DashboardMetrics(totalCustomers: $totalCustomers, activeCustomers: $activeCustomers, totalRds: $totalRds, activeRds: $activeRds, totalOtds: $totalOtds, activeOtds: $activeOtds, activeOtdsByScheme: $activeOtdsByScheme, totalOtdsByScheme: $totalOtdsByScheme)';
}


}

/// @nodoc
abstract mixin class _$DashboardMetricsCopyWith<$Res> implements $DashboardMetricsCopyWith<$Res> {
  factory _$DashboardMetricsCopyWith(_DashboardMetrics value, $Res Function(_DashboardMetrics) _then) = __$DashboardMetricsCopyWithImpl;
@override @useResult
$Res call({
 int totalCustomers, int activeCustomers, int totalRds, int activeRds, int totalOtds, int activeOtds, Map<OneTimeSchemeType, int> activeOtdsByScheme, Map<OneTimeSchemeType, int> totalOtdsByScheme
});




}
/// @nodoc
class __$DashboardMetricsCopyWithImpl<$Res>
    implements _$DashboardMetricsCopyWith<$Res> {
  __$DashboardMetricsCopyWithImpl(this._self, this._then);

  final _DashboardMetrics _self;
  final $Res Function(_DashboardMetrics) _then;

/// Create a copy of DashboardMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCustomers = null,Object? activeCustomers = null,Object? totalRds = null,Object? activeRds = null,Object? totalOtds = null,Object? activeOtds = null,Object? activeOtdsByScheme = null,Object? totalOtdsByScheme = null,}) {
  return _then(_DashboardMetrics(
totalCustomers: null == totalCustomers ? _self.totalCustomers : totalCustomers // ignore: cast_nullable_to_non_nullable
as int,activeCustomers: null == activeCustomers ? _self.activeCustomers : activeCustomers // ignore: cast_nullable_to_non_nullable
as int,totalRds: null == totalRds ? _self.totalRds : totalRds // ignore: cast_nullable_to_non_nullable
as int,activeRds: null == activeRds ? _self.activeRds : activeRds // ignore: cast_nullable_to_non_nullable
as int,totalOtds: null == totalOtds ? _self.totalOtds : totalOtds // ignore: cast_nullable_to_non_nullable
as int,activeOtds: null == activeOtds ? _self.activeOtds : activeOtds // ignore: cast_nullable_to_non_nullable
as int,activeOtdsByScheme: null == activeOtdsByScheme ? _self._activeOtdsByScheme : activeOtdsByScheme // ignore: cast_nullable_to_non_nullable
as Map<OneTimeSchemeType, int>,totalOtdsByScheme: null == totalOtdsByScheme ? _self._totalOtdsByScheme : totalOtdsByScheme // ignore: cast_nullable_to_non_nullable
as Map<OneTimeSchemeType, int>,
  ));
}


}

/// @nodoc
mixin _$ChartDataPoint {

 int get id; String get label; double get amount; int get count;
/// Create a copy of ChartDataPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartDataPointCopyWith<ChartDataPoint> get copyWith => _$ChartDataPointCopyWithImpl<ChartDataPoint>(this as ChartDataPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartDataPoint&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,amount,count);

@override
String toString() {
  return 'ChartDataPoint(id: $id, label: $label, amount: $amount, count: $count)';
}


}

/// @nodoc
abstract mixin class $ChartDataPointCopyWith<$Res>  {
  factory $ChartDataPointCopyWith(ChartDataPoint value, $Res Function(ChartDataPoint) _then) = _$ChartDataPointCopyWithImpl;
@useResult
$Res call({
 int id, String label, double amount, int count
});




}
/// @nodoc
class _$ChartDataPointCopyWithImpl<$Res>
    implements $ChartDataPointCopyWith<$Res> {
  _$ChartDataPointCopyWithImpl(this._self, this._then);

  final ChartDataPoint _self;
  final $Res Function(ChartDataPoint) _then;

/// Create a copy of ChartDataPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? amount = null,Object? count = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc


class _ChartDataPoint implements ChartDataPoint {
  const _ChartDataPoint({required this.id, required this.label, required this.amount, required this.count});
  

@override final  int id;
@override final  String label;
@override final  double amount;
@override final  int count;

/// Create a copy of ChartDataPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartDataPointCopyWith<_ChartDataPoint> get copyWith => __$ChartDataPointCopyWithImpl<_ChartDataPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartDataPoint&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,amount,count);

@override
String toString() {
  return 'ChartDataPoint(id: $id, label: $label, amount: $amount, count: $count)';
}


}

/// @nodoc
abstract mixin class _$ChartDataPointCopyWith<$Res> implements $ChartDataPointCopyWith<$Res> {
  factory _$ChartDataPointCopyWith(_ChartDataPoint value, $Res Function(_ChartDataPoint) _then) = __$ChartDataPointCopyWithImpl;
@override @useResult
$Res call({
 int id, String label, double amount, int count
});




}
/// @nodoc
class __$ChartDataPointCopyWithImpl<$Res>
    implements _$ChartDataPointCopyWith<$Res> {
  __$ChartDataPointCopyWithImpl(this._self, this._then);

  final _ChartDataPoint _self;
  final $Res Function(_ChartDataPoint) _then;

/// Create a copy of ChartDataPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? amount = null,Object? count = null,}) {
  return _then(_ChartDataPoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
