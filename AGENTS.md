# Postfolio Project Guidelines

These guidelines define how AI agents must behave and interact with this repository. Adhere to these behavioral and architectural choices at all times.

## 1. The Agent Handshake (Mandatory)
All progress, tasks, and architectural conventions are stored in the `.agents/` folder. 
**CRITICAL INSTRUCTION FOR ALL AI AGENTS:** 
- DO NOT rely on the internal Copilot `/memories/repo/` system for core state.
- The `.agents/` folder is the **single source of truth**.
- When starting a new conversation, you MUST immediately read:
  1. `.agents/progress.md` (Current state)
  2. `.agents/tasks.md` (Roadmap)
  3. `docs/setup_guide.md` (Dev/Release setup & recovery)
  4. `.agents/session_logs/` (Recent history)

## 2. Core Rule Library
Detailed technical conventions are modularized. Read these files when working on relevant parts of the system:
- **Git & Commits**: [`.agents/rules/git.md`](.agents/rules/git.md) (Format, behavior, workflow)
- **Architecture**: [`.agents/rules/architecture.md`](.agents/rules/architecture.md) (Riverpod, Firebase, Routing)
- **UI & Presentation**: [`.agents/rules/ui.md`](.agents/rules/ui.md) (Theming, widgets, formatting)
- **Logic & Purity**: [`.agents/rules/logic.md`](.agents/rules/logic.md) (Immutability, Records, Patterns)

## 3. Agent Workflow Rules
- **Maintain Markdown State**: You MUST actively update `.md` files in `.agents/` (progress, tasks, session logs) as part of your workflow. Create a new session log for every session (`YYYY-MM-DD_session_N.md`).
- **No Unsolicited Commits**: NEVER suggest or ask to commit code. The user will provide the command when ready.
- **Dumb Widgets**: UI code must be strictly declarative. Logic belongs in Notifiers or Hooks.
- **Releases**: Use the **`release-manager`** skill for all version bumping and changelog updates.

## 4. Logical Workflow
1. Read the "Handshake" files.
2. Formulate a plan and update `tasks.md`.
3. Execute changes using `replace_string_in_file`.
4. Run `dart analyze` and tests.
5. Update `session_log.md` and `progress.md`.
6. **Pre-Commit Check**: Verify commit messages against `rules/git.md` (Check for strict casing: `Feat` NOT `feat`).
