import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/widgets/domain/nominee_form_hook.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
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
    final emphasized = AppTypography.emphasizedOf(context);
    final financial = AppFinancialColors.of(context);
    final isExactHundred = totalBps == BasisPoints.hundredPercent;
    final allocatedPctLabel = formatNomineePercentage(totalBps.value / 100.0);
    final allocation = isExactHundred ? financial.settled : financial.warning;
    final allocatedSummary = t.nominees.allocatedSummary(
      allocated: allocatedPctLabel,
    );

    final addButton = Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppButton.tonal(
        label: t.nominees.addNominee,
        icon: HugeIcons.strokeRoundedAdd01,
        onPressed: addNominee,
      ),
    );

    // The section is one group of rows: the allocation, one row per nominee, and the add
    // action. With no nominees it is a single row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The chip sits at the end of the heading's line, and moves under the heading when
        // the two do not fit side by side (large text).
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DetailSectionTitle(t.nominees.title),
            if (nominees.length >= 2)
              Padding(
                // Lines the chip up with the heading's text, and keeps it off the group
                // below, when it is on its own line.
                padding: const EdgeInsetsDirectional.only(
                  start: AppDimensions.paddingLg,
                  bottom: AppDimensions.paddingXs,
                ),
                child: ActionChip(
                  key: const ValueKey('split_nominees_evenly_chip'),
                  avatar: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPercent,
                    size: AppDimensions.iconSm,
                  ),
                  label: Text(t.nominees.splitEvenly),
                  onPressed: splitEvenly,
                ),
              ),
          ],
        ),
        if (nominees.isEmpty)
          AppGroupTile(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.nominees.noNominees,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacings.gapMd,
                  addButton,
                ],
              ),
            ),
          )
        else ...[
          AppGroupTile(
            position: AppGroupPosition.first,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    allocatedSummary,
                    style: emphasized.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  AppSpacings.gapSm,
                  AppLinearProgress(
                    value:
                        totalBps.value / BasisPoints.hundredPercent.value,
                    color: allocation.accent,
                    semanticsLabel: allocatedSummary,
                  ),
                ],
              ),
            ),
          ),
          for (var index = 0; index < nominees.length; index++)
            Padding(
              key: ValueKey(rowKeysRef.value[index]),
              padding: const EdgeInsets.only(top: AppShapes.groupGap),
              child: _NomineeItemForm(
                index: index,
                nominee: nominees[index],
                onRemove: () => removeNominee(index),
                onChanged: (updated) {
                  final list = List<Nominee>.of(nominees);
                  list[index] = updated;
                  onChanged(list);
                },
              ),
            ),
          const SizedBox(height: AppShapes.groupGap),
          AppGroupTile(
            position: AppGroupPosition.last,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: addButton,
            ),
          ),
        ],
      ],
    );
  }
}

/// One nominee: a middle row of the nominees group (the allocation row sits above the
/// nominees and the add action below them).
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

    return AppGroupTile(
      position: AppGroupPosition.middle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLg,
          AppDimensions.paddingSm,
          AppDimensions.paddingLg,
          AppDimensions.paddingLg,
        ),
        child: Column(
          children: [
            _buildNomineeHeader(context, index: index, onRemove: onRemove),
            AppSpacings.gapSm,
            _buildNameField(
              nameController: state.nameController,
              onChanged: state.notifyChange,
            ),
            AppSpacings.gapMd,
            _buildRelationshipField(
              relationshipState: state.relationshipState,
              onChanged: state.notifyChange,
            ),
            if (state.relationshipState.value == NomineeRelationship.other) ...[
              AppSpacings.gapMd,
              _buildCustomRelationshipField(
                customRelationshipController:
                    state.customRelationshipController,
                onChanged: state.notifyChange,
              ),
            ],
            AppSpacings.gapMd,
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
          style: AppTypography.emphasizedOf(context).titleSmall,
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
          (rel) => DropdownMenuItem(
            value: rel,
            child: Text(
              rel.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
