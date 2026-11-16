# Postfolio

A portfolio management application for Post Office Small Savings Schemes, built with Flutter, Riverpod, and Supabase (PostgreSQL). Firebase is used only for Hosting (web) and Crashlytics (native).

## Getting Started

For setting up a new development machine, managing release keys, backups, and the release order when a database migration is included, see the **[Setup & Disaster Recovery Guide](docs/setup_guide.md)**.

### Quick Start

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Create `.env` and generate code:
   ```bash
   cp .env.local .env   # or copy .env.example and fill it in
   dart run slang
   dart run build_runner build
   ```

---

## Running the Application

### 1. Local Supabase (development)

Ensure Docker is running, then start the local stack. This replays every file in `supabase/migrations/` and loads `supabase/seed.sql`:

```bash
supabase start
```

Supabase Studio (database UI) is at `http://localhost:54323`.

Run the app against the local stack without touching `.env`:

```bash
flutter run -d chrome --dart-define-from-file=config/local.json
flutter run --flavor staging --dart-define-from-file=config/local.json   # Android
```

The same targets are available in VS Code's Run and Debug menu (`.vscode/launch.json`).

To reset the local database to migrations + seed:

```bash
supabase db reset
```

### 2. Production backend

Runs against the hosted Supabase project configured in `.env` (`cp .env.prod .env`, then re-run `build_runner`):

```bash
flutter run --flavor prod
```

### 3. Demo Mode

Toggle **Demo Mode** on the login screen to use in-memory fixtures with no backend.

---

## Tests

```bash
dart analyze --fatal-infos
flutter test --exclude-tags integration          # fast suite, no Docker
flutter test --tags integration                  # needs the local Supabase stack
docker exec -i supabase_db_postfolio psql -v ON_ERROR_STOP=1 -U postgres -d postgres \
  < supabase/tests/rd_ledger_facts_rls.sql       # SQL contracts; every case rolls back
```

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
