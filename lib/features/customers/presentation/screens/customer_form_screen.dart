import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:intl/intl.dart';

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

class _CustomerForm extends ConsumerStatefulWidget {
  final Customer? existingCustomer;

  const _CustomerForm({this.existingCustomer});

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cifNumberController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _aadhaarNumberController;
  late final TextEditingController _panNumberController;
  late final TextEditingController _savingsAccountNumberController;

  List<Nominee> _nominees = [];

  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.existingCustomer;
    _nameController = TextEditingController(text: customer?.name);
    _emailController = TextEditingController(text: customer?.email);
    _phoneController = TextEditingController(text: customer?.phone);
    _addressController = TextEditingController(text: customer?.address);
    _cifNumberController = TextEditingController(text: customer?.cifNumber);
    _aadhaarNumberController = TextEditingController(
      text: customer?.aadhaarNumber,
    );
    _panNumberController = TextEditingController(text: customer?.panNumber);
    _savingsAccountNumberController = TextEditingController(
      text: customer?.savingsAccount?.accountNumber,
    );

    _nominees = List.of(customer?.savingsAccount?.nominees ?? []);

    _selectedDate = customer?.dateOfBirth;
    _dateOfBirthController = TextEditingController(
      text: _selectedDate != null
          ? DateFormat.yMMMd().format(_selectedDate!)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cifNumberController.dispose();
    _dateOfBirthController.dispose();
    _aadhaarNumberController.dispose();
    _panNumberController.dispose();
    _savingsAccountNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = DateFormat.yMMMd().format(_selectedDate!);
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final result = await ref
          .read(customersControllerProvider.notifier)
          .saveCustomer(
            id: widget.existingCustomer?.id,
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            cifNumber: _cifNumberController.text.trim().isEmpty
                ? null
                : _cifNumberController.text.trim(),
            dateOfBirth: _selectedDate,
            aadhaarNumber: _aadhaarNumberController.text.trim().isEmpty
                ? null
                : _aadhaarNumberController.text.trim(),
            panNumber: _panNumberController.text.trim().isEmpty
                ? null
                : _panNumberController.text.trim(),
            savingsAccountNumber:
                _savingsAccountNumberController.text.trim().isEmpty
                ? null
                : _savingsAccountNumberController.text.trim(),
            savingsNominees: _nominees,
          );

      if (!mounted) return;
      setState(() => _isSaving = false);

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

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.existingCustomer != null;

    return Scaffold(
      appBar: FormAppBar(
        title: isUpdating ? t.customers.editCustomer : t.customers.newCustomer,
        isSaving: _isSaving,
        onSave: _save,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Form(
          key: _formKey,
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
                controller: _nameController,
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
                controller: _phoneController,
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
                controller: _emailController,
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
                controller: _dateOfBirthController,
                labelText: t.customers.fields.dateOfBirth,
                onTap: () => _selectDate(context),
              ),
              AppSpacings.gapMd,
              AppTextField(
                controller: _addressController,
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
                controller: _cifNumberController,
                labelText: t.customers.fields.cif,
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTicket01,
                  size: AppDimensions.iconMd,
                ),
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              AppTextField(
                controller: _aadhaarNumberController,
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
                controller: _panNumberController,
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
                controller: _savingsAccountNumberController,
                labelText: t.customers.fields.sbAccountNumber,
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedBank,
                  size: AppDimensions.iconMd,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapXl,
              NomineesInputSection(
                initialNominees: _nominees,
                onChanged: (newNominees) {
                  _nominees = newNominees;
                },
              ),
              AppSpacings.gapXxl,
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    AppDimensions.buttonHeight,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: AppDimensions.iconMd,
                        width: AppDimensions.iconMd,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.customers.saveCustomer),
              ),
              AppSpacings.gapXxl,
            ],
          ),
        ),
      ),
    );
  }
}
