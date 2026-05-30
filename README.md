# Postfolio

A sophisticated portfolio management application for Small Savings Schemes, built with Flutter, Riverpod, and Firebase.

## Getting Started

### Prerequisites

- **Flutter SDK**: Ensure you have the latest stable version of Flutter installed.
- **Firebase CLI**: Required to run the local emulators.
- **Java JRE**: Required for Firebase Emulators.

### Installation

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

### 2. Emulator Mode (Local Development)
Runs the app connected to the local Firebase Emulator Suite. This is recommended for development to avoid costs and data pollution.

**Step A: Start the Emulators**
In a separate terminal, start the Firestore and Authentication emulators. It is recommended to specify your project ID to ensure the emulator uses the correct configuration:
```bash
firebase emulators:start --project=postfolio-app
```

> **Tip**: You can access the **Emulator UI** at `http://localhost:4000` to manage local users and view Firestore data.

**Step B: Run the App**
Run the app with the `USE_EMULATOR` flag:
```bash
flutter run --dart-define=USE_EMULATOR=true
```

> **Note**: You can also use the **"Postfolio (Firebase Emulator)"** launch configuration in VS Code.

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

## Multi-Machine Setup (Google Sign-In)

If you are developing this project on multiple machines (e.g., switching between MacBook and Linux), you must register the unique debug SHA-1 fingerprint for **each** machine in the Firebase Console to enable Google Sign-In.

### 1. Retrieve SHA-1 Fingerprint
Run the following command on your new machine to get the debug fingerprint:
```bash
# Linux/macOS
cd android && ./gradlew signingReport
```
Look for the `SHA1` value under the `debug` variant.

### 2. Register in Firebase Console
1. Go to **Project Settings** > **General** in the [Firebase Console](https://console.firebase.google.com/).
2. Select the Android app (`com.example.postfolio`).
3. Click **Add fingerprint** and paste your machine's SHA-1.
4. (Optional) Also add the SHA-256 fingerprint for full support.

### 3. Sync Configuration
Once the fingerprint is added in the console, synchronize your local files:
```bash
# Ensure flutterfire-cli is in your PATH (see Environment Setup below)
flutterfire configure --project=postfolio-app --yes
```
This automatically updates `android/app/google-services.json` and `lib/firebase_options.dart`.

---

## Environment Setup

### PATH Configuration
Ensure your shell profile (e.g., `~/.zshrc` or `~/.bashrc`) includes the following paths to use the Flutter and Dart CLI tools effectively:

```bash
# Flutter SDK
export PATH="$PATH:[PATH_TO_FLUTTER]/bin"

# Dart Global Packages (e.g. flutterfire)
export PATH="$PATH:$HOME/.pub-cache/bin"
```

For more details, see the official [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in) and [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) documentation.

---

## Architecture & Conventions

This project follows strict architectural patterns:
- **State Management**: Riverpod (Notifiers & AsyncNotifiers).
- **Models**: Freezed (Immutable classes & Sealed unions).
- **Navigation**: GoRouter (Declarative routing).
- **Design System**: Standardized components in `lib/core/widgets/` using HugeIcons.

Refer to `AGENTS.md` for detailed coding conventions and structural guidelines.
