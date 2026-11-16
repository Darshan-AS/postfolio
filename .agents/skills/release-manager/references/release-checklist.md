# Release Checklist

Ensure all items are checked before finalizing a production release.

## 🧱 Foundation
- [ ] Version bumped in `pubspec.yaml` (e.g., `2.4.0+23`).
- [ ] `CHANGELOG.md` updated with human-readable changes.
- [ ] No `TODO` or `FIXME` comments left in critical business logic.

## 🧪 Testing & Quality
- [ ] `dart analyze --fatal-infos` passes with zero issues.
- [ ] `flutter test --exclude-tags integration` passes 100%.
- [ ] CI is green on the release commit (SQL contracts + integration suite on a clean local Supabase stack).
- [ ] App launches against the local Supabase stack (`supabase start`).
- [ ] Smoke test: Login, Create Deposit, View Dashboard, record an RD payment on the Monthly Hub.

## 🗄️ Database (when `supabase/migrations/` changed since the last tag)
- [ ] Hosted database backed up.
- [ ] Migration rehearsed on a current copy of production (row counts unchanged, no constraint aborts).
- [ ] `supabase db push` applied **before** the tag is pushed. See "Release order when a migration is included" in `docs/setup_guide.md`.

## 🔒 Security & Config
- [ ] GitHub Secrets `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` point at the production project.
- [ ] ProGuard/R8 rules are checked for Android (if any new packages were added).
- [ ] Keystore/Provisioning profiles are valid and accessible.

## 📱 Platform Specifics
- [ ] **Firebase Distribution**: Verify `FIREBASE_ANDROID_APP_ID` and `FIREBASE_CREDENTIAL_FILE_CONTENT` are active in GitHub Secrets.
- [ ] **GitHub Releases**: Ensure the tag follows the `v*` pattern (e.g., `v2.4.0+23`) to trigger the automatic release.
- [ ] **Web**: Verify Firebase Hosting project ID matches the environment.

## 📝 Post-Release
- [ ] Git tag created and pushed (`git tag v2.4.0+23 && git push origin v2.4.0+23`).
- [ ] Verify APKs are available in the GitHub Release "Assets" section.
- [ ] Verify testers received the update notification via Firebase App Distribution.
- [ ] Release APK installed and smoke-tested on a device.
- [ ] `.agents/progress.md` updated with the new release state.
