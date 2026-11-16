import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/models/nominee.dart';

String formatNomineePercentage(double pct) {
  if (pct == pct.roundToDouble()) {
    return pct.toInt().toString();
  }
  final fixed = pct.toStringAsFixed(2);
  return fixed.endsWith('0') ? fixed.substring(0, fixed.length - 1) : fixed;
}

class NomineeFormState {
  final TextEditingController nameController;
  final TextEditingController customRelationshipController;
  final TextEditingController percentageController;
  final ValueNotifier<NomineeRelationship> relationshipState;
  final VoidCallback notifyChange;

  NomineeFormState({
    required this.nameController,
    required this.customRelationshipController,
    required this.percentageController,
    required this.relationshipState,
    required this.notifyChange,
  });
}

NomineeFormState useNomineeFormState({
  required Nominee nominee,
  required ValueChanged<Nominee> onChanged,
}) {
  final nameController = useTextEditingController(text: nominee.name);
  final customRelationshipController = useTextEditingController(
    text: nominee.customRelationship ?? '',
  );
  final percentageController = useTextEditingController(
    text: formatNomineePercentage(nominee.percentage),
  );
  final relationshipState = useState<NomineeRelationship>(nominee.relationship);

  // Sync controllers when parent updates state externally (e.g. Split Evenly),
  // without trimming mid-word spaces or resetting the active cursor.
  useEffect(() {
    if (nameController.text != nominee.name) {
      nameController.text = nominee.name;
    }
    if (customRelationshipController.text != (nominee.customRelationship ?? '')) {
      customRelationshipController.text = nominee.customRelationship ?? '';
    }
    if (relationshipState.value != nominee.relationship) {
      relationshipState.value = nominee.relationship;
    }
    final parsedCurrent = double.tryParse(percentageController.text.trim());
    if (parsedCurrent != nominee.percentage) {
      percentageController.text = formatNomineePercentage(nominee.percentage);
    }
    return null;
  }, [nominee]);

  void notifyChange() {
    onChanged(
      nominee.copyWith(
        name: nameController.text,
        relationship: relationshipState.value,
        customRelationship: relationshipState.value == NomineeRelationship.other
            ? customRelationshipController.text
            : null,
        percentage: double.tryParse(percentageController.text.trim()) ?? 0.0,
      ),
    );
  }

  return NomineeFormState(
    nameController: nameController,
    customRelationshipController: customRelationshipController,
    percentageController: percentageController,
    relationshipState: relationshipState,
    notifyChange: notifyChange,
  );
}
