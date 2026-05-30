import "package:postfolio/core/constants/app_constants.dart";
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_colors.dart';

import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/firebase_options.dart';

// --- Pure Functions for Parsing ---

double _parseCurrency(String val) =>
    double.tryParse(val.replaceAll(RegExp(r'[₹,\s]'), '')) ?? 0.0;

double _parsePercentage(String val) =>
    double.tryParse(val.replaceAll('%', '').trim()) ?? 0.0;

DateTime _parseDate(String val) {
  try {
    return DateFormat('M/d/yyyy').parse(val.trim());
  } catch (_) {
    return DateTime.now(); // Fallback
  }
}

DepositStatus _parseStatus(String val) => val.trim().toUpperCase() == 'Y'
    ? DepositStatus.closed
    : DepositStatus.active;

NomineeRelationship _parseNomineeRelation(String val) {
  final s = val.toLowerCase().trim();
  if (s.contains('husband')) return NomineeRelationship.husband;
  if (s.contains('wife')) return NomineeRelationship.wife;
  if (s.contains('son')) return NomineeRelationship.son;
  if (s.contains('daughter')) return NomineeRelationship.daughter;
  if (s.contains('father')) return NomineeRelationship.father;
  if (s.contains('mother')) return NomineeRelationship.mother;
  if (s.contains('brother')) return NomineeRelationship.brother;
  if (s.contains('sister')) return NomineeRelationship.sister;
  if (s.contains('nephew')) return NomineeRelationship.nephew;
  if (s.contains('niece')) return NomineeRelationship.niece;
  return NomineeRelationship.other;
}

List<Nominee> _parseNominees(String name, String relation) {
  if (name.trim().isEmpty) return [];
  return [
    Nominee(
      name: name.trim(),
      relationship: _parseNomineeRelation(relation),
      percentage: AppConstants.maxPercentage,
      customRelationship:
          _parseNomineeRelation(relation) == NomineeRelationship.other
          ? relation.trim()
          : null,
    ),
  ];
}

OneTimeSchemeType _mapOneTimeScheme(String schemeStr) {
  final s = schemeStr.toLowerCase();
  if (s.contains('kvp')) return OneTimeSchemeType.kisanVikasPatra;
  if (s.contains('nsc')) return OneTimeSchemeType.nationalSavingsCertificate;
  if (s.contains('mis')) return OneTimeSchemeType.monthlyIncomeScheme;
  return OneTimeSchemeType.timeDeposit;
}

Customer _parseCustomer(List<dynamic> row, String id) {
  final dobStr = row.length > 3 ? row[3].toString().trim() : '';
  final dob = dobStr.isNotEmpty ? _parseDate(dobStr) : null;

  final sbAccountNumber = row.length > 7 ? row[7].toString().trim() : '';
  final sbNomineeName = row.length > 8 ? row[8].toString().trim() : '';
  final sbNomineeRel = row.length > 9 ? row[9].toString().trim() : '';

  SavingsAccount? savingsAccount;
  if (sbAccountNumber.isNotEmpty ||
      sbNomineeName.isNotEmpty ||
      sbNomineeRel.isNotEmpty) {
    savingsAccount = SavingsAccount(
      accountNumber: sbAccountNumber,
      nominees: _parseNominees(sbNomineeName, sbNomineeRel),
    );
  }

  return Customer(
    id: id,
    name: row.length > 0 ? row[0].toString().trim() : '',
    phone: row.length > 1 ? row[1].toString().trim() : '',
    cifNumber: row.length > 2 ? row[2].toString().trim() : '',
    dateOfBirth: dob,
    address: row.length > 4 ? row[4].toString().trim() : '',
    aadhaarNumber: row.length > 5 ? row[5].toString().trim() : '',
    panNumber: row.length > 6 ? row[6].toString().trim() : '',
    savingsAccount: savingsAccount,
  );
}

OneTimeDeposit _parseOneTimeDeposit(List<dynamic> row, String customerId) {
  final accountNo = row[0].toString().trim();
  return OneTimeDeposit(
    id: accountNo.replaceAll('/', '-'), // Sanitize for Firestore ID
    accountNo: accountNo,
    principalAmount: _parseCurrency(row.length > 1 ? row[1].toString() : ''),
    termYears:
        int.tryParse(row.length > 2 ? row[2].toString().trim() : '') ?? 0,
    termMonths:
        int.tryParse(row.length > 3 ? row[3].toString().trim() : '') ?? 0,
    interestRate: _parsePercentage(row.length > 4 ? row[4].toString() : ''),
    customerId: customerId,
    schemeType: _mapOneTimeScheme(row.length > 6 ? row[6].toString() : ''),
    startDate: _parseDate(row.length > 8 ? row[8].toString() : ''),
    nominees: _parseNominees(
      row.length > 10 ? row[10].toString() : '',
      row.length > 12 ? row[12].toString() : '',
    ),
    status: _parseStatus(row.length > 11 ? row[11].toString() : ''),
  );
}

RecurringDeposit _parseRecurringDeposit(List<dynamic> row, String customerId) {
  final accountNo = row[1].toString().trim();
  return RecurringDeposit(
    id: accountNo.replaceAll('/', '-'), // Sanitize for Firestore ID
    serialNo: row[0].toString().trim(),
    accountNo: accountNo,
    installmentAmount: _parseCurrency(row.length > 2 ? row[2].toString() : ''),
    termYears:
        int.tryParse(row.length > 3 ? row[3].toString().trim() : '') ??
        5, // Default to 5
    termMonths: 0,
    interestRate: _parsePercentage(row.length > 4 ? row[4].toString() : ''),
    customerId: customerId,
    schemeType: RecurringSchemeType.recurringDeposit,
    startDate: _parseDate(row.length > 7 ? row[7].toString() : ''),
    nominees: _parseNominees(
      row.length > 9 ? row[9].toString() : '',
      row.length > 11 ? row[11].toString() : '',
    ),
    status: _parseStatus(row.length > 10 ? row[10].toString() : ''),
  );
}

// --- Migration Stats Model ---

class MigrationStats {
  final int csvTotal;
  final int processed;
  final int migrated;
  final int skippedMissingCustomer;
  final int skippedDuplicate;

  MigrationStats({
    this.csvTotal = 0,
    this.processed = 0,
    this.migrated = 0,
    this.skippedMissingCustomer = 0,
    this.skippedDuplicate = 0,
  });

  @override
  String toString() {
    if (processed < csvTotal && processed > 0) {
      return t.migration.summaryBatch(
        processed: processed,
        total: csvTotal,
        migrated: migrated,
        duplicates: skippedDuplicate,
      );
    }
    return t.migration.summaryAll(
      total: csvTotal,
      migrated: migrated,
      missingCust: skippedMissingCustomer,
      duplicates: skippedDuplicate,
    );
  }
}

// --- Flutter App Shell for Migration ---

const bool useFirebaseEmulator = bool.fromEnvironment(
  'USE_EMULATOR',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useFirebaseEmulator) {
    try {
      final String host;
      if (kIsWeb) {
        host = 'localhost';
      } else {
        // Migration script might be run on Android emulator
        host = (defaultTargetPlatform == TargetPlatform.android)
            ? '10.0.2.2'
            : 'localhost';
      }
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      debugPrint('Connected to Firebase Emulator at $host');
    } catch (e) {
      debugPrint('Failed to connect to Firebase Emulator: $e');
    }
  } else {
    debugPrint('Connected to Firebase Production');
  }

  runApp(const MaterialApp(home: MigrationRunner()));
}

class MigrationRunner extends StatefulWidget {
  const MigrationRunner({super.key});

  @override
  State<MigrationRunner> createState() => _MigrationRunnerState();
}

class _MigrationRunnerState extends State<MigrationRunner> {
  String status = "Ready to migrate. Enter target UID or Sign In.";
  String statsDisplay = "";
  final _uuid = const Uuid();
  final _uidController = TextEditingController();
  final _countController = TextEditingController(text: '10');
  bool _isMigrating = false;

  final Map<String, String> _customerCache = {};
  final Map<String, String> _customerNameFallbackCache = {};
  final Set<String> _oneTimeCache = {};
  final Set<String> _recurringCache = {};

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _uidController.text = FirebaseAuth.instance.currentUser!.uid;
    } else {
      _uidController.text = 'test_user_123';
    }

    // Automatically run migration for 10 customers on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMigration(maxCustomers: 10);
    });
  }

  Future<void> _deleteAllData() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      setState(() => status = "Error: Please enter a target UID to delete.");
      return;
    }

    setState(() {
      _isMigrating = true;
      status = "Deleting all data for UID: $uid...";
    });

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);

    try {
      Future<void> deleteCollection(String name) async {
        final collection = userRef.collection(name);
        final snapshots = await collection.get();
        final batch = firestore.batch();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await deleteCollection('customers');
      await deleteCollection('one_time_deposits');
      await deleteCollection('recurring_deposits');

      _customerCache.clear();
      _customerNameFallbackCache.clear();
      _oneTimeCache.clear();
      _recurringCache.clear();

      setState(() {
        status = "All data deleted for $uid! 🔥";
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        status = "Delete Error: $e";
        _isMigrating = false;
      });
    }
  }

  Future<void> _signIn() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.addScope('email');
        final creds = await FirebaseAuth.instance.signInWithPopup(authProvider);
        if (creds.user != null) {
          setState(() {
            _uidController.text = creds.user!.uid;
            status = "Signed in as ${creds.user!.email}";
          });
        }
      } else {
        setState(
          () => status =
              "Sign in only supported on web migration. Please paste UID manually.",
        );
      }
    } catch (e) {
      setState(() => status = "Sign in error: $e");
    }
  }

  Future<void> _runMigration({int? maxCustomers}) async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      setState(() => status = "Error: Please enter a target UID or Sign In.");
      return;
    }

    setState(() {
      _isMigrating = true;
      status = "Starting migration for UID: $uid...";
      statsDisplay = "Scanning CSVs...";
    });

    final firestore = FirebaseFirestore.instance;

    try {
      final limit = maxCustomers ?? 999999;
      final custStats = await _migrateCustomers(firestore, uid, limit);
      final otStats = await _migrateDeposits(
        firestore,
        uid: uid,
        collectionName: 'one_time_deposits',
        csvPath: 'data/onetime_deposits.csv',
        cache: _oneTimeCache,
        parser: _parseOneTimeDeposit,
        customerNameIndex: 5,
        accountNoIndex: 0,
      );
      final rdStats = await _migrateDeposits(
        firestore,
        uid: uid,
        collectionName: 'recurring_deposits',
        csvPath: 'data/recurring_deposits.csv',
        cache: _recurringCache,
        parser: _parseRecurringDeposit,
        customerNameIndex: 5,
        accountNoIndex: 1,
      );

      setState(() {
        status = "Emulator Migration Complete! 🎉\nMigrated data to users/$uid";
        statsDisplay =
            """
--- Migration Summary ---
Customers: $custStats
One-Time: $otStats
Recurring: $rdStats
-------------------------
Check your Firebase Local Emulator UI.
""";
        _isMigrating = false;
      });
    } catch (e, stack) {
      setState(() {
        status = "Error: $e\n$stack";
        _isMigrating = false;
      });
    }
  }

  Future<MigrationStats> _migrateCustomers(
    FirebaseFirestore firestore,
    String uid,
    int maxCustomers,
  ) async {
    setState(
      () => status = "Migrating first $maxCustomers Customers to Emulator...",
    );
    final rawData = await rootBundle.loadString('data/customers.csv');
    final rows = const CsvToListConverter(eol: '\n').convert(rawData);

    var batch = firestore.batch();
    int migratedCount = 0;
    int csvTotal = 0;
    int duplicateCount = 0;
    int processedCount = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row[0].toString().trim().isEmpty) continue;
      csvTotal++;

      if (migratedCount >= maxCustomers) continue;
      processedCount++;

      final name = row.length > 0 ? row[0].toString().trim() : '';
      final phone = row.length > 1 ? row[1].toString().trim() : '';
      final cacheKey = '${name}_$phone';

      if (!_customerCache.containsKey(cacheKey)) {
        final newId = _uuid.v4();
        final customer = _parseCustomer(row, newId);

        batch.set(
          firestore
              .collection('users')
              .doc(uid)
              .collection('customers')
              .doc(newId),
          customer.toJson(),
        );

        _customerCache[cacheKey] = newId;
        _customerNameFallbackCache[name] = newId;
        migratedCount++;

        if (migratedCount % AppConstants.firestoreBatchLimit == 0) {
          await batch.commit();
          batch = firestore.batch();
        }
      } else {
        duplicateCount++;
      }
    }

    if (migratedCount % AppConstants.firestoreBatchLimit != 0 ||
        (migratedCount > 0 &&
            migratedCount < AppConstants.firestoreBatchLimit)) {
      await batch.commit();
    }

    return MigrationStats(
      csvTotal: csvTotal,
      processed: processedCount,
      migrated: migratedCount,
      skippedDuplicate: duplicateCount,
    );
  }

  Future<MigrationStats> _migrateDeposits(
    FirebaseFirestore firestore, {
    required String uid,
    required String collectionName,
    required String csvPath,
    required Set<String> cache,
    required dynamic Function(List<dynamic>, String) parser,
    required int customerNameIndex,
    required int accountNoIndex,
  }) async {
    setState(
      () => status = "Migrating $collectionName for imported customers...",
    );
    final rawData = await rootBundle.loadString(csvPath);
    final rows = const CsvToListConverter(eol: '\n').convert(rawData);

    var batch = firestore.batch();
    int migratedCount = 0;
    int csvTotal = 0;
    int missingCustomerCount = 0;
    int duplicateCount = 0;
    int relevantToBatch = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row[0].toString().trim().isEmpty) continue;
      csvTotal++;

      final accountNo = row.length > accountNoIndex
          ? row[accountNoIndex].toString().trim()
          : '';
      final customerName = row.length > customerNameIndex
          ? row[customerNameIndex].toString().trim()
          : '';

      final customerId = _customerNameFallbackCache[customerName];

      if (customerId != null) {
        relevantToBatch++;
        if (!cache.contains(accountNo)) {
          final deposit = parser(row, customerId);

          batch.set(
            firestore
                .collection('users')
                .doc(uid)
                .collection(collectionName)
                .doc(deposit.id),
            deposit.toJson(),
          );

          cache.add(accountNo);
          migratedCount++;

          if (migratedCount % AppConstants.firestoreBatchLimit == 0) {
            await batch.commit();
            batch = firestore.batch();
          }
        } else {
          duplicateCount++;
        }
      } else {
        missingCustomerCount++;
      }
    }

    if (migratedCount % AppConstants.firestoreBatchLimit != 0 ||
        (migratedCount > 0 &&
            migratedCount < AppConstants.firestoreBatchLimit)) {
      await batch.commit();
    }

    return MigrationStats(
      csvTotal: csvTotal,
      processed: relevantToBatch,
      migrated: migratedCount,
      skippedMissingCustomer: missingCustomerCount,
      skippedDuplicate: duplicateCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.migration.title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _uidController,
                decoration: InputDecoration(
                  labelText: t.migration.targetUid,
                  helperText: t.migration.targetUidHelper,
                  border: const OutlineInputBorder(),
                ),
              ),
              AppSpacings.gapLg,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.migration.batchSize,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  AppSpacings.gapLg,
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: Text(t.migration.signIn),
                    onPressed: _isMigrating ? null : _signIn,
                  ),
                ],
              ),
              AppSpacings.gapXl,
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isMigrating
                        ? null
                        : () {
                            final count =
                                int.tryParse(_countController.text) ?? 10;
                            _runMigration(maxCustomers: count);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                    ),
                    child: Text(t.migration.migrateBatch),
                  ),
                  ElevatedButton(
                    onPressed: _isMigrating
                        ? null
                        : () => _runMigration(maxCustomers: null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.surface,
                    ),
                    child: Text(t.migration.migrateAll),
                  ),
                  ElevatedButton(
                    onPressed: _isMigrating ? null : _deleteAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.surface,
                    ),
                    child: Text(t.migration.deleteAll),
                  ),
                ],
              ),
              AppSpacings.gapXxl,
              if (_isMigrating) const CircularProgressIndicator(),
              AppSpacings.gapLg,
              Text(
                status,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              if (statsDisplay.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingXl,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingLg),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: SelectableText(
                    statsDisplay,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
