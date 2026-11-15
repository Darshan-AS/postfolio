import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

/// Shapes from the official Material shape library ([MaterialShapes]) used for avatars and
/// hero badges. Material 3 Expressive uses these instead of plain circles.
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

  /// Shapes with enough even interior for one or two characters of text.
  static const List<AppAvatarShape> _personShapes = [
    AppAvatarShape.cookie9,
    AppAvatarShape.cookie6,
    AppAvatarShape.clover4,
    AppAvatarShape.sunny,
    AppAvatarShape.cookie12,
    AppAvatarShape.pentagon,
    AppAvatarShape.cookie7,
    AppAvatarShape.flower,
  ];

  /// A shape chosen from [seed] (a name or id), so the same person always gets the same
  /// shape and a list shows a mix of them. Uses the code units rather than `hashCode`,
  /// which differs between the VM and the web.
  static AppAvatarShape forSeed(String seed) {
    var sum = 0;
    for (final unit in seed.codeUnits) {
      sum = (sum + unit) & 0x7fffffff;
    }
    return _personShapes[sum % _personShapes.length];
  }
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
