import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

/// One choice in an [AppButtonGroup]: a [label], an [icon], or both.
///
/// An icon-only segment must say what it is through [tooltip]; as with the official
/// `IconButton`, the tooltip is the name a screen reader announces for it.
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

/// A connected Material 3 Expressive button group for picking among a few options: exactly
/// one with the default constructor, any number with [AppButtonGroup.multi].
///
/// It replaces `SegmentedButton`: segments share the width, sit 2dp apart with small inner
/// corners, and a selected one becomes a filled pill.
///
/// It is built from the community package's toggle buttons rather than its `M3EButtonGroup`.
/// That widget keeps an invisible copy of every label in the tree to measure it, so
/// `find.text` matches each label more than once; it also clips labels that do not fit
/// instead of wrapping. Here the labels exist once, and above [_stackAboveTextScale] the
/// segments stack vertically so every label has the full width.
class AppButtonGroup<T> extends StatelessWidget {
  /// One option is always selected. Tapping it again reports nothing; tapping another
  /// reports that one through [onChanged].
  const AppButtonGroup({
    super.key,
    required this.segments,
    required T selected,
    required ValueChanged<T> onChanged,
    this.enabled = true,
    this.expand = true,
  }) : _selected = selected,
       _selectedValues = null,
       _onPressed = onChanged;

  /// Any number of options are selected, none included. Every tap reports its value
  /// through [onToggled], for the caller to add or remove.
  const AppButtonGroup.multi({
    super.key,
    required this.segments,
    required Set<T> selected,
    required ValueChanged<T> onToggled,
    this.enabled = true,
    this.expand = true,
  }) : _selected = null,
       _selectedValues = selected,
       _onPressed = onToggled;

  final List<AppSegment<T>> segments;
  final bool enabled;

  /// The selected value of a single-select group.
  final T? _selected;

  /// The selected values of a multi-select group; null in a single-select one.
  final Set<T>? _selectedValues;
  final ValueChanged<T> _onPressed;

  /// Share the available width between the segments. Set to false where the group must hug
  /// its content, such as in an app bar.
  final bool expand;

  static const double _stackAboveTextScale = AppDimensions.largeTextScale;
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
      final selectedValues = _selectedValues;
      final isSelected = selectedValues != null
          ? selectedValues.contains(item.value)
          : item.value == _selected;
      final button = M3EButton(
        onPressed: enabled && item.enabled
            ? () {
                // A single-select group always has a choice, so its selected segment
                // does nothing; in a multi-select group the same tap deselects.
                if (selectedValues != null || !isSelected) _onPressed(item.value);
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
        // As in AppButton: a label that does not fit shrinks, it is never cut.
        label: item.label == null
            ? null
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(item.label!, maxLines: 1, softWrap: false),
              ),
      );
      // The community button reports "selected" on one semantics node and the button on a
      // child node; merged, a screen reader gets one node with the name, the role and the
      // state. The tooltip is the official one: it joins that node (it is the name of an
      // icon-only segment, as with the official `IconButton`) and `find.byTooltip` finds it.
      return MergeSemantics(
        child: item.tooltip == null
            ? button
            : Tooltip(message: item.tooltip, child: button),
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
