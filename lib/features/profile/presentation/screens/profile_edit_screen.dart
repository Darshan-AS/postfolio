import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/enums/agency_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/feedback/unsaved_changes_pop_scope.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/form_app_bar.dart';
import 'package:postfolio/core/widgets/layout/form_screen_body.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/profile/presentation/controllers/profile_controller.dart';
import 'package:postfolio/features/profile/presentation/hooks/use_profile_form.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final fallbackUser = switch (authState) {
      AuthStateAuthenticated(:final user) => user,
      _ => null,
    };

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: FormAppBar(title: t.settings.editProfile),
        body: const Center(child: AppLoadingIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: FormAppBar(title: t.settings.editProfile),
        body: ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
      ),
      data: (profile) => _ProfileForm(
        initialProfile: AgentProfile.effectiveFrom(profile, fallbackUser),
      ),
    );
  }
}

class _ProfileForm extends HookConsumerWidget {
  const _ProfileForm({required this.initialProfile});

  final AgentProfile initialProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = useProfileForm(context, ref, initialProfile);
    final isDemoMode = ref.watch(demoModeProvider);

    return UnsavedChangesPopScope(
      isDirty: form.isDirty && !form.isSaving.value,
      child: Scaffold(
        appBar: FormAppBar(title: t.settings.editProfile),
        body: FormScreenBody(
          isSaving: form.isSaving.value,
          onSave: form.save,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pageMargin,
              AppDimensions.paddingSm,
              AppDimensions.pageMargin,
              AppDimensions.paddingLg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxFormWidth,
                ),
                child: Form(
                  key: form.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormSection(
                        title: t.settings.profileFields.personalSection,
                        children: [
                          AppTextField(
                            controller: form.nameController,
                            labelText: t.settings.profileFields.displayName,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedUser,
                              size: AppDimensions.iconMd,
                            ),
                            isRequired: true,
                            validator: AgentProfile.validateName,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacings.gapLg,
                          AppTextField(
                            controller: form.emailController,
                            labelText: t.settings.profileFields.email,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedMail01,
                              size: AppDimensions.iconMd,
                            ),
                            readOnly: true,
                            enabled: false,
                          ),
                          FormFieldSupportingText(
                            t.settings.profileFields.emailManagedByGoogle,
                          ),
                          AppSpacings.gapLg,
                          AppTextField(
                            controller: form.phoneController,
                            labelText: t.settings.profileFields.phone,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedCall02,
                              size: AppDimensions.iconMd,
                            ),
                            validator: AgentProfile.validatePhone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacings.gapLg,
                          AppDateField(
                            controller: form.dobController,
                            labelText: t.settings.profileFields.dateOfBirth,
                            onTap: () => form.pickDate(
                              state: form.dobDate,
                              controller: form.dobController,
                              firstDate: DateTime(
                                AppConstants.firstDatePickerYear,
                              ),
                              lastDate: ref.read(currentDateProvider),
                            ),
                            onClear: () => form.clearDate(
                              form.dobDate,
                              form.dobController,
                            ),
                          ),
                          AppSpacings.gapLg,
                          AppTextField(
                            controller: form.addressController,
                            labelText: t.settings.profileFields.address,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedHome01,
                              size: AppDimensions.iconMd,
                            ),
                            maxLines: AppConstants.addressMaxLines,
                          ),
                        ],
                      ),
                      AppSpacings.gapLg,
                      FormSection(
                        title: t.settings.profileFields.agencySection,
                        children: [
                          Text(
                            t.settings.profileFields.agencyType,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          AppSpacings.gapXs,
                          AppButtonGroup<AgencyType>.multi(
                            key: const ValueKey('profile_agency_types_group'),
                            selected: form.selectedAgencyTypes.value,
                            onToggled: form.toggleAgencyType,
                            segments: [
                              AppSegment(
                                value: AgencyType.mpkby,
                                label: AgencyType.mpkby.displayName,
                              ),
                              AppSegment(
                                value: AgencyType.sas,
                                label: AgencyType.sas.displayName,
                              ),
                            ],
                          ),
                          FormFieldSupportingText(
                            t.settings.profileFields.agencyTypeHint,
                          ),
                          AppSpacings.gapLg,
                          AppTextField(
                            controller: form.agencyCodeController,
                            labelText: t.settings.profileFields.dopAgentId,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedTicket01,
                              size: AppDimensions.iconMd,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacings.gapLg,
                          AppTextField(
                            controller: form.branchController,
                            labelText:
                                t.settings.profileFields.postOfficeBranch,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedBuilding03,
                              size: AppDimensions.iconMd,
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                      _AnimatedFormSection(
                        visible: form.showMpkby,
                        child: _LicenseFormSection(
                          title: t.settings.profileFields.mpkbySection,
                          numberController: form.mpkbyLicenseController,
                          numberLabel: t.settings.profileFields.mpkbyLicenseNo,
                          validController: form.mpkbyValidController,
                          validLabel: t.settings.profileFields.mpkbyValidUntil,
                          hasValidDate: form.mpkbyValidUntil.value != null,
                          onPickValid: () => form.pickDate(
                            state: form.mpkbyValidUntil,
                            controller: form.mpkbyValidController,
                            firstDate: DateTime(AppConstants.firstStartYear),
                            lastDate: DateTime(AppConstants.lastDatePickerYear),
                          ),
                          onClearValid: () => form.clearDate(
                            form.mpkbyValidUntil,
                            form.mpkbyValidController,
                          ),
                        ),
                      ),
                      _AnimatedFormSection(
                        visible: form.showSas,
                        child: _LicenseFormSection(
                          title: t.settings.profileFields.sasSection,
                          numberController: form.sasLicenseController,
                          numberLabel: t.settings.profileFields.sasLicenseNo,
                          validController: form.sasValidController,
                          validLabel: t.settings.profileFields.sasValidUntil,
                          hasValidDate: form.sasValidUntil.value != null,
                          onPickValid: () => form.pickDate(
                            state: form.sasValidUntil,
                            controller: form.sasValidController,
                            firstDate: DateTime(AppConstants.firstStartYear),
                            lastDate: DateTime(AppConstants.lastDatePickerYear),
                          ),
                          onClearValid: () => form.clearDate(
                            form.sasValidUntil,
                            form.sasValidController,
                          ),
                        ),
                      ),
                      AppSpacings.gapLg,
                      FormSection(
                        title: t.settings.profileFields.kycSection,
                        children: [
                          AppTextField(
                            controller: form.panController,
                            labelText: t.settings.profileFields.panNumber,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedCreditCard,
                              size: AppDimensions.iconMd,
                            ),
                            inputFormatters: const [UpperCaseTextFormatter()],
                            validator: AgentProfile.validatePan,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacings.gapLg,
                          AppTextField(
                            controller: form.aadhaarController,
                            labelText: t.settings.profileFields.aadhaarNumber,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedId,
                              size: AppDimensions.iconMd,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                AppConstants.aadhaarLength,
                              ),
                            ],
                            validator: AgentProfile.validateAadhaar,
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacings.gapLg,
                          AppTextField(
                            controller: form.commissionSbController,
                            labelText:
                                t.settings.profileFields.commissionSbAccount,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedBank,
                              size: AppDimensions.iconMd,
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                      AppSpacings.gapLg,
                      FormSection(
                        title: t.settings.profileFields.notes,
                        children: [
                          AppTextField(
                            controller: form.notesController,
                            labelText: t.settings.profileFields.notes,
                            prefixIcon: const AppIcon(
                              HugeIcons.strokeRoundedNote01,
                              size: AppDimensions.iconMd,
                            ),
                            minLines: AppConstants.notesMinLines,
                            maxLines: AppConstants.notesMaxLines,
                          ),
                        ],
                      ),
                      if (isDemoMode) ...[
                        AppSpacings.gapMd,
                        Text(
                          t.settings.demoProfileNotice,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LicenseFormSection extends StatelessWidget {
  const _LicenseFormSection({
    required this.title,
    required this.numberController,
    required this.numberLabel,
    required this.validController,
    required this.validLabel,
    required this.hasValidDate,
    required this.onPickValid,
    required this.onClearValid,
  });

  final String title;
  final TextEditingController numberController;
  final String numberLabel;
  final TextEditingController validController;
  final String validLabel;
  final bool hasValidDate;
  final VoidCallback onPickValid;
  final VoidCallback onClearValid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacings.gapLg,
        FormSection(
          title: title,
          children: [
            AppTextField(
              controller: numberController,
              labelText: numberLabel,
              prefixIcon: const AppIcon(
                HugeIcons.strokeRoundedId,
                size: AppDimensions.iconMd,
              ),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppDateField(
              controller: validController,
              labelText: validLabel,
              prefixIcon: HugeIcons.strokeRoundedCalendar03,
              onTap: onPickValid,
              onClear: onClearValid,
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedFormSection extends StatelessWidget {
  const _AnimatedFormSection({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = visible ? child : const SizedBox.shrink();
    if (MediaQuery.disableAnimationsOf(context)) return content;
    return AnimatedSize(
      duration: AppMotion.spatialFastDuration,
      curve: AppMotion.effectsCurve,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: content,
    );
  }
}
