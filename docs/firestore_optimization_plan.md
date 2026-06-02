# Firestore Optimization Plan

## Problem Statement
The application is currently exhausting its daily Firestore quota. A review of the codebase indicates this is caused by:
1. **Unbounded Real-time Streams:** Repositories (`customer_repository.dart`, `recurring_deposit_repository.dart`, `one_time_deposit_repository.dart`) are fetching entire collections using `.snapshots()` without any `.limit()`.
2. **Client-Side Filtering & Sorting:** We are fetching all records to run Dart's `.where()` and `.sort()` locally. Firestore explicitly warns against downloading entire databases to perform client-side substring matching, which burns through document reads rapidly.
3. **Cross-fetching (N+1 style issue):** `filteredRecurringDeposits` and `filteredOneTimeDeposits` depend on the full customer list to look up customer names for searching and sorting.

## Resolution
The actionable steps for this plan have been migrated to the project roadmap (`.agents/tasks.md` under **Phase 8: Firestore Optimization**) to ensure they are tracked and executed.
