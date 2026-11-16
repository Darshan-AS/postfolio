import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/domain/nominees_input_section.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/feedback/unsaved_changes_pop_scope.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/form_app_bar.dart';

import 'package:postfolio/features/customers/presentation/hooks/use_customer_form.dart';
import 'package:postfolio/i18n/strings.g.dart';

class CustomerFormScreen extends ConsumerWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customerId == null) {
      return const _CustomerForm();
    }
    return AsyncSingleEntityBuilder<Customer>(
      state: ref.watch(customerByIdProvider(customerId!)),
      notFoundMessage: t.customers.customerNotFound,
      onRetry: () => ref.invalidate(customerByIdProvider(customerId!)),
      builder: (customer) => _CustomerForm(existingCustomer: customer),
    );
  }
}

class _CustomerForm extends HookConsumerWidget {
  final Customer? existingCustomer;

  const _CustomerForm({this.existingCustomer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = useCustomerForm(ref: ref, customer: existingCustomer);
    final isDirty = useIsFormDirty(
      [
        state.nameController,
        state.emailController,
        state.phoneController,
        state.addressController,
        state.cifNumberController,
        state.aadhaarNumberController,
        state.panNumberController,
        state.savingsAccountNumberController,
        state.dateOfBirthController,
        state.notesController,
        state.nominees,
      ],
      () => [
        state.nameController.text,
        state.emailController.text,
        state.phoneController.text,
        state.addressController.text,
        state.cifNumberController.text,
        state.aadhaarNumberController.text,
        state.panNumberController.text,
        state.savingsAccountNumberController.text,
        state.dateOfBirthController.text,
        state.notesController.text,
        state.nominees.value.toString(),
      ].join('\u0000'),
    );

    return UnsavedChangesPopScope(
      isDirty: isDirty && !state.isSaving.value,
      child: Scaffold(
        appBar: FormAppBar(
          title: state.isUpdating
              ? t.customers.editCustomer
              : t.customers.newCustomer,
          isSaving: state.isSaving.value,
          onSave: () => state.save(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxFormWidth,
              ),
              child: Form(
                key: state.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildPersonalInfo(
                      nameController: state.nameController,
                      phoneController: state.phoneController,
                      emailController: state.emailController,
                      dateOfBirthController: state.dateOfBirthController,
                      addressController: state.addressController,
                      onSelectDate: () => state.selectDate(context),
                    ),
                    ..._buildIdentityDocuments(
                      cifNumberController: state.cifNumberController,
                      aadhaarNumberController: state.aadhaarNumberController,
                      panNumberController: state.panNumberController,
                    ),
                    ..._buildSavingsBank(
                      savingsAccountNumberController:
                          state.savingsAccountNumberController,
                      nominees: state.nominees,
                    ),
                    ..._buildNotes(
                      notesController: state.notesController,
                    ),
                    FilledButton.icon(
                      onPressed: state.isSaving.value
                          ? null
                          : () => state.save(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppDimensions.buttonHeight,
                        ),
                      ),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: AppDimensions.iconMd,
                      ),
                      label: Text(
                        state.isSaving.value ? t.common.saving : t.common.confirm,
                      ),
                    ),
                    AppSpacings.gapXl,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildPersonalInfo({
  required TextEditingController nameController,
  required TextEditingController phoneController,
  required TextEditingController emailController,
  required TextEditingController dateOfBirthController,
  required TextEditingController addressController,
  required VoidCallback onSelectDate,
}) {
  return [
    FormSectionHeader(
      title: t.customers.sections.personalInfo,
      padding: EdgeInsets.zero,
    ),
    AppSpacings.gapMd,
    AppTextField(
      controller: nameController,
      labelText: t.customers.fields.fullName,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        size: AppDimensions.iconMd,
      ),
      isRequired: true,
      validator: Customer.validateName,
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapMd,
    AppTextField(
      controller: phoneController,
      labelText: t.customers.fields.phoneNumber,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCall02,
        size: AppDimensions.iconMd,
      ),
      validator: Customer.validatePhone,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapMd,
    AppTextField(
      controller: emailController,
      labelText: t.customers.fields.emailAddress,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedMail01,
        size: AppDimensions.iconMd,
      ),
      validator: Customer.validateEmail,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapMd,
    AppDateField(
      controller: dateOfBirthController,
      labelText: t.customers.fields.dateOfBirth,
      onTap: onSelectDate,
    ),
    AppSpacings.gapMd,
    AppTextField(
      controller: addressController,
      labelText: t.customers.fields.homeAddress,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedHome01,
        size: AppDimensions.iconMd,
      ),
      maxLines: AppConstants.addressMaxLines,
    ),
  ];
}

List<Widget> _buildIdentityDocuments({
  required TextEditingController cifNumberController,
  required TextEditingController aadhaarNumberController,
  required TextEditingController panNumberController,
}) {
  return [
    FormSectionHeader(title: t.customers.sections.identityDocuments),
    AppTextField(
      controller: cifNumberController,
      labelText: t.customers.fields.cif,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedTicket01,
        size: AppDimensions.iconMd,
      ),
      validator: Customer.validateCif,
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapMd,
    AppTextField(
      controller: aadhaarNumberController,
      labelText: t.customers.fields.aadhaarNumber,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedId,
        size: AppDimensions.iconMd,
      ),
      validator: Customer.validateAadhaar,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapMd,
    AppTextField(
      controller: panNumberController,
      labelText: t.customers.fields.panNumber,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCreditCard,
        size: AppDimensions.iconMd,
      ),
      validator: Customer.validatePan,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: const [UpperCaseTextFormatter()],
      textInputAction: TextInputAction.next,
    ),
  ];
}

List<Widget> _buildSavingsBank({
  required TextEditingController savingsAccountNumberController,
  required ValueNotifier<List<Nominee>> nominees,
}) {
  return [
    FormSectionHeader(title: t.customers.sections.savingsBank),
    AppTextField(
      controller: savingsAccountNumberController,
      labelText: t.customers.fields.sbAccountNumber,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedBank,
        size: AppDimensions.iconMd,
      ),
      validator: (val) => Customer.validateSavingsAccount(val, nominees.value),
      textInputAction: TextInputAction.next,
    ),
    NomineesInputSection(
      nominees: nominees.value,
      onChanged: (newNominees) {
        nominees.value = newNominees;
      },
    ),
    AppSpacings.gapXxl,
  ];
}

List<Widget> _buildNotes({
  required TextEditingController notesController,
}) {
  return [
    FormSectionHeader(title: t.customers.fields.notes),
    AppTextField(
      controller: notesController,
      labelText: t.customers.fields.notes,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedNote01,
        size: AppDimensions.iconMd,
      ),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 3,
      maxLines: null,
    ),
    AppSpacings.gapXxl,
  ];
}
