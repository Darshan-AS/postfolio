import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
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

class OneTimeDepositFormScreen extends ConsumerWidget {
  final String? depositId;

  const OneTimeDepositFormScreen({super.key, this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<OneTimeDeposit>(
      state: ref.watch(oneTimeDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.oneTimeDeposits.depositNotFound,
      onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
      builder: (deposit) => _OneTimeDepositForm(existingDeposit: deposit),
    );
  }
}

class _OneTimeDepositForm extends HookConsumerWidget {
  final OneTimeDeposit? existingDeposit;

  const _OneTimeDepositForm({this.existingDeposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final deposit = existingDeposit;
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

    final selectedCustomerId = useState<String?>(deposit?.customerId);
    final selectedScheme = useState<OneTimeSchemeType>(
      deposit?.schemeType ?? OneTimeSchemeType.timeDeposit,
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
                  selectedScheme.value.tenureInputType ==
                      TenureInputType.derived
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
            if (isUpdating) {
              OneTimeDepositDetailRoute(deposit.id).go(context);
            } else {
              const OneTimeDepositsRoute().go(context);
            }
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

    void handleBack() {
      if (isUpdating) {
        OneTimeDepositDetailRoute(deposit.id).go(context);
      } else {
        const OneTimeDepositsRoute().go(context);
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
              ? t.oneTimeDeposits.editDeposit
              : t.oneTimeDeposits.newDeposit,
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
                accountNoController: accountNoController,
                selectedStatus: selectedStatus,
              ),
              ..._buildInvestmentDetails(
                context,
                selectedScheme: selectedScheme,
                selectedTermYears: selectedTermYears,
                selectedTermMonths: selectedTermMonths,
                principalAmountController: principalAmountController,
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
  required TextEditingController accountNoController,
  required ValueNotifier<DepositStatus> selectedStatus,
}) {
  return [
    FormSectionHeader(
      title: t.oneTimeDeposits.sections.accountInformation,
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
      controller: accountNoController,
      labelText: t.oneTimeDeposits.fields.accountNo,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedTicket01,
        size: AppDimensions.iconMd,
      ),
      validator: OneTimeDeposit.validateAccountNo,
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapLg,
    AppSegmentedButtonField<DepositStatus>(
      value: selectedStatus.value,
      labelText: t.oneTimeDeposits.fields.status,
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
  required ValueNotifier<OneTimeSchemeType> selectedScheme,
  required ValueNotifier<int> selectedTermYears,
  required ValueNotifier<int> selectedTermMonths,
  required TextEditingController principalAmountController,
  required TextEditingController interestRateController,
  required ValueNotifier<DateTime> startDate,
  required TextEditingController startDateController,
  required InvestmentProjection projection,
}) {
  return [
    FormSectionHeader(title: t.oneTimeDeposits.sections.investmentDetails),
    AppDropdownField<OneTimeSchemeType>(
      value: selectedScheme.value,
      labelText: t.oneTimeDeposits.fields.schemeType,
      items: OneTimeSchemeType.values
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
      controller: principalAmountController,
      labelText: t.oneTimeDeposits.fields.principalAmount,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCoins01,
        size: AppDimensions.iconMd,
      ),
      isRequired: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) => OneTimeDeposit.validateAmount(
        double.tryParse(val ?? ''),
        t.oneTimeDeposits.fields.principalAmount,
      ),
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapLg,
    AppTextField(
      controller: interestRateController,
      labelText: t.oneTimeDeposits.fields.interestRate,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedPercent,
        size: AppDimensions.iconMd,
      ),
      isRequired: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) => OneTimeDeposit.validateInterestRate(
        double.tryParse(val ?? ''),
        t.oneTimeDeposits.fields.interestRate,
      ),
      textInputAction: TextInputAction.next,
    ),
    AppSpacings.gapLg,
    AppDateField(
      controller: startDateController,
      labelText: t.oneTimeDeposits.fields.startDate,
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
      derivedString: projection is WealthAccumulation ? projection.note : null,
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
