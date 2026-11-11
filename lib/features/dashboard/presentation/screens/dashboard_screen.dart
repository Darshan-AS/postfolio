import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_chart_section.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_metrics_row.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_scheme_breakdown.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsDataProvider);
    final isInitialLoading =
        (ref.watch(customersControllerProvider).isLoading &&
            !ref.watch(customersControllerProvider).hasValue) ||
        (ref.watch(oneTimeDepositsControllerProvider).isLoading &&
            !ref.watch(oneTimeDepositsControllerProvider).hasValue) ||
        (ref.watch(recurringDepositsControllerProvider).isLoading &&
            !ref.watch(recurringDepositsControllerProvider).hasValue);

    Future<void> refreshAll() async {
      ref.invalidate(customersControllerProvider);
      ref.invalidate(oneTimeDepositsControllerProvider);
      ref.invalidate(recurringDepositsControllerProvider);
      ref.invalidate(rdLedgerSummariesProvider);
      await Future.wait([
        ref.read(customersControllerProvider.future),
        ref.read(oneTimeDepositsControllerProvider.future),
        ref.read(recurringDepositsControllerProvider.future),
      ]);
    }

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
          onRefresh: refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Skeletonizer(
              enabled: isInitialLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.dashboard.overview,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  DashboardMetricsRow(metrics: metrics),
                  const SizedBox(height: AppDimensions.paddingXl),
                  Text(
                    t.dashboard.activeOtdsByScheme,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSm),
                  DashboardSchemeBreakdown(metrics: metrics),
                  const SizedBox(height: AppDimensions.paddingXl),
                  const DashboardChartSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
