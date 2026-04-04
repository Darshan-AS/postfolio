// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deposit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Nominee {

 String get name; String get relationship;// e.g., "Spouse", "Son"
 String? get phone;
/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NomineeCopyWith<Nominee> get copyWith => _$NomineeCopyWithImpl<Nominee>(this as Nominee, _$identity);

  /// Serializes this Nominee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nominee&&(identical(other.name, name) || other.name == name)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,relationship,phone);

@override
String toString() {
  return 'Nominee(name: $name, relationship: $relationship, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $NomineeCopyWith<$Res>  {
  factory $NomineeCopyWith(Nominee value, $Res Function(Nominee) _then) = _$NomineeCopyWithImpl;
@useResult
$Res call({
 String name, String relationship, String? phone
});




}
/// @nodoc
class _$NomineeCopyWithImpl<$Res>
    implements $NomineeCopyWith<$Res> {
  _$NomineeCopyWithImpl(this._self, this._then);

  final Nominee _self;
  final $Res Function(Nominee) _then;

/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? relationship = null,Object? phone = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Nominee].
extension NomineePatterns on Nominee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Nominee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Nominee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Nominee value)  $default,){
final _that = this;
switch (_that) {
case _Nominee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Nominee value)?  $default,){
final _that = this;
switch (_that) {
case _Nominee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String relationship,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Nominee() when $default != null:
return $default(_that.name,_that.relationship,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String relationship,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _Nominee():
return $default(_that.name,_that.relationship,_that.phone);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String relationship,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _Nominee() when $default != null:
return $default(_that.name,_that.relationship,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Nominee implements Nominee {
  const _Nominee({required this.name, required this.relationship, this.phone});
  factory _Nominee.fromJson(Map<String, dynamic> json) => _$NomineeFromJson(json);

@override final  String name;
@override final  String relationship;
// e.g., "Spouse", "Son"
@override final  String? phone;

/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NomineeCopyWith<_Nominee> get copyWith => __$NomineeCopyWithImpl<_Nominee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NomineeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Nominee&&(identical(other.name, name) || other.name == name)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,relationship,phone);

@override
String toString() {
  return 'Nominee(name: $name, relationship: $relationship, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$NomineeCopyWith<$Res> implements $NomineeCopyWith<$Res> {
  factory _$NomineeCopyWith(_Nominee value, $Res Function(_Nominee) _then) = __$NomineeCopyWithImpl;
@override @useResult
$Res call({
 String name, String relationship, String? phone
});




}
/// @nodoc
class __$NomineeCopyWithImpl<$Res>
    implements _$NomineeCopyWith<$Res> {
  __$NomineeCopyWithImpl(this._self, this._then);

  final _Nominee _self;
  final $Res Function(_Nominee) _then;

/// Create a copy of Nominee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? relationship = null,Object? phone = freezed,}) {
  return _then(_Nominee(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Deposit {

 String get id; String get rowId; String get accountNo; double get amount; int get termYears; int get termMonths; double get interestRate; String get customerId; String get schemeId; double get maturityAmount; DateTime get depositDate; DateTime get maturityDate; List<Nominee> get nominees;
/// Create a copy of Deposit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DepositCopyWith<Deposit> get copyWith => _$DepositCopyWithImpl<Deposit>(this as Deposit, _$identity);

  /// Serializes this Deposit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Deposit&&(identical(other.id, id) || other.id == id)&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.maturityAmount, maturityAmount) || other.maturityAmount == maturityAmount)&&(identical(other.depositDate, depositDate) || other.depositDate == depositDate)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&const DeepCollectionEquality().equals(other.nominees, nominees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rowId,accountNo,amount,termYears,termMonths,interestRate,customerId,schemeId,maturityAmount,depositDate,maturityDate,const DeepCollectionEquality().hash(nominees));

@override
String toString() {
  return 'Deposit(id: $id, rowId: $rowId, accountNo: $accountNo, amount: $amount, termYears: $termYears, termMonths: $termMonths, interestRate: $interestRate, customerId: $customerId, schemeId: $schemeId, maturityAmount: $maturityAmount, depositDate: $depositDate, maturityDate: $maturityDate, nominees: $nominees)';
}


}

/// @nodoc
abstract mixin class $DepositCopyWith<$Res>  {
  factory $DepositCopyWith(Deposit value, $Res Function(Deposit) _then) = _$DepositCopyWithImpl;
@useResult
$Res call({
 String id, String rowId, String accountNo, double amount, int termYears, int termMonths, double interestRate, String customerId, String schemeId, double maturityAmount, DateTime depositDate, DateTime maturityDate, List<Nominee> nominees
});




}
/// @nodoc
class _$DepositCopyWithImpl<$Res>
    implements $DepositCopyWith<$Res> {
  _$DepositCopyWithImpl(this._self, this._then);

  final Deposit _self;
  final $Res Function(Deposit) _then;

/// Create a copy of Deposit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rowId = null,Object? accountNo = null,Object? amount = null,Object? termYears = null,Object? termMonths = null,Object? interestRate = null,Object? customerId = null,Object? schemeId = null,Object? maturityAmount = null,Object? depositDate = null,Object? maturityDate = null,Object? nominees = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as String,accountNo: null == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,maturityAmount: null == maturityAmount ? _self.maturityAmount : maturityAmount // ignore: cast_nullable_to_non_nullable
as double,depositDate: null == depositDate ? _self.depositDate : depositDate // ignore: cast_nullable_to_non_nullable
as DateTime,maturityDate: null == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime,nominees: null == nominees ? _self.nominees : nominees // ignore: cast_nullable_to_non_nullable
as List<Nominee>,
  ));
}

}


/// Adds pattern-matching-related methods to [Deposit].
extension DepositPatterns on Deposit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Deposit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Deposit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Deposit value)  $default,){
final _that = this;
switch (_that) {
case _Deposit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Deposit value)?  $default,){
final _that = this;
switch (_that) {
case _Deposit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rowId,  String accountNo,  double amount,  int termYears,  int termMonths,  double interestRate,  String customerId,  String schemeId,  double maturityAmount,  DateTime depositDate,  DateTime maturityDate,  List<Nominee> nominees)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Deposit() when $default != null:
return $default(_that.id,_that.rowId,_that.accountNo,_that.amount,_that.termYears,_that.termMonths,_that.interestRate,_that.customerId,_that.schemeId,_that.maturityAmount,_that.depositDate,_that.maturityDate,_that.nominees);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rowId,  String accountNo,  double amount,  int termYears,  int termMonths,  double interestRate,  String customerId,  String schemeId,  double maturityAmount,  DateTime depositDate,  DateTime maturityDate,  List<Nominee> nominees)  $default,) {final _that = this;
switch (_that) {
case _Deposit():
return $default(_that.id,_that.rowId,_that.accountNo,_that.amount,_that.termYears,_that.termMonths,_that.interestRate,_that.customerId,_that.schemeId,_that.maturityAmount,_that.depositDate,_that.maturityDate,_that.nominees);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rowId,  String accountNo,  double amount,  int termYears,  int termMonths,  double interestRate,  String customerId,  String schemeId,  double maturityAmount,  DateTime depositDate,  DateTime maturityDate,  List<Nominee> nominees)?  $default,) {final _that = this;
switch (_that) {
case _Deposit() when $default != null:
return $default(_that.id,_that.rowId,_that.accountNo,_that.amount,_that.termYears,_that.termMonths,_that.interestRate,_that.customerId,_that.schemeId,_that.maturityAmount,_that.depositDate,_that.maturityDate,_that.nominees);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Deposit implements Deposit {
  const _Deposit({required this.id, required this.rowId, required this.accountNo, required this.amount, required this.termYears, required this.termMonths, this.interestRate = 0.0, required this.customerId, required this.schemeId, required this.maturityAmount, required this.depositDate, required this.maturityDate, final  List<Nominee> nominees = const []}): _nominees = nominees;
  factory _Deposit.fromJson(Map<String, dynamic> json) => _$DepositFromJson(json);

@override final  String id;
@override final  String rowId;
@override final  String accountNo;
@override final  double amount;
@override final  int termYears;
@override final  int termMonths;
@override@JsonKey() final  double interestRate;
@override final  String customerId;
@override final  String schemeId;
@override final  double maturityAmount;
@override final  DateTime depositDate;
@override final  DateTime maturityDate;
 final  List<Nominee> _nominees;
@override@JsonKey() List<Nominee> get nominees {
  if (_nominees is EqualUnmodifiableListView) return _nominees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nominees);
}


/// Create a copy of Deposit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DepositCopyWith<_Deposit> get copyWith => __$DepositCopyWithImpl<_Deposit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DepositToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Deposit&&(identical(other.id, id) || other.id == id)&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.termYears, termYears) || other.termYears == termYears)&&(identical(other.termMonths, termMonths) || other.termMonths == termMonths)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.maturityAmount, maturityAmount) || other.maturityAmount == maturityAmount)&&(identical(other.depositDate, depositDate) || other.depositDate == depositDate)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&const DeepCollectionEquality().equals(other._nominees, _nominees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rowId,accountNo,amount,termYears,termMonths,interestRate,customerId,schemeId,maturityAmount,depositDate,maturityDate,const DeepCollectionEquality().hash(_nominees));

@override
String toString() {
  return 'Deposit(id: $id, rowId: $rowId, accountNo: $accountNo, amount: $amount, termYears: $termYears, termMonths: $termMonths, interestRate: $interestRate, customerId: $customerId, schemeId: $schemeId, maturityAmount: $maturityAmount, depositDate: $depositDate, maturityDate: $maturityDate, nominees: $nominees)';
}


}

/// @nodoc
abstract mixin class _$DepositCopyWith<$Res> implements $DepositCopyWith<$Res> {
  factory _$DepositCopyWith(_Deposit value, $Res Function(_Deposit) _then) = __$DepositCopyWithImpl;
@override @useResult
$Res call({
 String id, String rowId, String accountNo, double amount, int termYears, int termMonths, double interestRate, String customerId, String schemeId, double maturityAmount, DateTime depositDate, DateTime maturityDate, List<Nominee> nominees
});




}
/// @nodoc
class __$DepositCopyWithImpl<$Res>
    implements _$DepositCopyWith<$Res> {
  __$DepositCopyWithImpl(this._self, this._then);

  final _Deposit _self;
  final $Res Function(_Deposit) _then;

/// Create a copy of Deposit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rowId = null,Object? accountNo = null,Object? amount = null,Object? termYears = null,Object? termMonths = null,Object? interestRate = null,Object? customerId = null,Object? schemeId = null,Object? maturityAmount = null,Object? depositDate = null,Object? maturityDate = null,Object? nominees = null,}) {
  return _then(_Deposit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as String,accountNo: null == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,termYears: null == termYears ? _self.termYears : termYears // ignore: cast_nullable_to_non_nullable
as int,termMonths: null == termMonths ? _self.termMonths : termMonths // ignore: cast_nullable_to_non_nullable
as int,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,maturityAmount: null == maturityAmount ? _self.maturityAmount : maturityAmount // ignore: cast_nullable_to_non_nullable
as double,depositDate: null == depositDate ? _self.depositDate : depositDate // ignore: cast_nullable_to_non_nullable
as DateTime,maturityDate: null == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime,nominees: null == nominees ? _self._nominees : nominees // ignore: cast_nullable_to_non_nullable
as List<Nominee>,
  ));
}


}

// dart format on
