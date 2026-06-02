# Git & Commit Conventions

## 1. Commit Message Format
All commits must follow the **Conventional Commits** format: `<type>(<scope>): <summary>`.

### Types
- `Feat`: New functionality.
- `Fix`: Bug fixes.
- `Refactor`: Structural changes without behavior change.
- `Docs`: Updates to documentation, `.agents/` or README.
- `UI`: Visual-only changes (colors, themes, dimensions).
- `Chore`: Dependencies, build scripts, configuration.

### Summary Rules
- **Sentence case**: Must start with a Capital letter (e.g., "Add feature" not "add feature").
- **Imperative mood**: Use "Add" instead of "Added".
- **No trailing periods**: Do not end the summary with a `.`.

## 2. Agent Behavior
- **No Unsolicited Commits**: NEVER suggest, ask, or attempt to perform a git commit or push unless the user explicitly instructs you to do so. Assume the user has more edits to make until told otherwise.
- **Workflow Integrity**: All relevant `.md` files in `.agents/` (progress, tasks, session logs) MUST be updated **before** a commit is made. This ensures that every commit reflects the accurately documented state of the project.
- **Build Before Commit**: Ensure the codebase builds successfully and passes the analyzer (`dart analyze`) before making a commit.
- **Logical Commits**: Commits should only be made at logical stages and only when the codebase is in a working state.
