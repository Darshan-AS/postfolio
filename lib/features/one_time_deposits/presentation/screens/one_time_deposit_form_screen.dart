import 'package:material_ui/material_ui.dart';
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
import 'package:postfolio/core/widgets/feedback/unsaved_changes_pop_scope.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/form_app_bar.dart';
import 'package:postfolio/core/widgets/forms/app_duration_input.dart';
import 'package:postfolio/core/widgets/domain/investment_projection_card.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/models/nominee.dart';

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
    if (depositId == null) {
      return _OneTimeDepositForm(
        initialCustomerId: initialCustomerId,
      );
    }
    return AsyncSingleEntityBuilder<OneTimeDeposit>(
      state: ref.watch(oneTimeDepositByIdProvider(depositId!)),
      notFoundMessage: t.oneTimeDeposits.depositNotFound,
      onRetry: () => ref.invalidate(oneTimeDepositByIdProvider(depositId!)),
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
    final isDirty = useIsFormDirty(
      [
        state.selectedCustomerId,
        state.accountNoController,
        state.selectedStatus,
        state.selectedScheme,
        state.selectedTermYears,
        state.selectedTermMonths,
        state.principalAmountController,
        state.interestRateController,
        state.startDate,
        state.nominees,
      ],
      () => [
        state.selectedCustomerId.value ?? '',
        state.accountNoController.text,
        state.selectedStatus.value.name,
        state.selectedScheme.value.name,
        state.selectedTermYears.value.toString(),
        state.selectedTermMonths.value.toString(),
        state.principalAmountController.text,
        state.interestRateController.text,
        state.startDate.value.toIso8601String(),
        state.nominees.value.toString(),
      ].join('\u0000'),
    );

    return UnsavedChangesPopScope(
      isDirty: isDirty && !state.isSaving.value,
      child: Scaffold(
        appBar: FormAppBar(
          title: state.isUpdating
              ? t.oneTimeDeposits.editDeposit
              : t.oneTimeDeposits.newDeposit,
          isSaving: state.isSaving.value,
          onSave: state.save,
        ),
        body: Form(
          key: state.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxFormWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    FilledButton.icon(
                      onPressed: state.isSaving.value ? null : state.save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppDimensions.buttonHeight,
                        ),
                      ),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: AppDimensions.iconMd,
                      ),
                      label: Text(
                        state.isSaving.value
                            ? t.common.saving
                            : t.common.confirm,
                      ),
                    ),
                    AppSpacings.gapXl,
                  ],
                ),
              ),
            ),
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
      onChanged: state.onSchemeChanged,
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
        if (picked != null && context.mounted) {
          state.onStartDateChanged(picked);
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
      onChanged: state.onDurationChanged,
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
      onChanged: state.onInterestRateChanged,
      validator: (val) => OneTimeDeposit.validateInterestRate(
        double.tryParse(val ?? ''),
        t.oneTimeDeposits.fields.interestRate,
      ),
      textInputAction: TextInputAction.next,
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
