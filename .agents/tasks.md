# Project Tasks & Roadmap

*Note: For a summarized history of past work, see `.agents/historical_summary.md` and `.agents/progress.md`. For the raw chronological task history, see `.agents/historical_tasks_archive.md`.*

## 🚀 Next Up (Supabase Migration - Phase 2)
- [ ] **Environments**: Add `GOOGLE_WEB_CLIENT_ID` and `GOOGLE_IOS_CLIENT_ID` to `.env`.
- [ ] **Freezed Snake Case**: Update all Freezed models with `@JsonSerializable(fieldRename: FieldRename.snake)`.
- [ ] **Date Conversion**: Update `@TimestampConverter()` to support both Firebase and Supabase.
- [ ] **Interfaces**: Define abstract interfaces for all repositories.
- [ ] **Parallel Repositories**: Create `Supabase*Repository` implementations alongside `Firebase*Repository`.
- [ ] **Riverpod Toggle**: Implement provider overrides based on `Env.useSupabase`.

## 📦 Release & Publication (Play Store)
- [x] **Change Application ID**: Update `applicationId` in `android/app/build.gradle.kts` (e.g., to `dev.darshanas.postfolio`).
- [ ] **Update App Icons**: Replace default icons with branded adaptive icons (using `flutter_launcher_icons`). (Skipped for initial internal testing)
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
- [ ] **Linting**: Add `riverpod_lint` and `custom_lint` for static analysis.
- [ ] **Firebase App Check**: Configure with Play Integrity/App Attest and local Debug Tokens.
- [ ] **Firebase Remote Config**: Integrate for dynamic rates, version enforcement, and feature flags.
- [ ] **Analytics & Tracing**: Add Firebase Analytics wrapper, `GoRouter` observer, and custom Performance traces.
- [ ] **Native Integration**: Integrate `share_plus` (reports), `flutter_native_splash` (splash screen), and Local App Lock (Biometrics/PIN).
- [ ] **Value Objects**: Explore migrating `termYears`/`termMonths` into a custom Domain-Driven Value Object.

## 📱 Future Epics
### Epic: Responsive Architecture
- [ ] Add `flutter_adaptive_scaffold`.
- [ ] Implement adaptive navigation (BottomNavigationBar vs NavigationRail).
- [ ] Create Master-Detail layouts for large screens.
- [ ] Conditionally render `BottomSheet` as `AlertDialog`/Side Panel on large screens.

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

### Supabase Migration (Phase 1)
- [x] **CLI Init**: Initialized Supabase project using `supabase init`.
- [x] **Docker**: Started local Supabase emulators (`supabase start`).
- [x] **Schema**: Defined initial Postgres schema with RLS policies in `supabase/migrations/`.
- [x] **Dependency**: Added `supabase_flutter` and `envied` to `pubspec.yaml`.
- [x] **Env Config**: Set up type-safe environment management with `Env` class and `.env`.
- [x] **Web Fixes**: Added Passkeys Web SDK to `web/index.html`.
- [x] **Seed**: Created `supabase/seed.sql` for local testing.
