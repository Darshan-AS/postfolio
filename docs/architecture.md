# Postfolio Architecture Guide

This document provides a high-level overview of Postfolio's **Presentation ↔ Domain ↔ Data** architecture on **Flutter + Riverpod + Supabase (PostgreSQL 17)**.

## 1. Feature-First Layered Architecture

The codebase inside `lib/` is organized into two top-level directories:
1. **`core/`**: Shared design tokens (`core/theme/`), reusable widgets (`core/widgets/`), routing (`core/routing/`), environment/flavor safety (`core/env/`), error sanitization (`core/utils/supabase_error_mapper.dart`), Web telemetry (`core/services/app_error_reporter.dart`), and deterministic demo fixtures (`core/mocks/fake_data_source.dart`).
2. **`features/`**: Self-contained vertical business slices (`auth`, `customers`, `one_time_deposits`, `recurring_deposits`, `dashboard`).

Inside each feature, layers are strictly isolated:

```text
lib/features/<feature>/
 ├── data/           # Abstract repository contracts, Supabase*Repository, Fake*Repository
 ├── domain/         # Pure Dart Freezed entities, validation rules, projectors/calculators
 └── presentation/   # Riverpod Notifiers/Controllers, HookConsumerWidget screens & sheets
```

---

## 2. Unidirectional Data Flow ("Brain in Dart, Muscle in Postgres")

### A. Presentation Layer (UI & State)
- **Dumb Widgets**: Screens and widgets are declarative (`ConsumerWidget` / `HookConsumerWidget`). They read state via `ref.watch(...)` and dispatch intents to Riverpod controllers via `ref.read(...Provider.notifier)`.
- **Hooks**: Ephemeral UI state (`TextEditingController`, `FocusNode`, form drafts) lives in `flutter_hooks`.
- **Controllers**: Riverpod `Notifier` / `AsyncNotifier` classes coordinate domain validation and repository calls, returning `Result<T, String>` (`Success` / `Failure`) rather than throwing across UI boundaries.

### B. Domain Layer (Pure Business Logic — "The Brain")
- **Zero Infrastructure Dependencies**: Domain models and calculators have zero imports from Flutter UI or Supabase SDKs.
- **Smart Factories & Invariants**: `Customer.create`, `OneTimeDeposit.create`, `RecurringDeposit.create`, and `Nominee.validateNominees` enforce domain invariants before any write reaches the network.
- **Facts-Only Sequential RD Ledger (`RDLedgerProjector`)**:
  - Persists only atomic facts: customer collections (`rd_transactions`), Post Office counter deposits (`rd_po_deposits`), and agent fee absorptions (`rd_fee_absorptions`).
  - `RDLedgerProjector.project(facts, asOf)` deterministically derives the 60-month passbook, accrued vs settled India Post default fees, `customerCredit`, and the `RDLedgerSummary` Monthly Hub cache.

### C. Data Layer (Supabase PostgreSQL 17 — "The Muscle")
- **Single Source of Truth**: Supabase Auth (Google Sign-In / OAuth PKCE on Web, native ID token on mobile) + PostgreSQL 17 with Row-Level Security (`RLS`) on every table.
- **Reads**: Pre-joined `security_invoker = true` SQL views (`customer_details_view`, `one_time_deposit_details_view`, `recurring_deposit_details_view`) paired with agent-scoped Realtime CDC streams.
- **Writes**: Multi-table writes execute atomically inside PL/pgSQL RPCs (`save_customer_with_sb_account`, `save_one_time_deposit`, `save_recurring_deposit`, `set_deposit_status`, `undo_rd_po_deposit_batch`). Internal privileged helpers reside in the unexposed `private` schema.
- **Sanitized Error Boundary**: All `Supabase*Repository` implementations map `PostgrestException` and `AuthException` through `SupabaseErrorMapper` so raw SQL constraint names never leak to the UI.
- **Demo Mode & Unit Testing**: Toggling `demoModeProvider` (or overriding providers in `ProviderContainer` tests) binds repositories to deterministic in-memory `Fake*Repository` implementations backed by `FakeDataSource` (zero `Mockito`, zero network calls).

---

## 3. Platform Hosting, Flavors & Crash Telemetry

- **Hosting**: Flutter Web (`--wasm`) is deployed to **Firebase Hosting** (`postfolio-app`) with strict security and cache headers.
- **Telemetry**:
  - **Android / iOS / macOS**: `FirebaseCrashlytics` captures fatal Flutter and async platform errors.
  - **Web**: `AppErrorReporter` forwards deduplicated, rate-limited uncaught errors to `public.log_client_error` (`public.app_error_logs`, bounded to 500 rows).
- **Flavor Safety**: Android defines `staging` (`dev.darshanas.postfolio.staging`) and `prod` (`dev.darshanas.postfolio`) flavors. `Env.assertFlavorSafe` blocks `staging` builds from booting against a production Supabase URL unless explicitly configured via `--dart-define-from-file=config/local.json` or `config/staging.json`.
