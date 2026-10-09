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
1. Copy either `.env.local` or `.env.prod` to `.env` depending on your active target:
   ```bash
   cp .env.local .env
   ```
2. Build/Compile the env variables using the generator:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

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

## Database Backups

To create a full manual backup (complete DDL schema + all data rows) into a self-contained SQL file using Docker:

```bash
docker run --rm -v $(pwd):/backup postgres:17 pg_dump "YOUR_SESSION_POOLER_DATABASE_URL" -f /backup/full_backup_$(date +%Y_%m_%d).sql
```

For complete instructions on retrieving the Supabase Session Pooler connection string, verifying the dump, and restoring the database, see the **[Setup & Disaster Recovery Guide](docs/setup_guide.md#database-backups-schema--all-data-via-docker)**.

---

## Architecture & Conventions

This project follows strict architectural patterns:
- **State Management**: Riverpod (Notifiers & AsyncNotifiers).
- **Models**: Freezed (Immutable classes & Sealed unions).
- **Navigation**: GoRouter (Declarative routing).
- **Design System**: Standardized components in `lib/core/widgets/` using HugeIcons.

Refer to `AGENTS.md` for detailed coding conventions and structural guidelines.
