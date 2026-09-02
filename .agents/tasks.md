# Project Tasks & Roadmap

*Note: For a summarized history of past work, see `.agents/historical_summary.md` and `.agents/progress.md`. For the raw chronological task history, see `.agents/historical_tasks_archive.md`.*

## 🚀 Next Up (Supabase Migration - Phase 2 & 3)
- [x] **Bulk Migration Optimizer**: Redesigned sequential N+1 writes into batch/bulk insertions, reducing network roundtrips by up to 99.5% and accelerating bulk data migrations (e.g., 600+ records) by 100x+.
- [x] **Environments**: Add `GOOGLE_WEB_CLIENT_ID` and `GOOGLE_IOS_CLIENT_ID` to `.env`.
- [x] **Freezed Snake Case**: Update all Freezed models with `@JsonSerializable(fieldRename: FieldRename.snake)`.
- [x] **Date Conversion**: Update `@TimestampConverter()` to support both Firebase and Supabase.
- [x] **Interfaces**: Define abstract interfaces for all repositories.
- [x] **Parallel Repositories**: Create `Supabase*Repository` implementations alongside `Firebase*Repository`.
- [x] **Riverpod Toggle**: Implement provider overrides based on `Env.useSupabase`.
- [x] **SQL Views & RPC Procedures (Option 2 Architecture)**: Create SQL migrations for views (`customer_details_view`, `one_time_deposit_details_view`, `recurring_deposit_details_view`) and stored procedure RPCs (`save_customer_with_sb_account`, `save_one_time_deposit`, `save_recurring_deposit`). Refactor all `Supabase*Repository` implementations to use views for reads and RPCs for 100% atomic writes.
- [ ] **Automated Database Backups to Google Drive**: Set up scheduled GitHub Action / cron job with `supabase db dump` to automatically export and upload daily database backups to Google Drive.

## ⚡ Supabase Query Optimizations (Prioritized)
- [x] **P1: Server-Side Joins for Deposit Customer Names**: Modify `one_time_deposit_details_view` and `recurring_deposit_details_view` views to join with the `customers` table and return `customer_name`. Add `@JsonKey(includeFromJson: true, includeToJson: false) String? customerName` to deposit models to eliminate client-side cross-fetching/map loops.
- [ ] **P1.1: Migrate to Two Channels CQRS Pattern**: Refactor the data & domain models to use separate, direct channels for reads vs writes, eliminating **Domain Pollution** and avoid mapping overhead (never decoupling/recombining views).
  - *Architectural Design:*
    - **Read Channel (Direct & Pragmatic)**: Database View (`one_time_deposit_details_view`) maps 1-to-1 to a read-only Presentation DTO (`OneTimeDepositWithCustomer`). The repository queries the view and outputs the DTO straight to the UI. The core write domain entity is never touched during reads.
    - **Write Channel (Pure & Controlled)**: UI Form maps to a pure domain model (`OneTimeDeposit` — stripped of `customerName`) to enforce domain calculations and logic validation (`OneTimeDeposit.create(...)`). The repository sends this pure model to the database write RPC (`save_one_time_deposit`).
  - *Benefits to achieve:*
    - **No Mapping Trap**: Eliminates complex intermediate mapping where fields are split and recombined.
    - **Strict Boundaries**: Core entities remain 100% focused on business logic/writes. Read-only DTOs represent exact screens.
    - **Performance & Safety**: No fallback checks, clean and fast JSON parsing directly from database views, and zero state desynchronization.
- [x] **P2: Filter Real-Time CDC Streams by Agent ID**: Update repositories to filter change streams using `.stream(...).eq('agent_id', _userId)` instead of listening to all database-wide table changes.
- [ ] **P3: Server-Side Searching, Filtering, and Sorting**: Offload sorting, filtering, and search matching to PostgREST/Supabase query builders instead of pulling entire tables into Dart in-memory lists.
- [ ] **P4: Server-Side Pagination**: Implement offset/limit pagination using Supabase's `.range()` builder paired with `infinite_scroll_pagination` on list screens to cap memory/RAM usage.
- [ ] **P5: Database Fuzzy Search Indexes**: Enable `pg_trgm` extension and create GIN trigram indexes on text search targets (e.g. `idx_customers_name_trgm` on `customers(name)`) to avoid CPU-intensive sequential table scans.
- [ ] **P6: Upgrade Client UUID Generation to UUIDv7**: Migrate the client-side `uuid` package to use time-ordered v7 UUIDs (`Uuid().v7()`) to prevent index B-tree fragmentation on insertion.

## 📦 Release & Publication (Play Store)
- [x] **Change Application ID**: Update `applicationId` in `android/app/build.gradle.kts` (e.g., to `dev.darshanas.postfolio`).
- [x] **Android Product Flavors (Staging & Prod)**: Configured `staging` (`.staging` package suffix, "Postfolio Staging") and `prod` ("Postfolio") flavors for side-by-side device installation and independent testing.
- [x] **Distinguishing Staging & Prod App Icons**: Configured flavor-specific app icons generated via `flutter_launcher_icons`. Staging icon features a prominent orange banner and "STAGING" badge to clearly distinguish from the production icon.
- [ ] **Native Splash Screen**: Implement using `flutter_native_splash`. (Skipped for initial internal testing)
- [x] **Production Keystore**: Generate release JKS and configure `key.properties`. (Placeholder `key.properties` created and `build.gradle` updated)
- [ ] **Firebase Production**: Configure production project, update `google-services.json`, and enable **App Check** (Security Hardening).
- [x] **Store Assets**: Prepare screenshots, feature graphic, and metadata. (Placeholder directory and checklist created)
- [x] **Privacy Policy**: Host and link the privacy policy. (Placeholder created)
- [x] **AAB Build**: Run `flutter build appbundle` for release. (v1.5.1+15 built and successfully deployed to Internal Testing)

## 🧮 Domain Math & Business Logic
- [ ] **KVP Term DB Sync**: Decide whether to sync the dynamically calculated KVP term to the database (`termYears`/`termMonths`) or skip storing it entirely and rely purely on the dynamic calculation.
- [ ] **Commissions**: Auto-calculate Gross Commission, deduct 2% TDS, and derive Net Payout.
- [ ] **Penalties & Rebates**: Calculate RD Late Fees and Advance Deposit Rebates.
- [ ] **Premature Closure (RD)**: Prompt user for penalty interest rate and show the premature withdrawal amount.
- [ ] **Premature Closure (General)**: Implement early withdrawal calculation logic for all applicable schemes.
- [ ] **Data Integrity**: Implement `isDeleted` flag (Soft Deletes) to prevent orphaned records for Customers and Deposits.

## 📊 Dashboard & Analytics
- [x] **Core Dashboard**: Implemented dashboard with aggregated metrics, active/total breakdowns, and interactive `fl_chart` data visualizations.
- [x] **Financial Year Charting**: Switched the "Deposits Over Time" graph to map and display using the Indian Financial Year (e.g. "FY 23-24") starting in April.
- [x] **Chart Drill-Down**: Added month-level drill-down interaction to the Financial Year chart with a 'Back to Years' UI.
- [ ] *Reserved for future dashboard widgets and analytics (e.g. commission estimates, maturing soon lists).*

## 🎨 UI/UX Polish & Features
- [ ] **Design Inspiration**: Refer to [flutterpro.design](https://flutterpro.design) for small details and micro-interactions that build "taste" in Flutter.
- [ ] **Nominee UI Overhaul**:
  - [ ] Update to an input widget/slider that strictly enforces the 100% rule.
  - [ ] Organize SB account number and associated nomination into a single cohesive UI section.
  - [ ] Ensure the relationship of each nominee is clearly displayed.
- [x] **Preferences**: Persist sort/filter selections and `maturityWarningDays` across sessions.
- [ ] **Visual Enhancements**:
  - [ ] Redesign leading visual elements in deposit list tiles (replace generic circular icons).
  - [ ] Apply distinct color coding for deposit types.
  - [x] Enhance visual prominence of scheme type in detail views and forms (Migrated Dropdowns to Segmented Buttons).
  - [x] Form inputs correctly format currency strings and auto-display localized amount in words.
  - [ ] Add relative time display (`timeago`).
  - [ ] Implement dark theme support.
- [ ] **Media**: Implement image capture and display for customer profiles.
- [x] **Routing UX**: Re-evaluate context-aware "back" navigation (e.g., Detail -> List vs Detail -> Home).
- [ ] **Predictive Back Gesture**: Add predictive back gestures. The last trial had issues between customer detail page to customer list page.
- [ ] **Minor Fixes**: Remove duplicate display of RD interest rate; replace `FilledButton` with `AppButton` (if deemed necessary).

## ⚙️ Architecture, Tooling & Security
- [x] **Agent Customization**: Refactored guidelines into a modular rule system in `.agents/rules/` for improved agent compliance and platform-agnosticism.
- [x] **Modern Android & Gradle Ecosystem Migration**: Upgraded project to use modern Android tooling: Gradle 9.5.1, AGP 9.3.0, Kotlin 2.3.20, and modern Firebase plugins (google-services 4.5.0, firebase-perf 2.0.2, firebase-crashlytics 3.0.8). Fully migrated to **Built-in Kotlin** (`android.builtInKotlin=true`), eliminating KGP-related deprecation warnings, and enabled AGP 9.0+ resource value compatibility.
- [ ] **Linting**: Add `riverpod_lint` and `custom_lint` for static analysis.
- [ ] **Firebase App Check**: Configure with Play Integrity/App Attest and local Debug Tokens.
- [ ] **Firebase Remote Config**: Integrate for dynamic rates, version enforcement, and feature flags.
- [ ] **Analytics & Tracing**: Add Firebase Analytics wrapper, `GoRouter` observer, and custom Performance traces.
- [ ] **Native Integration**: Integrate `share_plus` (reports), `flutter_native_splash` (splash screen), and Local App Lock (Biometrics/PIN).
- [ ] **Value Objects**: Explore migrating `termYears`/`termMonths` into a custom Domain-Driven Value Object.
- [ ] **Unique Email Guardrails**: Enforce a case-insensitive unique email constraint on `agent_profiles` at the DB level, and intercept constraint violations (PostgreSQL error code `23505`) in the repository/controllers to present clean user-facing error messages.

## 📱 Future Epics
### Epic: Responsive Architecture
- [ ] Add `flutter_adaptive_scaffold`.
- [ ] Implement adaptive navigation (BottomNavigationBar vs NavigationRail).
- [ ] Create Master-Detail layouts for large screens.
- [ ] Conditionally render `BottomSheet` as `AlertDialog`/Side Panel on large screens.

### Epic: Firebase Elimination
- [ ] Complete codebase cleanup of Firebase dependencies (`firebase_core`, `firebase_auth`, `cloud_firestore`).
- [ ] Remove legacy `Firebase*Repository` classes and the `Env.useSupabase` toggle strategy.
- [ ] Clean up redundant fallback `customerMap` logic in `one_time_deposits_controller.dart` and `recurring_deposits_controller.dart` once pre-joined database views are the sole source of truth.

### Epic: Agent Profile
- [ ] Expand `AppUser` to include personal/agency details.
- [ ] Build `AgentProfileRepository` and `AgentProfileController`.

---

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
