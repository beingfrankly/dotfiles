# Beads (`bd`)

Call `/opt/homebrew/bin/bd` for every Beads command, including `bd prime`. Never call bare `bd`. The directory `~/.asdf/shims` precedes Homebrew on PATH, so a shim can shadow the binary at any time.

Beads is the source of truth for durable task state. Use the todo list only for current-session execution state.

## Startup

Run `bd prime` before you plan or edit in a repository that has a Beads database. When the user or an orchestrator names a Bead, run `bd show <id>` first. Use `bd ready` to pick new work only when the user asks you to pick work.

## Scope a work question to the current worktree

A work question is a question such as "which Beads are next" or "which Beads are ready to be picked up". Every worktree of a repository resolves to the same shared database. An unscoped `bd ready` therefore answers with the whole backlog. Measured in `~/code/hfs.feature-II-6100-source-channel-field`: `bd ready --plain -n 0` returned 204 Beads. Derive the scope before you answer.

1. Run `git branch --show-current`.
2. Take the issue key from the branch name, such as `II-6100` from `feature/II-6100-source-channel-field`.
3. Run `bd list --all --title-contains "<key>" --flat`. This returns the plan of the branch, with the status of each step.
4. Run `bd ready --parent <id>` when step 3 returns a parent Bead or an epic.
5. Report that set only. Name the closed steps, the in-progress Bead, the next open Bead, and each blocker.

Never combine `--ready` with `--title-contains`, and never use `--label-pattern`. Both filters are silently dropped. Measured on the `hfs` database: `bd list --ready --title-contains "II-6182"` returned Beads that hold no `II-6182` in the title, and `bd list --label-pattern "II-6100*"` returned Beads that hold no `II-6100` label. Filter by status instead, with `--status open,in_progress,blocked`. An exact `--label` value works on `bd ready`; a glob does not.

Run an unscoped `bd ready` in these 3 cases only:

- The user asks for the whole backlog.
- Step 3 returns no open Bead. State first that the branch work is complete.
- The branch name carries no issue key, and a search on the branch slug returns nothing.

In the third case, ask the user which scope to use. Never print the whole ready list as the answer to a scoped question.

## Ownership

Claim only the Beads for your current work, with `bd update <id> --claim`. Close a Bead only when the task gives you ownership and the work is complete. Never create or change a Bead outside your assigned scope. Record a dependency with `bd dep add <blocked-id> <blocker-id>`, and change the dependency graph only when the assigned work is graph maintenance.

Store durable knowledge with `bd remember`. Never create `MEMORY.md`, an ad hoc notes file, or a markdown TODO list for durable task tracking.

## Infrastructure

All projects share one local Dolt server at `127.0.0.1:3308`, with its data in `~/.beads/shared-server/dolt`. Never start a second server. Never create an embedded database for a project that the shared server already holds.

Beads is local-only. Never run `bd dolt push` or `bd dolt pull`. Never add, change, or remove a Dolt remote. The HFS database must never sync.

The canonical HFS database is `hfs`. The database `hfs_legacy` holds preserved history. Read it when you need the history. Never write to it.

## Approval and failure

Ask the user for explicit approval before you run any of these commands, and report why you need it:

- `bd dolt start`, `bd dolt stop`, or any restart of the shared server.
- `bd dolt push`, `bd dolt pull`, or any `bd dolt remote` change.
- `bd compact`, `bd flatten`, or `bd gc`, because each one rewrites history.
- `bd delete`, or any command that removes a backup, an export, or an issue.

Never wrap a `bd` command in a pipeline, a redirection, or a command chain. A failed or blocked `bd` command is a blocker to report, with the exact command and the exact reason. Never retry it through another agent, and never resolve it by starting a server, changing a remote, or rewriting history.
