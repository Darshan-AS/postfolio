# Git & Commit Conventions

## 1. Commit Message Format
All commits MUST follow this EXACT casing: `<Type>(<scope>): <Summary>`.

### Types (STRICT CAPITALIZATION)
- `Feat`: New functionality.
- `Fix`: Bug fixes.
- `Refactor`: Structural changes.
- `Docs`: Updates to documentation or `.agents/`.
- `UI`: Visual-only changes.
- `Chore`: Dependencies/Build.

### Summary Rules
- **Sentence case**: Start with a Capital (e.g., "Add feature").
- **Imperative**: Use "Add" not "Added".
- **No trailing periods**.
- **No lowercase types**: `feat(...)` is a violation; use `Feat(...)`.

## 2. Agent Behavior
- **No Unsolicited Commits**: NEVER suggest, ask, or attempt to perform a git commit or push unless the user explicitly instructs you to do so. Assume the user has more edits to make until told otherwise.
- **Workflow Integrity**: All relevant `.md` files in `.agents/` (progress, tasks, session logs) MUST be updated **before** a commit is made. This ensures that every commit reflects the accurately documented state of the project.
- **Build Before Commit**: Ensure the codebase builds successfully and passes the analyzer (`dart analyze`) before making a commit.
- **Logical Commits**: Commits should only be made at logical stages and only when the codebase is in a working state.
