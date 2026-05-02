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
- [x] Fix oversized icons in form fields by standardizing prefix icon sizes in the global `InputDecorationTheme`.
- [x] Standardize icon sizes for `AppBar` and `ListTile` actions.
- [x] Use same icons in entity add/edit page and entity view page.

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
- [ ] Build `InvestmentProjectionCard` UI for live previews.
- [ ] Implement Gross/Net Commission logic and TDS rules.

## Phase 6: Structural Refactoring (Pending)
- [x] Reorganize `lib/core/` structure (Created `services/`, `extensions/`).
- [x] Extract shared services into `lib/core/services/`.
- [x] Extract extension methods into `lib/core/extensions/`.
- [x] Refactor `AppTheme` into a granular file structure inside `lib/core/theme/`.
- [x] Extract generic `AppTextField` widgets into `lib/core/widgets/`, removing all `.w`/`.h`/`.sp` screenutil references.
- [ ] Replace standard `FilledButton` usages across the app with `AppButton` to leverage built-in loading states. (To rethink)
- [x] Integrate `skeletonizer` for list and detail loading states.
- [x] Integrate `flutter_animate` for UI entry/exit animations.
- [x] Migrate all icons from `font_awesome_flutter` and Material to `hugeicons`.
- [x] Refactor UI layer to use `flutter_hooks` and `hooks_riverpod`, eliminating all `StatefulWidget` and `ConsumerStatefulWidget` boilerplate.

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
- [x] Expand `SchemeType` enum and models to support an exhaustive list of Term Deposit variants.
- [ ] **Domain Math - Maturity Calculators & Projections:**
  - [x] Create `InvestmentProjection` model in `lib/core/models/`.
  - [x] Create `ProjectionCalculator` utility class in `lib/core/services/` for RD, TD, MIS, NSC, and KVP formulas.
  - [x] Refactor `BaseDeposit`, `OneTimeDeposit`, and `RecurringDeposit` to replace `maturityAmount` and `maturityDate` with dynamic getters.
  - [x] Update controllers, fake repositories, and dummy data to omit manual maturity fields.
  - [x] Run `build_runner` to regenerate Freezed models and JSON serialization.
- [ ] **Domain Math - Commission Calculators:** Implement functions to auto-calculate Gross Commission per transaction (4% for RD, 0.5% for others) and auto-deduct the 2% TDS to derive the Net Payout.
- [ ] **Domain Math - Penalties & Rebates:** Implement transaction evaluation logic to automatically calculate RD Late Fees (1% per month delayed) and Advance Deposit Rebates (₹10/₹40 rules for 6+/12+ months).
- [ ] **UI Cleanup - Live Preview & "Dumb Widgets":**
  - [ ] Create Riverpod Form Notifiers (`OneTimeDepositFormNotifier`, `RecurringDepositFormNotifier`) to track inputs and expose live `InvestmentProjection`.
  - [x] Remove manual `maturityDate` and `maturityAmount` input fields from form screens.
  - [ ] **Dynamic Form Previews:** Create and integrate an `InvestmentProjectionCard` to dynamically calculate and display the expected Maturity Date, Maturity Amount, and interest projections in real-time as the user changes form values.
- [ ] **UI Cleanup - Non-Editable Fixed Fields:** Make form fields read-only (non-editable) when they only have a single valid value or don't require user input. For example, lock the "Scheme Type" selection for Recurring Deposits, and make the "Term Length" field non-editable for single-tenure schemes like MIS and NSC.
- [ ] **UI Cleanup - Deposit Status Selection:** Upgrade the "Deposit Status" widget in the form screens from a standard dropdown to a more intuitive UI component (e.g., a SegmentedButton or ChoiceChips).
- [ ] Add filtering capabilities to deposit list screens (e.g., view by Active, Matured, Closed status).
- [ ] Integrate search functionality across all entity listing screens (Customers, Deposits, RDs).
- [ ] Create and integrate an enum for relationships in the `Nominee` model.
- [ ] Explore migrating `termYears` and `termMonths` into a custom Domain-Driven Value Object (e.g., `class Tenure`) to encapsulate calendar math, keeping in mind the tradeoffs for Firestore compound indexing.
- [ ] Implement and support dark theme across the application.
- [ ] Implement local App Lock (Biometrics/PIN) for additional privacy and security.
- [ ] Explore `flutter_flavorizr` for managing native app flavors (Dev, Staging, Prod).
- [ ] Integrate `firebase_crashlytics` for automatic error tracking and reporting in production.
- [ ] Integrate `firebase_analytics` to track user engagement and app usage metrics.
- [ ] Integrate `share_plus` into `IntentService` to allow agents to share deposit details/reports with customers via native share sheets.
- [ ] Integrate `flutter_native_splash` to generate native splash screens and prevent cold-boot white flashes.
