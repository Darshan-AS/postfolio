import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The body of a create / edit screen: the fields scroll and the save button stays under
/// them.
///
/// The button is the one way to save. It is part of the body, not of the scaffold's bottom
/// slot, so it stays above the keyboard: a field can be corrected and saved without closing
/// the keyboard first. The forms are several screens long, and the button used to be at the
/// very end of them, with an unlabelled tick in the app bar as the way to reach it sooner.
class FormScreenBody extends StatelessWidget {
  /// The scrolling fields.
  final Widget child;
  final bool isSaving;
  final VoidCallback onSave;

  const FormScreenBody({
    super.key,
    required this.child,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        // Opaque: the fields scroll up to its top edge.
        ColoredBox(
          color: Theme.of(context).colorScheme.page,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageMargin,
                vertical: AppDimensions.paddingSm,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxFormWidth,
                  ),
                  child: AppButton(
                    label: isSaving ? t.common.saving : t.common.confirm,
                    icon: HugeIcons.strokeRoundedTick01,
                    size: AppButtonSize.medium,
                    expand: true,
                    isLoading: isSaving,
                    onPressed: onSave,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
