import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_header.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_list.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_toolbar.dart';

/// Monthly Hub shell. Composition only — each zone is its own consumer so a search
/// keystroke rebuilds the toolbar + list and nothing else.
///
/// * Zone 1 — [RDHubHeader]: scrolls away (month switcher, progress, KPI filter tiles).
/// * Zone 2 — [RDHubToolbar]: pinned (search, sort toggle, due window).
/// * Zone 3 — [RDHubList]: the rows.
class RDMonthlyOperationsView extends HookConsumerWidget {
  const RDMonthlyOperationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First run after migration: build summaries for RDs that have none yet.
    useEffect(() {
      Future.microtask(
        () => ref
            .read(rDMonthlyOperationsActionsProvider.notifier)
            .ensureSummaries(),
      );
      return null;
    }, const []);

    Future<void> onRefresh() async {
      await ref
          .read(rDMonthlyOperationsActionsProvider.notifier)
          .ensureSummaries(rebuildAll: true);
      ref.invalidate(monthlyOperationItemsProvider);
    }

    return AppRefreshIndicator(
      onRefresh: onRefresh,
      child: const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: RDHubHeader()),
          PinnedHeaderSliver(child: RDHubToolbar()),
          RDHubList(),
        ],
      ),
    );
  }
}
