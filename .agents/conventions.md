# Postfolio Conventions
- State Management: Riverpod
- Paradigm: Functional programming (immutability via freezed, pure functions)
- Dependency Injection: Handled via Riverpod
- UI: Dumb widgets, feature-first architecture, cross-platform seamless UI.
- Error Handling: Native Dart 3 Records, Pattern matching, and Sealed classes (Always use `sealed class` for Freezed models).
- Validation: Extensions and Factories (Avoid primitive Value Objects).
- Routing: go_router
- Database: Firebase/Firestore (Using native offline persistence, no local DB).
- Folder Structure: Feature-first with inner Layered Architecture (data, domain, presentation).
