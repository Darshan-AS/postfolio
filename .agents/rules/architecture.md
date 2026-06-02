# Architecture & Infrastructure Conventions

## 1. State Management & DI
- **Riverpod**: Use `Notifier` or `AsyncNotifier` (via `@riverpod` generator).
- **Dependency Injection**: All services, repositories, and Firebase instances must be provided via Riverpod. No static singletons.
- **Feature-First Structure**: `lib/features/<feature>/` with `data`, `domain`, and `presentation` layers. Layers must be isolated.

## 2. Routing (go_router)
- **Declarative Navigation**: Prefer `.go(context)` for routes in the URI hierarchy.
- **Imperative Navigation**: Use `.push(context)` only for overlays or when awaiting a result.
- **Keyboard Handling**: Let the outer `Scaffold` handle resizing. Use a `Builder` inside the body if `MediaQuery` modification is needed.

## 3. Backend (Firebase)
- **Firestore**: Primary DB. Use native offline-persistence.
- **Repository Pattern**: Repositories must convert Firestore DTOs to pure Domain Entities.
- **Auth Guards**: All repo operations must check for authentication.
- **Offline-First**: Do not always `await` Firestore writes if immediate UI feedback is preferred.
- **Client-Side IDs**: Generate UUIDs on the client before saving to Firestore.

## 4. Local Storage
- Use `SharedPreferences` (wrapped in `StorageService`) only for non-sensitive UI state (theme, onboarding).
- Prohibited: `flutter_secure_storage`, `hive_ce`, `isar`, `drift`.
