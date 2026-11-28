import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

/// The type of a `HugeIcons.*` constant.
///
/// `hugeicons` icons are vector data drawn by the [HugeIcon] widget, not `IconData`, so
/// widgets that size and tint an icon themselves take this and build the [HugeIcon].
typedef AppIconData = List<List<dynamic>>;

/// Draws [icon] at [size], tinted with [color] or, when null, the ambient [IconTheme] colour.
///
/// [emphasized] thickens the stroke. The icon set has one style (stroke), so a heavier stroke
/// stands in for the filled icon Material uses on a selected destination.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppDimensions.iconMd,
    this.color,
    this.emphasized = false,
  });

  final AppIconData icon;
  final double size;
  final Color? color;
  final bool emphasized;

  static const double _emphasizedStroke = 2.25;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      size: size,
      color: color ?? IconTheme.of(context).color,
      strokeWidth: emphasized ? _emphasizedStroke : null,
    );
  }
}
