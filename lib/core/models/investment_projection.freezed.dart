// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_projection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestmentProjection {

 double get totalInvested; double get maturityAmount; double get totalInterestEarned; DateTime get maturityDate; String? get note;
/// Create a copy of InvestmentProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentProjectionCopyWith<InvestmentProjection> get copyWith => _$InvestmentProjectionCopyWithImpl<InvestmentProjection>(this as InvestmentProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentProjection&&(identical(other.totalInvested, totalInvested) || other.totalInvested == totalInvested)&&(identical(other.maturityAmount, maturityAmount) || other.maturityAmount == maturityAmount)&&(identical(other.totalInterestEarned, totalInterestEarned) || other.totalInterestEarned == totalInterestEarned)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,totalInvested,maturityAmount,totalInterestEarned,maturityDate,note);

@override
String toString() {
  return 'InvestmentProjection(totalInvested: $totalInvested, maturityAmount: $maturityAmount, totalInterestEarned: $totalInterestEarned, maturityDate: $maturityDate, note: $note)';
}


}

/// @nodoc
abstract mixin class $InvestmentProjectionCopyWith<$Res>  {
  factory $InvestmentProjectionCopyWith(InvestmentProjection value, $Res Function(InvestmentProjection) _then) = _$InvestmentProjectionCopyWithImpl;
@useResult
$Res call({
 double totalInvested, double maturityAmount, double totalInterestEarned, DateTime maturityDate, String? note
});




}
/// @nodoc
class _$InvestmentProjectionCopyWithImpl<$Res>
    implements $InvestmentProjectionCopyWith<$Res> {
  _$InvestmentProjectionCopyWithImpl(this._self, this._then);

  final InvestmentProjection _self;
  final $Res Function(InvestmentProjection) _then;

/// Create a copy of InvestmentProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalInvested = null,Object? maturityAmount = null,Object? totalInterestEarned = null,Object? maturityDate = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
totalInvested: null == totalInvested ? _self.totalInvested : totalInvested // ignore: cast_nullable_to_non_nullable
as double,maturityAmount: null == maturityAmount ? _self.maturityAmount : maturityAmount // ignore: cast_nullable_to_non_nullable
as double,totalInterestEarned: null == totalInterestEarned ? _self.totalInterestEarned : totalInterestEarned // ignore: cast_nullable_to_non_nullable
as double,maturityDate: null == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}



/// @nodoc


class WealthAccumulation extends InvestmentProjection {
  const WealthAccumulation({required this.totalInvested, required this.maturityAmount, required this.totalInterestEarned, required this.maturityDate, this.note}): super._();
  

@override final  double totalInvested;
@override final  double maturityAmount;
@override final  double totalInterestEarned;
@override final  DateTime maturityDate;
@override final  String? note;

/// Create a copy of InvestmentProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WealthAccumulationCopyWith<WealthAccumulation> get copyWith => _$WealthAccumulationCopyWithImpl<WealthAccumulation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WealthAccumulation&&(identical(other.totalInvested, totalInvested) || other.totalInvested == totalInvested)&&(identical(other.maturityAmount, maturityAmount) || other.maturityAmount == maturityAmount)&&(identical(other.totalInterestEarned, totalInterestEarned) || other.totalInterestEarned == totalInterestEarned)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,totalInvested,maturityAmount,totalInterestEarned,maturityDate,note);

@override
String toString() {
  return 'InvestmentProjection.wealthAccumulation(totalInvested: $totalInvested, maturityAmount: $maturityAmount, totalInterestEarned: $totalInterestEarned, maturityDate: $maturityDate, note: $note)';
}


}

/// @nodoc
abstract mixin class $WealthAccumulationCopyWith<$Res> implements $InvestmentProjectionCopyWith<$Res> {
  factory $WealthAccumulationCopyWith(WealthAccumulation value, $Res Function(WealthAccumulation) _then) = _$WealthAccumulationCopyWithImpl;
@override @useResult
$Res call({
 double totalInvested, double maturityAmount, double totalInterestEarned, DateTime maturityDate, String? note
});




}
/// @nodoc
class _$WealthAccumulationCopyWithImpl<$Res>
    implements $WealthAccumulationCopyWith<$Res> {
  _$WealthAccumulationCopyWithImpl(this._self, this._then);

  final WealthAccumulation _self;
  final $Res Function(WealthAccumulation) _then;

/// Create a copy of InvestmentProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalInvested = null,Object? maturityAmount = null,Object? totalInterestEarned = null,Object? maturityDate = null,Object? note = freezed,}) {
  return _then(WealthAccumulation(
totalInvested: null == totalInvested ? _self.totalInvested : totalInvested // ignore: cast_nullable_to_non_nullable
as double,maturityAmount: null == maturityAmount ? _self.maturityAmount : maturityAmount // ignore: cast_nullable_to_non_nullable
as double,totalInterestEarned: null == totalInterestEarned ? _self.totalInterestEarned : totalInterestEarned // ignore: cast_nullable_to_non_nullable
as double,maturityDate: null == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class IncomeGeneration extends InvestmentProjection {
  const IncomeGeneration({required this.totalInvested, required this.maturityAmount, required this.totalInterestEarned, required this.maturityDate, required this.periodicPayoutAmount, required this.payoutFrequency, this.note}): super._();
  

@override final  double totalInvested;
@override final  double maturityAmount;
@override final  double totalInterestEarned;
@override final  DateTime maturityDate;
 final  double periodicPayoutAmount;
 final  PayoutFrequency payoutFrequency;
@override final  String? note;

/// Create a copy of InvestmentProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomeGenerationCopyWith<IncomeGeneration> get copyWith => _$IncomeGenerationCopyWithImpl<IncomeGeneration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomeGeneration&&(identical(other.totalInvested, totalInvested) || other.totalInvested == totalInvested)&&(identical(other.maturityAmount, maturityAmount) || other.maturityAmount == maturityAmount)&&(identical(other.totalInterestEarned, totalInterestEarned) || other.totalInterestEarned == totalInterestEarned)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&(identical(other.periodicPayoutAmount, periodicPayoutAmount) || other.periodicPayoutAmount == periodicPayoutAmount)&&(identical(other.payoutFrequency, payoutFrequency) || other.payoutFrequency == payoutFrequency)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,totalInvested,maturityAmount,totalInterestEarned,maturityDate,periodicPayoutAmount,payoutFrequency,note);

@override
String toString() {
  return 'InvestmentProjection.incomeGeneration(totalInvested: $totalInvested, maturityAmount: $maturityAmount, totalInterestEarned: $totalInterestEarned, maturityDate: $maturityDate, periodicPayoutAmount: $periodicPayoutAmount, payoutFrequency: $payoutFrequency, note: $note)';
}


}

/// @nodoc
abstract mixin class $IncomeGenerationCopyWith<$Res> implements $InvestmentProjectionCopyWith<$Res> {
  factory $IncomeGenerationCopyWith(IncomeGeneration value, $Res Function(IncomeGeneration) _then) = _$IncomeGenerationCopyWithImpl;
@override @useResult
$Res call({
 double totalInvested, double maturityAmount, double totalInterestEarned, DateTime maturityDate, double periodicPayoutAmount, PayoutFrequency payoutFrequency, String? note
});




}
/// @nodoc
class _$IncomeGenerationCopyWithImpl<$Res>
    implements $IncomeGenerationCopyWith<$Res> {
  _$IncomeGenerationCopyWithImpl(this._self, this._then);

  final IncomeGeneration _self;
  final $Res Function(IncomeGeneration) _then;

/// Create a copy of InvestmentProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalInvested = null,Object? maturityAmount = null,Object? totalInterestEarned = null,Object? maturityDate = null,Object? periodicPayoutAmount = null,Object? payoutFrequency = null,Object? note = freezed,}) {
  return _then(IncomeGeneration(
totalInvested: null == totalInvested ? _self.totalInvested : totalInvested // ignore: cast_nullable_to_non_nullable
as double,maturityAmount: null == maturityAmount ? _self.maturityAmount : maturityAmount // ignore: cast_nullable_to_non_nullable
as double,totalInterestEarned: null == totalInterestEarned ? _self.totalInterestEarned : totalInterestEarned // ignore: cast_nullable_to_non_nullable
as double,maturityDate: null == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime,periodicPayoutAmount: null == periodicPayoutAmount ? _self.periodicPayoutAmount : periodicPayoutAmount // ignore: cast_nullable_to_non_nullable
as double,payoutFrequency: null == payoutFrequency ? _self.payoutFrequency : payoutFrequency // ignore: cast_nullable_to_non_nullable
as PayoutFrequency,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
