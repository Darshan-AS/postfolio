import 'package:material_ui/material_ui.dart';

/// An app bar title that stays whole beside the bar's actions.
///
/// A title that does not fit is scaled down rather than cut: "Recurring Depo…" next to
/// the view switch on a 360dp phone, or any title at a large system text size.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(title, maxLines: 1, softWrap: false),
    );
  }
}
