import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Month navigator for the Monthly Hub. Purely declarative: the caller decides what
/// "current month" means and how a picked month is applied.
class RDMonthSwitcher extends StatelessWidget {
  final DateTime selectedMonth;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onResetToCurrent;
  final ValueChanged<DateTime> onPickMonth;

  /// How far the "jump to month" picker may travel from the selected month.
  static const int _pickerYearSpan = 10;

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
      lastDate: DateTime(selectedMonth.year + _pickerYearSpan, DateTime.december, 31),
      initialDatePickerMode: DatePickerMode.year,
      helpText: t.recurringDeposits.monthlyOperations.toolbar.pickMonth,
    );
    if (picked == null || !context.mounted) return;
    onPickMonth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSm,
            vertical: AppDimensions.paddingXs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: AppDimensions.iconSm,
                ),
                tooltip: ops.previousMonth,
                onPressed: onPrevious,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: ops.toolbar.pickMonth,
                      child: InkWell(
                        onTap: () => _pickMonth(context),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSm,
                            vertical: AppDimensions.paddingXxs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedMonth.toMonthYearFormat(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacings.gapXs,
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowDown01,
                                size: AppDimensions.iconXs,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isCurrentMonth) ...[
                      AppSpacings.gapXs,
                      InkWell(
                        onTap: onResetToCurrent,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSm,
                            vertical: AppDimensions.paddingXs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedRotateLeft01,
                                size: AppDimensions.iconXs,
                                color: theme.colorScheme.primary,
                              ),
                              AppSpacings.gapXs,
                              Text(
                                ops.currentMonth,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: AppDimensions.iconSm,
                ),
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
