# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.1+7]: https://github.com/Darshan-AS/postfolio/compare/v1.1.0+6...v1.1.1+7
[1.1.0+6]: https://github.com/Darshan-AS/postfolio/compare/v1.0.4+5...v1.1.0+6
[1.0.4+5]: https://github.com/Darshan-AS/postfolio/compare/v1.0.3+4...v1.0.4+5
[1.0.3+4]: https://github.com/Darshan-AS/postfolio/releases/tag/v1.0.3+4
