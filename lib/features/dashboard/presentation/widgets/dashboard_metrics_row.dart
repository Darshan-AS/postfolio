import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';

import 'package:postfolio/i18n/strings.g.dart';

class DashboardMetricsRow extends StatelessWidget {
  final DashboardMetrics metrics;

  const DashboardMetricsRow({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: t.dashboard.metrics.customers,
            active: metrics.activeCustomers,
            total: metrics.totalCustomers,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSm),
        Expanded(
          child: _MetricCard(
            title: t.dashboard.metrics.rds,
            active: metrics.activeRds,
            total: metrics.totalRds,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSm),
        Expanded(
          child: _MetricCard(
            title: t.dashboard.metrics.otds,
            active: metrics.activeOtds,
            total: metrics.totalOtds,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int active;
  final int total;

  const _MetricCard({
    required this.title,
    required this.active,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingLg,
          horizontal: AppDimensions.paddingMd,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            RichText(
              text: TextSpan(
                text: '$active',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '${t.format.fractionSeparator}$total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
