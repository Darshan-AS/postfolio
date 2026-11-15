import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

/// One choice in an [AppButtonGroup]: a [label], an [icon], or both.
///
/// An icon-only segment must say what it is through [tooltip], which is also its
/// accessibility label.
class AppSegment<T> {
  const AppSegment({
    required this.value,
    this.label,
    this.icon,
    this.tooltip,
    this.enabled = true,
  }) : assert(label != null || (icon != null && tooltip != null));

  final T value;
  final String? label;
  final AppIconData? icon;
  final String? tooltip;
  final bool enabled;
}

/// A connected Material 3 Expressive button group for picking exactly one of a few options.
///
/// It replaces `SegmentedButton`: segments share the width, sit 2dp apart with small inner
/// corners, and the selected one becomes a filled pill.
///
/// It is built from the community package's toggle buttons rather than its `M3EButtonGroup`.
/// That widget keeps an invisible copy of every label in the tree to measure it, so
/// `find.text` matches each label more than once; it also clips labels that do not fit
/// instead of wrapping. Here the labels exist once, and above [_stackAboveTextScale] the
/// segments stack vertically so every label has the full width.
class AppButtonGroup<T> extends StatelessWidget {
  const AppButtonGroup({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.expand = true,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  /// Share the available width between the segments. Set to false where the group must hug
  /// its content, such as in an app bar.
  final bool expand;

  static const double _stackAboveTextScale = 1.3;
  static const double _iconSize = 20;

  /// Width share of a segment: its label length plus a constant for padding and icon.
  ///
  /// Equal shares would ellipsize "Transactions" next to "Info" on a phone. Sharing the row
  /// by label length keeps short and long labels readable; equal-length labels still get
  /// equal widths.
  static int _flexFor(AppSegment<Object?> segment) =>
      (segment.label?.length ?? 0) + (segment.icon != null ? 3 : 0) + 4;

  @override
  Widget build(BuildContext context) {
    final hasLabels = segments.any((s) => s.label != null);
    // Stacking exists to give labels room; icon-only and content-hugging groups stay in a row.
    final stacked =
        hasLabels &&
        expand &&
        MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

    Widget segment(int index) {
      final item = segments[index];
      final isSelected = item.value == selected;
      return M3EButton(
        onPressed: enabled && item.enabled
            ? () {
                if (!isSelected) onChanged(item.value);
              }
            : null,
        isSelected: isSelected,
        // Tonal: unselected segments keep a visible container on every surface the group
        // sits on (page, card, sheet); the plain filled style leaves them transparent.
        style: M3EButtonStyle.tonal,
        size: M3EButtonSize.sm,
        isGroupConnected: !stacked,
        isFirstInGroup: index == 0,
        isLastInGroup: index == segments.length - 1,
        tooltip: item.tooltip,
        semanticLabel: item.label == null ? item.tooltip : null,
        icon: item.icon != null ? AppIcon(item.icon!, size: _iconSize) : null,
        label: item.label == null
            ? null
            : Text(
                item.label!,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
      );
    }

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < segments.length; i++) segment(i)],
      );
    }

    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: AppShapes.groupGap),
          expand
              ? Expanded(flex: _flexFor(segments[i]), child: segment(i))
              : segment(i),
        ],
      ],
    );
  }
}
