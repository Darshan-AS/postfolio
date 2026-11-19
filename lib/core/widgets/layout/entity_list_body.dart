import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The body of an entity list screen for every state of its data: skeleton rows while
/// loading, an error with retry, an empty message (with "clear filters" when filters hide
/// everything), or the grouped, pull-to-refresh list.
///
/// The three list screens (customers, one-time deposits, recurring deposits) differ only in
/// their row widget, so the states live here once.
class EntityListBody<T> extends StatelessWidget {
  const EntityListBody({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.skeletonBuilder,
    required this.onRefresh,
    required this.onRetry,
    required this.emptyMessage,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  final AsyncValue<List<T>> state;

  /// Builds the row for [item]; pass [position] on to its grouped tile.
  final Widget Function(BuildContext context, T item, AppGroupPosition position)
  itemBuilder;

  /// Builds a placeholder row for the loading skeleton.
  final Widget Function(AppGroupPosition position) skeletonBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  /// Shown when there is no data at all.
  final String emptyMessage;

  /// True when a search or filter is narrowing the list, so an empty list means "no
  /// results" rather than "nothing yet".
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  static const int _skeletonRows = 5;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncData(:final value) => _data(value),
      AsyncError(:final error) => ErrorStateView(
        message: error.toString(),
        onRetry: onRetry,
      ),
      _ => Skeletonizer(
        enabled: true,
        child: AppGroupListView(
          itemCount: _skeletonRows,
          itemBuilder: (context, index, position) => skeletonBuilder(position),
        ),
      ),
    };
  }

  Widget _data(List<T> items) {
    if (items.isEmpty) {
      return hasActiveFilters
          ? EmptyStateView(
              icon: HugeIcons.strokeRoundedSearchRemove,
              message: t.common.noResults,
              actionLabel: t.common.clearFilters,
              actionIcon: HugeIcons.strokeRoundedFilterRemove,
              onAction: onClearFilters,
            )
          : EmptyStateView(message: emptyMessage);
    }
    return AppRefreshIndicator(
      onRefresh: onRefresh,
      child: AppGroupListView(
        itemCount: items.length,
        itemBuilder: (context, index, position) =>
            itemBuilder(context, items[index], position),
      ),
    );
  }
}
