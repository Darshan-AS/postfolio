import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';

/// Emphasis of an [AppButton], highest first.
enum AppButtonVariant { filled, tonal, elevated, outlined, text }

/// Material 3 Expressive button sizes (container height in dp).
enum AppButtonSize {
  /// 32dp. Dense inline actions.
  extraSmall,

  /// 40dp. The default.
  small,

  /// 56dp. The main action of a screen or sheet.
  medium,

  /// 96dp. A single hero action.
  large,
}

/// A Material 3 Expressive button: a pill that pulls its corners in on a spring while it
/// is pressed.
///
/// One widget covers what `FilledButton`, `FilledButton.tonal`, `OutlinedButton` and
/// `TextButton` did, so every action in the app shares the same shape, motion and sizes.
/// The official `material_ui` buttons have no Expressive variant yet (only `ElevatedButton`
/// does); when they do, this wrapper is the one place to switch.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.small,
    this.expand = false,
    this.isLoading = false,
    this.isDestructive = false,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.small,
    this.expand = false,
    this.isLoading = false,
    this.isDestructive = false,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.small,
    this.expand = false,
    this.isLoading = false,
    this.isDestructive = false,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.small,
    this.expand = false,
    this.isLoading = false,
    this.isDestructive = false,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  }) : variant = AppButtonVariant.text;

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Fill the available width instead of hugging the label.
  final bool expand;

  /// Shows a loading indicator in the icon slot and ignores presses.
  final bool isLoading;

  /// Uses the error colours for this [variant].
  final bool isDestructive;

  /// Overrides the container colour (e.g. a financial status colour).
  final Color? backgroundColor;

  /// Overrides the label and icon colour.
  final Color? foregroundColor;
  final String? tooltip;

  M3EButtonStyle get _style => switch (variant) {
    AppButtonVariant.filled => M3EButtonStyle.filled,
    AppButtonVariant.tonal => M3EButtonStyle.tonal,
    AppButtonVariant.elevated => M3EButtonStyle.elevated,
    AppButtonVariant.outlined => M3EButtonStyle.outlined,
    AppButtonVariant.text => M3EButtonStyle.text,
  };

  M3EButtonSize get _size => switch (size) {
    AppButtonSize.extraSmall => M3EButtonSize.xs,
    AppButtonSize.small => M3EButtonSize.sm,
    AppButtonSize.medium => M3EButtonSize.md,
    AppButtonSize.large => M3EButtonSize.lg,
  };

  double get _iconSize => switch (size) {
    AppButtonSize.extraSmall || AppButtonSize.small => 20,
    AppButtonSize.medium => 24,
    AppButtonSize.large => 32,
  };

  ({Color? background, Color? foreground}) _colors(ColorScheme scheme) {
    if (!isDestructive) {
      return (background: backgroundColor, foreground: foregroundColor);
    }
    return switch (variant) {
      AppButtonVariant.filled => (
        background: scheme.error,
        foreground: scheme.onError,
      ),
      AppButtonVariant.tonal => (
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
      AppButtonVariant.elevated ||
      AppButtonVariant.outlined ||
      AppButtonVariant.text => (background: null, foreground: scheme.error),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(Theme.of(context).colorScheme);
    final decoration = (colors.background != null || colors.foreground != null)
        ? M3EButtonDecoration.styleFrom(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
          )
        : null;

    final Widget? leading = isLoading
        ? AppLoadingIndicator(size: _iconSize, color: colors.foreground)
        : icon != null
        ? AppIcon(icon!, size: _iconSize, color: colors.foreground)
        : null;

    final button = M3EButton(
      onPressed: isLoading ? null : onPressed,
      enabled: onPressed != null,
      style: _style,
      size: _size,
      decoration: decoration,
      tooltip: tooltip,
      icon: leading,
      label: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
