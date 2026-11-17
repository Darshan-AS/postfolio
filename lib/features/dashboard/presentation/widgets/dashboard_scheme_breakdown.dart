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
/// The strip carries the page margin itself. When every pill fits, they share the width
/// between the margins. When they do not, the strip scrolls sideways and the pills are
/// sized so that half of the next one shows at the window's edge: a pill that happened to
/// end on the edge looked cut off by it, and gave no sign that more follow.
class DashboardSchemeBreakdown extends StatelessWidget {
  final DashboardMetrics metrics;

  const DashboardSchemeBreakdown({super.key, required this.metrics});

  static const double _gap = AppDimensions.paddingSm;

  /// The share of the next pill left showing at the edge of a strip that scrolls.
  static const double _peek = 0.5;

  @override
  Widget build(BuildContext context) {
    final schemes = [
      for (final entry in metrics.activeOtdsByScheme.entries)
        if ((metrics.totalOtdsByScheme[entry.key] ?? 0) > 0)
          (
            scheme: entry.key,
            active: entry.value,
            total: metrics.totalOtdsByScheme[entry.key] ?? 0,
          ),
    ];
    if (schemes.isEmpty) return const SizedBox.shrink();

    // The width the widest pill needs: its fixed parts and its figure.
    var figureWidth = 0.0;
    for (final entry in schemes) {
      final painter = TextPainter(
        text: _SchemePill.figureSpan(context, entry.active, entry.total),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (painter.width > figureWidth) figureWidth = painter.width;
      painter.dispose();
    }
    final naturalWidth = _SchemePill.fixedWidth + figureWidth.ceilToDouble();

    final pills = [
      for (final entry in schemes)
        _SchemePill(scheme: entry.scheme, active: entry.active, total: entry.total),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = pills.length;
        final room = constraints.maxWidth - 2 * AppDimensions.pageMargin;

        if (count * naturalWidth + (count - 1) * _gap <= room) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageMargin),
            child: Row(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(child: pills[i]),
                ],
              ],
            ),
          );
        }

        // As many whole pills as fit beside the part of the next one.
        var width = naturalWidth;
        for (var whole = count - 1; whole >= 1; whole--) {
          final candidate =
              (constraints.maxWidth - AppDimensions.pageMargin - whole * _gap) /
              (whole + _peek);
          if (candidate >= naturalWidth) {
            width = candidate;
            break;
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageMargin),
          child: Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                SizedBox(width: width, child: pills[i]),
              ],
            ],
          ),
        );
      },
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

  static const double _leadingInset = AppDimensions.paddingSm;
  static const double _figureGap = AppDimensions.paddingMd;
  static const double _trailingInset = AppDimensions.paddingXl;

  /// Everything in a pill but its figure: the insets, the avatar and the gap after it.
  static const double fixedWidth =
      _leadingInset + AppDimensions.avatarMd + _figureGap + _trailingInset;

  /// `2 / 3`, the active count leading.
  static TextSpan figureSpan(BuildContext context, int active, int total) {
    final theme = Theme.of(context);
    return TextSpan(
      text: '$active',
      style: AppTypography.emphasizedOf(context).titleLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      children: [
        TextSpan(
          text: '${t.format.fractionSeparator}$total',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

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
          _leadingInset,
          AppDimensions.paddingSm,
          _trailingInset,
          AppDimensions.paddingSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppShapeAvatar(
              shape: scheme.avatarShape,
              size: AppDimensions.avatarMd,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingSm),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(scheme.shortName, style: emphasized.titleSmall),
                ),
              ),
            ),
            const SizedBox(width: _figureGap),
            Text.rich(figureSpan(context, active, total), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
