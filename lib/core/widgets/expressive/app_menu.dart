import 'dart:math' as math;

import 'package:material_3_expressive/components/menus/m3e_menus.dart';
import 'package:material_3_expressive/foundations/theme/m3e_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

/// One entry of an [AppMenu].
class AppMenuEntry {
  const AppMenuEntry({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.selected,
  });

  final String label;

  /// Null disables the entry.
  final VoidCallback? onPressed;

  /// Shown before the label; a `HugeIcon`. It takes the entry's colour unless it sets one.
  final Widget? icon;

  /// Draws the entry in the error colour.
  final bool isDestructive;

  /// For a menu that picks one of its entries: whether this is the current one, which is
  /// drawn in the selected colours and ends with a tick. Null for an entry that is an action.
  final bool? selected;
}

/// A Material 3 Expressive menu: a rounded surface that springs open from its anchor.
///
/// [anchorBuilder] builds the control that opens it and is handed the callback to do so.
/// The menu closes on a choice, on a tap outside, and on back, which closes the menu and
/// leaves the screen where it is.
///
/// The community menu takes its width from its anchor (an icon button gives 224dp) and cuts
/// a label that does not fit. Here the menu is as wide as its longest label needs, up to the
/// window's width, so a label is cut only when it is wider than the screen.
class AppMenu extends StatefulWidget {
  const AppMenu({super.key, required this.entries, required this.anchorBuilder});

  final List<AppMenuEntry> entries;
  final Widget Function(BuildContext context, VoidCallback open) anchorBuilder;

  @override
  State<AppMenu> createState() => _AppMenuState();
}

class _AppMenuState extends State<AppMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _isOpen = false;

  /// The largest icon an entry carries; the community menu sizes its own at 20dp, but a
  /// `HugeIcon` with a size of its own keeps it.
  static const double _iconRoom = AppDimensions.iconMd;

  /// The least the menu keeps from the window's edges.
  static const double _edgeGap = AppDimensions.paddingSm;

  /// Each entry is the community menu's free-form item with the label and icon laid out
  /// here. Its ready-made entry names itself to a screen reader and leaves its text in the
  /// tree as well, so the label is read twice.
  List<M3EMenuNode> get _nodes => [
    for (final entry in widget.entries)
      M3EMenuWidget(
        semanticLabel: entry.label,
        value: entry.label,
        enabled: entry.onPressed != null,
        selected: entry.selected ?? false,
        onPressed: entry.onPressed,
        child: ExcludeSemantics(child: _EntryBody(entry)),
      ),
  ];

  /// The width the longest entry needs: its label on one line, its icon, and the menu's
  /// own insets.
  double _widthFor(BuildContext context, M3EMenuTheme theme) {
    final style = M3ETheme.of(context).typeScale.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final entry in widget.entries) {
      final painter = TextPainter(
        text: TextSpan(text: entry.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final icon = entry.icon == null ? 0.0 : _iconRoom + theme.iconGap;
      // The current entry of a menu that picks one ends with a tick.
      final tick = entry.selected == null ? 0.0 : theme.iconSize + theme.iconGap;
      widest = math.max(widest, painter.width + icon + tick);
      painter.dispose();
    }
    // The menu pads its surface by twice its elevation on every side, for the shadow.
    final insets =
        2 *
        (theme.stateLayerInset +
            theme.entryHorizontalPadding +
            theme.contentHorizontalPadding +
            2 * theme.elevation);
    // One more pixel: a width that equals the text's exactly can still round to a cut.
    return (widest + insets).ceilToDouble() + 1;
  }

  Future<void> _open() async {
    final anchorContext = _anchorKey.currentContext;
    final anchor = anchorContext == null ? null : m3eOverlayRectFor(anchorContext);
    if (_isOpen || anchor == null) return;

    final theme = M3ETheme.of(context).menuTheme.metricsFor(M3EMenuVariant.vertical);
    final room = MediaQuery.sizeOf(context).width - 2 * _edgeGap;
    final width = math.max(theme.minWidth, math.min(_widthFor(context, theme), room));

    setState(() => _isOpen = true);
    await showM3EMenu<Object>(
      context: context,
      anchor: anchor,
      children: _nodes,
      readChildren: () => _nodes,
      preferredWidth: width,
      themeOverride: theme.copyWith(
        maxWidth: width,
        screenEdgePadding: _edgeGap,
      ),
    );
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    // The open menu is an entry in its route's local history, which closes it on back. That
    // alone does not tell Android the app will take the gesture, so from a tab's own screen
    // the system took it and left the app. A route that cannot pop does tell it.
    return PopScope(
      canPop: !_isOpen,
      onPopInvokedWithResult: (didPop, _) {
        // `pop` takes the route's newest local history entry, which is the menu, and the
        // route stays. Checked first: without an entry it would pop the screen.
        if (didPop || !(ModalRoute.of(context)?.willHandlePopInternally ?? false)) return;
        Navigator.of(context).pop();
      },
      child: KeyedSubtree(key: _anchorKey, child: widget.anchorBuilder(context, _open)),
    );
  }
}

/// The icon and label of one entry, in the error colour for a destructive one.
class _EntryBody extends StatelessWidget {
  const _EntryBody(this.entry);

  final AppMenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final gap = M3ETheme.of(context).menuTheme.iconGap;
    final icon = entry.icon;

    Widget body = Row(
      children: [
        if (icon != null) ...[icon, SizedBox(width: gap)],
        Flexible(
          child: Text(entry.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    // A disabled entry keeps the menu's own faded colour.
    if (entry.isDestructive && entry.onPressed != null) {
      final error = Theme.of(context).colorScheme.error;
      body = IconTheme.merge(
        data: IconThemeData(color: error),
        child: DefaultTextStyle.merge(style: TextStyle(color: error), child: body),
      );
    }
    return body;
  }
}
