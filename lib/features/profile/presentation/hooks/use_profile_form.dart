import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/agency_type.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/unsaved_changes_pop_scope.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/profile/presentation/controllers/profile_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class ProfileFormState {
  const ProfileFormState({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.dobDate,
    required this.dobController,
    required this.selectedAgencyTypes,
    required this.agencyCodeController,
    required this.branchController,
    required this.mpkbyLicenseController,
    required this.mpkbyValidUntil,
    required this.mpkbyValidController,
    required this.sasLicenseController,
    required this.sasValidUntil,
    required this.sasValidController,
    required this.panController,
    required this.aadhaarController,
    required this.commissionSbController,
    required this.notesController,
    required this.isSaving,
    required this.isDirty,
    required this.showMpkby,
    required this.showSas,
    required this.toggleAgencyType,
    required this.pickDate,
    required this.clearDate,
    required this.save,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final ValueNotifier<DateTime?> dobDate;
  final TextEditingController dobController;
  final ValueNotifier<Set<AgencyType>> selectedAgencyTypes;
  final TextEditingController agencyCodeController;
  final TextEditingController branchController;
  final TextEditingController mpkbyLicenseController;
  final ValueNotifier<DateTime?> mpkbyValidUntil;
  final TextEditingController mpkbyValidController;
  final TextEditingController sasLicenseController;
  final ValueNotifier<DateTime?> sasValidUntil;
  final TextEditingController sasValidController;
  final TextEditingController panController;
  final TextEditingController aadhaarController;
  final TextEditingController commissionSbController;
  final TextEditingController notesController;
  final ValueNotifier<bool> isSaving;
  final bool isDirty;
  final bool showMpkby;
  final bool showSas;
  final ValueChanged<AgencyType> toggleAgencyType;
  final Future<void> Function({
    required ValueNotifier<DateTime?> state,
    required TextEditingController controller,
    required DateTime firstDate,
    required DateTime lastDate,
  })
  pickDate;
  final void Function(
    ValueNotifier<DateTime?> state,
    TextEditingController controller,
  )
  clearDate;
  final Future<void> Function() save;
}

ProfileFormState useProfileForm(
  BuildContext context,
  WidgetRef ref,
  AgentProfile initialProfile,
) {
  final formKey = useMemoized(() => GlobalKey<FormState>());
  final nameController = useTextEditingController(text: initialProfile.name);
  final emailController = useTextEditingController(text: initialProfile.email);
  final phoneController = useTextEditingController(text: initialProfile.phone);
  final addressController = useTextEditingController(
    text: initialProfile.address,
  );
  final dobDate = useState<DateTime?>(initialProfile.dateOfBirth);
  final dobController = useTextEditingController(
    text: initialProfile.dateOfBirth?.toAppFormat() ?? '',
  );

  final selectedAgencyTypes = useState<Set<AgencyType>>({
    ...initialProfile.agencyTypes,
    if (initialProfile.hasMpkbyLicenseDetails) AgencyType.mpkby,
    if (initialProfile.hasSasLicenseDetails) AgencyType.sas,
  });
  final agencyCodeController = useTextEditingController(
    text: initialProfile.agencyCode,
  );
  final branchController = useTextEditingController(
    text: initialProfile.postOfficeBranch,
  );
  final mpkbyLicenseController = useTextEditingController(
    text: initialProfile.mpkbyLicenseNo,
  );
  final mpkbyValidUntil = useState<DateTime?>(initialProfile.mpkbyValidUntil);
  final mpkbyValidController = useTextEditingController(
    text: initialProfile.mpkbyValidUntil?.toAppFormat() ?? '',
  );
  final sasLicenseController = useTextEditingController(
    text: initialProfile.sasLicenseNo,
  );
  final sasValidUntil = useState<DateTime?>(initialProfile.sasValidUntil);
  final sasValidController = useTextEditingController(
    text: initialProfile.sasValidUntil?.toAppFormat() ?? '',
  );

  final panController = useTextEditingController(
    text: initialProfile.panNumber,
  );
  final aadhaarController = useTextEditingController(
    text: initialProfile.aadhaarNumber,
  );
  final commissionSbController = useTextEditingController(
    text: initialProfile.commissionSbAccount,
  );
  final notesController = useTextEditingController(text: initialProfile.notes);
  final isSaving = useState(false);

  final isDirty = useIsFormDirty(
    [
      nameController,
      phoneController,
      addressController,
      dobDate,
      selectedAgencyTypes,
      agencyCodeController,
      branchController,
      mpkbyLicenseController,
      mpkbyValidUntil,
      sasLicenseController,
      sasValidUntil,
      panController,
      aadhaarController,
      commissionSbController,
      notesController,
    ],
    () => [
      nameController.text,
      phoneController.text,
      addressController.text,
      dobDate.value?.toIso8601String() ?? '',
      (selectedAgencyTypes.value.map((e) => e.name).toList()..sort()).join(','),
      agencyCodeController.text,
      branchController.text,
      mpkbyLicenseController.text,
      mpkbyValidUntil.value?.toIso8601String() ?? '',
      sasLicenseController.text,
      sasValidUntil.value?.toIso8601String() ?? '',
      panController.text,
      aadhaarController.text,
      commissionSbController.text,
      notesController.text,
    ].join('\u0000'),
  );

  Future<void> pickDate({
    required ValueNotifier<DateTime?> state,
    required TextEditingController controller,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final today = ref.read(currentDateProvider);
    final initial = state.value ?? today;
    final clampedInitial = initial.isBefore(firstDate)
        ? firstDate
        : (initial.isAfter(lastDate) ? lastDate : initial);
    final picked = await showDatePicker(
      context: context,
      initialDate: clampedInitial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      state.value = picked;
      controller.text = picked.toAppFormat();
    }
  }

  void clearDate(
    ValueNotifier<DateTime?> state,
    TextEditingController controller,
  ) {
    state.value = null;
    controller.clear();
  }

  void toggleAgencyType(AgencyType type) {
    final next = {...selectedAgencyTypes.value};
    if (!next.add(type)) {
      next.remove(type);
    }
    selectedAgencyTypes.value = next;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSaving.value = true;
    final includeMpkby = selectedAgencyTypes.value.contains(AgencyType.mpkby);
    final includeSas = selectedAgencyTypes.value.contains(AgencyType.sas);
    final updated = initialProfile.copyWith(
      name: nameController.text,
      phone: phoneController.text,
      address: addressController.text,
      dateOfBirth: dobDate.value,
      agencyTypes: AgencyType.values
          .where(selectedAgencyTypes.value.contains)
          .toList(),
      agencyCode: agencyCodeController.text,
      postOfficeBranch: branchController.text,
      mpkbyLicenseNo: includeMpkby ? mpkbyLicenseController.text : null,
      mpkbyValidUntil: includeMpkby ? mpkbyValidUntil.value : null,
      sasLicenseNo: includeSas ? sasLicenseController.text : null,
      sasValidUntil: includeSas ? sasValidUntil.value : null,
      panNumber: panController.text,
      aadhaarNumber: aadhaarController.text,
      commissionSbAccount: commissionSbController.text,
      notes: notesController.text,
    );
    final result = await ref
        .read(profileControllerProvider.notifier)
        .saveProfile(updated);
    isSaving.value = false;
    if (!context.mounted) return;
    AppFeedback.showResult(
      context,
      result,
      successMessage: t.settings.profileUpdated,
    );
    if (result is Success) {
      Navigator.of(context).pop();
    }
  }

  return ProfileFormState(
    formKey: formKey,
    nameController: nameController,
    emailController: emailController,
    phoneController: phoneController,
    addressController: addressController,
    dobDate: dobDate,
    dobController: dobController,
    selectedAgencyTypes: selectedAgencyTypes,
    agencyCodeController: agencyCodeController,
    branchController: branchController,
    mpkbyLicenseController: mpkbyLicenseController,
    mpkbyValidUntil: mpkbyValidUntil,
    mpkbyValidController: mpkbyValidController,
    sasLicenseController: sasLicenseController,
    sasValidUntil: sasValidUntil,
    sasValidController: sasValidController,
    panController: panController,
    aadhaarController: aadhaarController,
    commissionSbController: commissionSbController,
    notesController: notesController,
    isSaving: isSaving,
    isDirty: isDirty,
    showMpkby: selectedAgencyTypes.value.contains(AgencyType.mpkby),
    showSas: selectedAgencyTypes.value.contains(AgencyType.sas),
    toggleAgencyType: toggleAgencyType,
    pickDate: pickDate,
    clearDate: clearDate,
    save: save,
  );
}
