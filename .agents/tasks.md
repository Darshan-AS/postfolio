# Project Tasks & Roadmap

*Note: For a summarized history of past work, see `.agents/historical_summary.md` and `.agents/progress.md`. For the raw chronological task history, see `.agents/historical_tasks_archive.md`.*

## 🛡️ Stabilization & Redesign Roadmap (Stages 0–5)
### Stage 0: Emergency P0 Security, Data-Loss & Summary Race Hotfixes (Completed)
- [x] **P0-1 (Supabase RPC & Grant Lockdown)**: Move internal `SECURITY DEFINER` helpers (`assert_authenticated`, `assert_customer_owner`, `assert_account_owner`, `upsert_account_identity`, `replace_account_nominees`) into unexposed `private` schema; inline nominee JSON aggregation into `security_invoker = true` views and drop `public.get_account_nominees`; revoke `SELECT` on `public` tables from `anon` and `EXECUTE` on `public` routines from `PUBLIC`/`anon`/`authenticated`, granting `EXECUTE` strictly to valid client RPCs and RLS boolean helpers (`is_admin`, `owns_account`).
- [x] **P0-2 (JIT Linking FK Cascade)**: Add missing `ON UPDATE CASCADE` to `agent_id` foreign keys on `rd_po_deposits`, `rd_fee_absorptions`, and `rd_ledger_summary` so `handle_new_user()` profile ID relinking never fails with FK violations.
- [x] **P0-3 (Deposit Status Toggle Data-Loss Fix)**: Add `opening_receivable` to `SupabaseRecurringDepositRepository._listColumns`; create atomic `public.set_deposit_status(p_id, p_status)` RPC; wire `updateDepositStatus` across OTD/RD repositories and controllers so toggling `active`/`closed` never wipes `nominees`, `opening_receivable`, or `rd_ledger_summary`; preserve `rd_ledger_summary` in `save_recurring_deposit` when financial/schedule terms are unchanged; align `RecurringDeposit.validateUpdate` and `RDLedgerFacts.isFinancialTermsLocked`.
- [x] **P0-4 (RD Ledger Summary Double-Count, Race & 766-RD `undoBatch` Fix)**: Deduplicate optimistic `apply` closures by ID in `RDLedgerController.recordPayment` and `depositNextToPo`; `await _refreshSummary` inside `_mutate` to prevent sequential `recordPayment` + `absorbFee` clobbering; remove stale `autoDispose` `.value` shortcut in `RDLedgerController._readFacts`; add atomic `public.undo_rd_po_deposit_batch(p_batch_id)` RPC enforcing latest-visit ordering and returning affected `UUID[]` so `undoBatch` refreshes only touched RDs instead of all 766 accounts.
- [x] **P0-5 (PII Asset Leak & Dead Web Script Removal)**: Remove `- data/` from `pubspec.yaml` `flutter.assets` and remove unused Corbado Passkeys `<script>` from `web/index.html`.
- [x] **P0-6 (SQL + Dart Verification Suite)**: Extended `supabase/tests/rd_ledger_facts_rls.sql` (14 SQL cases), controller unit tests, and Supabase repository/E2E tests; verified `dart analyze --fatal-infos` (0 issues) and `flutter test` (82/82 passing).

### Stage 1: CI Gates, Encrypted GDrive Backups & Repo Baseline Test Backfill (Completed)
- [x] Convert `supabase/tests/rd_ledger_facts_rls.sql` into self-asserting SQL contract suite (`ON_ERROR_STOP=1` + `SQLSTATE` assertions on all 14 cases) and split `@Tags(['integration'])` in `dart_test.yaml`.
- [x] Backfill compact table-driven domain tests (`Customer`, `Nominee`, `OneTimeDeposit`, `ProjectionCalculator` 5-scheme math) and `ProviderContainer` + `Fake*Repository` baseline tests (`CustomersController`, `OneTimeDepositsController`, `RecurringDepositsController`, list criteria, `dashboardMetricsProvider` Indian FY math), plus `tool/check_coverage.dart` per-layer DDD coverage ratchet (`domain >= 72%`, `controllers >= 68%`, `total >= 44%`).
- [x] Add `.github/workflows/ci.yml` (analyzer, codegen, unit/widget + `lcov` ratchet stripping `*.g.dart`/`*.freezed.dart`, Supabase Docker SQL + integration suites) and `.github/workflows/backup.yml` (nightly `pg_dump -Fc | age` uploaded via `rclone` `drive.file` OAuth2 token to Google Drive + optional in-memory `pg_restore --list` verification).
- [x] Harden `release.yml` (tag-gated deploys, analyzer/test gate, `UPLOAD_KEYSTORE_BASE64` + `KEY_PROPERTIES` support with `KEYSTORE_BASE64` fallback), Android R8 (`isMinifyEnabled`, `isShrinkResources`, `proguard-rules.pro`, `-Xmx4G`), `firebase.json` security/cache headers, and `analysis_options.yaml` (`strict-casts`, `strict-raw-types`, `unawaited_futures`, `cancel_subscriptions`, `only_throw_errors`).

### Stage 2: Legacy Firebase Excision, Error Sanitization & Flavor Isolation (Completed)
- [x] TDD first: `AuthController` + `FakeAuthRepository` spec, table-driven `PostgrestException`/`AuthException` `SupabaseErrorMapper` spec, `app_error_logs` RLS & truncation SQL contract (`CASE 15`), `AppErrorReporter` rate-limiting spec, `Env.assertFlavorSafe` spec, and deterministic `FakeDataSource` domain-invariant spec (fixing the 200%-nominee Demo Mode bug).
- [x] Remove `cloud_firestore`, `firebase_auth`, `firebase_performance`, `firebase_analytics`, `faker`, `csv`, `Firestore*Repository`, `FirebaseAuthRepository`, `UnsupportedRDLedgerRepository`, `Env.useSupabase`, `firestore_keys.dart`, `firestore.rules`, and retired migration runners (retaining `firebase_core` + native `!kIsWeb` `firebase_crashlytics` + Firebase Hosting + Web `AppErrorReporter` -> `public.app_error_logs`).
- [x] Wire `--dart-define-from-file` (`config/local.json`, `config/staging.json.example`) + `Env.assertFlavorSafe(flavor: appFlavor)`, verify `flutter build web --wasm`, update architecture docs, and ratchet DDD layer coverage (`domain >= 73%`, `controllers >= 71%`, `data >= 41%`, `total >= 46%`).

### Stage 3: Domain Math, Pure-Dart Business Rules, Session Scoping & GoRouter Overhaul (Completed)
- [x] **Stage 3 (Domain Math, Pure-Dart Business Rules, Session Scoping & GoRouter Overhaul)**:
  - [x] TDD first: `Paise`/`BasisPoints`/`LocalDate` boundary & float-sum tables (`16.1+48.2+35.7 == 100%` nominees, `₹2.50` / `₹616.67` paise formatting, `23:45 IST` UTC day-shift), `ProjectionCalculator` month-end clamping + RD default maturity extension + Dec 2011–Nov 2014 KVP boundary, `RDPoDeposit.feePaid` counter override & cash-lot quote accuracy, Dart-owned `RecurringDeposit.validateUpdate` lock check + latest-visit batch undo validation, reactive customer rename overlay, auth sign-out cache disposal, and `GoRouter` deep-link/redirect/root-navigator specs.
  - [x] Implement exact money/date primitives, `RDLedgerProjector` counter-fee parity + trimmed `RDLedgerSummary.openItems` + future-month Hub arrears visibility, controller-level RD financial-terms lock & batch-undo rules (eliminating split-brain with SQL), bulk PO visit batch writes (`addPoDeposits(List)` + `upsertSummaries(List)` + self-healing dirty-summary retry), session-scoped `keepAlive` providers, reactive midnight clock, synchronous `AuthController` session hydration, `?redirect=` deep links, root-navigator detail/form routes, and `PopScope` dirty-form guards.

### Stage 4: UI System `material_ui`, Screen Polish, Counter-Fee Override UI, Accessibility & i18n (Completed)
- [x] **Stage 4 (UI System `material_ui`, Screen Polish, Counter-Fee Override UI, Accessibility & i18n)**:
  - [x] TDD first: form/sheet hook interaction specs (`NomineesInputSection` spacebar/share math, `CustomerFormScreen` validators, `RDLogPaymentSheet` prefill focus, `RDDepositSheet` / `RDPoVisitSheet` counter-fee override) and parameterized `360×800` @ `2.0x` text-scale + Light/Dark WCAG AA contrast & `>=44dp` tap-target suite.
  - [x] Implement `AppFinancialColors` + 4-mode theme selector, `Skeletonizer` dark shimmer, `AppFeedback` unification, form/sheet UX fixes (including counter-fee override inputs), desktop width constraints + copy actions, full Slang string extraction, and dead-key pruning.

### Stage 5: Pure-DDD Database Storage Hardening & Supabase `>1k`-Row Scalability (Completed)
- [x] **Stage 5 (Pure-DDD Database Storage Hardening & Supabase `>1k`-Row Scalability — Final Pre-PR Consolidation)**:
  - [x] TDD first: SQL storage-physics contracts (`ON DELETE NO ACTION` `23503` on customers/RDs with child records while cascading full-agent teardown, case-insensitive `UNIQUE (lower(email))` `23505`, partial `UNIQUE` SB per customer, `NUMERIC(12,2)` / `NUMERIC(5,2)` bounds, and plain `TEXT` enum columns accepting evolved Dart enum values without DDL) + `.range()` `>1,000`-row pagination & debounced reload spec + batch Hub `ensureSummaries` spec + Demo Mode delete-protection parity spec.
  - [x] Consolidate into a single post-`v2.3.1` SQL migration (`supabase/migrations/20261111000000_v2_4_storage_hardening.sql`): strip domain rules & enum `CHECK`s out of SQL (drop `undo_rd_po_deposit_batch`, drop `rd_transactions_payment_mode_check`, remove lock check from `save_recurring_deposit` and status enum check from `set_deposit_status`, leaving dumb multi-table ACID persistence envelopes), add `ON DELETE NO ACTION` FKs, `NUMERIC` types, `UNIQUE` indexes, Realtime publication cleanup, `.range()` pagination, batch `ensureSummaries`, and `Uuid().v7()`.

## 🔎 v2.4 Audit Follow-ups (Approved 2026-11-12 — In Progress)
*From the independent audit in `.agents/session_logs/2026-11-11_session_2.md`; fix log in `.agents/session_logs/2026-11-12_session_1.md`.*
- [x] **A1 (Visit selection)**: Keep the selected rows as the planner's seed set so toggling "include unready" in `RDPoVisitSheet` never widens the plan to every Hub row.
- [ ] **A2 (Visit write path)**: Stop `depositBatchToPo` / `undoBatch` returning Failure after the facts are committed; read facts with `fetchRawFactsForRds` instead of per-RD streams; make a retried visit a no-op (unique client batch ID).
- [ ] **A3 (Lock fails closed)**: `saveRecurringDeposit` must refuse a terms change when ledger facts cannot be read.
- [ ] **A4 (Backup workflow)**: Pass `$SUPABASE_DB_SESSION_URL` to `pg_dump` in `backup.yml`; run it once and restore one archive.
- [ ] **A5 (Default privileges)**: Revoke PUBLIC's default EXECUTE on functions globally and add a SQL contract that fails if any `public` function is executable by `anon`.
- [ ] **A6 (Enum guard)**: Decide the SQL boundary (restore enum CHECKs and/or tolerant decoding); decode list rows individually and log the original error instead of discarding it.
- [ ] **A7 (Migration rehearsal)**: Apply `20261111000000_v2_4_storage_hardening.sql` to a copy of production data before `supabase db push`; define release ordering.
- [ ] **A8 (Realtime staleness)**: Refetch on resubscribe and app resume, retry failed loads, and keep a queued refetch when the in-flight fetch throws.

## 📜 Upcoming Milestone: India Post Policy & Domain Audit (`v2.5`)
- [ ] **1. Statutory Rulebook & Circular Reference Docs (`docs/india_post_schemes_policy.md`)**: Compile authoritative citations across `G.S.R. 916(E)`–`922(E)` (National Savings RD, TD, MIS, KVP, NSC Rules 2019 & subsequent Gazette amendments), DOP SB Orders, Finacle CBS / DOP Agent Portal behavior, and MPKBY / SAS agency rules.
- [ ] **2. RD Default-Fee & Discontinuation Verification (`G.S.R. 916(E)`)**: Verify ₹1 per ₹100 denomination default-fee calculation on ₹10-multiple installments (`₹250` RD -> exact `₹2.50` paise vs whole-rupee ceiling at Finacle CBS / DOP Agent Portal), maximum 4-default discontinuation threshold + 2-month revival window, and 6-month / 12-month advance deposit rebates.
- [ ] **3. Quarterly Rate Schedule & Maturity Formula Audit (`PostalRateService` & `ProjectionCalculator`)**: Cross-check all 2000–2026 Ministry of Finance DEA quarterly rate circulars across `RD`, `TD` (1/2/3/5Y), `MIS`, `NSC`, and `KVP`, Finacle CBS maturity rounding conventions (exact paise vs nearest rupee), and scheme denomination min/max/multiple invariants (`RD` min ₹100 + ₹10 multiples; `TD`/`MIS`/`KVP`/`NSC` min ₹1,000 + ₹100 multiples; `MIS` ₹9L single / ₹15L joint caps).
- [ ] **4. MPKBY (4%) & SAS (0.5%) Commission + Section 194H TDS Rules**: Verify current Section 194H TDS rate (`2%` post-Oct 2024 Finance Act amendment) and aggregate Financial Year exemption threshold (`₹20,000`/FY from FY 2025-26) plus SAS applicability per scheme before implementing commission tracking.

## 🚀 Next Up (Supabase Migration - Phase 2 & 3)
- [x] **Bulk Migration Optimizer**: Redesigned sequential N+1 writes into batch/bulk insertions, reducing network roundtrips by up to 99.5% and accelerating bulk data migrations (e.g., 600+ records) by 100x+.
- [x] **Environments**: Add `GOOGLE_WEB_CLIENT_ID` and `GOOGLE_IOS_CLIENT_ID` to `.env`.
- [x] **Freezed Snake Case**: Update all Freezed models with `@JsonSerializable(fieldRename: FieldRename.snake)`.
- [x] **Date Conversion**: Update `@TimestampConverter()` to support both Firebase and Supabase.
- [x] **Interfaces**: Define abstract interfaces for all repositories.
- [x] **Parallel Repositories**: Create `Supabase*Repository` implementations alongside `Firebase*Repository`.
- [x] **Riverpod Toggle**: Implement provider overrides based on `Env.useSupabase`.
- [x] **SQL Views & RPC Procedures (Option 2 Architecture)**: Create SQL migrations for views (`customer_details_view`, `one_time_deposit_details_view`, `recurring_deposit_details_view`) and stored procedure RPCs (`save_customer_with_sb_account`, `save_one_time_deposit`, `save_recurring_deposit`). Refactor all `Supabase*Repository` implementations to use views for reads and RPCs for 100% atomic writes.
- [x] **Manual Full Database Backup via Docker**: Documented and verified official PostgreSQL 17 Docker container command to dump complete schema + data to local SQL files for manual cold storage archiving.
- [x] **Automated Off-site Database Backups**: Implemented `.github/workflows/backup.yml` streaming `postgres:17 pg_dump -Fc | age` to Google Drive via `rclone` (`drive.file` OAuth2 token) with 30-day pruning.

## 📅 Epic: RD Monthly Ledger & Transaction Tracking
- [x] **Phase 1: Database Schema & Migration (Muscle Approach)**: Created migration `20260903000000_rd_ledger_feature.sql` defining `rd_installments` schedule, check constraints, indexing, enabling real-time CDC, and designing atomic, lightweight bulk-write RPCs (`save_recurring_deposit`, `record_rd_customer_payment_allocated`, `record_rd_po_payments`). Verified successfully with local database compilation via `supabase db reset`.
- [x] **Phase 2: Dart Domain Models & Data Mapping**: Define Freezed domain models (`RDInstallment`, `RDTransaction`), implement pure late fee calculation, due date resolution, and payment allocation service in Dart, and compile using `build_runner`.
- [x] **Phase 3: Repository & State Architecture (DDD)**: Add ledger signatures to `RecurringDepositRepository` and implement in `SupabaseRecurringDepositRepository` & `FakeRecurringDepositRepository`. Set up Riverpod controllers and streams.
- [x] **Phase 4: UI Screen Integration & Polish**: Built collapsible prototype sections in `RecurringDepositDetailScreen` for Installments schedule and Payment history, added `initialPaidInstallments` onboarding baseline support, and fully resolved all enum/check constraint issues across screens, controllers, and database layers. Added robust multi-tiered validation guardrails (UI form greyouts, alert badge, domain model validation, and PostgreSQL exception raise) protecting financial terms (installment amount, start date, term, onboarding baseline) once active ledger transactions have been recorded. Unified write operations into `saveRecurringDeposit` across all repositories, resolved schedule date-drifting on terms update when uncommitted, and decoupled fake repositories from runtime domain services.
- [x] **Phase 4.1: Transaction Mutations & PO Reversals (DDD Allocation Replay Engine)**: Added `recomputeScheduleFromTransactions` in `RDLedgerService` to recalculate customer installment allocations, statuses, and late fees upon transaction edit or deletion. Added atomic RPCs `delete_rd_transaction` and `update_rd_transaction` in PostgreSQL migration `20260905000000_rd_transaction_mutations.sql`. Implemented repository and controller methods (`deleteCustomerPayment`, `updateCustomerPayment`, `revertPoPayments`). Added Material 3 `MenuAnchor` for editing (with live recalculated preview) and deleting transactions with confirmations, and updated the PO selection mode to allow both depositing and reverting PO settlement status.
- [x] **Phase 4.2: Fee Waivers, Dual Tracking & Split Allocations**: Added granular tracking of principal vs default fees (`paid_late_fee`, `is_late_fee_waived`), transaction split allocation components (`installment_amount`, `late_fee_amount`), 1-click fee forgiveness at any time (`toggle_rd_late_fee_waiver` RPC), and installment-first payment priority leaving default fees pending. Supported in `_LogPaymentBottomSheet` and `_EditPaymentBottomSheet` with live allocation previews. Verified with comprehensive unit test suites.
- [x] **Phase 4.3: Presentation Modularization & Clean Conventions Compliance**: Fully localized RD ledger using Slang (`t.recurringDeposits.ledger`), replaced Material icons with `HugeIcons` exclusively, eliminated magic numbers using `AppDimensions` and `AppSpacings`, decomposed 2,068-line screen into modular presentation widgets (`RDInstallmentsSection`, `RDTransactionsSection`, `RDLogPaymentSheet`, `RDEditPaymentSheet`, `RDAllocationPreviewCard`), and refactored `RDLedgerService` domain methods into pure helper functions and a functional `fold`. Verified with local Supabase DB reset and chrome unit test suites.
- [x] **Phase 4.4: RD Ledger Micro-View Overhaul (Heatmap, Next-Due Hero Card, Inspector Card & Yearly Accordion)**: Replaced uncollapsed 60-row scroll fatigue with an interactive 60-month Tenure Heatmap (`RDInstallmentHeatmap`), prominent "Next Due" Hero Card with 1-tap payment (`RDNextDueHeroCard`), single-month noise-free Inspector Card (`RDMonthInspectorCard`), and expandable yearly accordion (`_RDYearlyScheduleAccordion`).
- [x] **Phase 4.5: RD Macro Monthly Operations Hub**: Primary navigation `SegmentedButton` (`Accounts` | `Monthly Operations`), calendar month switcher (`< Month Year >`) with quick-reset chip, operational filter pills (`All`, `To Collect`, `Ready for PO`, `Settled`, `Overdue`) with dynamic counts, monthly KPI summary metrics, high-density operation cards with contextual 1-tap payment prefill, 1-tap PO deposit, multi-select batch PO deposits, and complete prior-month carryover arrears integration (top notice banner with 1-tap review, card subtitle past-due badge, red urgency indicator, and "Pay All" action). Verified with full test suite passing on Chrome (68/68 tests) and 0 analyzer issues.
- [x] **Phase 4.6: RD Ledger Architecture Redesign & Roadmap (Option 1+: Sparse Rollup + Allocation Lineage + In-Memory Hydration)**:
  - [x] **Stage 1 (Core Schema & Domain Foundation — Replaces RDL-1, RDL-2, RDL-10)**: Implement sparse `rd_installments` + normalized `rd_payment_allocations` (`ON DELETE CASCADE`) + `split_mode` intent on `rd_transactions` in migration `20261025000000_sparse_rd_ledger_and_allocations.sql`. Add `RDLedgerService.hydrateSchedule`, `extractSparseInstallments`, `diffSchedules`, replay pool overflow fix, and fee un-waiver integrity fix. Stop inserting 60 dummy rows on RD creation/update and switch SQL RPCs from `FOR` loops to set-based `jsonb_to_recordset` upserts with auto-pruning of untouched rows.
  - [x] **Stage 2 (Zero-Latency Monthly Hub Hydration & Deterministic Clock — RDL-3 & RDL-4)**: Introduce injectable `clockProvider` replacing scattered `DateTime.now()` calls, and hydrate Monthly Hub items and prior carryover arrears in memory from the sparse `rd_installments` stream + cached `recurringDepositsController` so month switching (`< Prev | Next >`) and filter changes execute in `< 1ms` with zero extra HTTP queries or skeleton flashes.
  - [x] **Stage 3 (Dumb Widgets & Presentation Decomposition — RDL-5)**: Move `isCurrentMonthOverdue` and `hasDivergentPending` into `RDMonthlyOperationItem`, move `prepareLogPayment` into `RDMonthlyOperationsController`, and extract `RDCheckpointsRow`, `RDOperationActionButton`, and a shared confirmation dialog helper from `RDMonthlyOperationCard` and `RDMonthlyOperationsView`.
  - [x] **Stage 4 (Post Office Agent Workflow Enhancements — RDL-6, RDL-7, RDL-8)**: Add India Post statutory deadline segmentation (`Due 15th` vs `Due EOM`), `By Account | By Customer` household grouping in the Monthly Hub, and global cross-month Agent Float summary (`Undeposited Cash in Hand` vs `Pocket Advances Receivable`).
  - [ ] **Stage 5 (On Hold — RDL-9: First-Class PO Lot Builder & Advance Rebates)**: Model DOP Portal Schedules/Lots (`rd_po_batches` linked via `po_batch_id` already provisioned on `rd_installments`, ₹20,000 cash limit guardrail, 6M/12M India Post Advance Deposit Rebates, and 4% MPKBY Commission/TDS calculation).
- [x] **Phase 4.7: RD Ledger & Monthly Hub UI/UX Redesign**:
  - [x] **Stage 1 (Macro Hub Sliver Layout & 3-Stage Pipeline)**: Refactor `RDMonthlyOperationsView` to `CustomScrollView` with collapsible header, interactive 3-Stage Pipeline (`RDMonthlyKpiRow`), sticky compact toolbar (removing duplicate status chips), and PO Queue quick-select strip.
  - [x] **Stage 2 (Smart 2-Step Pipeline Card)**: Replace verbose 3-pill fraction checkpoints in `RDMonthlyOperationCard` with a compact `Customer -> PO` 2-step pipeline pill + exception-only fraction/fee/arrear badges.
  - [x] **Stage 3 (Tabbed RD Detail Screen & Grid/List Toggle)**: Upgrade `RecurringDepositDetailScreen` with compact summary header + 3 tabs (`Schedule`, `Transactions`, `Account Info`), and add a `[ Matrix | Yearly List ]` toggle inside `RDInstallmentsSection`.
  - [x] **Stage 4 (Per-Month Allocation Chips on Transaction Receipts)**: Compute and render per-month allocation breakdown pills (`Inst #N: ₹X`, `Fee #N: ₹Y`) on each receipt card in `RDTransactionsSection`.
- [x] **Phase 5: Migration Script Backfill Adjustments**: Updated `lib/run_supabase_migration.dart` and added `RDLedgerService.calculateInitialPaidInstallments` to compute `initial_paid_installments` chronologically for legacy RDs (leveraging Option 1+ sparse schedule hydration so 0 dummy rows are inserted into `rd_installments` during migration).
- [x] **Phase 6: Facts-Only Ledger Redesign (supersedes Option 1+; see `rd_ledger_redesign_proposal.md`)** — persisted derived state (`rd_installments`) replaced by facts + one pure projection:
  - [x] **Step 1 (Domain)**: Add `RDPoDeposit`, `RDFeeWaiver`, `RDLedgerFacts`, `RDLedgerRules` (date-only default rule, paise-exact fee), `RDScheduleFactory`, `RDLedgerProjector` (single allocation path, fee accrual until settlement, overflow → `customerCredit`), `RDLedgerProjection`, `RDLedgerSummary` (hub cache shape with `installmentFor` reconstruction), `RDInstallmentDisplayStatus` mapper, `Money` paise helpers, `DateOnlyConverter`. Table-driven tests in `test/features/recurring_deposits/domain/`.
  - [x] **Step 2 (Schema)**: Migration creating `rd_po_deposits`, `rd_fee_waivers`, `rd_ledger_summary`, CHECK constraints on `rd_transactions`, backfill from `rd_installments`, RLS; drop broken `upsert_and_prune_rd_installments` and the ledger RPCs; simplify `save_recurring_deposit`. Verify against local DB.
  - [x] **Step 3 (Data)**: `RDLedgerRepository` (bounded per-RD fact streams, plain writes, summary upsert) with Supabase + Fake implementations; split out of `RecurringDepositRepository`.
  - [x] **Step 4 (State)**: `rdLedgerFactsProvider`/`rdLedgerProjectionProvider(rdId)`, `RDLedgerController` with busy state + `Result` handling, hub rows from summaries, split hub notifiers (`select`), `prepareLogPayment` from projection.
  - [x] **Step 5 (Presentation)**: Widgets consume projection + `displayStatusAt`; `usePaymentDraft` hook; controller-owned PO actions with undo; batch bar total; selection union semantics.
  - [x] **Step 6 (Cleanup)**: Delete `RDLedgerService` hydrate/diff/sparse APIs, `rd_payment_allocations`, dead month-query repository methods, legacy tests; shrink Fake repo.
  - [x] **Step 7 (Docs)**: Update `progress.md`, `docs/setup_guide.md`, session log.
- [x] **Phase 7: Sequential Ledger (ground-truth rules from `rd_ledger_usecases_agreed.md`)** — both ledgers sequential, one due amount per month, agent-absorbed fees:
  - [x] **Step 1 (Schema)**: `20261028000000_sequential_rd_ledger.sql` (now collapsed into `20261110000000_rd_ledger.sql`) — `rd_po_deposits` as count-on-date events (legacy rows collapsed), `rd_fee_waivers` → `rd_fee_absorptions(amount)`, split columns dropped from `rd_transactions`, `collection_id`/`batch_id` hooks, `opening_receivable`, `save_recurring_deposit` updated; seed + RLS test updated and verified on the local stack.
  - [x] **Step 2 (Dart switchover)**: v2 domain (`RDLedgerProjector` single due amount, customer-vs-PO fee, `RDPoReadiness`, `quoteNextDeposit`), repositories, controllers (`depositNextToPo`, `undoLatestPoDeposit`, `absorbFee`), widgets (passbook view, "Deposit next N", simplified payment sheet, cash/digital float), tests.
  - [x] **Step 3 (Docs)**: progress, setup guide, session log.
- [x] **Phase 8: Ledger UI improvements (interview + review, `docs/rd_ledger_ui_improvement_plan.md`)**:
  - [x] Tier A — money-visible correctness: accurate PO quotes (incl. fee) for batch deposits, from-pocket via the deposit sheet, one `absorbableFee` rule, Collect only on next due, batch `batch_id` + undo, no ellipsised money, ≥44dp primary buttons.
  - [x] PO visit planner (`RDPoVisitPlanner` + `rd_po_visit_sheet.dart`): per-account counts/₹/fee on a chosen date, cash vs UPI, >₹20k cash lot grouping, front-from-pocket per line, one Undo visit.
  - [x] Hub row re-rank (name first, `owes ₹X` primary, footer Collect/Deposit) and 2×2 header (To collect / In hand / Receivable / Arrears) as filters; toggle to app bar; distinct status colours.
  - [x] Vocabulary, accessibility (Semantics, tooltips, tap targets), passbook/inspector layout, purity, i18n prune.
  - [ ] Deferred by decision: household lump-sum split (`collection_id` ready), one-tap collect without sheet, Today dashboard, arrears screen, receipt screen.

## ⚡ Supabase Query Optimizations (Prioritized)
- [x] **P1: Server-Side Joins for Deposit Customer Names**: Modify `one_time_deposit_details_view` and `recurring_deposit_details_view` views to join with the `customers` table and return `customer_name`. Add `@JsonKey(includeFromJson: true, includeToJson: false) String? customerName` to deposit models to eliminate client-side cross-fetching/map loops.
- [ ] **P1.1 (On Hold / Deferred): Migrate to Two Channels CQRS Pattern**: Refactor the data & domain models to use separate, direct channels for reads vs writes, eliminating **Domain Pollution** and avoid mapping overhead (never decoupling/recombining views).
  - *Architectural Design:*
    - **Read Channel (Direct & Pragmatic)**: Database View (`one_time_deposit_details_view`) maps 1-to-1 to a read-only Presentation DTO (`OneTimeDepositWithCustomer`). The repository queries the view and outputs the DTO straight to the UI. The core write domain entity is never touched during reads.
    - **Write Channel (Pure & Controlled)**: UI Form maps to a pure domain model (`OneTimeDeposit` — stripped of `customerName`) to enforce domain calculations and logic validation (`OneTimeDeposit.create(...)`). The repository sends this pure model to the database write RPC (`save_one_time_deposit`).
  - *Benefits to achieve:*
    - **No Mapping Trap**: Eliminates complex intermediate mapping where fields are split and recombined.
    - **Strict Boundaries**: Core entities remain 100% focused on business logic/writes. Read-only DTOs represent exact screens.
    - **Performance & Safety**: No fallback checks, clean and fast JSON parsing directly from database views, and zero state desynchronization.
- [x] **P2: Filter Real-Time CDC Streams by Agent ID**: Update repositories to filter change streams using `.stream(...).eq('agent_id', _userId)` instead of listening to all database-wide table changes.
- [x] **P2.1: Lightweight Base Table Streaming for Customer List**: Stream physical `customers` table directly in `watchCustomers()` without `.asyncMap` view queries, eliminating 749 lateral joins on every CDC mutation. Lazy-load single full view details in `CustomerDetailScreen` and `CustomerFormScreen` via `customerByIdProvider(customerId)`.
- [x] **P2.2: Strip N+1 Customer Stream Watchers from Deposit Cards & Form Screens**: Remove `ref.watch(customerByIdProvider)` from `OneTimeDepositCard` and `RecurringDepositCard`, resolving titles directly from pre-joined `deposit.customerName`. Bypass list controller streams in `OneTimeDepositFormScreen` and `RecurringDepositFormScreen` on deposit creation.
- [x] **P2.3: Single Deposit Detail Providers & Watchers (Phase 2)**: Added `watchOneTimeDepositById` and `watchRecurringDepositById` across Supabase, Firestore, and Fake repositories. Added `oneTimeDepositByIdProvider` and `recurringDepositByIdProvider` family providers. Refactored `OneTimeDepositDetailScreen`, `RecurringDepositDetailScreen`, and deposit form screens (in edit mode) to use `AsyncSingleEntityBuilder`, decoupling single deposit detail and edit screens from entire list controller streams.
- [x] **P2.4: Defer Nominees from Deposit List Queries (Lightweight List Views)**: Specified explicit column projections in `watchOneTimeDeposits()` and `watchRecurringDeposits()` in Supabase repositories to omit `nominees`. By omitting `nominees`, Postgres completely bypasses `public.get_account_nominees(d.id)` lateral function execution across all list rows, cutting list query overhead while single deposit detail queries retain full nominee data.
- [ ] **P2.5: Dedicated Database Views for Deposit Lists (`one_time_deposit_list_view` & `recurring_deposit_list_view`)**: Replace ad-hoc static `_listColumns` strings in Dart repositories with formal PostgreSQL database views. Define `one_time_deposit_list_view` and `recurring_deposit_list_view` in a migration with flat indexed joins omitting `nominees`, enabling repositories to cleanly query `.from('..._list_view').select()` without hardcoded column strings.
- [ ] **P3: Server-Side Searching, Filtering, and Sorting**: Offload sorting, filtering, and search matching to PostgREST/Supabase query builders instead of pulling entire tables into Dart in-memory lists.
- [x] **P4a: Multi-Page `.range()` Auto-Pagination (`>1,000`-Row Safe)**: Implemented `SupabasePaginatedQuery.fetchAllPages` (`.range()` 500-row pages) + debounced Realtime/local-mutation collection streams across all Supabase repositories so agent collections scale seamlessly past PostgREST's 1,000-row `max-rows` cap.
- [ ] **P4b (Optional >5k Scale): Lazy UI Virtualized Pagination**: Pair `.range()` cursor/offset paging with `infinite_scroll_pagination` if single-agent list sizes ever exceed ~5,000 records.
- [ ] **P5: Database Fuzzy Search Indexes**: Enable `pg_trgm` extension and create GIN trigram indexes on text search targets (e.g. `idx_customers_name_trgm` on `customers(name)`) to avoid CPU-intensive sequential table scans.
- [x] **P6: Upgrade Client UUID Generation to UUIDv7**: Migrated client-side `uuid` generation across Customers, OTDs, RDs, RD transactions, and PO deposits to time-ordered RFC 9562 v7 UUIDs (`const Uuid().v7()`) to prevent B-tree index page splits.

## 📦 Release & Publication (Play Store)
- [x] **Fix Firebase Hosting deploy in CI**: `release.yml` failed on v2.3.0+21 and v2.3.1+22 with `403 PERMISSION_DENIED` (`serviceusage.services.get` on `firebasehosting.googleapis.com`). Cause: `action-hosting-deploy` runs `firebase-tools@latest`, and a newer CLI added a Service Usage pre-check the CI service account lacked. Fixed by granting the SA **Service Usage Consumer** (Cloud Console IAM) and pinning `firebaseToolsVersion: 15.35.0`; rerun of 42806147007 deployed 2.3.1+22 to https://postfolio-app.web.app.
- [x] **Change Application ID**: Update `applicationId` in `android/app/build.gradle.kts` (e.g., to `dev.darshanas.postfolio`).
- [x] **Android Product Flavors (Staging & Prod)**: Configured `staging` (`.staging` package suffix, "Postfolio Staging") and `prod` ("Postfolio") flavors for side-by-side device installation and independent testing.
- [x] **Distinguishing Staging & Prod App Icons**: Configured flavor-specific app icons generated via `flutter_launcher_icons`. Staging icon features a prominent orange banner and "STAGING" badge to clearly distinguish from the production icon.
- [ ] **Native Splash Screen**: Implement using `flutter_native_splash`. (Skipped for initial internal testing)
- [x] **Production Keystore**: Generate release JKS and configure `key.properties`. (Placeholder `key.properties` created and `build.gradle` updated)
- [ ] **Firebase Production**: Configure production project, update `google-services.json`, and enable **App Check** (Security Hardening).
- [x] **Store Assets**: Prepare screenshots, feature graphic, and metadata. (Placeholder directory and checklist created)
- [x] **Privacy Policy**: Host and link the privacy policy. (Placeholder created)
- [x] **AAB Build**: Run `flutter build appbundle` for release. (v1.5.1+15 built and successfully deployed to Internal Testing)

## 🧮 Domain Math & Business Logic
- [x] **KVP Term DB Sync & Official Post Office Rate Schedule (`PostalRateService`)**: Implemented `PostalRateService` (`postalRateServiceProvider`) and `@freezed sealed class PostalSchemeTerms` mapping investment `startDate` across all schemes (`KVP`, `NSC`, `MIS`, `TD` 1/2/3/5Y, `RD`) to official Ministry of Finance / Department of Posts historical circulars (2000–Present). Deposit creation and projection calculation now only require `startDate` to auto-resolve official `interestRate`, `termYears`, `termMonths`, `maturityDate`, and `maturityAmount`, while keeping `Interest Rate (%)` and KVP `Term (Years / Months)` editable in the UI as an agent override for newly announced circulars or edge cases. Enforced the Contractual Snapshot pattern so `OneTimeDeposit` and `RecurringDeposit` persist the resolved/overridden `interestRate`, `termYears`, and `termMonths` to the DB on save and strictly trust the stored DB snapshot on read.
- [ ] **Commissions**: Auto-calculate Gross Commission, deduct 2% TDS, and derive Net Payout.
- [ ] **Penalties & Rebates**: Calculate RD Late Fees and Advance Deposit Rebates.
- [ ] **Premature Closure (RD)**: Prompt user for penalty interest rate and show the premature withdrawal amount.
- [ ] **Premature Closure (General)**: Implement early withdrawal calculation logic for all applicable schemes.
- [ ] **Data Integrity**: Implement `isDeleted` flag (Soft Deletes) to prevent orphaned records for Customers and Deposits.

## 📊 Dashboard & Analytics
- [x] **Core Dashboard**: Implemented dashboard with aggregated metrics, active/total breakdowns, and interactive `fl_chart` data visualizations.
- [x] **Financial Year Charting**: Switched the "Deposits Over Time" graph to map and display using the Indian Financial Year (e.g. "FY 23-24") starting in April.
- [x] **Chart Drill-Down**: Added month-level drill-down interaction to the Financial Year chart with a 'Back to Years' UI.
- [ ] *Reserved for future dashboard widgets and analytics (e.g. commission estimates, maturing soon lists).*

## 🎨 UI/UX Polish & Features
- [ ] **Design Inspiration**: Refer to [flutterpro.design](https://flutterpro.design) for small details and micro-interactions that build "taste" in Flutter.
- [ ] **Nominee UI Overhaul**:
  - [ ] Update to an input widget/slider that strictly enforces the 100% rule.
  - [ ] Organize SB account number and associated nomination into a single cohesive UI section.
  - [ ] Ensure the relationship of each nominee is clearly displayed.
- [x] **Preferences**: Persist sort/filter selections and `maturityWarningDays` across sessions.
- [ ] **Visual Enhancements**:
  - [x] Redesign leading visual elements in deposit list tiles and detail headers (replace generic circular icons): OTD cards and detail headers display scheme short name (`TD`, `MIS`, `NSC`, `KVP`) with smaller tenure sub-label (`1Y`–`5Y` for TD); RD cards and detail headers display serial number (`#<serialNo>`) with `RD` fallback.
  - [ ] Apply distinct color coding for deposit types.
  - [x] Enhance visual prominence of scheme type in detail views and forms (Migrated Dropdowns to Segmented Buttons).
  - [x] Form inputs correctly format currency strings and auto-display localized amount in words.
  - [ ] Add relative time display (`timeago`).
  - [x] Implement dark theme support.
- [ ] **Media**: Implement image capture and display for customer profiles.
- [x] **Routing UX**: Re-evaluate context-aware "back" navigation (e.g., Detail -> List vs Detail -> Home).
- [ ] **Predictive Back Gesture**: Add predictive back gestures. The last trial had issues between customer detail page to customer list page.
- [x] **Minor Fixes**: Remove duplicate display of RD interest rate; replace `FilledButton` with `AppButton` (if deemed necessary).

## ⚙️ Architecture, Tooling & Security
- [x] **Agent Customization**: Refactored guidelines into a modular rule system in `.agents/rules/` for improved agent compliance and platform-agnosticism.
- [x] **Modern Android & Gradle Ecosystem Migration**: Upgraded project to use modern Android tooling: Gradle 9.5.1, AGP 9.3.0, Kotlin 2.3.20, and modern Firebase plugins (google-services 4.5.0, firebase-perf 2.0.2, firebase-crashlytics 3.0.8). Fully migrated to **Built-in Kotlin** (`android.builtInKotlin=true`), eliminating KGP-related deprecation warnings, and enabled AGP 9.0+ resource value compatibility.
- [ ] **Linting**: Add `riverpod_lint` and `custom_lint` for static analysis.
- [x] **DDD Auth User decoupling & Ubiquitous Language Refactor**: Decoupled technical Auth context (`AuthUser`) from the business domain, renamed `_userId` and `userId` variables inside all customer and deposit repositories to ubiquitous `_agentId` and `agentId` terms to align with database schemas (`agent_id` / `agent_profiles`).
- [ ] **Firebase App Check**: Configure with Play Integrity/App Attest and local Debug Tokens.
- [ ] **Firebase Remote Config**: Integrate for dynamic rates, version enforcement, and feature flags.
- [ ] **Analytics & Tracing**: Add Firebase Analytics wrapper, `GoRouter` observer, and custom Performance traces.
- [ ] **Native Integration**: Integrate `share_plus` (reports), `flutter_native_splash` (splash screen), and Local App Lock (Biometrics/PIN).
- [ ] **Value Objects**: Explore migrating `termYears`/`termMonths` into a custom Domain-Driven Value Object.
- [ ] **Database Casing and Constraint Alignment**: Revisit database columns and serialization enums in a future phase to standardize all tables on Postgres snake_case enums paired with strict database-level `CHECK` constraints (currently using default camelCase to maintain parity with legacy enums).
- [x] **Unique Email Guardrails**: Enforced case-insensitive unique email index (`idx_agent_profiles_email_lower` on `lower(email)`) + case-insensitive `handle_new_user()` JIT relinking on `agent_profiles`, intercepting PostgreSQL `23505` violations in `SupabaseErrorMapper`.

## 📱 Future Epics
### Epic: Responsive Architecture
- [ ] Add `flutter_adaptive_scaffold`.
- [ ] Implement adaptive navigation (BottomNavigationBar vs NavigationRail).
- [ ] Create Master-Detail layouts for large screens.
- [ ] Conditionally render `BottomSheet` as `AlertDialog`/Side Panel on large screens.

### Epic: Firebase Elimination
- [x] Complete codebase cleanup of legacy Firebase data/auth/analytics dependencies (`firebase_auth`, `cloud_firestore`, `firebase_performance`, `firebase_analytics`), retaining only `firebase_core` + native `!kIsWeb` `firebase_crashlytics` and Firebase Hosting.
- [x] Remove legacy `Firebase*Repository` / `Firestore*Repository` classes and the `Env.useSupabase` toggle strategy.
- [x] Clean up redundant fallback `customerMap` logic in `one_time_deposits_controller.dart` and `recurring_deposits_controller.dart` once pre-joined database views + reactive customer name overlay are wired in Stage 3.

### Epic: Agent Profile
- [ ] Build `Agent` domain model and mapping logic to rich business profile.
- [ ] Build `AgentProfileRepository` and `AgentProfileController`.

---

## ✅ Completed Milestones

### Foundation & Architecture
- [x] Scaffold Feature-First directory structure, Freezed models, and Riverpod DI.
- [x] Configure Firebase as BaaS and setup GoRouter with `StatefulShellRoute`.
- [x] Configure Firebase Emulator support for local development.

### Core Features (CRUD)
- [x] **Customers**: Implemented Repository, Controllers, and full Form/Detail Screens.
- [x] **One-Time Deposits**: Built complete flow including Form/Detail screens and domain math projections.
- [x] **Recurring Deposits**: Built complete flow including Form/Detail screens and domain math projections.
- [x] **Auth**: Integrated Firebase Auth, Google Sign-In, and GoRouter refresh guards.

### Advanced Domain Logic & Data
- [x] Built pure `ProjectionCalculator` utility for Post Office scheme rules.
- [x] Created strictly typed `InvestmentProjection` state class.
- [x] Built Data Migration tool (`run_migration.dart`) to import legacy CSV data to Firestore.
- [x] Transitioned fetching from list-streams to single-document family providers for performance.

### UI/UX Overhaul (Material 3)
- [x] Migrated fully to dynamic Material 3 Theming (`dynamic_color`).
- [x] Replaced `StatefulWidget` with pure `HookConsumerWidget`s across all forms.
- [x] Extracted common UI components (`AppTextField`, `AppDropdownField`, `EntityListTile`).
- [x] Standardized layouts, paddings, icon libraries (`hugeicons`), and animations (`flutter_animate`, `skeletonizer`).
- [x] Centralized Slang localizations (`.i18n.yaml`).
- [x] Added persistent unified Search/Filter/Sort UI across all listing screens.

### Supabase Migration (Phases 1-4)
- [x] **CLI Init**: Initialized Supabase project using `supabase init`.
- [x] **Docker**: Started local Supabase emulators (`supabase start`).
- [x] **Schema**: Defined initial Postgres schema with RLS policies in `supabase/migrations/`.
- [x] **Dependency**: Added `supabase_flutter` and `envied` to `pubspec.yaml`.
- [x] **Env Config**: Set up type-safe environment management with `Env` class and `.env`.
- [x] **Web Fixes**: Added Passkeys Web SDK to `web/index.html`.
- [x] **Seed**: Created `supabase/seed.sql` for local testing.
- [x] **Pre-Joined Views (Reads)**: Implemented server-side Postgres Views to eliminate client-side N+1 queries.
- [x] **PL/pgSQL RPC Stored Procedures (Writes)**: Implemented atomic multi-table write operations in 1 network roundtrip.
- [x] **Realtime CDC Streams**: Streamed base tables with `REPLICA IDENTITY FULL` mapped via `asyncMap` for seamless real-time updates.
- [x] **High-Fidelity Migration Screen**: Built programmatic user provisioning and data migration module in `lib/run_supabase_migration.dart` with Admin API integration and visual progress/error console.
- [x] **VS Code Launch Targets**: Integrated emulator and production execution targets inside `.vscode/launch.json` for 1-click execution.
