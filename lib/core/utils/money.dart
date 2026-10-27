/// Integer-paise money helpers.
///
/// The ledger allocates in integer paise and only converts back to rupee `double`s at the
/// boundary, so `==` comparisons and running sums never drift by floating-point epsilons.
abstract final class Money {
  static const int paisePerRupee = 100;

  /// Converts a rupee amount to integer paise, rounding half away from zero.
  static int toPaise(double rupees) => (rupees * paisePerRupee).round();

  /// Converts integer paise back to a rupee double with exactly 2 decimal places of precision.
  static double toRupees(int paise) => paise / paisePerRupee;

  /// Rounds a rupee double to 2 decimal places via the paise domain.
  static double round(double rupees) => toRupees(toPaise(rupees));

  /// Whole-rupee ceiling of a paise amount (e.g. 150 paise -> 2 rupees).
  static int ceilToRupees(int paise) =>
      (paise + paisePerRupee - 1) ~/ paisePerRupee;

  /// Money-safe equality (true when the two amounts round to the same paise).
  static bool equals(double a, double b) => toPaise(a) == toPaise(b);

  /// Money-safe zero check.
  static bool isZero(double rupees) => toPaise(rupees) == 0;
}
