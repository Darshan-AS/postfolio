# Google Play Store Setup & Migration Guide

This guide walks through migrating **Postfolio** (`dev.darshanas.postfolio`) from Firebase App Distribution to the Google Play Store — starting with **Internal Testing** for immediate Play Store installs and auto-updates, then progressing through **Closed Testing** to **Production**.

---

## Track Overview (Personal Account Created After Nov 13, 2023)

| Track | Who can install | Review time | Counts toward Production? | Use for |
| :--- | :--- | :--- | :---: | :--- |
| **Internal testing** | Up to 100 testers by Gmail | Minutes (no full review) | No | Immediate move off Firebase App Distribution; fast QA |
| **Closed testing** (`alpha`) | Invited email lists / Google Groups | Standard Play review (hours–days) | **Yes** (12+ testers opted in continuously for 14 days) | Trusted testers + unlocking public Production |
| **Production** (`production`) | Public Play Store | Standard Play review | — | General public release (unlocked after Closed Testing approval) |

> [!NOTE]
> Testers who opt into **Internal testing** receive only the Internal testing track even if they are also on Closed testing. When you are ready to start the 14-day Closed Testing clock, have testers opt out of Internal testing (or use the Closed Testing track directly once your first build is reviewed).

---

## Step 1: Generate Your Upload Keystore & Add GitHub Secrets

Currently, GitHub Actions only has the legacy `KEYSTORE_BASE64` (debug keystore) secret. Google Play requires a real release upload keystore.

> [!CAUTION]
> **Back up `upload-keystore.jks` and your passwords in your Password Manager immediately.** Never commit either file to Git.

1. Generate the upload keystore on your local machine:
   ```bash
   keytool -genkey -v \
     -keystore android/app/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```
   Use a strong password for both the keystore and key password, and save them in your password manager.

2. Create `android/key.properties` locally (git-ignored):
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. Base64-encode the keystore for GitHub Actions:
   ```bash
   # macOS
   base64 -i android/app/upload-keystore.jks | pbcopy

   # Linux
   base64 -w 0 android/app/upload-keystore.jks
   ```

4. Add two repository secrets in GitHub (**Settings → Secrets and variables → Actions → New repository secret**):
   - **`UPLOAD_KEYSTORE_BASE64`**: the base64 string from step 3.
   - **`KEY_PROPERTIES`**: the exact 4-line contents of `android/key.properties`.

---

## Step 2: Create the App in Google Play Console

1. Open [Google Play Console](https://play.google.com/console) → **Create app**:
   - **App name:** `Postfolio`
   - **Default language:** English (India) or English (United States)
   - **App or game:** App
   - **Free or paid:** Free
2. Complete the initial **App content** items on the Dashboard (required before Closed Testing / Production; Internal Testing can start even earlier):
   - **Privacy Policy:** Update `[Your Email]` in `docs/legal/privacy_policy.md` and host it at a public URL (e.g., on your Firebase Hosting site or GitHub Pages).
   - **App access:** Select **All or some functionality is restricted** and note that reviewers can use **Demo Mode** (no sign-in required) right from the login screen.
   - **Ads:** No, my app does not contain ads.
   - **Content rating:** Complete the IARC questionnaire (Finance/utility app → Everyone / 3+).
   - **Target audience:** 18 and over.
   - **Government apps:** Select **No** (Postfolio is an independent portfolio tracker for Post Office agents, not an official India Post / Government of India app).
   - **Data safety:**
     - Collects: **Personal info** (Name, Email via Google Sign-In/Supabase Auth), **Financial info / User-entered portfolio records** (stored per-agent in Supabase PostgreSQL with RLS), **App info and performance** (Crash logs via Firebase Crashlytics).
     - Shares data with third parties: **No** (data is not sold or shared for advertising).
     - Data encrypted in transit: **Yes** (TLS).
     - Account/data deletion: Provide an email or web URL where users can request account and data deletion.

---

## Step 3: Upload Your Very First `.aab` Manually

Google Play requires the **first** App Bundle for a new app to be uploaded manually in the Play Console web UI (this registers `dev.darshanas.postfolio` and initializes **Play App Signing**). Every release after this can be automated via GitHub Actions.

1. Get your signed `.aab` in either of two ways:
   - **Option A (from GitHub Actions — easiest):** After adding `UPLOAD_KEYSTORE_BASE64` and `KEY_PROPERTIES` in Step 1, go to **Actions → App Release Pipeline → Run workflow** (leave `deploy_live` unchecked). Download the **`postfolio-prod-aab`** artifact containing `app-prod-release.aab`.
   - **Option B (locally):** With `android/app/upload-keystore.jks` and `android/key.properties` in place:
     ```bash
     flutter build appbundle --flavor prod --release --dart-define-from-file=config/prod.json
     ```
     Output: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.
2. In Play Console, go to **Test and release → Testing → Internal testing**.
3. Click **Create new release** → accept **Google Play App Signing** → upload `app-prod-release.aab` → save & roll out to Internal testing.
4. Open the **Testers** tab → create an email list with your trusted testers' Google/Gmail addresses → save → copy the **opt-in link** (`https://play.google.com/apps/internaltest/...`).

---

## Step 4: Fix Google Sign-In for Play Store Installs (Critical!)

Because Google Play re-signs your `.aab` with its own **Play App Signing key**, Google Sign-In will fail with a developer error on Play Store builds until you register Google's signing certificate:

1. In Play Console, go to **Protected with Play → Play Store protection → Play App Signing** (or search **App signing** in the top search bar).
2. Copy both **SHA-1** and **SHA-256** under **App signing key certificate** (not just the upload key certificate).
3. Add both fingerprints to:
   - **Firebase Console** → `postfolio-app` → Project Settings → Your apps → Android (`dev.darshanas.postfolio`) → **Add fingerprint** (or via CLI: `firebase apps:android:sha:create 1:143378829514:android:41d9df0d03361b6d20a433 "<SHA>" --project postfolio-app`).
   - **Google Cloud Console** → APIs & Services → Credentials → Android OAuth 2.0 Client ID for `dev.darshanas.postfolio` (Firebase syncs this automatically).
4. *(Optional)* Also add the **Upload key certificate** SHA-1/SHA-256 so locally built release APKs work with Google Sign-In too.

---

## Step 5: Migrate Existing Firebase App Distribution Testers

1. Have each tester **uninstall** the existing Firebase App Distribution APK once (Android cannot update across different signing keys).
2. Send them the Play Console opt-in link.
3. They tap **Accept invite → Download it on Google Play**.
4. From that point on, every new release you publish to their track updates automatically through Google Play Store.

---

## Step 6: Automate Future Releases in GitHub Actions

`.github/workflows/release.yml` already has the `Upload to Google Play` step wired up and safely guarded until you add the service account secret.

1. **Enable the API:** In Google Cloud Console (for `postfolio-app` or any GCP project), go to **APIs & Services → Library** and enable **Google Play Android Developer API**.
2. **Create a Service Account:**
   - Go to **IAM & Admin → Service Accounts → Create Service Account** (e.g., `github-play-deployer`).
   - Skip GCP IAM roles (permissions are granted in Play Console).
   - Open the service account → **Keys → Add Key → Create new key → JSON**. Download the JSON file.
3. **Grant Play Console Access:**
   - In Play Console, go to **Manage account → Users and permissions → Invite new users**.
   - Paste the service account email (`github-play-deployer@...iam.gserviceaccount.com`).
   - Under **App permissions**, add **Postfolio** and grant:
     - **View app information (read-only)**
     - **Edit and delete draft apps**
     - **Release apps to testing tracks**
     - **Release to production, exclude devices, and use Play App Signing**
   - Click **Apply → Invite user → Send invite** (service accounts accept automatically).
4. **Add GitHub Secret & Optional Variables:**
   - Secret **`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`**: paste the full JSON contents of the downloaded key file.
   - *(Optional)* Repository Variable **`PLAY_STORE_TRACK`**: defaults to `internal`. Change to `alpha` (Closed Testing) or `production` whenever you graduate tracks.
   - *(Optional)* Repository Variable **`PLAY_STORE_RELEASE_STATUS`**: defaults to `completed`. If Play Console rejects an API upload while the app is still in *Draft* state before its first review, temporarily set this variable to `draft`, then remove it once published.

Once configured, pushing a release tag (`v2.4.1+24`, etc.) automatically builds the `.aab` with R8 mapping and native debug symbols and uploads it to your configured Play Store track.

> [!TIP]
> Once all testers have moved to Play Store, you can remove the `Upload to Firebase App Distribution` step from `.github/workflows/release.yml` and retire the `FIREBASE_ANDROID_APP_ID` secret.

---

## Step 7: Moving to Closed Testing & Public Production

When you are ready to unlock public Play Store distribution:

1. Prepare store graphics from `docs/store_assets/README.md` (512×512 icon, 1024×500 feature graphic, 2–8 phone screenshots).
2. In Play Console, go to **Test and release → Testing → Closed testing**, promote your tested Internal release (or upload a new build) to the closed track (`alpha`).
3. Invite **15–20 real testers** (buffer above the 12-tester minimum in case someone opts out) and have them stay opted in for **14 consecutive days** while actually using the app.
4. Set GitHub Variable `PLAY_STORE_TRACK` to `alpha` so any bugfix tags during the 14 days roll out to your closed testers automatically.
5. After 14 continuous days, click **Apply for production** on the Play Console Dashboard, answer the short questions about your testing and feedback, and once approved, switch `PLAY_STORE_TRACK` to `production`.
