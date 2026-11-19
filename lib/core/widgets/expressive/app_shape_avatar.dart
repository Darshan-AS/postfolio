import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';

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
    this.opensFrom,
  });

  static const double defaultSize = AppDimensions.iconXl;

  /// How long an avatar with [opensFrom] stays its first shape: the time a screen's
  /// content takes to fade in, so that the turning is seen.
  static const Duration _openWait = AppMotion.spatialFastDuration;

  final Widget child;
  final AppAvatarShape shape;
  final double size;

  /// Defaults to `primaryContainer`.
  final Color? backgroundColor;

  /// Colour for text and icons inside. Defaults to `onPrimaryContainer`.
  final Color? foregroundColor;

  /// The shape the avatar opens from, once, when it is first shown: it turns into [shape]
  /// and stays. For a screen's one mark, not for rows. The turning is the official shape
  /// border's own (it blends two shapes); a device set to remove animations gets [shape]
  /// at once.
  final AppAvatarShape? opensFrom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = foregroundColor ?? scheme.onPrimaryContainer;
    final border = MaterialShapeBorder(shape: shape.polygon);
    final content = IconTheme.merge(
      data: IconThemeData(color: foreground),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Center(child: child),
      ),
    );

    // `Material` eases a changed shape in by itself. While the shape is given frame by
    // frame that easing would trail behind it.
    Widget surface(
      ShapeBorder shape,
      Widget? child, {
      bool frameByFrame = false,
    }) => Material(
      color: backgroundColor ?? scheme.primaryContainer,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      animationDuration: frameByFrame ? Duration.zero : kThemeChangeDuration,
      child: child,
    );

    final from = opensFrom;
    return SizedBox.square(
      dimension: size,
      child: from == null || MediaQuery.disableAnimationsOf(context)
          ? surface(border, content)
          : TweenAnimationBuilder<ShapeBorder?>(
              tween: ShapeBorderTween(
                begin: MaterialShapeBorder(shape: from.polygon),
                end: border,
              ),
              duration: _openWait + AppMotion.spatialDuration,
              // Between the two shapes all the way: an overshoot would ask for a shape
              // past the second one.
              curve: Interval(
                _openWait.inMilliseconds /
                    (_openWait + AppMotion.spatialDuration).inMilliseconds,
                1,
                curve: AppMotion.effectsCurve,
              ),
              child: content,
              builder: (context, shape, child) =>
                  surface(shape ?? border, child, frameByFrame: true),
            ),
    );
  }
}
