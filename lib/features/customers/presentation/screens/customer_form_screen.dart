import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/domain/nominees_input_section.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/form_app_bar.dart';

import 'package:postfolio/features/customers/presentation/hooks/use_customer_form.dart';
import 'package:postfolio/i18n/strings.g.dart';

class CustomerFormScreen extends ConsumerWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<Customer>(
      state: ref.watch(customersControllerProvider),
      entityId: customerId,
      idSelector: (c) => c.id,
      notFoundMessage: t.customers.customerNotFound,
      onRetry: () => ref.invalidate(customersControllerProvider),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        state.handleBack(context);
      },
      child: Scaffold(
        appBar: FormAppBar(
          title: state.isUpdating
              ? t.customers.editCustomer
              : t.customers.newCustomer,
          isSaving: state.isSaving.value,
          onSave: () => state.save(context),
          onBack: () => state.handleBack(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Form(
            key: state.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
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
