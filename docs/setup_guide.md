# Setup & Disaster Recovery Guide

This document provides instructions for setting up new development environments and ensuring you never lose access to your production application.

## 💻 1. New Development Machine Setup

If you are starting work on a new machine, follow these steps to get fully operational:

### A. Environment Prerequisites
1.  **Flutter SDK**: Install the version named in `.fvmrc`. CI reads the same file, so a newer SDK on your machine can pass or fail checks that CI does not.
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
`Env` takes its values from `--dart-define-from-file=config/<backend>.json` when one is passed, and otherwise from `.env`, compiled into the app by `envied`.

1. **One file per backend (what you run with day to day)**:

   | File | Backend | In git |
   | :--- | :--- | :--- |
   | `config/local.json` | Local Supabase stack in Docker, seed data | Yes |
   | `config/prod.json` | Hosted project, real customer data | No. Copy `config/prod.json.example` and fill it in from the Supabase dashboard and Google Cloud console |
   | `config/staging.json` | A hosted staging project, if one is ever created | No. Template: `config/staging.json.example` |

   Every VS Code launch entry passes one of these, and is named `Local: …` or `PRODUCTION: …`, so an entry cannot reach a backend other than the one in its name.
2. **`.env` (the fallback, and what CI's release build uses)**:
   - Local stack: `cp .env.local .env` (or copy `.env.example` to `.env`).
   - Production build without a config file: `cp .env.prod .env`.
   - `.env` is read when code is generated, not when the app starts. After changing it, regenerate `lib/core/env/env.g.dart`:
     ```bash
     dart run build_runner build
     ```
   - A run that passes no config file (`flutter run` on its own) uses these values, so it reaches whichever backend `.env` held when code was last generated.
3. **Android and the local stack (`adb reverse`)**:
   - `config/local.json` points the app at `http://127.0.0.1:54321`. On an Android phone or emulator that address is the device itself. Forward the port to this machine first:
     ```bash
     adb reverse tcp:54321 tcp:54321
     ```
   - The `Local: Android (staging app)` and `Local: Android (staging app, profile)` launch entries run this for every connected device (USB or Wireless Debugging) before each launch. A device forgets the forwarding when it disconnects.
   - The iOS Simulator shares this machine's network and needs nothing. A physical iPhone or iPad cannot use `adb reverse`; it would need this machine's network address passed as `--dart-define=SUPABASE_URL=http://<address>:54321`, which has not been tried.
4. **Flavor Isolation (`staging` vs `prod`)**:
   - The Android `staging` flavor (`dev.darshanas.postfolio.staging`, "Postfolio Staging", its own icon) installs beside the production app.
   - `Env.assertFlavorSafe(flavor: appFlavor)` stops it from connecting to production Supabase. It runs against the local stack:
     ```bash
     adb reverse tcp:54321 tcp:54321
     flutter run --flavor staging --dart-define-from-file=config/local.json
     ```
   - Add `--profile` (or use `Local: Android (staging app, profile)`) for smooth AOT animations, or `--release` for a standalone release build that stays installed on a phone. It reaches the local stack only while connected over ADB (USB or Wireless Debugging) with port 54321 forwarded; Demo Mode works without either.
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
flutter build appbundle --flavor prod --release --dart-define-from-file=config/prod.json
```

For full Google Play Console setup (Internal/Closed Testing, Play App Signing SHA-1 for Google Sign-In, CI automation, and the 12-tester / 14-day Production path), see [`docs/play_store_setup.md`](play_store_setup.md).

### D. Release order when a migration is included
`release.yml` does not run migrations, and pushing a `v*` tag deploys the web build at once. When a release contains a new file under `supabase/migrations/`, do these in order:

1. **Back up** the hosted database (manual dump below, or a verified nightly archive).
2. **Rehearse** the migration on a copy of production if it alters or deletes existing data: restore the dump into a scratch database, apply the migration, compare row counts.
3. **Apply it**: `supabase db push`.
4. **Then** tag and release the client.

For `20261111000000_v2_4_storage_hardening.sql` specifically:
- It was rehearsed twice on copies of production: on 10 Nov 2026 (before the hosted RD-ledger migration) and again on 16 Nov 2026 with the final file (757 customers, 766 RDs, 733 OTDs, 214 ledger summaries, no ledger facts yet). Both times it applied cleanly in one transaction and no row counts or money totals changed.
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
- End-to-end provider check (it creates its own agent and account, and removes them): `flutter test test/supabase_rd_ledger_e2e_test.dart`
- If the Monthly Hub shows stale badges after editing data directly in SQL, pull-to-refresh on the Hub — it re-projects every visible RD from facts and rewrites the summary cache.

### Local seed data

`supabase/seed.sql` runs on every `supabase db reset`. It creates three local agents:

- **Primary Admin Agent**: `agent@postfolio.com` / `password123` (Jim Gordon, granted `'admin'` in `public.user_roles`), with 22 DC Universe customers, 21 recurring deposits (`0200010001`–`0200010021`), 17 one-time deposits (`0300020001`–`0300020017`), and 1 savings account (`0100030017`), mirrored 1-to-1 by Demo Mode's `FakeDataSource`.
- **Secondary Agents (for Admin Acting-As)**: `lucius@postfolio.com` / `password123` (Lucius Fox: 3 customers, 2 RDs, 2 OTDs) and `perry@postfolio.com` / `password123` (Perry White: 2 customers, 1 RD, 2 OTDs).

- **One customer, one situation.** Each customer on the primary agent's book showcases a real workflow or edge case with natural in-character notes:

  | # | Customers | What they show |
  | :--- | :--- | :--- |
  | 1–13 | Alfred Pennyworth to John Constantine | Monthly Hub & ledger intermediate states: in hand cash (`Alfred`) and large cash split into two PO lots (`Diana`), in hand via UPI (`Clark`) and bank transfer (`Edward`), part-paid (`Barbara`), part-paid with prior arrears (`Jason`), advance-paid 2 months ahead (`Barry`), household with 2 RDs (`Bruce`), 1 and 3–4 months in arrears (`Arthur`, `Harvey`), fronted (`Hal`), 3 installments caught up at once (`Harleen`), and an absorbed default fee (`John Constantine`) |
  | 14–22 | Kara Zor-El to Victor Stone | Account lifecycle & customer shapes: opened this month (`Kara`), long >50-char name (`Koriand'r`), 36 baseline installments + ₹10,000 opening receivable (`Lex`), due month-end (`Lois`), maturing soon in 20 days (`Oliver`, plus `Diana` MIS at 15d and `Edward` KVP at 25d), matured and still open (`Oswald`), closed (`Pamela`), minimal KYC name-only (`Selina`), and zero accounts (`Victor`) |

- **Dates follow the day of the reset.** Every date is counted back from that day in India time, so "this month", "overdue" and "maturing soon" are true on that day, and nothing is dated after it. The data ages as days pass: after a month end, this month's rows become last month's. Run `supabase db reset` to refresh it.
- **Signing in.** A build that runs against the local stack (`config/local.json`) shows **Sign in as seeded agent** on the login screen (signing in as Jim Gordon, with Admin Acting-As ready). If you sign in with Google instead, the first such sign-in takes over the primary seed portfolio (the `trigger_seed_adoption` trigger) and receives the `'admin'` role so Lucius Fox and Perry White remain accessible via Switch Account. To hand the data to a particular account by hand:
  `docker exec supabase_db_postfolio psql -U postgres -d postgres -c "SELECT public.adopt_seed_data('you@example.com');"`
- **It is checked.** `test/supabase_seed_scenarios_test.dart` reads the seed through the app's repositories and ledger projection and asserts each situation above (plus Admin Acting-As listing). Change the seed and that test together. The test is skipped when the seeded agent owns no customers.
- **Enum columns** (`scheme_type`, `status`, `relationship`, `payment_mode`) must hold the app's serialised names (`recurringDeposit`, `monthlyIncomeScheme`, `Son`, `bankTransfer`, …). A CHECK constraint refuses anything else.
- **Reseeding without the Supabase CLI**: wipe, then seed. The seed file does not update rows that exist.
  ```
  docker exec -i supabase_db_postfolio psql -U postgres -d postgres < supabase/tests/wipe_emulator_data.sql
  docker exec -i supabase_db_postfolio psql -U postgres -d postgres < supabase/seed.sql
  ```
- **Trying another day**: seed as if today were a different date, to see the data on the 1st or the last day of a month:
  ```
  docker exec -i supabase_db_postfolio psql -U postgres -d postgres < supabase/tests/wipe_emulator_data.sql
  docker exec -i -e PGOPTIONS="-c seed.today=2026-11-30" supabase_db_postfolio psql -U postgres -d postgres < supabase/seed.sql
  ```
  The app still uses the device's clock, so this is for checking the seed (`flutter test test/supabase_seed_scenarios_test.dart --dart-define=SEED_TODAY=2026-11-30`), not for browsing it.

-   **"Developer Error" on Google Sign-In**: Usually means the SHA-1 in Firebase doesn't match the key used to sign the app (Debug vs Release).
-   **"Keystore file not found"**: Check the path in `android/key.properties`. It is relative to the `android/app` directory.
-   **"Snapshot generator failed (exit code -9)"**: This is an Out-Of-Memory error. Close heavy applications and try building for a single architecture:
    ```bash
    flutter build appbundle --target-platform android-arm64
    ```
