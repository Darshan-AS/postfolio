import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

class CustomerFormState {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cifNumberController;
  final TextEditingController aadhaarNumberController;
  final TextEditingController panNumberController;
  final TextEditingController savingsAccountNumberController;
  final TextEditingController dateOfBirthController;
  final ValueNotifier<List<Nominee>> nominees;
  final ValueNotifier<bool> isSaving;
  final bool isUpdating;
  final Future<void> Function(BuildContext context) selectDate;
  final Future<void> Function(BuildContext context) save;

  CustomerFormState({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.cifNumberController,
    required this.aadhaarNumberController,
    required this.panNumberController,
    required this.savingsAccountNumberController,
    required this.dateOfBirthController,
    required this.nominees,
    required this.isSaving,
    required this.isUpdating,
    required this.selectDate,
    required this.save,
  });
}

CustomerFormState useCustomerForm({
  required WidgetRef ref,
  Customer? customer,
}) {
  final formKey = useMemoized(() => GlobalKey<FormState>());
  final isUpdating = customer != null;

  final nameController = useTextEditingController(text: customer?.name);
  final emailController = useTextEditingController(text: customer?.email);
  final phoneController = useTextEditingController(text: customer?.phone);
  final addressController = useTextEditingController(text: customer?.address);
  final cifNumberController = useTextEditingController(
    text: customer?.cifNumber,
  );
  final aadhaarNumberController = useTextEditingController(
    text: customer?.aadhaarNumber,
  );
  final panNumberController = useTextEditingController(
    text: customer?.panNumber,
  );
  final savingsAccountNumberController = useTextEditingController(
    text: customer?.savingsAccount?.accountNumber,
  );

  final nominees = useState<List<Nominee>>(
    List.of(customer?.savingsAccount?.nominees ?? []),
  );
  final selectedDate = useState<DateTime?>(customer?.dateOfBirth);
  final dateOfBirthController = useTextEditingController(
    text: selectedDate.value != null ? selectedDate.value!.toAppFormat() : '',
  );

  final isSaving = useState(false);

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(AppConstants.firstDatePickerYear),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
      dateOfBirthController.text = picked.toAppFormat();
    }
  }

  Future<void> save(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isSaving.value = true;
      final result = await ref
          .read(customersControllerProvider.notifier)
          .saveCustomer(
            id: customer?.id,
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            address: addressController.text,
            cifNumber: cifNumberController.text,
            dateOfBirth: selectedDate.value,
            aadhaarNumber: aadhaarNumberController.text,
            panNumber: panNumberController.text,
            savingsAccountNumber: savingsAccountNumberController.text,
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

  return CustomerFormState(
    formKey: formKey,
    nameController: nameController,
    emailController: emailController,
    phoneController: phoneController,
    addressController: addressController,
    cifNumberController: cifNumberController,
    aadhaarNumberController: aadhaarNumberController,
    panNumberController: panNumberController,
    savingsAccountNumberController: savingsAccountNumberController,
    dateOfBirthController: dateOfBirthController,
    nominees: nominees,
    isSaving: isSaving,
    isUpdating: isUpdating,
    selectDate: selectDate,
    save: save,
  );
}
