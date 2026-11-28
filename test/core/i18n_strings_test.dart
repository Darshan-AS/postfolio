import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Strings whose wording depends on a count.
void main() {
  test(
    'months waiting for the Post Office are counted in the singular for one',
    () {
      final passbook = t.recurringDeposits.ledger.passbook;

      expect(passbook.inHandTitle(n: 1), contains('1 month'));
      expect(passbook.inHandTitle(n: 1), isNot(contains('months')));
      expect(passbook.inHandTitle(n: 3), contains('3 months'));

      expect(
        passbook.inHandSubtitleWithFee(amount: '₹5,050', fee: '₹50'),
        allOf(contains('₹5,050'), contains('₹50 fee')),
      );
    },
  );
}
