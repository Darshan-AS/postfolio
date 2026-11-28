import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

@JsonEnum()
enum AgencyType {
  mpkby,
  sas;

  String get displayName => t.enums.agencyType[name] ?? name;

  String get shortLabel => t.enums.agencyTypeShort[name] ?? name.toUpperCase();
}
