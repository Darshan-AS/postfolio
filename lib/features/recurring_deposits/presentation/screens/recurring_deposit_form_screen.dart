import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/nominees_input_section.dart';
import 'package:postfolio/core/widgets/async_entity_builder.dart';
import 'package:postfolio/core/widgets/app_form_fields.dart';
import 'package:postfolio/core/widgets/form_app_bar.dart';
import 'package:postfolio/core/widgets/app_duration_input.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/models/nominee.dart';

class RecurringDepositFormScreen extends ConsumerWidget {
  final String? depositId;

  const RecurringDepositFormScreen({super.key, this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<RecurringDeposit>(
      state: ref.watch(recurringDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
      builder: (deposit) => _RecurringDepositForm(existingDeposit: deposit),
    );
  }
}

class _RecurringDepositForm extends HookConsumerWidget {
  final RecurringDeposit? existingDeposit;

  const _RecurringDepositForm({this.existingDeposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final deposit = existingDeposit;

    final serialNoController = useTextEditingController(text: deposit?.serialNo);
    final accountNoController = useTextEditingController(text: deposit?.accountNo);
    final installmentAmountController = useTextEditingController(text: deposit?.installmentAmount.toString());
    final interestRateController = useTextEditingController(text: deposit?.interestRate.toString());
    final linkedAccountController = useTextEditingController(text: deposit?.linkedAutoDebitAccountNo);

    final selectedCustomerId = useState<String?>(deposit?.customerId);
    final selectedScheme = useState<RecurringSchemeType>(deposit?.schemeType ?? RecurringSchemeType.recurringDeposit);
    
    // Default values if not updating
    final initialTermYears = deposit?.termYears ?? selectedScheme.value.defaultTenureYears;
    final initialTermMonths = deposit?.termMonths ?? 0;

    final selectedTermYears = useState<int>(initialTermYears);
    final selectedTermMonths = useState<int>(initialTermMonths);
    final selectedStatus = useState<DepositStatus>(deposit?.status ?? DepositStatus.active);
    final startDate = useState<DateTime>(deposit?.startDate ?? DateTime.now());
    final nominees = useState<List<Nominee>>(deposit != null ? List.of(deposit.nominees) : []);

    final isSaving = useState(false);

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
              serialNo: serialNoController.text.trim(),
              accountNo: accountNoController.text.trim(),
              installmentAmount: double.tryParse(installmentAmountController.text.trim()) ?? 0.0,
              termYears: selectedTermYears.value,
              termMonths: selectedScheme.value.isFixedTenure ? 0 : selectedTermMonths.value,
              interestRate: double.tryParse(interestRateController.text.trim()) ?? 0.0,
              customerId: selectedCustomerId.value ?? '',
              schemeType: selectedScheme.value,
              status: selectedStatus.value,
              startDate: startDate.value,
              linkedAutoDebitAccountNo: linkedAccountController.text.trim(),
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
                  t.recurringDeposits.failedToSaveDeposit(error: err.toString()),
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
            ? t.recurringDeposits.editDeposit
            : t.recurringDeposits.newDeposit,
        isSaving: isSaving.value,
        onSave: save,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          children: [
            Text(
              'Account Details',
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
            AppDropdownField<DepositStatus>(
              value: selectedStatus.value,
              labelText: t.recurringDeposits.fields.status,
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
              'Deposit Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapMd,
            AppDropdownField<RecurringSchemeType>(
              value: selectedScheme.value,
              labelText: t.recurringDeposits.fields.schemeType,
              items: RecurringSchemeType.values
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
              controller: installmentAmountController,
              labelText: t.recurringDeposits.fields.installmentAmount,
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
              labelText: t.recurringDeposits.fields.interestRate,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPercent,
                size: AppDimensions.iconMd,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppDateField(
              controller: useTextEditingController(
                text: MaterialLocalizations.of(context)
                    .formatCompactDate(startDate.value),
              ),
              labelText: t.recurringDeposits.fields.startDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: startDate.value,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  startDate.value = picked;
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
            Text(
              'Linked Accounts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapMd,
            AppTextField(
              controller: linkedAccountController,
              labelText: t.recurringDeposits.fields.linkedSavingsAccount,
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
            AppSpacings.gapXxl,
          ],
        ),
      ),
    );
  }
}
