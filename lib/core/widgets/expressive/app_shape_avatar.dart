import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

/// Shapes from the official Material shape library ([MaterialShapes]) used for avatars and
/// hero badges.
///
/// Shapes are decoration, not a code. Material's guidance is that a shape carries no
/// fixed meaning, and offers these for avatars and image crops. So: a person's avatar takes
/// one of them from the person's name ([forPerson]); a deposit's avatar takes its scheme's,
/// with the scheme written inside it; and nothing is said by a shape alone. A status is a
/// pill and a colour, a payment mode is an icon.
enum AppAvatarShape {
  circle,
  cookie4,
  cookie6,
  cookie7,
  cookie9,
  cookie12,
  clover4,
  clover8,
  sunny,
  pentagon,
  gem,
  flower,
  softBurst,
  puffy,
  arch,
  pill;

  RoundedPolygon get polygon => switch (this) {
    AppAvatarShape.circle => MaterialShapes.circle,
    AppAvatarShape.cookie4 => MaterialShapes.cookie4Sided,
    AppAvatarShape.cookie6 => MaterialShapes.cookie6Sided,
    AppAvatarShape.cookie7 => MaterialShapes.cookie7Sided,
    AppAvatarShape.cookie9 => MaterialShapes.cookie9Sided,
    AppAvatarShape.cookie12 => MaterialShapes.cookie12Sided,
    AppAvatarShape.clover4 => MaterialShapes.clover4Leaf,
    AppAvatarShape.clover8 => MaterialShapes.clover8Leaf,
    AppAvatarShape.sunny => MaterialShapes.sunny,
    AppAvatarShape.pentagon => MaterialShapes.pentagon,
    AppAvatarShape.gem => MaterialShapes.gem,
    AppAvatarShape.flower => MaterialShapes.flower,
    AppAvatarShape.softBurst => MaterialShapes.softBurst,
    AppAvatarShape.puffy => MaterialShapes.puffy,
    AppAvatarShape.arch => MaterialShapes.arch,
    AppAvatarShape.pill => MaterialShapes.pill,
  };

  /// Shapes with an even interior for an initial. None is a shape a deposit scheme takes,
  /// so a customer's avatar is not mistaken for a deposit's.
  static const List<AppAvatarShape> _personShapes = [
    AppAvatarShape.cookie9,
    AppAvatarShape.flower,
    AppAvatarShape.cookie6,
    AppAvatarShape.clover8,
    AppAvatarShape.cookie7,
    AppAvatarShape.puffy,
  ];

  /// A shape for a person, chosen from their name: the same person always has the same
  /// shape, and a list shows a mix. Uses the code units rather than `hashCode`, which
  /// differs between the VM and the web.
  static AppAvatarShape forPerson(String name) {
    var sum = 0;
    for (final unit in name.codeUnits) {
      sum = (sum + unit) & 0x7fffffff;
    }
    return _personShapes[sum % _personShapes.length];
  }

  /// The shape of an avatar that holds an icon and stands for no scheme.
  static const AppAvatarShape neutral = AppAvatarShape.circle;
}

/// A tinted Material shape holding an initial, a short code or an icon.
class AppShapeAvatar extends StatelessWidget {
  const AppShapeAvatar({
    super.key,
    required this.child,
    this.shape = AppAvatarShape.cookie9,
    this.size = defaultSize,
    this.backgroundColor,
    this.foregroundColor,
  });

  static const double defaultSize = AppDimensions.iconXl;

  final Widget child;
  final AppAvatarShape shape;
  final double size;

  /// Defaults to `primaryContainer`.
  final Color? backgroundColor;

  /// Colour for text and icons inside. Defaults to `onPrimaryContainer`.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = foregroundColor ?? scheme.onPrimaryContainer;

    return SizedBox.square(
      dimension: size,
      child: Material(
        color: backgroundColor ?? scheme.primaryContainer,
        shape: MaterialShapeBorder(shape: shape.polygon),
        clipBehavior: Clip.antiAlias,
        child: IconTheme.merge(
          data: IconThemeData(color: foreground),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
