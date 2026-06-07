import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';
import 'package:postfolio/i18n/strings.g.dart';

class DashboardSchemeBreakdown extends StatelessWidget {
  final DashboardMetrics metrics;

  const DashboardSchemeBreakdown({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final schemes = metrics.activeOtdsByScheme.entries.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: schemes.map((entry) {
          final scheme = entry.key;
          final active = entry.value;
          final total = metrics.totalOtdsByScheme[scheme] ?? 0;

          if (total == 0) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.paddingSm),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withAlpha(120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                  vertical: AppDimensions.paddingSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scheme.shortName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMd),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Text(
                        '$active${t.format.fractionSeparator}$total',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
