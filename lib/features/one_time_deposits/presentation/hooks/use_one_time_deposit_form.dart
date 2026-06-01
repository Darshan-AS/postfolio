import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

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
  final VoidCallback save;
  final VoidCallback handleBack;
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
    required this.save,
    required this.handleBack,
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

  final accountNoController = useTextEditingController(
    text: deposit?.accountNo,
  );
  final principalAmountController = useTextEditingController(
    text: deposit?.principalAmount.round().toString(),
  );
  final interestRateController = useTextEditingController(
    text: deposit?.interestRate.toString(),
  );

  final selectedCustomerId = useState<String?>(
    deposit?.customerId ?? initialCustomerId,
  );
  final selectedScheme = useState<OneTimeSchemeType>(
    deposit?.schemeType ?? OneTimeSchemeType.timeDeposit,
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
  useListenable(principalAmountController);
  useListenable(interestRateController);

  final currentPrincipal =
      double.tryParse(principalAmountController.text.trim()) ?? 0.0;
  final currentInterest =
      double.tryParse(interestRateController.text.trim()) ?? 0.0;

  final projection = useMemoized(
    () {
      return ProjectionCalculator.calculateOneTimeDeposit(
        schemeType: selectedScheme.value,
        principalAmount: currentPrincipal,
        interestRate: currentInterest,
        startDate: startDate.value,
        termYears: selectedTermYears.value,
      );
    },
    [
      currentPrincipal,
      currentInterest,
      startDate.value,
      selectedTermYears.value,
      selectedScheme.value,
    ],
  );

  // Keep hidden state in sync for derived tenures like KVP
  useEffect(() {
    if (selectedScheme.value.tenureInputType == TenureInputType.derived) {
      final timeInMonths = ProjectionCalculator.calculateKvpTermMonths(
        currentInterest,
      );
      final years = timeInMonths ~/ 12;
      final months = timeInMonths % 12;

      if (selectedTermYears.value != years ||
          selectedTermMonths.value != months) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          selectedTermYears.value = years;
          selectedTermMonths.value = months;
        });
      }
    }
    return null;
  }, [selectedScheme.value, currentInterest]);

  void handleBack() {
    if (isUpdating) {
      OneTimeDepositDetailRoute(deposit.id).go(context);
    } else if (initialCustomerId != null) {
      CustomerDetailRoute(initialCustomerId).go(context);
    } else {
      const OneTimeDepositsRoute().go(context);
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

      isSaving.value = true;
      final result = await ref
          .read(oneTimeDepositsControllerProvider.notifier)
          .saveOneTimeDeposit(
            id: deposit?.id,
            accountNo: accountNoController.text,
            principalAmount: principalAmountController.text,
            termYears: selectedTermYears.value,
            termMonths:
                selectedScheme.value.tenureInputType == TenureInputType.derived
                ? selectedTermMonths.value
                : 0,
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
          handleBack();
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
    save: save,
    handleBack: handleBack,
    isUpdating: isUpdating,
  );
}
