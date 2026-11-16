# Postfolio

A portfolio management application for Post Office Small Savings Schemes, built with Flutter, Riverpod, and Supabase (PostgreSQL). Firebase is used only for Hosting (web) and Crashlytics (native).

## Getting Started

For setting up a new development machine, managing release keys, backups, and the release order when a database migration is included, see the **[Setup & Disaster Recovery Guide](docs/setup_guide.md)**.

### Quick Start

1. Clone the repository.
2. Install the Flutter version named in `.fvmrc` (CI uses the same one).
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Create `.env` and generate code:
   ```bash
   cp .env.local .env   # or copy .env.example and fill it in
   dart run slang
   dart run build_runner build
   ```

---

## Running the Application

Which backend a run talks to is named by a file in `config/`, passed with `--dart-define-from-file`:

| File | Backend | In git |
| :--- | :--- | :--- |
| `config/local.json` | The Supabase stack in Docker on this machine, with the seed data | Yes |
| `config/prod.json` | The hosted project with real customer data | No: copy `config/prod.json.example` and fill it in |

Every entry in VS Code's Run and Debug menu (`.vscode/launch.json`) passes one of them, and its name starts with `Local:` or `PRODUCTION:`. `.env` is only the fallback for a run that passes no file, and for CI's release build.

### 1. Local Supabase (development)

Ensure Docker is running, then start the local stack. The first start replays every file in `supabase/migrations/` and loads `supabase/seed.sql`:

```bash
supabase start
```

Supabase Studio (database UI) is at `http://localhost:54323`.

**Signing in.** A build that runs against the local stack shows **Sign in as seeded agent** on the login screen. One tap signs in as `agent@postfolio.com`, who owns the seed data; no other build has the button. Google sign-in also works where this machine's debug key is registered in Firebase.

Run one of the `Local:` entries from Run and Debug; each first checks that the stack is up. From a terminal:

```bash
flutter run -d chrome --web-port=3000 --dart-define-from-file=config/local.json
flutter run -d macos --dart-define-from-file=config/local.json
```

**Android (emulator or a phone over USB or Wireless Debugging).** On Android, `127.0.0.1` is the device itself, so the stack's port has to be forwarded to this machine. Both `Local: Android (staging app)` launch entries (debug and profile) do it before every launch. From a terminal:

```bash
adb reverse tcp:54321 tcp:54321
flutter run --flavor staging --dart-define-from-file=config/local.json
```

A device forgets the forwarding when it disconnects; run `adb reverse` again after reconnecting.

To reset the local database to migrations + seed:

```bash
supabase db reset
```

### 2. Production backend

Run one of the `PRODUCTION:` entries, or:

```bash
flutter run --flavor prod --dart-define-from-file=config/prod.json
```

### 3. The staging app on a phone, beside the production app

The Android `staging` flavor has its own package ID (`dev.darshanas.postfolio.staging`), name ("Postfolio Staging") and icon, so it installs next to the production app. It refuses to connect to production and talks to the local stack over ADB (USB or Wireless Debugging).

- **Debugging (Hot Reload)**: the `Local: Android (staging app)` entry, with the phone connected via USB or Wireless Debugging.
- **Smooth animations & motion**: the `Local: Android (staging app, profile)` entry (AOT-compiled without debug assertions; no Hot Reload).
- **A release build that stays on the phone**:
  ```bash
  adb reverse tcp:54321 tcp:54321
  flutter run --release --flavor staging --dart-define-from-file=config/local.json
  ```
  The installed app reaches the local stack only while the phone has an active ADB connection (USB or Wireless Debugging) with port 54321 forwarded. Disconnected, Demo Mode still works.

### 4. Demo Mode

Toggle **Demo Mode** on the login screen to use in-memory fixtures with no backend.

---

## Tests

```bash
dart format lib test tool                        # CI fails on an unformatted hand-written file
dart analyze --fatal-infos
flutter test --exclude-tags integration --concurrency 8   # fast suite, no Docker
flutter test --tags integration                  # needs the local Supabase stack
docker exec -i supabase_db_postfolio psql -v ON_ERROR_STOP=1 -U postgres -d postgres \
  < supabase/tests/rd_ledger_facts_rls.sql       # SQL contracts; every case rolls back
```

`dart_test.yaml` runs one test file at a time, because the integration suites share one Supabase stack. The fast suite (450+ tests) shares nothing, so `--concurrency` runs its files side by side. The same commands are VS Code tasks (`.vscode/tasks.json`).

---

## Database Backups

To create a full manual backup (schema + all rows) into a self-contained SQL file using Docker:

```bash
docker run --rm -v $(pwd):/backup postgres:17 pg_dump "YOUR_SESSION_POOLER_DATABASE_URL" -f /backup/full_backup_$(date +%Y_%m_%d).sql
```

For retrieving the Session Pooler connection string, the nightly encrypted backup workflow, and restoring, see the **[Setup & Disaster Recovery Guide](docs/setup_guide.md#database-backups-schema--all-data-via-docker)**.

---

## Architecture & Conventions

- **State Management**: Riverpod (Notifiers & AsyncNotifiers).
- **Models**: Freezed (immutable classes & sealed unions).
- **Navigation**: GoRouter (declarative routing).
- **Backend**: Supabase (PostgreSQL with row-level security); business rules live in Dart.
- **Design System**: Standardized components in `lib/core/widgets/` using HugeIcons.

See [docs/architecture.md](docs/architecture.md) and `AGENTS.md` for coding conventions and structural guidelines.
