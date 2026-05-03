import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

@JsonEnum()
enum DepositStatus {
  active,
  matured,
  closed;

  String get displayName => t.enums.depositStatus[name] ?? name;
}
