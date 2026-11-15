import 'package:material_3_expressive/components/refresh_indicator/m3e_refresh_indicator.dart';
import 'package:material_ui/material_ui.dart';

/// Pull-to-refresh that shows the Material 3 Expressive loading indicator on a tonal disc.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;

  /// The scrollable to refresh.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return M3ERefreshIndicator.contained(onRefresh: onRefresh, child: child);
  }
}
