import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

/// The Dart enums own the vocabularies; Postgres mirrors them in CHECK constraints so a
/// token no client can decode is rejected at the door. This test fails when the two lists
/// drift: adding an enum value needs a migration that extends the matching CHECK.
void main() {
  // Every `ADD CONSTRAINT <name> CHECK (<column> IN (...))` across the migrations, in file
  // order; a later migration that redefines a constraint wins.
  final constraints = <String, Set<String>>{};
  setUpAll(() {
    final files = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final definition = RegExp(
      r'ADD CONSTRAINT (\w+)\s+CHECK \(\s*\w+ IN \(([^)]*)\)\s*\)',
      multiLine: true,
    );
    final token = RegExp("'([^']+)'");
    for (final file in files) {
      for (final match in definition.allMatches(file.readAsStringSync())) {
        constraints[match.group(1)!] = {
          for (final t in token.allMatches(match.group(2)!)) t.group(1)!,
        };
      }
    }
  });

  final day = DateTime(2026, 1, 15);

  String otdWire(String key, {OneTimeSchemeType? scheme, DepositStatus? status}) =>
      OneTimeDeposit(
        id: 'x',
        principalAmount: 1000,
        termYears: 5,
        termMonths: 0,
        interestRate: 7.5,
        customerId: 'c',
        schemeType: scheme ?? OneTimeSchemeType.timeDeposit,
        startDate: day,
        status: status ?? DepositStatus.active,
      ).toJson()[key] as String;

  String rdWire(String key, {RecurringSchemeType? scheme, DepositStatus? status}) =>
      RecurringDeposit(
        id: 'x',
        installmentAmount: 1000,
        termYears: 5,
        termMonths: 0,
        interestRate: 6.7,
        customerId: 'c',
        schemeType: scheme ?? RecurringSchemeType.recurringDeposit,
        startDate: day,
        status: status ?? DepositStatus.active,
      ).toJson()[key] as String;

  final cases = <String, Set<String> Function()>{
    'one_time_deposits_status_check': () =>
        {for (final s in DepositStatus.values) otdWire('status', status: s)},
    'recurring_deposits_status_check': () =>
        {for (final s in DepositStatus.values) rdWire('status', status: s)},
    'one_time_deposits_scheme_type_check': () =>
        {for (final s in OneTimeSchemeType.values) otdWire('scheme_type', scheme: s)},
    'recurring_deposits_scheme_type_check': () =>
        {for (final s in RecurringSchemeType.values) rdWire('scheme_type', scheme: s)},
    'nominees_relationship_check': () => {
          for (final r in NomineeRelationship.values)
            Nominee(name: 'n', relationship: r, percentage: 100).toJson()['relationship']
                as String,
        },
    'rd_transactions_payment_mode_check': () => {
          for (final m in RDPaymentMode.values)
            RDTransaction(id: 't', rdId: 'r', paidDate: day, amount: 1, paymentMode: m)
                .toJson()['payment_mode'] as String,
        },
  };

  for (final entry in cases.entries) {
    test('SQL CHECK ${entry.key} lists exactly the Dart enum wire values', () {
      expect(
        constraints[entry.key],
        isNotNull,
        reason: 'no `ADD CONSTRAINT ${entry.key} CHECK (... IN (...))` found in supabase/migrations',
      );
      expect(constraints[entry.key], entry.value());
    });
  }
}
