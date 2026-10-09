# Setup & Disaster Recovery Guide

This document provides instructions for setting up new development environments and ensuring you never lose access to your production application.

## 💻 1. New Development Machine Setup

If you are starting work on a new machine, follow these steps to get fully operational:

### A. Environment Prerequisites
1.  **Flutter SDK**: Install the latest stable version.
2.  **Java JDK**: (Required for Android builds and Firebase Emulators). Ensure `JAVA_HOME` is set.
3.  **Firebase CLI**: Install via `npm install -g firebase-tools` and login using `firebase login`.

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

### C. Environment Configuration (Supabase & Envied)
Because the codebase uses `envied` to secure and obfuscate project API keys, follow these instructions to configure and switch environments:
1. **Local Emulator Config**: Copy the `.env.local` template to `.env`:
   ```bash
   cp .env.local .env
   ```
2. **Production Config**: Copy the `.env.prod` template to `.env`:
   ```bash
   cp .env.prod .env
   ```
   *(Ensure you update the publishable/secret tokens in `.env` if targeting live production databases)*.
3. **Compile Configuration**: Whenever you update or switch your `.env` file, you **must** compile the variables into the Dart configuration target:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

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

#### 5. Restoring from a Backup
To restore the complete dump into a target database:

```bash
docker run --rm -v $(pwd):/backup postgres:17 psql "TARGET_DATABASE_URL" -f /backup/full_backup_YYYY_MM_DD.sql
```

### If you lose your Upload Key (.jks):
Because we use **Google Play App Signing**, you can recover:
1.  Contact Google Play Support.
2.  Verify your identity.
3.  Request a **Key Reset**.
4.  Generate a brand new `.jks` and provide the new certificate to Google.

---

## 🛠️ 4. Common Troubleshooting

-   **"Developer Error" on Google Sign-In**: Usually means the SHA-1 in Firebase doesn't match the key used to sign the app (Debug vs Release).
-   **"Keystore file not found"**: Check the path in `android/key.properties`. It is relative to the `android/app` directory.
-   **"Snapshot generator failed (exit code -9)"**: This is an Out-Of-Memory error. Close heavy applications and try building for a single architecture:
    ```bash
    flutter build appbundle --target-platform android-arm64
    ```
