import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
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
    final customersState = ref.watch(customersControllerProvider);
    final otdsState = ref.watch(oneTimeDepositsControllerProvider);
    final rdsState = ref.watch(recurringDepositsControllerProvider);

    final metrics = ref.watch(dashboardMetricsDataProvider);
    final isInitialLoading =
        (customersState.isLoading && !customersState.hasValue) ||
        (otdsState.isLoading && !otdsState.hasValue) ||
        (rdsState.isLoading && !rdsState.hasValue);

    final hasBlockingError =
        !isInitialLoading &&
        ((customersState.hasError && !customersState.hasValue) ||
            (otdsState.hasError && !otdsState.hasValue) ||
            (rdsState.hasError && !rdsState.hasValue));
    final firstError =
        customersState.error ?? otdsState.error ?? rdsState.error;

    final hasSchemes = metrics.totalOtdsByScheme.values.any((c) => c > 0);

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
        child: hasBlockingError
            ? ErrorStateView(
                message: firstError.toString(),
                onRetry: refreshAll,
              )
            : AppRefreshIndicator(
                onRefresh: refreshAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingLg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppDimensions.maxContentWidth,
                      ),
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
                                  if (isInitialLoading || hasSchemes) ...[
                                    AppSpacings.gapLg,
                                    DetailSectionTitle(
                                      t.dashboard.activeOtdsByScheme,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isInitialLoading || hasSchemes)
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
              ),
      ),
    );
  }
}
