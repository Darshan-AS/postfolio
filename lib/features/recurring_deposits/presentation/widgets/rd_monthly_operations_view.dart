import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_batch_bar.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_header.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_list.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_toolbar.dart';

/// Monthly Hub shell. Composition only — each zone is its own consumer so a search
/// keystroke rebuilds the toolbar + list and nothing else.
///
/// * Zone 1 — [RDHubHeader]: scrolls away (month switcher, KPIs, banners).
/// * Zone 2 — [RDHubToolbar]: pinned (search, due window, group/select toggles).
/// * Zone 3 — [RDHubList]: the rows.
/// * Overlay — [RDHubBatchBar]: shown while rows are selected.
class RDMonthlyOperationsView extends HookConsumerWidget {
  const RDMonthlyOperationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(
      rDHubSelectionProvider.select((s) => s.isSelectionMode && s.count > 0),
    );

    // First run after migration: build summaries for RDs that have none yet.
    useEffect(() {
      Future.microtask(
        () => ref.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries(),
      );
      return null;
    }, const []);

    Future<void> onRefresh() async {
      await ref.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries(rebuildAll: true);
      ref.invalidate(monthlyOperationItemsProvider);
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: const CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: RDHubHeader()),
              PinnedHeaderSliver(child: RDHubToolbar()),
              RDHubList(),
            ],
          ),
        ),
        if (hasSelection)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RDHubBatchBar(),
          ),
      ],
    );
  }
}
