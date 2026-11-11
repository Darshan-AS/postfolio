# Setup & Disaster Recovery Guide

This document provides instructions for setting up new development environments and ensuring you never lose access to your production application.

## 💻 1. New Development Machine Setup

If you are starting work on a new machine, follow these steps to get fully operational:

### A. Environment Prerequisites
1.  **Flutter SDK**: Install the latest stable version.
2.  **Java JDK**: Required for Android Gradle builds. Ensure `JAVA_HOME` is set.
3.  **Docker & Supabase CLI**: Required for running the local PostgreSQL 17 + Auth + Realtime stack (`supabase start`).
4.  **Firebase CLI**: Install via `npm install -g firebase-tools` and login using `firebase login` (used for Firebase Hosting web deploys).

### B. Project Initialization
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/Darshan-AS/postfolio.git
    cd postfolio
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

### C. Environment & Flavor Configuration (`Env`, `--dart-define-from-file` & `envied`)
`Env` resolves runtime configuration with explicit `--dart-define` / `--dart-define-from-file` precedence and falls back to `.env` values obfuscated via `envied`:
1. **Default `.env` Setup**:
   - Local stack: `cp .env.local .env` (or copy `.env.example` to `.env`).
   - Production build: `cp .env.prod .env`.
   - Compile `lib/core/env/env.g.dart` whenever `.env` changes:
     ```bash
     dart run build_runner build
     ```
2. **Flavor Isolation (`staging` vs `prod`)**:
   - `Env.assertFlavorSafe(flavor: appFlavor)` prevents the Android `staging` flavor (`dev.darshanas.postfolio.staging`) from accidentally connecting to production Supabase.
   - To run `staging` against local Supabase without rewriting `.env`, pass the tracked `config/local.json` file (already wired in `.vscode/launch.json`):
     ```bash
     flutter run --flavor staging --dart-define-from-file=config/local.json
     ```
   - For a remote staging Supabase project, copy `config/staging.json.example` to `config/staging.json` (git-ignored) and pass `--dart-define-from-file=config/staging.json`.

### D. Google Sign-In (Debug)
Each development machine has a unique debug signature. To make Google Sign-In work locally:
1.  **Generate Debug SHA-1**:
    ```bash
    cd android && ./gradlew signingReport
    ```
2.  **Add to Firebase**:
    - Go to [Firebase Console](https://console.firebase.google.com/) -> Project Settings.
    - Add the **SHA-1** and **SHA-256** from the `debug` variant to your Android app.

---

## 🚀 2. Release & Build Machine Setup

To build the production version (`.aab`) for the Play Store, you need the signing keys which are **not** stored in Git.

### A. Restore the Keystore
1.  Locate your `upload-keystore.jks` file (stored in your Google Drive/Password Manager/Secure Storage).
2.  Place it in `android/app/upload-keystore.jks`.

### B. Configure Signing Properties
1.  Locate your `key.properties` file (stored in your Password Manager/Secure Storage).
2.  Place it in `android/key.properties`.
3.  Alternatively, create the file and add the following (using your actual passwords):
    ```properties
    storePassword=YOUR_STORE_PASSWORD
    keyPassword=YOUR_KEY_PASSWORD
    keyAlias=upload
    storeFile=upload-keystore.jks
    ```

### C. Verify the Release Build
```bash
flutter build appbundle
```

### D. Release order when a migration is included
`release.yml` does not run migrations, and pushing a `v*` tag deploys the web build at once. When a release contains a new file under `supabase/migrations/`, do these in order:

1. **Back up** the hosted database (manual dump below, or a verified nightly archive).
2. **Rehearse** the migration on a copy of production if it alters or deletes existing data: restore the dump into a scratch database, apply the migration, compare row counts.
3. **Apply it**: `supabase db push`.
4. **Then** tag and release the client.

For `20261111000000_v2_4_storage_hardening.sql` specifically:
- It was rehearsed on the 10 Nov 2026 production copy (757 customers, 766 RDs, 730 OTDs): it applied cleanly and no row counts changed. That copy predates the hosted RD-ledger migration, so the ledger tables were empty in the rehearsal.
- The v2.4 client needs it first: it calls `set_deposit_status` and `log_client_error`, which do not exist before the migration.
- The installed v2.3.1 client is expected to keep working after it: it uses only tables, views and the three `save_*` RPCs that the migration keeps. This comes from reading that client's code; it has not been run against the migrated schema. One known difference: deleting a customer who has a savings account fails until that client is updated.

---

## 🛡️ 3. Disaster Recovery & Security

**CRITICAL: If you lose these, you may lose the ability to update your app.**

### What to store in your Password Manager:
1.  **`upload-keystore.jks`**: The physical binary file.
2.  **`key.properties`**: The physical file or its exact content (passwords and alias).
3.  **Firebase Service Account Keys**: (Optional) For server-side scripts.
4.  **Google Play Recovery Codes**: Backup codes for your owner account.

### Database Backups (Schema + All Data via Docker)

For manual database dumps (e.g. before schema changes, migrations, or for off-site cold storage in Google Drive), use the official PostgreSQL 17 Docker container. This generates a complete, self-contained `.sql` file containing both the full DDL table schemas and all table data rows in a single file.

#### 1. Obtain Your Supabase Session Pooler URL
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Select your project and navigate to **Project Settings** > **Database**.
3. Scroll to **Connection string** > **URI**.
4. Select Mode **Session** (Port `5432` or `6543`).
   - *Example format:* `postgresql://postgres.[project-ref]:[YOUR-PASSWORD]@aws-0-[region].pooler.supabase.com:5432/postgres`
   - Replace `[YOUR-PASSWORD]` with your actual database password.

> [!TIP]
> **Always use the Session Pooler URL**: Use the **Session Pooler** connection string rather than the direct database host (`db.[project-ref].supabase.co`). The direct host resolves exclusively over IPv6, which is blocked or dropped on most home, office, and mobile network ISPs. The session pooler provides stable IPv4 connectivity.
>
> **Why Docker (`postgres:17`)?**: Supabase runs PostgreSQL 17. Using the official `postgres:17` container guarantees 100% client-to-server version parity and eliminates the need to install or maintain local PostgreSQL tools via Homebrew/apt.

#### 2. Run the Dump Command
Run this one-liner from the project root directory:

```bash
docker run --rm -v $(pwd):/backup postgres:17 pg_dump "YOUR_SESSION_POOLER_DATABASE_URL" -f /backup/full_backup_$(date +%Y_%m_%d).sql
```

**Command breakdown:**
- `--rm`: Automatically removes the temporary Docker container after completion.
- `-v $(pwd):/backup`: Mounts your current terminal directory to `/backup` inside the container, saving the output file directly to your workspace.
- `postgres:17`: Uses the official PostgreSQL 17 client image matching Supabase's server version.
- `pg_dump`: PostgreSQL native utility that dumps schema definitions and table rows into plain-text SQL (`COPY` commands).
- `-f /backup/full_backup_...`: Writes the dump to the mounted host path.

#### 3. Verify the Export
Verify that the file was created and contains both DDL schemas and real table rows:

```bash
# Check file size (should be non-empty)
ls -lh full_backup_*.sql

# Check SQL header and DDL statements
head -n 25 full_backup_*.sql

# Confirm table data rows exist (looking for PostgreSQL COPY statements)
grep -m 5 "^COPY public\." full_backup_*.sql
```

#### 4. Safe Cold Storage & Security
- **Store Off-Site**: Upload the generated `.sql` file to your private Google Drive folder, encrypted volume, or password manager vault.
- **Git Safety**: Local dump files (`*.dump`, `full_backup*.sql`, `postfolio_backup*.sql`) are excluded in `.gitignore`. **NEVER commit raw database dumps to GitHub**, as this repository is public.

#### 5. Restoring from a Manual Plaintext SQL Backup
To restore a plain `.sql` dump into a target database:

```bash
docker run --rm -v $(pwd):/backup postgres:17 psql "TARGET_DATABASE_URL" -f /backup/full_backup_YYYY_MM_DD.sql
```

---

### Automated Nightly Encrypted Backups (`.github/workflows/backup.yml`)

Because this repository is public, nightly backups (`01:30 IST` daily) stream `postgres:17 pg_dump -Fc` directly into an **`age` public-key encrypted archive** (`postfolio_YYYY_MM_DDTHHMMSSZ.dump.age` — zero plaintext ever touches the runner disk) and upload it to your Google Drive via `rclone` (`drive.file` scope), pruning snapshots older than 30 days.

#### One-Time Setup (~2 Minutes on macOS)

1. **Generate a Dedicated `age` Backup Keypair**:
   ```bash
   brew install age rclone
   age-keygen -o ~/postfolio-backup-age-key.txt
   ```
   - Store the entire contents of `~/postfolio-backup-age-key.txt` (`AGE-SECRET-KEY-1...`) in your **Password Manager** immediately, then delete the local file (`rm ~/postfolio-backup-age-key.txt`).
   - Copy the printed `age1...` public key for the `AGE_PUBLIC_KEY` GitHub Secret.

2. **Create a Non-Expiring `drive.file` OAuth Token With `rclone`**:
   - In Google Cloud Console (`postfolio-app` -> **Google Auth Platform / OAuth consent screen**), ensure **Google Drive API** is enabled in **APIs & Services -> Library**, create an OAuth 2.0 **Desktop app** client ID (if not already present), and set Publishing status to **"In production"** *(because `drive.file` is a non-sensitive scope, Google requires zero app verification review, and publishing prevents Google's 7-day "Testing" refresh-token expiry)*.
   - Run locally:
     ```bash
     rclone config
     ```
     - `n` (New remote) -> name: `gdrive` -> Storage: `drive` (Google Drive)
     - Enter your Desktop `client_id` and `client_secret`
     - Scope: select **`drive.file`** (*Access only to files created by rclone*)
     - Complete the browser login, leave `service_account_file` blank, decline Team Drive (`n`), and save (`y`).
   - Print the generated config block and copy it for the `RCLONE_CONFIG` GitHub Secret:
     ```bash
     cat ~/.config/rclone/rclone.conf
     ```

3. **Add GitHub Repository Secrets** (`Settings -> Secrets and variables -> Actions`):

   | Secret Name | Required | Value |
   | :--- | :---: | :--- |
   | `SUPABASE_DB_SESSION_URL` | Yes | Supabase Session Pooler URI (`postgresql://postgres.<ref>:<pw>@aws-0-<region>.pooler.supabase.com:5432/postgres`) |
   | `AGE_PUBLIC_KEY` | Yes | Recipient public key (`age1...`) |
   | `RCLONE_CONFIG` | Yes | Contents of `~/.config/rclone/rclone.conf` (`[gdrive]` section) |
   | `GDRIVE_BACKUP_REMOTE` | Optional | Defaults to `gdrive:postfolio-backups` |
   | `AGE_VERIFY_SECRET_KEY` | Optional | If set, the workflow decrypts each archive and checks its `pg_restore --list` table of contents. The key is written to a temporary file that is shredded when the step ends. Storing it here puts the decryption key next to the database URL, so leave it unset if you want a leaked GitHub secret store to be unable to read backups. |

> [!WARNING]
> **This workflow has not run on GitHub yet, and the restore below has never been rehearsed.** Its dump step was verified only locally (same `docker run … pg_dump -Fc` line against the local Supabase database, without `age`). Before relying on it: configure the secrets, trigger the workflow once by hand, and restore that archive into a throwaway project.

4. **One-Command Disaster Recovery (Decrypt + Restore `pg_dump -Fc` Archive)**:
   Download `postfolio_YYYY_MM_DDTHHMMSSZ.dump.age` from your Google Drive `postfolio-backups` folder, place your `age` secret key in `key.txt`, and run:
   ```bash
   age -d -i key.txt postfolio_YYYY_MM_DDTHHMMSSZ.dump.age \
     | docker run --rm -i postgres:17 pg_restore \
         --clean --if-exists --no-owner --no-privileges \
         -d "TARGET_SESSION_POOLER_DATABASE_URL"
   ```
   `--no-privileges` skips every `GRANT`/`REVOKE` in the archive, including the lockdown from `20261111000000_v2_4_storage_hardening.sql` (no `anon` table access, RPCs executable only by `authenticated`). After a restore with that flag, re-apply section 8 of that migration, or restore without the flag, before pointing the app at the database.

### If you lose your Upload Key (.jks):
Because we use **Google Play App Signing**, you can recover:
1.  Contact Google Play Support.
2.  Verify your identity.
3.  Request a **Key Reset**.
4.  Generate a brand new `.jks` and provide the new certificate to Google.

---

## 🛠️ 4. Common Troubleshooting

### RD Ledger schema (facts-only + sequential, migration `20261110000000_rd_ledger.sql`)
- The ledger persists **facts only**: `rd_transactions` (a payment is just money), `rd_po_deposits` (events: "next N installments deposited on <date>"), `rd_fee_absorptions` (fee the agent paid from pocket). Installment status, default fees and arrears are projected on the client by `RDLedgerProjector`; `rd_ledger_summary` is a per-RD cache the app rebuilds itself (pull-to-refresh on the Monthly Hub, or automatically for RDs that have no row yet).
- Apply locally with `supabase db reset` (replays all migrations from scratch).
- Verify RLS + constraints at any time (every case rolls back):
  `docker exec -i supabase_db_postfolio psql -U postgres -d postgres < supabase/tests/rd_ledger_facts_rls.sql`
- End-to-end provider check against the seeded data: `flutter test test/supabase_rd_ledger_e2e_test.dart`
- If the Monthly Hub shows stale badges after editing data directly in SQL, pull-to-refresh on the Hub — it re-projects every visible RD from facts and rewrites the summary cache.

### Local seed data & your Google account
- `supabase/seed.sql` creates a dummy agent (`agent@postfolio.com` / `password123`) with 3 customers, 3 RDs (with payments, PO deposits, a waiver and real arrears), 3 OTDs and nominees. Enum columns (`scheme_type`, `status`, `relationship`, `payment_mode`) **must** use the app's serialised names (`recurringDeposit`, `monthlyIncomeScheme`, `Son`, `bankTransfer`, …) — a raw short code like `'RD'` makes `fromJson` throw and the RD tab fail to load.
- The **first non-`@example.com` agent to sign in** on the emulator (e.g. your Google account) automatically adopts the seeded portfolio via the `trigger_seed_adoption` trigger. To hand it to a specific account manually:
  `docker exec supabase_db_postfolio psql -U postgres -d postgres -c "SELECT public.adopt_seed_data('you@example.com');"`
- Without the Supabase CLI on PATH you can wipe + reseed the running container with:
  ```
  docker exec -i supabase_db_postfolio psql -U postgres -d postgres < supabase/tests/wipe_emulator_data.sql
  docker exec -i supabase_db_postfolio psql -U postgres -d postgres < supabase/seed.sql
  ```

-   **"Developer Error" on Google Sign-In**: Usually means the SHA-1 in Firebase doesn't match the key used to sign the app (Debug vs Release).
-   **"Keystore file not found"**: Check the path in `android/key.properties`. It is relative to the `android/app` directory.
-   **"Snapshot generator failed (exit code -9)"**: This is an Out-Of-Memory error. Close heavy applications and try building for a single architecture:
    ```bash
    flutter build appbundle --target-platform android-arm64
    ```
