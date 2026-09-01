# Beads (`bd`)

Call `/opt/homebrew/bin/bd` for every Beads command, including `bd prime`. Never call bare `bd`. The directory `~/.asdf/shims` precedes Homebrew on PATH, so a shim can shadow the binary at any time.

Beads is the source of truth for durable task state. Use the todo list only for current-session execution state.

## Startup

Run `bd prime` before you plan or edit in a repository that has a Beads database. When the user or an orchestrator names a Bead, run `bd show <id>` first. Use `bd ready` to pick new work only when the user asks you to pick work.

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
