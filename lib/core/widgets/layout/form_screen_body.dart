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

  /// Label for the submit button when idle. Defaults to [t.common.confirm].
  final String? submitLabel;

  /// Whether the submit button can be pressed while idle.
  final bool isEnabled;

  /// Shows a compact primary indicator above the submit button when unsaved edits exist.
  final bool showUnsavedHint;

  const FormScreenBody({
    super.key,
    required this.child,
    required this.isSaving,
    required this.onSave,
    this.submitLabel,
    this.isEnabled = true,
    this.showUnsavedHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        // Opaque: the fields scroll up to its top edge.
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.page,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showUnsavedHint && !isSaving) ...[
                        Text(
                          t.common.unsavedChangesIndicator,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.primary),
                        ),
                        AppSpacings.gapXs,
                      ],
                      AppButton(
                        label: isSaving
                            ? t.common.saving
                            : (submitLabel ?? t.common.confirm),
                        icon: HugeIcons.strokeRoundedTick01,
                        size: AppButtonSize.medium,
                        expand: true,
                        isLoading: isSaving,
                        onPressed: isEnabled ? onSave : null,
                      ),
                    ],
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
