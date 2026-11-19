import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/i18n/strings.g.dart';

const int _accountTailLength = 4;

/// `Sl 12 • A/c …7890`: the serial an agent knows an account by, and the end of its
/// account number. Just the account when there is no serial.
String rdAccountIdentity(RecurringDeposit deposit) {
  final card = t.recurringDeposits.monthlyOperations.card;
  final accountNo = deposit.accountNo ?? '';
  final last4 = accountNo.length > _accountTailLength
      ? accountNo.substring(accountNo.length - _accountTailLength)
      : (accountNo.isEmpty ? t.common.notProvided : accountNo);
  final account = card.accountTail(last4: last4);
  final serialNo = deposit.serialNo;
  return serialNo == null || serialNo.isEmpty
      ? account
      : card.identity(
          serial: card.serial(serialNo: serialNo),
          account: account,
        );
}
