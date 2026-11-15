import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// A strip of pills, one per one-time scheme that has deposits: the scheme's avatar (the same
/// shape and code as in the deposit list) and its `active / total` count.
///
/// The strip scrolls sideways and carries the page margin itself, so pills run to the window
/// edge instead of being cut off at the margin.
class DashboardSchemeBreakdown extends StatelessWidget {
  final DashboardMetrics metrics;

  const DashboardSchemeBreakdown({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final schemes = [
      for (final entry in metrics.activeOtdsByScheme.entries)
        if ((metrics.totalOtdsByScheme[entry.key] ?? 0) > 0) entry,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageMargin),
      child: Row(
        children: [
          for (var i = 0; i < schemes.length; i++) ...[
            if (i > 0) AppSpacings.gapSm,
            _SchemePill(
              scheme: schemes[i].key,
              active: schemes[i].value,
              total: metrics.totalOtdsByScheme[schemes[i].key] ?? 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _SchemePill extends StatelessWidget {
  final OneTimeSchemeType scheme;
  final int active;
  final int total;

  const _SchemePill({
    required this.scheme,
    required this.active,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);

    return Material(
      color: colors.raised,
      shape: AppShapes.pill,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDimensions.paddingSm,
          AppDimensions.paddingSm,
          AppDimensions.paddingXl,
          AppDimensions.paddingSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppShapeAvatar(
              shape: scheme.avatarShape,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingSm),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(scheme.shortName, style: emphasized.titleSmall),
                ),
              ),
            ),
            AppSpacings.gapMd,
            Text.rich(
              TextSpan(
                text: '$active',
                style: emphasized.titleLarge?.copyWith(color: colors.onSurface),
                children: [
                  TextSpan(
                    text: '${t.format.fractionSeparator}$total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
