import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

/// One choice in an [AppButtonGroup].
class AppSegment<T> {
  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final AppIconData? icon;
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
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  static const double _stackAboveTextScale = 1.3;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

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
        icon: item.icon != null ? AppIcon(item.icon!, size: _iconSize) : null,
        label: Text(
          item.label,
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
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: AppShapes.groupGap),
          Expanded(child: segment(i)),
        ],
      ],
    );
  }
}
