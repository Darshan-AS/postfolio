import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/widgets/domain/nominee_form_hook.dart';
import 'package:postfolio/i18n/strings.g.dart';

class NomineesInputSection extends HookWidget {
  final List<Nominee> nominees;
  final ValueChanged<List<Nominee>> onChanged;

  const NomineesInputSection({
    super.key,
    required this.nominees,
    required this.onChanged,
  });

  void _addNominee() {
    onChanged([
      ...nominees,
      const Nominee(
        name: '',
        relationship: NomineeRelationship.other,
        percentage: AppConstants.maxPercentage,
      ),
    ]);
  }

  void _removeNominee(int index) {
    final list = List.of(nominees);
    list.removeAt(index);
    onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionHeader(
          title: t.nominees.title,
        ),
        if (nominees.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppDimensions.paddingMd,
            ),
            child: Text(
              t.nominees.noNominees,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nominees.length,
            itemBuilder: (context, index) {
              return _NomineeItemForm(
                index: index,
                nominee: nominees[index],
                onRemove: () => _removeNominee(index),
                onChanged: (updated) {
                  final list = List.of(nominees);
                  list[index] = updated;
                  onChanged(list);
                },
              );
            },
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: _addNominee,
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
      Text(
        '${t.nominees.singularTitle} ${index + 1}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      IconButton(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          size: AppDimensions.iconMd,
        ),
        color: Theme.of(context).colorScheme.error,
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
    labelText: t.nominees.relationship,
    prefixIcon: const HugeIcon(
      icon: HugeIcons.strokeRoundedUserMultiple,
      size: AppDimensions.iconMd,
    ),
    isRequired: true,
    textInputAction: TextInputAction.next,
    onChanged: (_) => onChanged(),
    validator: (val) {
      if (val == null || val.trim().isEmpty) {
        return t.errors.requiredField(field: t.nominees.relationship);
      }
      return null;
    },
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
