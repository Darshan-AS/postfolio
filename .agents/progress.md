# Project Progress

## Current State
**RD Ledger Feature - Robust Financial Guardrails & Validation Complete (Phase 4 Polish & Architecture Safeguards)**:
- **Form Screen Guard (`RecurringDepositFormScreen`)**: Implemented robust UI locking in `useRecurringDepositForm` and `_RecurringDepositForm` by checking for existing payment transactions (`hasTransactions`). When payments exist, financial terms are completely disabled/greyed out (`installmentAmount`, `startDate`, `term (years/months)`, `initialPaidInstallments`), keeping administrative fields like `accountNumber`, `serialNumber`, `nominees`, and `status` editable.
- **Helpful Alert Badge**: Added a visually prominent error-container themed notice banner at the top of the Investment Details section in the form screen: *"Financial terms cannot be modified after payments have been recorded."*
- **Domain Validation**: Created a pure, centralized validation rule `RecurringDeposit.validateUpdate` in the domain model to prevent any save or update operations from changing financial parameters if active payments have been recorded.
- **Backend RPC Safety**: Modified the database procedural function `save_recurring_deposit` inside PostgreSQL migration `20260903000000_rd_ledger_feature.sql` to explicitly assert that no updates can touch `installment_amount` and `start_date` if `rd_transactions` records are linked to the deposit, throwing a robust, human-friendly exception if violated.
- **Unified Clean Architecture Enforcement**: Integrated the validation flow consistently across presentation (form hooks, alert banner), application (controllers), domain models, and repositories (fake and Supabase) to guarantee comprehensive coverage against accidental edits or direct API manipulation.
- **Verified Stability**: Achieved 100% clean static analysis (`flutter analyze` returns 0 issues) and 100% passing test suite.

**RD Ledger Feature - Phase 4 Complete (Interactive Inline Collapsible Ledger UI, Onboarding Baseline, & Domain/Constraint Alignment)**:
- Designed and built standard Material 3 collapsible ledger segments in `RecurringDepositDetailScreen` for monthly schedules, raw transaction logs, and interactive chronological payment log sheets.
- Added support for onboarding baseline via `initialPaidInstallments`: payments before the specified threshold are automatically marked settled prior to onboarding.
- Standardized domain modeling with `validateInitialPaidInstallments` integrated directly with the central Slang localization system (`en.i18n.yaml` translation files).
- Decoupled `RDLedgerService` and `isNew` boolean flags from repositories; orchestrated ledger schedule generation cleanly in `RecurringDepositsController` to respect Clean Architecture boundaries.
- Standardized enums (`RDInstallmentStatus`, `RDPoStatus`, and `RDPaymentMode`) on default camelCase `@JsonEnum()` to maintain parity across the codebase, and removed database-level `CHECK` and `DEFAULT` constraints from the PostgreSQL migration to match, resolving any check constraint violations cleanly.
- Implemented full 3x2 state matrix handling agent pre-payments to the Post Office: enabled PO deposit selection for all unpaid PO installments, added purple `Advanced to PO` & `Advance Partially Repaid` badges with comprehensive breakdown indicators (`Customer owes: ₹X (Balance: ₹Y + Default Fee: ₹Z)`), and added summary KPI cards for `Pending at PO` and `Advanced (Receivable)`.
- Updated default/late fee calculation in `RDInstallment` and `RDLedgerService` to compute cumulative $1\% \times \text{months defaulted}$ dynamically in accordance with Post Office rules.
- Verified 100% clean static analysis (`flutter analyze` - 0 issues) and 100% passing tests (`flutter test`).

**RD Ledger Feature - Phase 1, 2 & 3 Complete (Relational Muscle, Pure Dart Domain Modeling, Repository Signatures, & Riverpod State Providers)**:
- Designed and built a high-performance relational database migration in `supabase/migrations/20260903000000_rd_ledger_feature.sql` implementing `rd_installments` monthly schedules and adding payment mode tracking to `rd_transactions`.
- Structured constraints to enforce data integrity: set up foreign keys with cascades, and standard indexes.
- Adopted a pure **"Brain & Muscle"** architecture: decoupled trigger-based business rules from the DB. Built lightweight, versatile database RPC functions (`save_recurring_deposit`, `record_rd_customer_payment_allocated`, `record_rd_po_payments`) supporting transaction logging and bulk schedule updates, ensuring calculations can be run client-side for immediate user previews while preserving atomic, single-roundtrip server writes.
- Defined Freezed domain models (`RDInstallment`, `RDTransaction`) as well as type-safe ledger enums (`RDInstallmentStatus`, `RDPoStatus`, `RDPaymentMode`) in Dart, cleanly compiling them via `build_runner`.
- Engineered a calendar-drift-safe chronological allocation service (`RDLedgerService`) in Dart (the "Brain") that handles 1% PO late-fee capping and calculation dynamically.
- Integrated the new `initialPaidInstallments` onboarding/backfill parameter into the parent `RecurringDeposit` domain model, updated `SupabaseRecurringDepositRepository` to generate initial ledger schedules automatically on creation/saves, resolved function overloading via `DROP FUNCTION` on schema reset, and verified that 100% of integration and unit tests pass cleanly.
- Fully implemented concrete ledger repository methods in `SupabaseRecurringDepositRepository` utilizing real-time CDC streams and Postgres RPC parameters (`record_rd_customer_payment_allocated`, `record_rd_po_payments`).
- Implemented robust in-memory ledger state and CDC-mocking stream providers in `FakeRecurringDepositRepository` for flawless offline Demo Mode functionality.
- Created `rdInstallmentsStreamProvider` and `rdTransactionsStreamProvider` to stream real-time ledger data reactively down to the UI.
- Built a unified `RDLedgerController` to handle side-effects such as logging customer payments and PO deposits, automatically computing payment allocations and triggering atomic DB writes.
- Verified local schema compilation with 100% success via local emulator reset (`npx supabase db reset`).

**DDD Auth User Decoupling & Ubiquitous Language Refactor Completed**:
- Refactored `AppUser` to `AuthUser` in the authentication domain context (`lib/features/auth/domain/auth_user.dart`) to strictly represent lightweight session identities. This aligns with Bounded Context design principles by preventing the core business `Agent` domain from being polluted with technical authentication details.
- Avoided name collisions with Supabase Flutter's exported `AuthUser` by utilizing `hide AuthUser` on the Supabase import inside `SupabaseAuthRepository`.
- Renamed all occurrences of technical `_userId` and `userId` inside all `CustomerRepository`, `OneTimeDepositRepository`, and `RecurringDepositRepository` implementations to ubiquitous, business-centric terms: `_agentId` and `agentId`. This strictly maps the persistence and presentation layers to real-world business entities (`agent_profiles` / `agent_id`).
- Regenerated all required boilerplate with code-generation and verified that 100% of static analysis checks (`flutter analyze`) and unit tests (`flutter test`) pass cleanly.

**P2 Optimization - Filter Real-Time CDC Streams by Agent ID Completed**:
- Updated `watchCustomers()` stream in `SupabaseCustomerRepository` to filter real-time CDC updates using `.eq('agent_id', _userId)`.
- Updated `watchOneTimeDeposits()` stream in `SupabaseOneTimeDepositRepository` to filter real-time CDC updates using `.eq('agent_id', _userId)`.
- Updated `watchRecurringDeposits()` stream in `SupabaseRecurringDepositRepository` to filter real-time CDC updates using `.eq('agent_id', _userId)`.
- This ensures only relevant real-time mutations are streamed to the client, drastically decreasing network egress, client-side message processing overhead, and memory load on shared tables.
- Passed 100% of static analysis checks (`flutter analyze`) and unit tests (`flutter test`).

**P1 Optimization - Server-Side Joins for Deposit Customer Names Completed**:
- Created database migration `supabase/migrations/20260902000000_p1_server_side_joins.sql` to join `customers` in `one_time_deposit_details_view` and `recurring_deposit_details_view`, returning pre-joined `customer_name`.
- Added `customerName` field to `BaseDeposit` interface, and `@JsonKey(includeFromJson: true, includeToJson: false) String? customerName` to Freezed models `OneTimeDeposit` and `RecurringDeposit` to read joining values but ignore them in client-side inserts/updates.
- Upgraded Riverpod list controllers `filteredOneTimeDeposits` and `filteredRecurringDeposits` with zero-overhead fallback mechanisms that fetch customer maps only when `customerName` is missing, allowing optimal Supabase performance while preserving full Firebase compatibility.
- Verified 100% clean compilation via `flutter analyze` and passing unit tests.

**Standalone Material/Cupertino Migration Complete**:
- Added `material_ui` (1.1.0) and `cupertino_ui` (1.0.1) as direct dependencies to decouple the app UI framework.
- Upgraded `dynamic_color` to `^2.1.0` to correctly align and resolve `ColorScheme` dynamic colors under `material_ui` across platforms.
- Migrated 54 codebase files to the new `material_ui` design widgets system using automated `dart fix --apply --code=migrate_design_widgets`.
- Cleaned up redundant/unused legacy imports (`package:flutter/material.dart` as `legacy`) inside `lib/main.dart`.
- Passed 100% of static analysis checks (`flutter analyze`) with 0 warnings/errors.
- Verified 100% pass on the entire unit test suite (`flutter test`, 4/4 passed).

**Major Dependency Upgrades & New Features Leveraged**:
- Upgraded direct dependencies to major releases: `go_router` (^18.0.0), `csv` (^8.0.0), `animations` (^3.0.0), `freezed` (^4.0.1).
- **Leveraged Android 14+ Predictive Back Gestures**: Configured `PredictiveBackPageTransitionsBuilder` on Android in `lib/core/theme/app_theme.dart` for native swipe-to-pop back navigation.
- **Leveraged Freezed 4 / Dart 3 Destructuring**: Updated `login_screen.dart` with `if (authState case AuthStateError(:final message))` pattern matching.
- **CSV 8.0 Engine Upgrade**: Updated `lib/run_migration.dart` to use `csv` 8.0's stream-ready `Csv(lineDelimiter: '\n').decode(rawData)`.
- Re-ran code generation (`dart run build_runner build --delete-conflicting-outputs`), generating 57 outputs.
- Verified zero analysis issues (`flutter analyze`) and all unit tests passing (`flutter test`, 4/4 passed).

**Flutter SDK Upgrade (v3.47.2) & Dependency Baseline Update**:
- Upgraded Flutter SDK to **3.47.2** (Dart 3.13.2, DevTools 2.60.0).
- Ran `flutter pub upgrade` updating 103 dependencies to latest compatible versions (`cloud_firestore` 6.9.0, `firebase_core` 4.14.0, `supabase_flutter` 2.17.2, `go_router` 17.5.0, `intl` 0.20.3, `slang` 4.19.0).
- Re-ran code generation (`dart run build_runner build --delete-conflicting-outputs`), updating 57 generated artifacts.
- Verified 100% clean static analysis (`flutter analyze`) and all tests passing (`flutter test`, 4/4 passed).

**Release Prepared (v2.0.0+17) & CI/CD Pipeline Updated**:
- Bumped app version to **v2.0.0+17** in `pubspec.yaml` and documented changes in `CHANGELOG.md`.
- Evaluated git commits since `v1.6.0+16` (Major release type due to Supabase migration, CQRS architecture, and Android build flavors).
- Updated GitHub Actions workflow (`.github/workflows/release.yml`) to inject repository secrets into `.env`, run `build_runner` for `env.g.dart`, and target `--flavor prod`.
- Verified pre-release validation: 100% clean static analysis (`flutter analyze`) and all tests passing (`flutter test`).

**Git Hygiene & Sensitive File Tracking Cleanup**:
- Updated `.gitignore` to explicitly ignore generated environment files (`lib/core/env/env.g.dart`) and include `.env.example` template tracking (`!.env.example`).
- Removed `lib/core/env/env.g.dart` from Git index tracking (`git rm --cached`).
- Audited git commit history for `lib/core/env/env.g.dart` (contained local emulator keys / dummy values).

**Android Product Flavors & Staging Launcher Icon Setup**:
- Configured Android Product Flavors in `android/app/build.gradle.kts`:
  - `staging`: Application ID suffix `.staging` (`dev.darshanas.postfolio.staging`), app name "Postfolio Staging".
  - `prod`: Base Application ID (`dev.darshanas.postfolio`), app name "Postfolio".
- Configured dynamic application label `@string/app_name` in `android/app/src/main/AndroidManifest.xml`.
- Configured distinguishing app launcher icons for `staging` vs `prod` using `flutter_launcher_icons`:
  - `staging`: Features a vibrant orange background banner and corner ribbon with clear "STAGING" and "STAGE" branding in `android/app/src/staging/res/mipmap-*/ic_launcher.png`.
  - `prod`: Uses clean base branding in `android/app/src/prod/res/mipmap-*/ic_launcher.png`.
- Configured dedicated VS Code launch targets in `.vscode/launch.json` for Staging and Production across physical devices and Android emulators.
- Set up system JDK to Java 21 (`/usr/lib/jvm/java-21-openjdk-amd64`) in `~/.zshrc` to resolve Gradle build compatibility with Java 25.
- Created and committed dedicated feature branch `feature/android-build-flavors`.
- Deployed production Firestore security rules (`firestore.rules`) to `postfolio-app` via Firebase CLI.

**Supabase Migration - Phase 4 Live Migration & Setup Complete**:
- **High-Fidelity Migration Screen**: Built a robust, admin-focused data migrator utility in `lib/run_supabase_migration.dart`.
  - Integrates direct administrative schema-level database migrations from Firebase Firestore to local/production Supabase.
  - Automatically provisions Supabase Auth users using the Service Role Admin client, maintaining verified states and linking them to `agent_profiles` with `legacy_firebase_uid`.
  - Performs multi-stage, transactional data mapping of nested collection schemas (Customers, SB accounts, OTDs, RDs, and Nominees) to normalized relational Postgres tables.
  - **Bulk Migration Optimizer**: Redesigned and optimized the migration run loop using a high-speed batching strategy. Rather than executing thousands of sequential individual HTTP insert requests inside nested loops (causing extensive N+1 network overhead), it accumulates entities into in-memory lists and performs bulk inserts chunked at 200 records in correct dependency order (Customers -> Account Identities -> Child Tables -> Nominees). This improves migration speeds for bulk files by 100x to 1000x while keeping UI rendering smooth by only printing chunking progress.
  - Supports full administrative safety controls, live step-by-step progress/error console reporting, and full database purge execution.
- **VS Code Integration**: Configured dedicated launch targets inside `.vscode/launch.json` for running the Supabase Migrator tool in both Emulator and Production configurations with 1-click execution.
- Verified 100% clean static analysis (`flutter analyze`) and successful testing (`flutter test` passes 4/4).

**Supabase Migration - Option 2 CQRS Architecture, Security Audit & Schema Normalization Implemented**:
- Standardized local development origin configurations to `localhost` (`http://localhost:3000`) instead of `127.0.0.1` across `supabase/config.toml` and `SupabaseAuthRepository` to resolve white-screen connection crashes in Chrome debug mode.
- Refactored and optimized Supabase migrations (`20260626000000` through `20260802000002`):
  - Removed redundant `customer_id` from deposit tables, standardizing on `account_identities` as the single FK source of truth.
  - Added FK & RLS query performance indexes across `user_roles`, `customers`, `account_identities`, `nominees`, and `rd_transactions`.
  - Added tenant isolation ownership checks (`agent_id = v_agent_id`) and `SET search_path = public` to all `SECURITY DEFINER` RPCs (`save_customer_with_sb_account`, `save_one_time_deposit`, `save_recurring_deposit`).
  - Refactored `20260626000000_initial_schema.sql` using clean code patterns: consolidated child table RLS policies using `FOR ALL`, and automated `updated_at` trigger attachment and RLS enabling loops via PL/pgSQL.
  - Extracted DRY helper functions for SQL migration operations (`assert_authenticated`, `assert_customer_owner`, `assert_account_owner`, `get_account_nominees`, `replace_account_nominees`) to simplify views and RPC procedures while keeping business logic in the app layer.
  - Implemented unified, polymorphic helper `upsert_account_identity(...)` to encapsulate parent identity resolution across all customer savings accounts, OTDs, and RDs, DRYing up database orchestration.
  - Added RLS DELETE policy on `agent_profiles` (`Users can delete own profile`) allowing authenticated users and test teardown hooks to purge test profiles and cascaded records.
  - Added automatic test teardown hooks (`addTearDown`) across Supabase repository integration test files to clean up test agent profiles and cascaded records, leaving the database clean after test runs.
  - Revoked write privileges on public tables from the `anon` role.
  - Added `rd_transactions` to `REPLICA IDENTITY FULL` and `supabase_realtime` publication.
- GoRouter Root Route & OAuth Parameter Handling:
  - Added fallback `GoRoute(path: '/', redirect: ...)` to handle OAuth redirects landing on `http://127.0.0.1:3000/?code=...` and forward parameters to `/login` to prevent missing route exceptions.
- CQRS Data Persistence Pattern:
  - `customer_details_view`, `one_time_deposit_details_view`, and `recurring_deposit_details_view` for pre-joined reads.
  - RPC stored procedures for 100% atomic multi-table writes in 1 network roundtrip.
  - Repositories stream base table CDC change events and map through `asyncMap` view queries for real-time UI updates.
- Verified 100% test pass (`flutter test`) and clean static analysis (`flutter analyze`).

- **Phase 1 Complete**:
    - Initialized Supabase CLI and started local emulators.
    - Defined and applied initial Postgres schema (`agent_profiles`, `customers`, `deposits`, etc.) with RLS policies.
    - Added `supabase_flutter` and `envied` dependencies.
    - Fixed schema column alignment (`percentage` instead of `share_percentage` for `nominees`).
    - Fixed deposit amount editing persistence across `SupabaseRecurringDepositRepository` and `SupabaseOneTimeDepositRepository` by cleaning immutable payload fields (`id`, `created_at`, `updated_at`) and robustly extracting raw numeric input from formatted currency text fields in forms.
    - Validated zero issues with `flutter analyze` and `flutter test`.
    - Configured environment variable management with `Env` class and `.env` file.
    - Created `supabase/seed.sql` for local testing.
    - Updated documentation (`README.md`, `tasks.md`, `docs/supabase_migration_plan.md`) for Option 2 data persistence architecture.
- Bumped app version to **v1.6.0+16** and updated `CHANGELOG.md`.
- Successfully validated codebase with `flutter analyze` and `flutter test` (100% pass).
- Migrated Application ID from `com.example.postfolio` to `dev.darshanas.postfolio` across Android, iOS, macOS, and Linux.
- Added a multiline "Notes" text feature to the Customer model to serve as a scratch space for unstructured metadata. Integrated it into the Customer Form and displayed it on the Customer Details screen.
- Implemented automatic migration of invalid legacy nominees to customer notes in the migration tool.
- Successfully built the release Android App Bundle (`.aab`) for v1.5.1+15. (Previous milestone)
- Initiated **Phase 2: App Icons & Branding** (Currently skipped for internal testing).
- Fixed Kotlin DSL syntax errors in `android/app/build.gradle.kts` and corrected the keystore path in `android/key.properties`.
- Generated placeholder files for Play Store publication, including `android/key.properties`, `docs/store_assets/README.md`, and `docs/legal/privacy_policy.md`.
- Configured Android app signing in `build.gradle.kts` to use the release keystore properties.
- Defined publication checklist in `tasks.md`.
- Migrated Application ID from `com.example.postfolio` to `dev.darshanas.postfolio` across Android, iOS, macOS, and Linux.
- Added a multiline "Notes" text feature to the Customer model to serve as a scratch space for unstructured metadata. Integrated it into the Customer Form and displayed it on the Customer Details screen.
- Refactored currency formatting in deposit forms by centralizing `CurrencyTextInputFormatter` inside hooks, eliminating `replaceAll` hacky string manipulations, fixing numerical precision bugs, and stripping redundant prefix symbols for a cleaner UI.
- Fixed an issue where the sort and filter badges incorrectly displayed on fresh logins by aligning `StorageService` default values with domain models.
- Set up core architecture with Riverpod, Freezed, and standard thematic elements.
- Enabled Firestore Offline Persistence for the Web platform to support cache reading and reduce billable quota hits.
- Integrated Firebase Auth and Google Sign-In into the core domain layer (`AppUser`, `AuthState`).
- Configured GoRouter with reactive routing, enforcing redirect rules using an auth-based listenable.
- Built a functional `AuthRepository` and `AuthController` employing native Dart 3 features for exception handling.
- Implemented robust `HugeIcon` usage throughout the UI, standardizing visual sizes for list tiles, app bars, detail views, and forms.
- Migrated the UI layer entirely to `flutter_hooks` and `hooks_riverpod` to eliminate `StatefulWidget` boilerplate and enforce a strictly functional, React-like paradigm for ephemeral UI state.
- Initiated transition to automatic domain mathematical calculations for Small Savings Schemes. 
- Unified Floating Action Button (FAB) styles across list and detail pages to ensure visual consistency and correct theme inheritance.
- Created strictly typed, immutable models (`InvestmentProjection`, `PayoutFrequency`) and functional pure utilities (`ProjectionCalculator`) to handle complex interest and compounding math dynamically.
- Refactored `BaseDeposit`, `OneTimeDeposit` and `RecurringDeposit` models. Removed stored `maturityDate` and `maturityAmount` fields and replaced them with dynamic getters leveraging the `ProjectionCalculator` to ensure functional purity.
- Implemented `InvestmentProjectionCard` with live native `TweenAnimationBuilder` counting animations and `flutter_animate` transitions, integrating it directly into `OneTimeDepositFormScreen` and `RecurringDepositFormScreen`.
- Refined projection UI and mathematical domain logic for MIS, TD, and KVP schemes: decoupled total return from principal maturity for payout schemes, and introduced a prominent "Doubles In" calendar metric for KVP.
- Standardized date formatting across the application using Slang's `intl` integration and a centralized `DateTimeFormatting` extension to prevent ambiguous format errors.
- Addressed text truncation issues in Entity tiles by allowing names to wrap across multiple lines and vertically stacking account numbers with their respective maturity dates.
- Unified Deposit Detail screens to dynamically display projection metrics (Total Invested, Total Interest, Payout Frequency) using Dart 3 pattern matching against the `InvestmentProjection` sealed class.
- Upgraded the Deposit Status selection in form screens from a standard dropdown to an intuitive `SegmentedButton` using a newly created `AppSegmentedButtonField`.
- Refactored `Nominee` relationship from raw strings to a strongly-typed `NomineeRelationship` enum, utilizing `@JsonEnum` and `slang` map code generation for boilerplate-free JSON and localization handling.
- Optimized UI architecture by unifying Deposit Cards into single smart `ConsumerWidget`s (`OneTimeDepositCard` and `RecurringDepositCard`). Eliminated wrapper components and resolved skeleton loader restrictions by implementing a pure internal layout view (`_OneTimeDepositCardView`) and a `.skeleton()` factory, entirely removing the messy `isDummy` conditionals from the domain logic while maintaining Pragmatic Composition.
- Implemented Quick Actions (Close/Reopen) directly on deposit cards and detail views to optimize UX for status toggling.
- Upgraded `NomineesInputSection` to use `AppDropdownField` for predefined relationships with a fallback dynamic text field for 'Other'.
- Surfaced the exact absolute maturity date into the `EntityListTile` subtitle beneath the account number for both `OneTimeDepositCard` and `RecurringDepositCard`, providing better immediate context without cluttering the financial trailing column.
- Replaced binary `isFixedTenure` boolean with a strict `TenureInputType` enum (`singleFixed`, `fixedOptions`, `derived`) to enforce domain rules and completely eliminate arbitrary free-text custom tenures, successfully fixing the mismatch in KVP's dynamic tenure projections.
- Standardized `LoginScreen` to use theme dimensions and `flutter_animate` transitions, and added a Sign Out button to `DashboardScreen` and `MainShellScaffold` using Slang localized strings.
- Refactored Form Screens (`RecurringDeposit`, `OneTimeDeposit`, `Customer`) to reduce `build` method length and complexity.
- Introduced `FormSectionHeader` to standardize section headers and reduce repetitive styling code.
- Replaced the custom `Material` layout in `DemoBanner` with the official Flutter `MaterialBanner` widget, dropping explicit colors to fix a visual crossfade lag issue during theme toggling.
- Refactored all Form routing to utilize temporal push/pop navigation in accordance with the official GoRouter guidelines, removing manual `PopScope` blocking to correctly support predictive back gestures.
- Fixed convention violations where inline filtering was used instead of dedicated providers (e.g., `customerByIdProvider`).
- Migrated `OneTimeDepositRepository` and `RecurringDepositRepository` to `cloud_firestore` with real-time stream sync, utilizing UUID generation for client-side offline support.
- Fully implemented Demo Mode with a toggle on the login page allowing users to skip authentication and use fake repository data for demonstration purposes. Ensured UI strings use Slang `t` conventions. Users can exit demo mode by logging out from the dashboard.
- Secured Firestore data by scoping repository queries directly to the authenticated user's ID (`users/{userId}/...`), resolving data leakage across users.
- Improved UX by allowing users to navigate directly to the customer detail screen from deposit details.
- Implemented contextual deposit creation from the Customer Detail screen using a Material 3 Speed Dial FAB, with automatic pre-filling of customer data and return-navigation.
- Standardized deposit icons across the entire application for visual consistency.
- Added strict domain validation to `Nominee` model to ensure that percentage allocations exactly sum to 100%, and centralized this logic across `SavingsAccount`, `OneTimeDeposit`, and `RecurringDeposit`.
- Configured **Firebase Emulator** support for Firestore (port 8080) and Authentication (port 9099).
- Added a dedicated `USE_EMULATOR` flag logic in `main.dart` for seamless local development.
- Developed a comprehensive **Migration Tool** (`lib/run_migration.dart`) that parses legacy CSV data (Customers, Deposits, RD) and bootstraps the local Firestore emulator environment.
- Fixed a critical Firestore document path error in the migration script by sanitizing account numbers containing slashes before using them as document IDs.
- Fixed migration script deduplication logic to correctly handle and migrate rows with empty account numbers instead of incorrectly marking them as duplicates.
- Enhanced the migration tool with real-time statistics tracking and a summary UI showing CSV totals, migration counts, and skip reasons.
- Integrated the migration tool with the Authentication emulator to allow local testing of authenticated scopes.
- Updated project documentation (`README.md`) with comprehensive emulator setup, multi-machine Google Sign-In instructions, and environment cleanup steps.
- Standardized repository authentication guards to use `StateError` and improved error handling across data layers.
- Fixed a Demo Mode data inconsistency where `FakeDataSource` was assigning random `DepositStatus` values irrespective of chronological maturity dates, preventing accurate date-based sorting. Mock deposits are now constrained to prevent future dates from erroneously appearing as "matured" or "overdue".
- Updated the dashboard chart tooltip to display full monetary amounts instead of compact numbers for better precision when inspecting data points.
- Implemented month-level drill-down functionality in the Dashboard's Financial Year chart, allowing users to tap on a year to view deposits distributed across its 12 months (April to March) with a dedicated clear button to return to the yearly view.
- Fixed a startup crash/debugger pause occurring on unauthenticated launch by ensuring repositories handle the unauthenticated state gracefully during route resolution.
- Resolved Google Sign-In "Account reauth failed" on Android by registering the machine-specific SHA-1 fingerprint and updating the project configuration via FlutterFire CLI.
- Configured Linux environment shell profile (`.zshrc`) with correct paths for Flutter and Dart global tools.
- Refactored project guidelines and agent instructions into a modular, platform-agnostic system in `.agents/rules/`.
- Enforced strict Conventional Commits formatting and behavioral boundaries to prevent unsolicited agent commit suggestions.
- Bumped app version to 1.0.4+5 and updated release pipeline documentation for keystore decoding.
- Standardized primitive formatting using pure Dart extensions (`toRupeeFormat()`, `toPhoneFormat()`, `toAadhaarFormat()`, `toPanFormat()`) across the UI layer, aligning with the project's declarative conventions and keeping widgets dumb.
- Updated the accessibility theme toggle across all main screens to use the universal standard `Icons.contrast` from the Material library, replacing ambiguous iconography and implementing a clear selected background state.
- Extracted and centralized duplicated `AppBar` across main navigation screens into `ShellAppBar`, which accepts a dynamic list of custom actions (`actions`) rather than hardcoded booleans, enabling dynamic trailing widgets alongside the persistent `AccessibleThemeToggle`.
- Localized raw strings in projection grids (`WealthAccumulationGrid` and `IncomeGenerationGrid`) using `slang` and the `.i18n.yaml` framework.
- Refactored large form widgets (`_OneTimeDepositForm`, `_RecurringDepositForm`, `_CustomerForm`) by extracting complex state initializations, projection calculations, and save logic into pure `flutter_hooks` (`useOneTimeDepositForm`, `useRecurringDepositForm`, `useCustomerForm`), adhering to DRY principles and decoupling business/state logic from declarative UI layouts.
- Abstracted `NomineesInputSection` logic into a reusable `useNomineeFormState` hook.
- Extracted large grid components (`WealthAccumulationGrid`, `IncomeGenerationGrid`) from `detail_components.dart` into their own dedicated widget files.
- Added dynamic bottom padding to the `ListView` in `EntityDetailScaffold` to prevent the `FloatingActionButton` from overlapping with scrollable content when reaching the bottom of the list.
- Added `dynamic_color` package and implemented Material Monet dynamic theming support in `main.dart`.
- Updated default sorting of Recurring Deposits to use Serial Number (Increasing) based on user preference.
- Refactored sorting system to a type-safe Composite Model: decoupled `SortField` and `SortDirection` enums.
- Updated `AppSortBottomSheet` to a "Dumb Widget" pattern, receiving typed properties and directions, and added a "Reset" button to restore defaults.
- Moved direction mapping logic into domain enums, making `AppSortBottomSheet` a strictly generic UI component.
- Standardized all feature search criteria and controllers to use the new architecture and added `clearSort` methods.
- Hardened agent instructions in `AGENTS.md` and `git.md` with a "Pre-Commit Check" and explicit "STRICT CAPITALIZATION" warnings to ensure consistent commit formatting across sessions.
- Conducted a comprehensive Flutter UI/UX audit resulting in ~85% Material 3 compliance validation.
- Eliminated hardcoded generic colors (`Colors.green`, `Colors.white`, `Colors.transparent`) in migration and detail screens in favor of standard Material 3 semantic roles (`colorScheme.tertiary`, `colorScheme.error`).
- Registered official `SnackBarThemeData` (enforcing floating behavior globally), `ExpansionTileThemeData` (M3 standard colors), and `RadioThemeData` into the centralized `AppTheme`.
- Replaced the legacy `PopupMenuButton` widget in `EntityListTile` with the official Material 3 `MenuAnchor` for proper menu alignment and modern interaction patterns.
- Introduced the `animations` package and enabled `SharedAxisPageTransitionsBuilder` across Android, iOS, and macOS platforms to supply polished horizontal M3 page transitions.
- Enforced `showDragHandle: true` on `CustomerSelectionSheet` to match other bottom sheets.
- Updated `AlertDialog` instances in `app_dialogs.dart` to use the Material 3 `icon` property, enabling standard M3 center-aligned dialog styles.
- Standardized `FloatingActionButton.extended` across main list views (`CustomersScreen`, `OneTimeDepositsScreen`, `RecurringDepositsScreen`) to remain in a static extended state for consistent visibility.
- Established an agnostic AI agent customization framework in `.agents/`, including a dedicated `release-manager` skill and agent persona to automate versioning and pre-release validation.
- Integrated `SharedPreferences` within a custom `StorageService` to persist implicit user preferences (Themes, List Sorting, List Filters).
- Standardized UI bottom sheets (`AppSortBottomSheet`, `AppFilterBottomSheet`), standardizing their "Clear" actions to prevent abrupt closures and migrating the Sort sheet from `flutter_hooks` to a purely reactive Riverpod `Consumer` pattern.

## Releases
- **v1.6.0+16 (2026-06-26)**: Application ID migration, nominee migration fix, and Supabase roadmap.
- **v1.5.1+15 (2026-06-07)**: Added multiline notes field to customer profiles. Formatted currency strings with numeric word translation. Show full amount in dashboard chart tooltips.
- **v1.5.0+14 (2026-06-07)**: Built analytics dashboard with interactive charts and Financial Year mappings. Enabled Firestore Web offline persistence. Standardized SchemeType UI to Segmented Buttons and restored predictive back gestures on forms.
- **v1.4.0+13 (2026-06-03)**: Type-safe composite sorting, persisted user preferences, Material 3 UI/UX improvements, and release manager skill.
- Started Phase 2 of Supabase Migration (Lift & Shift): Enforced snake_case serialization, updated TimestampConverter for dual-db support, and created abstract interfaces for all repositories.
- Created parallel Supabase repositories (Auth, Customer, OTD, RD) and implemented Riverpod toggles based on Env.useSupabase.
- Fixed Google Sign-In assertion failure on Supabase Web by routing web authentication through `supabaseClient.auth.signInWithOAuth(OAuthProvider.google)` and bypassing the legacy `google_sign_in` flow on web.
- Configured local Supabase emulator to support Google Sign-In by adding the `[auth.external.google]` block in `config.toml`.
- Updated `.vscode/launch.json` to bind Flutter Web to `localhost:3000` to match Supabase's `site_url`.
- Explicitly set `redirectTo: http://127.0.0.1:3000` inside `supabaseClient.auth.signInWithOAuth()` to ensure Supabase Auth redirects back to the correct host/port on Flutter Web.
- Configured Supabase Google OAuth to automatically determine `redirectTo` based on the `USE_EMULATOR` flag.
- Added `--dart-define=USE_EMULATOR=true` to the `Postfolio (Chrome)` launch configuration to ensure Supabase knows when to override `redirectTo` for local development.
- Configured Flutter Web to use Path URL Strategy instead of Hash Routing by invoking `usePathUrlStrategy()` in `main.dart`, allowing OAuth providers to correctly pass `?code=` back to the app without causing route parse failures or white screens.
- Updated `GoRouter` redirect logic to preserve query parameters (`?code=...`) when redirecting unauthenticated users to `/login`, preventing Flutter from stripping Supabase's OAuth callback payload.
- Resolved `flutter pub get` duplicate key error in `pubspec.yaml` caused by malformed automated edits and successfully added `flutter_web_plugins` dependency to enable `usePathUrlStrategy()`.
- Fixed column naming mismatches (`account_number` -> `account_no`) and added missing `customer_id` columns on `recurring_deposits` and `one_time_deposits` in `supabase/migrations/20260626000000_initial_schema.sql` to match Dart model serialization.
- Added nominee creation and update handling in `SupabaseRecurringDepositRepository` and `SupabaseOneTimeDepositRepository`.
- Re-applied migrations with `npx supabase db reset`.
