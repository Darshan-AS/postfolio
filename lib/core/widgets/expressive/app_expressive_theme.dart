import 'package:material_3_expressive/foundations/theme/m3e_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Exposes [M3ETheme] derived from the ambient Material [ThemeData] without leaking
/// `package:material_3_expressive` imports outside `lib/core/widgets/expressive/`.
class AppExpressiveTheme extends StatelessWidget {
  const AppExpressiveTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return M3ETheme(
      data: M3EThemeData.fromMaterial(Theme.of(context)),
      child: child,
    );
  }
}
