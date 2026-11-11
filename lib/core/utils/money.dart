/// Zero-cost integer-paise value type (`1 rupee == 100 paise`).
///
/// Eliminates IEEE-754 binary floating-point rounding drift at compile time with zero heap
/// wrapper allocation.
extension type const Paise(int value) {
  static const Paise zero = Paise(0);
  static const int perRupee = 100;

  factory Paise.fromRupees(double rupees) => Paise((rupees * perRupee).round());

  double toRupees() => value / perRupee;
  bool get isZero => value == 0;
  bool get isPositive => value > 0;
  bool get isNegative => value < 0;
  bool get hasSubRupeePaise => value.abs() % perRupee != 0;

  int ceilToRupees() => (value + perRupee - 1) ~/ perRupee;

  Paise operator +(Paise other) => Paise(value + other.value);
  Paise operator -(Paise other) => Paise(value - other.value);
  Paise operator -() => Paise(-value);
  Paise operator *(int factor) => Paise(value * factor);
  int operator ~/(Paise other) => value ~/ other.value;

  bool operator <(Paise other) => value < other.value;
  bool operator <=(Paise other) => value <= other.value;
  bool operator >(Paise other) => value > other.value;
  bool operator >=(Paise other) => value >= other.value;

  Paise clamp(Paise min, Paise max) {
    if (value < min.value) return min;
    if (value > max.value) return max;
    return this;
  }

  int compareTo(Paise other) => value.compareTo(other.value);
}

/// Zero-cost basis-points value type (`1% == 100 bps`, `100.00% == 10000 bps`).
///
/// Used for nominee share totals (`16.1 + 48.2 + 35.7 == 100.00%`) and interest rates so
/// decimal percentages never fail equality checks due to binary float representation.
extension type const BasisPoints(int value) {
  static const BasisPoints zero = BasisPoints(0);
  static const BasisPoints hundredPercent = BasisPoints(10000);
  static const int perPercent = 100;

  factory BasisPoints.fromPercent(double percent) =>
      BasisPoints((percent * perPercent).round());

  double toPercent() => value / perPercent;

  BasisPoints operator +(BasisPoints other) => BasisPoints(value + other.value);
  BasisPoints operator -(BasisPoints other) => BasisPoints(value - other.value);
  bool operator <(BasisPoints other) => value < other.value;
  bool operator <=(BasisPoints other) => value <= other.value;
  bool operator >(BasisPoints other) => value > other.value;
  bool operator >=(BasisPoints other) => value >= other.value;

  int compareTo(BasisPoints other) => value.compareTo(other.value);
}

/// Integer-paise money helpers bridging domain models (`double` JSON boundary) and `Paise`.
abstract final class Money {
  static const int paisePerRupee = Paise.perRupee;

  /// Converts a rupee amount to integer paise, rounding half away from zero.
  static int toPaise(double rupees) => Paise.fromRupees(rupees).value;

  /// Converts integer paise back to a rupee double with 2 decimal places of precision.
  static double toRupees(int paise) => Paise(paise).toRupees();

  /// Rounds a rupee double to 2 decimal places via the paise domain.
  static double round(double rupees) => Paise.fromRupees(rupees).toRupees();

  /// Whole-rupee ceiling of a paise amount (e.g. 150 paise -> 2 rupees).
  static int ceilToRupees(int paise) => Paise(paise).ceilToRupees();

  /// Money-safe equality (true when the two amounts round to the same paise).
  static bool equals(double a, double b) =>
      Paise.fromRupees(a) == Paise.fromRupees(b);

  /// Money-safe zero check.
  static bool isZero(double rupees) => Paise.fromRupees(rupees).isZero;
}
