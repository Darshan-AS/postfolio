# Postfolio Project Guidelines

These guidelines apply to all code generated and modified in this workspace. Adhere to these architectural and design choices at all times.

## Architecture & State Management
- **Riverpod**: Use Riverpod for state management and dependency injection. Prefer `Notifier` or `AsyncNotifier` (or `@riverpod` code generation if set up) over `StateNotifier`.
- **Dependency Injection**: Use Riverpod providers to inject dependencies (e.g., Repositories, Services) into other providers or controllers. This ensures easily mockable and testable code.
- **Feature-First Structure**: Organize code by feature (e.g., `lib/features/auth/`, `lib/features/post/`). Each feature should contain its own `data`, `domain`, and `presentation` layers.

## Functional Programming & Purity
- **Immutability**: Use immutable data structures exclusively. We use the **`freezed`** package for all data classes, state representations, and unions to ensure strict immutability, `copyWith` functionality, and safe JSON serialization. Never mutate state directly in place. **Always declare Freezed classes as `sealed class`** rather than `abstract class` to leverage Dart 3's exhaustive pattern matching and prevent external subclassing.
- **Modern Dart 3 Features**: Avoid heavyweight functional packages like `dartz`. Instead, use native Dart 3 **Records**, **Pattern Matching**, and **Sealed Classes** (via Freezed) for error handling and state unions.
- **Validation**: Avoid over-engineered Value Objects for primitive types. Use extension methods or factory constructors on Freezed models for data validation.
- **Pure Functions**: Keep business logic in pure functions inside your Notifiers/Controllers. State should be replaced with newly computed objects rather than mutated.
- **One-Way Data Flow**: 
  - UI reads state from Providers.
  - UI dispatches intents/events to the Notifier.
  - Notifier computes the new immutable state and updates the Provider.
  - UI rebuilds via `ref.watch`.

## UI & Presentation Layer
- **Dumb Widgets**: Widgets should be completely "dumb". They are strictly responsible for displaying data and capturing user input. Never perform API calls, complex logic, or database operations directly inside a widget.
- **ConsumerWidget**: Prefer `ConsumerWidget` or `ConsumerStatefulWidget` (via Riverpod) over vanilla `StatefulWidget` unless handling ephemeral UI-only state (like an animation controller or a text field focus).
- **Seamless Cross-Platform UI**: Ensure the UI is seamless across all supported platforms (iOS, Android, Web, Desktop). Use responsive design principles (e.g., `LayoutBuilder`, `MediaQuery`) and platform-aware styling where appropriate to ensure the app feels native and polished everywhere.

## Routing & Infrastructure
- **Routing**: Use **`go_router`** for declarative routing without the need for code generation.
- **Backend & Database**: Use **Firebase (Firestore)** as the Backend-as-a-Service. Rely on Firestore's native offline-persistence instead of maintaining a separate local database (like Isar/Drift). All data repositories should interact directly with Firestore.

## Build and Test
{Commands to install, build, test—agents will attempt to run these}

## Agent Memory & Handoff
All progress, tasks, and architectural conventions are stored in the `.agents/` folder. 
**CRITICAL INSTRUCTION FOR ALL AI AGENTS:** 
When starting a new conversation or picking up this repository, you MUST immediately read the following files before making any changes:
1. `.agents/progress.md` (To understand current state and immediate next steps)
2. `.agents/tasks.md` (To understand the project roadmap)
3. `.agents/conventions.md` (To understand strict coding rules)

## Agent Workflow Rules
- **Build Before Commit:** Ensure everything builds successfully before making a commit.
- **Logical Commits:** Commits should only be made at logical stages, and only when the codebase is in a building/working state.
- **Maintain Markdown State:** Keep all markdown files (like `progress.md`, `tasks.md`, `conventions.md`, and `AGENTS.md`) updated based on the conversations so the next agent is fully informed.

## Conventions
{Patterns that differ from common practices—include specific examples}
