import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
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
      ref.invalidate(isAdminProvider);
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

    // Sections carry the page margin themselves, so the scheme strip can scroll edge to edge.
    const pageInsets = EdgeInsets.symmetric(
      horizontal: AppDimensions.pageMargin,
    );

    return Scaffold(
      appBar: ShellAppBar(title: t.nav.dashboard),
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingLg),
            child: Skeletonizer(
              enabled: isInitialLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: pageInsets,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DetailSectionTitle(t.dashboard.overview),
                        DashboardMetricsRow(metrics: metrics),
                        AppSpacings.gapLg,
                        DetailSectionTitle(t.dashboard.activeOtdsByScheme),
                      ],
                    ),
                  ),
                  DashboardSchemeBreakdown(metrics: metrics),
                  AppSpacings.gapXl,
                  const Padding(
                    padding: pageInsets,
                    child: DashboardChartSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
