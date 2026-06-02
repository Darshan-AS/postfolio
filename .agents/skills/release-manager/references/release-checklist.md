# Release Checklist

Ensure all items are checked before finalizing a production release.

## 🧱 Foundation
- [ ] Version bumped in `pubspec.yaml` (e.g., `1.3.3+13`).
- [ ] `CHANGELOG.md` updated with human-readable changes.
- [ ] No `TODO` or `FIXME` comments left in critical business logic.

## 🧪 Testing & Quality
- [ ] `flutter analyze` passes with zero errors.
- [ ] `flutter test` passes 100%.
- [ ] App launches successfully on the Firebase Emulator.
- [ ] Smoke test: Login, Create Deposit, View Dashboard.

## 🔒 Security & Config
- [ ] `USE_EMULATOR` flag is set to `false` for production builds.
- [ ] Firebase project ID is correctly set to production.
- [ ] ProGuard/R8 rules are checked for Android (if any new packages were added).
- [ ] Keystore/Provisioning profiles are valid and accessible.

## 📱 Platform Specifics
- [ ] **Firebase Distribution**: Verify `FIREBASE_ANDROID_APP_ID` and `FIREBASE_CREDENTIAL_FILE_CONTENT` are active in GitHub Secrets.
- [ ] **GitHub Releases**: Ensure the tag follows the `v*` pattern (e.g., `v1.3.3+13`) to trigger the automatic release.
- [ ] **Web**: Verify Firebase Hosting project ID matches the environment.

## 📝 Post-Release
- [ ] Git tag created and pushed (`git tag v1.3.3+13 && git push origin v1.3.3+13`).
- [ ] Verify APKs are available in the GitHub Release "Assets" section.
- [ ] Verify testers received the update notification via Firebase App Distribution.
- [ ] `.agents/progress.md` updated with the new release state.
