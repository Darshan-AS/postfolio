import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/postal_scheme_terms.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'one_time_deposit_model.freezed.dart';
part 'one_time_deposit_model.g.dart';

@freezed
sealed class OneTimeDeposit with _$OneTimeDeposit implements BaseDeposit {
  const OneTimeDeposit._();

  static const PostalRateService _postalRateService = PostalRateService();

  const factory OneTimeDeposit({
    required String id,
    String? accountNo,
    required double principalAmount,
    required int termYears,
    required int termMonths,
    required double interestRate,
    required String customerId,
    @JsonKey(includeFromJson: true, includeToJson: false) String? customerName,
    required OneTimeSchemeType schemeType,
    required DateTime startDate,
    @Default([]) List<Nominee> nominees,
    @Default(DepositStatus.active) DepositStatus status,
    @TimestampConverter() @JsonKey(includeIfNull: false) DateTime? createdAt,
    @TimestampConverter() @JsonKey(includeIfNull: false) DateTime? updatedAt,
    @JsonKey(includeIfNull: false) String? migrationSource,
  }) = _OneTimeDeposit;

  /// Official Post Office terms for [schemeType] and [startDate].
  PostalSchemeTerms get postalTerms =>
      _postalRateService.resolveOneTimeSchemeTerms(
        schemeType: schemeType,
        startDate: startDate,
        tdTenureYears: termYears,
      );

  /// Effective interest rate, resolving from the Postal Service if not stored.
  double get effectiveInterestRate =>
      interestRate > 0 ? interestRate : postalTerms.interestRate;

  /// Effective tenure years, self-healing legacy KVP defaults or formula
  /// rounding drift while respecting intentional custom overrides.
  int get effectiveTermYears {
    if (schemeType == OneTimeSchemeType.kisanVikasPatra) {
      final months = _postalRateService.resolveEffectiveKvpMonths(
        interestRate: effectiveInterestRate,
        startDate: startDate,
        termYears: termYears,
        termMonths: termMonths,
      );
      return months ~/ 12;
    }
    return termYears > 0 ? termYears : postalTerms.termYears;
  }

  /// Effective tenure months, self-healing legacy KVP defaults or formula
  /// rounding drift while respecting intentional custom overrides.
  int get effectiveTermMonths {
    if (schemeType == OneTimeSchemeType.kisanVikasPatra) {
      final months = _postalRateService.resolveEffectiveKvpMonths(
        interestRate: effectiveInterestRate,
        startDate: startDate,
        termYears: termYears,
        termMonths: termMonths,
      );
      return months % 12;
    }
    return termMonths;
  }

  @override
  InvestmentProjection get projection =>
      ProjectionCalculator.calculateOneTimeDeposit(
        schemeType: schemeType,
        principalAmount: principalAmount,
        interestRate: effectiveInterestRate,
        startDate: startDate,
        termYears: effectiveTermYears,
        termMonths: effectiveTermMonths,
      );

  @override
  double get maturityAmount => projection.maturityAmount;

  @override
  DateTime get maturityDate => projection.maturityDate;

  /// Default sorting logic for One Time Deposits (ascending by maturity date).
  static int defaultCompare(OneTimeDeposit a, OneTimeDeposit b) {
    return a.maturityDate.compareTo(b.maturityDate);
  }

  factory OneTimeDeposit.fromJson(Map<String, dynamic> json) =>
      _$OneTimeDepositFromJson(json);

  static OneTimeDeposit get dummy => OneTimeDeposit(
    id: 'dummy',
    accountNo: 'Loading...',
    principalAmount: 10000.0,
    termYears: 5,
    termMonths: 0,
    interestRate: 7.5,
    customerId: 'Loading Dummy Name...',
    customerName: 'Loading Dummy Name...',
    schemeType: OneTimeSchemeType.timeDeposit,
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

  static Result<OneTimeDeposit, String> create({
    required String id,
    String? accountNo,
    required double principalAmount,
    required String customerId,
    required OneTimeSchemeType schemeType,
    required DateTime startDate,
    int? termYears,
    int? termMonths,
    double? interestRate,
    List<Nominee> nominees = const [],
    DepositStatus status = DepositStatus.active,
    PostalRateService postalRateService = const PostalRateService(),
  }) {
    final postalTerms = postalRateService.resolveOneTimeSchemeTerms(
      schemeType: schemeType,
      startDate: startDate,
      tdTenureYears: termYears,
    );

    final resolvedInterestRate = (interestRate != null && interestRate > 0)
        ? interestRate
        : postalTerms.interestRate;

    final int resolvedTermYears;
    final int resolvedTermMonths;

    if (schemeType == OneTimeSchemeType.kisanVikasPatra) {
      final effectiveMonths = postalRateService.resolveEffectiveKvpMonths(
        interestRate: resolvedInterestRate,
        startDate: startDate,
        termYears: termYears,
        termMonths: termMonths,
      );
      resolvedTermYears = effectiveMonths ~/ 12;
      resolvedTermMonths = effectiveMonths % 12;
    } else {
      resolvedTermYears = termYears ?? postalTerms.termYears;
      resolvedTermMonths = termMonths ?? postalTerms.termMonths;
    }

    final validationError =
        BaseDeposit.validateAccountNo(accountNo) ??
        BaseDeposit.validateAmount(
          principalAmount,
          t.oneTimeDeposits.fields.principalAmount,
        ) ??
        BaseDeposit.validateTerm(resolvedTermYears, resolvedTermMonths) ??
        BaseDeposit.validateInterestRate(
          resolvedInterestRate,
          t.oneTimeDeposits.fields.interestRate,
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
      OneTimeDeposit(
        id: id,
        accountNo: accountNo?.trim(),
        principalAmount: principalAmount,
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
