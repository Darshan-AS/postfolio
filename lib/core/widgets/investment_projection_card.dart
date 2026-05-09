import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

class InvestmentProjectionCard extends StatelessWidget {
  final InvestmentProjection? projection;

  const InvestmentProjectionCard({super.key, this.projection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proj = projection;

    if (proj == null) {
      return const SizedBox.shrink();
    }

    final formatCurrency = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 0,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.projection.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapMd,
              _AnimatedStatRow(
                label: t.projection.totalInvested,
                value: proj.totalInvested,
                formatter: formatCurrency,
              ),
              AppSpacings.gapSm,
              _AnimatedStatRow(
                label: t.projection.totalInterestEarned,
                value: proj.totalInterestEarned,
                formatter: formatCurrency,
                valueStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
                prefix: '+ ',
              ),
              ...proj.map(
                wealthAccumulation: (w) =>
                    _buildWealthAccumulationDetails(context, w, formatCurrency),
                incomeGeneration: (i) =>
                    _buildIncomeGenerationDetails(context, i, formatCurrency),
              ),
              AppSpacings.gapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.projection.maturityDate,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    proj.maturityDate.toAppFormat(),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              ...proj.map(
                wealthAccumulation: (w) =>
                    _buildWealthAccumulationNote(context, w),
                incomeGeneration: (i) => _buildIncomeGenerationNote(context, i),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

List<Widget> _buildWealthAccumulationDetails(
  BuildContext context,
  WealthAccumulation w,
  NumberFormat formatter,
) {
  final theme = Theme.of(context);
  return [
    AppSpacings.gapMd,
    Divider(color: theme.colorScheme.outlineVariant),
    AppSpacings.gapMd,
    _AnimatedStatRow(
      label: t.projection.estimatedMaturity,
      value: w.maturityAmount,
      formatter: formatter,
      valueStyle: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
    ),
  ];
}

List<Widget> _buildIncomeGenerationDetails(
  BuildContext context,
  IncomeGeneration i,
  NumberFormat formatter,
) {
  final theme = Theme.of(context);
  return [
    AppSpacings.gapSm,
    _AnimatedStatRow(
      label: t.projection.payout(frequency: i.payoutFrequency.displayName),
      value: i.periodicPayoutAmount,
      formatter: formatter,
      valueStyle: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.secondary,
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0),
    AppSpacings.gapMd,
    Divider(color: theme.colorScheme.outlineVariant),
    AppSpacings.gapMd,
    _AnimatedStatRow(
      label: t.projection.totalReturn,
      value: i.totalInvested + i.totalInterestEarned,
      formatter: formatter,
      valueStyle: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
    ),
    AppSpacings.gapSm,
    _AnimatedStatRow(
      label: t.projection.estimatedMaturity,
      value: i.maturityAmount,
      formatter: formatter,
      valueStyle: theme.textTheme.titleMedium,
    ),
  ];
}

List<Widget> _buildWealthAccumulationNote(
  BuildContext context,
  WealthAccumulation w,
) {
  final theme = Theme.of(context);
  if (w.note == null) return [];

  return [
    AppSpacings.gapSm,
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t.projection.doublesIn, style: theme.textTheme.bodyMedium),
        Text(
          w.note!,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().fade(),
  ];
}

List<Widget> _buildIncomeGenerationNote(
  BuildContext context,
  IncomeGeneration i,
) {
  final theme = Theme.of(context);
  if (i.note == null) return [];

  return [
    AppSpacings.gapMd,
    Text(
      i.note!,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontStyle: FontStyle.italic,
      ),
    ).animate().fade(),
  ];
}

class _AnimatedStatRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat formatter;
  final TextStyle? valueStyle;
  final String prefix;

  const _AnimatedStatRow({
    required this.label,
    required this.value,
    required this.formatter,
    this.valueStyle,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return Text(
              '$prefix${formatter.format(val)}',
              style: valueStyle ?? Theme.of(context).textTheme.titleMedium,
            );
          },
        ),
      ],
    );
  }
}
