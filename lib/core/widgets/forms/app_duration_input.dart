import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AppDurationInput extends HookWidget {
  final TenureInputType tenureInputType;
  final List<int> allowedTenuresInYears;
  final int selectedYears;
  final int selectedMonths;
  final String? derivedString;
  final void Function(int years, int months) onChanged;

  const AppDurationInput({
    super.key,
    required this.tenureInputType,
    required this.allowedTenuresInYears,
    required this.selectedYears,
    required this.selectedMonths,
    this.derivedString,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final yearsController = useTextEditingController(
      text: selectedYears.toString(),
    );
    final monthsController = useTextEditingController(
      text: selectedMonths.toString(),
    );

    // Sync controllers with external state if it changes programmatically
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final parsedYears = int.tryParse(yearsController.text) ?? 0;
        if (parsedYears != selectedYears || yearsController.text.isEmpty) {
          yearsController.text = selectedYears.toString();
        }
        final parsedMonths = int.tryParse(monthsController.text) ?? 0;
        if (parsedMonths != selectedMonths || monthsController.text.isEmpty) {
          monthsController.text = selectedMonths.toString();
        }
      });
      return null;
    }, [selectedYears, selectedMonths]);

    switch (tenureInputType) {
      case TenureInputType.singleFixed:
      case TenureInputType.fixedOptions:
        return _buildFixedTenure(context, yearsController);
      case TenureInputType.derived:
        return _buildDerivedTenure(
          context,
          yearsController: yearsController,
          monthsController: monthsController,
        );
    }
  }

  Widget _buildFixedTenure(
    BuildContext context,
    TextEditingController yearsController,
  ) {
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
        isRequired: true,
        readOnly: true,
      );
    }

    // For TD with multiple options (1, 2, 3, 5 years)
    return AppSegmentedButtonField<int>(
      value: selectedYears,
      labelText: t.common.duration.termYears,
      isRequired: true,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar01,
        size: AppDimensions.iconMd,
      ),
      segments: allowedYears.map((year) {
        return ButtonSegment<int>(
          value: year,
          label: Text(t.common.duration.yearAbbreviation(n: year)),
        );
      }).toList(),
      onChanged: (int newSelection) {
        onChanged(newSelection, 0);
      },
    );
  }

  Widget _buildDerivedTenure(
    BuildContext context, {
    required TextEditingController yearsController,
    required TextEditingController monthsController,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            controller: yearsController,
            labelText: t.common.duration.termYears,
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              size: AppDimensions.iconMd,
            ),
            isRequired: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              final years = int.tryParse(val) ?? 0;
              final months = int.tryParse(monthsController.text) ?? 0;
              onChanged(years, months);
            },
          ),
        ),
        AppSpacings.gapMd,
        Expanded(
          child: AppTextField(
            controller: monthsController,
            labelText: t.common.duration.termMonths,
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              size: AppDimensions.iconMd,
            ),
            isRequired: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              final years = int.tryParse(yearsController.text) ?? 0;
              final months = int.tryParse(val) ?? 0;
              onChanged(years, months);
            },
          ),
        ),
      ],
    );
  }
}
