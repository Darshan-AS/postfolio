# Project Progress

## Current State
- Set up core architecture with Riverpod, Freezed, and standard thematic elements.
- Integrated Firebase Auth and Google Sign-In into the core domain layer (`AppUser`, `AuthState`).
- Configured GoRouter with reactive routing, enforcing redirect rules using an auth-based listenable.
- Built a functional `AuthRepository` and `AuthController` employing native Dart 3 features for exception handling.
- Implemented robust `HugeIcon` usage throughout the UI, standardizing visual sizes for list tiles, app bars, detail views, and forms.
- Migrated the UI layer entirely to `flutter_hooks` and `hooks_riverpod` to eliminate `StatefulWidget` boilerplate and enforce a strictly functional, React-like paradigm for ephemeral UI state.
- Initiated transition to automatic domain mathematical calculations for Small Savings Schemes. 
- Created strictly typed, immutable models (`InvestmentProjection`, `PayoutFrequency`) and functional pure utilities (`ProjectionCalculator`) to handle complex interest and compounding math dynamically.
- Refactored `BaseDeposit`, `OneTimeDeposit` and `RecurringDeposit` models. Removed stored `maturityDate` and `maturityAmount` fields and replaced them with dynamic getters leveraging the `ProjectionCalculator` to ensure functional purity.
- Implemented `InvestmentProjectionCard` with live native `TweenAnimationBuilder` counting animations and `flutter_animate` transitions, integrating it directly into `OneTimeDepositFormScreen` and `RecurringDepositFormScreen`.
- Refined projection UI and mathematical domain logic for MIS, TD, and KVP schemes: decoupled total return from principal maturity for payout schemes, and introduced a prominent "Doubles In" calendar metric for KVP.
- Standardized date formatting across the application using Slang's `intl` integration and a centralized `DateTimeFormatting` extension to prevent ambiguous format errors.
- Addressed text truncation issues in Entity tiles by allowing names to wrap across multiple lines and vertically stacking account numbers with their respective maturity dates.
- Unified Deposit Detail screens to dynamically display projection metrics (Total Invested, Total Interest, Payout Frequency) using Dart 3 pattern matching against the `InvestmentProjection` sealed class.
- Upgraded the Deposit Status selection in form screens from a standard dropdown to an intuitive `SegmentedButton` using a newly created `AppSegmentedButtonField`.
- Refactored `Nominee` relationship from raw strings to a strongly-typed `NomineeRelationship` enum, utilizing `@JsonEnum` and `slang` map code generation for boilerplate-free JSON and localization handling.
- Upgraded `NomineesInputSection` to use `AppDropdownField` for predefined relationships with a fallback dynamic text field for 'Other'.
- Standardized `LoginScreen` to use theme dimensions and `flutter_animate` transitions, and added a Sign Out button to `DashboardScreen` and `MainShellScaffold` using Slang localized strings.
- Refactored Form Screens (`RecurringDeposit`, `OneTimeDeposit`, `Customer`) to reduce `build` method length and complexity.
- Introduced `FormSectionHeader` to standardize section headers and reduce repetitive styling code.
- Fixed convention violations where inline filtering was used instead of dedicated providers (e.g., `customerByIdProvider`).
- Migrated `OneTimeDepositRepository` and `RecurringDepositRepository` to `cloud_firestore` with real-time stream sync, utilizing UUID generation for client-side offline support.
- Fully implemented Demo Mode with a toggle on the login page allowing users to skip authentication and use fake repository data for demonstration purposes. Ensured UI strings use Slang `t` conventions. Users can exit demo mode by logging out from the dashboard.
- Secured Firestore data by scoping repository queries directly to the authenticated user's ID (`users/{userId}/...`), resolving data leakage across users.
- Improved UX by allowing users to navigate directly to the customer detail screen from deposit details.
- Enhanced `CustomerDetailScreen` UX by directly listing all associated "One-Time Deposits" and "Recurring Deposits" inside the customer detail view, giving comprehensive portfolio oversight without switching contexts.
- Added strict domain validation to `Nominee` model to ensure that percentage allocations exactly sum to 100%, and centralized this logic across `SavingsAccount`, `OneTimeDeposit`, and `RecurringDeposit`.

## Next Steps
- **Form State Refactor**: Migrate local hook-based form state inside form screens to dedicated Riverpod Form Notifiers (`OneTimeDepositFormNotifier`, `RecurringDepositFormNotifier`) for strictly pure business logic.
- **Implement Commission Logic**: Add the next set of domain math features to automatically deduce gross/net commissions and TDS.
- **Fixed/Locked UI Fields**: Make form fields read-only for specific schemes (e.g., lock Scheme Type for RD, term length for MIS/NSC).
