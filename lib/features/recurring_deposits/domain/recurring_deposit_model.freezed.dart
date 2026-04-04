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

 String get id; String get accountNo; double get installmentAmount; int get termYears; int get termMonths; double get interestRate; String get customerId; String get schemeId; double get maturityAmount; DateTime get startDate; DateTime get maturityDate; List<Nominee> get nominees;
/// Create a copy of RecurringDeposit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringDepositCopyWith<RecurringDeposit> get copyWith => _$RecurringDepositCopyWithImpl<RecurringDeposit>(this as RecurringDeposit, _$identity);

  /// Serializes this RecurringDeposit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringDeposit&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.installmentAmount, installmentAmount) || other.installmentAmount == installmentAmount)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.maturityAmount, maturityAmount) || other.maturityAmount == maturityAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&const DeepCollectionEquality().equals(other.nominees, nominees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountNo,installmentAmount,termYears,termMonths,interestRate,customerId,schemeId,maturityAmount,startDate,maturityDate,const DeepCollectionEquality().hash(nominees));

@override
String toString() {
  return 'RecurringDeposit(id: $id, accountNo: $accountNo, installmentAmount: $installmentAmount, termYears: $termYears, termMonths: $termMonths, interestRate: $interestRate, customerId: $customerId, schemeId: $schemeId, maturityAmount: $maturityAmount, startDate: $startDate, maturityDate: $maturityDate, nominees: $nominees)';
}


}

/// @nodoc
abstract mixin class $RecurringDepositCopyWith<$Res>  {
  factory $RecurringDepositCopyWith(RecurringDeposit value, $Res Function(RecurringDeposit) _then) = _$RecurringDepositCopyWithImpl;
@useResult
$Res call({
 String id, String accountNo, double installmentAmount, int termYears, int termMonths, double interestRate, String customerId, String schemeId, double maturityAmount, DateTime startDate, DateTime maturityDate, List<Nominee> nominees
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountNo = null,Object? installmentAmount = null,Object? termYears = null,Object? termMonths = null,Object? interestRate = null,Object? customerId = null,Object? schemeId = null,Object? maturityAmount = null,Object? startDate = null,Object? maturityDate = null,Object? nominees = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNo: null == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String,installmentAmount: null == installmentAmount ? _self.installmentAmount : installmentAmount // ignore: cast_nullable_to_non_nullable
as double,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,maturityAmount: null == maturityAmount ? _self.maturityAmount : maturityAmount // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,maturityDate: null == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime,nominees: null == nominees ? _self.nominees : nominees // ignore: cast_nullable_to_non_nullable
as List<Nominee>,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringDeposit].
extension RecurringDepositPatterns on RecurringDeposit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringDeposit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringDeposit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringDeposit value)  $default,){
final _that = this;
switch (_that) {
case _RecurringDeposit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringDeposit value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringDeposit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountNo,  double installmentAmount,  int termYears,  int termMonths,  double interestRate,  String customerId,  String schemeId,  double maturityAmount,  DateTime startDate,  DateTime maturityDate,  List<Nominee> nominees)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringDeposit() when $default != null:
return $default(_that.id,_that.accountNo,_that.installmentAmount,_that.termYears,_that.termMonths,_that.interestRate,_that.customerId,_that.schemeId,_that.maturityAmount,_that.startDate,_that.maturityDate,_that.nominees);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountNo,  double installmentAmount,  int termYears,  int termMonths,  double interestRate,  String customerId,  String schemeId,  double maturityAmount,  DateTime startDate,  DateTime maturityDate,  List<Nominee> nominees)  $default,) {final _that = this;
switch (_that) {
case _RecurringDeposit():
return $default(_that.id,_that.accountNo,_that.installmentAmount,_that.termYears,_that.termMonths,_that.interestRate,_that.customerId,_that.schemeId,_that.maturityAmount,_that.startDate,_that.maturityDate,_that.nominees);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountNo,  double installmentAmount,  int termYears,  int termMonths,  double interestRate,  String customerId,  String schemeId,  double maturityAmount,  DateTime startDate,  DateTime maturityDate,  List<Nominee> nominees)?  $default,) {final _that = this;
switch (_that) {
case _RecurringDeposit() when $default != null:
return $default(_that.id,_that.accountNo,_that.installmentAmount,_that.termYears,_that.termMonths,_that.interestRate,_that.customerId,_that.schemeId,_that.maturityAmount,_that.startDate,_that.maturityDate,_that.nominees);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringDeposit implements RecurringDeposit {
  const _RecurringDeposit({required this.id, required this.accountNo, required this.installmentAmount, required this.termYears, required this.termMonths, required this.interestRate, required this.customerId, required this.schemeId, required this.maturityAmount, required this.startDate, required this.maturityDate, final  List<Nominee> nominees = const []}): _nominees = nominees;
  factory _RecurringDeposit.fromJson(Map<String, dynamic> json) => _$RecurringDepositFromJson(json);

@override final  String id;
@override final  String accountNo;
@override final  double installmentAmount;
@override final  int termYears;
@override final  int termMonths;
@override final  double interestRate;
@override final  String customerId;
@override final  String schemeId;
@override final  double maturityAmount;
@override final  DateTime startDate;
@override final  DateTime maturityDate;
 final  List<Nominee> _nominees;
@override@JsonKey() List<Nominee> get nominees {
  if (_nominees is EqualUnmodifiableListView) return _nominees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nominees);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringDeposit&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.installmentAmount, installmentAmount) || other.installmentAmount == installmentAmount)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.maturityAmount, maturityAmount) || other.maturityAmount == maturityAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&const DeepCollectionEquality().equals(other._nominees, _nominees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountNo,installmentAmount,termYears,termMonths,interestRate,customerId,schemeId,maturityAmount,startDate,maturityDate,const DeepCollectionEquality().hash(_nominees));

@override
String toString() {
  return 'RecurringDeposit(id: $id, accountNo: $accountNo, installmentAmount: $installmentAmount, termYears: $termYears, termMonths: $termMonths, interestRate: $interestRate, customerId: $customerId, schemeId: $schemeId, maturityAmount: $maturityAmount, startDate: $startDate, maturityDate: $maturityDate, nominees: $nominees)';
}


}

/// @nodoc
abstract mixin class _$RecurringDepositCopyWith<$Res> implements $RecurringDepositCopyWith<$Res> {
  factory _$RecurringDepositCopyWith(_RecurringDeposit value, $Res Function(_RecurringDeposit) _then) = __$RecurringDepositCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountNo, double installmentAmount, int termYears, int termMonths, double interestRate, String customerId, String schemeId, double maturityAmount, DateTime startDate, DateTime maturityDate, List<Nominee> nominees
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountNo = null,Object? installmentAmount = null,Object? termYears = null,Object? termMonths = null,Object? interestRate = null,Object? customerId = null,Object? schemeId = null,Object? maturityAmount = null,Object? startDate = null,Object? maturityDate = null,Object? nominees = null,}) {
  return _then(_RecurringDeposit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNo: null == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String,installmentAmount: null == installmentAmount ? _self.installmentAmount : installmentAmount // ignore: cast_nullable_to_non_nullable
as double,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,maturityAmount: null == maturityAmount ? _self.maturityAmount : maturityAmount // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,maturityDate: null == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime,nominees: null == nominees ? _self._nominees : nominees // ignore: cast_nullable_to_non_nullable
as List<Nominee>,
  ));
}


}

// dart format on
