# Current Progress & Agent Handoff

**Last Updated:** April 11, 2026

## Current State
The project is structurally sound and compiles perfectly. We have successfully implemented a full CRUD cycle for the `Customers`, `OneTimeDeposit`, and `RecurringDeposit` features using mock repositories and Riverpod state management. Each feature follows the exact same architectural pattern, including UI parity with consistent form fields, validators, and loading states. The app uses a `StatefulShellRoute` for bottom navigation, and routing is completely type-safe using `go_router_builder`.

Nominee inputs have been unified across the Customers (SB Account) and Deposits (One-Time and Recurring) features, utilizing the `NomineesInputSection` and removing redundant code. The phone number field was removed from the `Nominee` model, adhering strictly to the shared unified structure.

## UI & Architectural Refinements
- **Theming & Colors**: Replaced all hardcoded usages of `AppTheme.primary`, `AppTheme.error`, `AppTheme.accent` with `Theme.of(context).colorScheme...` to correctly support dark mode/dynamic themes.
- **Typography**: Removed hardcoded `TextStyle` usages (like `const TextStyle(fontWeight: FontWeight.bold)`) from AppBars, cards, and buttons, standardizing on `Theme.of(context).textTheme...`.
- **State Mismanagement**: Refactored `CustomerSelectionField` to resolve selected customers within the `build` method directly from the provider state, removing anti-patterns where `WidgetsBinding.addPostFrameCallback` was used to trigger `setState`.

## Active Technical Debt
None currently. The architectural cleanup phase, type-safe routing migration, UI updates (pull-to-refresh, standardized ListView layouts, Detail screen parity, and AppDimensions usage), and mock CRUD implementations are complete. 

*Note: All features now have full CRUD capabilities, initial fake data, and centralized validation. Deposits and RD forms include start/maturity dates, interest rates, linked account fields, and dynamic Nominee inputs, matching the Customer feature's level of polish. Colors, Route paths, Dimensions, and Spacings are centralized, and ListView layouts/Detail screens are standardized across all features. Domain Validation and Controller validation logic are implemented across all models. CustomerCard's intent handling was extracted to IntentService. Form screen initialization and loading states are fixed using local `setState`. Controllers return pure FP `Result` objects. UI Strings are localized via Slang (`en.i18n.yaml`). Generic error views are used via `ErrorStateView`. Pull-to-refresh (`RefreshIndicator`) is present in all listing screens.*

## Next Agent Action
The immediate next step is to proceed to **Phase 5 (Firebase Integration)** from `tasks.md`. Run `flutterfire configure` to connect the project, and then start building the real `FirestoreCustomerRepository` and Firestore repositories for Deposits, RD, and Schemes to replace the current Fake repositories.

- Refactored legacy `Provider` declarations to use `@riverpod` annotation (code generation) for `CustomerRepository`, `OneTimeDepositRepository`, `RecurringDepositRepository`, `GoRouter`, and `IntentService` to adhere rigorously to Riverpod conventions.
- Ensured no usages of `StateNotifier` or `dartz` exist in the codebase.

- Added `EntityListTile` to centralize list item UI across Customer and Deposit cards.
- Added `AppTextField`, `AppDropdownField`, `AppDateField` for form field deduplication.
- Added `AsyncEntityFormBuilder` to wrap async riverpod state in forms.
- Added `FormAppBar` to standardize the save actions across forms.
- Refactored `customer_form_screen`, `one_time_deposit_form_screen`, and `recurring_deposit_form_screen` to use the new core widgets.

- Created `EntityDetailScaffold` to standardize details screen scaffold.
- Created `EntityDetailHeader` to standardize hero section of detail screens.
- Refactored `AsyncEntityFormBuilder` to `AsyncEntityBuilder` for generic usage across forms and details.
- Abstracted `NomineesDetailSection` for reuse.
- Refactored all Detail screens to utilize the new common scaffold.

- Fixed an issue where deleted records would reappear due to FakeRepository instance resets (made data lists static).
- Standardized delete handling in list screens to await results and handle errors.
