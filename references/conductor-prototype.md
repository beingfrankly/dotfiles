# Conductor prototype

## What it is

The conductor starts and sequences other agents through `herdr`, one step of a
declared flow at a time. It does no work itself: no editing, no reading of source,
no searching, no builds. It has no `Read` tool on purpose — if it needed one, it
would be doing someone else's job. Its `Bash` use is confined to three families:
`herdr ...`, `bd ...`, and `cat` of a flow file or an agent definition under
`~/.claude/agents/` (`claude/.claude/agents/conductor.md:7,28-29`).

## Launching it

```bash
herdr agent start <name> --kind claude --pane <pane-id> --timeout <herdr_timeout_ms> -- --agent conductor
```

Same generic start form as `claude/.claude/agents/conductor.md:45` (`--timeout` is
the herdr clock, not a step budget — see below), run with `permissionMode:
bypassPermissions` (`claude/.claude/agents/conductor.md:8`).

## Preflight — refuse before starting anything

Before starting any step, the conductor checks that every step's agent can reach
the beads bus — the first live run died forty minutes in on a reviewer with no
`Bash` (`claude/.claude/agents/conductor.md:31-40`). `kind: codex` passes on shell
access; `kind: claude` requires `cat`-ing the agent definition's `tools:` line, and
an agent missing `Bash` there cannot participate — the flow does not start.

## The marker contract

Each flow step declares a marker like `[conductor:plan:done]`. A step is complete
**only** when `bd show <issue>` shows that marker as its own comment in the
`COMMENTS` section — never anywhere else, since an issue body that quotes a
marker as an example would otherwise satisfy the step falsely.

`herdr agent prompt --wait` observes a *state* (the pane going idle), not an
outcome. It must never be read as "the task finished" — the pane's own contract
says it does not track turns, so an already-working agent's earlier completion
can match the wait.

The `bd-issue-to-review` flow has three steps, each with two clocks that are **not
interchangeable**: `herdr_timeout_ms` (passed to `herdr agent ...`, capped at 300000)
and `step_budget_ms` (how long the conductor keeps polling beads for the marker).
Never pass a step budget to herdr (`claude/.claude/agents/conductor.md:72-74`;
`claude/.claude/conductor/flows/bd-issue-to-review.yaml:27`).

- **plan** — `orchestrator`, kind `claude`, pane `plan`; herdr timeout 120000ms,
  step budget 900000ms
- **implement** — `worker`, kind `claude`, pane `worker`; herdr timeout 120000ms,
  step budget 3600000ms
- **review** — `reviewer`, kind `codex` (needs shell access to post to beads),
  with `-s workspace-write` since bd's Dolt db is in-workspace but bd also holds a
  lock outside it (`claude/.claude/conductor/flows/bd-issue-to-review.yaml:99-101,107-108`);
  pane `reviewer`, herdr timeout 120000ms, step budget 900000ms

A step that cannot be completed posts an explanation and no marker. A missing
marker is a valid outcome; a false one is not.

## Where the pieces live

- `claude/.claude/agents/conductor.md` (repo, real file) ←
  `~/.claude/agents/conductor.md` (symlink)
- `claude/.claude/conductor/flows/bd-issue-to-review.yaml` (repo, real file) ←
  `~/.claude/conductor/flows` (symlink; `~/.claude/conductor/` itself is a real
  directory, only `flows` is the link)

Both source files are currently untracked in git.

## Known gap: no guard profile

`~/.claude/hooks/rules.toml` (symlink, outside this repo) has no `[profiles.conductor]`
section, so the guard logs a BLOCKED warning on every call — harmless under
`CLAUDE_HOOK_GUARD_WARN_ONLY=1` (`claude/.claude/settings.json:6`), fatal without it; not fixed here.

Gotcha: a bd comment that quotes a later step's marker literal (even in prose)
will falsely satisfy that step early when the conductor greps for it. Describe
markers in prose, never repeat them as literal bracketed strings, in any
comment except the one that is genuinely that step's completion notice.
