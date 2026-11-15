import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

/// Layout rules shared by the Monthly Hub widgets.
abstract final class RDHubLayout {
  /// At large text, things that sit side by side at normal sizes take a line each: the
  /// header tiles, a row's status and figure, a customer header and its button, the batch
  /// bar and its action. The threshold is the app-wide one, at which `AppButtonGroup` also
  /// stacks its segments, so the whole Hub changes shape together.
  static bool isLargeText(BuildContext context) => AppDimensions.isLargeText(context);
}
