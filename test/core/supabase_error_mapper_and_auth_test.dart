import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/services/app_error_reporter.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, AuthUser;

void main() {
  group('SupabaseErrorMapper', () {
    test('table: maps PostgrestException, AuthException, and StateError without leaking SQL', () {
      final cases = <({
        String label,
        Object error,
        String expected,
      })>[
        (
          label: 'duplicate email 23505',
          error: const PostgrestException(
            message: 'duplicate key value violates unique constraint "idx_agent_profiles_email"',
            code: '23505',
            details: 'Key (lower(email))=(agent@example.com) already exists.',
          ),
          expected: 'An agent profile with this email already exists.',
        ),
        (
          label: 'generic unique constraint 23505',
          error: const PostgrestException(
            message: 'duplicate key value violates unique constraint "rd_transactions_pkey"',
            code: '23505',
          ),
          expected: 'This entry has already been recorded.',
        ),
        (
          label: 'FK restrict 23503',
          error: const PostgrestException(
            message: 'update or delete on table "customers" violates foreign key constraint',
            code: '23503',
          ),
          expected: 'This record cannot be deleted while linked accounts or ledger entries exist.',
        ),
        (
          label: 'locked financial terms 23514',
          error: const PostgrestException(
            message: 'Financial terms cannot be modified after ledger activity has been recorded.',
            code: '23514',
          ),
          expected: 'Financial terms cannot be modified after ledger activity has been recorded.',
        ),
        (
          label: 'superseded PO batch 23514',
          error: const PostgrestException(
            message: 'Cannot undo visit: a newer Post Office deposit exists on one or more accounts.',
            code: '23514',
          ),
          expected: 'Cannot undo this visit because a newer Post Office deposit was recorded afterward.',
        ),
        (
          label: 'RLS denial 42501',
          error: const PostgrestException(
            message: 'new row violates row-level security policy for table "customers"',
            code: '42501',
          ),
          expected: 'You do not have permission to modify this record.',
        ),
        (
          label: 'unauthenticated RPC 42501',
          error: const PostgrestException(message: 'Unauthenticated', code: '42501'),
          expected: 'Your session has expired. Please sign in again.',
        ),
        (
          label: 'not found P0002',
          error: const PostgrestException(message: 'Deposit not found', code: 'P0002'),
          expected: 'The requested record could not be found.',
        ),
        (
          label: 'AuthException invalid credentials',
          error: const AuthException('Invalid login credentials'),
          expected: 'Invalid email or password.',
        ),
        (
          label: 'StateError passes domain message through',
          error: StateError('Agent not authenticated'),
          expected: 'Agent not authenticated',
        ),
        (
          label: 'unexpected runtime error uses clean fallback',
          error: Exception('raw internal socket trace'),
          expected: 'Something went wrong while talking to the server. Please try again.',
        ),
      ];

      for (final c in cases) {
        final actual = SupabaseErrorMapper.describe(c.error);
        expect(actual, c.expected, reason: c.label);
        expect(actual, isNot(contains('PostgrestException')));
      }
    });
  });

  group('AuthController & FakeAuthRepository', () {
    test('handles stream transitions, sign-in errors, and demo-mode sign-out isolation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeAuth = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeAuth.dispose);

      container.listen(authControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider), const AuthState.unauthenticated());

      // Failed Google sign-in surfaces AuthState.error.
      fakeAuth.signInError = 'Sign-in cancelled';
      final failRes = await container.read(authControllerProvider.notifier).signInWithGoogle();
      expect(failRes, isA<Failure<void, String>>());
      expect(container.read(authControllerProvider), const AuthState.error('Sign-in cancelled'));

      // Successful sign-in updates stream -> AuthState.authenticated.
      fakeAuth.signInError = null;
      const agent = AuthUser(id: 'agent-1', email: 'agent@postfolio.com', displayName: 'Agent');
      final okRes =
          await container.read(authControllerProvider.notifier).signInWithGoogle();
      expect(okRes, isA<Success<void, String>>());
      fakeAuth.emit(agent);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider), const AuthState.authenticated(user: agent));

      // Demo mode overrides active user; signing out exits demo mode without calling remote signOut.
      await container.read(demoModeProvider.notifier).enable();
      expect(
        container.read(authControllerProvider),
        const AuthState.authenticated(
          user: AuthUser(id: 'demo_user', email: 'agent@demo.com', displayName: 'Demo Agent'),
        ),
      );
      expect(fakeAuth.signOutCount, 0);
      await container.read(authControllerProvider.notifier).signOut();
      expect(container.read(demoModeProvider), isFalse);
      expect(fakeAuth.signOutCount, 0, reason: 'exiting demo mode must not sign out real session');

      // Real sign-out invokes repository and emits null.
      await container.read(authControllerProvider.notifier).signOut();
      expect(fakeAuth.signOutCount, 1);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider), const AuthState.unauthenticated());
    });
  });

  group('FakeDataSource domain integrity', () {
    test('all demo customers, OTDs, and RDs have valid 100% nominee shares and non-empty facts', () {
      final ds = FakeDataSource();
      expect(ds.customers, isNotEmpty);
      expect(ds.oneTimeDeposits, isNotEmpty);
      expect(ds.recurringDeposits, isNotEmpty);
      expect(ds.rdTransactions.values.expand((e) => e), isNotEmpty);
      expect(ds.rdPoDeposits.values.expand((e) => e), isNotEmpty);

      for (final c in ds.customers) {
        if (c.savingsAccount != null) {
          expect(Nominee.validateNominees(c.savingsAccount!.nominees), isNull,
              reason: 'Customer ${c.id} nominees must sum to 100%');
        }
      }
      for (final otd in ds.oneTimeDeposits) {
        expect(Nominee.validateNominees(otd.nominees), isNull);
        expect(otd.customerName, isNotNull);
      }
      for (final rd in ds.recurringDeposits) {
        expect(Nominee.validateNominees(rd.nominees), isNull);
        expect(rd.customerName, isNotNull);
      }
    });
  });

  group('AppErrorReporter rate-limiting & resilience', () {
    test('deduplicates repeated errors within cooldown, enforces session cap, and swallows send errors', () async {
      var now = DateTime(2026, 11, 11, 10, 0);
      final recorded = <String>[];
      final reporter = AppErrorReporter(
        now: () => now,
        cooldown: const Duration(seconds: 60),
        maxReportsPerSession: 3,
        send: ({required platform, required error, stackTrace}) async {
          if (error == 'boom-network') throw Exception('network down');
          recorded.add('$platform:$error');
        },
      );

      await reporter.report(platform: 'web', error: 'RenderFlex overflow');
      await reporter.report(platform: 'web', error: 'RenderFlex overflow'); // duplicate in cooldown
      expect(recorded, ['web:RenderFlex overflow']);

      now = now.add(const Duration(seconds: 61));
      await reporter.report(platform: 'web', error: 'RenderFlex overflow'); // allowed after cooldown
      await reporter.report(platform: 'web', error: 'boom-network'); // swallowed, counts toward cap
      await reporter.report(platform: 'web', error: 'over-cap'); // dropped by maxReportsPerSession=3
      expect(recorded, ['web:RenderFlex overflow', 'web:RenderFlex overflow']);
      expect(reporter.sentCount, 3);
    });
  });

  group('Env.assertFlavorSafe', () {
    test('blocks staging flavor when pointed at remote production URL under prod APP_ENV', () {
      expect(
        () => Env.assertFlavorSafe(
          flavor: 'staging',
          effectiveEnv: 'prod',
          emulatorOverride: false,
          resolvedUrl: 'https://prod-ref.supabase.co',
        ),
        throwsStateError,
      );

      // Staging pointed at local emulator or explicit staging APP_ENV succeeds.
      expect(
        () => Env.assertFlavorSafe(
          flavor: 'staging',
          effectiveEnv: 'local',
          emulatorOverride: false,
          resolvedUrl: 'http://127.0.0.1:54321',
        ),
        returnsNormally,
      );
      expect(
        () => Env.assertFlavorSafe(
          flavor: 'staging',
          effectiveEnv: 'staging',
          emulatorOverride: false,
          resolvedUrl: 'https://staging-ref.supabase.co',
        ),
        returnsNormally,
      );
      expect(
        () => Env.assertFlavorSafe(
          flavor: 'prod',
          effectiveEnv: 'prod',
          emulatorOverride: false,
          resolvedUrl: 'https://prod-ref.supabase.co',
        ),
        returnsNormally,
      );
    });
  });
}
