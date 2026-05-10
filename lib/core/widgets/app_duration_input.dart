import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
import 'package:hugeicons/hugeicons.dart';
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
    final derivedController = useTextEditingController(
      text: derivedString ?? '',
    );

    // Sync controllers with external state if it changes
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (yearsController.text != selectedYears.toString()) {
          yearsController.text = selectedYears.toString();
        }
        if (derivedController.text != (derivedString ?? '')) {
          derivedController.text = derivedString ?? '';
        }
      });
      return null;
    }, [selectedYears, selectedMonths, derivedString]);

    switch (tenureInputType) {
      case TenureInputType.singleFixed:
      case TenureInputType.fixedOptions:
        return _buildFixedTenure(context, yearsController);
      case TenureInputType.derived:
        return _buildDerivedTenure(context, derivedController);
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
        readOnly: true,
        enabled: true,
      );
    }

    // For TD with multiple options (1, 2, 3, 5 years)
    return AppSegmentedButtonField<int>(
      value: selectedYears,
      labelText: t.common.duration.termYears,
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
    BuildContext context,
    TextEditingController derivedController,
  ) {
    return AppTextField(
      controller: derivedController,
      labelText: t.common.duration.termYears,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar01,
        size: AppDimensions.iconMd,
      ),
      readOnly: true,
      enabled: true,
    );
  }
}
