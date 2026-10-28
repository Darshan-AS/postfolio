import 'package:freezed_annotation/freezed_annotation.dart';

/// How the customer handed money to the agent. Only cash counts against the ₹20,000
/// per-lot cash cap at the Post Office, so the agent float is split by [isCash].
@JsonEnum()
enum RDPaymentMode {
  cash,
  upi,
  cheque,
  bankTransfer;

  bool get isCash => this == RDPaymentMode.cash;

  String get displayName {
    switch (this) {
      case RDPaymentMode.cash:
        return 'Cash';
      case RDPaymentMode.upi:
        return 'UPI';
      case RDPaymentMode.cheque:
        return 'Cheque';
      case RDPaymentMode.bankTransfer:
        return 'Bank Transfer';
    }
  }
}
