import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';

export 'package:postfolio/core/theme/app_shapes.dart' show AppGroupPosition;

/// One row of a grouped list: a tonal surface whose corners depend on where it sits in the
/// group, so a run of rows reads as one container with thin seams (the Material 3
/// Expressive list style), instead of flat rows split by divider lines.
///
/// While pressed, the row pulls all four corners in to the same radius; the `Material`
/// animates the shape change.
class AppGroupTile extends StatefulWidget {
  const AppGroupTile({
    super.key,
    required this.child,
    this.position = AppGroupPosition.single,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.color,
  });

  final Widget child;
  final AppGroupPosition position;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Tints the row with the selection colour.
  final bool selected;

  /// Overrides the resting surface colour.
  final Color? color;

  @override
  State<AppGroupTile> createState() => _AppGroupTileState();
}

class _AppGroupTileState extends State<AppGroupTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final shape = _pressed
        ? AppShapes.rounded(AppShapes.pressed)
        : AppShapes.group(widget.position);

    return Material(
      color: widget.selected
          ? scheme.secondaryContainer
          : widget.color ?? scheme.raised,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: interactive
          ? InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              child: widget.child,
            )
          : widget.child,
    );
  }
}

/// A column of [AppGroupTile]s separated by the group gap. For short, fixed lists; long
/// lists build [AppGroupTile]s lazily and add [AppShapes.groupGap] themselves.
class AppGroup extends StatelessWidget {
  const AppGroup({super.key, required this.children});

  /// The content of each row. Null and empty entries are not expected; filter first.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppShapes.groupGap),
          AppGroupTile(
            position: AppGroupPosition.at(i, children.length),
            child: children[i],
          ),
        ],
      ],
    );
  }
}

/// A lazily built list of grouped rows with the page margin on both sides.
///
/// [itemBuilder] receives the row's [AppGroupPosition] and returns the row, normally an
/// [AppGroupTile] or a widget that wraps one.
class AppGroupListView extends StatelessWidget {
  const AppGroupListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.bottomPadding = AppDimensions.listBottomPaddingFAB,
  });

  final int itemCount;
  final Widget Function(
    BuildContext context,
    int index,
    AppGroupPosition position,
  )
  itemBuilder;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pageMargin,
        0,
        AppDimensions.pageMargin,
        bottomPadding,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(
          bottom: index == itemCount - 1 ? 0 : AppShapes.groupGap,
        ),
        child: itemBuilder(
          context,
          index,
          AppGroupPosition.at(index, itemCount),
        ),
      ),
    );
  }
}
