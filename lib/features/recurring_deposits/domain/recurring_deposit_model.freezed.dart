// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_deposit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringDeposit {

 String get id; String? get serialNo; String? get accountNo; double get installmentAmount; int get termYears; int get termMonths; double get interestRate; String get customerId; RecurringSchemeType get schemeType; DateTime get startDate; List<Nominee> get nominees; DepositStatus get status;@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? get createdAt;@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? get updatedAt;@JsonKey(includeIfNull: false) String? get migrationSource;
/// Create a copy of RecurringDeposit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringDepositCopyWith<RecurringDeposit> get copyWith => _$RecurringDepositCopyWithImpl<RecurringDeposit>(this as RecurringDeposit, _$identity);

  /// Serializes this RecurringDeposit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringDeposit&&(identical(other.id, id) || other.id == id)&&(identical(other.serialNo, serialNo) || other.serialNo == serialNo)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.installmentAmount, installmentAmount) || other.installmentAmount == installmentAmount)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&const DeepCollectionEquality().equals(other.nominees, nominees)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.migrationSource, migrationSource) || other.migrationSource == migrationSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serialNo,accountNo,installmentAmount,termYears,termMonths,interestRate,customerId,schemeType,startDate,const DeepCollectionEquality().hash(nominees),status,createdAt,updatedAt,migrationSource);

@override
String toString() {
  return 'RecurringDeposit(id: $id, serialNo: $serialNo, accountNo: $accountNo, installmentAmount: $installmentAmount, termYears: $termYears, termMonths: $termMonths, interestRate: $interestRate, customerId: $customerId, schemeType: $schemeType, startDate: $startDate, nominees: $nominees, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, migrationSource: $migrationSource)';
}


}

/// @nodoc
abstract mixin class $RecurringDepositCopyWith<$Res>  {
  factory $RecurringDepositCopyWith(RecurringDeposit value, $Res Function(RecurringDeposit) _then) = _$RecurringDepositCopyWithImpl;
@useResult
$Res call({
 String id, String? serialNo, String? accountNo, double installmentAmount, int termYears, int termMonths, double interestRate, String customerId, RecurringSchemeType schemeType, DateTime startDate, List<Nominee> nominees, DepositStatus status,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? createdAt,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? updatedAt,@JsonKey(includeIfNull: false) String? migrationSource
});




}
/// @nodoc
class _$RecurringDepositCopyWithImpl<$Res>
    implements $RecurringDepositCopyWith<$Res> {
  _$RecurringDepositCopyWithImpl(this._self, this._then);

  final RecurringDeposit _self;
  final $Res Function(RecurringDeposit) _then;

/// Create a copy of RecurringDeposit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serialNo = freezed,Object? accountNo = freezed,Object? installmentAmount = null,Object? termYears = null,Object? termMonths = null,Object? interestRate = null,Object? customerId = null,Object? schemeType = null,Object? startDate = null,Object? nominees = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? migrationSource = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serialNo: freezed == serialNo ? _self.serialNo : serialNo // ignore: cast_nullable_to_non_nullable
as String?,accountNo: freezed == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String?,installmentAmount: null == installmentAmount ? _self.installmentAmount : installmentAmount // ignore: cast_nullable_to_non_nullable
as double,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as RecurringSchemeType,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,nominees: null == nominees ? _self.nominees : nominees // ignore: cast_nullable_to_non_nullable
as List<Nominee>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DepositStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,migrationSource: freezed == migrationSource ? _self.migrationSource : migrationSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}



/// @nodoc
@JsonSerializable()

class _RecurringDeposit extends RecurringDeposit {
  const _RecurringDeposit({required this.id, this.serialNo, this.accountNo, required this.installmentAmount, required this.termYears, required this.termMonths, required this.interestRate, required this.customerId, required this.schemeType, required this.startDate, final  List<Nominee> nominees = const [], this.status = DepositStatus.active, @TimestampConverter()@JsonKey(includeIfNull: false) this.createdAt, @TimestampConverter()@JsonKey(includeIfNull: false) this.updatedAt, @JsonKey(includeIfNull: false) this.migrationSource}): _nominees = nominees,super._();
  factory _RecurringDeposit.fromJson(Map<String, dynamic> json) => _$RecurringDepositFromJson(json);

@override final  String id;
@override final  String? serialNo;
@override final  String? accountNo;
@override final  double installmentAmount;
@override final  int termYears;
@override final  int termMonths;
@override final  double interestRate;
@override final  String customerId;
@override final  RecurringSchemeType schemeType;
@override final  DateTime startDate;
 final  List<Nominee> _nominees;
@override@JsonKey() List<Nominee> get nominees {
  if (_nominees is EqualUnmodifiableListView) return _nominees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nominees);
}

@override@JsonKey() final  DepositStatus status;
@override@TimestampConverter()@JsonKey(includeIfNull: false) final  DateTime? createdAt;
@override@TimestampConverter()@JsonKey(includeIfNull: false) final  DateTime? updatedAt;
@override@JsonKey(includeIfNull: false) final  String? migrationSource;

/// Create a copy of RecurringDeposit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringDepositCopyWith<_RecurringDeposit> get copyWith => __$RecurringDepositCopyWithImpl<_RecurringDeposit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringDepositToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringDeposit&&(identical(other.id, id) || other.id == id)&&(identical(other.serialNo, serialNo) || other.serialNo == serialNo)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.installmentAmount, installmentAmount) || other.installmentAmount == installmentAmount)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&const DeepCollectionEquality().equals(other._nominees, _nominees)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.migrationSource, migrationSource) || other.migrationSource == migrationSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serialNo,accountNo,installmentAmount,termYears,termMonths,interestRate,customerId,schemeType,startDate,const DeepCollectionEquality().hash(_nominees),status,createdAt,updatedAt,migrationSource);

@override
String toString() {
  return 'RecurringDeposit(id: $id, serialNo: $serialNo, accountNo: $accountNo, installmentAmount: $installmentAmount, termYears: $termYears, termMonths: $termMonths, interestRate: $interestRate, customerId: $customerId, schemeType: $schemeType, startDate: $startDate, nominees: $nominees, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, migrationSource: $migrationSource)';
}


}

/// @nodoc
abstract mixin class _$RecurringDepositCopyWith<$Res> implements $RecurringDepositCopyWith<$Res> {
  factory _$RecurringDepositCopyWith(_RecurringDeposit value, $Res Function(_RecurringDeposit) _then) = __$RecurringDepositCopyWithImpl;
@override @useResult
$Res call({
 String id, String? serialNo, String? accountNo, double installmentAmount, int termYears, int termMonths, double interestRate, String customerId, RecurringSchemeType schemeType, DateTime startDate, List<Nominee> nominees, DepositStatus status,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? createdAt,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? updatedAt,@JsonKey(includeIfNull: false) String? migrationSource
});




}
/// @nodoc
class __$RecurringDepositCopyWithImpl<$Res>
    implements _$RecurringDepositCopyWith<$Res> {
  __$RecurringDepositCopyWithImpl(this._self, this._then);

  final _RecurringDeposit _self;
  final $Res Function(_RecurringDeposit) _then;

/// Create a copy of RecurringDeposit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serialNo = freezed,Object? accountNo = freezed,Object? installmentAmount = null,Object? termYears = null,Object? termMonths = null,Object? interestRate = null,Object? customerId = null,Object? schemeType = null,Object? startDate = null,Object? nominees = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? migrationSource = freezed,}) {
  return _then(_RecurringDeposit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serialNo: freezed == serialNo ? _self.serialNo : serialNo // ignore: cast_nullable_to_non_nullable
as String?,accountNo: freezed == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String?,installmentAmount: null == installmentAmount ? _self.installmentAmount : installmentAmount // ignore: cast_nullable_to_non_nullable
as double,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as RecurringSchemeType,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,nominees: null == nominees ? _self._nominees : nominees // ignore: cast_nullable_to_non_nullable
as List<Nominee>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DepositStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,migrationSource: freezed == migrationSource ? _self.migrationSource : migrationSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
