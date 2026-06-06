# Architecture & Infrastructure Conventions

## 1. State Management & DI
- **Riverpod**: Use `Notifier` or `AsyncNotifier` (via `@riverpod` generator).
- **Dependency Injection**: All services, repositories, and Firebase instances must be provided via Riverpod. No static singletons.
- **Feature-First Structure**: `lib/features/<feature>/` with `data`, `domain`, and `presentation` layers. Layers must be isolated.

## 2. Routing (go_router)
- **Navigation Policy (`go` vs `push`)**: 
  - **`go()` (Declarative/Logical Navigation)**: Replaces the current navigation stack to match the exact route hierarchy defined in the router configuration. 
    - **Use for**: Primary navigation (Tabs, Shell routes, Auth redirects), Deep Linking, and horizontal structural movement.
    - **Why**: Perfect for Web Deep Linking and predictable state. Required for Bottom Navigation.
  - **`push()` (Imperative/Temporal Navigation)**: Adds the new route strictly on top of whatever the current stack is.
    - **Use for**: Master-Detail Flow (List -> Item), Forms, Data Entry, and vertical hierarchical movement.
    - **Why**: Perfect for Mobile UX. The hardware back button or swipe-to-go-back gesture (Predictive Back on Android) will take the user exactly back to where they were.
- **Deep Links**: Do not pass complex objects via `extra`. Pass primitive IDs in the URL to ensure Web Deep Links don't break on page refresh.
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
