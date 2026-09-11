# direnv: HFS repo environment

The HFS monorepo config used to live in the global zsh config. It now loads
per-directory through direnv. This removes 29 lines and 11 secrets from every
unrelated shell.

## Layout

| File | Scope | Tracked |
|---|---|---|
| `~/code/hfs/.envrc` | all worktrees (bare repo root) | no (outside any worktree) |
| `~/code/hfs/<worktree>/.envrc` | one worktree | no (gitignored) |
| `~/code/hfs/<worktree>/.env` | one worktree | no (gitignored) |
| `~/.config/zsh/secrets-hfs.sh` | loaded by `~/code/hfs/.envrc` | no (mode 600) |
| `~/.config/zsh/secrets-global.sh` | loaded by `zsh-exports` | no (mode 600) |

`~/code/hfs` is a **bare** repository and every worktree is a directory inside
it. direnv walks up from the cwd, so one `.envrc` at the bare root covers all
~90 worktrees. The per-worktree `.envrc` calls `source_up_if_exists` to reach it.

## Per-worktree template

Every worktree carries an `.envrc`. It must reach the shared
`~/code/hfs/.envrc`, or no secret loads: direnv reads only the nearest
`.envrc` and does not walk further up on its own.

Standard template, for a worktree under `~/code/hfs/`:

```sh
source_up_if_exists
dotenv_if_exists
if [[ -d mcp ]]; then
  PATH_add mcp
fi
```

## Worktree topology

Enumerate worktrees with `git worktree list`, never with a `~/code/hfs/*/`
glob. The glob returns 91 directories but only 56 are worktrees. The rest are
bare-repo internals (`objects/`, `refs/`, `logs/`, `worktrees/`), leaked
monorepo service directories (`select-application/`, `login-bff/`), and
parent directories of nested worktrees (`chore/`).

Three shapes exist:

- **Flat** — `~/code/hfs/<branch>`. `source_up_if_exists` walks one level.
- **Nested** — `~/code/hfs/chore/<branch>`, from branch names containing `/`.
  `source_up_if_exists` walks two levels and still finds the shared file.
- **Sibling** — `~/code/hfs.<branch>`, from the default `wt` path template.
  These sit *outside* `~/code/hfs`, so `source_up_if_exists` cannot reach the
  shared file. They need the explicit form instead:

```sh
source_env_if_exists "$HOME/code/hfs/.envrc"
```

`wt` propagates `main/.envrc` to new worktrees through `step copy-ignored`. A
worktree created with plain `git worktree add` gets none and falls back to the
shared file directly, but will not load its own `.env`.

## The go-hfs command

`~/.local/bin/go-hfs` is a dispatcher. It runs `git rev-parse --show-toplevel`,
uses `<worktree>/go-hfs/bin/go-hfs` when that exists, and otherwise falls back
to the copy in `main`.

This is a script rather than a `PATH_add` line because only 17 of 91 worktrees
carry an `.envrc`, and because the command must also work outside the repo.
`PATH_add` would have made `go-hfs` resolve in `main` alone.

## Secret split

`secrets-hfs.sh` holds the `HFS_*` variables plus `JIRA_TOKEN`, `HUBSPOT_ID`
and `HUBSPOT_PAT`, because every consumer sits inside the monorepo:

- `scripts/hubspot/backfill_striive_marketplace.py:394` reads `HUBSPOT_PAT`
  through `--token-env`.
- The Atlassian MCP wrapper reads the Jira token from the `jira_api_token`
  keychain entry, never from `JIRA_TOKEN`.
- nvim reads `JIRA_TOKEN` only as a fallback when that keychain entry is
  unavailable (`lua/lib/jira.lua:239`). The entry exists, so nvim is unaffected.

`secrets-global.sh` holds `BW_SESSION` alone.

### Reaching agents

The Bash tool does not load `.envrc` (see the last section). Claude Code
inherits these variables only from the shell that launched it. Start `claude`
from inside the worktree, or wrap the call: `direnv exec . <command>`.

## Allow list

`~/.config/direnv/direnv.toml` whitelists the `~/code/hfs` prefix, so a new
worktree loads without `direnv allow`. The tradeoff: any `.envrc` under that
path runs without review. `.envrc` is gitignored in this repo, so a teammate
cannot ship one.

## Testcontainers staleness

`~/code/hfs/.envrc` resolves `TESTCONTAINERS_HOST_OVERRIDE` from the Rancher
Desktop VM address. direnv caches the result until `.envrc` changes. Restarting
Rancher Desktop can change that address. Run `direnv reload` after a restart.
The previous global block re-resolved the address on every new shell.

`DOCKER_HOST` is no longer global. The Rancher `docker` CLI uses its
`rancher-desktop` context, so plain `docker` still works outside the repo.
Only Testcontainers needed the variable, and that runs inside the repo.

## Why agent config does not belong here

Claude Code scopes MCP servers, skills, rules, hooks and settings by directory
already, through `.mcp.json` and `.claude/`. The Bash tool runs a
**non-interactive** zsh, which reads `~/.zshenv` and never `.zshrc`, so the
direnv hook is absent and no `.envrc` loads. direnv cannot gate agent behaviour.
