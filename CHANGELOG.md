# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.1+15] - 2026-06-07

### Added
- **Customer**: Added multiline notes field to customer profiles for unstructured metadata.
- **Forms**: Added numeric word translation and robust currency formatting.

### Changed
- **Dashboard**: Show full amount in dashboard chart tooltips.

## [1.5.0+14] - 2026-06-07

### Added
- **Dashboard**: Built analytics dashboard screen with aggregated metrics and interactive charts.
- **Dashboard**: Mapped "Deposits Over Time" chart to use the Indian Financial Year.
- **Dashboard**: Added month-level drill-down functionality to the Financial Year chart.
- **Firestore**: Enabled offline persistence for the Web platform to support cache reading.

### Changed
- **UI/Deposits**: Migrated SchemeType selection from dropdowns to standard M3 Segmented Buttons.
- **UI/Dashboard**: Improved chart formatting by slanting x-axis labels and enhancing button styling.
- **UI/Nominees**: Standardized `NomineesInputSection` layout and spacing.
- **Routing**: Migrated form routing to use temporal push/pop navigation, restoring predictive back gestures.

### Refactored
- **Domain/Deposits**: Extracted and decoupled default sorting logic into domain models.
- **Storage**: Aligned `StorageService` default values with domain models to fix initial UI inconsistencies.

## [1.4.0+13] - 2026-06-03

### Added
- **Architecture**: Implemented type-safe composite sorting architecture.
- **UI/UX**: Added "Reset" button to Sort BottomSheet.
- **Preferences**: Persisted user preferences for sorting and themes.
- **Agent Workflow**: Added release management framework and modular agent rule system.

### Changed
- **UI/UX**: Comprehensive Material 3 UI/UX improvements.
- **Docs**: Consolidated markdown documentation and architecture guidelines.

## [1.3.2+12] - 2026-06-02

### Added
- **RD**: Update default RD list sort to serial number descending.

### Changed
- **UI**: Unify entity list cards and fix deposit sorting.
- **UI/Customers**: Group closed deposits under collapsible history.

### Fixed
- **UI**: Add FAB padding to entity detail scaffold.

## [1.3.1+11] - 2026-06-01

### Added
- **Theming**: Integrated Material Monet dynamic theming.

### Fixed
- **UI Rendering**: Fixed interest rate being incorrectly rounded and displayed as currency.
- **Theming**: Enforced strict accessible theme isolation from dynamic colors.

## [1.3.0+10] - 2026-06-01

### Added
- **Theme Accessibility**: Added accessible color-blind mode with Wong/Tol palette.
- **Deposit Management**: Added quick toggle for Close/Reopen deposit status directly in UI.

### Changed
- **Theming**: Migrated to Material 3 dynamic theming and decoupled static colors.
- **UI Architecture**: Categorized core widgets into sub-folders, extracted `AccessibleThemeToggle`, `ShellAppBar`, and hooks for form components.
- **Conventions**: Updated architecture documentation and enforced Dart 3 pattern matching.

### Fixed
- **UI Rendering**: Refactored `DemoBanner` to use official `MaterialBanner` to prevent theme transition lag.

## [1.2.0+9] - 2026-05-31

### Added
- **Contextual Creation**: Added Speed Dial to Customer Detail page for quick adding of Recurring and One-Time Deposits.
- **Advanced Sorting**: Added ability to sort customers by "Newest First" and "Oldest First" using audit timestamps.
- **Audit Tracking**: Integrated `createdAt`, `updatedAt`, and `migrationSource` into all domain models for better data lineage.
- **Security**: Updated Firestore rules to grant administrative access based on verified email.

### Changed
- **UI Consistency**: Unified FAB and SpeedDial colors and behaviors across all screens for a more cohesive experience.
- **Firestore Layer**: Refactored data layer to use `withConverter` for type-safe document interaction.
- **Migration Tool**: Enhanced CSV parsing logic and added automatic emulator detection.

### Fixed
- **UI/UX**: Resolved a "double inset" keyboard layout bug in Demo Mode.
- **Code Quality**: Resolved several linting and static analysis warnings.

## [1.1.2+8] - 2026-05-31

### Added
- **Firebase Infrastructure**: Integrated Firebase App Distribution / Release Monitoring.
- **Firebase Performance Monitoring**: Added tracing capabilities to monitor app performance.
- **Global Error Reporting**: Integrated Firebase Crashlytics to catch and report errors globally.
- **License**: Added MIT License to the project.
- **Dependabot**: Added Dependabot configuration for automated dependency updates.

### Changed
- **Web App**: Configured Web PWA, limited Firebase hosting releases, and capitalized app name.

## [1.1.1+7] - 2026-05-31

### Added
- **Web App Hosting**: Officially deployed the Flutter web application to Firebase Hosting with full Single Page Application (SPA) routing support for `go_router`.
- **Unified CI/CD**: Upgraded GitHub Actions (`release.yml`) to automatically build and deploy both Mobile (Android APK) and Web applications concurrently whenever a release tag is pushed, ensuring strict feature parity across platforms.

## [1.1.0+6] - 2026-05-31

### Changed
- **UI/UX Polish**: Standardized `AppBar` styling and removed hardcoded typography across the app.
- **Entity Lists**: Streamlined customer card actions and entity list tile layouts, tightening action button spacing.
- **Deposit Cards**: Improved maturity date layout, trailing layout constraints, and status badge visibility.
- **Domain Refactor**: Removed redundant `matured` state from `DepositStatus` and renamed `MaturityUrgency`'s `overdue` to `matured` for cleaner domain logic.

### Fixed
- **Customer Intents**: Hid intent actions (SMS, Phone, WhatsApp) for customers when contact information is missing and fixed native intent launching.
- **Android Builds**: Resolved CI build issues and KGP deprecation warnings for Android.
- **Demo Mode**: Corrected random deposit status generation based on chronological maturity when testing with fake data.

## [1.0.4+5] - 2026-05-25

### Added
- **The "Who Owes Me Money" CRM:** Complete customer management capabilities. The brand-new Customer Profile automatically gathers all One-Time and Recurring Deposits into a single view.
- **Smart Domain Math Engine:** Pure, functional `ProjectionCalculator` now automatically computes maturity amounts, compounding interest, and dynamic "Doubles In" metrics (for KVP).
- **Mini Wall Street Projections:** Added a dynamic `InvestmentProjectionCard` to deposit forms featuring live, stock-ticker-style animations.
- **Rural Internet Survival Kit:** Integrated Firebase Cloud Firestore fully optimized for offline-first usage. The app syncs automatically when a connection is restored.
- **Strict Data Privacy:** All Firestore queries are strictly scoped to the user's `userId`, ensuring zero cross-agent data leakage.
- **Commitment-Free Demo Mode:** Toggle "Demo Mode" on the login screen to bypass authentication and use the app with fake repositories and dummy data.
- **The "Math Police" Validation:** Strictly enforce that Nominee percentage allocations sum exactly to 100%. Added auto-formatting for Rupees, Phones, Aadhaar, and PAN cards.
- **Search, Filter & Sort:** Added a premium Material 3 `SearchBar` across all listing screens, complete with slide-up bottom sheets for quick filtering and sorting.
- **Time-Travel Data Migration:** Robust Flutter-based migration utility (`run_migration.dart`) that parses old CSV ledgers and bootstraps them to Firestore.

### Changed
- **Evicted StatefulWidget:** Replaced all usages of `StatefulWidget` with `flutter_hooks` and `hooks_riverpod` for ephemeral UI state.
- **Form Build Method Diet:** Removed string parsing and mathematical logic out of the UI and moved it into Notifiers and Domain classes.
- **Design System Glow-Up:** Centralized colors, typography, and spacing into a robust `AppTheme`. Deduplicated shared widgets (`AppTextField`, `SegmentedButton`).
- **Fairy Dust & Polish:** Added `flutter_animate` for screen transitions, `skeletonizer` for loading states, and swapped out icons for premium `hugeicons`.
- **Polyglot Formatting:** Integrated `slang` for strict, typed internationalization, centralizing text strings and standardizing date formatting.
- **Developer Experience:** Hooked up local Firebase Emulators (Auth & Firestore) for local development, and documented conventions in `AGENTS.md`.

### Fixed
- **Declarative Routing Therapy:** Replaced `.push()` with strictly declarative `.go()` routing to resolve GoRouter exceptions (`ImperativeRouteMatch.complete`) when using the system back button.
- **Migration Identity Crisis:** Fixed the CSV migration tool so an empty account number doesn't incorrectly flag a row as a duplicate clone.
- **Unauthenticated Existential Dread:** Fixed an issue where the app would crash or pause the debugger if launched without being logged in.
- **Appeasing the Google Sign-In Gods:** Resolved "Account reauth failed" errors on Android by establishing proper SHA-1 debug key registration protocols for multi-machine setups.
- **UI Botox:** Reduced oversized form icons, fixed text truncation on list tiles, and realigned paddings.
- **Domain vs. UI Couples Counseling:** Stripped out rogue invalid properties (e.g., `linkedSavingsAccount`) from domain models and visually enforced `isRequired` fields on UI forms.
- **Sign in issues:** Added a keystore step in the release `yml` to resolve app signing issues causing sign-in failures on distributed builds.

## [1.0.3+4] - 2026-05-15

### Added
- Initial test release.

[1.1.2+8]: https://github.com/Darshan-AS/postfolio/compare/v1.1.1+7...v1.1.2+8
[1.1.1+7]: https://github.com/Darshan-AS/postfolio/compare/v1.1.0+6...v1.1.1+7
[1.1.0+6]: https://github.com/Darshan-AS/postfolio/compare/v1.0.4+5...v1.1.0+6
[1.0.4+5]: https://github.com/Darshan-AS/postfolio/compare/v1.0.3+4...v1.0.4+5
[1.0.3+4]: https://github.com/Darshan-AS/postfolio/releases/tag/v1.0.3+4
