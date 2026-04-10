import 'package:freezed_annotation/freezed_annotation.dart';

enum DepositStatus {
  @JsonValue('active')
  active(displayName: 'Active'),
  @JsonValue('matured')
  matured(displayName: 'Matured'),
  @JsonValue('closed')
  closed(displayName: 'Closed');

  final String displayName;

  const DepositStatus({required this.displayName});
}
