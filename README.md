# Postfolio

A sophisticated portfolio management application for Small Savings Schemes, built with Flutter, Riverpod, and Firebase.

## Getting Started

For detailed instructions on setting up a new development machine, managing release keys, or recovering from a lost environment, please refer to the **[Setup & Disaster Recovery Guide](docs/setup_guide.md)**.

### Quick Start

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Initialize Firebase (if not already configured):
   ```bash
   flutterfire configure
   ```

---

## Running the Application

### 1. Normal Mode (Production/Cloud Firebase)
Runs the app connected to your live Firebase project.
```bash
flutter run
```

### 2. Emulator Mode (Local Development - Supabase)
Postfolio is currently migrating to Supabase. During this transition, we use local Supabase emulators for development.

**Step A: Start the Emulators**
Ensure Docker is running, then start the Supabase emulators:
```bash
npx supabase start
```

> **Tip**: You can access the **Supabase Studio** (Database UI) at `http://localhost:54323`.

**Step B: Configure Environment**
Copy `.env.example` to `.env` and ensure the local credentials (from `npx supabase status`) are correct.

**Step C: Run the App**
Run the app normally:
```bash
flutter run
```

### 3. Legacy Emulator Mode (Firebase)
*Note: This will be deprecated once the migration is complete.*
... (rest of the firebase section)

### 3. Cleanup & Stopping
To completely stop the emulators and any running Flutter instances (especially helpful if ports are stuck), you can use:
```bash
# Kill Firebase Emulators (silent if no processes found)
lsof -ti:8080,9099 | xargs -r kill -9

# Kill all Chrome/Flutter run processes (Linux/macOS)
pkill -f chrome
```

---

## Data Migration

If you need to bootstrap your local environment with legacy data (CSV/JSON), use the built-in migration utility. **Note**: Running on Chrome is highly recommended for the migration UI.

1. Place your CSV/JSON files in the `data/` directory.
2. Ensure the Firebase Emulator is running (`firebase emulators:start`).
3. Run the migration script using the following command:
   ```bash
   flutter run -t lib/run_migration.dart -d chrome
   ```
4. Once the app launches, click **"Sign In"** to authenticate, then click **"Run Migration"**.

---

## Architecture & Conventions

This project follows strict architectural patterns:
- **State Management**: Riverpod (Notifiers & AsyncNotifiers).
- **Models**: Freezed (Immutable classes & Sealed unions).
- **Navigation**: GoRouter (Declarative routing).
- **Design System**: Standardized components in `lib/core/widgets/` using HugeIcons.

Refer to `AGENTS.md` for detailed coding conventions and structural guidelines.
