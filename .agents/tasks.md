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

## Phase 3: Architectural Cleanup (Pending)
- [ ] Refactor `UserCard` native intents (SMS/Phone/Map) into an injected `IntentService`.
- [x] Refactor `UsersController` to accept raw strings, validate, and construct the Domain model.
- [ ] Implement Domain Validation (e.g., Extension methods on Freezed models).
- [ ] Centralize hardcoded route paths into a constants file.
- [ ] Centralize hardcoded colors into `lib/core/theme/`.

## Phase 4: Deposits & RD Features (Pending)
- [ ] Build `DepositsRepository` and `DepositsController`.
- [ ] Build `DepositsScreen` (List) and `DepositCard`.
- [ ] Build `DepositFormScreen` (Create/Update).
- [ ] Build `DepositDetailScreen`.
- [ ] Repeat for Recurring Deposits (RD).

## Phase 5: Firebase Integration (Pending)
- [ ] Run `flutterfire configure`.
- [ ] Build `FirestoreUserRepository` and swap out the Fake repository.
- [ ] Build Firestore repositories for Deposits, RD, and Schemes.
