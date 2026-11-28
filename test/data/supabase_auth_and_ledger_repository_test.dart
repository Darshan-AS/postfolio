import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/auth/data/supabase_auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

typedef _RecordedRequest = ({
  String method,
  String path,
  Map<String, String> query,
  Object? body,
});

typedef _StubHandler =
    ({int statusCode, Object? body}) Function(_RecordedRequest req);

class _FakeGoogleSignIn implements GoogleSignIn {
  bool signOutCalled = false;
  Error? throwOnAuthenticate;
  Exception? throwOnSignOut;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {}

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const <String>[],
  }) async {
    if (throwOnAuthenticate != null) throw throwOnAuthenticate!;
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    if (throwOnSignOut != null) throw throwOnSignOut!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<
  ({
    HttpServer server,
    SupabaseClient client,
    List<_RecordedRequest> requests,
    void Function(_StubHandler fn) setHandler,
  })
>
_startStubSupabaseServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final requests = <_RecordedRequest>[];
  _StubHandler handler = (_) => (statusCode: 200, body: const <Object?>[]);

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
    final recorded = (
      method: req.method,
      path: req.uri.path,
      query: req.uri.queryParameters,
      body: decoded,
    );
    requests.add(recorded);
    final res = handler(recorded);
    req.response.statusCode = res.statusCode;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(res.body));
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
    setHandler: (_StubHandler fn) => handler = fn,
  );
}

void main() {
  group('SupabaseAuthRepository', () {
    test(
      'exposes currentUser, handles signInWithPassword success/errors & signOut',
      () async {
        final stub = await _startStubSupabaseServer();
        final google = _FakeGoogleSignIn();
        final repo = SupabaseAuthRepository(
          supabaseClient: stub.client,
          googleSignIn: google,
        );

        expect(repo.currentUser, isNull);
        final emitted = <String?>[];
        final sub = repo.authStateChanges.listen((u) => emitted.add(u?.email));
        addTearDown(sub.cancel);

        // Password sign-in success creates session and emits mapped user.
        stub.setHandler((req) {
          if (req.path.endsWith('/token')) {
            return (
              statusCode: 200,
              body: {
                'access_token':
                    'header.${base64Url.encode(utf8.encode('{"sub":"agent-1","exp":2999999999}'))}.sig',
                'token_type': 'bearer',
                'expires_in': 3600,
                'refresh_token': 'refresh-1',
                'user': {
                  'id': 'agent-1',
                  'aud': 'authenticated',
                  'role': 'authenticated',
                  'email': 'agent@postfolio.dev',
                  'app_metadata': {'provider': 'email'},
                  'user_metadata': {'full_name': 'Agent One'},
                  'created_at': '2026-01-01T00:00:00Z',
                },
              },
            );
          }
          return (statusCode: 200, body: {});
        });

        final ok = await repo.signInWithPassword(
          email: 'agent@postfolio.dev',
          password: 'secret',
        );
        expect(ok, isA<Success<AuthUser, String>>());
        expect(
          (ok as Success<AuthUser, String>).value.email,
          'agent@postfolio.dev',
        );
        expect(repo.currentUser?.displayName, 'Agent One');

        // Google sign-in error maps cleanly through SupabaseErrorMapper.
        google.throwOnAuthenticate = StateError('cancelled');
        final gFail = await repo.signInWithGoogle();
        expect(
          gFail,
          isA<Failure<AuthUser, String>>().having(
            (f) => f.error,
            'error',
            'cancelled',
          ),
        );

        // Invalid credentials map through SupabaseErrorMapper without leaking GoTrue guts.
        stub.setHandler(
          (_) => (
            statusCode: 400,
            body: {
              'error': 'invalid_grant',
              'message': 'Invalid login credentials',
            },
          ),
        );
        final bad = await repo.signInWithPassword(
          email: 'agent@postfolio.dev',
          password: 'wrong',
        );
        expect(
          bad,
          isA<Failure<AuthUser, String>>().having(
            (f) => f.error,
            'error',
            t.errors.invalidCredentials,
          ),
        );

        // Sign-out calls googleSignIn.signOut and clears session.
        stub.setHandler((_) => (statusCode: 204, body: null));
        final signedOut = await repo.signOut();
        expect(google.signOutCalled, isTrue);
        expect(signedOut, isA<Success<void, String>>());

        // Sign-out failure returns localized fallback when google signOut throws.
        google.throwOnSignOut = Exception('network');
        final signOutErr = await repo.signOut();
        expect(
          signOutErr,
          isA<Failure<void, String>>().having(
            (f) => f.error,
            'error',
            t.errors.signOutFailed,
          ),
        );
      },
    );
  });

  group('SupabaseRDLedgerRepository', () {
    test(
      'short-circuits empty inputs, guards unauthenticated reads, and executes RPC/UPSERT payloads',
      () async {
        final stub = await _startStubSupabaseServer();

        final unauthRepo = SupabaseRDLedgerRepository(stub.client);
        addTearDown(unauthRepo.dispose);

        expect(
          await unauthRepo.fetchRawFactsForRds([]),
          isA<Success<Map<String, RDRawFactsBundle>, String>>().having(
            (s) => s.value,
            'value',
            isEmpty,
          ),
        );
        expect(
          await unauthRepo.upsertSummaries([]),
          isA<Success<void, String>>(),
        );
        expect(
          await unauthRepo.applyChange(const RDLedgerChange()),
          isA<Success<void, String>>(),
        );
        expect(
          await unauthRepo.watchSummaries().first,
          isA<Success<List<RDLedgerSummary>, String>>().having(
            (s) => s.value,
            'value',
            isEmpty,
          ),
        );
        expect(
          await unauthRepo.fetchRawFactsForRds(['rd-1']),
          isA<Failure<Map<String, RDRawFactsBundle>, String>>().having(
            (f) => f.error,
            'error',
            'Agent not authenticated',
          ),
        );
        expect(
          await unauthRepo.fetchPoDepositsByBatch('batch-1'),
          isA<Failure<List<RDPoDeposit>, String>>().having(
            (f) => f.error,
            'error',
            'Agent not authenticated',
          ),
        );

        // Scoped repository (acting as agent-2) executes reads, upserts, and RPC cleanly.
        final repo = SupabaseRDLedgerRepository(
          stub.client,
          effectiveAgentId: 'agent-2',
        );
        addTearDown(repo.dispose);

        stub.setHandler((req) {
          if (req.path.endsWith('/rd_transactions')) {
            return (
              statusCode: 200,
              body: [
                {
                  'id': 'tx-1',
                  'rd_id': 'rd-1',
                  'amount': 1000.0,
                  'paid_date': '2026-04-10',
                  'payment_mode': 'cash',
                },
              ],
            );
          }
          if (req.path.endsWith('/rd_po_deposits')) {
            return (
              statusCode: 200,
              body: [
                {
                  'id': 'po-1',
                  'rd_id': 'rd-1',
                  'deposited_on': '2026-04-12',
                  'installment_count': 1,
                  'fee_paid': 0.0,
                  'amount': 1000.0,
                  'batch_id': 'batch-1',
                },
              ],
            );
          }
          return (statusCode: 200, body: const <Object?>[]);
        });

        final facts = await repo.fetchRawFactsForRds(['rd-1', 'rd-1']);
        expect(facts, isA<Success<Map<String, RDRawFactsBundle>, String>>());
        final bundle = (facts as Success<Map<String, RDRawFactsBundle>, String>)
            .value['rd-1']!;
        expect(bundle.transactions.single.id, 'tx-1');
        expect(bundle.poDeposits.single.batchId, 'batch-1');

        final batch = await repo.fetchPoDepositsByBatch('batch-1');
        expect(batch, isA<Success<List<RDPoDeposit>, String>>());
        expect(
          (batch as Success<List<RDPoDeposit>, String>).value.single.id,
          'po-1',
        );

        final summary = RDLedgerSummary(
          rdId: 'rd-1',
          factsVersion: 1,
          projectedOn: DateTime(2026, 4, 20),
        );
        expect(
          await repo.upsertSummaries([summary]),
          isA<Success<void, String>>(),
        );

        final change = RDLedgerChange(
          upsertTransactions: [
            RDTransaction(
              id: 'tx-2',
              rdId: 'rd-1',
              amount: 1000,
              paidDate: DateTime(2026, 4, 15),
              paymentMode: RDPaymentMode.upi,
            ),
          ],
          insertPoDeposits: [
            RDPoDeposit(
              id: 'po-2',
              rdId: 'rd-1',
              depositedOn: DateTime(2026, 4, 16),
              installmentCount: 1,
              feePaid: 0,
              amount: 1000,
            ),
          ],
        );
        expect(
          await repo.applyChange(change, summaries: [summary]),
          isA<Success<void, String>>(),
        );
        final rpcReq = stub.requests.last;
        expect(rpcReq.path, endsWith('/rpc/apply_rd_ledger_change'));
        expect((rpcReq.body as Map<String, dynamic>)['p_agent_id'], 'agent-2');

        // Error responses are mapped cleanly.
        stub.setHandler(
          (_) =>
              (statusCode: 400, body: {'code': '42501', 'message': 'denied'}),
        );
        expect(
          await repo.upsertSummaries([summary]),
          isA<Failure<void, String>>().having(
            (f) => f.error,
            'error',
            t.errors.permissionDenied,
          ),
        );
      },
    );
  });
}
