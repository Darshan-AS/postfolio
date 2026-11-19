import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Month navigator for the Monthly Hub: `‹  Mar 2026 ▾  ›`, with a "Current month" button
/// only when the hub is looking at another month.
///
/// The month and that button share the space between the two arrows; when they do not fit
/// side by side (large text, narrow window) the button drops under the month instead of
/// squeezing it.
/// Purely declarative: the caller decides what "current month" means and how a picked
/// month is applied.
class RDMonthSwitcher extends StatelessWidget {
  final DateTime selectedMonth;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onResetToCurrent;
  final ValueChanged<DateTime> onPickMonth;

  /// How far the "jump to month" picker may travel from the selected month.
  static const int _pickerYearSpan = 10;

  /// On a wide window the switcher stays this wide and centred, so the arrows keep their
  /// place next to the month they step instead of drifting to the window's edges.
  static const double _maxWidth = AppDimensions.maxLoginWidth;

  const RDMonthSwitcher({
    super.key,
    required this.selectedMonth,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onResetToCurrent,
    required this.onPickMonth,
  });

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(selectedMonth.year - _pickerYearSpan),
      lastDate: DateTime(
        selectedMonth.year + _pickerYearSpan,
        DateTime.december,
        31,
      ),
      initialDatePickerMode: DatePickerMode.year,
      helpText: t.recurringDeposits.monthlyOperations.toolbar.pickMonth,
    );
    if (picked == null || !context.mounted) return;
    onPickMonth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ops = t.recurringDeposits.monthlyOperations;
    final monthLabel = DateFormat.yMMM(resolvedDateLocale()).format(selectedMonth);

    // The theme shrinks icon buttons to 40dp on desktop; these stay a full touch target.
    final stepStyle = IconButton.styleFrom(
      minimumSize: const Size.square(AppDimensions.actionButtonSize),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageMargin,
          ),
          child: Row(
            children: [
              IconButton.filledTonal(
                style: stepStyle,
                icon: const AppIcon(HugeIcons.strokeRoundedArrowLeft01),
                tooltip: ops.previousMonth,
                onPressed: onPrevious,
              ),
              Expanded(
                child: OverflowBar(
                  alignment: MainAxisAlignment.center,
                  overflowAlignment: OverflowBarAlignment.center,
                  spacing: AppDimensions.paddingXs,
                  children: [
                    _MonthTitle(
                      label: monthLabel,
                      tooltip: ops.toolbar.pickMonth,
                      onTap: () => _pickMonth(context),
                    ),
                    if (!isCurrentMonth)
                      AppButton.text(
                        label: ops.currentMonth,
                        onPressed: onResetToCurrent,
                      ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                style: stepStyle,
                icon: const AppIcon(HugeIcons.strokeRoundedArrowRight01),
                tooltip: ops.nextMonth,
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The month as a title that opens the month picker. The label shrinks rather than being
/// cut: a month that reads "Apr 20…" is no use.
class _MonthTitle extends StatelessWidget {
  const _MonthTitle({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        shape: AppShapes.pill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.actionButtonSize,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppTypography.emphasizedOf(context).titleLarge
                            ?.copyWith(color: scheme.onSurface),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  AppSpacings.gapXs,
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
