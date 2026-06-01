# Exploration-Handoff Provenance Contract

> **Status:** authoritative reference
> **Cited by:** `~/.claude/agents/search.md`, `~/.claude/agents/orchestrator.md`, `~/.claude/agents/worker.md`

---

## 1. Purpose

When an explorer (search, ast-search, lsp-search, or any discovery subagent) hands findings to a consumer (orchestrator or worker), the consumer must be able to distinguish a directly-observed, load-bearing fact from a one-time inference, and must know exactly where the explorer's map ends. Without provenance, every downstream decision rests on an unknown epistemic foundation: a finding that looked certain could be a guess, and silence on a module could mean "clean" or could mean "not looked at". This contract solves that problem by requiring every finding to carry a confidence marker, every handoff to declare its coverage, and every handoff to answer whether the task's stated premise survived contact with reality. The contract is intentionally minimal — no LSP daemon, no build system coupling — it is built on top of telemetry already captured during tool use and on the citation discipline already required by the existing report format.

---

## 2. Confidence Taxonomy

This taxonomy **extends** the existing `UNVERIFIED` convention. It does **not** replace it; `UNVERIFIED` remains a valid alias (see below).

Every finding in a `RESULTS` section carries **exactly one** of the following markers:

| Marker | Meaning |
|---|---|
| `[verified]` | Direct evidence. The explorer opened the file, read the range, and cites the exact `file:line`. The claim is only as strong as the cited line; if that line changes, re-verify. |
| `[inferred]` | Reasoned from evidence but not directly confirmed. The explorer observed related facts (e.g. a function exported at `foo.ts:12`) and inferred a downstream consequence (e.g. "therefore all callers receive the new signature") without reading each caller. |
| `[unverified]` | Could not be checked with available tools — blocked command, missing permission, out-of-scope file, or tool gap. **Alias: `UNVERIFIED`** (the uppercase form used in existing agent definitions is equivalent and acceptable). |

**Rules:**
- Each `RESULTS` bullet carries exactly one marker, placed immediately after the bullet dash: `- [verified] ...`.
- A finding that mixes direct and inferred components must be split into separate bullets.
- Omitting a marker is a format violation; consumers must treat an unmarked finding as `[unverified]`.

---

## 3. PREMISE CHECK (mandatory field)

Every exploration handoff must include the following line, placed immediately after the `RESULTS` section and before `FILES INSPECTED`:

```
PREMISE CHECK: <YES|NO> — <explanation or "premise held">
```

- **NO** means nothing in the exploration contradicted the task's stated premise.
- **YES** means at least one observation conflicts with or invalidates the premise. Provide the specific conflicting evidence with `file:line` citations.
- This field is **mandatory even when the answer is NO**. An absent `PREMISE CHECK` is treated as `YES` by consumers (missing = unknown = must re-evaluate). Explicit `NO` is signal; silence is not.

---

## 4. COVERAGE Block

The `COVERAGE` block is appended after `LIMITATIONS` in every exploration handoff. It has two parts:

### 4a. DECLARED Coverage (explorer-authored)

The explorer self-reports what it deliberately examined and what it deliberately skipped. Written in plain prose or a two-item list:

```
COVERAGE:
  DECLARED:
    examined: <paths, modules, or symbols the explorer actively looked at>
    skipped:  <paths, modules, or symbols the explorer consciously excluded>
```

Declared coverage is the explorer's own attestation. It is **secondary** to observed coverage (see 4b). Consumers must not trust declared coverage alone.

### 4b. OBSERVED Coverage (tooling-written, authoritative)

The authoritative coverage record is written by tooling — not by the explorer — to:

```
~/.claude/telemetry/coverage/<agent_id>.json
```

The key is the subagent's `agent_id` for the session. This file is produced separately from the handoff report; the explorer does not write it. It captures which files were actually opened (via `Read`, `Glob`, `Grep`, etc.) regardless of what the explorer claims to have examined.

**Declared coverage is secondary to observed.** When the two disagree, observed wins. A file not in observed coverage was not examined, even if the explorer listed it under `examined`.

---

## 5. Consumer Rules

### Orchestrator

After an explorer returns:

1. Read `~/.claude/telemetry/coverage/<agentId>.json` to determine the observed file set.
2. Treat every `[inferred]` and `[unverified]` finding as **re-verify-before-use**: do not base worker task scope or plan decisions on them without a targeted follow-up search.
3. Any file or module **outside** the observed coverage is **"unknown, not clear"** — never assume the explorer's silence means checked-and-clear. Scope worker tasks accordingly (treat as unexplored territory).
4. A `PREMISE CHECK: YES` forces **plan re-evaluation before proceeding**. Do not dispatch workers against an invalidated premise without explicitly acknowledging the conflict and adjusting the plan.

### Worker

When handed exploration context:

1. Treat any finding below `[verified]` (i.e. `[inferred]` or `[unverified]`) as a claim to independently verify before acting on it — use `Read` or a targeted `Grep` to confirm before editing.
2. When making edits that fall **outside** the explorer's observed coverage, acknowledge the gap explicitly in your report under `CONCERNS`. Do not assume the unexplored areas are safe; surface them for orchestrator awareness.

---

## 6. Producer Format

The following example shows how a `search`-style agent embeds confidence markers per `RESULTS` bullet and appends the `PREMISE CHECK` and `COVERAGE` sections to the existing 4-section report.

```markdown
## RESULTS

- [verified] `AuthService.login` is defined at `src/auth/auth.service.ts:42` and accepts `(email: string, password: string): Promise<Session>`.
- [inferred] All callers likely receive the updated `Session` shape; `grep` found 3 call sites at `src/api/login.ts:18`, `src/api/sso.ts:31`, `src/cli/auth.ts:9` but the return-type consumers were not individually read.
- [unverified] Whether `src/legacy/auth.js` still imports `AuthService` — file exists but was out of declared scope; no `Read` was performed.

PREMISE CHECK: NO — premise held. Task stated "AuthService is the only auth entry point"; no contradicting entry points were found within observed coverage.

## FILES INSPECTED

- `src/auth/auth.service.ts` lines 38–55 — to confirm method signature
- `src/api/login.ts` line 18 — call site confirmation

## SEARCH AUDIT

- `Grep "AuthService"` scoped to `src/` — returned 4 matches
- `Glob "src/auth/**"` — 3 files, all inspected

## LIMITATIONS

- `src/legacy/` not examined; legacy callers may exist.
- No AST traversal; inferred return-type consumers require lsp-search follow-up.

## COVERAGE

  DECLARED:
    examined: src/auth/, src/api/login.ts, src/api/sso.ts, src/cli/auth.ts
    skipped:  src/legacy/ (out of task scope per caller instructions)
```

> Observed coverage is written to `~/.claude/telemetry/coverage/<agent_id>.json` by tooling and is authoritative over the `DECLARED` block above.
