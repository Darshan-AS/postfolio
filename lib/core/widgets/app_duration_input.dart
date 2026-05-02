import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AppDurationInput extends HookWidget {
  final bool isFixedTenure;
  final List<int> allowedTenuresInYears;
  final int selectedYears;
  final int selectedMonths;
  final void Function(int years, int months) onChanged;

  const AppDurationInput({
    super.key,
    required this.isFixedTenure,
    required this.allowedTenuresInYears,
    required this.selectedYears,
    required this.selectedMonths,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final yearsController = useTextEditingController(text: selectedYears.toString());
    final monthsController = useTextEditingController(text: selectedMonths.toString());

    // Sync controllers with external state if it changes
    useEffect(() {
      if (yearsController.text != selectedYears.toString()) {
        yearsController.text = selectedYears.toString();
      }
      if (monthsController.text != selectedMonths.toString()) {
        monthsController.text = selectedMonths.toString();
      }
      return null;
    }, [selectedYears, selectedMonths]);

    if (isFixedTenure) {
      final allowedYears = allowedTenuresInYears;

      // For schemes like MIS/NSC which only have a single valid tenure (e.g., 5 years)
      if (allowedYears.length == 1) {
        return AppTextField(
          controller: yearsController,
          labelText: t.common.duration.termYears,
          prefixIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCalendar01,
            size: AppDimensions.iconMd,
          ),
          readOnly: true,
          enabled: true,
        );
      }

      // For TD with multiple options (1, 2, 3, 5 years)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.paddingXs,
              bottom: AppDimensions.paddingSm,
            ),
            child: Text(
              t.common.duration.termYears,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          SegmentedButton<int>(
            segments: allowedYears.map((year) {
              return ButtonSegment<int>(
                value: year,
                label: Text(t.common.duration.yearAbbreviation(n: year)),
              );
            }).toList(),
            selected: {selectedYears},
            onSelectionChanged: (Set<int> newSelection) {
              onChanged(newSelection.first, 0);
            },
          ),
        ],
      );
    }

    // Custom Tenure (e.g., KVP)
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: yearsController,
            labelText: t.common.duration.termYears,
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              size: AppDimensions.iconMd,
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              onChanged(int.tryParse(val) ?? 0, selectedMonths);
            },
          ),
        ),
        AppSpacings.gapMd,
        Expanded(
          child: AppTextField(
            controller: monthsController,
            labelText: t.common.duration.termMonths,
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar02,
              size: AppDimensions.iconMd,
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              onChanged(selectedYears, int.tryParse(val) ?? 0);
            },
          ),
        ),
      ],
    );
  }
}
