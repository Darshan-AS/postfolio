import 'package:flutter/material.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/i18n/strings.g.dart';

class _NomineeFormModel {
  final TextEditingController nameController;
  final TextEditingController relationshipController;
  final TextEditingController percentageController;

  _NomineeFormModel({String? name, String? relationship, double? percentage})
    : nameController = TextEditingController(text: name),
      relationshipController = TextEditingController(text: relationship),
      percentageController = TextEditingController(
        text: percentage?.toString() ?? '100',
      );

  void dispose() {
    nameController.dispose();
    relationshipController.dispose();
    percentageController.dispose();
  }
}

class NomineesInputSection extends StatefulWidget {
  final List<Nominee> initialNominees;
  final ValueChanged<List<Nominee>> onChanged;

  const NomineesInputSection({
    super.key,
    required this.initialNominees,
    required this.onChanged,
  });

  @override
  State<NomineesInputSection> createState() => _NomineesInputSectionState();
}

class _NomineesInputSectionState extends State<NomineesInputSection> {
  final List<_NomineeFormModel> _nomineeForms = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialNominees.isNotEmpty) {
      _nomineeForms.addAll(
        widget.initialNominees.map(
          (n) =>
              _NomineeFormModel(
                  name: n.name,
                  relationship: n.relationship,
                  percentage: n.percentage,
                )
                ..nameController.addListener(_notifyChanges)
                ..relationshipController.addListener(_notifyChanges)
                ..percentageController.addListener(_notifyChanges),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final form in _nomineeForms) {
      form.dispose();
    }
    super.dispose();
  }

  void _notifyChanges() {
    final list = _nomineeForms
        .map(
          (f) => Nominee(
            name: f.nameController.text.trim(),
            relationship: f.relationshipController.text.trim(),
            percentage:
                double.tryParse(f.percentageController.text.trim()) ?? 100,
          ),
        )
        .toList();
    widget.onChanged(list);
  }

  void _addNominee() {
    setState(() {
      final form = _NomineeFormModel();
      form.nameController.addListener(_notifyChanges);
      form.relationshipController.addListener(_notifyChanges);
      form.percentageController.addListener(_notifyChanges);
      _nomineeForms.add(form);
    });
    _notifyChanges();
  }

  void _removeNominee(int index) {
    setState(() {
      final form = _nomineeForms.removeAt(index);
      form.dispose();
    });
    _notifyChanges();
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
              icon: const Icon(Icons.add),
              label: Text(t.nominees.addNominee),
            ),
          ],
        ),
        AppSpacings.gapSm,
        if (_nomineeForms.isEmpty)
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
            itemCount: _nomineeForms.length,
            itemBuilder: (context, index) {
              final form = _nomineeForms[index];
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
                            icon: const Icon(Icons.delete_outline),
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () => _removeNominee(index),
                          ),
                        ],
                      ),
                      AppSpacings.gapSm,
                      TextFormField(
                        controller: form.nameController,
                        decoration: AppInputDecoration.m3(
                          context,
                          labelText: t.nominees.name,
                          prefixIcon: Icons.person_pin_outlined,
                          isRequired: true,
                        ),
                        validator: Nominee.validateName,
                        textInputAction: TextInputAction.next,
                      ),
                      AppSpacings.gapSm,
                      TextFormField(
                        controller: form.relationshipController,
                        decoration: AppInputDecoration.m3(
                          context,
                          labelText: t.nominees.relationship,
                          prefixIcon: Icons.people_alt_outlined,
                          isRequired: true,
                        ),
                        validator: Nominee.validateRelationship,
                        textInputAction: TextInputAction.next,
                      ),
                      AppSpacings.gapSm,
                      TextFormField(
                        controller: form.percentageController,
                        decoration: AppInputDecoration.m3(
                          context,
                          labelText: t.nominees.percentage,
                          prefixIcon: Icons.percent_outlined,
                          isRequired: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => Nominee.validatePercentage(
                          double.tryParse(v ?? ''),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
