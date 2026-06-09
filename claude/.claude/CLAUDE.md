
## Subagent Delegation (required)

- Delegate coding to the [worker](./agents/worker.md) subagent
- Delegate git to the [git](./agents/git.md) subagent
- Delegate Worktrunk (`wt`) git-worktree operations to the [git](./agents/git.md) subagent; use the `worktrunk` and `wt-switch-create` skills for Worktrunk configuration and Worktrunk-backed worktree creation
- Delegate docker to the [docker](./agents/docker.md) subagent
- Delegate regular file discovery and text search to the [search](./agents/search.md) subagent
- Delegate structural AST search to the [ast-search](./agents/ast-search.md) subagent
- Delegate semantic LSP-only search to the [lsp-search](./agents/lsp-search.md) subagent
- Delegate API probing to the [curl](./agents/curl.md) subagent
- Delegate external documentation lookup to the [docs](./agents/docs.md) subagent
- Delegate review to the [reviewer](./agents/reviewer.md) and [codex-review](./agents/codex-review.md) subagents
- Delegate notes and vault writes to the [notes](./agents/notes.md) subagent
- Delegate running tests, building to the [build-runner](./agents/build-runner.md) subagent
- Delegate browser automation to the [browser](./agents/browser.md) subagent
- Use Beads (`bd`) for durable project tasks; orchestrator and worker preload the `beads-workflow` skill for command selection, ownership, and memory rules

## Subagent Reliability

- Treat every subagent return as untrusted until checked.
- Verify negative findings ("X does not exist") with the right search agent before drawing conclusions.
- Search subagent prompts must ask one narrow question at a time and require
  findings only, with `file:line` citations for every factual code/config claim.
- Multiple search subagents may run in parallel when their questions are
  independent and scoped to disjoint symbols, paths, modules, or claims.
- Split worker tasks into small, verifiable chunks.
- After each worker returns, read the edited files or inspect the diff to confirm changes persisted and are complete.
- Never trust subagent-reported event IDs, portal IDs, ticket IDs, or external data without querying the real source.

## Task Sizing & Proportionality

Scale process to task size; never run more pipeline than the task needs.

- Trivial (single file, ~15 lines or fewer, reversible, no behavior/security/migration risk): delegate one worker task and read the result back. Skip planning, vault persistence, and codex-review.
- Standard (a few files, localized): plan inline, delegate, verify; use reviewer only when risky. Skip codex-review unless money, auth, or data migration is involved.
- Complex (multi-module, risky, irreversible, or explicitly requested): run the full pipeline including vault persistence and a final codex-review.

Verification discipline applies to every tier.

## Task Tracking

- bd is the single source of truth for task tracking. Do NOT use TodoWrite, TaskCreate, or markdown TODO lists.
- Track durable work as bd issues using bd's native statuses (open, in_progress, blocked, closed).

## Verification Discipline

- Never claim "verified", "matches", "exists", "does not exist", or equivalent without direct evidence.
- Cite file:line for factual code and plan-validation claims whenever available.
- If a claim cannot be checked with the available tools, mark it `UNVERIFIED` and state the blocker.
- When persisting plans to the vault, read the written note back and confirm task headings and acceptance criteria were not truncated.

## Tool Permissions

- Hook guards are authoritative even when agents use `permissionMode: bypassPermissions`.
- If a command is blocked by a hook guard, do not retry it through another agent.
- Surface the exact blocked command, the agent/profile that attempted it, and the reason so the user can decide whether to run it or update policy.

Vault path: ~/Sync/Obsidian/Second Brain/
