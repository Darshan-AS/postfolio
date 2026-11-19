# Project Tasks & Roadmap

## Phase 1: Foundation (Completed)
- [x] Define architecture conventions (Riverpod, Freezed, Feature-First).
- [x] Scaffold directory structure (`lib/core/`, `lib/features/`).
- [x] Create Domain Models (`User`, `Scheme`, `Deposit`, `RecurringDeposit`, `Nominee`).
- [x] Configure Firebase as BaaS (decided against local DBs like Isar/Drift).
- [x] Set up GoRouter with `StatefulShellRoute` (Main Bottom Nav).

## Phase 2: Customers Feature (Completed)
- [x] Implement `CustomerRepository` interface and `FakeCustomerRepository`.
- [x] Implement `CustomersController` (Riverpod).
- [x] Build `CustomersScreen` (List View).
- [x] Build `CustomerFormScreen` (Create/Update).
- [x] Build `CustomerDetailScreen` (Read/Delete/Contextual Create).
    - [x] Implement Speed Dial for One-Time/Recurring deposit creation.
    - [x] Standardize icons across portfolio views.

## Phase 3: Architectural Cleanup (In Progress)
- [x] Refactor `CustomerCard` native intents (SMS/Phone/Map) into an injected `IntentService`.
- [x] Refactor `CustomersController` to accept raw strings, validate, and construct the Domain model.
- [x] Implement Domain Validation (e.g., Extension methods on Freezed models).
- [x] Centralize hardcoded route paths into a constants file.
- [x] Integrate `go_router_builder` for type-safe routing.
- [x] Centralize hardcoded colors into `lib/core/theme/`.
- [x] Migrate to fully dynamic Material 3 Theming (ColorScheme, TextTheme, Dark Mode support).
- [x] Integrate Material Monet dynamic theming via `dynamic_color`.
- [x] Conduct a comprehensive Material 3 UI/UX audit, replace legacy widgets (like PopupMenuButton), standardizing widget themes, and configure SharedAxisPageTransitions.

- [x] Remove direct static AppTheme usages and hardcoded TextStyles from UI layers, relying strictly on Theme.of(context).
- [x] Standardize AppBar styling by removing hardcoded typography from UI screens and centralizing it in `AppWidgetThemes`.
- [x] Centralize hardcoded dimensions and spacings into `AppSpacings` and `AppDimensions`.
- [x] Replace hardcoded padding with `AppDimensions` in deposit cards.
- [x] Standardize ListView layouts and padding across screens.
- [x] Deduplicate and extract common widgets into `EntityListTile`, `AppTextField`, `AppDropdownField`, `AsyncEntityFormBuilder`, and `FormAppBar`.
- [x] Deduplicate and extract common widgets into `EntityDetailScaffold`, `EntityDetailHeader`, `NomineesDetailSection`, and generalize `AsyncEntityBuilder`.
- [x] Standardize Detail Screen layouts and widget sizes.
- [x] Fix `CustomerFormScreen` initialization (avoid synchronously reading controller state).
- [x] Implement robust loading states in `CustomerFormScreen` (disable buttons during save).
- [x] Create a reusable `ErrorStateView` widget for consistent error handling and retries.
- [x] Refactor Controllers to return strongly-typed `Result` types instead of throwing exceptions.
- [x] Add strict domain validation and factory constructors to `Deposit`, `Scheme`, and `RecurringDeposit` models.
- [x] Remove Hardcoded Strings by setting up Slang localizations (`.i18n.yaml` files).
- [x] Add pull-to-refresh to listing screens.
- [x] Unify `Nominee` model and widgets across Customers and Deposits, removing duplicate logic.
- [x] Add domain validation to ensure Nominee percentages sum exactly to 100%.
- [x] Fix uneven horizontal padding in List Views (right side currently has more empty space than the left).
- [x] Standardize Input Decorations across all form fields using `AppInputDecoration.m3`.
- [x] Standardize Save Buttons across all form screens using `FilledButtonThemeData`.
- [x] Unify border radius to `radiusLg` across input decorations, cards, and buttons.
- [x] Standardize bottom padding in all form screens by ensuring a `gapXxl` after the save button.
- [x] Fix oversized icons in form fields by standardizing prefix icon sizes in the global `InputDecorationTheme`.
- [x] Standardize icon sizes for `AppBar` and `ListTile` actions.
- [x] Use same icons in entity add/edit page and entity view page.
- [x] Refactor domain enums to remove verbose boilerplate and switch statements using `@JsonEnum` and `slang` translation maps.
- [ ] Add `riverpod_lint` and `custom_lint` for static analysis of Riverpod rules.
- [ ] Update Nominee UI to a better input widget/slider that enforces the 100% rule.
- [ ] Organize the Savings Bank (SB) account number and its associated nomination details into a single cohesive UI section.
- [ ] Ensure that the relationship of each nominee to the account holder is clearly displayed in the UI.
- [ ] Remove duplicate display of the interest rate in the Recurring Deposits (RD) UI.

## Phase 4: Deposits & RD Features (Completed)
- [x] Build `OneTimeDepositRepository` and `OneTimeDepositsController`.
- [x] Build `RecurringDepositRepository` and `RecurringDepositsController`.
- [x] Build `OneTimeScreen` (List) and `OneTimeDepositCard`.
- [x] Build `OneTimeDepositFormScreen` (Create/Update).
- [x] Build `OneTimeDepositDetailScreen`.
- [x] Build `RecurringDepositsScreen` (List) and `RecurringDepositCard`.
- [x] Build `RecurringDepositFormScreen` (Create/Update).
- [x] Build `RecurringDepositDetailScreen`.

## Phase 5: Domain Math & Automatic Calculations (In Progress)
- [x] Create `PayoutFrequency` enum and strictly typed `InvestmentProjection` state class.
- [x] Build `ProjectionCalculator` pure utility class for PO scheme rules.
- [x] Refactor Deposit models to strictly compute maturity projections (removing persisted inputs).
- [x] Build `InvestmentProjectionCard` UI for live previews.
- [x] Build `run_migration.dart` utility to bootstrap local emulator data from legacy CSV exports.
- [x] Fixed a critical Firestore document path error in the migration script by sanitizing account numbers containing slashes before using them as document IDs.
- [x] Fixed migration script deduplication logic to correctly handle and migrate rows with empty account numbers instead of incorrectly marking them as duplicates.
- [x] Rework migration script to dynamically parse CSV headers and use strict `Row ID` foreign keys, resolving customer name duplication bugs.
- [ ] Implement Gross/Net Commission logic and TDS rules.

## Phase 6: Structural Refactoring (In Progress)
- [x] Reorganize `lib/core/` structure (Created `services/`, `extensions/`).
- [x] Extract shared services into `lib/core/services/`.
- [x] Extract extension methods into `lib/core/extensions/`.
- [x] Refactor `AppTheme` into a granular file structure inside `lib/core/theme/`.
- [x] Extract generic `AppTextField` widgets into `lib/core/widgets/`, removing all `.w`/`.h`/`.sp` screenutil references.
- [x] Integrate `skeletonizer` for list and detail loading states.
- [x] Integrate `flutter_animate` for UI entry/exit animations.
- [x] Migrate all icons from `font_awesome_flutter` and Material to `hugeicons`.
- [x] Refactor UI layer to use `flutter_hooks` and `hooks_riverpod`, eliminating all `StatefulWidget` and `ConsumerStatefulWidget` boilerplate.
- [x] Clean up the codebase to ensure no function/method is excessively long. Extract complex business logic and UI build methods into pure, composable logical functions wherever possible.
- [ ] Replace standard `FilledButton` usages across the app with `AppButton` to leverage built-in loading states. (To rethink)

## Phase 7: Firebase Integration & Authentication (Completed)
- [x] Run `flutterfire configure`.
- [x] Add necessary packages: `firebase_core`, `firebase_auth`, `google_sign_in`, and `cloud_firestore`.
- [x] Update iOS `Info.plist` with the URL Scheme from `GoogleService-Info.plist` and verify Android SHA keys.
- [x] Expose Firebase instances (`FirebaseAuth`, `GoogleSignIn`) using Riverpod Providers.
- [ ] Configure Firebase App Check (Audit Mode) with Play Integrity/App Attest for release and Debug Tokens for local dev.
- [ ] Integrate Firebase Remote Config for dynamic app configurations (e.g., dynamic interest/commission rates, minimum required version for forced updates, feature kill switches).
- [x] **Authentication Domain:** Create `AppUser` model and sealed `AuthState` union (Freezed).
- [x] **Authentication Data Layer:** Build `AuthRepository` for Google Sign-In and mapping to Firebase.
- [x] **Authentication Presentation:** Build `AuthController` and the `LoginScreen` widget.
- [x] **Secure Routing:** Set up GoRouter `refreshListenable` and `redirect` guard for unauthenticated users.
- [x] Build `FirestoreCustomerRepository` and swap out the Fake repository.
- [ ] Add Firebase Analytics wrapper (`AnalyticsService`), inject `FirebaseAnalyticsObserver` to `GoRouter`, and track key business events in controllers (e.g., `log_collection`, `create_rd_account`, `create_ot_account`, `add_customer`, and screen tracking).
- [x] Setup Client-Side ID generation for Customers using `uuid` to improve Firestore syncing and offline-support.
- [x] Integrate Firebase Performance Monitoring for automated tracing of app startup and offline-sync network behavior.

## Phase 8: Optimization & Quota Management (Planned)
- [ ] Implement Firestore optimization plan to fix quota exhaustion (see [firestore_optimization_plan.md](../docs/firestore_optimization_plan.md)):
  - [ ] Denormalize Customer Data in Deposits
  - [ ] Implement Server-Side Pagination & Infinite Scrolling UI
  - [ ] Move Filtering/Sorting to Server-Side (Firestore `orderBy`)
  - [ ] Implement Server-Side Prefix Search
  - [ ] Enable Web Offline Persistence
- [x] Build Firestore repositories for Deposits, RD, and Schemes.
- [x] **Refactor Data Fetching**: Transition detail screens from list-based filtering (`AsyncValue<List<T>>`) to single-document fetching (`AsyncValue<T>`) using Riverpod family providers to improve efficiency with Firestore. Rewrite `AsyncEntityBuilder` accordingly.
- [x] Configure **Firebase Emulator** support for local development (Firestore on port 8080, Auth on port 9099).

## Phase 9: Enhancements & Refinements (In Progress)
- [x] **System Metadata:** Add `createdAt`, `updatedAt` (using `FieldValue.serverTimestamp()`), and `migrationSource` (e.g., 'legacy_csv_v1_{timestamp}') to all Domain models. Update Firestore repositories and `run_migration.dart` to populate these fields.
- [ ] **Data Integrity - Soft Deletes (Deferred):** Implement an `isDeleted` flag and document `version` on domain models (Customers, Deposits, RDs). 
  - *Why this is critical:* Hard deleting a customer leaves orphaned deposits pointing to a non-existent `customerId`, breaking referential integrity. It also permanently destroys historical financial records which may be needed for commission audits.
  - *Action:* Update queries to filter out `isDeleted == true` and implement a "soft delete" rather than a Firestore `delete()` operation.
- [x] Implement a **"Demo Mode"** feature toggle. When activated via a persistent UI button on the login screen, the app bypasses Firebase Auth constraints and wires all repository providers to their `FakeDataRepository` counterparts instead of `FirestoreRepository`, allowing a complete offline, zero-setup interactive demonstration.
- [x] Extract `shared_preferences` implementation into `lib/core/services/storage_service.dart` for simple UI state.
- [x] Implement comprehensive form field validations across all create/update screens.
- [x] **Routing UX:** Navigate to corresponding customer detail screen when clicking on a customer in the deposit detail view.
- [x] **Customer Detail UX:** List all associated deposits (One-Time and Recurring) directly within the customer's detail view. (Added Collapsible History for closed deposits)
- [x] **UI Cleanup - Formatting:** Display Aadhaar number in format "XXXX XXXX XXXX" across the app.
- [x] Implement a predefined dropdown with a manual entry fallback for Nominee relationship fields across all forms.
- [x] Expand `SchemeType` enum and models to support an exhaustive list of Term Deposit variants.
- [x] **Domain Math - Maturity Calculators & Projections:** Create `InvestmentProjection` model, `ProjectionCalculator` utility class, and refactor Base models to replace maturity fields with getters.
- [x] Run `build_runner` to regenerate Freezed models and JSON serialization.
- [x] Configured Firebase Web Hosting for SPA routing and deployed to default/custom domains.
- [x] **UI Cleanup - Live Preview & "Dumb Widgets":** Use `flutter_hooks` to manage local ephemeral form state and isolate business math.
- [x] Remove manual `maturityDate` and `maturityAmount` input fields from form screens.
- [x] **Dynamic Form Previews:** Create and integrate an `InvestmentProjectionCard` to dynamically calculate and display projections.
- [x] **Explore Projection Animations:** Investigate "stock ticker" or odometer-style rolling number animations for the `InvestmentProjectionCard`.
- [x] **Refine Projection UX:** Split "Total Return" from principal for Income Generation schemes and display KVP's dynamic "Doubles In" duration.
- [x] **UI Cleanup - Date Formatting:** Standardize date displays across the entire app using `slang`'s `intl` integration.
- [x] **UI Cleanup - Non-Editable Fixed Fields:** Make form fields read-only when they only have a single valid value or don't require user input.
- [x] **UI Cleanup - Deposit Status Selection:** Upgrade the "Deposit Status" widget in the form screens from a standard dropdown to a more intuitive UI component.
- [x] **UI Cleanup - Hero Animations:** Add unique `heroTag` properties to the `FloatingActionButton`s and implement physical expanding Hero animations transitioning into the Create Form screens.
- [x] Create and integrate an enum for relationships in the `Nominee` model.
- [ ] Implement image capture and display functionality for customer profiles.
- [x] Support Search feature in Customers, One-Time Deposits, and Recurring Deposits.
- [x] Support Filter features across all entity listing screens.
- [x] Support Sort features across all entity listing screens.
- [x] Add UI controls for search/filter/sort:
  - [x] Add a Filter Bottom Sheet for filtering on deposit screens.
  - [x] Implement a reusable Sort Bottom Sheet triggered by a sort icon in the App Bar.
  - [x] Add friendly "No results found" empty states with a "Clear Filters" action.
- [x] Polish the Search Bar UI/UX (migrated to official M3 SearchBar with custom theme and added a dedicated "Cancel" button).
- [x] Implement a persistent Unified Search Bar with inline sort and filter actions across all listing screens.
- [ ] Persist all sort and filter selections as user preferences so defaults are retained across sessions.
- [ ] Add `maturityWarningDays` (default 7d) as a user preference so agents can customize their notification window.
- [x] Highlight deposits based on maturity status:
  - [x] About to mature (computed via `maturityWarningDays` threshold)
  - [x] Matured but not closed (overdue) -> Renamed to `matured` in `MaturityUrgency`
  - [x] Completely closed
- [ ] Redesign the leading visual element in deposit list tiles to replace the generic circular icons.
- [ ] Apply distinct color coding to differentiate deposit types in list views.
- [ ] Enhance the visual prominence of the scheme type in deposit detail views.
- [ ] **Domain Math - Commission Calculators:** Implement functions to auto-calculate Gross Commission and auto-deduct the 2% TDS to derive the Net Payout.
- [ ] **Domain Math - Penalties & Rebates:** Implement transaction evaluation logic to automatically calculate RD Late Fees and Advance Deposit Rebates.
- [ ] **UI Cleanup - Relative Time Formatting:** Add relative time display using the `timeago` or `jiffy` packages.
- [ ] Explore migrating `termYears` and `termMonths` into a custom Domain-Driven Value Object.
- [ ] Implement and support dark theme across the application.
- [ ] Implement local App Lock (Biometrics/PIN) for additional privacy and security.
- [ ] Explore `flutter_flavorizr` for managing native app flavors (Dev, Staging, Prod).
- [x] Integrate `firebase_crashlytics` for automatic error tracking and reporting.
- [ ] Implement Custom Firebase Performance traces for intensive client-side processing (e.g., list sorting, heavy projections) (Planned for Optimization Phase).
- [ ] Integrate `firebase_analytics` to track user engagement and app usage metrics.
- [ ] Integrate `share_plus` into `IntentService` to allow agents to share deposit details/reports.
- [ ] **Routing UX Re-evaluation:** Refactor routing logic to handle context-aware "back" navigation (e.g., clicking 'Edit' from a List view should return to the List on back/cancel, rather than always returning to the Detail view).
- [ ] Integrate `flutter_native_splash` to generate native splash screens.
- [ ] **Detail View - RD Premature Closure**: Prompt user for applicable penalty interest rate and show the premature withdrawal amount.
- [ ] **Detail View - General Premature Closure**: Implement early withdrawal calculation logic for all applicable schemes.
- [ ] Show maturity date in list view.
- [x] Fix trailing layout constraints and status badge visibility in deposit cards.
- [x] Streamline entity list tile layouts and tighten action button spacing.
- [x] Adjust spacing across the app (reduce padding/margin).
- [x] Fix white space layout bug in Demo Mode by standardizing nested scaffold keyboard resizing behavior.
- [x] Hide intent actions (SMS, Phone, WhatsApp) for customers when contact information is missing.
- [x] Round off amounts to nearest integer.
- [x] Add Wong/Tol accessible color palette concepts (Magenta for error, Yellow/Orange for success) for Red-Green Color Blindness.

## Phase 10: Responsive Architecture (Pending)
- [ ] Add `flutter_adaptive_scaffold` to the project for official Material 3 adaptive layouts.
- [ ] Refactor `go_router` in `app_router.dart` to use `StatefulShellRoute` wrapping the `AdaptiveScaffold`.
- [ ] Implement adaptive navigation (BottomNavigationBar on Mobile vs NavigationRail on Web/Desktop).
- [ ] Create Master-Detail layouts for Customer, RD, and Deposit lists on large screens.
- [ ] Refactor `BottomSheet` invocations to conditionally display as `AlertDialog` or Side Panels on large screens.

## Phase 11: Agent Profile Feature (Pending)
- [ ] Expand `AppUser` domain model to include personal info and agency details.
- [ ] Build `AgentProfileRepository` for managing agent details in Firestore.
- [ ] Build `AgentProfileController` for state management.
- [ ] Build `AgentProfileScreen` to display and edit personal and agency details.

## Phase 11: Internationalization & Localization (Future)
- [ ] **Phone Numbers**: Migrate from custom Dart extensions to a `libphonenumber` backed package (e.g., `phone_numbers_parser`).
- [ ] **Currencies**: Refactor `DoubleFormatExtension` to a dynamic currency formatter that reads the user's preferred locale.

## Phase 12: CI/CD & Distribution (Pending)
- [x] Automate build process and release per-platform APKs using GitHub Actions.
- [x] Distribute beta builds to internal testers using Firebase App Distribution.
- [x] Unified CI/CD: Append Firebase Web deployment to the mobile release workflow for strict Web/Mobile parity on `v*` tags.
- [ ] Write end-to-end UI tests for critical user flows using the `integration_test` package.
- [ ] Configure Firebase Test Lab to run tests on virtual/physical devices.
- [ ] Set up an optional manual trigger (`workflow_dispatch` or Environments) in GitHub Actions for Test Lab to conserve free tier quota.

## Phase 13: Advanced Firebase Integrations (Future)
- [ ] **Authentication**: Implement Passkey or Biometric Login to secure the app without requiring constant Google re-authentication.
- [ ] **Cloud Firestore**: Implement Agency Mode / Shared Ledgers using an `accessList` in security rules to allow agents and assistants to collaborate on the same ledger.
- [ ] **Realtime Database**: Implement Live Presence and Edit Locks to prevent data-overwrite collisions when multiple users edit the same customer profile.
- [ ] **Cloud Storage**: Create a Digital Document Vault for securely uploading and viewing physical deposit slips, Aadhaar, and PAN cards.
- [ ] **Cloud Functions (Requires Blaze Plan)**: Automate PDF Ledger Reports with a cron job that emails weekly maturity summaries to agents.
- [ ] **Firebase Extensions (Requires Blaze Plan)**: Auto-Sync CRM data to Google Sheets using official extensions to provide agents with a live spreadsheet backup.
- [x] **Firebase Hosting**: Deploy a Web Desktop Dashboard to allow agents to perform heavy data entry on a laptop keyboard.
  - [x] Configure `firebase.json` with rewrites to `index.html` to fully support `go_router` deep linking.
  - [x] Set up a custom domain (e.g., `app.postfolio.in`) with auto-provisioned free SSL.
  - [x] Enable and verify Progressive Web App (PWA) capabilities so agents can "Install" the web app on their desktops.
- [ ] **Crashlytics**: Track Non-Fatal Math Errors from the `ProjectionCalculator` to gracefully catch and fix domain logic edge cases.
- [ ] **Performance Monitoring**: Track UI render times (e.g., `InvestmentProjectionCard`) to ensure 60fps performance on large data sets.
- [ ] **Remote Config**: Fetch Dynamic Interest Rates for Post Office schemes remotely so math calculations update instantly without requiring app store releases.
- [ ] **Cloud Messaging (FCM)**: Send proactive Maturity Alerts (Push Notifications) to remind agents of upcoming maturity dates.
- [ ] **Google Analytics**: Track Feature Adoption (e.g., `filter_used`) to understand how agents are utilizing new search and filtering tools.
- [ ] **In-App Messaging**: Display native pop-ups for Feature Discovery to announce new app capabilities to users after an update.

## Known Bugs & Issues

### Resolved
- [x] **Customer Form - Saving Issue**: Entering only a name and saving a customer works, but entering all details and saving fails or does not work.
- [x] **Date Picker UI Bug**: On selecting a new date in the date widget, the form text field does not visually update in the UI.
- [x] **KVP Projection Crash**: The Form UI crashes for KVP selection with unsupported operation infinity when interest rate is cleared or 0.
- [x] **Form View - KVP Crash**: Fixed flutter build phase exception (setState during build) when switching to KVP.
- [x] **Form View - TD Calculation**: The maturity amount should have interest added in.
- [x] **Form View - MIS Projection**: Add a field to show maturity amount + total earned (e.g., "Total Value" or "Total Return").
- [x] **Form View - KVP Projection**: Show a human-readable time period indicating when the deposit doubles.

### Open
- [ ] **Form View - Keyboard Spacer**: Clicking on a text field in a form brings up the keyboard and a lot of empty white space on top of it.

### Pending Architecture Refactors
- [ ] **Cross-Feature Isolation**: Extract shared widgets (like `customer_selection_field`) into `lib/core/widgets/`. Move data-fetching providers into `domain/providers/` to allow features to read each other's data without importing `presentation` or `data` layers.
- [ ] **Domain Purification (DTOs)**: Create Firestore DTOs (e.g., `CustomerDTO`) in the `data` layer. Remove `@TimestampConverter` and JSON serialization from `domain` models to completely decouple the Domain from Firebase.
- [ ] **Auth Realignment**: Move `lib/features/auth` to `lib/core/auth` as it is a global infrastructure dependency rather than an isolated feature.

## Phase 8: Firestore Optimization (Pending)
- [ ] Denormalize Customer Data: Add `customerName` (and any other search-relevant fields) to the `OneTimeDeposit` and `RecurringDeposit` models.
- [ ] Update save logic in controllers/repositories to populate the denormalized name, eliminating the need to fetch the entire customer list for search/sort.
- [ ] Implement Server-Side Pagination: Refactor Repositories to use `limit(20)` and `.get()` (or paginated snapshots) alongside `startAfterDocument()` cursors.

---

# Finished items moved out of `.agents/tasks.md` on 2026-11-19

*Unchanged, under their original headings. Everything here was finished before the v2.4 work began. A parent line is repeated here when some of what is under it is still open in `tasks.md`.*

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

## ⚡ Supabase Query Optimizations (Prioritized)
- [x] **P1: Server-Side Joins for Deposit Customer Names**: Modify `one_time_deposit_details_view` and `recurring_deposit_details_view` views to join with the `customers` table and return `customer_name`. Add `@JsonKey(includeFromJson: true, includeToJson: false) String? customerName` to deposit models to eliminate client-side cross-fetching/map loops.
- [x] **P2: Filter Real-Time CDC Streams by Agent ID**: Update repositories to filter change streams using `.stream(...).eq('agent_id', _userId)` instead of listening to all database-wide table changes.
- [x] **P2.1: Lightweight Base Table Streaming for Customer List**: Stream physical `customers` table directly in `watchCustomers()` without `.asyncMap` view queries, eliminating 749 lateral joins on every CDC mutation. Lazy-load single full view details in `CustomerDetailScreen` and `CustomerFormScreen` via `customerByIdProvider(customerId)`.
- [x] **P2.2: Strip N+1 Customer Stream Watchers from Deposit Cards & Form Screens**: Remove `ref.watch(customerByIdProvider)` from `OneTimeDepositCard` and `RecurringDepositCard`, resolving titles directly from pre-joined `deposit.customerName`. Bypass list controller streams in `OneTimeDepositFormScreen` and `RecurringDepositFormScreen` on deposit creation.
- [x] **P2.3: Single Deposit Detail Providers & Watchers (Phase 2)**: Added `watchOneTimeDepositById` and `watchRecurringDepositById` across Supabase, Firestore, and Fake repositories. Added `oneTimeDepositByIdProvider` and `recurringDepositByIdProvider` family providers. Refactored `OneTimeDepositDetailScreen`, `RecurringDepositDetailScreen`, and deposit form screens (in edit mode) to use `AsyncSingleEntityBuilder`, decoupling single deposit detail and edit screens from entire list controller streams.
- [x] **P2.4: Defer Nominees from Deposit List Queries (Lightweight List Views)**: Specified explicit column projections in `watchOneTimeDeposits()` and `watchRecurringDeposits()` in Supabase repositories to omit `nominees`. By omitting `nominees`, Postgres completely bypasses `public.get_account_nominees(d.id)` lateral function execution across all list rows, cutting list query overhead while single deposit detail queries retain full nominee data.
- [x] **P4a: Multi-Page `.range()` Auto-Pagination (`>1,000`-Row Safe)**: Implemented `SupabasePaginatedQuery.fetchAllPages` (`.range()` 500-row pages) + debounced Realtime/local-mutation collection streams across all Supabase repositories so agent collections scale seamlessly past PostgREST's 1,000-row `max-rows` cap.
- [x] **P6: Upgrade Client UUID Generation to UUIDv7**: Migrated client-side `uuid` generation across Customers, OTDs, RDs, RD transactions, and PO deposits to time-ordered RFC 9562 v7 UUIDs (`const Uuid().v7()`) to prevent B-tree index page splits.

## 📦 Release & Publication (Play Store)
- [x] **Fix Firebase Hosting deploy in CI**: `release.yml` failed on v2.3.0+21 and v2.3.1+22 with `403 PERMISSION_DENIED` (`serviceusage.services.get` on `firebasehosting.googleapis.com`). Cause: `action-hosting-deploy` runs `firebase-tools@latest`, and a newer CLI added a Service Usage pre-check the CI service account lacked. Fixed by granting the SA **Service Usage Consumer** (Cloud Console IAM) and pinning `firebaseToolsVersion: 15.35.0`; rerun of 42806147007 deployed 2.3.1+22 to https://postfolio-app.web.app.
- [x] **Change Application ID**: Update `applicationId` in `android/app/build.gradle.kts` (e.g., to `dev.darshanas.postfolio`).
- [x] **Android Product Flavors (Staging & Prod)**: Configured `staging` (`.staging` package suffix, "Postfolio Staging") and `prod` ("Postfolio") flavors for side-by-side device installation and independent testing.
- [x] **Distinguishing Staging & Prod App Icons**: Configured flavor-specific app icons generated via `flutter_launcher_icons`. Staging icon features a prominent orange banner and "STAGING" badge to clearly distinguish from the production icon.
- [x] **Production Keystore**: Generate release JKS and configure `key.properties`. (Placeholder `key.properties` created and `build.gradle` updated)
- [x] **Store Assets**: Prepare screenshots, feature graphic, and metadata. (Placeholder directory and checklist created)
- [x] **Privacy Policy**: Host and link the privacy policy. (Placeholder created)
- [x] **AAB Build**: Run `flutter build appbundle` for release. (v1.5.1+15 built and successfully deployed to Internal Testing)

## 🧮 Domain Math & Business Logic
- [x] **KVP Term DB Sync & Official Post Office Rate Schedule (`PostalRateService`)**: Implemented `PostalRateService` (`postalRateServiceProvider`) and `@freezed sealed class PostalSchemeTerms` mapping investment `startDate` across all schemes (`KVP`, `NSC`, `MIS`, `TD` 1/2/3/5Y, `RD`) to official Ministry of Finance / Department of Posts historical circulars (2000–Present). Deposit creation and projection calculation now only require `startDate` to auto-resolve official `interestRate`, `termYears`, `termMonths`, `maturityDate`, and `maturityAmount`, while keeping `Interest Rate (%)` and KVP `Term (Years / Months)` editable in the UI as an agent override for newly announced circulars or edge cases. Enforced the Contractual Snapshot pattern so `OneTimeDeposit` and `RecurringDeposit` persist the resolved/overridden `interestRate`, `termYears`, and `termMonths` to the DB on save and strictly trust the stored DB snapshot on read.

## 📊 Dashboard & Analytics
- [x] **Core Dashboard**: Implemented dashboard with aggregated metrics, active/total breakdowns, and interactive `fl_chart` data visualizations.
- [x] **Financial Year Charting**: Switched the "Deposits Over Time" graph to map and display using the Indian Financial Year (e.g. "FY 23-24") starting in April.
- [x] **Chart Drill-Down**: Added month-level drill-down interaction to the Financial Year chart with a 'Back to Years' UI.

## 🎨 UI/UX Polish & Features
- [x] **Preferences**: Persist sort/filter selections and `maturityWarningDays` across sessions.
- [x] **Routing UX**: Re-evaluate context-aware "back" navigation (e.g., Detail -> List vs Detail -> Home).
- [x] **Minor Fixes**: Remove duplicate display of RD interest rate; replace `FilledButton` with `AppButton` (if deemed necessary).

## ⚙️ Architecture, Tooling & Security
- [x] **Agent Customization**: Refactored guidelines into a modular rule system in `.agents/rules/` for improved agent compliance and platform-agnosticism.
- [x] **Modern Android & Gradle Ecosystem Migration**: Upgraded project to use modern Android tooling: Gradle 9.5.1, AGP 9.3.0, Kotlin 2.3.20, and modern Firebase plugins (google-services 4.5.0, firebase-perf 2.0.2, firebase-crashlytics 3.0.8). Fully migrated to **Built-in Kotlin** (`android.builtInKotlin=true`), eliminating KGP-related deprecation warnings, and enabled AGP 9.0+ resource value compatibility.
- [x] **DDD Auth User decoupling & Ubiquitous Language Refactor**: Decoupled technical Auth context (`AuthUser`) from the business domain, renamed `_userId` and `userId` variables inside all customer and deposit repositories to ubiquitous `_agentId` and `agentId` terms to align with database schemas (`agent_id` / `agent_profiles`).
- [x] **Unique Email Guardrails**: Enforced case-insensitive unique email index (`idx_agent_profiles_email_lower` on `lower(email)`) + case-insensitive `handle_new_user()` JIT relinking on `agent_profiles`, intercepting PostgreSQL `23505` violations in `SupabaseErrorMapper`.

## 📱 Future Epics
### Epic: Firebase Elimination
- [x] Complete codebase cleanup of legacy Firebase data/auth/analytics dependencies (`firebase_auth`, `cloud_firestore`, `firebase_performance`, `firebase_analytics`), retaining only `firebase_core` + native `!kIsWeb` `firebase_crashlytics` and Firebase Hosting.
- [x] Remove legacy `Firebase*Repository` / `Firestore*Repository` classes and the `Env.useSupabase` toggle strategy.
- [x] Clean up redundant fallback `customerMap` logic in `one_time_deposits_controller.dart` and `recurring_deposits_controller.dart` once pre-joined database views + reactive customer name overlay are wired in Stage 3.

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
