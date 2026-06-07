import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:number_to_indian_words/number_to_indian_words.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:postfolio/core/constants/app_constants.dart';

class RecurringDepositFormState {
  final GlobalKey<FormState> formKey;
  final TextEditingController serialNoController;
  final TextEditingController accountNoController;
  final TextEditingController installmentAmountController;
  final TextEditingController interestRateController;
  final TextEditingController startDateController;
  final ValueNotifier<String?> selectedCustomerId;
  final ValueNotifier<RecurringSchemeType> selectedScheme;
  final ValueNotifier<int> selectedTermYears;
  final ValueNotifier<int> selectedTermMonths;
  final ValueNotifier<DepositStatus> selectedStatus;
  final ValueNotifier<DateTime> startDate;
  final ValueNotifier<List<Nominee>> nominees;
  final ValueNotifier<bool> isSaving;
  final InvestmentProjection projection;
  final String amountInWords;
  final CurrencyTextInputFormatter amountFormatter;
  final VoidCallback save;
  final bool isUpdating;

  RecurringDepositFormState({
    required this.formKey,
    required this.serialNoController,
    required this.accountNoController,
    required this.installmentAmountController,
    required this.interestRateController,
    required this.startDateController,
    required this.selectedCustomerId,
    required this.selectedScheme,
    required this.selectedTermYears,
    required this.selectedTermMonths,
    required this.selectedStatus,
    required this.startDate,
    required this.nominees,
    required this.isSaving,
    required this.projection,
    required this.amountInWords,
    required this.amountFormatter,
    required this.save,
    required this.isUpdating,
  });
}

RecurringDepositFormState useRecurringDepositForm({
  required BuildContext context,
  required WidgetRef ref,
  RecurringDeposit? deposit,
  String? initialCustomerId,
}) {
  final formKey = useMemoized(() => GlobalKey<FormState>());
  final isUpdating = deposit != null;

  final amountFormatter = useMemoized(
    () => CurrencyTextInputFormatter.currency(
      locale: AppConstants.defaultLocale,
      symbol: '',
      decimalDigits: 0,
    ),
  );

  final serialNoController = useTextEditingController(text: deposit?.serialNo);
  final accountNoController = useTextEditingController(
    text: deposit?.accountNo,
  );
  final installmentAmountController = useTextEditingController(
    text: deposit != null
        ? amountFormatter.formatDouble(deposit.installmentAmount)
        : '',
  );
  final interestRateController = useTextEditingController(
    text: deposit?.interestRate.toString(),
  );

  final selectedCustomerId = useState<String?>(
    deposit?.customerId ?? initialCustomerId,
  );
  final selectedScheme = useState<RecurringSchemeType>(
    deposit?.schemeType ?? RecurringSchemeType.recurringDeposit,
  );

  final initialTermYears =
      deposit?.termYears ?? selectedScheme.value.defaultTenureYears;
  final initialTermMonths = deposit?.termMonths ?? 0;

  final selectedTermYears = useState<int>(initialTermYears);
  final selectedTermMonths = useState<int>(initialTermMonths);
  final selectedStatus = useState<DepositStatus>(
    deposit?.status ?? DepositStatus.active,
  );
  final startDate = useState<DateTime>(deposit?.startDate ?? DateTime.now());
  final nominees = useState<List<Nominee>>(deposit?.nominees.toList() ?? []);

  final isSaving = useState(false);

  final startDateController = useTextEditingController(
    text: startDate.value.toAppFormat(),
  );

  // Live Projection Calculation
  useListenable(installmentAmountController);
  useListenable(interestRateController);

  final amountInWords = useMemoized(() {
    if (installmentAmountController.text.trim().isEmpty) return '';

    final number = amountFormatter.getUnformattedValue().toInt();
    if (number > 0) {
      final words = NumToWords.convertNumberToIndianWords(number);
      return words;
    }
    return '';
  }, [installmentAmountController.text]);

  final currentInstallment = amountFormatter.getUnformattedValue().toDouble();
  final currentInterest =
      double.tryParse(interestRateController.text.trim()) ?? 0.0;

  final projection = useMemoized(
    () {
      return ProjectionCalculator.calculateRD(
        monthlyInstallment: currentInstallment,
        interestRate: currentInterest,
        startDate: startDate.value,
        termYears: selectedTermYears.value,
        termMonths: selectedTermMonths.value,
      );
    },
    [
      currentInstallment,
      currentInterest,
      startDate.value,
      selectedTermYears.value,
      selectedTermMonths.value,
    ],
  );

  Future<void> save() async {
    if (formKey.currentState!.validate()) {
      if (selectedCustomerId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.recurringDeposits.selectCustomerPrompt)),
        );
        return;
      }

      isSaving.value = true;
      final result = await ref
          .read(recurringDepositsControllerProvider.notifier)
          .saveRecurringDeposit(
            id: deposit?.id,
            serialNo: serialNoController.text,
            accountNo: accountNoController.text,
            installmentAmount: amountFormatter.getUnformattedValue().toString(),
            termYears: selectedTermYears.value,
            termMonths:
                selectedScheme.value.tenureInputType == TenureInputType.derived
                ? 0 // RD doesn't have derived, but keeping pattern
                : selectedTermMonths.value,
            interestRate: interestRateController.text,
            customerId: selectedCustomerId.value ?? '',
            schemeType: selectedScheme.value,
            status: selectedStatus.value,
            startDate: startDate.value,
            nominees: nominees.value,
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
                t.recurringDeposits.failedToSaveDeposit(error: err.toString()),
              ),
            ),
          );
      }
    }
  }

  return RecurringDepositFormState(
    formKey: formKey,
    serialNoController: serialNoController,
    accountNoController: accountNoController,
    installmentAmountController: installmentAmountController,
    interestRateController: interestRateController,
    startDateController: startDateController,
    selectedCustomerId: selectedCustomerId,
    selectedScheme: selectedScheme,
    selectedTermYears: selectedTermYears,
    selectedTermMonths: selectedTermMonths,
    selectedStatus: selectedStatus,
    startDate: startDate,
    nominees: nominees,
    isSaving: isSaving,
    projection: projection,
    amountInWords: amountInWords,
    amountFormatter: amountFormatter,
    save: save,
    isUpdating: isUpdating,
  );
}
