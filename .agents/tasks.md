# Project Tasks & Roadmap

*Note: For a summarized history of past work, see `.agents/historical_summary.md` and `.agents/progress.md`. For the raw chronological task history, see `.agents/historical_tasks_archive.md`.*

## 🚀 Next Up (High Priority: Firestore Quota Fixes)
- [ ] **Denormalize Customer Data**: Add `customerName` to Deposits to avoid N+1 queries.
- [ ] **Pagination**: Implement Server-Side Pagination & Infinite Scrolling UI (`limit()`, `startAfterDocument()`).
- [ ] **Search/Sort Refactor**: Move Filtering/Sorting to Server-Side (Firestore `orderBy` and Prefix Search).
- [x] **Web Support**: Enable Firestore Web Offline Persistence.

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
