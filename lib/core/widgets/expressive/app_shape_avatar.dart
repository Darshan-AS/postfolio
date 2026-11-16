import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

/// Shapes from the official Material shape library ([MaterialShapes]) used for avatars and
/// hero badges.
///
/// On a row or a detail header a shape other than a circle names a deposit scheme, and
/// nothing else: status is a pill and a colour, a payment mode is an icon. People are
/// [person]. Illustrations (empty states, the login badge) use whichever shape suits them.
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

  /// The shape of every person. It varied from person to person, in the shapes the
  /// schemes use, and meant nothing.
  static const AppAvatarShape person = AppAvatarShape.circle;

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
