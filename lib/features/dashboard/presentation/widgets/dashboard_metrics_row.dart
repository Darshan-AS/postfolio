import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';

import 'package:postfolio/i18n/strings.g.dart';

/// The overview tiles: customers, recurring deposits and one-time deposits, each showing
/// `active / total` with the active count as the hero figure.
///
/// Each tile has its own container colour family (primary, secondary, tertiary) so the three
/// read apart.
///
/// The arrangement follows the room each `active / total` pair needs on one line:
/// three tiles in a row on a wide window, a tall customers tile beside the two deposit tiles
/// on a phone, and one tile per row when large text leaves no room for two.
class DashboardMetricsRow extends StatelessWidget {
  final DashboardMetrics metrics;

  const DashboardMetricsRow({super.key, required this.metrics});

  /// Width a tile needs at the default text size to show a pair such as `757 / 757` on one
  /// line. It grows with the text scale.
  static const double _minTileWidth = 136;

  static const double _gap = AppDimensions.paddingSm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tileWidth = _minTileWidth * MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsThree = constraints.maxWidth >= tileWidth * 3 + _gap * 2;
        final fitsTwo = constraints.maxWidth >= tileWidth * 2 + _gap;

        final customers = _MetricTile(
          title: t.dashboard.metrics.customers,
          icon: HugeIcons.strokeRoundedUserMultiple,
          active: metrics.activeCustomers,
          total: metrics.totalCustomers,
          color: scheme.primaryContainer,
          onColor: scheme.onPrimaryContainer,
          accentColor: scheme.primary,
          onAccentColor: scheme.onPrimary,
          isHero: fitsTwo && !fitsThree,
        );
        final rds = _MetricTile(
          title: t.dashboard.metrics.rds,
          icon: HugeIcons.strokeRoundedTransaction,
          active: metrics.activeRds,
          total: metrics.totalRds,
          color: scheme.secondaryContainer,
          onColor: scheme.onSecondaryContainer,
          accentColor: scheme.secondary,
          onAccentColor: scheme.onSecondary,
        );
        final otds = _MetricTile(
          title: t.dashboard.metrics.otds,
          icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
          active: metrics.activeOtds,
          total: metrics.totalOtds,
          color: scheme.tertiaryContainer,
          onColor: scheme.onTertiaryContainer,
          accentColor: scheme.tertiary,
          onAccentColor: scheme.onTertiary,
        );

        if (fitsThree) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: customers),
                const SizedBox(width: _gap),
                Expanded(child: rds),
                const SizedBox(width: _gap),
                Expanded(child: otds),
              ],
            ),
          );
        }

        if (fitsTwo) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: customers),
                const SizedBox(width: _gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: rds),
                      const SizedBox(height: _gap),
                      Expanded(child: otds),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            customers,
            const SizedBox(height: _gap),
            rds,
            const SizedBox(height: _gap),
            otds,
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final AppIconData icon;
  final int active;
  final int total;
  final Color color;
  final Color onColor;

  /// Colours of the shape badge on the hero tile.
  final Color accentColor;
  final Color onAccentColor;

  /// The tall tile of the phone layout: a shape badge on top and a larger figure.
  final bool isHero;

  const _MetricTile({
    required this.title,
    required this.icon,
    required this.active,
    required this.total,
    required this.color,
    required this.onColor,
    required this.accentColor,
    required this.onAccentColor,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final emphasized = AppTypography.emphasizedOf(context);

    final label = Text(
      title,
      style: emphasized.titleSmall?.copyWith(color: onColor),
    );

    // One line, whatever the counts: shrink rather than wrap between the two numbers.
    final figure = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        TextSpan(
          text: '$active',
          style: (isHero ? emphasized.displayMedium : emphasized.headlineLarge)
              ?.copyWith(color: onColor),
          children: [
            TextSpan(
              text: '${t.format.fractionSeparator}$total',
              style: textTheme.titleMedium?.copyWith(color: onColor),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );

    final Widget content;
    if (isHero) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppShapeAvatar(
            shape: AppAvatarShape.cookie9,
            backgroundColor: accentColor,
            foregroundColor: onAccentColor,
            child: AppIcon(icon, size: AppDimensions.iconMd),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [label, figure],
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: label),
              AppSpacings.gapSm,
              AppIcon(icon, size: AppDimensions.iconMd, color: onColor),
            ],
          ),
          AppSpacings.gapXs,
          figure,
        ],
      );
    }

    return Material(
      color: color,
      shape: AppShapes.rounded(AppShapes.extraLarge),
      child: Padding(
        // The tall tile pins its badge to one corner and its figure to another, so its
        // inset is the same on every side. The short tiles centre their content.
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: isHero ? AppDimensions.paddingLg : AppDimensions.paddingMd,
        ),
        child: content,
      ),
    );
  }
}
