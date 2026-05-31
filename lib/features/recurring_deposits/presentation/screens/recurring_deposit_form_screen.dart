import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/nominees_input_section.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
import 'package:postfolio/core/widgets/form_app_bar.dart';
import 'package:postfolio/core/widgets/app_duration_input.dart';
import 'package:postfolio/core/widgets/investment_projection_card.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

class RecurringDepositFormScreen extends ConsumerWidget {
  final String? depositId;
  final String? initialCustomerId;

  const RecurringDepositFormScreen({super.key, this.depositId, this.initialCustomerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<RecurringDeposit>(
      state: ref.watch(recurringDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
      builder: (deposit) => _RecurringDepositForm(existingDeposit: deposit, initialCustomerId: initialCustomerId),
    );
  }
}

class _RecurringDepositForm extends HookConsumerWidget {
  final RecurringDeposit? existingDeposit;
  final String? initialCustomerId;

  const _RecurringDepositForm({this.existingDeposit, this.initialCustomerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final deposit = existingDeposit;
    final isUpdating = deposit != null;

    final serialNoController = useTextEditingController(
      text: deposit?.serialNo,
    );
    final accountNoController = useTextEditingController(
      text: deposit?.accountNo,
    );
    final installmentAmountController = useTextEditingController(
      text: deposit?.installmentAmount.round().toString(),
    );
    final interestRateController = useTextEditingController(
      text: deposit?.interestRate.toString(),
    );

    final selectedCustomerId = useState<String?>(deposit?.customerId ?? initialCustomerId);
    final selectedScheme = useState<RecurringSchemeType>(
      deposit?.schemeType ?? RecurringSchemeType.recurringDeposit,
    );

    // Default values if not updating
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

    final currentInstallment =
        double.tryParse(installmentAmountController.text.trim()) ?? 0.0;
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

    void handleBack() {
      if (isUpdating) {
        RecurringDepositDetailRoute(deposit.id).go(context);
      } else if (initialCustomerId != null) {
        CustomerDetailRoute(initialCustomerId!).go(context);
      } else {
        const RecurringDepositsRoute().go(context);
      }
    }

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
              installmentAmount: installmentAmountController.text,
              termYears: selectedTermYears.value,
              termMonths:
                  selectedScheme.value.tenureInputType ==
                      TenureInputType.derived
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
            handleBack();
          case Failure(error: final err):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.recurringDeposits.failedToSaveDeposit(
                    error: err.toString(),
                  ),
                ),
              ),
            );
        }
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        appBar: FormAppBar(
          title: isUpdating
              ? t.recurringDeposits.editDeposit
              : t.recurringDeposits.newDeposit,
          isSaving: isSaving.value,
          onSave: save,
          onBack: handleBack,
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              ..._buildAccountInformation(
                selectedCustomerId: selectedCustomerId,
                serialNoController: serialNoController,
                accountNoController: accountNoController,
                selectedStatus: selectedStatus,
              ),
              ..._buildInvestmentDetails(
                context,
                selectedScheme: selectedScheme,
                selectedTermYears: selectedTermYears,
                selectedTermMonths: selectedTermMonths,
                installmentAmountController: installmentAmountController,
                interestRateController: interestRateController,
                startDate: startDate,
                startDateController: startDateController,
                projection: projection,
              ),
              ..._buildNomineesSection(nominees: nominees),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildAccountInformation({
  required ValueNotifier<String?> selectedCustomerId,
  required TextEditingController serialNoController,
  required TextEditingController accountNoController,
  required ValueNotifier<DepositStatus> selectedStatus,
}) {
  return [
    FormSectionHeader(
      title: t.recurringDeposits.sections.accountInformation,
      padding: EdgeInsets.zero,
    ),
    AppSpacings.gapMd,
    CustomerSelectionField(
      initialCustomerId: selectedCustomerId.value,
      onCustomerSelected: (customer) {
        selectedCustomerId.value = customer?.id;
      },
    ),
    AppSpacings.gapLg,
    AppTextField(
      controller: serialNoController,
      labelText: t.recurringDeposits.fields.serialNo,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedTag01,
        size: AppDimensions.iconMd,
      ),
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapLg,
    AppTextField(
      controller: accountNoController,
      labelText: t.recurringDeposits.fields.accountNo,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedTicket01,
        size: AppDimensions.iconMd,
      ),
      validator: RecurringDeposit.validateAccountNo,
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapLg,
    AppSegmentedButtonField<DepositStatus>(
      value: selectedStatus.value,
      labelText: t.recurringDeposits.fields.status,
      segments: DepositStatus.values
          .map(
            (status) =>
                ButtonSegment(value: status, label: Text(status.displayName)),
          )
          .toList(),
      onChanged: (status) {
        selectedStatus.value = status;
      },
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedActivity01,
        size: AppDimensions.iconMd,
      ),
    ),
  ];
}

List<Widget> _buildInvestmentDetails(
  BuildContext context, {
  required ValueNotifier<RecurringSchemeType> selectedScheme,
  required ValueNotifier<int> selectedTermYears,
  required ValueNotifier<int> selectedTermMonths,
  required TextEditingController installmentAmountController,
  required TextEditingController interestRateController,
  required ValueNotifier<DateTime> startDate,
  required TextEditingController startDateController,
  required InvestmentProjection projection,
}) {
  return [
    FormSectionHeader(title: t.recurringDeposits.sections.investmentDetails),
    AppDropdownField<RecurringSchemeType>(
      value: selectedScheme.value,
      labelText: t.recurringDeposits.fields.schemeType,
      items: RecurringSchemeType.values
          .map(
            (scheme) => DropdownMenuItem(
              value: scheme,
              child: Text(scheme.displayName),
            ),
          )
          .toList(),
      onChanged: (scheme) {
        if (scheme != null) {
          selectedScheme.value = scheme;
          selectedTermYears.value = scheme.defaultTenureYears;
        }
      },
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedLayers01,
        size: AppDimensions.iconMd,
      ),
    ),
    AppSpacings.gapLg,
    AppTextField(
      controller: installmentAmountController,
      labelText: t.recurringDeposits.fields.installmentAmount,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCoins01,
        size: AppDimensions.iconMd,
      ),
      isRequired: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) => RecurringDeposit.validateAmount(
        double.tryParse(val ?? ''),
        t.recurringDeposits.fields.installmentAmount,
      ),
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapLg,
    AppTextField(
      controller: interestRateController,
      labelText: t.recurringDeposits.fields.interestRate,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedPercent,
        size: AppDimensions.iconMd,
      ),
      isRequired: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) => RecurringDeposit.validateInterestRate(
        double.tryParse(val ?? ''),
        t.recurringDeposits.fields.interestRate,
      ),
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapLg,
    AppDateField(
      controller: startDateController,
      labelText: t.recurringDeposits.fields.startDate,
      isRequired: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: startDate.value,
          firstDate: DateTime(AppConstants.firstStartYear),
          lastDate: DateTime(AppConstants.lastDatePickerYear),
        );
        if (picked != null) {
          startDate.value = picked;
          if (context.mounted) {
            startDateController.text = picked.toAppFormat();
          }
        }
      },
    ),
    AppSpacings.gapLg,
    AppDurationInput(
      tenureInputType: selectedScheme.value.tenureInputType,
      allowedTenuresInYears: selectedScheme.value.allowedTenuresInYears,
      selectedYears: selectedTermYears.value,
      selectedMonths: selectedTermMonths.value,
      onChanged: (years, months) {
        selectedTermYears.value = years;
        selectedTermMonths.value = months;
      },
    ),
    AppSpacings.gapXl,
    InvestmentProjectionCard(projection: projection),
  ];
}

List<Widget> _buildNomineesSection({
  required ValueNotifier<List<Nominee>> nominees,
}) {
  return [
    NomineesInputSection(
      nominees: nominees.value,
      onChanged: (newNominees) {
        nominees.value = newNominees;
      },
    ),
    AppSpacings.gapXxl,
  ];
}
