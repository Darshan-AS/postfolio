# Architecture & Infrastructure Conventions

## 1. State Management & DI
- **Riverpod**: Use `Notifier` or `AsyncNotifier` (via `@riverpod` generator).
- **Dependency Injection**: All services, repositories, and the `SupabaseClient` instance must be provided via Riverpod (`supabaseClientProvider`). No static singletons in domain or presentation code.
- **Feature-First Structure**: `lib/features/<feature>/` with `data`, `domain`, and `presentation` layers. Layers must be isolated: `domain` never imports `data` or `presentation`.

## 2. Routing (`go_router`)
- **Navigation Policy (`go` vs `push`)**:
  - **`go()` (Declarative/Logical Navigation)**: Replaces the current navigation stack to match the exact route hierarchy defined in the router configuration.
    - **Use for**: Primary navigation (Tabs, Shell routes, Auth redirects), Deep Linking, and horizontal structural movement.
  - **`push()` (Imperative/Temporal Navigation)**: Pushes onto the navigation stack.
    - **Use for**: Master-Detail Flow (List -> Detail), Forms, Data Entry, and vertical hierarchical movement so hardware/predictive back returns cleanly.
- **Deep Links**: Never pass complex objects via `extra`. Pass primitive IDs in the URL so Web page refreshes (`F5`) and deep links stay deterministic.
- **Keyboard Handling**: Let the outer `Scaffold` handle resizing. Use a `Builder` inside the body if `MediaQuery` modification is needed.

## 3. Backend & Telemetry ("Brain in Dart, Muscle in Postgres")
- **Single Backend (Supabase / PostgreSQL 17)**:
  - **Reads**: Pre-joined `security_invoker = true` PostgreSQL views (`*_details_view`) + agent-filtered Realtime CDC streams (`.stream(primaryKey: ['id']).eq('agent_id', _agentId)`).
  - **Writes**: Multi-table mutations execute inside atomic PL/pgSQL RPCs (`save_customer_with_sb_account`, `save_one_time_deposit`, `save_recurring_deposit`, `set_deposit_status`, `undo_rd_po_deposit_batch`). Internal `SECURITY DEFINER` helpers live strictly in the unexposed `private` schema.
  - **Facts-Only RD Ledger**: `rd_transactions`, `rd_po_deposits`, and `rd_fee_absorptions` store immutable domain facts; `RDLedgerProjector` derives the 60-month passbook, default fees, and summary cache (`rd_ledger_summary`).
- **Error Sanitization**: Every `Supabase*Repository` routes caught exceptions through `SupabaseErrorMapper.describe(...)` before returning `Failure<T, String>`. Raw SQL identifiers, constraint names, or stack traces must never reach UI strings.
- **Crash & Error Telemetry**:
  - **Native (`!kIsWeb`)**: Firebase Crashlytics (`firebase_core` + `firebase_crashlytics`). No other Firebase SDKs (`cloud_firestore`, `firebase_auth`, `firebase_analytics`, `firebase_performance`) are permitted.
  - **Web (`kIsWeb`)**: `AppErrorReporter` writes rate-limited, truncated entries via `public.log_client_error` into bounded `public.app_error_logs` (capped at 500 rows). Web builds are hosted on **Firebase Hosting** (`postfolio-app`).
- **Environment & Flavor Isolation (`Env`)**:
  - Prefers `--dart-define` / `--dart-define-from-file=config/<env>.json` at compile time with `.env` (`envied`) fallback.
  - `Env.assertFlavorSafe(flavor: appFlavor)` runs in `main()` before `Supabase.initialize` and throws `StateError` if the `staging` flavor is pointed at production Supabase.

## 4. Local Storage & Demo Mode
- Use `SharedPreferences` (wrapped in `StorageService`) strictly for non-sensitive UI preferences (theme mode, sort/filter state, demo mode flag).
- Demo Mode (`demoModeProvider`) swaps data providers to deterministic in-memory `Fake*Repository` / `FakeDataSource` fixtures (zero network writes, 100% domain-valid data).
- Prohibited: `flutter_secure_storage`, `hive_ce`, `isar`, `drift`, `cloud_firestore`, `firebase_auth`.
