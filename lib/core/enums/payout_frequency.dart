import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum PayoutFrequency {
  @JsonValue('monthly')
  monthly(monthsInterval: 1),
  @JsonValue('quarterly')
  quarterly(monthsInterval: 3),
  @JsonValue('annually')
  annually(monthsInterval: 12);

  /// The number of months between each payout.
  final int monthsInterval;

  const PayoutFrequency({required this.monthsInterval});

  /// Mathematical helper: How many payouts happen in a single year?
  int get payoutsPerYear => 12 ~/ monthsInterval;

  String get displayName {
    switch (this) {
      case PayoutFrequency.monthly:
        return t.enums.payoutFrequency.monthly;
      case PayoutFrequency.quarterly:
        return t.enums.payoutFrequency.quarterly;
      case PayoutFrequency.annually:
        return t.enums.payoutFrequency.annually;
    }
  }
}
