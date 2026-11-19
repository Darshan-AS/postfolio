import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';

/// App bar of a create / edit form: back and the form's title. Saving is the button under
/// the fields (`FormScreenBody`).
class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;

  const FormAppBar({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AppBarTitle(title),
      leading: onBack != null ? BackButton(onPressed: onBack) : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}
