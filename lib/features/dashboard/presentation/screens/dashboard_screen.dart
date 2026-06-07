import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_metrics_row.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_scheme_breakdown.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_chart_section.dart';
import 'package:postfolio/i18n/strings.g.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsDataProvider);

    return Scaffold(
      appBar: ShellAppBar(
        title: t.nav.dashboard,
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              size: AppDimensions.iconMd,
            ),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: t.auth.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Providers watch streams from controllers, so pull-to-refresh
            // might just be a no-op, but it's good for UX.
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                // ROW 1: 3 Square Cards
                DashboardMetricsRow(metrics: metrics),
                const SizedBox(height: AppDimensions.paddingXl),

                Text(
                  t.dashboard.activeOtdsByScheme,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                // ROW 2: Pill shaped cards for scheme breakdown
                DashboardSchemeBreakdown(metrics: metrics),
                const SizedBox(height: AppDimensions.paddingXl),

                // ROW 3: Big Graph
                const DashboardChartSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
