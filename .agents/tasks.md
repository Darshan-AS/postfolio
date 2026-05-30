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
- [x] **Authentication Domain:** Create `AppUser` model and sealed `AuthState` union (Freezed).
- [x] **Authentication Data Layer:** Build `AuthRepository` for Google Sign-In and mapping to Firebase.
- [x] **Authentication Presentation:** Build `AuthController` and the `LoginScreen` widget.
- [x] **Secure Routing:** Set up GoRouter `refreshListenable` and `redirect` guard for unauthenticated users.
- [x] Build `FirestoreCustomerRepository` and swap out the Fake repository.
- [x] Setup Client-Side ID generation for Customers using `uuid` to improve Firestore syncing and offline-support.
- [x] Build Firestore repositories for Deposits, RD, and Schemes.
- [x] **Refactor Data Fetching**: Transition detail screens from list-based filtering (`AsyncValue<List<T>>`) to single-document fetching (`AsyncValue<T>`) using Riverpod family providers to improve efficiency with Firestore. Rewrite `AsyncEntityBuilder` accordingly.
- [x] Configure **Firebase Emulator** support for local development (Firestore on port 8080, Auth on port 9099).

## Phase 8: Enhancements & Refinements (In Progress)
- [x] Implement a **"Demo Mode"** feature toggle. When activated via a persistent UI button on the login screen, the app bypasses Firebase Auth constraints and wires all repository providers to their `FakeDataRepository` counterparts instead of `FirestoreRepository`, allowing a complete offline, zero-setup interactive demonstration.
- [x] Extract `shared_preferences` implementation into `lib/core/services/storage_service.dart` for simple UI state.
- [x] Implement comprehensive form field validations across all create/update screens.
- [x] **Routing UX:** Navigate to corresponding customer detail screen when clicking on a customer in the deposit detail view.
- [x] **Customer Detail UX:** List all associated deposits (One-Time and Recurring) directly within the customer's detail view.
- [x] **UI Cleanup - Formatting:** Display Aadhaar number in format "XXXX XXXX XXXX" across the app.
- [x] Implement a predefined dropdown with a manual entry fallback for Nominee relationship fields across all forms.
- [x] Expand `SchemeType` enum and models to support an exhaustive list of Term Deposit variants.
- [x] **Domain Math - Maturity Calculators & Projections:** Create `InvestmentProjection` model, `ProjectionCalculator` utility class, and refactor Base models to replace maturity fields with getters.
- [x] Run `build_runner` to regenerate Freezed models and JSON serialization.
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
  - [x] Matured but not closed (overdue)
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
- [ ] Integrate `firebase_crashlytics` for automatic error tracking and reporting.
- [ ] Integrate `firebase_analytics` to track user engagement and app usage metrics.
- [ ] Integrate `share_plus` into `IntentService` to allow agents to share deposit details/reports.
- [ ] Integrate `flutter_native_splash` to generate native splash screens.
- [ ] **Detail View - RD Premature Closure**: Prompt user for applicable penalty interest rate and show the premature withdrawal amount.
- [ ] **Detail View - General Premature Closure**: Implement early withdrawal calculation logic for all applicable schemes.

## Phase 9: Responsive Architecture (Pending)
- [ ] Add `flutter_adaptive_scaffold` to the project for official Material 3 adaptive layouts.
- [ ] Refactor `go_router` in `app_router.dart` to use `StatefulShellRoute` wrapping the `AdaptiveScaffold`.
- [ ] Implement adaptive navigation (BottomNavigationBar on Mobile vs NavigationRail on Web/Desktop).
- [ ] Create Master-Detail layouts for Customer, RD, and Deposit lists on large screens.
- [ ] Refactor `BottomSheet` invocations to conditionally display as `AlertDialog` or Side Panels on large screens.

## Phase 10: Agent Profile Feature (Pending)
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
