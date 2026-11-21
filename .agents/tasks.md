# Project Tasks & Roadmap

*Note: Finished items from before the v2.4 work are in `.agents/historical_tasks_archive.md`, with the older raw task history. For a summary of early work see `.agents/historical_summary.md`; for the current state see `.agents/progress.md`.*

## 🔐 Admin Acting-As Mode (Full CRUD) — Merged into `main`
*Branch `feat/admin-acting-as` rebased onto `main` (`fe505d0`, post PR #21) and merged (2026-11-20). Log: `.agents/session_logs/2026-11-20_session_1.md`.*
- [x] **SQL Migration (`20261120000000_admin_acting_as.sql`) & Contract Tests**: Added `private.can_access_agent` / `private.resolve_acting_agent`, append-only `public.admin_audit_logs` (`start`, `end`, `rpc:*`, `ON UPDATE CASCADE`), `public.log_admin_acting_as_event`, `public.list_agents_for_admin`, backwards-compatible `p_agent_id UUID DEFAULT NULL` on all 6 write RPCs (with per-RPC admin audit logging and cross-agent PK-collision guard on `rd_transactions`), admin-matched `rd_*` write RLS policies, and CASE 19b/19d + CASE 22a–22f in `supabase/tests/rd_ledger_facts_rls.sql`.
- [x] **Admin Domain, Repository & Session Scoping**: Added `AgentProfile`, `ActingAsState`, `ActingAsAuditAction` (`start`/`end`), `AdminRepository` (`SupabaseAdminRepository` + `FakeAdminRepository`), `isAdminProvider` (with 1.2s transient-failure retry + pull-to-refresh invalidation), `adminAgentsListProvider`, `actingAsControllerProvider` (in-memory only, resets on sign-out/demo), `effectiveAgentIdProvider`, and `activeSessionKeyProvider` (`auth:<uid>:as:<target>`).
- [x] **Repositories**: Injected `effectiveAgentId` and `dispose()` (`ref.onDispose`) across all 4 `Supabase*Repository` classes; passed `p_agent_id` to all 6 write RPCs and `.eq('agent_id', _agentId)` to direct deletes.
- [x] **UI & Localization**: Mounted topology-invariant root-level `ActingAsBanner` (`errorContainer` warning bar + `Exit` to `/dashboard`) in `MaterialApp.router.builder`, `AdminAgentPickerSheet` (`AppAdaptiveSheet`, search, O(N) own-account hoist), admin trigger in `DashboardScreen` (mobile) & `MainShellScaffold` rail (desktop), and Slang `admin.*` strings. **Zero feature UI files modified** — full CRUD stays active by default (owner decision: exact 1:1 agent UX without scattered `isReadOnly` checks).
- [x] **Hosted Rollout & Live Prod Verification**: Backed up hosted DB (`full_backup_2026_11_20_pre_admin_acting_as_data.sql`), pushed `20261120000000_admin_acting_as.sql` to hosted prod (`supabase db push`), granted `'admin'` in prod `public.user_roles`, and verified acting-as on Pixel 11 against live prod (including throwaway `v2.4.0+23` and `v2.3.1+22` diagnostic checks for Shivanand's portfolio).
- [x] **Verification (rebased onto `fe505d0`)**: `dart format --output=none --set-exit-if-changed` clean, `dart analyze --fatal-infos` clean (0 issues), **501/501 fast tests pass**, coverage gate **80.6% total** (domain 83.9%, controllers 86.3%, data 71.3%, UI 79.9%); 22/22 SQL contracts, 15/15 integration tests, and `flutter build web --wasm` verified pre-rebase.

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
- [x] **A2 (Visit write path)**: Stop `depositBatchToPo` / `undoBatch` returning Failure after the facts are committed; read facts with `fetchRawFactsForRds` instead of per-RD streams; make a retried visit a no-op (unique client batch ID).
  - [x] Follow-up (done as B3): the deposit sheet created a new event id per attempt, so a retry after a lost response recorded twice. Correction to the earlier note: the collect sheet was never affected — `usePaymentDraft` already holds one id per sheet, so a retry used to hit a duplicate-key error and now succeeds as an upsert.
  - Decided (B2): the single busy flag stays and rejects rather than queues. Queueing would turn a double-tapped Undo into two undos; with each write now one read plus one request the window is short.
- [x] **A3 (Lock fails closed)**: `saveRecurringDeposit` must refuse a terms change when ledger facts cannot be read.
- [x] **A4 (Backup workflow)**: Pass `$SUPABASE_DB_SESSION_URL` to `pg_dump` in `backup.yml`.
  - [ ] Owner action: configure the backup secrets, trigger the workflow once by hand, and restore that archive into a throwaway project. Neither has been done.
- [x] **A5 (Default privileges)**: Revoke PUBLIC's default EXECUTE on functions globally and add a SQL contract that fails if any `public` function is executable by `anon`.
- [x] **A6 (Enum guard)**: Decide the SQL boundary (restore enum CHECKs and/or tolerant decoding); decode list rows individually and log the original error instead of discarding it.
  - Decision: enum CHECKs in SQL mirroring the Dart enums, plus per-row decoding that names the failing row and reports the cause. Lists remain all-or-nothing.
- [x] **A7 (Migration rehearsal)**: Apply `20261111000000_v2_4_storage_hardening.sql` to a copy of production data before `supabase db push`; define release ordering.
  - [x] Backed up hosted, ran `supabase db push`, tagged `v2.4.0+23` (2026-11-16; see `.agents/session_logs/2026-11-16_session_2.md`).
- [x] **A8 (Realtime staleness)**: Refetch on resubscribe, retry failed loads, and keep a queued refetch when the in-flight fetch throws.
  - [x] Follow-up (done as B4): every ledger write refetched the whole `rd_ledger_summary` list; Realtime rows are now applied to an in-memory map instead.

### Ledger-write group (approved 2026-11-12)
- [x] **B1 (Atomic customer delete)**: `public.delete_customer(p_id)` removes the customer and its savings account in one transaction; `SupabaseCustomerRepository.deleteCustomer` is one request.
- [x] **B2 (Atomic ledger change)**: one RPC writes ledger facts and their summaries together; every `RDLedgerController` write goes through it.
- [x] **B3 (Retry-safe single-account deposit)**: the deposit sheet keeps one event id per attempt so a retry after a lost response stores one event.
- [x] **B4 (Incremental summary stream)**: apply Realtime summary rows to an in-memory map instead of refetching every summary after each write.

### v2.4.0+23 release (2026-11-16)
- [x] Release-readiness audit, PR #18, README and release checklist brought up to date, SQL contract CASE 17 made independent of which agent profile sorts first.
- [x] Pin Flutter 3.47.2 in `ci.yml` and `release.yml`; make the Hub E2E test wait for its summary row.
- [x] Re-rehearse the migration on a current copy of hosted; bump to `2.4.0+23`; changelog.
- [x] Merge PR #18 with a merge commit (not squash) once CI is green.
- [x] Full hosted backup → `supabase db push` → tag `v2.4.0+23` (R8 Play Core rule added in PR #19 after the first tag run failed; tag moved to `99868b9`).
- [ ] Owner: smoke-test the released web build and the release APK on a device; testers update from 2.3.1.
- [ ] After release: move to Flutter 3.50 (import `GlobalCupertinoLocalizations` from `cupertino_ui`) and raise the pin; configure the backup workflow secrets, run it once and rehearse a restore. *(Supabase CLI pin in `ci.yml` done on `chore/dev-experience`.)*

## 🎨 Material 3 Expressive Redesign (Approved 2026-11-15 — Done on the branch, awaiting owner review)
*Branch `feat/m3-expressive-ui`. Started on `refactor/v2.4-stabilization`; rebased onto `main` on 2026-11-16, after PR #18 (v2.4.0+23) was merged. Research and log in `.agents/session_logs/2026-11-15_session_1.md`.*
- [x] **M0 (Package scouting)**: Compare official `material_ui` (1.11.0, 2026-11-09) with community M3 Expressive packages.
- [x] **Owner decision (2026-11-15)**: hybrid. `material_ui` 1.11.0 is the base; `material_3_expressive` 1.2.1 supplies the Expressive components the official package lacks, behind wrappers. The whole app moves to the Expressive look, not a few widgets.
- [x] **M1 (Dependencies)**: upgrade `material_ui` to 1.11.0, add `material_3_expressive` 1.2.1.
- [x] **M2 (Theme)**: Expressive shape, motion and type tokens (`AppShapes`, `AppMotion`, `AppTypography`); surface roles (`page` / `raised` / `inset`); component themes, with the official Expressive variant for `IconButton` / `ElevatedButton`; brand palette on the `vibrant` scheme variant.
- [x] **M3 (Expressive widget layer)**: `lib/core/widgets/expressive/` — `AppButton`, `AppButtonGroup`, `AppExtendedFab` / `AppFabMenu`, `AppLoadingIndicator` / `AppLinearProgress`, `AppRefreshIndicator`, `AppNavigationBar` / `AppNavigationRail` (community package), and `AppGroupTile`, `AppShapeAvatar` (official shapes). `.agents/rules/ui.md` amended; `test/core/expressive_import_boundary_test.dart` keeps `package:material_3_expressive` imports inside that folder. Further wrappers (floating toolbar) are added with the screen that needs them.
- [x] **M4 (Shell and shared layout)**: navigation bar/rail, app bars, grouped `EntityListTile`, `EntityListBody`, detail scaffold/header/sections, sort and filter sheets, dialogs, search, empty and error states.
- [x] **M5 (List screens)**: Customers, One-time deposits, Recurring deposits (Accounts), on the shared `EntityListBody` and `DepositListTile`.
- [x] **M6 (Detail screens)**: Customer, One-time deposit and Recurring deposit, including the passbook and transactions tabs.
- [x] **M7 (Forms)**: the three entity forms on `FormSection` groups, customer picker, nominee section, projection card.
- [x] **M8 (RD Monthly Hub and ledger sheets)**: hub header tiles, month switcher, toolbar, operation rows, floating batch bar; collect / edit, deposit and PO-visit sheets.
- [x] **M9 (Dashboard and login)**: metric tiles, scheme breakdown, chart card, projection grids, login.
- [x] **M10 (Sweep and verification)**: no plain `Card`, `ListTile`, `ExpansionTile`, `Divider`, Material button, `SegmentedButton`, FAB or progress indicator left outside the wrappers; one text-scale threshold (`AppDimensions.largeTextScale`). Analyzer, fast tests, coverage gate and `flutter build web --wasm` pass; see the session log for what was not run.
- [x] **M11 (Sort and filter sheets, follow-up)**: the filter sheet's options are a multi-select `AppButtonGroup` instead of stock chips; both sheets open through `AppAdaptiveSheet` (dialog on wide windows, full-height sheet on a phone); list rows keep the name whole above 1.3x text. `test/core/sort_filter_sheet_test.dart` covers both sheets, which had no test.
- [x] **M12 (Last stock chips, follow-up)**: the dashboard chart's scheme selector is a button group and "Include RDs" a toggle; the collect sheet's quick amounts are toggle buttons; "Split evenly" is a tonal button. `AppButton.toggle` is new. No chip is left in `lib`. The chart's value axis keeps its unit at large text. `test/features/choice_controls_test.dart` covers all of it; none had a test.
- [x] **M13 (Design critique pass, 2026-11-16)**: the layout-only items of the design critique, one commit each. Log: `.agents/session_logs/2026-11-16_session_1.md`.
  - [x] **Monthly Hub density**: two-line header tiles, no group header for a customer with one account, one figure per row with the action on the status line.
  - [x] **Red means overdue**: Collect is always the brand colour and Deposit tonal; "from pocket" on the sheets takes the fronted colour.
  - [x] **Labelled view switch**: Accounts / Monthly Hub are two labelled segments in the app bar's title slot instead of two icons.
  - [x] **Compact detail header**: a 64dp avatar beside the name instead of a centred hero; a recurring deposit's tabs start above the middle of a phone.
  - [x] **List rows**: WhatsApp in the row's menu, a status badge only when not Active, a search hint that is never cut, and account numbers as titles on a customer's deposits.
  - [x] **Forms**: one Confirm button under the fields, above the keyboard; labels above the field above 1.3x text; label and icon on the first row of a multi-row field.
  - [x] **Shapes**: an avatar's shape names a scheme only; people and payments are circles, Hub rows take the recurring scheme's shape.
  - [x] **Status action**: closing or reopening a deposit is a labelled menu entry on its screen, not a bare seal icon in the app bar.
  - [x] **Receipts**: the Transactions tab groups receipts by year instead of giving each one a month header; the allocation pills are neutral.
  - [x] **String hygiene**: the unsaved-changes dialog reads from Slang; the passbook's Post Office line says "1 month".
  - [x] **Deposit wording**: the menu says "Close deposit"; the one-time deposit header says when it matures.
  - [x] **Sheet titles**: the collect and deposit sheets name the customer in the title and the account on a line under it.
  - [x] **Customer shapes**: a customer's avatar takes a shape from their name again, from shapes no scheme uses; shapes are decoration, not a code.
- [x] **M14 (Spacing pass, 2026-11-17)**: paddings, margins and gaps checked on every screen, at 360dp and on a 412dp phone with system bars. Log: `.agents/session_logs/2026-11-17_session_1.md`.
  - [x] **Monthly Hub**: the status stripe follows the row's corners, the status pill sits at one height with or without a button, 12dp between the blocks, tile text on the rows' edge, toggles that do not touch, a search hint that is not cut.
  - [x] **Dashboard**: scheme pills share the width or leave half of the next one showing, the chart's controls are one step apart with less of a hole above the bars, the tall tile is inset the same on every side.
  - [x] **Shared layout**: app bar actions end on the content's edge, the copy button and the chevron of a detail row share an axis, customer form fields are 16dp apart like the deposit forms', one gap after a detail screen's figures.
- [x] **M15 (Motion, page transitions and predictive back, 2026-11-17)**: what the packages already offer, switched on; nothing built by hand. Log: part 2 of `.agents/session_logs/2026-11-17_session_1.md`.
  - [x] **Predictive back**: the manifest opts in, so Android 13 to 15 send the gesture too (Android 16 already did); tests drive the swipe through the router: detail to list, a cancelled swipe, a form with unsaved input, an open sheet, the tab roots.
  - [x] **Page transitions**: every platform has one. iOS gets the Cupertino transition and with it the swipe back from the edge; Windows, Linux and Fuchsia get the shared axis macOS had (they fell back to the Android 10 zoom).
  - [x] **Menus**: the five `MenuAnchor` menus open and close with the official Material 3 animation (`animated: true`); a test keeps new ones on it.
  - [x] **Sheets over the navigation bar** (found while testing back): a sheet opened from a tab's own screen sat above the navigation bar, which stayed bright and tappable. Sheets now open on the root navigator and cover it.
- [x] **M16 (More of the community package, 2026-11-17)**: the Expressive components the owner asked for, each behind an `App*` wrapper and checked at 360dp, 2x text, 48dp targets and with a screen reader's tree. Log: part 3 of `.agents/session_logs/2026-11-17_session_1.md`.
  - [x] **Dependencies**: `go_router` 18.1.4 (navigation bar back in the screen reader's tree, system back after a tab switch) and `material_3_expressive` 1.2.2 (menus inside a nested navigator anchor to their trigger).
  - [x] **Menus**: the five menus are `AppMenu` on the community menu. Back closes an open menu (it used to leave the app from a tab's own screen). The wrapper widens the menu to its longest label; the community one is 224dp from an icon button and cuts the rest.
  - [x] **Refresh on detail screens**: the customer and both deposit detail screens can be pulled down to reload (`EntityDetailScaffold.onRefresh`), like the lists, the dashboard and the Hub.
  - [x] **Dialogs**: the confirm and error dialogs are the community dialog behind `AppDialog` (spring entrance, actions stack at large text). All of them already went through `AppDialogs`.
  - [x] **Status bar under the demo banner** (found on the emulator): after the new dialog closed, the clock stayed white on the light page. The banner now asks for its theme's status bar icons.
- [x] **M17 (Chips and parts that travel, 2026-11-18)**: the collect sheet's quick amounts are chips again, and a customer's avatar, name and phone travel from the row to the customer's screen. Log: `.agents/session_logs/2026-11-18_session_1.md`.
  - [x] **Quick amounts as chips**: the collect sheet's quick amounts are the official `ChoiceChip` (toggle buttons since M12). A chosen chip has the colours of a selected segment and no tick, so choosing one moves nothing; a label shrinks instead of being cut.
  - [x] **Live page transitions**: on Android both screens are drawn live while the transition runs (`allowSnapshotting: false` on the theme's builder). The default animates a picture of each screen taken on its first frame, so a detail screen's content, which fades in, stayed invisible until the transition had ended. The cost on a slow phone has not been measured.
  - [x] **Avatar, name and phone travel to the customer's screen**: from the customer's row to the head of the customer's screen, and back on the back button (`EntityHero`, the framework's `Hero`; the route stays `go_router`'s). The head is drawn from the list's record at once (`AsyncSingleEntityBuilder.seed`) and the rest is a placeholder until the full record arrives. The email line and the actions wait for the parts to land (`EntityHeroFollower`). Customers list only; the other lists wait for the owner's look.
  - [x] **Avatar and account number travel to a deposit's screen**: from the one-time and the recurring list, and from a deposit's row on its customer's screen. A tag names the row as well as the entity (`EntityHero.tagFrom(origin, id)`; the row hands its origin to the route as `$extra`): with the id alone, a tab out of view sent its row of a deposit to the customer's screen. A screen that no row opened has no tag, so nothing travels to it and nothing waits. Not from the Hub (a row's avatar is the month's installment, `#16`; the head's is the account's serial, `#1`) and not from the customer link on a deposit's screen.
  - [x] **Sections wait for the travelling parts**: `EntityDetailScaffold` holds its sections back with the rest of the head (`EntityHeroFollower`) until the parts have landed. From a row low on the screen (a customer's deposit rows) the parts crossed the sections while they faded in. The owner chose this over the crossing after seeing both as films; the cost is about 300 ms of a nearly empty page.
  - [x] **Text changes style on its way, and the amount travels**: a line of text goes from the row's size, weight and colour to the screen's while it travels (the account number used to reach a list's row as the bold title and snap to the row's style). A deposit's amount travels to the first figure of its screen. A deposit's screen has no placeholder any more: its list record lacks only the nominees, and a section rebuilt mid-flight would end the amount's trip.
  - [x] **A deposit's screen is headed like its row**: the customer's name, then the account number, then the scheme (owner, 2026-11-18). Name and number both travel from a list's row and keep their order; before, the number became the title and the name disappeared. A recurring deposit's link to the customer reads "Customer Details". The maturity date and the status badge do not travel, by the owner's decision: a transition reads when few things move.
  - [x] **A travelling avatar changes form**: a written avatar (`EntityAvatar`: an initial, a scheme over its term, a serial) has letters that are larger for its size at the head of a screen than in a row. It travelled as the head's avatar scaled down, so `#4` or `TD` reached a row large and snapped to the row's size (seen by the owner in the film). The avatar in flight is now the same widget part of the way between its two forms.
  - [x] **The parts travel when a back swipe is let go** (owner, 2026-11-18): Android's predictive preview stays (the screen shrinks whole under the finger) and at the release the parts travel to the row from where the shrunken screen had them. `EntityHeroBackSwipe`, an observer on the root navigator, asks the hero controller for the flights at that moment; `EntityHero` lets the framework's switch on only while a swipe is in progress. About 45 lines on public framework classes, leaning on the order in which the framework handles a released swipe; the tests hold it to that. On iOS parts sit the swipe out.
- [x] **M18 (More of Expressive, without the chaos, 2026-11-18)**: after a review against the Material 3 Expressive guidance the owner approved a set of elements and motion, each with a job of its own. Log: part 7 of `.agents/session_logs/2026-11-18_session_1.md`. Every package widget has to pass 2.0x text, 360dp and the screen reader's tree before it is adopted.
  - [x] **Haptics**: a light tap when a saved action is confirmed (`AppFeedback.showSuccess`), and the platform's long-press feedback when a long press starts a selection on the Hub.
  - [x] **Figures that count**: the Hub's four tiles count to their new value after a collect or a deposit (`AnimatedFigure`); another month's figure is shown at once.
  - [x] **Extended FAB that shrinks to its icon on scroll**, on the three lists (`AppExtendedFabScrollArea`, `useAppExtendedFabController`). A changed search or filter brings the label back. The wrapper also gives a screen reader the whole label once; the community widget said its first word, twice.
  - [x] **Selection flip**: in selection mode a Hub row's avatar turns over into an empty mark, and into a tick when the row is selected (`AppSelectionFlip`). A screen reader still gets a named checkbox that can be acted on.
  - [x] **Month's progress** on the Hub: accounts whose installment for the month is settled, of the accounts due, as a bar under the month. The **flat** track: the package's wavy one never stops moving and cannot be told to, which keeps the screen repainting and stops tests that wait for it to settle. When the last account is settled the bar gives way to the **"month settled" statement**, with a motion only if that happens on screen. A settled past month and a month with no account say nothing.
  - [x] **Sign-in shape**: the mark opens from a circle into its burst once, after the content has faded in (`AppShapeAvatar.opensFrom`; the official shape border blends two shapes itself). The screen comes to rest.
  - [x] **Navigation badge**: accounts in arrears on the Recurring destination, bar and rail, from the one-row-per-account summary cache. An account with no summary yet is not counted until the Hub has filled the cache.
  - **Not built, with the reason** (2026-11-19):
    - *Month picker*: the package has none. Its `M3EMonthPicker` is the pager of day grids inside its date picker.
    - *Package date picker*: rendered beside the official one (`shots/m18_date_picker.png` in the agent's artifacts). It looks the same but for a filled OK, overflows by 28px at 2.0x text, and names a day to a screen reader by its number alone, with no weekday, month or selected state. A wrapper cannot reach the day cells. The official picker stays, for the Hub's month too.
    - *Package expandable item*: it is a mode of the package's list (`M3EList`), which was rendered and held on 2026-11-17, not a widget of its own. The passbook's accordion stays.
    - *A Hub row that moves*: **dropped by the owner** (2026-11-19). Grouped by customer (the default) a row keeps its place after a collect; only the ungrouped list reorders. The framework has no list that animates a move, so it would be motion code of our own or a new package, with tiles whose corners depend on their place.
  - Already in the app, proposed by mistake: Undo after Collect (the collect sheet's snackbar), the loading indicator in a button (`AppButton.isLoading`), chart bars that grow when a filter changes.
  - **Button groups stay** (owner, 2026-11-19, after seeing the comparison): no tabs for views (plainer than the pills; the package's tabs overflow at 2.0x text), no switch for the Hub's grouping (a full row for what is an icon), no filter chips for the Hub's date ranges (they save a line at 2.0x, but the dashboard chart would keep its group, since chips wrap there at 360dp, and one kind of choice would have two looks). The connected button group is itself one of Expressive's new components.
  - Not forced, by the owner's word: a slider for amounts, a carousel, swipe actions on rows.
  - **Icon buttons stay the official ones** (owner, 2026-11-19, after seeing them rendered): the package's (`M3EIconButton`) gives two new outlines and a springier toggle, and needs a wrapper because a screen reader gets its name and its tap action on two different nodes. The package's card (`M3ECard`) has not been rendered.
  - **Postponed by the owner** (2026-11-19): a month card at the top of the dashboard (one display-size figure for what the month asks next, the settled bar, a button into the Hub). Rendered and liked by the agent; the sample is described in `.agents/session_logs/2026-11-19_session_1.md`. Open before it can be built: which figure leads, the colour, the wording, where the button goes, and why the dashboard's figure did not match the Hub's in the render.

### Left for the owner after the redesign
- [ ] **Look at it on a device**: nothing was run on a phone or in a browser. Everything was checked in widget tests and rendered screenshots (light, dark, 2.0x text, desktop width). On 2026-11-17 the motion work alone was run on an Android 17 emulator in demo mode (customers list, a customer's screen, the customer form, the sort sheet, a row's menu).
- [ ] **Web icon font (decision)**: `flutter build web --wasm` now ships 1,261,120 bytes of `MaterialIcons-Regular.otf` (469 KB gzipped) instead of 7,736. `material_3_expressive` declares every Material icon in `M3EIcons` without `@staticIconProvider`, and every component imports it. With that annotation added to a copy of the package the font is 9,624 bytes. Android is not affected (2,116 bytes). Choose: report it upstream and wait, or override the dependency with a patched copy.
- [x] **Flaky Hub integration test**: fixed on `main` by `1467dc5` (the test waits for the summary row instead of sleeping 500 ms). The integration suite passes on this branch after the rebase.
- [ ] **Palette**: the brand scheme now uses `DynamicSchemeVariant.vibrant` (`lib/core/theme/app_theme.dart`). Keep it, or go back to the default variant in that one line.
- [x] **Strings**: "1 months" on the passbook, the hard-coded unsaved-changes dialog and the field labels cut at 2.0x text are fixed.
- [ ] **Hub at 2.0x text**: the four header tiles take a line each, so the first row starts below the fold on an 800dp screen. The alternative is a 2×2 grid with smaller figures.
- [x] **Rebuild `chore/dev-experience`** on `main` (`d097a9e`, after PR #20 merged): done on 2026-11-19 (`.agents/session_logs/2026-11-19_session_2.md`).
- [ ] **Critique items still open** (details in `.agents/session_logs/2026-11-16_session_1.md`). Adding Slang keys needs no discussion, so the string ones are plain work:
  - Deferred by the owner: responsive UI, desktop included, will be its own branch. (The desktop test in `test/ui/accessibility_and_layout_invariants_test.dart` asserts a full-width search bar and flush-right row menus.)
  - To do, with new strings: labelled fee and fronting controls on the visit sheet; what the "6" in "5 / 6" on the dashboard is; a "Plan visit" button in place of the "In hand" tile's second job; the monthly payout as the headline of a Monthly Income Scheme deposit.
  - To do, with a hook change: grouping the amount typed on the collect sheet (the payment hook parses the field's text).
  - Fields without an outline at rest: needs the filled-field layout with the label inside, which changes every field's height.
  - Hub toolbar: the group and select toggles inside the search pill. The select toggle is the only visible way into selection, and grouping has no other place to go.
  - Shell: theme and sign-out into one account menu; the "+" on a customer's screen as add buttons on the deposit sections.
  - Palette: less chroma in the neutrals (one line in the theme; look at it on a device first).
  - Product: the Hub as its own destination; a dashboard that says what to do; masking Aadhaar.
- [ ] **Motion that needs our own code** (asked 2026-11-17; the owner wants it from packages only, so none is built; details in part 2, section 5 of `.agents/session_logs/2026-11-17_session_1.md`):
  - A transition between the four destinations (fade through). Needs a container for `go_router`'s `navigatorContainerBuilder` that keeps every tab alive, about 30 to 50 lines.
  - Predictive back and a spring on sheets. Means moving every sheet to the community `M3EBottomSheet` and passing each sheet's unsaved-input guard to it.
  - Container transform from a row to its screen. Not built. The package versions push routes outside `go_router`, and a page transition of our own was tried on 2026-11-18 and dropped (it threw on a back swipe, and it was all our own code). The owner chose the framework's `Hero` on the parts a row and its screen share instead (M17). Branch `spike/hero-morph`, the whole-screen morph of 2026-11-17, is superseded and can be deleted.
- [ ] **Parts that travel: look at them on a device** (M17). Built for the customers list, the two deposit lists and a customer's deposit rows. The owner has seen films drawn by the test binding; the profile build is on the owner's Pixel 11 since 2026-11-18, and the customers list ran once on the emulator.
  - To judge there: the flight when a back swipe is let go (built on 2026-11-18, run only in the test binding); on the way back the parts pass over the rows above their own; at 2.0x text a phone number changes between two lines and one; whether live page transitions cost frames on a slow phone.
  - Left out, with the reason in part 2 of `.agents/session_logs/2026-11-18_session_1.md`: the Hub's rows and the customer link on a deposit's screen. Neither shows what the head shows.
  - Asked by the owner, not built: the row's phone icon turning into the Call button. It needs a flight builder of our own that blends the two widgets.
- [ ] **Try on a phone** (motion pass): a back swipe from a detail screen, from a form with something typed, from a tab's own screen, and with a sheet open, on Android 13, 14 or 15 if one is at hand, since only those depend on the new manifest flag; the swipe back from the left edge on an iPhone.
- [x] **Row menu at the screen's edge**: the `AppMenu` keeps at least 8dp from the window; about 12dp on the 448dp emulator.
- [ ] **Community widgets held back (owner decision, 2026-11-17)**: search bar, chips, split button, app bar, toolbar, lists and bottom sheet were rendered and not adopted; the reasons are in part 3, section 3 of `.agents/session_logs/2026-11-17_session_1.md`. They fail at 2.0x text or in the screen reader's tree, or drop an unsaved-input guard. To adopt them the owner has to accept that, or wait for the package.
  - Added on 2026-11-19 (M18): the package's date picker and its expandable item, for the reasons under M18.
  - Where the owner wanted them: chips for the collect sheet's quick amounts (done with the official chip, M17), a split button for Deposit on the passbook strip, the toolbar for the Hub's batch bar.
  - Owner, 2026-11-18: no split button of our own. It comes from the package or not at all.
- [ ] **`material_ui` Expressive coverage**: when the official package ships an Expressive button group, FAB menu, navigation bar or loading indicator, move that `App*` wrapper onto it and drop the community widget.

## 🧰 Development experience (2026-11-16, rebased on `main` 2026-11-19 — done on branch, awaiting owner review)
*Branch `chore/dev-experience`, rebased onto `main` (`d097a9e`, PR #20 merged). Logs in `.agents/session_logs/2026-11-16_session_3.md` and `.agents/session_logs/2026-11-19_session_2.md`.*
- [x] Format all 246 tracked hand-written Dart files; CI fails on an unformatted one.
- [x] Pin the Flutter version once (`.fvmrc`); pin Supabase CLI (`v2.117.0` on `supabase/setup-cli@v3`) in `ci.yml`; run fast tests in parallel in both `ci.yml` and `release.yml`; drop removed `--delete-conflicting-outputs`.
- [x] Launch entries that name their backend (including `Local: Android (staging app, profile)` for AOT animation checks); `adb reverse` for Android (USB or Wireless Debugging); `config/prod.json.example`; one-click pre-PR check task in `tasks.json`.
- [x] "Sign in as seeded agent" and compact `LocalBackendBanner` ("Local Supabase (seed data)") for builds on the local stack.
- [x] Seed data & Demo Mode parity: 21 customers, one situation each, dates relative to today in both `supabase/seed.sql` (checked by `test/supabase_seed_scenarios_test.dart`) and `FakeDataSource.forDate` via `demoDataSourceProvider` (checked across 8 boundary dates in `test/core/fake_data_source_scenarios_test.dart`).
- [x] README, setup guide, privacy policy, and PRD: backends, Android forwarding (USB or Wireless Debugging), profile mode, staging app beside production, and retired Firestore references cleaned up.
- [x] Archive `progress.md` and `tasks.md` history from before v2.4 (preserving post-v2.4 items like M15 Predictive Back); delete stale `rebuild/dev-experience` and `spike/hero-morph` branches.
- Decided by the owner: no Makefile, no `doctor` script, no git hooks. The staging app uses the local stack over ADB; no hosted staging project for now.
- [ ] See the two workflows pass on GitHub: `ci.yml` on the pull request, `release.yml` once by hand with the deploy option off before the next tag.
- [ ] Try on Pixel 11 from VS Code: `Local: Android (staging app)` and `Local: Android (staging app, profile)` entries, the seeded-agent button, `LocalBackendBanner`, and the staging app beside production.
- [ ] Try the iOS Simulator, macOS and `PRODUCTION:` entries; none was run.
- [ ] The Android emulator's storage is 94% full; the debug build does not install on it.

## 📜 Upcoming Milestone: India Post Policy & Domain Audit (`v2.5`)
- [ ] **1. Statutory Rulebook & Circular Reference Docs (`docs/india_post_schemes_policy.md`)**: Compile authoritative citations across `G.S.R. 916(E)`–`922(E)` (National Savings RD, TD, MIS, KVP, NSC Rules 2019 & subsequent Gazette amendments), DOP SB Orders, Finacle CBS / DOP Agent Portal behavior, and MPKBY / SAS agency rules.
- [ ] **2. RD Default-Fee & Discontinuation Verification (`G.S.R. 916(E)`)**: Verify ₹1 per ₹100 denomination default-fee calculation on ₹10-multiple installments (`₹250` RD -> exact `₹2.50` paise vs whole-rupee ceiling at Finacle CBS / DOP Agent Portal), maximum 4-default discontinuation threshold + 2-month revival window, and 6-month / 12-month advance deposit rebates.
- [ ] **3. Quarterly Rate Schedule & Maturity Formula Audit (`PostalRateService` & `ProjectionCalculator`)**: Cross-check all 2000–2026 Ministry of Finance DEA quarterly rate circulars across `RD`, `TD` (1/2/3/5Y), `MIS`, `NSC`, and `KVP`, Finacle CBS maturity rounding conventions (exact paise vs nearest rupee), and scheme denomination min/max/multiple invariants (`RD` min ₹100 + ₹10 multiples; `TD`/`MIS`/`KVP`/`NSC` min ₹1,000 + ₹100 multiples; `MIS` ₹9L single / ₹15L joint caps).
- [ ] **4. MPKBY (4%) & SAS (0.5%) Commission + Section 194H TDS Rules**: Verify current Section 194H TDS rate (`2%` post-Oct 2024 Finance Act amendment) and aggregate Financial Year exemption threshold (`₹20,000`/FY from FY 2025-26) plus SAS applicability per scheme before implementing commission tracking.

## 📅 Epic: RD Monthly Ledger & Transaction Tracking
- [x] **Phase 4.6: RD Ledger Architecture Redesign & Roadmap (Option 1+: Sparse Rollup + Allocation Lineage + In-Memory Hydration)**:
  - [ ] **Stage 5 (On Hold — RDL-9: First-Class PO Lot Builder & Advance Rebates)**: Model DOP Portal Schedules/Lots (`rd_po_batches` linked via `po_batch_id` already provisioned on `rd_installments`, ₹20,000 cash limit guardrail, 6M/12M India Post Advance Deposit Rebates, and 4% MPKBY Commission/TDS calculation).
- [x] **Phase 8: Ledger UI improvements (interview + review, `docs/rd_ledger_ui_improvement_plan.md`)**:
  - [ ] Deferred by decision: household lump-sum split (`collection_id` ready), one-tap collect without sheet, Today dashboard, arrears screen, receipt screen.

## ⚡ Supabase Query Optimizations (Prioritized)
- [ ] **P1.1 (On Hold / Deferred): Migrate to Two Channels CQRS Pattern**: Refactor the data & domain models to use separate, direct channels for reads vs writes, eliminating **Domain Pollution** and avoid mapping overhead (never decoupling/recombining views).
  - *Architectural Design:*
    - **Read Channel (Direct & Pragmatic)**: Database View (`one_time_deposit_details_view`) maps 1-to-1 to a read-only Presentation DTO (`OneTimeDepositWithCustomer`). The repository queries the view and outputs the DTO straight to the UI. The core write domain entity is never touched during reads.
    - **Write Channel (Pure & Controlled)**: UI Form maps to a pure domain model (`OneTimeDeposit` — stripped of `customerName`) to enforce domain calculations and logic validation (`OneTimeDeposit.create(...)`). The repository sends this pure model to the database write RPC (`save_one_time_deposit`).
  - *Benefits to achieve:*
    - **No Mapping Trap**: Eliminates complex intermediate mapping where fields are split and recombined.
    - **Strict Boundaries**: Core entities remain 100% focused on business logic/writes. Read-only DTOs represent exact screens.
    - **Performance & Safety**: No fallback checks, clean and fast JSON parsing directly from database views, and zero state desynchronization.
- [ ] **P2.5: Dedicated Database Views for Deposit Lists (`one_time_deposit_list_view` & `recurring_deposit_list_view`)**: Replace ad-hoc static `_listColumns` strings in Dart repositories with formal PostgreSQL database views. Define `one_time_deposit_list_view` and `recurring_deposit_list_view` in a migration with flat indexed joins omitting `nominees`, enabling repositories to cleanly query `.from('..._list_view').select()` without hardcoded column strings.
- [ ] **P3: Server-Side Searching, Filtering, and Sorting**: Offload sorting, filtering, and search matching to PostgREST/Supabase query builders instead of pulling entire tables into Dart in-memory lists.
- [ ] **P4b (Optional >5k Scale): Lazy UI Virtualized Pagination**: Pair `.range()` cursor/offset paging with `infinite_scroll_pagination` if single-agent list sizes ever exceed ~5,000 records.
- [ ] **P5: Database Fuzzy Search Indexes**: Enable `pg_trgm` extension and create GIN trigram indexes on text search targets (e.g. `idx_customers_name_trgm` on `customers(name)`) to avoid CPU-intensive sequential table scans.

## 📦 Release & Publication (Play Store)
- [x] **Play Store Build, CI & Migration Guide (`docs/play_store_setup.md`)**: Enabled `ndk.debugSymbolLevel = "SYMBOL_TABLE"` in `android/app/build.gradle.kts`, added `.aab` build + signed artifact upload + guarded `r0adkll/upload-google-play@v1` step to `.github/workflows/release.yml`, and documented the full Internal → Closed (12 testers / 14 days) → Production setup.
- [x] **Owner: Upload Keystore & GitHub Secrets**: Verified existing `upload-keystore.jks` matches Play Console, backed up to Bitwarden, and added `UPLOAD_KEYSTORE_BASE64` + `KEY_PROPERTIES` to GitHub Secrets.
- [x] **Owner: Play App Signing SHA-1/SHA-256, Internal Testers & CI Service Account**: Registered Play App Signing fingerprints in Firebase, added Internal Testing testers in Play Console, created `github-play-deployer` service account with Play Console permissions, and set `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret + `PLAY_STORE_RELEASE_STATUS=draft` variable.
- [ ] **Owner: Finish Play Console Dashboard Setup**: Host Privacy Policy URL (`web/privacy-policy.html` + email in `docs/legal/privacy_policy.md`), complete App Content declarations & Store Listing, then switch `PLAY_STORE_RELEASE_STATUS` from `draft` to `completed` once published.
- [ ] **Owner: Closed Testing → Production (12 testers / 14 days)**: Run a Closed Test (`alpha`) with 12+ testers continuously opted in for 14 days, then apply for Production access.
- [x] **Owner: Retire Firebase App Distribution**: Removed the universal APK build and Firebase App Distribution upload step from `.github/workflows/release.yml`; all Play Store releases now default to Closed Testing (`alpha`).
- [ ] **Native Splash Screen**: Implement using `flutter_native_splash`. (Skipped for initial internal testing)
- [ ] **Firebase Production**: Configure production project, update `google-services.json`, and enable **App Check** (Security Hardening).

## 🧮 Domain Math & Business Logic
- [ ] **Commissions**: Auto-calculate Gross Commission, deduct 2% TDS, and derive Net Payout.
- [ ] **Penalties & Rebates**: Calculate RD Late Fees and Advance Deposit Rebates.
- [ ] **Premature Closure (RD)**: Prompt user for penalty interest rate and show the premature withdrawal amount.
- [ ] **Premature Closure (General)**: Implement early withdrawal calculation logic for all applicable schemes.
- [ ] **Data Integrity**: Implement `isDeleted` flag (Soft Deletes) to prevent orphaned records for Customers and Deposits.

## 📊 Dashboard & Analytics
- [ ] *Reserved for future dashboard widgets and analytics (e.g. commission estimates, maturing soon lists).*

## 🎨 UI/UX Polish & Features
- [ ] **Design Inspiration**: Refer to [flutterpro.design](https://flutterpro.design) for small details and micro-interactions that build "taste" in Flutter.
- [ ] **Nominee UI Overhaul**:
  - [ ] Update to an input widget/slider that strictly enforces the 100% rule.
  - [ ] Organize SB account number and associated nomination into a single cohesive UI section.
  - [ ] Ensure the relationship of each nominee is clearly displayed.
- [ ] **Visual Enhancements**:
  - [x] Redesign leading visual elements in deposit list tiles and detail headers (replace generic circular icons): OTD cards and detail headers display scheme short name (`TD`, `MIS`, `NSC`, `KVP`) with smaller tenure sub-label (`1Y`–`5Y` for TD); RD cards and detail headers display serial number (`#<serialNo>`) with `RD` fallback.
  - [ ] Apply distinct color coding for deposit types.
  - [x] Enhance visual prominence of scheme type in detail views and forms (Migrated Dropdowns to Segmented Buttons).
  - [x] Form inputs correctly format currency strings and auto-display localized amount in words.
  - [ ] Add relative time display (`timeago`).
  - [x] Implement dark theme support.
- [ ] **Media**: Implement image capture and display for customer profiles.
- [x] **Predictive Back Gesture**: on since M15 (2026-11-17): the theme's builder plus the manifest opt-in. Customer detail to the list works on an Android 17 emulator, release and cancel. Not tried on a phone or on Android 13 to 15.

## ⚙️ Architecture, Tooling & Security
- [ ] **Linting**: Add `riverpod_lint` and `custom_lint` for static analysis.
- [ ] **Firebase App Check**: Configure with Play Integrity/App Attest and local Debug Tokens.
- [ ] **Firebase Remote Config**: Integrate for dynamic rates, version enforcement, and feature flags.
- [ ] **Analytics & Tracing**: Add Firebase Analytics wrapper, `GoRouter` observer, and custom Performance traces.
- [ ] **Native Integration**: Integrate `share_plus` (reports), `flutter_native_splash` (splash screen), and Local App Lock (Biometrics/PIN).
- [ ] **Value Objects**: Explore migrating `termYears`/`termMonths` into a custom Domain-Driven Value Object.
- [ ] **Database Casing and Constraint Alignment**: Revisit database columns and serialization enums in a future phase to standardize all tables on Postgres snake_case enums paired with strict database-level `CHECK` constraints (currently using default camelCase to maintain parity with legacy enums).

## 📱 Future Epics
### Epic: Responsive Architecture
- [ ] Add `flutter_adaptive_scaffold`.
- [ ] Implement adaptive navigation (BottomNavigationBar vs NavigationRail).
- [ ] Create Master-Detail layouts for large screens.
- [ ] Conditionally render `BottomSheet` as `AlertDialog`/Side Panel on large screens.

### Epic: Agent Profile
- [ ] Build `Agent` domain model and mapping logic to rich business profile.
- [ ] Build `AgentProfileRepository` and `AgentProfileController`.
