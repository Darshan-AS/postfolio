import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AppDurationInput extends StatefulWidget {
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
  State<AppDurationInput> createState() => _AppDurationInputState();
}

class _AppDurationInputState extends State<AppDurationInput> {
  late final TextEditingController _yearsController;
  late final TextEditingController _monthsController;

  @override
  void initState() {
    super.initState();
    _yearsController = TextEditingController(text: widget.selectedYears.toString());
    _monthsController = TextEditingController(text: widget.selectedMonths.toString());
  }

  @override
  void didUpdateWidget(covariant AppDurationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYears != widget.selectedYears && _yearsController.text != widget.selectedYears.toString()) {
      _yearsController.text = widget.selectedYears.toString();
    }
    if (oldWidget.selectedMonths != widget.selectedMonths && _monthsController.text != widget.selectedMonths.toString()) {
      _monthsController.text = widget.selectedMonths.toString();
    }
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFixedTenure) {
      final allowedYears = widget.allowedTenuresInYears;

      // For schemes like MIS/NSC which only have a single valid tenure (e.g., 5 years)
      if (allowedYears.length == 1) {
        return AppTextField(
          controller: _yearsController,
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
            selected: {widget.selectedYears},
            onSelectionChanged: (Set<int> newSelection) {
              widget.onChanged(newSelection.first, 0);
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
            controller: _yearsController,
            labelText: t.common.duration.termYears,
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              size: AppDimensions.iconMd,
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              widget.onChanged(int.tryParse(val) ?? 0, widget.selectedMonths);
            },
          ),
        ),
        AppSpacings.gapMd,
        Expanded(
          child: AppTextField(
            controller: _monthsController,
            labelText: t.common.duration.termMonths,
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar02,
              size: AppDimensions.iconMd,
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              widget.onChanged(widget.selectedYears, int.tryParse(val) ?? 0);
            },
          ),
        ),
      ],
    );
  }
}
