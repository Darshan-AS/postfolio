import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/domain/nominees_input_section.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/feedback/unsaved_changes_pop_scope.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/form_app_bar.dart';
import 'package:postfolio/core/widgets/layout/form_screen_body.dart';
import 'package:postfolio/core/widgets/forms/app_duration_input.dart';
import 'package:postfolio/core/widgets/domain/investment_projection_card.dart';

import 'package:postfolio/features/recurring_deposits/presentation/hooks/use_recurring_deposit_form.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
    if (depositId == null) {
      return _RecurringDepositForm(initialCustomerId: initialCustomerId);
    }
    return AsyncSingleEntityBuilder<RecurringDeposit>(
      state: ref.watch(recurringDepositByIdProvider(depositId!)),
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositByIdProvider(depositId!)),
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
    final isDirty = useIsFormDirty(
      [
        state.selectedCustomerId,
        state.serialNoController,
        state.accountNoController,
        state.selectedStatus,
        state.selectedTermYears,
        state.selectedTermMonths,
        state.installmentAmountController,
        state.interestRateController,
        state.startDate,
        state.initialPaidInstallmentsController,
        state.openingReceivableController,
        state.nominees,
      ],
      () => [
        state.selectedCustomerId.value ?? '',
        state.serialNoController.text,
        state.accountNoController.text,
        state.selectedStatus.value.name,
        state.selectedTermYears.value.toString(),
        state.selectedTermMonths.value.toString(),
        state.installmentAmountController.text,
        state.interestRateController.text,
        state.startDate.value.toIso8601String(),
        state.initialPaidInstallmentsController.text,
        state.openingReceivableController.text,
        state.nominees.value.toString(),
      ].join('\u0000'),
    );

    return UnsavedChangesPopScope(
      isDirty: isDirty && !state.isSaving.value,
      child: Scaffold(
        appBar: FormAppBar(
          title: state.isUpdating
              ? t.recurringDeposits.editDeposit
              : t.recurringDeposits.newDeposit,
        ),
        body: FormScreenBody(
          isSaving: state.isSaving.value,
          onSave: state.save,
          child: Form(
            key: state.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pageMargin,
                AppDimensions.paddingSm,
                AppDimensions.pageMargin,
                AppDimensions.paddingLg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxFormWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAccountInformation(
                        selectedCustomerId: state.selectedCustomerId,
                        serialNoController: state.serialNoController,
                        accountNoController: state.accountNoController,
                        selectedStatus: state.selectedStatus,
                      ),
                      AppSpacings.gapLg,
                      // While the ledger lock state resolves the terms are treated as locked
                      // (fail safe) and the section is skeletonized so it never looks editable.
                      Skeletonizer(
                        enabled: state.isFinancialTermsLockLoading,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInvestmentDetails(
                              context,
                              selectedScheme: state.selectedScheme,
                              selectedTermYears: state.selectedTermYears,
                              selectedTermMonths: state.selectedTermMonths,
                              installmentAmountController:
                                  state.installmentAmountController,
                              interestRateController:
                                  state.interestRateController,
                              startDate: state.startDate,
                              startDateController: state.startDateController,
                              state: state,
                            ),
                            InvestmentProjectionCard(
                              projection: state.projection,
                            ),
                          ],
                        ),
                      ),
                      AppSpacings.gapLg,
                      NomineesInputSection(
                        nominees: state.nominees.value,
                        onChanged: (newNominees) {
                          state.nominees.value = newNominees;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildAccountInformation({
  required ValueNotifier<String?> selectedCustomerId,
  required TextEditingController serialNoController,
  required TextEditingController accountNoController,
  required ValueNotifier<DepositStatus> selectedStatus,
}) {
  return FormSection(
    title: t.recurringDeposits.sections.accountInformation,
    children: [
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
              (status) => AppSegment(value: status, label: status.displayName),
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
    ],
  );
}

Widget _buildInvestmentDetails(
  BuildContext context, {
  required ValueNotifier<RecurringSchemeType> selectedScheme,
  required ValueNotifier<int> selectedTermYears,
  required ValueNotifier<int> selectedTermMonths,
  required TextEditingController installmentAmountController,
  required TextEditingController interestRateController,
  required ValueNotifier<DateTime> startDate,
  required TextEditingController startDateController,
  required RecurringDepositFormState state,
}) {
  final scheme = Theme.of(context).colorScheme;
  return FormSection(
    title: t.recurringDeposits.sections.investmentDetails,
    children: [
      if (state.isFinancialTermsLocked &&
          !state.isFinancialTermsLockLoading) ...[
        // A fact about this account, not a mistake in the form: no error colour.
        Material(
          color: scheme.secondaryContainer,
          shape: AppShapes.rounded(AppShapes.large),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedLockKey,
                  color: scheme.onSecondaryContainer,
                  size: AppDimensions.iconMd,
                ),
                AppSpacings.gapMd,
                Expanded(
                  child: Text(
                    t.recurringDeposits.fields.financialTermsLocked,
                    style: AppTypography.emphasizedOf(
                      context,
                    ).bodySmall?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppSpacings.gapLg,
      ],
      AppTextField(
        controller: installmentAmountController,
        labelText: t.recurringDeposits.fields.installmentAmount,
        enabled: !state.isFinancialTermsLocked,
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
              field: t.recurringDeposits.fields.installmentAmount,
            );
          }
          return RecurringDeposit.validateAmount(
            state.amountFormatter.getUnformattedValue().toDouble(),
            t.recurringDeposits.fields.installmentAmount,
          );
        },
        textInputAction: TextInputAction.next,
      ),
      if (state.amountInWords.isNotEmpty)
        FormFieldSupportingText(
          t.common.amountInWords(amount: state.amountInWords),
          isEcho: true,
        ),
      AppSpacings.gapLg,
      AppDateField(
        controller: startDateController,
        labelText: t.recurringDeposits.fields.startDate,
        isRequired: true,
        enabled: !state.isFinancialTermsLocked,
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
        enabled: !state.isFinancialTermsLocked,
        onChanged: (years, months) {
          selectedTermYears.value = years;
          selectedTermMonths.value = months;
        },
      ),
      AppSpacings.gapLg,
      AppTextField(
        controller: interestRateController,
        labelText: t.recurringDeposits.fields.interestRate,
        enabled: !state.isFinancialTermsLocked,
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
      AppTextField(
        controller: state.initialPaidInstallmentsController,
        labelText: t.recurringDeposits.fields.initialPaidInstallments,
        enabled: !state.isFinancialTermsLocked,
        prefixIcon: const HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          size: AppDimensions.iconMd,
        ),
        keyboardType: TextInputType.number,
        validator: (val) => RecurringDeposit.validateInitialPaidInstallments(
          val,
          selectedTermYears.value,
          selectedTermMonths.value,
        ),
        textInputAction: TextInputAction.next,
      ),
      FormFieldSupportingText(
        t.recurringDeposits.fields.initialPaidInstallmentsHelper,
      ),
      AppSpacings.gapLg,
      AppTextField(
        controller: state.openingReceivableController,
        labelText: t.recurringDeposits.fields.openingReceivable,
        enabled: !state.isFinancialTermsLocked,
        prefixIcon: const HugeIcon(
          icon: HugeIcons.strokeRoundedWallet02,
          size: AppDimensions.iconMd,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: RecurringDeposit.validateOpeningReceivable,
        textInputAction: TextInputAction.next,
      ),
      FormFieldSupportingText(
        t.recurringDeposits.fields.openingReceivableHelper,
      ),
    ],
  );
}
