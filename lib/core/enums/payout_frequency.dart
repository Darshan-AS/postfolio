import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

@JsonEnum()
enum PayoutFrequency {
  monthly(monthsInterval: 1),
  quarterly(monthsInterval: 3),
  annually(monthsInterval: 12);

  /// The number of months between each payout.
  final int monthsInterval;

  const PayoutFrequency({required this.monthsInterval});

  /// Mathematical helper: How many payouts happen in a single year?
  int get payoutsPerYear => 12 ~/ monthsInterval;

  String get displayName => t.enums.payoutFrequency[name] ?? name;
}
