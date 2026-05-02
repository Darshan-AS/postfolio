import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/nominees_input_section.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
import 'package:postfolio/core/widgets/form_app_bar.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

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
    final formKey = useMemoized(() => GlobalKey<FormState>());
    
    final customer = existingCustomer;
    
    final nameController = useTextEditingController(text: customer?.name);
    final emailController = useTextEditingController(text: customer?.email);
    final phoneController = useTextEditingController(text: customer?.phone);
    final addressController = useTextEditingController(text: customer?.address);
    final cifNumberController = useTextEditingController(text: customer?.cifNumber);
    final aadhaarNumberController = useTextEditingController(text: customer?.aadhaarNumber);
    final panNumberController = useTextEditingController(text: customer?.panNumber);
    final savingsAccountNumberController = useTextEditingController(
      text: customer?.savingsAccount?.accountNumber,
    );

    final nominees = useState<List<Nominee>>(List.of(customer?.savingsAccount?.nominees ?? []));
    final selectedDate = useState<DateTime?>(customer?.dateOfBirth);
    final dateOfBirthController = useTextEditingController(
      text: selectedDate.value != null
          ? selectedDate.value!.toAppFormat()
          : '',
    );
    
    final isSaving = useState(false);

    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != selectedDate.value) {
        selectedDate.value = picked;
        dateOfBirthController.text = picked.toAppFormat();
      }
    }

    Future<void> save() async {
      if (formKey.currentState!.validate()) {
        isSaving.value = true;
        final result = await ref
            .read(customersControllerProvider.notifier)
            .saveCustomer(
              id: customer?.id,
              name: nameController.text.trim(),
              email: emailController.text.trim().isEmpty
                  ? null
                  : emailController.text.trim(),
              phone: phoneController.text.trim().isEmpty
                  ? null
                  : phoneController.text.trim(),
              address: addressController.text.trim().isEmpty
                  ? null
                  : addressController.text.trim(),
              cifNumber: cifNumberController.text.trim().isEmpty
                  ? null
                  : cifNumberController.text.trim(),
              dateOfBirth: selectedDate.value,
              aadhaarNumber: aadhaarNumberController.text.trim().isEmpty
                  ? null
                  : aadhaarNumberController.text.trim(),
              panNumber: panNumberController.text.trim().isEmpty
                  ? null
                  : panNumberController.text.trim(),
              savingsAccountNumber:
                  savingsAccountNumberController.text.trim().isEmpty
                  ? null
                  : savingsAccountNumberController.text.trim(),
              savingsNominees: nominees.value,
            );

        if (!context.mounted) return;
        isSaving.value = false;

        switch (result) {
          case Success():
            context.pop();
          case Failure(error: final err):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.customers.failedToSaveCustomer(error: err.toString()),
                ),
              ),
            );
        }
      }
    }

    final isUpdating = customer != null;

    return Scaffold(
      appBar: FormAppBar(
        title: isUpdating ? t.customers.editCustomer : t.customers.newCustomer,
        isSaving: isSaving.value,
        onSave: save,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.customers.sections.personalInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
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
                onTap: () => selectDate(context),
              ),
              AppSpacings.gapMd,
              AppTextField(
                controller: addressController,
                labelText: t.customers.fields.homeAddress,
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedHome01,
                  size: AppDimensions.iconMd,
                ),
                maxLines: 3,
              ),
              AppSpacings.gapXl,
              Text(
                t.customers.sections.identityDocuments,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapMd,
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
              AppSpacings.gapXl,
              Text(
                t.customers.sections.savingsBank,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapMd,
              AppTextField(
                controller: savingsAccountNumberController,
                labelText: t.customers.fields.sbAccountNumber,
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedBank,
                  size: AppDimensions.iconMd,
                ),
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              NomineesInputSection(
                nominees: nominees.value,
                onChanged: (newNominees) {
                  nominees.value = newNominees;
                },
              ),
              AppSpacings.gapXxl,
            ],
          ),
        ),
      ),
    );
  }
}
