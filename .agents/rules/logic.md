# Logic & Purity Conventions

## 1. Immutability & Data Modeling
- **Freezed**: Use for all data classes and state unions.
- **Sealed Classes**: Always use `sealed class` for Freezed models to ensure exhaustive pattern matching.
- **Immutability**: Never mutate state in place; always use `copyWith`.

## 2. Enums and JSON Serialization
- **Case and Format Parity**: Ensure that serialization casing (camelCase, snake_case, PascalCase) matches consistently across all models and the database. By default, enums in the codebase serialize to `camelCase` (e.g. `OneTimeSchemeType`, `DepositStatus`). Ensure new enums align with this standard unless explicit database rules dictate otherwise.
- **Dangers of raw `.name` in DB payloads**: Avoid using the raw Dart `.name` property when serializing enums for database payloads. A refactor or a different serialization configuration (like `@JsonEnum` renaming) will cause silent runtime validation failures or database check constraint violations. Always serialize enums using their designated serialization method (e.g., `.toJson()`) or map them cleanly through model-level serialization.
- **Brain & Muscle Separation**: Business rules, sequential workflows, allocations, and dynamic mathematical logic (The Brain) belong in pure, highly-testable client-side Dart files. The database schema, indexes, and cascades (The Muscle) are responsible for data integrity, atomicity, and performance. Do not leak complex domain calculations or client-side business rules into PostgreSQL database triggers.

## 3. Modern Dart 3 Features
- Use native **Records**, **Pattern Matching**, and **Sealed Classes** for error handling.
- Prohibited: Heavy functional packages like `dartz`.

## 3. Business Logic
- **Pure Functions**: Keep logic in pure functions inside Notifiers or separate domain classes.
- **Error Handling**: Controllers should return typed `Result<Success, Error>` records instead of throwing exceptions.
- **Validation**: Use factory constructors on Freezed models for validation (e.g., `Model.create()`).

## 4. Hooks
- Use `flutter_hooks` to extract complex screen logic (e.g., form validation) from the UI layer.
