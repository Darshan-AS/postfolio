import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppInputDecoration {
  static InputDecoration m3(
    BuildContext context, {
    String? labelText,
    String? hintText,
    String? errorText,
    Widget? prefixIcon,
    String? prefixText,
    bool isRequired = false,

    /// Rows the field shows while it is empty. Above one, the label and the icon sit on
    /// the first row instead of the middle of the field.
    int restingLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputStyle = theme.textTheme.bodyLarge;
    final rowHeight =
        MediaQuery.textScalerOf(context).scale(inputStyle?.fontSize ?? 16) *
        (inputStyle?.height ?? 1.5);
    // The decorator centres the icon in the field. Padding under it as tall as the rows
    // after the first puts it level with the first row.
    final iconLift = restingLines > 1 ? (restingLines - 1) * rowHeight : 0.0;

    // One line, cut with an ellipsis, as the official label built from `labelText` is. A
    // label that wraps is drawn across the field's top edge and over what was typed. The
    // required marker is a separate text so that a cut label keeps it.
    Widget? label;
    if (labelText != null) {
      final text = Text(
        labelText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      label = isRequired
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: text),
                Text(' *', style: TextStyle(color: colorScheme.error)),
              ],
            )
          : text;
    }

    Widget? finalPrefixIcon;
    if (prefixIcon != null) {
      finalPrefixIcon = Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.paddingMd,
          right: AppDimensions.paddingMd,
          bottom: iconLift,
        ),
        child: IconTheme(
          data: IconThemeData(
            size: AppDimensions.iconMd,
            color: colorScheme.onSurfaceVariant,
          ),
          child: prefixIcon,
        ),
      );
    }

    return InputDecoration(
      label: label,
      alignLabelWithHint: restingLines > 1,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: finalPrefixIcon,
      prefixText: prefixText,
      prefixStyle: inputStyle?.copyWith(color: colorScheme.onSurface),
    );
  }
}

/// Builds a field with its label: inside the field, or above it at large text.
///
/// The label inside a field is one line and is cut when it does not fit ("Installment
/// Amo…"). Above 1.3x text most labels do not fit, so there the label is a line of its own
/// above the field, where it can wrap, and [builder] is given no label to put inside.
class AppLabeledField extends StatelessWidget {
  final String labelText;
  final bool isRequired;
  final Widget Function(BuildContext context, String? labelText) builder;

  const AppLabeledField({
    super.key,
    required this.labelText,
    required this.builder,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppDimensions.isLargeText(context)) return builder(context, labelText);

    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.paddingXs,
            right: AppDimensions.paddingXs,
            bottom: AppDimensions.paddingSm,
          ),
          child: Text.rich(
            TextSpan(
              text: labelText,
              children: [
                if (isRequired)
                  TextSpan(text: ' *', style: TextStyle(color: scheme.error)),
              ],
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        builder(context, null),
      ],
    );
  }
}
