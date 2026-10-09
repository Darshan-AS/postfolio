import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/postal_scheme_terms.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:number_to_indian_words/number_to_indian_words.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:postfolio/core/constants/app_constants.dart';

class OneTimeDepositFormState {
  final GlobalKey<FormState> formKey;
  final TextEditingController accountNoController;
  final TextEditingController principalAmountController;
  final TextEditingController interestRateController;
  final TextEditingController startDateController;
  final ValueNotifier<String?> selectedCustomerId;
  final ValueNotifier<OneTimeSchemeType> selectedScheme;
  final ValueNotifier<int> selectedTermYears;
  final ValueNotifier<int> selectedTermMonths;
  final ValueNotifier<DepositStatus> selectedStatus;
  final ValueNotifier<DateTime> startDate;
  final ValueNotifier<List<Nominee>> nominees;
  final ValueNotifier<bool> isSaving;
  final InvestmentProjection projection;
  final String amountInWords;
  final CurrencyTextInputFormatter amountFormatter;
  final void Function(OneTimeSchemeType scheme) onSchemeChanged;
  final void Function(DateTime pickedDate) onStartDateChanged;
  final void Function(int years, int months) onDurationChanged;
  final void Function(String val) onInterestRateChanged;
  final VoidCallback save;
  final bool isUpdating;

  OneTimeDepositFormState({
    required this.formKey,
    required this.accountNoController,
    required this.principalAmountController,
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
    required this.onSchemeChanged,
    required this.onStartDateChanged,
    required this.onDurationChanged,
    required this.onInterestRateChanged,
    required this.save,
    required this.isUpdating,
  });
}

OneTimeDepositFormState useOneTimeDepositForm({
  required BuildContext context,
  required WidgetRef ref,
  OneTimeDeposit? deposit,
  String? initialCustomerId,
}) {
  final formKey = useMemoized(() => GlobalKey<FormState>());
  final isUpdating = deposit != null;
  final postalRateService = ref.watch(postalRateServiceProvider);

  final amountFormatter = useMemoized(
    () => CurrencyTextInputFormatter.currency(
      locale: AppConstants.defaultLocale,
      symbol: '',
      decimalDigits: 0,
    ),
  );

  final initialScheme = deposit?.schemeType ?? OneTimeSchemeType.timeDeposit;
  final initialStartDate = deposit?.startDate ?? DateTime.now();
  final initialTerms = postalRateService.resolveOneTimeSchemeTerms(
    schemeType: initialScheme,
    startDate: initialStartDate,
    tdTenureYears: deposit?.termYears ?? initialScheme.defaultTenureYears,
  );

  final accountNoController = useTextEditingController(
    text: deposit?.accountNo,
  );
  final principalAmountController = useTextEditingController(
    text: deposit != null
        ? amountFormatter.formatDouble(deposit.principalAmount)
        : '',
  );
  final interestRateController = useTextEditingController(
    text: (deposit?.interestRate ?? initialTerms.interestRate).toStringAsFixed(
      2,
    ),
  );

  final selectedCustomerId = useState<String?>(
    deposit?.customerId ?? initialCustomerId,
  );
  final selectedScheme = useState<OneTimeSchemeType>(initialScheme);
  final selectedTermYears = useState<int>(
    deposit?.termYears ?? initialTerms.termYears,
  );
  final selectedTermMonths = useState<int>(
    deposit?.termMonths ?? initialTerms.termMonths,
  );
  final selectedStatus = useState<DepositStatus>(
    deposit?.status ?? DepositStatus.active,
  );
  final startDate = useState<DateTime>(initialStartDate);
  final nominees = useState<List<Nominee>>(deposit?.nominees.toList() ?? []);

  final isSaving = useState(false);

  final startDateController = useTextEditingController(
    text: startDate.value.toAppFormat(),
  );

  // Live Projection Calculation
  useListenable(principalAmountController);
  useListenable(interestRateController);

  final amountInWords = useMemoized(() {
    if (principalAmountController.text.trim().isEmpty) return '';

    final cleaned = principalAmountController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final number =
        int.tryParse(cleaned) ?? amountFormatter.getUnformattedValue().toInt();
    if (number > 0) {
      final words = NumToWords.convertNumberToIndianWords(number);
      return words;
    }
    return '';
  }, [principalAmountController.text]);

  final cleanedPrincipalStr = principalAmountController.text.replaceAll(
    RegExp(r'[^0-9.]'),
    '',
  );
  final currentPrincipal =
      double.tryParse(cleanedPrincipalStr) ??
      amountFormatter.getUnformattedValue().toDouble();
  final currentRate = double.tryParse(interestRateController.text.trim()) ?? 0.0;

  final projection = useMemoized(
    () {
      return ProjectionCalculator.calculateOneTimeDeposit(
        schemeType: selectedScheme.value,
        principalAmount: currentPrincipal,
        interestRate: currentRate,
        startDate: startDate.value,
        termYears: selectedTermYears.value,
        termMonths: selectedTermMonths.value,
      );
    },
    [
      currentPrincipal,
      currentRate,
      selectedTermYears.value,
      selectedTermMonths.value,
      startDate.value,
      selectedScheme.value,
    ],
  );

  void syncTermsFromSchedule({
    required OneTimeSchemeType scheme,
    required DateTime date,
    int? tdYears,
  }) {
    final PostalSchemeTerms terms = postalRateService.resolveOneTimeSchemeTerms(
      schemeType: scheme,
      startDate: date,
      tdTenureYears: tdYears ?? scheme.defaultTenureYears,
    );
    interestRateController.text = terms.interestRate.toStringAsFixed(2);
    selectedTermYears.value = terms.termYears;
    selectedTermMonths.value = terms.termMonths;
  }

  void onSchemeChanged(OneTimeSchemeType scheme) {
    selectedScheme.value = scheme;
    syncTermsFromSchedule(
      scheme: scheme,
      date: startDate.value,
      tdYears: scheme.defaultTenureYears,
    );
  }

  void onStartDateChanged(DateTime pickedDate) {
    startDate.value = pickedDate;
    startDateController.text = pickedDate.toAppFormat();
    syncTermsFromSchedule(
      scheme: selectedScheme.value,
      date: pickedDate,
      tdYears: selectedTermYears.value,
    );
  }

  void onDurationChanged(int years, int months) {
    selectedTermYears.value = years;
    selectedTermMonths.value = months;
    if (selectedScheme.value == OneTimeSchemeType.timeDeposit) {
      syncTermsFromSchedule(
        scheme: selectedScheme.value,
        date: startDate.value,
        tdYears: years,
      );
    }
  }

  void onInterestRateChanged(String val) {
    if (selectedScheme.value == OneTimeSchemeType.kisanVikasPatra) {
      final parsedRate = double.tryParse(val);
      if (parsedRate != null && parsedRate > 0) {
        final kvpMonths = postalRateService.calculateKvpTermMonths(
          parsedRate,
          startDate: startDate.value,
        );
        selectedTermYears.value = kvpMonths ~/ 12;
        selectedTermMonths.value = kvpMonths % 12;
      }
    }
  }

  Future<void> save() async {
    if (formKey.currentState!.validate()) {
      if (selectedCustomerId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.oneTimeDeposits.selectCustomerPrompt)),
        );
        return;
      }

      final cleanedAmountStr = principalAmountController.text.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      final principalAmountVal = cleanedAmountStr.isNotEmpty
          ? cleanedAmountStr
          : amountFormatter.getUnformattedValue().toString();

      isSaving.value = true;
      final result = await ref
          .read(oneTimeDepositsControllerProvider.notifier)
          .saveOneTimeDeposit(
            id: deposit?.id,
            accountNo: accountNoController.text,
            principalAmount: principalAmountVal,
            termYears: selectedTermYears.value,
            termMonths: selectedTermMonths.value,
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
                t.oneTimeDeposits.failedToSaveDeposit(error: err.toString()),
              ),
            ),
          );
      }
    }
  }

  return OneTimeDepositFormState(
    formKey: formKey,
    accountNoController: accountNoController,
    principalAmountController: principalAmountController,
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
    onSchemeChanged: onSchemeChanged,
    onStartDateChanged: onStartDateChanged,
    onDurationChanged: onDurationChanged,
    onInterestRateChanged: onInterestRateChanged,
    save: save,
    isUpdating: isUpdating,
  );
}
