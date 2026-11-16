import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/widgets/domain/nominee_form_hook.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:uuid/uuid.dart';

class NomineesInputSection extends HookWidget {
  final List<Nominee> nominees;
  final ValueChanged<List<Nominee>> onChanged;

  const NomineesInputSection({
    super.key,
    required this.nominees,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rowKeysRef = useRef<List<String>>(<String>[]);
    const uuid = Uuid();

    // Ensure every nominee entry has a stable key across rebuilds and external loads.
    while (rowKeysRef.value.length < nominees.length) {
      rowKeysRef.value.add(uuid.v4());
    }
    if (rowKeysRef.value.length > nominees.length) {
      rowKeysRef.value = rowKeysRef.value.sublist(0, nominees.length);
    }

    final totalBps = nominees.fold<BasisPoints>(
      BasisPoints.zero,
      (sum, n) => sum + BasisPoints.fromPercent(n.percentage),
    );
    final remainingBps = math.max(
      0,
      BasisPoints.hundredPercent.value - totalBps.value,
    );

    void addNominee() {
      rowKeysRef.value = [...rowKeysRef.value, uuid.v4()];
      final defaultRel = nominees.isEmpty
          ? NomineeRelationship.wife
          : NomineeRelationship.son;
      final defaultPct = nominees.isEmpty ? 100.0 : remainingBps / 100.0;
      onChanged([
        ...nominees,
        Nominee(
          name: '',
          relationship: defaultRel,
          percentage: defaultPct,
        ),
      ]);
    }

    void removeNominee(int index) {
      final nextKeys = List<String>.of(rowKeysRef.value)..removeAt(index);
      rowKeysRef.value = nextKeys;
      final nextList = List<Nominee>.of(nominees)..removeAt(index);
      onChanged(nextList);
    }

    void splitEvenly() {
      if (nominees.isEmpty) return;
      final n = nominees.length;
      final baseBps = BasisPoints.hundredPercent.value ~/ n;
      final remainder = BasisPoints.hundredPercent.value % n;
      onChanged([
        for (var i = 0; i < n; i++)
          nominees[i].copyWith(
            percentage: (baseBps + (i < remainder ? 1 : 0)) / 100.0,
          ),
      ]);
    }

    final theme = Theme.of(context);
    final financial = AppFinancialColors.of(context);
    final isExactHundred = totalBps == BasisPoints.hundredPercent;
    final allocatedPctLabel = formatNomineePercentage(totalBps.value / 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: FormSectionHeader(title: t.nominees.title)),
            if (nominees.length >= 2)
              ActionChip(
                key: const ValueKey('split_nominees_evenly_chip'),
                avatar: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPercent,
                  size: AppDimensions.iconSm,
                ),
                label: Text(t.nominees.splitEvenly),
                onPressed: splitEvenly,
              ),
          ],
        ),
        if (nominees.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingMd),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMd,
              vertical: AppDimensions.paddingXs,
            ),
            decoration: BoxDecoration(
              color: isExactHundred
                  ? financial.settled.container
                  : financial.warning.container,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              t.nominees.allocatedSummary(allocated: allocatedPctLabel),
              style: theme.textTheme.labelMedium?.copyWith(
                color: isExactHundred
                    ? financial.settled.onContainer
                    : financial.warning.onContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (nominees.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingMd),
            child: Text(
              t.nominees.noNominees,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          )
        else
          Column(
            children: [
              for (var index = 0; index < nominees.length; index++)
                _NomineeItemForm(
                  key: ValueKey(rowKeysRef.value[index]),
                  index: index,
                  nominee: nominees[index],
                  onRemove: () => removeNominee(index),
                  onChanged: (updated) {
                    final list = List<Nominee>.of(nominees);
                    list[index] = updated;
                    onChanged(list);
                  },
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: addNominee,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: AppDimensions.iconSm,
            ),
            label: Text(t.nominees.addNominee),
          ),
        ),
      ],
    );
  }
}

class _NomineeItemForm extends HookWidget {
  final int index;
  final Nominee nominee;
  final VoidCallback onRemove;
  final ValueChanged<Nominee> onChanged;

  const _NomineeItemForm({
    super.key,
    required this.index,
    required this.nominee,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = useNomineeFormState(nominee: nominee, onChanged: onChanged);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMd),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          children: [
            _buildNomineeHeader(context, index: index, onRemove: onRemove),
            AppSpacings.gapSm,
            _buildNameField(
              nameController: state.nameController,
              onChanged: state.notifyChange,
            ),
            AppSpacings.gapSm,
            _buildRelationshipField(
              relationshipState: state.relationshipState,
              onChanged: state.notifyChange,
            ),
            if (state.relationshipState.value == NomineeRelationship.other) ...[
              AppSpacings.gapSm,
              _buildCustomRelationshipField(
                customRelationshipController:
                    state.customRelationshipController,
                onChanged: state.notifyChange,
              ),
            ],
            AppSpacings.gapSm,
            _buildPercentageField(
              percentageController: state.percentageController,
              onChanged: state.notifyChange,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildNomineeHeader(
  BuildContext context, {
  required int index,
  required VoidCallback onRemove,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          '${t.nominees.singularTitle} ${index + 1}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      IconButton(
        key: ValueKey('delete_nominee_$index'),
        tooltip: t.nominees.deleteNominee,
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          size: AppDimensions.iconMd,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: onRemove,
      ),
    ],
  );
}

Widget _buildNameField({
  required TextEditingController nameController,
  required VoidCallback onChanged,
}) {
  return AppTextField(
    controller: nameController,
    labelText: t.nominees.name,
    prefixIcon: const HugeIcon(
      icon: HugeIcons.strokeRoundedUser,
      size: AppDimensions.iconMd,
    ),
    isRequired: true,
    validator: Nominee.validateName,
    textInputAction: TextInputAction.next,
    onChanged: (_) => onChanged(),
  );
}

Widget _buildRelationshipField({
  required ValueNotifier<NomineeRelationship> relationshipState,
  required VoidCallback onChanged,
}) {
  return AppDropdownField<NomineeRelationship>(
    value: relationshipState.value,
    labelText: t.nominees.relationship,
    items: NomineeRelationship.values
        .map(
          (rel) => DropdownMenuItem(value: rel, child: Text(rel.displayName)),
        )
        .toList(),
    onChanged: (rel) {
      if (rel != null) {
        relationshipState.value = rel;
        onChanged();
      }
    },
    prefixIcon: const HugeIcon(
      icon: HugeIcons.strokeRoundedUserMultiple,
      size: AppDimensions.iconMd,
    ),
  );
}

Widget _buildCustomRelationshipField({
  required TextEditingController customRelationshipController,
  required VoidCallback onChanged,
}) {
  return AppTextField(
    controller: customRelationshipController,
    labelText: t.nominees.customRelationship,
    prefixIcon: const HugeIcon(
      icon: HugeIcons.strokeRoundedUserMultiple,
      size: AppDimensions.iconMd,
    ),
    isRequired: true,
    textInputAction: TextInputAction.next,
    onChanged: (_) => onChanged(),
    validator: (val) =>
        Nominee.validateCustomRelationship(NomineeRelationship.other, val),
  );
}

Widget _buildPercentageField({
  required TextEditingController percentageController,
  required VoidCallback onChanged,
}) {
  return AppTextField(
    controller: percentageController,
    labelText: t.nominees.percentage,
    prefixIcon: const HugeIcon(
      icon: HugeIcons.strokeRoundedPercent,
      size: AppDimensions.iconMd,
    ),
    isRequired: true,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (val) => Nominee.validatePercentage(double.tryParse(val ?? '')),
    textInputAction: TextInputAction.done,
    onChanged: (_) => onChanged(),
  );
}
