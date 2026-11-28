import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';

// Layout pieces shared by the Recurring Deposit ledger sheets (collect / edit payment,
// deposit, Post Office visit), so the three read as one family. Presentation only: every
// piece takes plain values and callbacks.

/// How far text scaling may enlarge the large type of these sheets. The same cap the
/// navigation labels use.
const double _largeTypeMaxScale = AppDimensions.largeTextScale;

/// [style], sized so that the ambient text scaling enlarges it to at most
/// [_largeTypeMaxScale] times its design size.
///
/// For the large type of these sheets (title, amount field). It is readable as designed,
/// and at 2.0x text an uncapped headline pushes an amount out of its field and the
/// customer's name out of the title. Body text is not capped.
TextStyle? rdSheetLargeType(BuildContext context, TextStyle? style) {
  final size = style?.fontSize;
  if (style == null || size == null) return style;
  final scaled = MediaQuery.textScalerOf(context).scale(size);
  final cap = size * _largeTypeMaxScale;
  return scaled <= cap ? style : style.copyWith(fontSize: size * cap / scaled);
}

/// Title and close button of a ledger sheet.
///
/// The shared `AppSheetHeader` is not used here because it differs in behaviour, not only in
/// looks: it keeps the title on one line and closes with `Navigator.pop`. These titles carry
/// the customer and serial number, so they may wrap, and closing goes through [onClose]
/// (`maybePop`) so a sheet's unsaved-input guard still runs.
class RDSheetHeader extends StatelessWidget {
  const RDSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.subtitle,
  });

  final String title;

  /// Which account the sheet is about, under the title. In the title it wrapped with the
  /// serial alone on the last line.
  final String? subtitle;
  final VoidCallback onClose;

  static const int _titleMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pageMargin,
        // A bottom sheet's drag handle already sets the title off from the top edge; the
        // dialog these sheets become on wide windows has no handle.
        AppAdaptiveSheet.isCompact(context)
            ? AppDimensions.paddingNone
            : AppDimensions.paddingLg,
        AppDimensions.paddingSm,
        AppDimensions.paddingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: rdSheetLargeType(
                      context,
                      AppTypography.emphasizedOf(context).titleLarge,
                    ),
                    maxLines: _titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacings.gapSm,
          IconButton(
            tooltip: t.common.close,
            icon: const AppIcon(
              HugeIcons.strokeRoundedCancel01,
              size: AppDimensions.iconMd,
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// The pinned bottom of a ledger sheet: an optional summary and the primary action.
///
/// Keeps the action clear of the system navigation area on phones. On wide windows the
/// content is a centred dialog, which does not reach that area.
class RDSheetFooter extends StatelessWidget {
  const RDSheetFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: AppAdaptiveSheet.isCompact(context),
      minimum: const EdgeInsets.fromLTRB(
        AppDimensions.pageMargin,
        AppDimensions.paddingSm,
        AppDimensions.pageMargin,
        AppDimensions.paddingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// The primary action of a ledger sheet: filled, full width, 56dp.
class RDSheetPrimaryAction extends StatelessWidget {
  const RDSheetPrimaryAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final AppIconData icon;

  /// Null disables the action.
  final VoidCallback? onPressed;

  /// True while the write is in flight.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: icon,
      size: AppButtonSize.medium,
      expand: true,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

/// A tonal block inside a ledger sheet for a derived result: the allocation preview, the
/// counter quote, the visit totals. With [color], a warning or failure notice.
class RDSheetBlock extends StatelessWidget {
  const RDSheetBlock({super.key, required this.child, this.color});

  final Widget child;

  /// Overrides the nested tone ([AppSurfaceRoles.inset]), e.g. with a financial status
  /// container colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? Theme.of(context).colorScheme.inset,
        shape: AppShapes.rounded(AppShapes.groupOuter),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: child,
      ),
    );
  }
}

/// The caption above a control or group in a ledger sheet, with an optional leading [icon].
class RDSheetSectionLabel extends StatelessWidget {
  const RDSheetSectionLabel(this.text, {super.key, this.icon});

  final String text;
  final AppIconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final label = Text(
      text,
      style: AppTypography.emphasizedOf(
        context,
      ).titleSmall?.copyWith(color: color),
    );
    if (icon == null) return label;
    return Row(
      children: [
        AppIcon(icon!, size: AppDimensions.iconSm, color: color),
        AppSpacings.gapSm,
        Expanded(child: label),
      ],
    );
  }
}

/// One line that carries a money figure. It is never wrapped or ellipsized: a line wider
/// than its space is scaled down to fit.
///
/// With [figure] (the formatted amount as it appears inside [text]), that part is drawn in
/// [figureStyle] and the words around it in [style], so the amount stands out without the
/// sentence being split into separately translated pieces.
class RDSheetFigure extends StatelessWidget {
  const RDSheetFigure(
    this.text, {
    super.key,
    this.style,
    this.figure,
    this.figureStyle,
  });

  final String text;
  final TextStyle? style;
  final String? figure;
  final TextStyle? figureStyle;

  @override
  Widget build(BuildContext context) {
    final part = figure;
    final at = (part == null || part.isEmpty) ? -1 : text.indexOf(part);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: at < 0
          ? Text(text, style: style, maxLines: 1, softWrap: false)
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: text.substring(0, at)),
                  TextSpan(text: part, style: figureStyle),
                  TextSpan(text: text.substring(at + part!.length)),
                ],
              ),
              style: style,
              maxLines: 1,
              softWrap: false,
            ),
    );
  }
}

/// A grouped row that opens a picker and shows the picked value in its [label] (the
/// payment, deposit or visit date).
///
/// It is a row rather than a button because the label carries the value: a button keeps its
/// label on one line and shrinks it at large text sizes, while this wraps at full size.
class RDSheetPickerTile extends StatelessWidget {
  const RDSheetPickerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.position = AppGroupPosition.single,
  });

  final AppIconData icon;
  final String label;

  /// Null disables the row.
  final VoidCallback? onTap;
  final AppGroupPosition position;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: AppGroupTile(
        position: position,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : AppDimensions.opacityDisabled,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.buttonHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
                vertical: AppDimensions.paddingMd,
              ),
              child: Row(
                children: [
                  AppIcon(icon, color: scheme.onSurfaceVariant),
                  AppSpacings.gapMd,
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.emphasizedOf(context).bodyLarge,
                    ),
                  ),
                  AppSpacings.gapSm,
                  AppIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    size: AppDimensions.iconSm,
                    color: scheme.onSurfaceVariant,
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
