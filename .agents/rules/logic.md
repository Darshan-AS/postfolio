# Logic & Purity Conventions

## 1. Immutability & Data Modeling
- **Freezed**: Use for all data classes and state unions.
- **Sealed Classes**: Always use `sealed class` for Freezed models to ensure exhaustive pattern matching.
- **Immutability**: Never mutate state in place; always use `copyWith`.

## 2. Modern Dart 3 Features
- Use native **Records**, **Pattern Matching**, and **Sealed Classes** for error handling.
- Prohibited: Heavy functional packages like `dartz`.

## 3. Business Logic
- **Pure Functions**: Keep logic in pure functions inside Notifiers or separate domain classes.
- **Error Handling**: Controllers should return typed `Result<Success, Error>` records instead of throwing exceptions.
- **Validation**: Use factory constructors on Freezed models for validation (e.g., `Model.create()`).

## 4. Hooks
- Use `flutter_hooks` to extract complex screen logic (e.g., form validation) from the UI layer.
