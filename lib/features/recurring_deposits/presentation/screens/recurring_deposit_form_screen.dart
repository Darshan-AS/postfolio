import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _RecurringDepositForm extends ConsumerStatefulWidget {
  final RecurringDeposit? existingDeposit;

  const _RecurringDepositForm({this.existingDeposit});

  @override
  ConsumerState<_RecurringDepositForm> createState() =>
      _RecurringDepositFormState();
}

class _RecurringDepositFormState extends ConsumerState<_RecurringDepositForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serialNoController;
  late final TextEditingController _accountNoController;
  late final TextEditingController _installmentAmountController;
  late final TextEditingController _termYearsController;
  late final TextEditingController _termMonthsController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _maturityAmountController;
  late final TextEditingController _linkedAccountController;

  String? _selectedCustomerId;

  RecurringSchemeType _selectedScheme = RecurringSchemeType.recurringDeposit;
  DepositStatus _selectedStatus = DepositStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime _maturityDate = DateTime.now().add(const Duration(days: 365));
  List<Nominee> _nominees = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _serialNoController = TextEditingController(
      text: widget.existingDeposit?.serialNo,
    );
    _accountNoController = TextEditingController(
      text: widget.existingDeposit?.accountNo,
    );
    _installmentAmountController = TextEditingController(
      text: widget.existingDeposit?.installmentAmount.toString(),
    );
    _termYearsController = TextEditingController(
      text: widget.existingDeposit?.termYears.toString(),
    );
    _termMonthsController = TextEditingController(
      text: widget.existingDeposit?.termMonths.toString(),
    );
    _interestRateController = TextEditingController(
      text: widget.existingDeposit?.interestRate.toString(),
    );
    _selectedCustomerId = widget.existingDeposit?.customerId;
    _maturityAmountController = TextEditingController(
      text: widget.existingDeposit?.maturityAmount.toString(),
    );
    _linkedAccountController = TextEditingController(
      text: widget.existingDeposit?.linkedAutoDebitAccountNo,
    );

    if (widget.existingDeposit != null) {
      _selectedScheme = widget.existingDeposit!.schemeType;
      _selectedStatus = widget.existingDeposit!.status;
      _startDate = widget.existingDeposit!.startDate;
      _maturityDate = widget.existingDeposit!.maturityDate;
      _nominees = List.of(widget.existingDeposit!.nominees);
    }
  }

  @override
  void dispose() {
    _serialNoController.dispose();
    _accountNoController.dispose();
    _installmentAmountController.dispose();
    _termYearsController.dispose();
    _termMonthsController.dispose();
    _interestRateController.dispose();
    _maturityAmountController.dispose();
    _linkedAccountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.recurringDeposits.selectCustomerPrompt)),
        );
        return;
      }

      setState(() => _isSaving = true);
      final result = await ref
          .read(recurringDepositsControllerProvider.notifier)
          .saveRecurringDeposit(
            id: widget.existingDeposit?.id,
            serialNo: _serialNoController.text.trim(),
            accountNo: _accountNoController.text.trim(),
            installmentAmount:
                double.tryParse(_installmentAmountController.text.trim()) ??
                0.0,
            termYears: int.tryParse(_termYearsController.text.trim()) ?? 0,
            termMonths: int.tryParse(_termMonthsController.text.trim()) ?? 0,
            interestRate:
                double.tryParse(_interestRateController.text.trim()) ?? 0.0,
            customerId: _selectedCustomerId ?? '',
            schemeType: _selectedScheme,
            status: _selectedStatus,
            maturityAmount:
                double.tryParse(_maturityAmountController.text.trim()) ?? 0.0,
            startDate: _startDate,
            maturityDate: _maturityDate,
            linkedAutoDebitAccountNo: _linkedAccountController.text.trim(),
            nominees: _nominees,
          );

      if (!mounted) return;
      setState(() => _isSaving = false);

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

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.existingDeposit != null;

    return Scaffold(
      appBar: FormAppBar(
        title: isUpdating
            ? t.recurringDeposits.editDeposit
            : t.recurringDeposits.newDeposit,
        isSaving: _isSaving,
        onSave: _save,
      ),
      body: Form(
        key: _formKey,
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
              initialCustomerId: _selectedCustomerId,
              onCustomerSelected: (customer) {
                setState(() {
                  _selectedCustomerId = customer?.id;
                });
              },
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _serialNoController,
              labelText: t.recurringDeposits.fields.serialNo,
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedTag01),
              isRequired: true,
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Required' : null,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _accountNoController,
              labelText: t.recurringDeposits.fields.accountNo,
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedTicket01),
              isRequired: true,
              validator: RecurringDeposit.validateAccountNo,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppDropdownField<DepositStatus>(
              value: _selectedStatus,
              labelText: t.recurringDeposits.fields.status,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
              ),
              items: DepositStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),

            AppSpacings.gapXl,
            Text(
              'Investment Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapMd,
            AppDropdownField<RecurringSchemeType>(
              value: _selectedScheme,
              labelText: t.recurringDeposits.fields.schemeType,
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedTag01),
              items: RecurringSchemeType.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.displayName));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedScheme = val);
              },
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _installmentAmountController,
              labelText: t.recurringDeposits.fields.installmentAmount,
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedMoney01),
              isRequired: true,
              keyboardType: TextInputType.number,
              validator: (val) => RecurringDeposit.validateAmount(
                double.tryParse(val ?? ''),
                'Installment Amount',
              ),
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _termYearsController,
                    labelText: t.recurringDeposits.fields.termYears,
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar01,
                    ),
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                AppSpacings.gapMd,
                Expanded(
                  child: AppTextField(
                    controller: _termMonthsController,
                    labelText: t.recurringDeposits.fields.termMonths,
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar02,
                    ),
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _interestRateController,
              labelText: t.recurringDeposits.fields.interestRate,
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedPercent),
              isRequired: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _maturityAmountController,
              labelText: t.recurringDeposits.fields.maturityAmount,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPiggyBank,
              ),
              isRequired: true,
              keyboardType: TextInputType.number,
              validator: (val) => RecurringDeposit.validateAmount(
                double.tryParse(val ?? ''),
                'Maturity Amount',
              ),
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _linkedAccountController,
              labelText: t.recurringDeposits.fields.linkedSavingsAccount,
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedBank),
              textInputAction: TextInputAction.next,
            ),

            AppSpacings.gapXl,
            Text(
              'Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapMd,
            Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(t.recurringDeposits.fields.startDate),
                    subtitle: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                    leading: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar01,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(t.recurringDeposits.fields.maturityDate),
                    subtitle: Text(
                      '${_maturityDate.day}/${_maturityDate.month}/${_maturityDate.year}',
                    ),
                    leading: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _maturityDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _maturityDate = date);
                    },
                  ),
                ],
              ),
            ),
            AppSpacings.gapXxl,
            NomineesInputSection(
              initialNominees: _nominees,
              onChanged: (newNominees) {
                _nominees = newNominees;
              },
            ),
            AppSpacings.gapXxl,
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: AppDimensions.iconMd,
                      width: AppDimensions.iconMd,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.recurringDeposits.saveDeposit),
            ),
            AppSpacings.gapXxl,
          ],
        ),
      ),
    );
  }
}
