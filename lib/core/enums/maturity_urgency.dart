import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

@JsonEnum()
enum MaturityUrgency {
  normal,
  maturingSoon,
  matured,
  closed;

  String get displayName => t.enums.maturityUrgency[name] ?? name;
}
