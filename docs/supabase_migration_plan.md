# Postfolio: Firebase to Supabase Migration Plan

## 1. Executive Summary & Architectural Decisions

This document outlines the strategy for migrating Postfolio from Firebase (NoSQL) to Supabase (PostgreSQL). The migration focuses on solving NoSQL quota limitations and setting a robust foundation for heavy relational data, such as RD tracking and advanced dashboard aggregations.

### Dashboard & Console Manual Checklist
Throughout this migration, several actions must be performed manually in external dashboards. 
*   [ ] **Google Cloud Console:** Create a new Web Client ID specifically for Supabase Auth.
*   [ ] **Supabase Dashboard:** Enable Google Provider in Authentication settings and paste the Web Client ID and Secret.
*   [ ] **Firebase Console:** Temporarily update `firestore.rules` during Phase 4 to allow admin read access for data extraction.
*   [ ] **Firebase Console (CLI):** Export Auth users to JSON (`firebase auth:export users.json`).
*   [ ] **Google Cloud Console:** Add production Play Store SHA-1 and SHA-256 fingerprints to the Web Client ID credentials before final deployment.
*   [ ] **Firebase Console:** Add production Play Store SHA-1 and SHA-256 fingerprints to Firebase settings to ensure Crashlytics/Analytics continue working.

### Core Decisions
1. **Offline Strategy**: **Online-Only (V1)**. The initial migration will require an active internet connection to read/write data. 
   * *UX Impact*: We will implement a global "No Internet" blocking screen. If the app boots without a connection, the user will be blocked at the routing layer rather than entering a broken/empty dashboard.
   * *Future Roadmap*: We will evaluate **PowerSync** or SQLite caching later to restore offline capabilities for agents.
2. **UI State Management**: **Blocking Overlays**. When a user saves a form, the UI will block with a loading spinner until the Supabase network request completes, ensuring absolute data consistency.
3. **The Firebase Purge**: **Hybrid Stack (Community Standard)**. We will eventually remove `cloud_firestore` and `firebase_auth`, but we will **keep** `firebase_core`, `firebase_analytics`, and `firebase_crashlytics`. *Note: The actual removal of the Firestore/Auth packages will happen at the very end of Phase 4; they must remain installed during development to support the parallel Riverpod toggles.*
4. **Implementation & Schema Strategy**: **Parallel Implementations & Iterative Normalization**. We will build this in a dedicated `feature/supabase-migration` branch. Instead of overwriting code, we will rename existing repositories to `Firebase*` and build `Supabase*` equivalents alongside them. We will start with a "Lift and Shift" of the flat Firestore schema to reach immediate compile parity, and then step-by-step write SQL migrations to transform it into the ideal relational state before launch.
5. **Data Migration**: **Maintenance Window**. Given the low active user count (< 5), we will schedule a brief downtime to run a migration script, moving Firestore data and Google Auth users directly into the finalized Supabase relational tables.

---

## 2. Target Postgres Schema (Iterative Normalization)

We will initially deploy flat tables that mirror our Firestore documents. Then, we will iteratively write SQL migrations to normalize them into the following ideal relational structure. This eliminates N+1 queries and makes aggregations instantaneous.

### Primary Keys & Data Types Strategy
*   **Primary Keys (UUIDv7):** We will use native Postgres `UUID`s for all primary keys. **Why:** The app is already generating UUIDs locally. However, we must upgrade the Dart `uuid` package implementation to generate **UUIDv7** (time-sorted) instead of `UUIDv4` (random). `v4` UUIDs cause severe index fragmentation in Postgres B-Trees. `v7` provides the benefits of client-side generation (crucial for optimistic UI) while ensuring optimal database insertion performance.
*   **Enums vs TEXT:** We will initially map `deposit_status` and `scheme_type` to `TEXT`. **Why:** This perfectly aligns with our "Lift & Shift" Strategy. Once the app compiles and is parity-tested, we will write a SQL migration during Phase 3 to cast these `TEXT` columns into strict Postgres `ENUM`s for ultimate database integrity.
*   **Complex Types (Immediate Normalization):** Instead of trapping `savingsAccount` and `nominees` in `JSONB` columns, we will strictly normalize them into separate relational tables from Day 1. **Why:** Trapping data in `JSONB` defeats the purpose of moving to Postgres, making it incredibly difficult to query or index specific nominees later. Since we are writing a data translation script anyway, it is trivial to extract these into dedicated tables during migration.

### Core Tables
*   **`agent_profiles` (New)**
    *   `id` (UUID, Primary Key, Foreign Key to `auth.users`) - 1:1 relationship with Supabase Auth.
    *   `legacy_firebase_uid` (Text, Unique, Nullable) - Temporary mapping column.
    *   `name`, `email`, `agency_code` (Text)
    *   `created_at`, `updated_at` (Timestamp with Time Zone)

*   **`savings_accounts` (Normalized)**
    *   `id` (UUID, PK)
    *   `customer_id` (UUID, FK to `customers`, ON DELETE CASCADE, Unique)
    *   `account_number` (Text)
    *   `linked_date` (Date)

*   **`customers`**
    *   `id` (UUID, Primary Key)
    *   `agent_id` (UUID, Foreign Key to `agent_profiles`) - Row Level Security (RLS)
    *   `name`, `phone`, `pan_number`, `email`, `address`, `cif_number`, `aadhaar_number` (Text)
    *   `date_of_birth` (Date)
    *   `created_at`, `updated_at` (Timestamp with Time Zone)
    *   `notes` (Text)

*   **`recurring_deposits` & `one_time_deposits`**
    *   `id` (UUID, PK)
    *   `customer_id` (UUID, FK to `customers`, ON DELETE CASCADE)
    *   `agent_id` (UUID, FK to `agent_profiles`)
    *   `status` (Text -> Migrated to ENUM later)
    *   `scheme_type` (Text -> Migrated to ENUM later)
    *   `account_number`, `serial_no` (Text)
    *   `principal_amount`, `installment_amount`, `interest_rate` (Numeric)
    *   `term_years`, `term_months` (Integer)
    *   `start_date` (Date)

*   **`nominees` (Normalized)**
    *   `id` (UUID, PK)
    *   `deposit_id` (UUID, FK to `recurring_deposits` or `one_time_deposits`, ON DELETE CASCADE)
    *   `name`, `relationship` (Text)
    *   `share_percentage` (Numeric)
  
*   **`rd_transactions` (New Feature Prep)**
    *   `id` (UUID, PK)
    *   `rd_id` (UUID, FK to `recurring_deposits`, ON DELETE CASCADE)
    *   `paid_date` (Date)
    *   `amount` (Numeric)
    *   `agent_id` (UUID, FK to `agent_profiles`)

### Database Views (For Dashboards)
Instead of fetching all deposits to Dart, we will create SQL `VIEW`s that pre-calculate metrics.
*   **`dashboard_metrics_view`**: Aggregates total active RDs, total OTDs, and total investment volume per agent.
*   **`monthly_investment_view`**: Groups deposits by month/year for the charts.

### Row Level Security (RLS) & Future Admin Roles
Every operational table (`customers`, `deposits`) contains an `agent_id` column. Currently, agents can only see their own records. To future-proof for "Admin" users who can view any agent's data:
1.  We will create a `user_roles` table (`user_id`, `role`).
2.  Our RLS policies on tables like `customers` will be written as: 
    `(auth.uid() = agent_id) OR (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'))`.
3.  This ensures security is enforced at the database level while keeping the schema completely open for future hierarchical access and the Agent Profiles feature.

---

## 3. Step-by-Step Migration Execution

### Phase 1: Local Supabase Setup (Emulator)
1. **CLI Init**: Install Supabase CLI and run `supabase init`.
2. **Docker**: Ensure Docker Desktop is running and run `supabase start` to spin up the local Postgres and Auth emulators.
3. **Docs Update**: Update `README.md` and `.agents/tasks.md` to instruct future agents/developers to run `supabase start` instead of `firebase emulators:start`.
4. **Schema**: Write initial schema and RLS policies in `supabase/migrations/`.
5. **Seed**: Generate local dummy data (`seed.sql`) for testing without hitting production.
6. **Package**: Add `supabase_flutter` to `pubspec.yaml`.
7. **Auth Config (Manual)**: 
   * Go to Google Cloud Console -> APIs & Services -> Credentials. Create an OAuth 2.0 Web Client ID.
   * Go to Supabase Dashboard -> Authentication -> Providers -> Google. Enable it and paste the Web Client ID and Secret. *(Note: We are focusing exclusively on Android/Google Sign-In for now. Apple Sign-In is out of scope).*

### Phase 2: Parallel Codebase Refactor (Lift & Shift)
1. **Environments:** Use the `envied` package for environment management. We will create a `.env.example` file with placeholder strings. The developer must copy this to `.env` and fill in the values before running `build_runner`, otherwise the app will not compile. We will track:
   * `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `USE_SUPABASE` (Toggle), `GOOGLE_WEB_CLIENT_ID`, and `GOOGLE_IOS_CLIENT_ID`.
2. **Freezed Snake Case**: Update all Freezed models with `@JsonSerializable(fieldRename: FieldRename.snake)` so Dart's `customerName` seamlessly maps to Postgres's `customer_name`.
3. **Date Conversion (Transition Strategy)**: Update the custom `@TimestampConverter()` in Freezed models to support *both* Firebase's `Timestamp` objects and Supabase's standard ISO-8601 `String` dates. This allows the models to work simultaneously for both implementations during the transition. Once Firebase is fully removed, delete the converter entirely.
4. **Interfaces**: Define abstract interfaces for all repositories (e.g., `CustomerRepository` interface).
5. **Rename Old**: Rename existing classes to `FirebaseCustomerRepository`, ensuring they implement the new interfaces.
6. **Create New**: Create `SupabaseCustomerRepository` and implement the interface. 
   * **Agent ID Injection:** Do *not* add `agentId` to the Freezed domain models. The `SupabaseCustomerRepository` will silently inject `supabase.auth.currentUser!.id` into the JSON payload right before calling `.insert()` or `.update()`. This keeps the domain models perfectly pure and decoupled from Auth.
7. **Riverpod Toggle**: Update Riverpod providers to read the `envied` variable (e.g., `USE_SUPABASE`) to seamlessly return either the Firebase or Supabase repository implementation. This creates a 1-line compile-time toggle between the two backends.
8. **Auth UX**: Keep the existing `google_sign_in` package to maintain the native bottom-sheet OS login experience. Do not use Supabase's native OAuth (which relies on deep links). Fetch the `idToken` from Google and pass it to Supabase via `supabase.auth.signInWithIdToken()`. Map the resulting Supabase `Session` directly to the `AppUser` domain model.
9. **Lift & Shift**: Map Dart models to flat Postgres tables that exactly mimic the Firestore JSON structure to achieve immediate compilation and functional parity.

### Phase 3: Schema Normalization, Refactoring & UI Adjustments
This phase specifically targets and eliminates the bad NoSQL habits currently plaguing the app.

1. **Eliminate N+1 Queries (Client-Side Joins)**:
   * *Current:* `OneTimeDepositRepository` fetches all deposits, then we fetch the entire `Customers` collection to look up `customerName` for the UI.
   * *New:* Use Supabase's built-in GraphQL-like join syntax: `supabase.from('one_time_deposits').select('*, customers(name)')`. The `SupabaseDepositRepository` will return a complete `Deposit` object that already includes the customer name.

2. **Server-Side Filtering & Sorting**:
   * *Current:* Dart's `.where()` and `.sort()` run on massive in-memory lists.
   * *New:* Update the `getDeposits()` repository method to accept `filter` and `sort` arguments. Use Supabase query builders: `.eq('status', filterStatus)` and `.order('created_at', ascending: false)`.

3. **Server-Side Pagination (UI & State Architecture)**:
   * *Current:* Unbounded `.snapshots()` streams filling a basic `ListView.builder` managed by Riverpod `$StreamNotifier`s.
   * *Targets:* `CustomerListScreen`, `RecurringDepositListScreen`, `OneTimeDepositListScreen`.
   * *New:* Implement the `infinite_scroll_pagination` package (Option B). 
     * **Architecture shift:** The Riverpod controllers will no longer hold the entire list of deposits. The UI will hold a `PagingController`, and the Riverpod repository will expose a Future-based `fetchPage(pageKey, searchCriteria)` method. When the user changes a filter or sort option, the UI simply calls `pagingController.refresh()`, triggering a new fetch from page 0 with the updated criteria. Riverpod will pivot to managing single-entity states (CRUD operations) and search criteria states.
     * **UI States:** We will reuse our existing empty state/error widgets for the `PagingController`. We only need to provide a simple generic `firstPageProgressIndicatorBuilder` (loading spinner) and `noItemsFoundIndicatorBuilder` (the existing "No records found" illustration).

4. **Search**: Replace local substring search filtering with native Supabase `.ilike('name', '%query%')` filters.
5. **Loading State & Error Handling**: 
   * **Mutation Loading**: Introduce a global or local `LoadingOverlay` widget that wraps forms during `.save()` operations (removing optimistic UI updates).
   * **Network Resilience**: Wrap all repository mutations in a try-catch for `SocketException` and `PostgrestException`. Since we are online-only (V1), network failures during a session will return a `Result.error`. The UI must catch this and show a highly visible SnackBar (e.g., "Network error. Please try again.") and keep the user's form data intact so they can retry.
   * **Cold Boot Offline Screen**: We will inject a global `ConnectivityBuilder` at the `MaterialApp` builder level. If there is no internet on boot, a full-screen `Scaffold` blocking overlay is shown, preventing access to the router.
6. **Normalize SQL**: Write SQL migrations to cast `TEXT` status columns to strict `ENUM` types.
7. **Model Updates for Joins**: Add `@JsonKey(includeFromJson: true, includeToJson: false) String? customerName` to the `OneTimeDeposit` and `RecurringDeposit` Freezed models. This allows the Dart models to safely receive the `customerName` from the Supabase `JOIN` query without trying to write it back to the database on save.

### Phase 4: Data Migration & "Big Bang" Launch
*(Note: Codebase review confirms zero usage of Firebase Storage or Cloud Functions, so the migration is strictly limited to Auth and Firestore text/number data).*

1. Ensure the isolated branch has reached parity with the live app (plus the new SQL superpowers).
2. **The Admin Migration App (Flutter)**: Instead of a backend Node.js script, we will build a dedicated Flutter migration screen (e.g., `lib/run_supabase_migration.dart`) mimicking the existing `run_migration.dart` pattern.
   * *Why Flutter:* This allows us to 100% reuse our existing `FirebaseCustomerRepository` and `SupabaseCustomerRepository` implementations and Freezed models, minimizing mapping bugs.
   * *Execution Environment:* **CRITICAL:** This migration app MUST be compiled and run as a **macOS/Windows desktop app** or run on the **iOS/Android Simulator**. It CANNOT be run as a pure Dart CLI, because `cloud_firestore` requires a native Flutter engine to initialize.
3. **Execution**:
   * Announce maintenance window to the < 5 active users.
   * **Firestore Security Rules (Manual)**: Temporarily update `firestore.rules` in the Firebase Console to allow `read` access to the entire database for the admin's UID during the migration window, otherwise the Flutter client SDK will be blocked by `Permission Denied` errors.
   * **Auth UID Mapping (The OAuth Fix)**: Since we cannot pre-create OAuth users via the Supabase Admin API inside a Flutter app, we will use an **Email-to-UID JIT Mapping** strategy:
     1. **Export Users (Manual)**: Export Firebase Auth users to a JSON file via Firebase CLI (`firebase auth:export users.json`).
     2. The Dart migration app reads this JSON and creates placeholder `agent_profiles` using standard `uuid-v4`s for the `id`, and saves the 28-char string in `legacy_firebase_uid`.
     3. Insert the Customers and Deposits into Supabase using the newly generated `agent_profiles.id` UUIDs (mapped in-memory via the legacy UID).
     4. Build a one-time "JIT (Just-in-Time) Migration Trigger" in the new app's Auth controller. When a user logs into Supabase for the first time, Supabase creates their `auth.users` row. The app then calls a secure Postgres RPC function that matches their email to the `agent_profiles` table and updates `agent_profiles.id` to match the newly generated `auth.users.id` (cascading the update to all their customers and deposits).
   * **Admin Auto-Provision**: The script must explicitly find `itisdarshan@gmail.com` and immediately run an `.rpc()` or direct SQL insert to add it to the `user_roles` table with the `admin` role.
   * **Data Translation & Dirty Data**: Fetch all Customers and Deposits from Firestore. 
     * *Dirty Data Strategy:* The Dart script must cast loose Firestore data (e.g., numbers stored as strings) into strict Postgres types before insertion. 
     * *Normalization Mapping:* As the script iterates over Firestore deposits, it must map the nested `nominees` list into separate `INSERT` commands for the new `nominees` relational table, ensuring foreign keys point back to the parent deposit UUID. Similarly, `savingsAccount` maps to the new `savings_accounts` table.
     * *Fallbacks:* If a row is missing a critical field, use sensible defaults to ensure zero data loss:
       * `startDate`: default to `createdAt` timestamp.
       * `status`: default to `'active'`.
       * `scheme_type`: default to `'td'` (for One-Time) or `'rd'` (for Recurring).
     * Insert them into the new Postgres tables using the mapped UUIDs.
4. Merge the isolated branch into `main`.
5. **The Firebase Purge**: Remove `cloud_firestore` and `firebase_auth` from `pubspec.yaml`, delete the `Firebase*` repository implementations, and clean up the Riverpod toggles.
6. **Play Store Deployment Readiness (Manual)**: 
   * Retain `google-services.json` in the Android build since we are keeping Firebase Crashlytics and Analytics.
   * Ensure the **SHA-1 and SHA-256 fingerprint certificates** from your Play Console (App Signing) are added to *both* the Firebase Console (for Analytics) AND the Google Cloud Console (for generating the Web Client ID used by Supabase Auth). If this is missed, Google Sign-In will silently fail in the production APK.
7. Update production API keys in the Flutter app and deploy the massive Supabase update to the Play Store.

---

## 4. Future Roadmap & Upcoming Features

With a relational database in place, the following features become significantly easier to implement natively:

1. **Monthly RD Transaction Tracking**: Natively supported by the new `rd_transactions` table. We can easily run SQL queries to find "RDs missing payments for the current month".
2. **Maturing/Expiring Reminders**: We can use Supabase **Edge Functions + pg_cron** to run a daily script at midnight that queries `SELECT * FROM deposits WHERE maturity_date = CURRENT_DATE + 30`. It can then send push notifications via Firebase Cloud Messaging (FCM).
3. **Advanced Financial Dashboards**: SQL enables hyper-efficient queries like charting MoM (Month-over-Month) growth or breaking down commissions by scheme type without downloading a single underlying row to the device.
4. **Offline Mode**: Evaluate implementing [PowerSync](https://www.powersync.com/) (a Postgres-to-SQLite sync engine) to restore the offline-first capability lost by moving away from Firebase.
