import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

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

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: AppDimensions.paddingXl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
            ),
            AppSpacings.gapSm,
            _AnimatedStatRow(
              label: t.projection.totalInterestEarned,
              value: proj.totalInterestEarned,
              valueStyle: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
              prefix: '+ ',
            ),
            ...switch (proj) {
              WealthAccumulation w => _buildWealthAccumulationDetails(
                context,
                w,
              ),
              IncomeGeneration i => _buildIncomeGenerationDetails(context, i),
            },
            AppSpacings.gapSm,
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.projection.maturityDate,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                AppSpacings.gapSm,
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      proj.maturityDate.toAppFormat(),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            ...switch (proj) {
              WealthAccumulation w => _buildWealthAccumulationNote(
                context,
                w,
              ),
              IncomeGeneration i => _buildIncomeGenerationNote(context, i),
            },
          ],
        ),
      ),
    );

    return disableAnimations
        ? card
        : card.animate().fade(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

List<Widget> _buildWealthAccumulationDetails(
  BuildContext context,
  WealthAccumulation w,
) {
  final theme = Theme.of(context);
  return [
    AppSpacings.gapMd,
    Divider(color: theme.colorScheme.outlineVariant),
    AppSpacings.gapMd,
    _AnimatedStatRow(
      label: t.projection.estimatedMaturity,
      value: w.maturityAmount,
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
) {
  final theme = Theme.of(context);
  final disableAnimations = MediaQuery.disableAnimationsOf(context);
  final payoutRow = _AnimatedStatRow(
    label: t.projection.payout(frequency: i.payoutFrequency.displayName),
    value: i.periodicPayoutAmount,
    valueStyle: theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.secondary,
    ),
  );

  return [
    AppSpacings.gapSm,
    disableAnimations
        ? payoutRow
        : payoutRow.animate().fade().slideY(begin: 0.1, end: 0),
    AppSpacings.gapMd,
    Divider(color: theme.colorScheme.outlineVariant),
    AppSpacings.gapMd,
    _AnimatedStatRow(
      label: t.projection.totalReturn,
      value: i.totalInvested + i.totalInterestEarned,
      valueStyle: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
    ),
    AppSpacings.gapSm,
    _AnimatedStatRow(
      label: t.projection.estimatedMaturity,
      value: i.maturityAmount,
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
  final disableAnimations = MediaQuery.disableAnimationsOf(context);

  final row = Row(
    children: [
      Expanded(
        child: Text(t.projection.doublesIn, style: theme.textTheme.bodyMedium),
      ),
      AppSpacings.gapSm,
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            w.note!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );

  return [
    AppSpacings.gapSm,
    disableAnimations ? row : row.animate().fade(),
  ];
}

List<Widget> _buildIncomeGenerationNote(
  BuildContext context,
  IncomeGeneration i,
) {
  final theme = Theme.of(context);
  if (i.note == null) return [];
  final disableAnimations = MediaQuery.disableAnimationsOf(context);

  final text = Text(
    i.note!,
    style: theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      fontStyle: FontStyle.italic,
    ),
  );

  return [
    AppSpacings.gapMd,
    disableAnimations ? text : text.animate().fade(),
  ];
}

class _AnimatedStatRow extends StatelessWidget {
  final String label;
  final double value;
  final TextStyle? valueStyle;
  final String prefix;

  const _AnimatedStatRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final effectiveStyle = valueStyle ?? Theme.of(context).textTheme.titleMedium;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        AppSpacings.gapSm,
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: disableAnimations
                ? Text('$prefix${value.toRupeeFormat()}', style: effectiveStyle)
                : TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: value),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Text(
                        '$prefix${val.toRupeeFormat()}',
                        style: effectiveStyle,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
