import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/models/nominee.dart';

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

class CustomerFormScreen extends ConsumerWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customerId == null) {
      return const _CustomerForm(existingCustomer: null);
    }

    final customersState = ref.watch(customersControllerProvider);

    return customersState.when(
      data: (customers) {
        final customer = customers.where((u) => u.id == customerId).firstOrNull;
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t.common.error)),
            body: ErrorStateView(message: t.customers.customerNotFound),
          );
        }
        return _CustomerForm(existingCustomer: customer);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(t.common.loading)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(t.common.error)),
        body: ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(customersControllerProvider),
        ),
      ),
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

  final List<_NomineeFormModel> _nomineeForms = [];

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

    final nominees = customer?.savingsAccount?.nominees ?? [];
    if (nominees.isNotEmpty) {
      _nomineeForms.addAll(
        nominees.map(
          (n) => _NomineeFormModel(
            name: n.name,
            relationship: n.relationship,
            percentage: n.percentage,
          ),
        ),
      );
    }

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
    for (final form in _nomineeForms) {
      form.dispose();
    }
    super.dispose();
  }

  void _addNominee() {
    setState(() {
      _nomineeForms.add(_NomineeFormModel());
    });
  }

  void _removeNominee(int index) {
    setState(() {
      final form = _nomineeForms.removeAt(index);
      form.dispose();
    });
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
            savingsNominees: _nomineeForms
                .map(
                  (f) => Nominee(
                    name: f.nameController.text.trim(),
                    relationship: f.relationshipController.text.trim(),
                    percentage:
                        double.tryParse(f.percentageController.text.trim()) ??
                        100,
                  ),
                )
                .toList(),
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
      appBar: AppBar(
        title: Text(
          isUpdating ? t.customers.editCustomer : t.customers.newCustomer,
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
              ),
              child: Center(
                child: SizedBox(
                  width: AppDimensions.iconMd,
                  height: AppDimensions.iconMd,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              color: AppTheme.primary,
              onPressed: _save,
              tooltip: t.customers.saveCustomer,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t.customers.fields.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: Customer.validateName,
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: t.customers.fields.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: Customer.validatePhone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: t.customers.fields.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: Customer.validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _cifNumberController,
                decoration: InputDecoration(
                  labelText: 'CIF',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _dateOfBirthController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: t.customers.fields.homeAddress,
                  prefixIcon: const Icon(Icons.home_outlined),
                ),
                maxLines: 3,
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _aadhaarNumberController,
                decoration: InputDecoration(
                  labelText: 'Aadhaar',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _panNumberController,
                decoration: InputDecoration(
                  labelText: 'PAN',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                ),
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              TextFormField(
                controller: _savingsAccountNumberController,
                decoration: const InputDecoration(
                  labelText: 'SB Account No.',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              AppSpacings.gapMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.customers.fields.nominees,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addNominee,
                    icon: const Icon(Icons.add),
                    label: Text(t.customers.fields.addNominee),
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _nomineeForms.length,
                itemBuilder: (context, index) {
                  final form = _nomineeForms[index];
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.paddingMd,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingMd),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${t.customers.fields.nominees} ${index + 1}',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.error,
                                ),
                                onPressed: () => _removeNominee(index),
                              ),
                            ],
                          ),
                          AppSpacings.gapSm,
                          TextFormField(
                            controller: form.nameController,
                            decoration: InputDecoration(
                              labelText: t.customers.fields.nomineeName,
                              prefixIcon: const Icon(Icons.person_pin_outlined),
                            ),
                            validator: Customer.validateName,
                          ),
                          AppSpacings.gapSm,
                          TextFormField(
                            controller: form.relationshipController,
                            decoration: InputDecoration(
                              labelText: t.customers.fields.relationship,
                              prefixIcon: const Icon(Icons.people_alt_outlined),
                            ),
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          AppSpacings.gapSm,
                          TextFormField(
                            controller: form.percentageController,
                            decoration: InputDecoration(
                              labelText: t.customers.fields.percentage,
                              prefixIcon: const Icon(Icons.percent_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0 || val > 100) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              AppSpacings.gapXxl,
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.customers.saveCustomer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
