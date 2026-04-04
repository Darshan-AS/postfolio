import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RecurringDepositFormScreen extends ConsumerWidget {
  final String? depositId;

  const RecurringDepositFormScreen({super.key, this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (depositId == null) {
      return const _RecurringDepositForm(existingDeposit: null);
    }

    final depositsState = ref.watch(recurringDepositsControllerProvider);

    return depositsState.when(
      data: (deposits) {
        final deposit = deposits.where((d) => d.id == depositId).firstOrNull;
        if (deposit == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t.common.error)),
            body: ErrorStateView(message: t.recurringDeposits.depositNotFound),
          );
        }
        return _RecurringDepositForm(existingDeposit: deposit);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(t.common.loading)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(t.common.error)),
        body: ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
        ),
      ),
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
  late final TextEditingController _accountNoController;
  late final TextEditingController _installmentAmountController;
  late final TextEditingController _termYearsController;
  late final TextEditingController _termMonthsController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _customerIdController;
  late final TextEditingController _maturityAmountController;
  late final TextEditingController _linkedAccountController;

  RecurringSchemeType _selectedScheme = RecurringSchemeType.recurringDeposit;
  DateTime _startDate = DateTime.now();
  DateTime _maturityDate = DateTime.now().add(const Duration(days: 365));

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
    _customerIdController = TextEditingController(
      text: widget.existingDeposit?.customerId,
    );
    _maturityAmountController = TextEditingController(
      text: widget.existingDeposit?.maturityAmount.toString(),
    );
    _linkedAccountController = TextEditingController(
      text: widget.existingDeposit?.linkedAutoDebitAccountNo,
    );

    if (widget.existingDeposit != null) {
      _selectedScheme = widget.existingDeposit!.schemeType;
      _startDate = widget.existingDeposit!.startDate;
      _maturityDate = widget.existingDeposit!.maturityDate;
    }
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _installmentAmountController.dispose();
    _termYearsController.dispose();
    _termMonthsController.dispose();
    _interestRateController.dispose();
    _customerIdController.dispose();
    _maturityAmountController.dispose();
    _linkedAccountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final result = await ref
          .read(recurringDepositsControllerProvider.notifier)
          .saveRecurringDeposit(
            id: widget.existingDeposit?.id,
            accountNo: _accountNoController.text.trim(),
            installmentAmount:
                double.tryParse(_installmentAmountController.text.trim()) ??
                0.0,
            termYears: int.tryParse(_termYearsController.text.trim()) ?? 0,
            termMonths: int.tryParse(_termMonthsController.text.trim()) ?? 0,
            interestRate:
                double.tryParse(_interestRateController.text.trim()) ?? 0.0,
            customerId: _customerIdController.text.trim(),
            schemeType: _selectedScheme,
            maturityAmount:
                double.tryParse(_maturityAmountController.text.trim()) ?? 0.0,
            startDate: _startDate,
            maturityDate: _maturityDate,
            linkedAutoDebitAccountNo: _linkedAccountController.text.trim(),
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
      appBar: AppBar(
        title: Text(
          isUpdating
              ? t.recurringDeposits.editDeposit
              : t.recurringDeposits.newDeposit,
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
              ),
              child: Center(
                child: SizedBox(
                  width: AppDimensions.iconMd,
                  height: AppDimensions.iconMd,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              color: AppTheme.primary,
              onPressed: _save,
              tooltip: t.recurringDeposits.saveDeposit,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          children: [
            TextFormField(
              controller: _accountNoController,
              decoration: InputDecoration(
                labelText: t.recurringDeposits.fields.accountNo,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers_outlined),
              ),
              validator: RecurringDeposit.validateAccountNo,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _installmentAmountController,
              decoration: InputDecoration(
                labelText: t.recurringDeposits.fields.installmentAmount,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.money_outlined),
              ),
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
                  child: TextFormField(
                    controller: _termYearsController,
                    decoration: InputDecoration(
                      labelText: t.recurringDeposits.fields.termYears,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                AppSpacings.gapMd,
                Expanded(
                  child: TextFormField(
                    controller: _termMonthsController,
                    decoration: InputDecoration(
                      labelText: t.recurringDeposits.fields.termMonths,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _interestRateController,
              decoration: InputDecoration(
                labelText: t.recurringDeposits.fields.interestRate,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.percent_outlined),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _customerIdController,
              decoration: InputDecoration(
                labelText: t.recurringDeposits.fields.customerId,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Required' : null,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            DropdownButtonFormField<RecurringSchemeType>(
              initialValue: _selectedScheme,
              decoration: InputDecoration(
                labelText: t.recurringDeposits.fields.schemeType,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: RecurringSchemeType.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.displayName));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedScheme = val);
              },
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _maturityAmountController,
              decoration: InputDecoration(
                labelText: t.recurringDeposits.fields.maturityAmount,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.savings_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (val) => RecurringDeposit.validateAmount(
                double.tryParse(val ?? ''),
                'Maturity Amount',
              ),
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _linkedAccountController,
              decoration: const InputDecoration(
                labelText: 'Linked Savings Account',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            ListTile(
              title: Text(t.recurringDeposits.fields.startDate),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              ),
              leading: const Icon(Icons.event),
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
            ListTile(
              title: Text(t.recurringDeposits.fields.maturityDate),
              subtitle: Text(
                '${_maturityDate.day}/${_maturityDate.month}/${_maturityDate.year}',
              ),
              leading: const Icon(Icons.event_available),
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
            AppSpacings.gapXxl,
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.recurringDeposits.saveDeposit),
            ),
          ],
        ),
      ),
    );
  }
}
