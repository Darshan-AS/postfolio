---
name: release-manager
description: 'Manage the application release process. Use for version bumping, CHANGELOG updates, pre-release validation, and building Flutter artifacts.'
argument-hint: 'prepare | build | finalize'
---

# Release Manager Skill

This skill automates the end-to-end release process for the Postfolio application, ensuring version consistency and proper documentation.

## When to Use
- When preparing a new version for testing or production.
- When you need to bump the version in `pubspec.yaml`.
- When generating a release summary from git logs.
- When performing pre-release checks (lints, tests, build).

## Procedures

### 1. Prepare Release
Analyze commits and update versioning to ensure consistency.
- **Step 1**: Identify the last git tag using `git describe --tags --abbrev=0`.
- **Step 2**: List all commits since that tag using `git log <last_tag>..HEAD --oneline`.
- **Step 3**: Analyze commit messages to determine the release type:
    - **Major**: Breaking changes or significant architectural shifts.
    - **Minor**: New features (look for `Feat:` or `Add:`).
    - **Patch**: Bug fixes, UI tweaks, or refactoring (look for `Fix:`, `UI:`, `Refactor:`, `Chore:`).
- **Step 4**: Open `pubspec.yaml` and increment the **version** (X.Y.Z) and **build number** (+N) accordingly.
- **Step 5**: Draft new entries in `CHANGELOG.md` summarizing the analyzed commits in a human-readable format.
- **Step 6**: Recommend a tag following the `v<version>+<build>` format (e.g., `v1.3.3+13`).

### 2. Pre-Release Validation
Before building, ensure the codebase is healthy.
- **Step 1**: Run `flutter analyze` to catch lints.
- **Step 2**: Run `flutter test` to ensure no regressions.
- **Step 3**: Verify [Release Checklist](./references/release-checklist.md).

### 3. Build & Finalize
- **Android**: Trigger via tag (e.g., `git tag v1.3.3+13 && git push origin v1.3.3+13`) or manual dispatch.
- **Distribution**: Artifacts are automatically uploaded to **Firebase App Distribution** (for testers) and **GitHub Releases**.
- **Web**: Automatically deployed to **Firebase Hosting**.
- **Finalize**: Update `.agents/progress.md` with the new version and summary of changes.

## Resources
- [Release Checklist](./references/release-checklist.md): Comprehensive manual checks.
