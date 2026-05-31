# Firestore Optimization Plan

## Problem Statement
The application is currently exhausting its daily Firestore quota. A review of the codebase indicates this is caused by:
1. **Unbounded Real-time Streams:** Repositories (`customer_repository.dart`, `recurring_deposit_repository.dart`, `one_time_deposit_repository.dart`) are fetching entire collections using `.snapshots()` without any `.limit()`.
2. **Client-Side Filtering & Sorting:** We are fetching all records to run Dart's `.where()` and `.sort()` locally. Firestore explicitly warns against downloading entire databases to perform client-side substring matching, which burns through document reads rapidly.
3. **Cross-fetching (N+1 style issue):** `filteredRecurringDeposits` and `filteredOneTimeDeposits` depend on the full customer list to look up customer names for searching and sorting.

## Impact
- **Quota Exhaustion:** If a user has 1,000 customers and 1,000 deposits, 2,000 reads occur every time the app starts, the cache clears, or the Web version is reloaded (without offline persistence enabled by default).
- **Performance:** Keeping thousands of models in memory and running heavy Dart `.where()` closures on every keystroke in the search bar causes UI stuttering and high CPU/RAM usage.

## Proposed Steps

### 1. Denormalize Customer Data
- Add `customerName` (and any other search-relevant fields) to the `OneTimeDeposit` and `RecurringDeposit` models. 
- Update the saving logic in the controllers/repositories to populate this name. This eliminates the need to fetch the entire customer list just to display or search deposits.

### 2. Implement Server-Side Pagination
- Refactor the Repositories to use `limit(20)` and `.get()` (or paginated snapshots) alongside `startAfterDocument()` cursors.
- Update the UI to implement "Infinite Scrolling" or a "Load More" functionality to fetch subsequent pages instead of loading everything at once.

### 3. Move Filtering/Sorting to Server-Side
- Replace Dart `.sort()` with Firestore `.orderBy()`. 
- **Note:** This will require creating Composite Indexes in Firebase for combined filters/sorts.

### 4. Implement Server-Side Prefix Search
- Replace Dart's `.contains()` substring matching with Firestore's prefix search (`where('name', isGreaterThanOrEqualTo: query, isLessThan: query + '\uf8ff')`).
- While this restricts searches to word prefixes (e.g., "Joh" finds "John", but "Doe" doesn't find "John Doe"), it is a necessary tradeoff to save quota and perform server-side querying without additional third-party dependencies (like Algolia) or complex token arrays.

### 5. Enable Web Offline Persistence
- Explicitly enable Firestore offline persistence for the Web platform in `main.dart` to prevent full re-reads on every page reload, leveraging the local cache.

## Verification
- Use the Firebase Local Emulator Suite.
- Seed the local database with ~1,000 records.
- Observe the Firestore emulator logs: the document reads should accurately reflect the page size limit (e.g., 20) instead of matching the full collection size.
