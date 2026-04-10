import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum DepositStatus {
  @JsonValue('active')
  active,
  @JsonValue('matured')
  matured,
  @JsonValue('closed')
  closed;

  String get displayName {
    switch (this) {
      case DepositStatus.active:
        return t.enums.depositStatus.active;
      case DepositStatus.matured:
        return t.enums.depositStatus.matured;
      case DepositStatus.closed:
        return t.enums.depositStatus.closed;
    }
  }
}
