import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
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

import 'package:postfolio/features/one_time_deposits/presentation/hooks/use_one_time_deposit_form.dart';
import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositFormScreen extends ConsumerWidget {
  final String? depositId;
  final String? initialCustomerId;

  const OneTimeDepositFormScreen({
    super.key,
    this.depositId,
    this.initialCustomerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<OneTimeDeposit>(
      state: ref.watch(oneTimeDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.oneTimeDeposits.depositNotFound,
      onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
      builder: (deposit) => _OneTimeDepositForm(
        existingDeposit: deposit,
        initialCustomerId: initialCustomerId,
      ),
    );
  }
}

class _OneTimeDepositForm extends HookConsumerWidget {
  final OneTimeDeposit? existingDeposit;
  final String? initialCustomerId;

  const _OneTimeDepositForm({this.existingDeposit, this.initialCustomerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = useOneTimeDepositForm(
      context: context,
      ref: ref,
      deposit: existingDeposit,
      initialCustomerId: initialCustomerId,
    );

    return Scaffold(
      appBar: FormAppBar(
        title: state.isUpdating
            ? t.oneTimeDeposits.editDeposit
            : t.oneTimeDeposits.newDeposit,
        isSaving: state.isSaving.value,
        onSave: state.save,
      ),
      body: Form(
        key: state.formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          children: [
            ..._buildAccountInformation(
              selectedCustomerId: state.selectedCustomerId,
              accountNoController: state.accountNoController,
              selectedStatus: state.selectedStatus,
            ),
            ..._buildInvestmentDetails(
              context,
              selectedScheme: state.selectedScheme,
              selectedTermYears: state.selectedTermYears,
              selectedTermMonths: state.selectedTermMonths,
              principalAmountController: state.principalAmountController,
              interestRateController: state.interestRateController,
              startDate: state.startDate,
              startDateController: state.startDateController,
              projection: state.projection,
              state: state,
            ),
            ..._buildNomineesSection(nominees: state.nominees),
          ],
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
  required OneTimeDepositFormState state,
}) {
  return [
    FormSectionHeader(title: t.oneTimeDeposits.sections.investmentDetails),
    AppSegmentedButtonField<OneTimeSchemeType>(
      value: selectedScheme.value,
      labelText: t.oneTimeDeposits.fields.schemeType,
      segments: OneTimeSchemeType.values
          .map(
            (scheme) =>
                ButtonSegment(value: scheme, label: Text(scheme.shortName)),
          )
          .toList(),
      onChanged: (scheme) {
        selectedScheme.value = scheme;
        selectedTermYears.value = scheme.defaultTenureYears;
      },
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedLayers01,
        size: AppDimensions.iconMd,
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.paddingXs,
        left: AppDimensions.paddingSm,
      ),
      child: Text(
        selectedScheme.value.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
    AppSpacings.gapLg,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: principalAmountController,
          labelText: t.oneTimeDeposits.fields.principalAmount,
          prefixIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCoins01,
            size: AppDimensions.iconMd,
          ),
          isRequired: true,
          keyboardType: TextInputType.number,
          inputFormatters: [state.amountFormatter],
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return t.errors.requiredField(
                field: t.oneTimeDeposits.fields.principalAmount,
              );
            }
            return OneTimeDeposit.validateAmount(
              state.amountFormatter.getUnformattedValue().toDouble(),
              t.oneTimeDeposits.fields.principalAmount,
            );
          },
          textInputAction: TextInputAction.next,
        ),
        if (state.amountInWords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              top: AppDimensions.paddingXs,
              left: AppDimensions.paddingMd,
            ),
            child: Text(
              t.common.amountInWords(amount: state.amountInWords),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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
