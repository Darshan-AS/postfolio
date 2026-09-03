import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum RDInstallmentStatus {
  @JsonValue('unpaid')
  unpaid,
  @JsonValue('partially_paid')
  partiallyPaid,
  @JsonValue('fully_paid')
  fullyPaid;

  String get displayName {
    switch (this) {
      case RDInstallmentStatus.unpaid:
        return 'Unpaid';
      case RDInstallmentStatus.partiallyPaid:
        return 'Partially Paid';
      case RDInstallmentStatus.fullyPaid:
        return 'Fully Paid';
    }
  }
}

@JsonEnum()
enum RDPoStatus {
  @JsonValue('unpaid')
  unpaid,
  @JsonValue('paid')
  paid;

  String get displayName {
    switch (this) {
      case RDPoStatus.unpaid:
        return 'Not Deposited';
      case RDPoStatus.paid:
        return 'Deposited';
    }
  }
}

@JsonEnum()
enum RDPaymentMode {
  @JsonValue('cash')
  cash,
  @JsonValue('upi')
  upi,
  @JsonValue('cheque')
  cheque,
  @JsonValue('bank_transfer')
  bankTransfer;

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
