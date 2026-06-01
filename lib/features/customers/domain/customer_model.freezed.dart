// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Customer {

 String get id; String get name; String? get email; String? get phone; String? get address; String? get cifNumber; DateTime? get dateOfBirth; String? get aadhaarNumber; String? get panNumber; SavingsAccount? get savingsAccount;@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? get createdAt;@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? get updatedAt;@JsonKey(includeIfNull: false) String? get migrationSource;
/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCopyWith<Customer> get copyWith => _$CustomerCopyWithImpl<Customer>(this as Customer, _$identity);

  /// Serializes this Customer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.cifNumber, cifNumber) || other.cifNumber == cifNumber)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.aadhaarNumber, aadhaarNumber) || other.aadhaarNumber == aadhaarNumber)&&(identical(other.panNumber, panNumber) || other.panNumber == panNumber)&&(identical(other.savingsAccount, savingsAccount) || other.savingsAccount == savingsAccount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.migrationSource, migrationSource) || other.migrationSource == migrationSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,phone,address,cifNumber,dateOfBirth,aadhaarNumber,panNumber,savingsAccount,createdAt,updatedAt,migrationSource);

@override
String toString() {
  return 'Customer(id: $id, name: $name, email: $email, phone: $phone, address: $address, cifNumber: $cifNumber, dateOfBirth: $dateOfBirth, aadhaarNumber: $aadhaarNumber, panNumber: $panNumber, savingsAccount: $savingsAccount, createdAt: $createdAt, updatedAt: $updatedAt, migrationSource: $migrationSource)';
}


}

/// @nodoc
abstract mixin class $CustomerCopyWith<$Res>  {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) _then) = _$CustomerCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? email, String? phone, String? address, String? cifNumber, DateTime? dateOfBirth, String? aadhaarNumber, String? panNumber, SavingsAccount? savingsAccount,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? createdAt,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? updatedAt,@JsonKey(includeIfNull: false) String? migrationSource
});


$SavingsAccountCopyWith<$Res>? get savingsAccount;

}
/// @nodoc
class _$CustomerCopyWithImpl<$Res>
    implements $CustomerCopyWith<$Res> {
  _$CustomerCopyWithImpl(this._self, this._then);

  final Customer _self;
  final $Res Function(Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = freezed,Object? phone = freezed,Object? address = freezed,Object? cifNumber = freezed,Object? dateOfBirth = freezed,Object? aadhaarNumber = freezed,Object? panNumber = freezed,Object? savingsAccount = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? migrationSource = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,cifNumber: freezed == cifNumber ? _self.cifNumber : cifNumber // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,aadhaarNumber: freezed == aadhaarNumber ? _self.aadhaarNumber : aadhaarNumber // ignore: cast_nullable_to_non_nullable
as String?,panNumber: freezed == panNumber ? _self.panNumber : panNumber // ignore: cast_nullable_to_non_nullable
as String?,savingsAccount: freezed == savingsAccount ? _self.savingsAccount : savingsAccount // ignore: cast_nullable_to_non_nullable
as SavingsAccount?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,migrationSource: freezed == migrationSource ? _self.migrationSource : migrationSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SavingsAccountCopyWith<$Res>? get savingsAccount {
    if (_self.savingsAccount == null) {
    return null;
  }

  return $SavingsAccountCopyWith<$Res>(_self.savingsAccount!, (value) {
    return _then(_self.copyWith(savingsAccount: value));
  });
}
}



/// @nodoc
@JsonSerializable()

class _Customer extends Customer {
  const _Customer({required this.id, required this.name, this.email, this.phone, this.address, this.cifNumber, this.dateOfBirth, this.aadhaarNumber, this.panNumber, this.savingsAccount, @TimestampConverter()@JsonKey(includeIfNull: false) this.createdAt, @TimestampConverter()@JsonKey(includeIfNull: false) this.updatedAt, @JsonKey(includeIfNull: false) this.migrationSource}): super._();
  factory _Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? email;
@override final  String? phone;
@override final  String? address;
@override final  String? cifNumber;
@override final  DateTime? dateOfBirth;
@override final  String? aadhaarNumber;
@override final  String? panNumber;
@override final  SavingsAccount? savingsAccount;
@override@TimestampConverter()@JsonKey(includeIfNull: false) final  DateTime? createdAt;
@override@TimestampConverter()@JsonKey(includeIfNull: false) final  DateTime? updatedAt;
@override@JsonKey(includeIfNull: false) final  String? migrationSource;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerCopyWith<_Customer> get copyWith => __$CustomerCopyWithImpl<_Customer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.cifNumber, cifNumber) || other.cifNumber == cifNumber)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.aadhaarNumber, aadhaarNumber) || other.aadhaarNumber == aadhaarNumber)&&(identical(other.panNumber, panNumber) || other.panNumber == panNumber)&&(identical(other.savingsAccount, savingsAccount) || other.savingsAccount == savingsAccount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.migrationSource, migrationSource) || other.migrationSource == migrationSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,phone,address,cifNumber,dateOfBirth,aadhaarNumber,panNumber,savingsAccount,createdAt,updatedAt,migrationSource);

@override
String toString() {
  return 'Customer(id: $id, name: $name, email: $email, phone: $phone, address: $address, cifNumber: $cifNumber, dateOfBirth: $dateOfBirth, aadhaarNumber: $aadhaarNumber, panNumber: $panNumber, savingsAccount: $savingsAccount, createdAt: $createdAt, updatedAt: $updatedAt, migrationSource: $migrationSource)';
}


}

/// @nodoc
abstract mixin class _$CustomerCopyWith<$Res> implements $CustomerCopyWith<$Res> {
  factory _$CustomerCopyWith(_Customer value, $Res Function(_Customer) _then) = __$CustomerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? email, String? phone, String? address, String? cifNumber, DateTime? dateOfBirth, String? aadhaarNumber, String? panNumber, SavingsAccount? savingsAccount,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? createdAt,@TimestampConverter()@JsonKey(includeIfNull: false) DateTime? updatedAt,@JsonKey(includeIfNull: false) String? migrationSource
});


@override $SavingsAccountCopyWith<$Res>? get savingsAccount;

}
/// @nodoc
class __$CustomerCopyWithImpl<$Res>
    implements _$CustomerCopyWith<$Res> {
  __$CustomerCopyWithImpl(this._self, this._then);

  final _Customer _self;
  final $Res Function(_Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = freezed,Object? phone = freezed,Object? address = freezed,Object? cifNumber = freezed,Object? dateOfBirth = freezed,Object? aadhaarNumber = freezed,Object? panNumber = freezed,Object? savingsAccount = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? migrationSource = freezed,}) {
  return _then(_Customer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,cifNumber: freezed == cifNumber ? _self.cifNumber : cifNumber // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,aadhaarNumber: freezed == aadhaarNumber ? _self.aadhaarNumber : aadhaarNumber // ignore: cast_nullable_to_non_nullable
as String?,panNumber: freezed == panNumber ? _self.panNumber : panNumber // ignore: cast_nullable_to_non_nullable
as String?,savingsAccount: freezed == savingsAccount ? _self.savingsAccount : savingsAccount // ignore: cast_nullable_to_non_nullable
as SavingsAccount?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,migrationSource: freezed == migrationSource ? _self.migrationSource : migrationSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SavingsAccountCopyWith<$Res>? get savingsAccount {
    if (_self.savingsAccount == null) {
    return null;
  }

  return $SavingsAccountCopyWith<$Res>(_self.savingsAccount!, (value) {
    return _then(_self.copyWith(savingsAccount: value));
  });
}
}

// dart format on
