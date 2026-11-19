import 'package:material_ui/material_ui.dart';

/// Where a row sits inside an [AppShapes.group] of rows.
enum AppGroupPosition {
  /// The only row: every corner takes the outer radius.
  single,
  first,
  middle,
  last;

  /// Position of row [index] in a group of [count] rows.
  static AppGroupPosition at(int index, int count) {
    if (count <= 1) return AppGroupPosition.single;
    if (index == 0) return AppGroupPosition.first;
    if (index == count - 1) return AppGroupPosition.last;
    return AppGroupPosition.middle;
  }
}

/// Material 3 Expressive corner scale and the shapes built from it.
///
/// The radii are the spec's shape tokens (`corner.small` … `corner.extra-extra-large`),
/// including the three steps Expressive added: `large-increased`, `extra-large-increased`
/// and `extra-extra-large`.
abstract final class AppShapes {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double largeIncreased = 20;
  static const double extraLarge = 28;
  static const double extraLargeIncreased = 32;
  static const double extraExtraLarge = 48;

  /// Outer corners of a group of rows, and of a stand-alone card.
  static const double groupOuter = largeIncreased;

  /// Corners between two rows of the same group.
  static const double groupInner = extraSmall;

  /// Gap between two rows of the same group.
  static const double groupGap = 2;

  /// A pressed row or card pulls its corners in to this radius.
  static const double pressed = medium;

  static const StadiumBorder pill = StadiumBorder();

  static RoundedRectangleBorder rounded(
    double radius, {
    BorderSide side = BorderSide.none,
  }) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side,
  );

  /// Corner radii of a row at [position]: outer corners on the group's edge, inner corners
  /// where it meets a neighbour.
  static BorderRadius groupRadius(AppGroupPosition position) {
    const outer = Radius.circular(groupOuter);
    const inner = Radius.circular(groupInner);
    return switch (position) {
      AppGroupPosition.single => const BorderRadius.all(outer),
      AppGroupPosition.first => const BorderRadius.vertical(
        top: outer,
        bottom: inner,
      ),
      AppGroupPosition.middle => const BorderRadius.all(inner),
      AppGroupPosition.last => const BorderRadius.vertical(
        top: inner,
        bottom: outer,
      ),
    };
  }

  static RoundedRectangleBorder group(AppGroupPosition position) =>
      RoundedRectangleBorder(borderRadius: groupRadius(position));

  /// Top-rounded shape of bottom sheets.
  static const RoundedRectangleBorder sheet = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(extraLarge)),
  );
}
