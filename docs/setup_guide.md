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

### C. Google Sign-In (Debug)
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
