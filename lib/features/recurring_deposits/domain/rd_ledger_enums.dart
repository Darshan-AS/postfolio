import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum RDInstallmentStatus {
  unpaid,
  partiallyPaid,
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
  unpaid,
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
  cash,
  upi,
  cheque,
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
