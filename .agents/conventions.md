# Postfolio Technical Conventions

This document tracks the architectural decisions, structural rules, and conventions for the `postfolio` app. 

## 1. Modular Rule Library
Detailed technical conventions are separated into focused modules for easier reference:
- [**Git & Commits**](rules/git.md): Commit message formats, types, and agent behavior rules.
- [**Architecture & Infrastructure**](rules/architecture.md): Riverpod, Firebase, Routing, and local storage rules.
- [**UI & Presentation**](rules/ui.md): Theming, widgets, formatting, and responsive layout rules.
- [**Logic & Purity**](rules/logic.md): Freezed models, Records, pattern matching, and functional patterns.

## 2. Global Anti-Patterns
1. **Committing Erroring States**: Never commit code that does not compile or pass the analyzer (`dart analyze`). Always format, build, and analyze before committing.
2. **List Controller Mutation Spoilage**: DO NOT manually set `state = loading` inside mutation methods (like `save()` or `delete()`) within a list controller. This wipes out data and causes UI rebuild bugs.
3. **Riverpod for Form Input**: Do NOT use Riverpod Notifiers to track individual keystrokes. Use `flutter_hooks` (`useTextEditingController`, `useState`) for live form inputs, and only pass structured data to Riverpod on submission.

## 3. Release Process
Releases are tag-driven and automated via GitHub Actions.
- **Prerequisites**: Update `pubspec.yaml` (version bump) and `CHANGELOG.md` (Keep a Changelog format).
- **Tooling**: Use the **`release-manager`** skill for versioning calculations and changelog updates.
- **Deployment**: Create a git tag matching the version (e.g., `v1.1.1`) and push to origin to trigger the deployment pipeline.
