import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';

/// The status of an installment month as a pill: the status icon and label on the status
/// colours of [visual].
///
/// A status whose container colour is the plain surface ("due today") carries an outline
/// colour in its [RDStatusVisual]; the pill draws it so the badge still has an edge.
class RDStatusPill extends StatelessWidget {
  const RDStatusPill({super.key, required this.visual});

  final RDStatusVisual visual;

  @override
  Widget build(BuildContext context) {
    final outline = visual.outline;

    return Material(
      color: visual.background,
      shape: outline == null
          ? AppShapes.pill
          : StadiumBorder(side: BorderSide(color: outline)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSm,
          vertical: AppDimensions.paddingXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              visual.icon,
              // The glyph is part of the label: it grows with the text beside it.
              size: MediaQuery.textScalerOf(
                context,
              ).scale(AppDimensions.iconXs),
              color: visual.foreground,
            ),
            AppSpacings.gapXs,
            Flexible(
              child: Text(
                visual.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.emphasizedOf(
                  context,
                ).labelSmall?.copyWith(color: visual.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
