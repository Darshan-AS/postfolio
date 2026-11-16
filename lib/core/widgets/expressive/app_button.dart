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
/// The label stays on one line and scales down when the button is too narrow for it.
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
  }) : selected = null,
       flushStart = false;

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
  }) : variant = AppButtonVariant.tonal,
       selected = null,
       flushStart = false;

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
  }) : variant = AppButtonVariant.outlined,
       selected = null,
       flushStart = false;

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
    this.flushStart = false,
  }) : variant = AppButtonVariant.text,
       selected = null;

  /// A toggle button: tonal while off, filled while [selected]. Every press is reported and
  /// the caller flips the state. Use it for one on/off choice, or several independent ones
  /// that wrap; a few options that belong together are an `AppButtonGroup`.
  const AppButton.toggle({
    super.key,
    required this.label,
    required bool this.selected,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.small,
    this.expand = false,
    this.tooltip,
  }) : variant = AppButtonVariant.tonal,
       isLoading = false,
       isDestructive = false,
       backgroundColor = null,
       foregroundColor = null,
       flushStart = false;

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

  /// Whether a toggle button is on; null for a button that is not a toggle.
  final bool? selected;

  /// Pulls a text button back by its own inset, so its icon or label starts where the text
  /// above it starts. The button keeps its size and its pressed shape hangs over that edge.
  final bool flushStart;

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

  /// The space Material 3 Expressive leaves before the icon or label at each size.
  double get _leadingSpace => switch (size) {
    AppButtonSize.extraSmall => 12,
    AppButtonSize.small => 16,
    AppButtonSize.medium => 24,
    AppButtonSize.large => 48,
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
    final scheme = Theme.of(context).colorScheme;
    final isOn = selected ?? false;
    // A toggle that is on takes the selected colours of a tonal toggle, the ones a selected
    // segment of an `AppButtonGroup` has.
    final colors = isOn
        ? (background: scheme.secondary, foreground: scheme.onSecondary)
        : _colors(scheme);
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
      // A toggle is drawn as a standard button with the selected colours and shape, not
      // through the package's `isSelected`. On its own, outside a group, that path sizes
      // the content box by aspect ratio and the button comes out about twice as wide as
      // its label.
      shape: isOn ? M3EButtonShape.square : M3EButtonShape.round,
      decoration: decoration,
      icon: leading,
      // A label that does not fit shrinks; it is never cut. Labels carry amounts
      // ("Collect ₹1,25,000"), and an ellipsis there hides the money.
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    );

    // The official Tooltip (the one `find.byTooltip` looks for), merged with the button so
    // a screen reader gets one node carrying the label, the tooltip and the action. The
    // community tooltip only labels its own bubble. A toggle's state joins the same node.
    Widget labelled = button;
    if (tooltip != null) {
      labelled = Tooltip(message: tooltip, child: labelled);
    }
    if (selected != null) {
      labelled = Semantics(selected: selected, child: labelled);
    }
    if (tooltip != null || selected != null) {
      labelled = MergeSemantics(child: labelled);
    }

    if (flushStart) {
      final towardsStart = Directionality.of(context) == TextDirection.ltr ? -1.0 : 1.0;
      labelled = Transform.translate(
        offset: Offset(towardsStart * _leadingSpace, 0),
        child: labelled,
      );
    }

    return expand
        ? SizedBox(width: double.infinity, child: labelled)
        : labelled;
  }
}
