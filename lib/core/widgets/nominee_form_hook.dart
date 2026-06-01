import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/models/nominee.dart';

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
    text: nominee.percentage.toString(),
  );
  final relationshipState = useState<NomineeRelationship>(nominee.relationship);

  // Sync controllers if parent changes state externally, but prevent cursor jumping
  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (nameController.text != nominee.name) {
        nameController.text = nominee.name;
      }
      if (customRelationshipController.text !=
          (nominee.customRelationship ?? '')) {
        customRelationshipController.text = nominee.customRelationship ?? '';
      }
      if (relationshipState.value != nominee.relationship) {
        relationshipState.value = nominee.relationship;
      }
      if (percentageController.text != nominee.percentage.toString() &&
          nominee.percentage !=
              (double.tryParse(percentageController.text) ??
                  AppConstants.maxPercentage)) {
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
        customRelationship: relationshipState.value == NomineeRelationship.other
            ? customRelationshipController.text.trim()
            : null,
        percentage:
            double.tryParse(percentageController.text.trim()) ??
            AppConstants.maxPercentage,
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
