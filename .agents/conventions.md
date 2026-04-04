# Postfolio Conventions

## Architecture & State Management
- **State Management**: Riverpod (AsyncNotifier / Notifier via riverpod_generator).
- **Dependency Injection**: Handled entirely via Riverpod providers.
- **Folder Structure**: Feature-first with inner Layered Architecture (`data/`, `domain/`, `presentation/`).

## Functional Programming & Purity
- **Immutability**: Freezed for all domain models. Never mutate state.
- **Sealed Classes**: Always use `sealed class` for Freezed models to enable exhaustive pattern matching.
- **Modern Dart 3 Features**: Use native Records, Pattern matching, and Sealed classes for error handling and state unions instead of third-party packages (e.g., `dartz`).
- **Domain Validation**: Use extension methods or Smart Factory constructors (`User.create()`) on Freezed models to return `(String? error, Model? data)` tuples. Avoid primitive Value Objects.
- **Error Handling**: Controllers must return typed `Result<SuccessType, ErrorType>` records/sealed classes instead of throwing exceptions.

## UI & Presentation Layer
- **Dumb Widgets**: Widgets are purely for displaying data and capturing input. 
- **Ephemeral UI State**: Prefer `ConsumerStatefulWidget` for managing purely local, ephemeral UI state (e.g., text controllers, focus nodes, form submission loading spinners).
- **Localization (i18n)**: Use **Slang** (with nested YAML configurations). Avoid raw `Text('...')` strings.
- **Theme & Dimensions**: Do not hardcode dimensions or colors. Use centralized `AppTheme`, `AppDimensions`, and `AppSpacings`.

## Anti-Patterns to Avoid
1. **List Controller Mutation Spoilage**: DO NOT manually set `state = const AsyncValue.loading()` inside mutation methods (like `save()` or `delete()`) within a list controller. This wipes out the data and causes massive UI rebuild bugs (e.g., destroying form state).
   *Solution*: Handle form submission loading states locally via `setState` in a `ConsumerStatefulWidget`, OR use a separate mutation controller.
2. **Inline Filtering in UI**: Avoid doing complex filtering like `users.where((u) => u.id == id)` inside `build()`. 
   *Solution*: Create a separate provider or selector (e.g., `userProvider(id)`) to keep the UI clean.
