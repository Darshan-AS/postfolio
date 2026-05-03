import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
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
    onChanged([...nominees, const Nominee(name: '', relationship: NomineeRelationship.other, percentage: 100)]);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.nominees.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _addNominee,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: AppDimensions.iconMd,
              ),
              label: Text(t.nominees.addNominee),
            ),
          ],
        ),
        AppSpacings.gapSm,
        if (nominees.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingMd,
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
    final nameController = useTextEditingController(text: nominee.name);
    final customRelationshipController = useTextEditingController(text: nominee.customRelationship ?? '');
    final percentageController = useTextEditingController(text: nominee.percentage.toString());
    final relationshipState = useState<NomineeRelationship>(nominee.relationship);

    // Sync controllers if parent changes state externally, but prevent cursor jumping
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nameController.text != nominee.name) {
          nameController.text = nominee.name;
        }
        if (customRelationshipController.text != (nominee.customRelationship ?? '')) {
          customRelationshipController.text = nominee.customRelationship ?? '';
        }
        if (relationshipState.value != nominee.relationship) {
          relationshipState.value = nominee.relationship;
        }
        if (percentageController.text != nominee.percentage.toString() && nominee.percentage != (double.tryParse(percentageController.text) ?? 100)) {
          percentageController.text = nominee.percentage.toString();
        }
      });
      return null;
    }, [nominee]);

    void notifyChange() {
      onChanged(
        nominee.copyWith(
          name: nameController.text.trim(),
          relationship: relationshipState.value,
          customRelationship: relationshipState.value == NomineeRelationship.other ? customRelationshipController.text.trim() : null,
          percentage: double.tryParse(percentageController.text.trim()) ?? 100,
        ),
      );
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${t.nominees.title} ${index + 1}',
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
            ),
            AppSpacings.gapSm,
            AppTextField(
              controller: nameController,
              labelText: t.nominees.name,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                size: AppDimensions.iconMd,
              ),
              isRequired: true,
              validator: Nominee.validateName,
              textInputAction: TextInputAction.next,
              onChanged: (_) => notifyChange(),
            ),
            AppSpacings.gapSm,
            AppDropdownField<NomineeRelationship>(
              value: relationshipState.value,
              labelText: t.nominees.relationship,
              items: NomineeRelationship.values
                  .map((rel) => DropdownMenuItem(
                        value: rel,
                        child: Text(rel.displayName),
                      ))
                  .toList(),
              onChanged: (rel) {
                if (rel != null) {
                  relationshipState.value = rel;
                  notifyChange();
                }
              },
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedUserMultiple,
                size: AppDimensions.iconMd,
              ),
            ),
            if (relationshipState.value == NomineeRelationship.other) ...[
              AppSpacings.gapSm,
              AppTextField(
                controller: customRelationshipController,
                labelText: t.nominees.relationship, // Can reuse the same label or add a new one
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserMultiple,
                  size: AppDimensions.iconMd,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => notifyChange(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Relationship is required';
                  return null;
                },
              ),
            ],
            AppSpacings.gapSm,
            AppTextField(
              controller: percentageController,
              labelText: t.nominees.percentage,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPercent,
                size: AppDimensions.iconMd,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) => notifyChange(),
            ),
          ],
        ),
      ),
    );
  }
}
