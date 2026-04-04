# Project Tasks & Roadmap

## Phase 1: Foundation (Completed)
- [x] Define architecture conventions (Riverpod, Freezed, Feature-First).
- [x] Scaffold directory structure (`lib/core/`, `lib/features/`).
- [x] Create Domain Models (`User`, `Scheme`, `Deposit`, `RecurringDeposit`, `Nominee`).
- [x] Configure Firebase as BaaS (decided against local DBs like Isar/Drift).
- [x] Set up GoRouter with `StatefulShellRoute` (Main Bottom Nav).

## Phase 2: Users Feature (Completed)
- [x] Implement `UserRepository` interface and `FakeUserRepository`.
- [x] Implement `UsersController` (Riverpod).
- [x] Build `UsersScreen` (List View).
- [x] Build `UserFormScreen` (Create/Update).
- [x] Build `UserDetailScreen` (Read/Delete).

## Phase 3: Architectural Cleanup (Completed)
- [x] Refactor `UserCard` native intents (SMS/Phone/Map) into an injected `IntentService`.
- [x] Refactor `UsersController` to accept raw strings, validate, and construct the Domain model.
- [x] Implement Domain Validation (e.g., Extension methods on Freezed models).
- [x] Centralize hardcoded route paths into a constants file.
- [x] Centralize hardcoded colors into `lib/core/theme/`.
- [x] Centralize hardcoded dimensions and spacings into `AppSpacings` and `AppDimensions`.
- [x] Fix `UserFormScreen` initialization (avoid synchronously reading controller state).
- [x] Implement robust loading states in `UserFormScreen` (disable buttons during save).
- [x] Create a reusable `ErrorStateView` widget for consistent error handling and retries.
- [x] Refactor Controllers to return strongly-typed `Result` types instead of throwing exceptions.
- [x] Add strict domain validation and factory constructors to `Deposit`, `Scheme`, and `RecurringDeposit` models.
- [x] Remove Hardcoded Strings by setting up Slang localizations (`.i18n.yaml` files).

## Phase 4: Deposits & RD Features (Completed)
- [x] Build `OneTimeDepositRepository` and `OneTimeDepositsController`.
- [x] Build `RecurringDepositRepository` and `RecurringDepositsController`.
- [x] Build `OneTimeScreen` (List) and `OneTimeDepositCard`.
- [x] Build `OneTimeDepositFormScreen` (Create/Update).
- [x] Build `OneTimeDepositDetailScreen`.
- [x] Build `RecurringDepositsScreen` (List) and `RecurringDepositCard`.
- [x] Build `RecurringDepositFormScreen` (Create/Update).
- [x] Build `RecurringDepositDetailScreen`.

## Phase 5: Firebase Integration (Pending)
- [ ] Run `flutterfire configure`.
- [ ] Build `FirestoreUserRepository` and swap out the Fake repository.
- [ ] Build Firestore repositories for Deposits, RD, and Schemes.
