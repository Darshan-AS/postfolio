# Postfolio Conventions & Architecture

This document tracks the architectural decisions, structural rules, and conventions for the `postfolio` app.

## 1. Architecture & State Management
- **State Management**: Riverpod (AsyncNotifier / Notifier via riverpod_generator).
- **Dependency Injection**: Handled entirely via Riverpod providers.
- **Folder Structure**: Feature-first with inner Layered Architecture (`data/`, `domain/`, `presentation/`).
- **Routing**: `go_router` combined with `go_router_builder` for type-safe routing.
- **Directory Structure Adjustments**: 
  - Keep the `lib/core/` folder. Do **NOT** bring everything inside it directly into `lib/`.
  - The only folders that should live directly alongside `features/` in `lib/` are: `core/`, `i18n/`, and `main.dart`.
  - Reorganize the `lib/core/` directory to match the following separation of concerns:
    - `lib/core/services/` for infrastructure code (e.g., `storage_service.dart`).
    - `lib/core/extensions/` to centralize Dart extension methods.
    - `lib/core/shared/widgets/` to clearly denote globally reusable UI components.

## 2. Functional Programming & Purity
- **Immutability**: Freezed for all domain models. Never mutate state.
- **Sealed Classes**: Always use `sealed class` for Freezed models to enable exhaustive pattern matching.
- **Modern Dart 3 Features**: Use native Records, Pattern matching, and Sealed classes for error handling and state unions instead of third-party packages (e.g., `dartz`).
- **Domain Validation**: Use extension methods or Smart Factory constructors (`Model.create()`) on Freezed models to return `Result<Model, String>` types to leverage exhaustive pattern matching. Avoid primitive Value Objects.
- **Error Handling**: Controllers must return typed `Result<SuccessType, ErrorType>` records/sealed classes instead of throwing exceptions.
- **Controller Result Matching**: For controller mutation operations (`save`, `delete`), match the result using `switch` on the `Result`. If `Success`, explicitly trigger `ref.invalidateSelf()` and return `Success`. Never manually update the local `state` cache to avoid bugs. Let `build()` fetch the single source of truth from the repository.

## 3. Core Infrastructure & Services
- **Service Wrappers**: Infrastructure code interacting with native device capabilities or external SDKs (e.g., SharedPreferences, Firebase) should be encapsulated in a dedicated Service class inside `lib/core/services/`.
- **Dependency Injection for Services**: Never use static singletons (e.g., `AuthService.instance` or `FirebaseFirestore.instance`). All services and external instances must be provided via Riverpod (`Provider`) to ensure mockability during testing.
- **Local Storage**: Extract `shared_preferences` into `lib/core/services/storage_service.dart` strictly for non-sensitive UI state (e.g., Theme mode, onboarding completion flags). Reject `flutter_secure_storage` and `hive_ce`. Rely entirely on Firestore's native offline-persistence for database caching.
- **Networking**: Reject `dio` and `internet_connection_checker_plus`. Firebase SDKs handle their own optimized network requests and offline caching under the hood. There is no need for a REST API client.
- **Firebase Integration**: Keep Firebase integrations strictly limited to `firebase_core`, `firebase_auth`, and `cloud_firestore` for the foundational build. Reject `firebase_database` and `firebase_storage`. `firebase_crashlytics` and `firebase_analytics` should be added later during the "Enhancements & Refinements" phase. All Firebase instances MUST be provided via Riverpod.
- **Device Interactions**: Reject `image_picker`, `file_picker`, and `permission_handler` to prevent unnecessary bloat. Reject the static singleton "Service Wrapper" pattern (e.g., `ShareService.instance`). Adopt `share_plus` in the future for sharing CRM data via a Riverpod-injected `IntentService`.

## 4. UI & Presentation Layer (After starting to use flutter_adaptive_scaffold. Ignore until then.)
- **Responsive Architecture**: Use the official `flutter_adaptive_scaffold` for structural adaptive layouts (Bottom Navigation Bar on Mobile vs Navigation Rail on Tablet/Desktop), wrapped inside a `go_router` `StatefulShellRoute`. 
- **Large Screen Overlays**: Modal `BottomSheet` invocations on Mobile must dynamically convert to centered `AlertDialog`s or sliding side-panels on Tablet/Desktop.
- **Large Screen Flows**: Use Master-Detail patterns for list views on Desktop (List fixed on the left, details rendered dynamically on the right).
- **Dumb Widgets**: Widgets are purely for displaying data and capturing input. 
- **Ephemeral UI State**: Use `HookConsumerWidget` (via `hooks_riverpod` and `flutter_hooks`) exclusively for managing purely local, ephemeral UI state (e.g., `useTextEditingController`, `useState`). `StatefulWidget` and `ConsumerStatefulWidget` are prohibited.
- **Localization & Magic Strings**: DO NOT hardcode user-facing text, symbols (like `₹`), or separators (like ` • `) directly in the UI. Always use **Slang** (with nested YAML configurations). Extract all "magic strings" into `i18n/`. Avoid raw `Text('...')` strings.
- **Theme, Dimensions & Magic Numbers**: DO NOT hardcode "magic numbers" for breakpoints (e.g., `600`), custom paddings, constraints, or colors anywhere in the UI codebase. Consolidate all styling into a granular file structure inside `lib/core/theme/` (e.g., `AppDimensions`). Use Flutter's `ThemeExtension` API to attach custom design tokens directly to the `ThemeData`. Access them safely via `Theme.of(context).extension<AppDesignTokens>()` and `Theme.of(context).colorScheme`.
- **ScreenUtil**: Reject `flutter_screenutil` (`.w`, `.h`, `.sp`) as it breaks responsive layouts on Web and Desktop. Strip all such dimensions during widget migrations.
- **UI Utilities**: Adopt `skeletonizer` for handling loading states, `flutter_animate` for declarative animations, and `hugeicons` for a cohesive premium icon library (migrating away from Material/Cupertino/FontAwesome). Adopt `cached_network_image` and `flutter_svg` for media handling.
- **App Launch / Splash**: Adopt `flutter_native_splash` utilizing the Hybrid Splash pattern (`preserve()` and `remove()`) to prevent white screen flashes.
- **Code Reuse**: Identify shared UI components early and centralize them in `lib/core/shared/widgets/`. Generic foundational widgets (e.g., `AppButton`, `AppCard`, `AppTextField`) belong here. Domain-specific UI scaffolding (e.g., `EntityDetailScaffold`, `FormAppBar`, `CustomerCard`) belong in `features/` and should utilize the generic widgets internally.

## 5. Anti-Patterns to Avoid
1. **Committing Erroring States**: Never commit code that does not compile or pass the analyzer (`dart analyze`). Always format, build, and analyze before committing.
2. **List Controller Mutation Spoilage**: DO NOT manually set `state = const AsyncValue.loading()` inside mutation methods (like `save()` or `delete()`) within a list controller. This wipes out the data and causes massive UI rebuild bugs (e.g., destroying form state). Handle form submission loading states locally via `useState` in a `HookConsumerWidget`, OR use a separate mutation controller.
3. **Inline Filtering in UI**: Avoid doing complex filtering like `customers.where((c) => c.id == id)` inside `build()`. Create a separate provider or selector (e.g., `customerProvider(id)`) to keep the UI clean.
4. **Riverpod for Form Input State**: Do NOT use Riverpod `Notifiers` to track individual keystrokes or granular text field states. This causes cursor jumping bugs and excessive boilerplate. Text input is *ephemeral UI state*. Use `flutter_hooks` (`useTextEditingController`, `useState`) to manage live form inputs, and only pass structured data to Riverpod controllers on submission. 
5. **Anti-pattern: Riverpod `family` for Keystrokes**: Do NOT pass highly volatile variables (like strings from text controllers) into a Riverpod `@riverpod` family provider. This causes Riverpod to instantiate and destroy a new provider in memory for every single letter typed. To derive live UI state from keystrokes (like math projections), use `useMemoized` alongside pure domain functions. If the pure function requires global dependencies (like tax rates), fetch the dependency via `ref.watch` in the widget and pass it into the `useMemoized` block.

## 6. Git & Commit Conventions
- **Conventional Commits**: All commits must follow the `<type>(<scope>): <summary>` format.
- **Prefixes**: 
  - `Feat`: New functionality.
  - `Fix`: Bug fixes.
  - `Refactor`: Structural changes without behavior change.
  - `Docs`: Updates to documentation, `.agents/` or README.
  - `UI`: Visual-only changes (colors, themes, dimensions).
  - `Chore`: Dependencies, build scripts, configuration.
- **Rules**:
  - Summaries must start with a capital letter.
  - No trailing periods.
  - Use imperative mood ("Add" instead of "Added").
  - Scope should represent the feature (e.g., `customers`, `deposits`, `core`).
