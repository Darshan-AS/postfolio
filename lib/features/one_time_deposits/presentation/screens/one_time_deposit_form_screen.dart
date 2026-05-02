import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _OneTimeDepositForm extends ConsumerStatefulWidget {
  final OneTimeDeposit? existingDeposit;

  const _OneTimeDepositForm({this.existingDeposit});

  @override
  ConsumerState<_OneTimeDepositForm> createState() =>
      _OneTimeDepositFormState();
}

class _OneTimeDepositFormState extends ConsumerState<_OneTimeDepositForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountNoController;
  late final TextEditingController _principalAmountController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _linkedAccountController;

  String? _selectedCustomerId;

  OneTimeSchemeType _selectedScheme = OneTimeSchemeType.timeDeposit;
  late int _selectedTermYears;
  late int _selectedTermMonths;
  DepositStatus _selectedStatus = DepositStatus.active;
  DateTime _startDate = DateTime.now();
  List<Nominee> _nominees = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _accountNoController = TextEditingController(
      text: widget.existingDeposit?.accountNo,
    );
    _principalAmountController = TextEditingController(
      text: widget.existingDeposit?.principalAmount.toString(),
    );
    _interestRateController = TextEditingController(
      text: widget.existingDeposit?.interestRate.toString(),
    );
    _selectedCustomerId = widget.existingDeposit?.customerId;
    _linkedAccountController = TextEditingController(
      text: widget.existingDeposit?.linkedSavingsAccountNo,
    );

    if (widget.existingDeposit != null) {
      _selectedScheme = widget.existingDeposit!.schemeType;
      _selectedTermYears = widget.existingDeposit!.termYears;
      _selectedTermMonths = widget.existingDeposit!.termMonths;
      _selectedStatus = widget.existingDeposit!.status;
      _startDate = widget.existingDeposit!.startDate;
      _nominees = List.of(widget.existingDeposit!.nominees);
    } else {
      _selectedTermYears = _selectedScheme.defaultTenureYears;
      _selectedTermMonths = 0;
    }
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _principalAmountController.dispose();
    _interestRateController.dispose();
    _linkedAccountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.oneTimeDeposits.selectCustomerPrompt)),
        );
        return;
      }

      setState(() => _isSaving = true);
      final result = await ref
          .read(oneTimeDepositsControllerProvider.notifier)
          .saveOneTimeDeposit(
            id: widget.existingDeposit?.id,
            accountNo: _accountNoController.text.trim(),
            principalAmount:
                double.tryParse(_principalAmountController.text.trim()) ?? 0.0,
            termYears: _selectedTermYears,
            termMonths: _selectedScheme.isFixedTenure ? 0 : _selectedTermMonths,
            interestRate:
                double.tryParse(_interestRateController.text.trim()) ?? 0.0,
            customerId: _selectedCustomerId ?? '',
            schemeType: _selectedScheme,
            status: _selectedStatus,
            startDate: _startDate,
            linkedSavingsAccountNo: _linkedAccountController.text.trim(),
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
      appBar: FormAppBar(
        title: isUpdating
            ? t.oneTimeDeposits.editDeposit
            : t.oneTimeDeposits.newDeposit,
        isSaving: _isSaving,
        onSave: _save,
      ),
      body: Form(
        key: _formKey,
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
              initialCustomerId: _selectedCustomerId,
              onCustomerSelected: (customer) {
                setState(() {
                  _selectedCustomerId = customer?.id;
                });
              },
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _accountNoController,
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
              value: _selectedStatus,
              labelText: t.oneTimeDeposits.fields.status,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                size: AppDimensions.iconMd,
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
              t.oneTimeDeposits.sections.investmentDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapMd,
            AppDropdownField<OneTimeSchemeType>(
              value: _selectedScheme,
              labelText: t.oneTimeDeposits.fields.schemeType,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedTag01,
                size: AppDimensions.iconMd,
              ),
              items: OneTimeSchemeType.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.displayName));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedScheme = val;
                    if (!_selectedScheme.allowedTenuresInYears.contains(_selectedTermYears) && _selectedScheme.isFixedTenure) {
                      _selectedTermYears = _selectedScheme.defaultTenureYears;
                    }
                  });
                }
              },
            ),
            AppSpacings.gapLg,
            AppDurationInput(
              isFixedTenure: _selectedScheme.isFixedTenure,
              allowedTenuresInYears: _selectedScheme.allowedTenuresInYears,
              selectedYears: _selectedTermYears,
              selectedMonths: _selectedTermMonths,
              onChanged: (years, months) {
                setState(() {
                  _selectedTermYears = years;
                  _selectedTermMonths = months;
                });
              },
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _principalAmountController,
              labelText: t.oneTimeDeposits.fields.principalAmount,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMoney01,
                size: AppDimensions.iconMd,
              ),
              keyboardType: TextInputType.number,
              validator: (val) => OneTimeDeposit.validateAmount(
                double.tryParse(val ?? ''),
                'Principal Amount',
              ),
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _interestRateController,
              labelText: t.oneTimeDeposits.fields.interestRate,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPercent,
                size: AppDimensions.iconMd,
              ),
              isRequired: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            AppTextField(
              controller: _linkedAccountController,
              labelText: t.oneTimeDeposits.fields.linkedSavingsAccount,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedBank,
                size: AppDimensions.iconMd,
              ),
              textInputAction: TextInputAction.next,
            ),

            AppSpacings.gapXl,
            Text(
              t.oneTimeDeposits.sections.timeline,
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
                    title: Text(t.oneTimeDeposits.fields.startDate),
                    subtitle: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                    leading: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar02,
                      size: AppDimensions.iconMd,
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
                  : Text(t.oneTimeDeposits.saveDeposit),
            ),
            AppSpacings.gapXxl,
          ],
        ),
      ),
    );
  }
}
