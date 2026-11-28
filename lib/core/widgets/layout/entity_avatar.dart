import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';

/// The avatar of an entity that is written, not drawn: a customer's initial, a deposit's
/// scheme over its term, a recurring deposit's serial.
///
/// It has two forms. In a row of a list it is small and so are its letters. At the head of
/// the entity's screen it is larger and its letters are larger for its size: there it is
/// the first thing read. [prominence] says which form: 0 the row's, 1 the head's. What lies
/// between is what the avatar looks like on its way from a row to the head of the screen
/// (see `EntityHero`), so it grows there instead of arriving as the other form.
class EntityAvatar extends StatelessWidget {
  const EntityAvatar({
    super.key,
    required this.text,
    this.subtext,
    this.shape = AppAvatarShape.cookie9,
    this.backgroundColor,
    this.foregroundColor,
    this.prominence = 0,
  });

  final String text;

  /// A smaller line under [text], e.g. a deposit's term under its scheme.
  final String? subtext;
  final AppAvatarShape shape;

  /// Defaults to `primaryContainer`.
  final Color? backgroundColor;

  /// Defaults to `onPrimaryContainer`.
  final Color? foregroundColor;

  /// 0 for the form in a row, 1 for the form at the head of a screen.
  final double prominence;

  /// The line height of the row's [text] when it stands over a [subtext].
  static const double _rowLineHeight = 1.15;

  static const TextHeightBehavior _noLeading = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  /// The avatar [t] of the way from its form in [row] to its form at [head].
  static EntityAvatar between(
    EntityAvatar row,
    EntityAvatar head,
    double t,
  ) => EntityAvatar(
    text: head.text,
    subtext: head.subtext,
    shape: head.shape,
    backgroundColor: Color.lerp(row.backgroundColor, head.backgroundColor, t),
    foregroundColor: Color.lerp(row.foregroundColor, head.foregroundColor, t),
    prominence: lerpDouble(row.prominence, head.prominence, t)!,
  );

  /// [row] at 0, [head] at 1, and the two blended in between.
  TextStyle? _style(TextStyle? row, TextStyle? head) => switch (prominence) {
    0 => row,
    1 => head,
    _ => TextStyle.lerp(row, head, prominence),
  };

  double _dimension(double row, double head) =>
      lerpDouble(row, head, prominence)!;

  @override
  Widget build(BuildContext context) {
    final emphasized = AppTypography.emphasizedOf(context);
    final foreground =
        foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer;
    final muted = foreground.withValues(alpha: AppDimensions.opacityMuted);
    final subtext = this.subtext;
    final hasSubtext = subtext != null && subtext.isNotEmpty;

    return AppShapeAvatar(
      size: _dimension(AppDimensions.avatarMd, AppDimensions.avatarLg),
      shape: shape,
      backgroundColor: backgroundColor,
      foregroundColor: foreground,
      child: Padding(
        padding: EdgeInsets.all(
          _dimension(AppDimensions.paddingSm, AppDimensions.paddingMd),
        ),
        // Whatever the text, it stays inside the shape.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                textHeightBehavior: _noLeading,
                style: _style(
                  // In a row an initial is larger than a code of several letters.
                  (text.length == 1
                          ? emphasized.titleLarge
                          : emphasized.titleSmall)
                      ?.copyWith(
                        height: hasSubtext ? _rowLineHeight : null,
                        color: foreground,
                      ),
                  emphasized.displaySmall?.copyWith(
                    height: hasSubtext ? AppDimensions.lineHeightTight : null,
                    color: foreground,
                  ),
                ),
              ),
              if (hasSubtext) ...[
                SizedBox(
                  height: _dimension(
                    AppDimensions.paddingXxs,
                    AppDimensions.paddingXs,
                  ),
                ),
                Text(
                  subtext,
                  textHeightBehavior: _noLeading,
                  style: _style(
                    emphasized.labelSmall?.copyWith(
                      fontSize: AppDimensions.fontXs,
                      height: AppDimensions.lineHeightTight,
                      color: muted,
                    ),
                    emphasized.titleMedium?.copyWith(
                      height: AppDimensions.lineHeightTight,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
