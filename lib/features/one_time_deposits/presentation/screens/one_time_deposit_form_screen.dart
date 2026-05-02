import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/nominees_input_section.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
import 'package:postfolio/core/widgets/form_app_bar.dart';
import 'package:postfolio/core/widgets/app_duration_input.dart';
import 'package:postfolio/core/widgets/investment_projection_card.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/models/nominee.dart';

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

    final accountNoController = useTextEditingController(text: deposit?.accountNo);
    final principalAmountController = useTextEditingController(text: deposit?.principalAmount.toString());
    final interestRateController = useTextEditingController(text: deposit?.interestRate.toString());
    final linkedAccountController = useTextEditingController(text: deposit?.linkedSavingsAccountNo);

    final selectedCustomerId = useState<String?>(deposit?.customerId);
    final selectedScheme = useState<OneTimeSchemeType>(deposit?.schemeType ?? OneTimeSchemeType.timeDeposit);
    
    // Default values if not updating
    final initialTermYears = deposit?.termYears ?? selectedScheme.value.defaultTenureYears;
    final initialTermMonths = deposit?.termMonths ?? 0;
    
    final selectedTermYears = useState<int>(initialTermYears);
    final selectedTermMonths = useState<int>(initialTermMonths);
    final selectedStatus = useState<DepositStatus>(deposit?.status ?? DepositStatus.active);
    final startDate = useState<DateTime>(deposit?.startDate ?? DateTime.now());
    final nominees = useState<List<Nominee>>(deposit != null ? List.of(deposit.nominees) : []);

    final isSaving = useState(false);

    final startDateController = useTextEditingController(
      text: MaterialLocalizations.of(context).formatCompactDate(startDate.value),
    );

    // Live Projection Calculation
    useListenable(principalAmountController);
    useListenable(interestRateController);

    final currentPrincipal = double.tryParse(principalAmountController.text.trim()) ?? 0.0;
    final currentInterest = double.tryParse(interestRateController.text.trim()) ?? 0.0;

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
              accountNo: accountNoController.text.trim(),
              principalAmount: double.tryParse(principalAmountController.text.trim()) ?? 0.0,
              termYears: selectedTermYears.value,
              termMonths: selectedScheme.value.isFixedTenure ? 0 : selectedTermMonths.value,
              interestRate: double.tryParse(interestRateController.text.trim()) ?? 0.0,
              customerId: selectedCustomerId.value ?? '',
              schemeType: selectedScheme.value,
              status: selectedStatus.value,
              startDate: startDate.value,
              linkedSavingsAccountNo: linkedAccountController.text.trim(),
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

    final isUpdating = deposit != null;

    return Scaffold(
      appBar: FormAppBar(
        title: isUpdating
            ? t.oneTimeDeposits.editDeposit
            : t.oneTimeDeposits.newDeposit,
        isSaving: isSaving.value,
        onSave: save,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          children: [
            Text(
              t.oneTimeDeposits.sections.accountInformation,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
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
            AppDropdownField<DepositStatus>(
              value: selectedStatus.value,
              labelText: t.oneTimeDeposits.fields.status,
              items: DepositStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (status) {
                if (status != null) {
                  selectedStatus.value = status;
                }
              },
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedActivity01,
                size: AppDimensions.iconMd,
              ),
            ),
            AppSpacings.gapXl,
            Text(
              t.oneTimeDeposits.sections.investmentDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapMd,
            AppDropdownField<OneTimeSchemeType>(
              value: selectedScheme.value,
              labelText: t.oneTimeDeposits.fields.schemeType,
              items: OneTimeSchemeType.values
                  .map((scheme) => DropdownMenuItem(
                        value: scheme,
                        child: Text(scheme.displayName),
                      ))
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppDateField(
              controller: startDateController,
              labelText: t.oneTimeDeposits.fields.startDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: startDate.value,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  startDate.value = picked;
                  if (context.mounted) {
                    startDateController.text = MaterialLocalizations.of(context).formatCompactDate(picked);
                  }
                }
              },
            ),
            AppSpacings.gapLg,
            AppDurationInput(
              isFixedTenure: selectedScheme.value.isFixedTenure,
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
            AppSpacings.gapXxl,
            Text(
              t.common.sections.linkedAccounts,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapMd,
            AppTextField(
              controller: linkedAccountController,
              labelText: t.oneTimeDeposits.fields.linkedSavingsAccount,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedBank,
                size: AppDimensions.iconMd,
              ),
              textInputAction: TextInputAction.done,
            ),
            AppSpacings.gapMd,
            NomineesInputSection(
              nominees: nominees.value,
              onChanged: (newNominees) {
                nominees.value = newNominees;
              },
            ),
          ],
        ),
      ),
    );
  }
}
