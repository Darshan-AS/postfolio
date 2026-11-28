import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/admin/data/admin_repository.dart';
import 'package:postfolio/features/admin/domain/acting_as_state.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/data/supabase_one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class _LoopbackHttpOverrides extends HttpOverrides {}

typedef _RecordedRequest = ({
  String method,
  String path,
  Map<String, String> query,
  Object? body,
});

void _expectSuccess<T>(Result<T, String> result, [Object? matcher]) {
  expect(result, isA<Success<T, String>>());
  if (matcher != null) {
    expect((result as Success<T, String>).value, matcher);
  }
}

void _expectFailure<T>(Result<T, String> result, Object errorMatcher) {
  expect(result, isA<Failure<T, String>>());
  expect((result as Failure<T, String>).error, errorMatcher);
}

Future<
  ({
    HttpServer server,
    SupabaseClient client,
    List<_RecordedRequest> requests,
    void Function(int statusCode, Object? body) setNextResponse,
  })
>
_startStubSupabaseServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final requests = <_RecordedRequest>[];
  var nextStatus = 200;
  Object? nextBody = const <Object?>[];

  server.listen((req) async {
    final rawBody = await utf8.decoder.bind(req).join();
    Object? decoded;
    if (rawBody.isNotEmpty) {
      try {
        decoded = jsonDecode(rawBody);
      } catch (_) {
        decoded = rawBody;
      }
    }
    requests.add((
      method: req.method,
      path: req.uri.path,
      query: req.uri.queryParameters,
      body: decoded,
    ));

    req.response.statusCode = nextStatus;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(nextBody));
    await req.response.close();
  });

  final client = SupabaseClient(
    'http://127.0.0.1:${server.port}',
    'test-anon-key',
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  addTearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  return (
    server: server,
    client: client,
    requests: requests,
    setNextResponse: (int statusCode, Object? body) {
      nextStatus = statusCode;
      nextBody = body;
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adminUser = AuthUser(
    id: 'admin-1',
    email: 'admin@postfolio.dev',
    displayName: 'Admin User',
  );
  const otherAdminUser = AuthUser(
    id: 'admin-2',
    email: 'admin2@postfolio.dev',
    displayName: 'Second Admin',
  );
  const adminProfile = AgentProfile(
    id: 'admin-1',
    name: 'Admin User',
    email: 'admin@postfolio.dev',
    agencyCode: 'AG-001',
  );
  const agentB = AgentProfile(
    id: 'agent-b',
    name: 'Bhavna Mehta',
    email: 'bhavna@postfolio.dev',
    agencyCode: 'AG-102',
  );
  const agentC = AgentProfile(
    id: 'agent-c',
    name: 'Chetan Patel',
    email: 'chetan@postfolio.dev',
    agencyCode: 'AG-203',
  );

  group('AgentProfile helpers & JSON', () {
    test(
      'deserializes snake_case agency_code and computes display/supporting labels',
      () {
        final decoded = AgentProfile.fromJson(const {
          'id': 'a-1',
          'name': '  Asha Rao  ',
          'email': '  asha@example.com  ',
          'agency_code': '  AG-42  ',
        });
        expect(decoded.id, 'a-1');
        expect(decoded.agencyCode, '  AG-42  ');
        expect(decoded.displayLabel, 'Asha Rao');
        expect(decoded.supportingLabel, 'asha@example.com • AG-42');
        expect(decoded.toJson()['agency_code'], '  AG-42  ');

        const emailFallback = AgentProfile(
          id: 'a-2',
          name: '   ',
          email: 'only@example.com',
          agencyCode: 'AG-99',
        );
        expect(emailFallback.displayLabel, 'only@example.com');
        expect(emailFallback.supportingLabel, 'AG-99');

        const emailOnly = AgentProfile(id: 'a-3', email: 'solo@example.com');
        expect(emailOnly.displayLabel, 'solo@example.com');
        expect(emailOnly.supportingLabel, isNull);

        const idFallback = AgentProfile(
          id: 'a-4',
          name: '',
          email: '  ',
          agencyCode: '  ',
        );
        expect(idFallback.displayLabel, 'a-4');
        expect(idFallback.supportingLabel, isNull);

        const idWithCode = AgentProfile(id: 'a-5', agencyCode: 'AG-55');
        expect(idWithCode.displayLabel, 'a-5');
        expect(idWithCode.supportingLabel, 'AG-55');
      },
    );
  });

  group('ActingAsState & ActingAsAuditAction', () {
    test('exposes exact getters and wire values', () {
      const none = ActingAsState.none();
      expect(none.isActingAs, isFalse);
      expect(none.targetAgentId, isNull);

      const active = ActingAsState.active(targetAgent: agentB);
      expect(active.isActingAs, isTrue);
      expect(active.targetAgentId, 'agent-b');

      expect(ActingAsAuditAction.values.map((a) => a.wireValue), [
        'start',
        'end',
      ]);
    });
  });

  group('ActingAsController, isAdminProvider, and session key isolation', () {
    Future<
      ({
        ProviderContainer container,
        FakeAuthRepository authRepo,
        FakeAdminRepository adminRepo,
        SharedPreferences prefs,
      })
    >
    buildHarness({
      AuthUser? initialUser = adminUser,
      bool isAdmin = true,
      String? isAdminError,
      int transientIsAdminFailures = 0,
      String? listAgentsError,
      String? logEventError,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository(initialUser: initialUser);
      final adminRepo = FakeAdminRepository(
        isAdmin: isAdmin,
        agents: const [adminProfile, agentB, agentC],
        isAdminError: isAdminError,
        transientIsAdminFailures: transientIsAdminFailures,
        listAgentsError: listAgentsError,
        logEventError: logEventError,
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(authRepo),
          adminRepositoryProvider.overrideWithValue(adminRepo),
          isAdminRetryDelayProvider.overrideWithValue(Duration.zero),
        ],
      );
      addTearDown(() {
        authRepo.dispose();
        container.dispose();
      });

      container.listen(authControllerProvider, (_, _) {});
      container.listen(actingAsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      return (
        container: container,
        authRepo: authRepo,
        adminRepo: adminRepo,
        prefs: prefs,
      );
    }

    test(
      'isAdminProvider reflects role, fails closed on error/unauth/demo/uninitialized',
      () async {
        final adminH = await buildHarness(isAdmin: true);
        expect(await adminH.container.read(isAdminProvider.future), isTrue);

        final agentH = await buildHarness(isAdmin: false);
        expect(await agentH.container.read(isAdminProvider.future), isFalse);

        final errH = await buildHarness(
          isAdmin: true,
          isAdminError: 'RPC failed',
        );
        expect(await errH.container.read(isAdminProvider.future), isFalse);
        expect(errH.adminRepo.isAdminCallCount, 2);

        // Transient first-attempt RPC failure (e.g. PostgREST PGRST303 after sign-in)
        // retries once and recovers instead of latching false.
        final transientH = await buildHarness(
          isAdmin: true,
          transientIsAdminFailures: 1,
        );
        expect(await transientH.container.read(isAdminProvider.future), isTrue);
        expect(transientH.adminRepo.isAdminCallCount, 2);

        final unauthH = await buildHarness(initialUser: null, isAdmin: true);
        expect(await unauthH.container.read(isAdminProvider.future), isFalse);

        // Enabling Demo Mode forces isAdmin -> false and uses FakeAdminRepository(isAdmin: false).
        await adminH.container.read(demoModeProvider.notifier).enable();
        expect(await adminH.container.read(isAdminProvider.future), isFalse);

        // Isolated container with no Supabase/SharedPreferences overrides fails closed safely.
        final isolated = ProviderContainer();
        addTearDown(isolated.dispose);
        expect(await isolated.read(isAdminProvider.future), isFalse);
        expect(
          isolated.read(actingAsControllerProvider),
          const ActingAsState.none(),
        );
        expect(isolated.read(effectiveAgentIdProvider), isNull);
      },
    );

    test(
      'adminAgentsListProvider returns repository result (success & failure)',
      () async {
        final h = await buildHarness();
        final res = await h.container.read(adminAgentsListProvider.future);
        _expectSuccess(res, hasLength(3));

        final errH = await buildHarness(listAgentsError: 'Denied');
        final errRes = await errH.container.read(
          adminAgentsListProvider.future,
        );
        _expectFailure(errRes, 'Denied');
      },
    );

    test(
      'state transitions, audit logs, self-selection, non-blocking audit errors, and zero persistence',
      () async {
        final h = await buildHarness();
        final c = h.container;
        final notifier = c.read(actingAsControllerProvider.notifier);

        expect(c.read(actingAsControllerProvider), const ActingAsState.none());
        expect(c.read(effectiveAgentIdProvider), 'admin-1');

        // Start acting as agent B; repeated call for same target is a no-op.
        await notifier.startActingAs(agentB);
        await notifier.startActingAs(agentB);
        expect(
          c.read(actingAsControllerProvider),
          const ActingAsState.active(targetAgent: agentB),
        );
        expect(c.read(effectiveAgentIdProvider), 'agent-b');
        expect(h.adminRepo.loggedEvents, [
          (targetAgentId: 'agent-b', action: ActingAsAuditAction.start),
        ]);

        // Switch directly to agent C -> brackets audit log with end(B) then start(C).
        await notifier.startActingAs(agentC);
        expect(
          c.read(actingAsControllerProvider),
          const ActingAsState.active(targetAgent: agentC),
        );
        expect(c.read(effectiveAgentIdProvider), 'agent-c');
        expect(h.adminRepo.loggedEvents.skip(1).toList(), [
          (targetAgentId: 'agent-b', action: ActingAsAuditAction.end),
          (targetAgentId: 'agent-c', action: ActingAsAuditAction.start),
        ]);

        // Selecting own account stops acting-as cleanly.
        await notifier.startActingAs(adminProfile);
        expect(c.read(actingAsControllerProvider), const ActingAsState.none());
        expect(c.read(effectiveAgentIdProvider), 'admin-1');
        expect(h.adminRepo.loggedEvents.last, (
          targetAgentId: 'agent-c',
          action: ActingAsAuditAction.end,
        ));

        // Audit log failures never block starting or exiting.
        h.adminRepo.logEventError = 'Audit endpoint offline';
        await notifier.startActingAs(agentB);
        expect(c.read(actingAsControllerProvider).targetAgentId, 'agent-b');
        await notifier.stopActingAs();
        expect(c.read(actingAsControllerProvider), const ActingAsState.none());

        // Never persisted to SharedPreferences: nothing written.
        expect(h.prefs.getKeys(), isEmpty);
      },
    );

    test('activeSessionKeyProvider resets on target switch and exit', () async {
      final h = await buildHarness();
      final c = h.container;

      final keyChanges = <String?>[];
      c.listen(
        activeSessionKeyProvider,
        (_, next) => keyChanges.add(next),
        fireImmediately: true,
      );
      c.listen(rDHubSelectionProvider, (_, _) {});
      c.listen(rDHubFiltersProvider, (_, _) {});

      expect(keyChanges, ['auth:admin-1']);

      // Switch to agent B -> new session key resets Hub selection/filters.
      c.read(rDHubSelectionProvider.notifier).selectAll(['inst-1']);
      c.read(rDHubFiltersProvider.notifier).setSearchQuery('old-query');
      await c.read(actingAsControllerProvider.notifier).startActingAs(agentB);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(activeSessionKeyProvider), 'auth:admin-1:as:agent-b');
      expect(keyChanges, ['auth:admin-1', 'auth:admin-1:as:agent-b']);
      expect(c.read(rDHubSelectionProvider).count, 0);
      expect(c.read(rDHubFiltersProvider).searchQuery, isEmpty);

      // Accumulate state under agent B, then switch to agent C -> new key resets session state.
      c.read(rDHubSelectionProvider.notifier).selectAll(['inst-b1']);
      c.read(rDHubFiltersProvider.notifier).setSearchQuery('bhavna-query');

      await c.read(actingAsControllerProvider.notifier).startActingAs(agentC);
      await Future<void>.delayed(Duration.zero);
      expect(keyChanges, [
        'auth:admin-1',
        'auth:admin-1:as:agent-b',
        'auth:admin-1:as:agent-c',
      ]);
      expect(c.read(rDHubSelectionProvider).count, 0);
      expect(c.read(rDHubFiltersProvider).searchQuery, isEmpty);

      // Stop acting as -> returns to admin's own session key.
      await c.read(actingAsControllerProvider.notifier).stopActingAs();
      await Future<void>.delayed(Duration.zero);
      expect(keyChanges.last, 'auth:admin-1');
    });

    test(
      'automatically resets to none on sign-out, account change, and enabling Demo Mode',
      () async {
        // 1. Sign-out reset.
        final h1 = await buildHarness();
        await h1.container
            .read(actingAsControllerProvider.notifier)
            .startActingAs(agentB);
        expect(
          h1.container.read(actingAsControllerProvider).isActingAs,
          isTrue,
        );

        await h1.container.read(authControllerProvider.notifier).signOut();
        await Future<void>.delayed(Duration.zero);
        expect(
          h1.container.read(actingAsControllerProvider),
          const ActingAsState.none(),
        );
        expect(h1.container.read(activeSessionKeyProvider), isNull);
        expect(h1.container.read(effectiveAgentIdProvider), isNull);

        // 2. Account switch reset.
        final h2 = await buildHarness();
        await h2.container
            .read(actingAsControllerProvider.notifier)
            .startActingAs(agentB);
        h2.authRepo.emit(otherAdminUser);
        await Future<void>.delayed(Duration.zero);
        expect(
          h2.container.read(actingAsControllerProvider),
          const ActingAsState.none(),
        );
        expect(h2.container.read(activeSessionKeyProvider), 'auth:admin-2');

        // 3. Demo Mode enable reset + blocks starting acting-as while in Demo Mode.
        final h3 = await buildHarness();
        await h3.container
            .read(actingAsControllerProvider.notifier)
            .startActingAs(agentB);
        await h3.container.read(demoModeProvider.notifier).enable();
        expect(
          h3.container.read(actingAsControllerProvider),
          const ActingAsState.none(),
        );
        expect(h3.container.read(activeSessionKeyProvider), 'demo');

        await h3.container
            .read(actingAsControllerProvider.notifier)
            .startActingAs(agentB);
        expect(
          h3.container.read(actingAsControllerProvider),
          const ActingAsState.none(),
        );
      },
    );
  });

  group('Supabase repositories: p_agent_id propagation, dispose & provider rebuilds', () {
    const sampleCustomer = Customer(
      id: 'cust-1',
      name: 'Asha',
      phone: '9876543210',
    );
    final sampleOtd = OneTimeDeposit(
      id: 'otd-1',
      customerId: 'cust-1',
      schemeType: OneTimeSchemeType.timeDeposit,
      principalAmount: 50000,
      interestRate: 7.5,
      termYears: 5,
      termMonths: 0,
      startDate: DateTime(2026, 1, 10),
    );
    final sampleRd = RecurringDeposit(
      id: 'rd-1',
      customerId: 'cust-1',
      schemeType: RecurringSchemeType.recurringDeposit,
      installmentAmount: 1000,
      interestRate: 6.7,
      termYears: 5,
      termMonths: 0,
      startDate: DateTime(2026, 1, 10),
    );
    final sampleSummary = RDLedgerSummary.pristine(
      sampleRd,
      DateTime(2026, 3, 20),
    );
    final sampleChange = RDLedgerChange(
      upsertTransactions: [
        RDTransaction(
          id: 'tx-1',
          rdId: 'rd-1',
          paidDate: DateTime(2026, 3, 10),
          amount: 1000,
          paymentMode: RDPaymentMode.cash,
        ),
      ],
    );

    test(
      'repository providers rebuild and dispose cleanly on target switch',
      () async {
        await HttpOverrides.runZoned(
          () async {
            SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();
            final authRepo = FakeAuthRepository(initialUser: adminUser);
            final adminRepo = FakeAdminRepository(
              isAdmin: true,
              agents: const [agentB, agentC],
            );
            final client = SupabaseClient(
              'http://127.0.0.1:9',
              'dummy-anon-key',
              authOptions: const AuthClientOptions(
                authFlowType: AuthFlowType.implicit,
              ),
            );

            final container = ProviderContainer(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                authRepositoryProvider.overrideWithValue(authRepo),
                adminRepositoryProvider.overrideWithValue(adminRepo),
                supabaseClientProvider.overrideWithValue(client),
              ],
            );
            addTearDown(() async {
              authRepo.dispose();
              container.dispose();
              await client.dispose();
            });

            container.listen(authControllerProvider, (_, _) {});
            container.listen(actingAsControllerProvider, (_, _) {});
            await Future<void>.delayed(Duration.zero);

            await container
                .read(actingAsControllerProvider.notifier)
                .startActingAs(agentB);

            final cSub = container.listen(
              customerRepositoryProvider,
              (_, _) {},
            );
            final oSub = container.listen(
              oneTimeDepositRepositoryProvider,
              (_, _) {},
            );
            final rSub = container.listen(
              recurringDepositRepositoryProvider,
              (_, _) {},
            );
            final lSub = container.listen(
              rdLedgerRepositoryProvider,
              (_, _) {},
            );
            addTearDown(() {
              cSub.close();
              oSub.close();
              rSub.close();
              lSub.close();
            });

            final c1 = cSub.read();
            final o1 = oSub.read();
            final r1 = rSub.read();
            final l1 = lSub.read();

            // Switching target to agent C creates fresh repository instances (and disposes previous ones).
            await container
                .read(actingAsControllerProvider.notifier)
                .startActingAs(agentC);
            expect(identical(cSub.read(), c1), isFalse);
            expect(identical(oSub.read(), o1), isFalse);
            expect(identical(rSub.read(), r1), isFalse);
            expect(identical(lSub.read(), l1), isFalse);

            // Idempotent dispose on previous repositories never throws.
            (c1 as SupabaseCustomerRepository).dispose();
            (o1 as SupabaseOneTimeDepositRepository).dispose();
            (r1 as SupabaseRecurringDepositRepository).dispose();
            (l1 as SupabaseRDLedgerRepository).dispose();
          },
          createHttpClient: (ctx) =>
              _LoopbackHttpOverrides().createHttpClient(ctx),
        );
      },
    );

    test(
      'SupabaseAdminRepository and all 4 repos send exact RPC params, p_agent_id, and agent_id filters',
      () async {
        await HttpOverrides.runZoned(
          () async {
            final stub = await _startStubSupabaseServer();

            // 1. SupabaseAdminRepository
            final adminRepo = SupabaseAdminRepository(stub.client);
            stub.setNextResponse(200, true);
            _expectSuccess(await adminRepo.isCurrentUserAdmin(), isTrue);
            expect(stub.requests.last.path, '/rest/v1/rpc/is_admin');

            stub.setNextResponse(200, [
              {
                'id': 'agent-b',
                'name': 'Bhavna Mehta',
                'email': 'bhavna@postfolio.dev',
                'agency_code': 'AG-102',
              },
            ]);
            _expectSuccess(await adminRepo.listAgents(), [agentB]);
            expect(
              stub.requests.last.path,
              '/rest/v1/rpc/list_agents_for_admin',
            );

            // Malformed response from list_agents_for_admin maps to sanitized Failure.
            stub.setNextResponse(200, {'unexpected': true});
            _expectFailure(await adminRepo.listAgents(), isNotEmpty);

            stub.setNextResponse(200, null);
            _expectSuccess(
              await adminRepo.logActingAsEvent(
                targetAgentId: 'agent-b',
                action: ActingAsAuditAction.start,
              ),
            );
            expect(
              stub.requests.last.path,
              '/rest/v1/rpc/log_admin_acting_as_event',
            );
            expect(stub.requests.last.body, {
              'p_target_agent_id': 'agent-b',
              'p_action': 'start',
            });

            // 42501 permission denied maps cleanly via SupabaseErrorMapper.
            stub.setNextResponse(403, {
              'code': '42501',
              'message': 'Unauthorized',
            });
            _expectFailure(
              await adminRepo.isCurrentUserAdmin(),
              'You do not have permission to modify this record.',
            );

            // 2. All 4 repositories send p_agent_id / agent_id = agent-b when acting as another agent.
            final customerRepo = SupabaseCustomerRepository(
              stub.client,
              effectiveAgentId: 'agent-b',
            );
            final otdRepo = SupabaseOneTimeDepositRepository(
              stub.client,
              effectiveAgentId: 'agent-b',
            );
            final rdRepo = SupabaseRecurringDepositRepository(
              stub.client,
              effectiveAgentId: 'agent-b',
            );
            final ledgerRepo = SupabaseRDLedgerRepository(
              stub.client,
              effectiveAgentId: 'agent-b',
            );
            addTearDown(() {
              customerRepo.dispose();
              otdRepo.dispose();
              rdRepo.dispose();
              ledgerRepo.dispose();
            });

            stub.setNextResponse(200, 'cust-1');
            _expectSuccess(await customerRepo.createCustomer(sampleCustomer));
            expect(
              stub.requests.last.path,
              '/rest/v1/rpc/save_customer_with_sb_account',
            );
            expect(
              (stub.requests.last.body as Map<String, dynamic>)['p_agent_id'],
              'agent-b',
            );

            stub.setNextResponse(200, null);
            _expectSuccess(await customerRepo.deleteCustomer('cust-1'));
            expect(stub.requests.last.path, '/rest/v1/rpc/delete_customer');
            expect(stub.requests.last.body, {
              'p_id': 'cust-1',
              'p_agent_id': 'agent-b',
            });

            stub.setNextResponse(200, 'otd-1');
            _expectSuccess(await otdRepo.createOneTimeDeposit(sampleOtd));
            expect(
              stub.requests.last.path,
              '/rest/v1/rpc/save_one_time_deposit',
            );
            expect(
              (stub.requests.last.body as Map<String, dynamic>)['p_agent_id'],
              'agent-b',
            );

            stub.setNextResponse(200, null);
            _expectSuccess(
              await otdRepo.updateDepositStatus('otd-1', DepositStatus.closed),
            );
            expect(stub.requests.last.path, '/rest/v1/rpc/set_deposit_status');
            expect(stub.requests.last.body, {
              'p_id': 'otd-1',
              'p_status': 'closed',
              'p_agent_id': 'agent-b',
            });

            stub.setNextResponse(200, const <Object?>[]);
            _expectSuccess(await otdRepo.deleteOneTimeDeposit('otd-1'));
            expect(stub.requests.last.method, 'DELETE');
            expect(stub.requests.last.path, '/rest/v1/account_identities');
            expect(stub.requests.last.query['id'], 'eq.otd-1');
            expect(stub.requests.last.query['agent_id'], 'eq.agent-b');

            stub.setNextResponse(200, 'rd-1');
            _expectSuccess(await rdRepo.saveRecurringDeposit(sampleRd));
            expect(
              stub.requests.last.path,
              '/rest/v1/rpc/save_recurring_deposit',
            );
            expect(
              (stub.requests.last.body as Map<String, dynamic>)['p_agent_id'],
              'agent-b',
            );

            stub.setNextResponse(200, null);
            _expectSuccess(
              await rdRepo.updateDepositStatus('rd-1', DepositStatus.closed),
            );
            expect(stub.requests.last.path, '/rest/v1/rpc/set_deposit_status');
            expect(stub.requests.last.body, {
              'p_id': 'rd-1',
              'p_status': 'closed',
              'p_agent_id': 'agent-b',
            });

            stub.setNextResponse(200, const <Object?>[]);
            _expectSuccess(await rdRepo.deleteRecurringDeposit('rd-1'));
            expect(stub.requests.last.method, 'DELETE');
            expect(stub.requests.last.path, '/rest/v1/account_identities');
            expect(stub.requests.last.query['id'], 'eq.rd-1');
            expect(stub.requests.last.query['agent_id'], 'eq.agent-b');

            stub.setNextResponse(200, const <Object?>[]);
            _expectSuccess(await ledgerRepo.upsertSummaries([sampleSummary]));
            expect(stub.requests.last.path, '/rest/v1/rd_ledger_summary');
            final upsertedRows = stub.requests.last.body as List<dynamic>;
            expect(
              (upsertedRows.single as Map<String, dynamic>)['agent_id'],
              'agent-b',
            );

            stub.setNextResponse(200, null);
            _expectSuccess(
              await ledgerRepo.applyChange(
                sampleChange,
                summaries: [sampleSummary],
              ),
            );
            expect(
              stub.requests.last.path,
              '/rest/v1/rpc/apply_rd_ledger_change',
            );
            expect(
              (stub.requests.last.body as Map<String, dynamic>)['p_agent_id'],
              'agent-b',
            );

            // 3. When effectiveAgentId is omitted, p_agent_id is omitted from RPC payloads.
            final defaultCustomerRepo = SupabaseCustomerRepository(stub.client);
            addTearDown(defaultCustomerRepo.dispose);
            stub.setNextResponse(200, null);
            _expectSuccess(await defaultCustomerRepo.deleteCustomer('cust-1'));
            expect(stub.requests.last.body, {'p_id': 'cust-1'});
          },
          createHttpClient: (ctx) =>
              _LoopbackHttpOverrides().createHttpClient(ctx),
        );
      },
    );
  });
}
