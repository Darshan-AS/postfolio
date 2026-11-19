import 'package:material_3_expressive/components/selection/m3e_selection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_motion.dart';

/// Turns [child] over to show [selectedChild], and back: a row's avatar becoming its
/// selection mark.
///
/// The community widget keeps both faces laid out so the row does not change size. It
/// always turns over 220ms; on a device set to remove animations the face is swapped at
/// once here.
class AppSelectionFlip extends StatelessWidget {
  const AppSelectionFlip({
    super.key,
    required this.selected,
    required this.child,
    required this.selectedChild,
  });

  final bool selected;
  final Widget child;
  final Widget selectedChild;

  @override
  Widget build(BuildContext context) {
    return M3ESelectionFlip(
      selected: selected,
      selectedChild: selectedChild,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.effectsDuration,
      // The faces set the size; the row is the touch target.
      minTapSize: 0,
      child: child,
    );
  }
}
