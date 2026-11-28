import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/domain/nominees_input_section.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/feedback/unsaved_changes_pop_scope.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/core/widgets/layout/form_app_bar.dart';
import 'package:postfolio/core/widgets/layout/form_screen_body.dart';
import 'package:postfolio/core/widgets/forms/app_duration_input.dart';
import 'package:postfolio/core/widgets/domain/investment_projection_card.dart';

import 'package:postfolio/features/recurring_deposits/presentation/hooks/use_recurring_deposit_form.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

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

    final editDeposit = existingDeposit;
    final editCustomerName = editDeposit == null
        ? null
        : (editDeposit.customerName?.isNotEmpty ?? false)
        ? editDeposit.customerName!
        : ref.watch(customerByIdProvider(editDeposit.customerId)).value?.name;
    final showOnboarding = useState(
      state.isUpdating ||
          (editDeposit?.initialPaidInstallments ?? 0) > 0 ||
          (editDeposit?.openingReceivable ?? 0) > 0,
    );
    final scheme = Theme.of(context).colorScheme;

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
          submitLabel: state.isUpdating
              ? t.common.saveChanges
              : t.recurringDeposits.createDeposit,
          isEnabled: !state.isUpdating || isDirty,
          showUnsavedHint: state.isUpdating && isDirty,
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
                      if (editDeposit != null) ...[
                        EntityListTile(
                          leadingText: editDeposit.avatarLabel,
                          leadingShape: AppAvatarShape.neutral,
                          leadingBackgroundColor: scheme.secondaryContainer,
                          leadingForegroundColor: scheme.onSecondaryContainer,
                          title:
                              editCustomerName ??
                              t.recurringDeposits.unnamedCustomer,
                          subtitle: Text(
                            [
                              if (editDeposit.accountNo?.trim().isNotEmpty ??
                                  false)
                                editDeposit.accountNo!.trim(),
                              editDeposit.status.displayName,
                            ].join(t.format.bulletSeparator),
                          ),
                        ),
                        AppSpacings.gapLg,
                      ],
                      _buildAccountInformation(
                        context,
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
                            if (state.isFinancialTermsLocked &&
                                editDeposit != null)
                              _buildLockedFinancialTerms(
                                context,
                                deposit: editDeposit,
                                projection: state.projection,
                              )
                            else
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
                                showOnboarding: showOnboarding,
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

Widget _buildAccountInformation(
  BuildContext context, {
  required ValueNotifier<String?> selectedCustomerId,
  required TextEditingController serialNoController,
  required TextEditingController accountNoController,
  required ValueNotifier<DepositStatus> selectedStatus,
}) {
  final stacked = AppDimensions.isLargeText(context);
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
      AppFormRow(
        left: AppTextField(
          controller: serialNoController,
          labelText: t.recurringDeposits.fields.serialNo,
          prefixIcon: stacked
              ? const AppIcon(
                  HugeIcons.strokeRoundedTag01,
                  size: AppDimensions.iconMd,
                )
              : null,
          textInputAction: TextInputAction.next,
        ),
        right: AppTextField(
          controller: accountNoController,
          labelText: t.recurringDeposits.fields.accountNo,
          prefixIcon: stacked
              ? const AppIcon(
                  HugeIcons.strokeRoundedTicket01,
                  size: AppDimensions.iconMd,
                )
              : null,
          validator: RecurringDeposit.validateAccountNo,
          textInputAction: TextInputAction.next,
        ),
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
        prefixIcon: const AppIcon(
          HugeIcons.strokeRoundedActivity01,
          size: AppDimensions.iconMd,
        ),
      ),
    ],
  );
}

Widget _buildLockedFinancialTerms(
  BuildContext context, {
  required RecurringDeposit deposit,
  required InvestmentProjection projection,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DetailSectionTitle(t.recurringDeposits.sections.lockedFinancialTerms),
      AppGroup(
        children: [
          DetailItem(
            label: t.recurringDeposits.fields.installmentAmount,
            value: [
              deposit.installmentAmount.toRupeeFormat(),
              t.recurringDeposits.fields.ratePercent(
                rate: deposit.interestRate.toStringAsFixed(2),
              ),
              t.common.duration.yearAbbreviation(n: deposit.termYears),
            ].join(t.format.bulletSeparator),
            icon: const AppIcon(HugeIcons.strokeRoundedCoins01),
          ),
          DetailItem(
            label: t.recurringDeposits.fields.startDate,
            value: [
              deposit.startDate.toAppFormat(),
              t.common.maturesOn(date: projection.maturityDate.toAppFormat()),
            ].join(t.format.bulletSeparator),
            icon: const AppIcon(HugeIcons.strokeRoundedCalendar01),
          ),
          if (deposit.initialPaidInstallments > 0 ||
              deposit.openingReceivable > 0)
            DetailItem(
              label: t.recurringDeposits.fields.initialPaidInstallments,
              value: [
                if (deposit.initialPaidInstallments > 0)
                  deposit.initialPaidInstallments.toString(),
                if (deposit.openingReceivable > 0)
                  '${t.recurringDeposits.fields.openingReceivable}: ${deposit.openingReceivable.toRupeeFormat()}',
              ].join(t.format.bulletSeparator),
              icon: const AppIcon(HugeIcons.strokeRoundedCheckmarkCircle02),
            ),
        ],
      ),
      AppSpacings.gapSm,
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
        ),
        child: Row(
          children: [
            AppIcon(
              HugeIcons.strokeRoundedLockKey,
              size: AppDimensions.iconSm,
              color: scheme.onSurfaceVariant,
            ),
            AppSpacings.gapSm,
            Expanded(
              child: Text(
                t.recurringDeposits.fields.financialTermsLocked,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
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
  required ValueNotifier<bool> showOnboarding,
  required RecurringDepositFormState state,
}) {
  final scheme = Theme.of(context).colorScheme;
  final emphasized = AppTypography.emphasizedOf(context);
  final stacked = AppDimensions.isLargeText(context);
  final disableAnimations = MediaQuery.disableAnimationsOf(context);

  final onboardingFields = showOnboarding.value
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacings.gapMd,
            AppTextField(
              controller: state.initialPaidInstallmentsController,
              labelText: t.recurringDeposits.fields.initialPaidInstallments,
              prefixIcon: const AppIcon(
                HugeIcons.strokeRoundedCheckmarkCircle02,
                size: AppDimensions.iconMd,
              ),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  RecurringDeposit.validateInitialPaidInstallments(
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
              prefixIcon: const AppIcon(
                HugeIcons.strokeRoundedWallet02,
                size: AppDimensions.iconMd,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: RecurringDeposit.validateOpeningReceivable,
              textInputAction: TextInputAction.next,
            ),
            FormFieldSupportingText(
              t.recurringDeposits.fields.openingReceivableHelper,
            ),
          ],
        )
      : const SizedBox.shrink();

  return FormSection(
    title: t.recurringDeposits.sections.investmentDetails,
    children: [
      AppTextField(
        controller: installmentAmountController,
        labelText: t.recurringDeposits.fields.installmentAmount,
        prefixText: '${t.format.currencySymbol} ',
        style: emphasized.headlineMedium?.copyWith(color: scheme.onSurface),
        prefixStyle: emphasized.titleLarge?.copyWith(color: scheme.primary),
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
      AppFormRow(
        left: AppDateField(
          controller: startDateController,
          labelText: t.recurringDeposits.fields.startDate,
          isRequired: true,
          showPrefixIcon: stacked,
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
        right: AppTextField(
          controller: interestRateController,
          labelText: t.recurringDeposits.fields.interestRate,
          suffixText: '%',
          prefixIcon: stacked
              ? const AppIcon(
                  HugeIcons.strokeRoundedPercent,
                  size: AppDimensions.iconMd,
                )
              : null,
          isRequired: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (val) => RecurringDeposit.validateInterestRate(
            double.tryParse(val ?? ''),
            t.recurringDeposits.fields.interestRate,
          ),
          textInputAction: TextInputAction.next,
        ),
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
      AppSpacings.gapMd,
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: AppButton.text(
          label: t.recurringDeposits.fields.existingAccountDetails,
          icon: showOnboarding.value
              ? HugeIcons.strokeRoundedArrowUp01
              : HugeIcons.strokeRoundedArrowDown01,
          flushStart: true,
          onPressed: () => showOnboarding.value = !showOnboarding.value,
        ),
      ),
      if (!showOnboarding.value)
        FormFieldSupportingText(
          t.recurringDeposits.fields.existingAccountDetailsHint,
        ),
      disableAnimations
          ? onboardingFields
          : AnimatedSize(
              duration: AppMotion.effectsSlowDuration,
              curve: AppMotion.effectsSlowCurve,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: onboardingFields,
            ),
    ],
  );
}
