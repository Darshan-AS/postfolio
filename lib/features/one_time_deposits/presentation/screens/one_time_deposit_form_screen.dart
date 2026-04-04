import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositFormScreen extends ConsumerWidget {
  final String? depositId;

  const OneTimeDepositFormScreen({super.key, this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (depositId == null) {
      return const _OneTimeDepositForm(existingDeposit: null);
    }

    final depositsState = ref.watch(oneTimeDepositsControllerProvider);

    return depositsState.when(
      data: (deposits) {
        final deposit = deposits.where((d) => d.id == depositId).firstOrNull;
        if (deposit == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t.common.error)),
            body: ErrorStateView(message: t.oneTimeDeposits.depositNotFound),
          );
        }
        return _OneTimeDepositForm(existingDeposit: deposit);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(t.common.loading)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(t.common.error)),
        body: ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
        ),
      ),
    );
  }
}

class _OneTimeDepositForm extends ConsumerStatefulWidget {
  final OneTimeDeposit? existingDeposit;

  const _OneTimeDepositForm({this.existingDeposit});

  @override
  ConsumerState<_OneTimeDepositForm> createState() =>
      _OneTimeDepositFormState();
}

class _OneTimeDepositFormState extends ConsumerState<_OneTimeDepositForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rowIdController;
  late final TextEditingController _accountNoController;
  late final TextEditingController _principalAmountController;
  late final TextEditingController _termYearsController;
  late final TextEditingController _termMonthsController;
  late final TextEditingController _customerIdController;
  late final TextEditingController _maturityAmountController;

  OneTimeSchemeType _selectedScheme = OneTimeSchemeType.timeDeposit;
  DateTime _startDate = DateTime.now();
  DateTime _maturityDate = DateTime.now().add(const Duration(days: 365));

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rowIdController = TextEditingController(
      text: widget.existingDeposit?.rowId,
    );
    _accountNoController = TextEditingController(
      text: widget.existingDeposit?.accountNo,
    );
    _principalAmountController = TextEditingController(
      text: widget.existingDeposit?.principalAmount.toString(),
    );
    _termYearsController = TextEditingController(
      text: widget.existingDeposit?.termYears.toString(),
    );
    _termMonthsController = TextEditingController(
      text: widget.existingDeposit?.termMonths.toString(),
    );
    _customerIdController = TextEditingController(
      text: widget.existingDeposit?.customerId,
    );
    _maturityAmountController = TextEditingController(
      text: widget.existingDeposit?.maturityAmount.toString(),
    );

    if (widget.existingDeposit != null) {
      _selectedScheme = widget.existingDeposit!.schemeType;
      _startDate = widget.existingDeposit!.startDate;
      _maturityDate = widget.existingDeposit!.maturityDate;
    }
  }

  @override
  void dispose() {
    _rowIdController.dispose();
    _accountNoController.dispose();
    _principalAmountController.dispose();
    _termYearsController.dispose();
    _termMonthsController.dispose();
    _customerIdController.dispose();
    _maturityAmountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final result = await ref
          .read(oneTimeDepositsControllerProvider.notifier)
          .saveOneTimeDeposit(
            id: widget.existingDeposit?.id,
            rowId: _rowIdController.text.trim(),
            accountNo: _accountNoController.text.trim(),
            principalAmount:
                double.tryParse(_principalAmountController.text.trim()) ?? 0.0,
            termYears: int.tryParse(_termYearsController.text.trim()) ?? 0,
            termMonths: int.tryParse(_termMonthsController.text.trim()) ?? 0,
            customerId: _customerIdController.text.trim(),
            schemeType: _selectedScheme,
            maturityAmount:
                double.tryParse(_maturityAmountController.text.trim()) ?? 0.0,
            startDate: _startDate,
            maturityDate: _maturityDate,
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
                t.oneTimeDeposits.failedToSaveDeposit(error: err.toString()),
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
              ? t.oneTimeDeposits.editDeposit
              : t.oneTimeDeposits.newDeposit,
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
              tooltip: t.oneTimeDeposits.saveDeposit,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          children: [
            TextFormField(
              controller: _rowIdController,
              decoration: InputDecoration(
                labelText: t.oneTimeDeposits.fields.rowId,
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            AppSpacings.gapMd,
            TextFormField(
              controller: _accountNoController,
              decoration: InputDecoration(
                labelText: t.oneTimeDeposits.fields.accountNo,
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            AppSpacings.gapMd,
            TextFormField(
              controller: _principalAmountController,
              decoration: InputDecoration(
                labelText: t.oneTimeDeposits.fields.principalAmount,
              ),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            AppSpacings.gapMd,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _termYearsController,
                    decoration: InputDecoration(
                      labelText: t.oneTimeDeposits.fields.termYears,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                AppSpacings.gapMd,
                Expanded(
                  child: TextFormField(
                    controller: _termMonthsController,
                    decoration: InputDecoration(
                      labelText: t.oneTimeDeposits.fields.termMonths,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            AppSpacings.gapMd,
            TextFormField(
              controller: _customerIdController,
              decoration: InputDecoration(
                labelText: t.oneTimeDeposits.fields.customerId,
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            AppSpacings.gapMd,
            DropdownButtonFormField<OneTimeSchemeType>(
              initialValue: _selectedScheme,
              decoration: InputDecoration(
                labelText: t.oneTimeDeposits.fields.schemeType,
              ),
              items: OneTimeSchemeType.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.displayName));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedScheme = val);
              },
            ),
            AppSpacings.gapMd,
            TextFormField(
              controller: _maturityAmountController,
              decoration: InputDecoration(
                labelText: t.oneTimeDeposits.fields.maturityAmount,
              ),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
