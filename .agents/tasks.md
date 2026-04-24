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
- [x] Build `CustomerDetailScreen` (Read/Delete).

## Phase 3: Architectural Cleanup (In Progress)
- [x] Refactor `CustomerCard` native intents (SMS/Phone/Map) into an injected `IntentService`.
- [x] Refactor `CustomersController` to accept raw strings, validate, and construct the Domain model.
- [x] Implement Domain Validation (e.g., Extension methods on Freezed models).
- [x] Centralize hardcoded route paths into a constants file.
- [x] Integrate `go_router_builder` for type-safe routing.
- [x] Centralize hardcoded colors into `lib/core/theme/`.
- [x] Remove direct static AppTheme usages and hardcoded TextStyles from UI layers, relying strictly on Theme.of(context).
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
- [ ] Add `riverpod_lint` and `custom_lint` for static analysis of Riverpod rules.
- [x] Standardize Input Decorations across all form fields using `AppInputDecoration.m3`.
- [x] Standardize Save Buttons across all form screens using `FilledButtonThemeData`.
- [x] Unify border radius to `radiusLg` across input decorations, cards, and buttons.
- [x] Standardize bottom padding in all form screens by ensuring a `gapXxl` after the save button.

## Phase 4: Deposits & RD Features (Completed)
- [x] Build `OneTimeDepositRepository` and `OneTimeDepositsController`.
- [x] Build `RecurringDepositRepository` and `RecurringDepositsController`.
- [x] Build `OneTimeScreen` (List) and `OneTimeDepositCard`.
- [x] Build `OneTimeDepositFormScreen` (Create/Update).
- [x] Build `OneTimeDepositDetailScreen`.
- [x] Build `RecurringDepositsScreen` (List) and `RecurringDepositCard`.
- [x] Build `RecurringDepositFormScreen` (Create/Update).
- [x] Build `RecurringDepositDetailScreen`.

## Phase 5: Structural Refactoring (In Progress)
- [x] Reorganize `lib/core/` structure (Created `services/`, `extensions/`).
- [x] Extract shared services into `lib/core/services/`.
- [x] Extract extension methods into `lib/core/extensions/`.
- [x] Refactor `AppTheme` into a granular file structure inside `lib/core/theme/`.
- [x] Extract generic `AppTextField` widgets into `lib/core/widgets/`, removing all `.w`/`.h`/`.sp` screenutil references.
- [ ] Replace standard `FilledButton` usages across the app with `AppButton` to leverage built-in loading states. (To rethink)
- [x] Integrate `skeletonizer` for list and detail loading states.
- [ ] Integrate `flutter_animate` for UI entry/exit animations.
- [ ] Migrate all icons from `font_awesome_flutter` and Material to `hugeicons`.
- [ ] Track structural decisions in `conventions.md`.

## Phase 6: Firebase Integration & Authentication (Pending)
- [ ] Run `flutterfire configure`.
- [ ] Add necessary packages: `firebase_core`, `firebase_auth`, and `cloud_firestore`. (Avoid unnecessary Firebase bloat).
- [ ] Expose Firebase instances (`FirebaseAuth`, `FirebaseFirestore`) using Riverpod Providers. Do not use static getters.
- [ ] Implement Email & Password Authentication.
- [ ] Implement Phone (OTP) Authentication.
- [ ] Build `FirestoreCustomerRepository` and swap out the Fake repository.
- [ ] Build Firestore repositories for Deposits, RD, and Schemes.
- [ ] **Refactor Data Fetching**: Transition detail screens from list-based filtering (`AsyncValue<List<T>>`) to single-document fetching (`AsyncValue<T>`) using Riverpod family providers to improve efficiency with Firestore. Rewrite `AsyncEntityBuilder` accordingly.

## Phase 7: Enhancements & Refinements (Pending)
- [ ] Extract `shared_preferences` implementation into `lib/core/services/storage_service.dart` for simple UI state.
- [ ] Implement comprehensive form field validations across all create/update screens.
- [ ] Expand `SchemeType` enum and models to support an exhaustive list of Term Deposit variants.
- [ ] **Domain Math - Maturity Calculators:** Implement pure Dart extensions to auto-calculate Maturity Dates (accounting for RD defaults) and Maturity Amounts (compounding for RD/TD/NSC, simple for MIS) based on principal, tenure, and start date.
- [ ] **Domain Math - Commission Calculators:** Implement functions to auto-calculate Gross Commission per transaction (4% for RD, 0.5% for others) and auto-deduct the 2% TDS to derive the Net Payout.
- [ ] **Domain Math - Penalties & Rebates:** Implement transaction evaluation logic to automatically calculate RD Late Fees (1% per month delayed) and Advance Deposit Rebates (₹10/₹40 rules for 6+/12+ months).
- [ ] **UI Cleanup - Remove Manual Fields:** Refactor `RecurringDepositFormScreen` and `OneTimeDepositFormScreen` to remove fields like "Maturity Amount" or "Maturity Date" if they require manual input. Replace them with read-only "Live Preview" text based on the auto-calculations.
- [ ] Add filtering capabilities to deposit list screens (e.g., view by Active, Matured, Closed status).
- [ ] Integrate search functionality across all entity listing screens (Customers, Deposits, RDs).
- [ ] Create and integrate an enum for relationships in the `Nominee` model.
- [ ] Rethink the data type for `termYears` and `termMonths` in deposit models (e.g., consider using a single duration or custom value object).
- [ ] Implement and support dark theme across the application.
- [ ] Implement local App Lock (Biometrics/PIN) for additional privacy and security.
- [ ] Explore `flutter_flavorizr` for managing native app flavors (Dev, Staging, Prod).
- [ ] Integrate `firebase_crashlytics` for automatic error tracking and reporting in production.
- [ ] Integrate `firebase_analytics` to track user engagement and app usage metrics.
- [ ] Integrate `share_plus` into `IntentService` to allow agents to share deposit details/reports with customers via native share sheets.
- [ ] Integrate `flutter_native_splash` to generate native splash screens and prevent cold-boot white flashes.
