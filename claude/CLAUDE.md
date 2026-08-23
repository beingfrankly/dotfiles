# Agent guidelines

- Inspect relevant files and state before acting; this prevents assumptions from becoming edits.
- Make the smallest change that fulfills the request and preserve unrelated work; this prevents scope creep and lost user changes.
- Surface material uncertainty and tradeoffs; this prevents guesses from being reported as facts.
- Verify outcomes with proportionate checks before claiming success; this prevents untested conclusions.
- Use non-interactive command flags where prompts are possible; this prevents unattended commands from hanging.

## Beads (`bd`)

When a repository has a Beads database, run `bd prime` and use `bd` as the task source of truth; this prevents work and context from drifting across sessions. Use `bd ready`, `bd show`, `bd update <id> --claim`, and `bd close <id>`. Store durable knowledge with `bd remember` instead of parallel markdown task or memory files.

## Herdr

When `HERDR_ENV=1` and terminal or agent orchestration is needed, load the Herdr skill and treat the installed CLI help as authoritative; this prevents stale syntax from controlling the wrong target.

- Target `--current` or explicit IDs, parse returned IDs, and use `--no-focus` for background work; this avoids hijacking the user's pane.
- Put long-running services in dedicated, reusable panes or tabs and verify readiness through the service or port; this avoids blocked agent panes, duplicate services, and false readiness.
- Do not close or restart panes, tabs, or services you did not create unless asked; this avoids interrupting other work.

Before finishing, run relevant quality gates, inspect the final diff and status, update the Beads issue, and follow the repository's commit and push policy.
