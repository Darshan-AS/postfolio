import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import 'package:postfolio/firebase_options.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/constants/firestore_keys.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

// --- Migration Constants ---
const String defaultSupabaseUrl = 'http://localhost:54321';
const String defaultServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';
const String defaultUsersAssetPath = 'data/users.json';
const bool useFirebaseEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useFirebaseEmulator) {
    try {
      const host = '127.0.0.1';
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      debugPrint('Connected to Firebase Emulator at $host');
    } catch (e) {
      debugPrint('Failed to connect to Firebase Emulator: $e');
    }
  }

  runApp(const MaterialApp(
    title: 'Firebase to Supabase Migrator',
    home: SupabaseMigrationRunnerScreen(),
  ));
}

class SupabaseMigrationRunnerScreen extends StatefulWidget {
  const SupabaseMigrationRunnerScreen({super.key});

  @override
  State<SupabaseMigrationRunnerScreen> createState() => _SupabaseMigrationRunnerScreenState();
}

class _SupabaseMigrationRunnerScreenState extends State<SupabaseMigrationRunnerScreen> {
  final _supabaseUrlController = TextEditingController(text: defaultSupabaseUrl);
  final _serviceRoleKeyController = TextEditingController(text: defaultServiceRoleKey);
  final _usersAssetPathController = TextEditingController(text: defaultUsersAssetPath);
  
  bool _isMigrating = false;
  String _status = 'Ready to migrate. Configure connection details and click Load.';
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  SupabaseClient? _adminClient;
  final Map<String, String> _userMapping = {}; // maps firebase_uid -> supabase_user_id (UUID)
  final Map<String, String> _userEmailMapping = {}; // maps firebase_uid -> email
  final Map<String, String> _userNameMapping = {};  // maps firebase_uid -> displayName
  final Map<String, bool> _selectedUsers = {};      // maps firebase_uid -> isSelected

  @override
  void initState() {
    super.initState();
    _detectFirebaseEmulator();
  }

  void _detectFirebaseEmulator() {
    try {
      // Simple check to see if emulator is configured
      FirebaseFirestore.instance;
      _log("Firebase initialized successfully.");
    } catch (e) {
      _log("Error verifying Firebase: $e");
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$timestamp] $message');
    });
    // Auto scroll logs
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  String _toUuid(String legacyId, {String? prefix}) {
    if (legacyId.isEmpty) {
      return const Uuid().v4();
    }
    final prefixStr = prefix != null ? '$prefix/' : '';
    return const Uuid().v5(Namespace.url.value, 'postfolio://firestore/$prefixStr$legacyId');
  }

  Map<String, dynamic> _convertKeysToSnakeCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      final snakeKey = _camelToSnake(key);
      if (value is Map<String, dynamic>) {
        result[snakeKey] = _convertKeysToSnakeCase(value);
      } else if (value is List) {
        result[snakeKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertKeysToSnakeCase(item);
          }
          return item;
        }).toList();
      } else {
        result[snakeKey] = value;
      }
    });
    return result;
  }

  String _camelToSnake(String input) {
    final RegExp regex = RegExp(r'(?<=[a-z0-9])([A-Z])');
    return input.replaceAllMapped(regex, (match) => '_${match.group(0)!}').toLowerCase();
  }

  Future<bool> _initSupabaseAdmin() async {
    final url = _supabaseUrlController.text.trim();
    final key = _serviceRoleKeyController.text.trim();

    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _status = "Error: Supabase URL and Service Role Key cannot be empty.";
      });
      _log("Error: Missing connection parameters.");
      return false;
    }

    try {
      _log("Initializing Supabase client with Admin/Service Role privileges...");
      _adminClient = SupabaseClient(url, key);
      _log("Supabase client initialized successfully.");
      return true;
    } catch (e) {
      _log("Failed to initialize Supabase client: $e");
      setState(() {
        _status = "Failed to connect to Supabase: $e";
      });
      return false;
    }
  }

  Future<void> _loadAndSetupUsers() async {
    setState(() {
      _isMigrating = true;
      _status = "Loading users & provisioning Auth accounts...";
    });
    _clearLogs();

    final success = await _initSupabaseAdmin();
    if (!success || _adminClient == null) {
      setState(() {
        _isMigrating = false;
      });
      return;
    }

    try {
      final path = _usersAssetPathController.text.trim();
      _log("Loading user configuration asset: $path");
      final rawJson = await rootBundle.loadString(path);
      final data = json.decode(rawJson) as Map<String, dynamic>;
      final users = data['users'] as List<dynamic>;

      _log("Found ${users.length} user record(s) in configuration file.");

      // 1. Retrieve existing users from auth.users using listUsers
      _log("Listing existing Supabase users to check for matches...");
      final List<User> existingSupabaseUsers = await _adminClient!.auth.admin.listUsers();
      _log("Found ${existingSupabaseUsers.length} existing user(s) in Supabase Auth.");

      _userMapping.clear();
      _userEmailMapping.clear();
      _userNameMapping.clear();

      for (var u in users) {
        final fUid = u['localId'] as String?;
        final email = u['email'] as String?;
        final displayName = u['displayName'] as String? ?? 'Agent';

        if (fUid == null || email == null) {
          _log("Warning: Skipping malformed configuration entry (missing localId or email): $u");
          continue;
        }

        _log("Processing User: $email (Firebase UID: $fUid)");
        _userEmailMapping[fUid] = email;
        _userNameMapping[fUid] = displayName;
        
        // Auto-select by default
        _selectedUsers[fUid] = true;

        // Check if user already exists in Supabase by email
        final match = existingSupabaseUsers.where((u) => u.email?.toLowerCase() == email.toLowerCase()).firstOrNull;

        String sUserId;
        if (match != null) {
          sUserId = match.id;
          _log("Existing match found in Supabase Auth (UUID: $sUserId). Linking...");
        } else {
          _log("No existing match found. Creating new verified user in Supabase Auth...");
          final response = await _adminClient!.auth.admin.createUser(
            AdminUserAttributes(
              email: email,
              emailConfirm: true,
              userMetadata: {
                'full_name': displayName,
              },
            ),
          );
          if (response.user == null) {
            throw Exception("Failed to create user $email");
          }
          sUserId = response.user!.id;
          _log("Successfully created user $email (Generated UUID: $sUserId).");
        }

        // Link the legacy_firebase_uid in agent_profiles
        _log("Linking legacy Firebase UID in agent_profiles for UUID: $sUserId...");
        await _adminClient!.from('agent_profiles').upsert({
          'id': sUserId,
          'email': email,
          'name': displayName,
          'legacy_firebase_uid': fUid,
        });
        _log("agent_profiles linking complete for $email.");

        _userMapping[fUid] = sUserId;
      }

      setState(() {
        _status = "User Provisioning Complete! Mapped ${_userMapping.length} users successfully.";
        _isMigrating = false;
      });
      _log("Successfully mapped and linked ${_userMapping.length} user(s). Ready to migrate data!");
    } catch (e, stack) {
      _log("Error provisioning users: $e\n$stack");
      setState(() {
        _status = "Error during user setup: $e";
        _isMigrating = false;
      });
    }
  }

  Future<void> _insertInChunks(String table, List<Map<String, dynamic>> records, {int chunkSize = 200}) async {
    if (records.isEmpty) return;
    _log("Inserting ${records.length} records into '$table' in chunks of $chunkSize...");
    for (var i = 0; i < records.length; i += chunkSize) {
      final chunk = records.sublist(i, i + chunkSize > records.length ? records.length : i + chunkSize);
      await _adminClient!.from(table).insert(chunk);
      _log(" -> Inserted chunk ${i ~/ chunkSize + 1}/${(records.length + chunkSize - 1) ~/ chunkSize} (${chunk.length} records)");
    }
  }

  Future<void> _runDataMigration() async {
    final activeMappings = _userMapping.keys.where((fUid) => _selectedUsers[fUid] ?? false).toList();

    if (activeMappings.isEmpty) {
      setState(() {
        _status = "Error: Please select at least one agent to migrate.";
      });
      _log("Error: No agents selected for migration.");
      return;
    }

    setState(() {
      _isMigrating = true;
      _status = "Migrating database schemas...";
    });
    _log("Starting high-fidelity data migration...");

    try {
      _log("Fetching existing customer IDs from Supabase to prevent overrides...");
      final List<dynamic> existingCustomersData = await _adminClient!.from('customers').select('id');
      final Set<String> existingCustomerIds = existingCustomersData.map((e) => e['id'] as String).toSet();
      _log(" -> Found ${existingCustomerIds.length} existing customer(s) in Supabase.");

      _log("Fetching existing account identity IDs from Supabase to prevent overrides...");
      final List<dynamic> existingIdentitiesData = await _adminClient!.from('account_identities').select('id');
      final Set<String> existingIdentityIds = existingIdentitiesData.map((e) => e['id'] as String).toSet();
      _log(" -> Found ${existingIdentityIds.length} existing account identity(s) in Supabase.");

      int totalCustomersProcessed = 0;
      int totalCustomersMigrated = 0;
      int totalCustomersSkipped = 0;

      int totalSBProcessed = 0;
      int totalSBMigrated = 0;
      int totalSBSkipped = 0;

      int totalOneTimeProcessed = 0;
      int totalOneTimeMigrated = 0;
      int totalOneTimeSkipped = 0;

      int totalRecurringProcessed = 0;
      int totalRecurringMigrated = 0;
      int totalRecurringSkipped = 0;

      int totalNomineesMigrated = 0;

      for (var fUid in activeMappings) {
        final sUid = _userMapping[fUid]!;
        final email = _userEmailMapping[fUid]!;

        _log("=========================================");
        _log("MIGRATING DATA FOR USER: $email");
        _log("Firebase UID: $fUid -> Supabase UUID: $sUid");
        _log("=========================================");

        final List<Map<String, dynamic>> customersBatch = [];
        final List<Map<String, dynamic>> accountIdentitiesBatch = [];
        final List<Map<String, dynamic>> savingsAccountsBatch = [];
        final List<Map<String, dynamic>> otdsBatch = [];
        final List<Map<String, dynamic>> rdsBatch = [];
        final List<Map<String, dynamic>> nomineesBatch = [];

        // --- 1. Migrate Customers ---
        _log("Fetching customers from Firestore for Firebase UID: $fUid...");
        final customerSnapshots = await FirebaseFirestore.instance
            .collection('users')
            .doc(fUid)
            .collection(FirestoreCollections.customers)
            .get();

        _log("Found ${customerSnapshots.docs.length} customers in Firestore. Preparing payloads...");

        for (var doc in customerSnapshots.docs) {
          totalCustomersProcessed++;
          final data = doc.data();
          final customer = Customer.fromJson({..._convertKeysToSnakeCase(data), 'id': doc.id});
          final customerUuid = _toUuid(customer.id, prefix: '$fUid/customer');

          if (existingCustomerIds.contains(customerUuid)) {
            totalCustomersSkipped++;
            _log(" -> Skipped existing Customer: '${customer.name}' | CIF: ${customer.cifNumber ?? 'N/A'} | Firestore Path: users/$fUid/customers/${doc.id} (Supabase UUID: $customerUuid)");
          } else {
            customersBatch.add({
              'id': customerUuid,
              'agent_id': sUid,
              'name': customer.name,
              'phone': customer.phone,
              'email': customer.email,
              'address': customer.address,
              'cif_number': customer.cifNumber,
              'aadhaar_number': customer.aadhaarNumber,
              'pan_number': customer.panNumber,
              'date_of_birth': customer.dateOfBirth?.toIso8601String().split('T').first,
              'notes': customer.notes,
              'created_at': customer.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'updated_at': customer.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            });
            totalCustomersMigrated++;
            existingCustomerIds.add(customerUuid);
          }

          // Handle Savings Account & Savings Nominees if present
          if (customer.savingsAccount != null) {
            final saAccountNumber = customer.savingsAccount!.accountNumber;
            if (saAccountNumber.isNotEmpty) {
              totalSBProcessed++;
              final saAccountId = _toUuid(customer.id, prefix: '$fUid/savings_account');
              
              if (existingIdentityIds.contains(saAccountId)) {
                totalSBSkipped++;
                _log(" -> Skipped existing SB Account: '$saAccountNumber' for Customer '${customer.name}' | Firestore Path: users/$fUid/customers/${doc.id} (Supabase UUID: $saAccountId)");
              } else {
                accountIdentitiesBatch.add({
                  'id': saAccountId,
                  'customer_id': customerUuid,
                  'agent_id': sUid,
                  'account_type': 'SB',
                  'created_at': customer.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                  'updated_at': customer.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                });

                savingsAccountsBatch.add({
                  'id': saAccountId,
                  'account_number': saAccountNumber,
                  'linked_date': null,
                  'updated_at': customer.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                });
                totalSBMigrated++;
                existingIdentityIds.add(saAccountId);

                // Migrate nominees for this SB account
                if (customer.savingsAccount!.nominees.isNotEmpty) {
                  for (var nominee in customer.savingsAccount!.nominees) {
                    nomineesBatch.add({
                      'id': const Uuid().v4(),
                      'account_id': saAccountId,
                      'name': nominee.name,
                      'relationship': nominee.toJson()['relationship'],
                      'custom_relationship': nominee.customRelationship,
                      'percentage': nominee.percentage,
                      'created_at': customer.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                      'updated_at': customer.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                    });
                    totalNomineesMigrated++;
                  }
                }
              }
            }
          }
        }

        // --- 2. Migrate One-Time Deposits ---
        _log("Fetching one-time deposits from Firestore for Firebase UID: $fUid...");
        final otdSnapshots = await FirebaseFirestore.instance
            .collection('users')
            .doc(fUid)
            .collection(FirestoreCollections.oneTimeDeposits)
            .get();

        _log("Found ${otdSnapshots.docs.length} one-time deposits in Firestore. Preparing payloads...");

        for (var doc in otdSnapshots.docs) {
          totalOneTimeProcessed++;
          final data = doc.data();
          OneTimeDeposit otd;
          try {
            otd = OneTimeDeposit.fromJson({..._convertKeysToSnakeCase(data), 'id': doc.id});
          } catch (e) {
            _log("CRITICAL ERROR: Failed to parse OneTimeDeposit JSON (ID: ${doc.id}): $e");
            _log("JSON keys and values: ${_convertKeysToSnakeCase(data)}");
            rethrow;
          }
          final otdUuid = _toUuid(otd.id, prefix: '$fUid/otd');
          final customerUuid = _toUuid(otd.customerId, prefix: '$fUid/customer');

          if (existingIdentityIds.contains(otdUuid)) {
            totalOneTimeSkipped++;
            _log(" -> Skipped existing OTD: Account '${otd.accountNo ?? 'Pending'}' | Scheme: ${otd.schemeType.name} | Firestore Path: users/$fUid/oneTimeDeposits/${doc.id} (Supabase UUID: $otdUuid)");
          } else {
            // Create account identity
            accountIdentitiesBatch.add({
              'id': otdUuid,
              'customer_id': customerUuid,
              'agent_id': sUid,
              'account_type': 'OTD',
              'created_at': otd.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'updated_at': otd.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            });

            // Create OTD details
            otdsBatch.add({
              'id': otdUuid,
              'status': otd.status.name,
              'scheme_type': otd.schemeType.name,
              'account_no': otd.accountNo,
              'principal_amount': otd.principalAmount,
              'interest_rate': otd.interestRate,
              'term_years': otd.termYears,
              'term_months': otd.termMonths,
              'start_date': otd.startDate.toIso8601String().split('T').first,
              'created_at': otd.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'updated_at': otd.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            });
            totalOneTimeMigrated++;
            existingIdentityIds.add(otdUuid);

            // Create nominees
            if (otd.nominees.isNotEmpty) {
              for (var nominee in otd.nominees) {
                nomineesBatch.add({
                  'id': const Uuid().v4(),
                  'account_id': otdUuid,
                  'name': nominee.name,
                  'relationship': nominee.toJson()['relationship'],
                  'custom_relationship': nominee.customRelationship,
                  'percentage': nominee.percentage,
                  'created_at': otd.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                  'updated_at': otd.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                });
                totalNomineesMigrated++;
              }
            }
          }
        }

        // --- 3. Migrate Recurring Deposits ---
        _log("Fetching recurring deposits from Firestore for Firebase UID: $fUid...");
        final rdSnapshots = await FirebaseFirestore.instance
            .collection('users')
            .doc(fUid)
            .collection(FirestoreCollections.recurringDeposits)
            .get();

        _log("Found ${rdSnapshots.docs.length} recurring deposits in Firestore. Preparing payloads...");

        for (var doc in rdSnapshots.docs) {
          totalRecurringProcessed++;
          final data = doc.data();
          final rd = RecurringDeposit.fromJson({..._convertKeysToSnakeCase(data), 'id': doc.id});
          final rdUuid = _toUuid(rd.id, prefix: '$fUid/rd');
          final customerUuid = _toUuid(rd.customerId, prefix: '$fUid/customer');

          if (existingIdentityIds.contains(rdUuid)) {
            totalRecurringSkipped++;
            _log(" -> Skipped existing RD: Account '${rd.accountNo ?? 'Pending'}' (Serial: ${rd.serialNo}) | Firestore Path: users/$fUid/recurringDeposits/${doc.id} (Supabase UUID: $rdUuid)");
          } else {
            // Create account identity
            accountIdentitiesBatch.add({
              'id': rdUuid,
              'customer_id': customerUuid,
              'agent_id': sUid,
              'account_type': 'RD',
              'created_at': rd.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'updated_at': rd.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            });

            // Create RD details
            rdsBatch.add({
              'id': rdUuid,
              'status': rd.status.name,
              'scheme_type': rd.schemeType.name,
              'account_no': rd.accountNo,
              'serial_no': rd.serialNo,
              'installment_amount': rd.installmentAmount,
              'interest_rate': rd.interestRate,
              'term_years': rd.termYears,
              'term_months': rd.termMonths,
              'start_date': rd.startDate.toIso8601String().split('T').first,
              'created_at': rd.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'updated_at': rd.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            });
            totalRecurringMigrated++;
            existingIdentityIds.add(rdUuid);

            // Create nominees
            if (rd.nominees.isNotEmpty) {
              for (var nominee in rd.nominees) {
                nomineesBatch.add({
                  'id': const Uuid().v4(),
                  'account_id': rdUuid,
                  'name': nominee.name,
                  'relationship': nominee.toJson()['relationship'],
                  'custom_relationship': nominee.customRelationship,
                  'percentage': nominee.percentage,
                  'created_at': rd.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                  'updated_at': rd.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                });
                totalNomineesMigrated++;
              }
            }
          }
        }

        // --- 4. Execute Optimized Bulk Inserts ---
        _log("Executing bulk database inserts...");
        await _insertInChunks('customers', customersBatch);
        await _insertInChunks('account_identities', accountIdentitiesBatch);
        await _insertInChunks('savings_accounts', savingsAccountsBatch);
        await _insertInChunks('one_time_deposits', otdsBatch);
        await _insertInChunks('recurring_deposits', rdsBatch);
        await _insertInChunks('nominees', nomineesBatch);
      }

      setState(() {
        _status = "Migration Complete! 🎉\n\n"
            "Customers: processed=$totalCustomersProcessed, migrated=$totalCustomersMigrated, skipped=$totalCustomersSkipped\n"
            "Savings Accounts: processed=$totalSBProcessed, migrated=$totalSBMigrated, skipped=$totalSBSkipped\n"
            "One-Time Deposits: processed=$totalOneTimeProcessed, migrated=$totalOneTimeMigrated, skipped=$totalOneTimeSkipped\n"
            "Recurring Deposits: processed=$totalRecurringProcessed, migrated=$totalRecurringMigrated, skipped=$totalRecurringSkipped\n"
            "Nominees: migrated=$totalNomineesMigrated";
        _isMigrating = false;
      });
      _log("---------------- MIGRATION COMPLETED ----------------");
      _log("Customers: Processed: $totalCustomersProcessed, Migrated: $totalCustomersMigrated, Skipped: $totalCustomersSkipped");
      _log("Savings Accounts: Processed: $totalSBProcessed, Migrated: $totalSBMigrated, Skipped: $totalSBSkipped");
      _log("One-Time Deposits: Processed: $totalOneTimeProcessed, Migrated: $totalOneTimeMigrated, Skipped: $totalOneTimeSkipped");
      _log("Recurring Deposits: Processed: $totalRecurringProcessed, Migrated: $totalRecurringMigrated, Skipped: $totalRecurringSkipped");
      _log("Nominees: Migrated: $totalNomineesMigrated");
      _log("You can now safely run and verify the app on Supabase!");
    } catch (e, stack) {
      _log("Migration aborted due to critical error: $e\n$stack");
      setState(() {
        _status = "Migration failed: $e";
        _isMigrating = false;
      });
    }
  }

  Future<void> _clearSupabaseDatabase() async {
    final success = await _initSupabaseAdmin();
    if (!success || _adminClient == null) return;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Database Purge'),
        content: const Text('This will delete all customers, deposits, nominees, and account identities from the target Supabase database. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white),
            child: const Text('PURGE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isMigrating = true;
      _status = "Purging database records...";
    });
    _clearLogs();
    _log("Starting database purge...");

    try {
      // Deleting from account_identities triggers cascading deletes to savings_accounts, one_time_deposits, recurring_deposits, and nominees
      _log("Deleting all records from account_identities (triggers cascades)...");
      await _adminClient!.from('account_identities').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      
      _log("Deleting all records from customers...");
      await _adminClient!.from('customers').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      _log("Deleting all custom user profiles (excludes system auth.users)...");
      await _adminClient!.from('agent_profiles').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      setState(() {
        _status = "Purge successful! 🗑️ Database is clean.";
        _isMigrating = false;
      });
      _log("Database purged successfully! Ready for a clean migration run.");
    } catch (e) {
      _log("Error purging database: $e");
      setState(() {
        _status = "Purge failed: $e";
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase to Supabase Migrator'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Left configuration panel
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(AppDimensions.paddingLg),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Connection Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    TextField(
                      controller: _supabaseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Supabase REST Endpoint URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    TextField(
                      controller: _serviceRoleKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Supabase SERVICE_ROLE / Admin Key',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    TextField(
                      controller: _usersAssetPathController,
                      decoration: const InputDecoration(
                        labelText: 'Path to exported users.json file',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_userMapping.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.paddingLg),
                      Text(
                        'Select Agents to Migrate',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppDimensions.paddingSm),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: _userMapping.keys.map((fUid) {
                            final email = _userEmailMapping[fUid] ?? '';
                            final name = _userNameMapping[fUid] ?? '';
                            return CheckboxListTile(
                              title: Text(name),
                              subtitle: Text(email),
                              value: _selectedUsers[fUid] ?? false,
                              onChanged: _isMigrating
                                  ? null
                                  : (bool? val) {
                                      setState(() {
                                        _selectedUsers[fUid] = val ?? false;
                                      });
                                    },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const Divider(),
                    const SizedBox(height: AppDimensions.paddingSm),
                    ElevatedButton.icon(
                      onPressed: _isMigrating ? null : _loadAndSetupUsers,
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Step 1: Load and Provision Users'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMd),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSm),
                    ElevatedButton.icon(
                      onPressed: _isMigrating ? null : _runDataMigration,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Step 2: Run Data Migration'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMd),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSm),
                    OutlinedButton.icon(
                      onPressed: _isMigrating ? null : _clearSupabaseDatabase,
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                      label: const Text('Purge Supabase Data', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMd),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right execution logging console
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.paddingLg),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Migration Console',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearLogs,
                          icon: const Icon(Icons.clear_all, color: Colors.tealAccent),
                          label: const Text('Clear Log', style: TextStyle(color: Colors.tealAccent)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.tealAccent),
                    const SizedBox(height: AppDimensions.paddingSm),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMd),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.teal),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Text(
                        _status,
                        style: const TextStyle(color: Colors.tealAccent, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    Expanded(
                      child: ListView.builder(
                        controller: _logScrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
