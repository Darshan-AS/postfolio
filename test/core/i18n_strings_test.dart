import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Strings whose wording depends on a count.
void main() {
  test(
    'months waiting for the Post Office are counted in the singular for one',
    () {
      final passbook = t.recurringDeposits.ledger.passbook;

      expect(
        passbook.readyToDeposit(n: 1, amount: '₹5,000'),
        contains('1 month ·'),
      );
      expect(
        passbook.readyToDeposit(n: 1, amount: '₹5,000'),
        isNot(contains('months')),
      );
      expect(
        passbook.readyToDeposit(n: 3, amount: '₹15,000'),
        contains('3 months ·'),
      );

      expect(
        passbook.readyToDepositWithFee(n: 1, amount: '₹5,050', fee: '₹50'),
        allOf(
          contains('1 month ·'),
          isNot(contains('months')),
          contains('₹50 fee'),
        ),
      );
      expect(
        passbook.readyToDepositWithFee(n: 2, amount: '₹10,100', fee: '₹100'),
        contains('2 months ·'),
      );
    },
  );
}
