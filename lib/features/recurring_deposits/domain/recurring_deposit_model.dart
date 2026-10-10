import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'recurring_deposit_model.freezed.dart';
part 'recurring_deposit_model.g.dart';

@freezed
sealed class RecurringDeposit with _$RecurringDeposit implements BaseDeposit {
  const RecurringDeposit._();

  const factory RecurringDeposit({
    required String id,
    String? serialNo,
    String? accountNo,
    required double installmentAmount,
    required int termYears,
    required int termMonths,
    required double interestRate,
    required String customerId,
    @JsonKey(includeFromJson: true, includeToJson: false) String? customerName,
    required RecurringSchemeType schemeType,
    required DateTime startDate,
    @Default([]) List<Nominee> nominees,
    @Default(DepositStatus.active) DepositStatus status,
    @TimestampConverter() @JsonKey(includeIfNull: false) DateTime? createdAt,
    @TimestampConverter() @JsonKey(includeIfNull: false) DateTime? updatedAt,
    @JsonKey(includeIfNull: false) String? migrationSource,
  }) = _RecurringDeposit;

  @override
  InvestmentProjection get projection => ProjectionCalculator.calculateRD(
    monthlyInstallment: installmentAmount,
    interestRate: interestRate,
    startDate: startDate,
    termYears: termYears,
    termMonths: termMonths,
  );

  @override
  double get maturityAmount => projection.maturityAmount;

  @override
  DateTime get maturityDate => projection.maturityDate;

  /// Leading label for list avatars (`#<serialNo>` when present, otherwise `RD`).
  String get avatarLabel {
    final trimmed = serialNo?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed.startsWith(t.format.countSymbol)
          ? trimmed
          : '${t.format.countSymbol}$trimmed';
    }
    return schemeType.shortName;
  }

  /// Default sorting logic for Recurring Deposits (ascending by serial no).
  static int defaultCompare(RecurringDeposit a, RecurringDeposit b) {
    final sA = a.serialNo ?? '';
    final sB = b.serialNo ?? '';
    final numA = int.tryParse(sA);
    final numB = int.tryParse(sB);
    if (numA != null && numB != null) {
      return numA.compareTo(numB);
    }
    return sA.compareTo(sB);
  }

  factory RecurringDeposit.fromJson(Map<String, dynamic> json) =>
      _$RecurringDepositFromJson(json);

  static RecurringDeposit get dummy => RecurringDeposit(
    id: 'dummy',
    serialNo: '12',
    accountNo: t.common.loading,
    installmentAmount: 1000.0,
    termYears: 5,
    termMonths: 0,
    interestRate: 6.7,
    customerId: t.common.loading,
    customerName: t.common.loading,
    schemeType: RecurringSchemeType.recurringDeposit,
    startDate: DateTime.now(),
  );

  // --- Domain Validation Rules ---

  static String? validateAccountNo(String? accountNo) =>
      BaseDeposit.validateAccountNo(accountNo);

  static String? validateAmount(double? amount, String fieldName) =>
      BaseDeposit.validateAmount(amount, fieldName);

  static String? validateTerm(int years, int months) =>
      BaseDeposit.validateTerm(years, months);

  static String? validateInterestRate(double? rate, String fieldName) =>
      BaseDeposit.validateInterestRate(rate, fieldName);

  static Result<RecurringDeposit, String> create({
    required String id,
    String? serialNo,
    String? accountNo,
    required double installmentAmount,
    required String customerId,
    required RecurringSchemeType schemeType,
    required DateTime startDate,
    int? termYears,
    int? termMonths,
    double? interestRate,
    List<Nominee> nominees = const [],
    DepositStatus status = DepositStatus.active,
    PostalRateService postalRateService = const PostalRateService(),
  }) {
    final postalTerms = postalRateService.resolveRecurringSchemeTerms(
      schemeType: schemeType,
      startDate: startDate,
    );

    final resolvedTermYears = termYears ?? postalTerms.termYears;
    final resolvedTermMonths = termMonths ?? postalTerms.termMonths;
    final resolvedInterestRate = (interestRate != null && interestRate > 0)
        ? interestRate
        : postalTerms.interestRate;

    final validationError =
        BaseDeposit.validateAccountNo(accountNo) ??
        BaseDeposit.validateAmount(
          installmentAmount,
          t.recurringDeposits.fields.installmentAmount,
        ) ??
        BaseDeposit.validateTerm(resolvedTermYears, resolvedTermMonths) ??
        BaseDeposit.validateInterestRate(
          resolvedInterestRate,
          t.recurringDeposits.fields.interestRate,
        ) ??
        Nominee.validateNominees(nominees);

    if (validationError != null) return Failure(validationError);

    if (schemeType.tenureInputType != TenureInputType.derived) {
      if (!schemeType.allowedTenuresInYears.contains(resolvedTermYears)) {
        return Failure(
          t.errors.invalidTenure(
            years: resolvedTermYears,
            scheme: schemeType.displayName,
          ),
        );
      }
      if (resolvedTermMonths != 0) {
        return Failure(t.errors.fixedTenureNoMonths);
      }
    }

    return Success(
      RecurringDeposit(
        id: id,
        serialNo: serialNo?.trim().isEmpty == true ? null : serialNo?.trim(),
        accountNo: accountNo?.trim(),
        installmentAmount: installmentAmount,
        termYears: resolvedTermYears,
        termMonths: resolvedTermMonths,
        interestRate: resolvedInterestRate,
        customerId: customerId,
        schemeType: schemeType,
        startDate: startDate,
        nominees: List.unmodifiable(nominees),
        status: status,
      ),
    );
  }
}
