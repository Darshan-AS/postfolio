import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/domain/nominees_input_section.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/form_app_bar.dart';
import 'package:postfolio/core/widgets/forms/app_duration_input.dart';
import 'package:postfolio/core/widgets/domain/investment_projection_card.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

import 'package:postfolio/features/recurring_deposits/presentation/hooks/use_recurring_deposit_form.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RecurringDepositFormScreen extends ConsumerWidget {
  final String? depositId;
  final String? initialCustomerId;

  const RecurringDepositFormScreen({
    super.key,
    this.depositId,
    this.initialCustomerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<RecurringDeposit>(
      state: ref.watch(recurringDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
      builder: (deposit) => _RecurringDepositForm(
        existingDeposit: deposit,
        initialCustomerId: initialCustomerId,
      ),
    );
  }
}

class _RecurringDepositForm extends HookConsumerWidget {
  final RecurringDeposit? existingDeposit;
  final String? initialCustomerId;

  const _RecurringDepositForm({this.existingDeposit, this.initialCustomerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = useRecurringDepositForm(
      context: context,
      ref: ref,
      deposit: existingDeposit,
      initialCustomerId: initialCustomerId,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        state.handleBack();
      },
      child: Scaffold(
        appBar: FormAppBar(
          title: state.isUpdating
              ? t.recurringDeposits.editDeposit
              : t.recurringDeposits.newDeposit,
          isSaving: state.isSaving.value,
          onSave: state.save,
          onBack: state.handleBack,
        ),
        body: Form(
          key: state.formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              ..._buildAccountInformation(
                selectedCustomerId: state.selectedCustomerId,
                serialNoController: state.serialNoController,
                accountNoController: state.accountNoController,
                selectedStatus: state.selectedStatus,
              ),
              ..._buildInvestmentDetails(
                context,
                selectedScheme: state.selectedScheme,
                selectedTermYears: state.selectedTermYears,
                selectedTermMonths: state.selectedTermMonths,
                installmentAmountController: state.installmentAmountController,
                interestRateController: state.interestRateController,
                startDate: state.startDate,
                startDateController: state.startDateController,
                projection: state.projection,
              ),
              ..._buildNomineesSection(nominees: state.nominees),
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
