import 'package:material_ui/material_ui.dart';

/// The app's surface hierarchy, named by job instead of by tone.
///
/// Material 3 Expressive separates content by tone, not by outlines: a tinted page, lighter
/// containers resting on it, and a recessed tone for things nested inside a container.
extension AppSurfaceRoles on ColorScheme {
  /// The page itself: scaffold, app bar and navigation bar.
  Color get page => surfaceContainer;

  /// Rows, cards and other containers resting on the [page].
  Color get raised => surfaceBright;

  /// A fill nested inside a [raised] container: text fields, inner tiles.
  Color get inset => surfaceContainerHigh;
}
