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

import 'package:postfolio/core/constants/firestore_keys.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/firebase_options.dart';

// --- Migration Assets ---

class MigrationAssets {
  static const String customers = 'data/customers.csv';
  static const String oneTimeDeposits = 'data/onetime_deposits.csv';
  static const String recurringDeposits = 'data/recurring_deposits.csv';
}

// --- Csv Headers Helper ---
class CsvHeaders {
  final Map<String, int> _indices = {};

  CsvHeaders(List<dynamic> headerRow) {
    for (int i = 0; i < headerRow.length; i++) {
      _indices[headerRow[i].toString().trim()] = i;
    }
  }

  String getString(
    List<dynamic> row,
    String columnName, {
    String defaultValue = '',
  }) {
    final index = _indices[columnName];
    if (index == null || index >= row.length) return defaultValue;
    return row[index].toString().trim();
  }
}

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

DateTime? _parseDateOrNull(String val) {
  if (val.trim().isEmpty) return null;
  try {
    return DateFormat('M/d/yyyy h:mm:ss a').parse(val.trim());
  } catch (_) {
    try {
      return DateFormat('M/d/yyyy').parse(val.trim());
    } catch (_) {
      return DateTime.tryParse(val.trim());
    }
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

Customer _parseCustomer(
  List<dynamic> row,
  CsvHeaders headers,
  DateTime? earliestDepositDate,
) {
  final idStr = headers.getString(row, 'Row ID');
  final id = idStr.isNotEmpty ? idStr : const Uuid().v4();
  final name = headers.getString(row, 'Name');
  final phone = headers.getString(row, 'Mobile');
  final cifNumber = headers.getString(row, 'CIF');
  final dobStr = headers.getString(row, 'DOB');
  final dob = dobStr.isNotEmpty ? _parseDate(dobStr) : null;
  final address = headers.getString(row, 'Address');
  final aadhaarNumber = headers.getString(row, 'Aadhaar');
  final panNumber = headers.getString(row, 'PAN');
  final sbAccountNumber = headers.getString(row, 'SB Account No.');
  final sbNomineeName = headers.getString(row, 'SB Nominee');
  final sbNomineeRel = headers.getString(row, 'SB Nominee Relationship');
  final rowCreatedAt = _parseDateOrNull(headers.getString(row, 'Created On'));
  final rowUpdatedAt = _parseDateOrNull(headers.getString(row, 'Updated On'));

  SavingsAccount? savingsAccount;
  String? migrationNotes;

  if (sbAccountNumber.isNotEmpty) {
    savingsAccount = SavingsAccount(
      accountNumber: sbAccountNumber,
      nominees: _parseNominees(sbNomineeName, sbNomineeRel),
    );
  } else if (sbNomineeName.isNotEmpty || sbNomineeRel.isNotEmpty) {
    final nominees = _parseNominees(sbNomineeName, sbNomineeRel);
    if (nominees.isNotEmpty) {
      final nomineeDetails = nominees.map((n) {
        final nName = n.name;
        final nRelation = n.customRelationship ?? n.relationship.name;
        final nPct = n.percentage;
        return "$nName ($nRelation - $nPct%)";
      }).join(', ');
      
      migrationNotes = "Legacy Nominees: $nomineeDetails";
    }
  }

  return Customer(
    id: id,
    name: name,
    phone: phone,
    cifNumber: cifNumber,
    dateOfBirth: dob,
    address: address,
    aadhaarNumber: aadhaarNumber,
    panNumber: panNumber,
    savingsAccount: savingsAccount,
    notes: migrationNotes,
    createdAt: rowCreatedAt ?? earliestDepositDate,
    updatedAt: rowUpdatedAt ?? earliestDepositDate,
    migrationSource: 'legacy_csv_v1_${DateTime.now().toIso8601String()}',
  );
}

OneTimeDeposit _parseOneTimeDeposit(List<dynamic> row, CsvHeaders headers) {
  final idStr = headers.getString(row, 'Id');
  final id = idStr.isNotEmpty ? idStr : const Uuid().v4();
  final accountNo = headers.getString(row, 'Account No.');
  final customerId = headers.getString(row, 'Customer Id');
  final createdAtStr = headers.getString(row, 'Created On');
  final updatedAtStr = headers.getString(row, 'Updated On');
  return OneTimeDeposit(
    id: id,
    accountNo: accountNo.isEmpty ? null : accountNo,
    principalAmount: _parseCurrency(headers.getString(row, 'Amount')),
    termYears: int.tryParse(headers.getString(row, 'Term Years')) ?? 0,
    termMonths: int.tryParse(headers.getString(row, 'Term Months')) ?? 0,
    interestRate: _parsePercentage(headers.getString(row, 'Interest Rate')),
    customerId: customerId,
    schemeType: _mapOneTimeScheme(headers.getString(row, 'Scheme')),
    startDate: _parseDate(headers.getString(row, 'Deposit Date')),
    nominees: _parseNominees(
      headers.getString(row, 'Nominee'),
      headers.getString(row, 'Nominee Relationship'),
    ),
    status: _parseStatus(headers.getString(row, 'Closed')),
    createdAt: _parseDateOrNull(createdAtStr),
    updatedAt: _parseDateOrNull(updatedAtStr),
    migrationSource: 'legacy_csv_v1_${DateTime.now().toIso8601String()}',
  );
}

RecurringDeposit _parseRecurringDeposit(List<dynamic> row, CsvHeaders headers) {
  final idStr = headers.getString(row, 'Id');
  final id = idStr.isNotEmpty ? idStr : const Uuid().v4();
  final serialNo = headers.getString(row, 'Serial No.');
  final accountNo = headers.getString(row, 'Account No.');
  final customerId = headers.getString(row, 'Customer Id');
  final createdAtStr = headers.getString(row, 'Created On');
  final updatedAtStr = headers.getString(row, 'Updated On');
  return RecurringDeposit(
    id: id,
    serialNo: serialNo,
    accountNo: accountNo.isEmpty ? null : accountNo,
    installmentAmount: _parseCurrency(headers.getString(row, 'Amount')),
    termYears:
        int.tryParse(headers.getString(row, 'Term Years')) ?? 5, // Default to 5
    termMonths: 0,
    interestRate: _parsePercentage(headers.getString(row, 'Interest Rate')),
    customerId: customerId,
    schemeType: RecurringSchemeType.recurringDeposit,
    startDate: _parseDate(headers.getString(row, 'Opening Date')),
    nominees: _parseNominees(
      headers.getString(row, 'Nominee'),
      headers.getString(row, 'Nominee Relationship'),
    ),
    status: _parseStatus(headers.getString(row, 'Closed')),
    createdAt: _parseDateOrNull(createdAtStr),
    updatedAt: _parseDateOrNull(updatedAtStr),
    migrationSource: 'legacy_csv_v1_${DateTime.now().toIso8601String()}',
  );
}

// --- Migration Stats Model ---

class MigrationStats {
  final int csvTotal;
  final int processed;
  final int migrated;
  final int skippedMissingCustomer;
  final int skippedDuplicate;
  final int emptyAccountMigrated;
  final int invalidNomineesMigrated;
  final int errorCount;
  final List<String> diffLog;

  MigrationStats({
    this.csvTotal = 0,
    this.processed = 0,
    this.migrated = 0,
    this.skippedMissingCustomer = 0,
    this.skippedDuplicate = 0,
    this.emptyAccountMigrated = 0,
    this.invalidNomineesMigrated = 0,
    this.errorCount = 0,
    this.diffLog = const [],
  });

  String get diffText =>
      diffLog.isEmpty ? "" : "\nDetails:\n${diffLog.join('\n')}";

  @override
  String toString() {
    String summary;
    if (processed < csvTotal && processed > 0) {
      summary = t.migration.summaryBatch(
        processed: processed,
        total: csvTotal,
        migrated: migrated,
        duplicates: skippedDuplicate,
        emptyAccounts: emptyAccountMigrated,
        errors: errorCount,
      );
    } else {
      summary = t.migration.summaryAll(
        total: csvTotal,
        migrated: migrated,
        missingCust: skippedMissingCustomer,
        duplicates: skippedDuplicate,
        emptyAccounts: emptyAccountMigrated,
        errors: errorCount,
      );
    }
    
    if (invalidNomineesMigrated > 0) {
      summary += "\nInvalid Nominees Migrated to Notes: $invalidNomineesMigrated";
    }
    
    return "$summary$diffText";
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
  final _uidController = TextEditingController();
  final _countController = TextEditingController(text: '10');
  bool _isMigrating = false;

  final Map<String, String> _customerCache = {};
  final Set<String> _oneTimeCache = {};
  final Set<String> _recurringCache = {};

  @override
  void initState() {
    super.initState();
    final env = useFirebaseEmulator ? "Emulator" : "PRODUCTION";
    status = "Ready to migrate ($env). Enter target UID or Sign In.";

    if (FirebaseAuth.instance.currentUser != null) {
      _uidController.text = FirebaseAuth.instance.currentUser!.uid;
    } else {
      _uidController.text = 'test_user_123';
    }

    // Automatically run migration for 10 customers on start (Emulator only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (useFirebaseEmulator) {
        _runMigration(maxCustomers: 10);
      }
    });
  }

  Future<bool> _confirmProductionAction(String title, String message) async {
    if (useFirebaseEmulator) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text("Proceed"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteAllData() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      setState(() => status = "Error: Please enter a target UID to delete.");
      return;
    }

    if (!await _confirmProductionAction(
      "Confirm Deletion",
      "You are in PRODUCTION mode. This will PERMANENTLY delete all customers and deposits for UID: $uid. Are you sure?",
    )) {
      return;
    }

    setState(() {
      _isMigrating = true;
      status = "Deleting all data for UID: $uid...";
    });

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection(FirestoreCollections.users).doc(uid);

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

      await deleteCollection(FirestoreCollections.customers);
      await deleteCollection(FirestoreCollections.oneTimeDeposits);
      await deleteCollection(FirestoreCollections.recurringDeposits);

      _customerCache.clear();
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

    if (!await _confirmProductionAction(
      "Confirm Migration",
      "You are in PRODUCTION mode. This will write data to the real Firestore for UID: $uid. Proceed?",
    )) {
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

      // Pre-calculate earliest deposit dates for customers
      final customerEarliestDates = await _calculateCustomerDates();

      final custStats = await _migrateCustomers(
        firestore,
        uid,
        limit,
        customerEarliestDates,
      );
      final otStats = await _migrateDeposits(
        firestore,
        uid: uid,
        collectionName: FirestoreCollections.oneTimeDeposits,
        csvPath: MigrationAssets.oneTimeDeposits,
        cache: _oneTimeCache,
        parser: _parseOneTimeDeposit,
      );
      final rdStats = await _migrateDeposits(
        firestore,
        uid: uid,
        collectionName: FirestoreCollections.recurringDeposits,
        csvPath: MigrationAssets.recurringDeposits,
        cache: _recurringCache,
        parser: _parseRecurringDeposit,
      );

      setState(() {
        final envLabel = useFirebaseEmulator ? "Emulator" : "Production";
        status =
            "$envLabel Migration Complete! 🎉\nMigrated data to users/$uid";
        statsDisplay =
            """
--- Migration Summary ---
Customers: $custStats
One-Time: $otStats
Recurring: $rdStats
-------------------------
${useFirebaseEmulator ? "Check your Firebase Local Emulator UI." : "Data is now live in Production Firestore."}
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

  Future<void> _migrateInvalidNominees() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      setState(() => status = "Error: Please enter a target UID or Sign In.");
      return;
    }

    if (!await _confirmProductionAction(
      "Confirm Nominee Migration",
      "You are in PRODUCTION mode. This will migrate invalid nominees to notes for UID: $uid. Proceed?",
    )) {
      return;
    }

    setState(() {
      _isMigrating = true;
      status = "Scanning customers for invalid nominees...";
      statsDisplay = "";
    });

    final firestore = FirebaseFirestore.instance;
    try {
      final customersRef = firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .collection(FirestoreCollections.customers);

      final snapshot = await customersRef.get();
      var batch = firestore.batch();
      int migratedCount = 0;
      int processedCount = snapshot.docs.length;
      final List<String> diffLog = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final savingsAccount = data['savingsAccount'] as Map<String, dynamic>?;
        if (savingsAccount != null) {
          final accountNo = savingsAccount['accountNumber'] as String?;
          final nominees = savingsAccount['nominees'] as List<dynamic>?;

          if ((accountNo == null || accountNo.trim().isEmpty) && nominees != null && nominees.isNotEmpty) {
            // Found invalid nominee!
            final nomineeDetails = nominees.map((n) {
              final name = n['name'] ?? '';
              final relation = n['customRelationship'] ?? n['relationship'] ?? '';
              final pct = n['percentage'] ?? 100;
              return "$name ($relation - $pct%)";
            }).join(', ');
            
            final noteText = "Legacy Nominees: $nomineeDetails";
            
            final existingNotes = data['notes'] as String?;
            final newNotes = existingNotes != null && existingNotes.isNotEmpty 
                ? "$existingNotes\n$noteText" 
                : noteText;
                
            Map<String, dynamic> updateData = {
               'notes': newNotes,
               'updatedAt': FieldValue.serverTimestamp(),
               'savingsAccount': FieldValue.delete(),
            };
            
            final customerName = data['name'] as String? ?? 'Unknown Name';
            
            batch.update(doc.reference, updateData);
            migratedCount++;
            diffLog.add("Customer ID: ${doc.id} ($customerName) - Added to notes: $noteText");
            
            if (migratedCount % AppConstants.firestoreBatchLimit == 0) {
               await batch.commit();
               batch = firestore.batch();
            }
          }
        }
      }
      
      if (migratedCount > 0 && migratedCount % AppConstants.firestoreBatchLimit != 0) {
        await batch.commit();
      }
      
      setState(() {
         status = "Nominee Migration Complete! 🎉";
         statsDisplay = "Processed: $processedCount\nMigrated: $migratedCount\n${diffLog.isNotEmpty ? '\nDetails:\n${diffLog.join('\n')}' : ''}";
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
    Map<String, DateTime> customerEarliestDates,
  ) async {
    final envLabel = useFirebaseEmulator ? "Emulator" : "Production";
    setState(
      () => status = "Migrating first $maxCustomers Customers to $envLabel...",
    );
    final rawData = await rootBundle.loadString(MigrationAssets.customers);
    final rows = const CsvToListConverter(eol: '\n').convert(rawData);
    if (rows.isEmpty) return MigrationStats();

    final headers = CsvHeaders(rows.first);

    var batch = firestore.batch();
    int migratedCount = 0;
    int csvTotal = 0;
    int duplicateCount = 0;
    int processedCount = 0;
    int errorCount = 0;
    int invalidNomineesMigrated = 0;
    final List<String> diffLog = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) {
        continue;
      }
      csvTotal++;

      if (migratedCount >= maxCustomers) continue;
      processedCount++;

      try {
        final id = headers.getString(row, 'Row ID');
        if (id.isEmpty) {
          errorCount++;
          diffLog.add("Skipped (Row ${i + 1}): Missing Customer ID (Row ID)");
          continue;
        }

        if (!_customerCache.containsKey(id)) {
          final earliestDate = customerEarliestDates[id];
          final customer = _parseCustomer(row, headers, earliestDate);
          final data = customer.toJson();
          data['createdAt'] ??= FieldValue.serverTimestamp();
          data['updatedAt'] ??= FieldValue.serverTimestamp();

          batch.set(
            firestore
                .collection(FirestoreCollections.users)
                .doc(uid)
                .collection(FirestoreCollections.customers)
                .doc(customer.id),
            data,
          );

          if (customer.notes?.startsWith("Legacy Nominees:") == true) {
             diffLog.add("Customer ID: ${customer.id} (${customer.name}) - Legacy Nominees migrated to notes: ${customer.notes}");
             invalidNomineesMigrated++;
          }

          _customerCache[id] = customer.id;
          migratedCount++;

          if (migratedCount % AppConstants.firestoreBatchLimit == 0) {
            await batch.commit();
            batch = firestore.batch();
          }
        } else {
          duplicateCount++;
          diffLog.add("Duplicate Customer ID: $id");
        }
      } catch (e) {
        errorCount++;
        diffLog.add("Error (Row ${i + 1}): $e");
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
      invalidNomineesMigrated: invalidNomineesMigrated,
      errorCount: errorCount,
      diffLog: diffLog,
    );
  }

  Future<MigrationStats> _migrateDeposits(
    FirebaseFirestore firestore, {
    required String uid,
    required String collectionName,
    required String csvPath,
    required Set<String> cache,
    required dynamic Function(List<dynamic>, CsvHeaders) parser,
  }) async {
    setState(
      () => status = "Migrating $collectionName for imported customers...",
    );
    final rawData = await rootBundle.loadString(csvPath);
    final rows = const CsvToListConverter(eol: '\n').convert(rawData);
    if (rows.isEmpty) return MigrationStats();

    final headers = CsvHeaders(rows.first);

    var batch = firestore.batch();
    int migratedCount = 0;
    int csvTotal = 0;
    int missingCustomerCount = 0;
    int duplicateCount = 0;
    int relevantToBatch = 0;
    int emptyAccountMigratedCount = 0;
    int errorCount = 0;
    final List<String> diffLog = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) {
        continue;
      }
      csvTotal++;

      try {
        final accountNo = headers.getString(row, 'Account No.');
        final customerId = headers.getString(row, 'Customer Id');

        if (customerId.isEmpty) {
          errorCount++;
          diffLog.add("Skipped (Row ${i + 1}): Missing Customer ID in CSV");
          continue;
        }

        final bool customerExists = _customerCache.containsKey(customerId);

        if (customerExists) {
          relevantToBatch++;
          final isDuplicate = accountNo.isNotEmpty && cache.contains(accountNo);

          if (!isDuplicate) {
            final deposit = parser(row, headers);
            final data = deposit.toJson();
            data['createdAt'] ??= FieldValue.serverTimestamp();
            data['updatedAt'] ??= FieldValue.serverTimestamp();

            batch.set(
              firestore
                  .collection(FirestoreCollections.users)
                  .doc(uid)
                  .collection(collectionName)
                  .doc(deposit.id),
              data,
            );

            if (accountNo.isNotEmpty) {
              cache.add(accountNo);
            } else {
              emptyAccountMigratedCount++;
              diffLog.add(
                "Migrated Empty Account (Generated ID: ${deposit.id})",
              );
            }
            migratedCount++;

            if (migratedCount % AppConstants.firestoreBatchLimit == 0) {
              await batch.commit();
              batch = firestore.batch();
            }
          } else {
            duplicateCount++;
            diffLog.add("Duplicate Account: $accountNo");
          }
        } else {
          missingCustomerCount++;
          diffLog.add(
            "Missing Customer ID: $customerId (Account: ${accountNo.isEmpty ? 'Empty' : accountNo})",
          );
        }
      } catch (e) {
        errorCount++;
        diffLog.add("Error (Row ${i + 1}): $e");
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
      emptyAccountMigrated: emptyAccountMigratedCount,
      errorCount: errorCount,
      diffLog: diffLog,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                  vertical: AppDimensions.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: useFirebaseEmulator
                      ? Theme.of(
                          context,
                        ).colorScheme.tertiary.withValues(alpha: 0.1)
                      : Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: useFirebaseEmulator
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      useFirebaseEmulator ? Icons.bug_report : Icons.warning,
                      color: useFirebaseEmulator
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                    AppSpacings.gapSm,
                    Text(
                      useFirebaseEmulator ? "EMULATOR MODE" : "PRODUCTION MODE",
                      style: TextStyle(
                        color: useFirebaseEmulator
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacings.gapXl,
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(t.migration.migrateBatch),
                  ),
                  ElevatedButton(
                    onPressed: _isMigrating
                        ? null
                        : () => _runMigration(maxCustomers: null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    ),
                    child: Text(t.migration.migrateAll),
                  ),
                  ElevatedButton(
                    onPressed: _isMigrating ? null : _migrateInvalidNominees,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                    child: const Text("Migrate Invalid Nominees"),
                  ),
                  ElevatedButton(
                    onPressed: _isMigrating ? null : _deleteAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
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

Future<Map<String, DateTime>> _calculateCustomerDates() async {
  final customerEarliestDate = <String, DateTime>{};

  void processRows(
    List<List<dynamic>> rows,
    CsvHeaders headers,
    String dateColumn,
  ) {
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) {
        continue;
      }

      final customerId = headers.getString(row, 'Customer Id');
      final dateStr = headers.getString(row, dateColumn);

      if (customerId.isNotEmpty && dateStr.isNotEmpty) {
        final date = _parseDateOrNull(dateStr);
        if (date != null) {
          if (!customerEarliestDate.containsKey(customerId) ||
              date.isBefore(customerEarliestDate[customerId]!)) {
            customerEarliestDate[customerId] = date;
          }
        }
      }
    }
  }

  try {
    final otRaw = await rootBundle.loadString(MigrationAssets.oneTimeDeposits);
    final otRows = const CsvToListConverter(eol: '\n').convert(otRaw);
    if (otRows.isNotEmpty) {
      processRows(otRows, CsvHeaders(otRows.first), 'Deposit Date');
    }

    final rdRaw = await rootBundle.loadString(
      MigrationAssets.recurringDeposits,
    );
    final rdRows = const CsvToListConverter(eol: '\n').convert(rdRaw);
    if (rdRows.isNotEmpty) {
      processRows(rdRows, CsvHeaders(rdRows.first), 'Opening Date');
    }
  } catch (e) {
    debugPrint("Error calculating customer dates: $e");
  }

  return customerEarliestDate;
}
