# Loaded-context baseline — 2026-08-10

Measured **before** any Claude-5 rewrite of `CLAUDE.md`, the agent fleet, or the skills.
Re-measure with the same method after; anything else makes the comparison worthless.

## Method

No tokenizer is installed on this machine (`tiktoken`, `transformers`, `ttok`, `tokencount` all absent),
so **`est_tokens = round(chars / 4)`** — the standard rough ratio for English markdown.

Raw `chars`, `words` and `lines` are recorded alongside every figure **so a real tokenizer can re-derive
these numbers later without re-doing the file selection.** If you install a tokenizer, recount from the
same file list rather than switching method mid-comparison.

Symlinks are resolved before reading (most of these files are stow symlinks).

## Totals

| group | files | est. tokens |
| --- | ---: | ---: |
| always-loaded | 4 | 2,189 |
| agent definitions | 14 | 10,829 |
| preloaded skills | 10 | 8,939 |
| **total** | **28** | **21,957** |

"Always-loaded" is what enters every main session. The other two groups are **per-spawn** costs, not
session costs — an agent's definition plus its frontmatter-declared skills load when it is spawned.

## Always loaded (every main session)

| file | chars | est. tokens |
| --- | ---: | ---: |
| `~/.claude/CLAUDE.md` (global) | 3,166 | 792 |
| `~/CLAUDE.md` (project) | 4,381 | 1,095 |
| `~/.claude/RTK.md` | 958 | 240 |
| `MEMORY.md` (auto-memory) | 247 | 62 |
| **total** | | **2,189** |

## Per-spawn cost, agent definition + preloaded skills

| agent | definition | skills | **total** |
| --- | ---: | ---: | ---: |
| **notes** | 861 | 6,035 | **6,896** |
| **orchestrator** | 2,578 | 2,150 | **4,728** |
| worker | 1,467 | 422 | 1,889 |
| search | 1,169 | — | 1,169 |
| ast-search | 557 | 495 | 1,052 |
| docs | 466 | 259 | 725 |
| build-runner | 726 | — | 726 |
| lsp-search | 655 | — | 655 |
| reviewer | 551 | — | 551 |
| curl | 488 | — | 488 |
| browser | 426 | — | 426 |
| codex-review | 336 | — | 336 |
| git | 309 | — | 309 |
| docker | 240 | — | 240 |

Skills by size: `obsidian-bases` 3,220 · `obsidian-markdown` 1,342 · `obsidian-cli` 794 ·
`obsidian-markdown-tables` 679 · `orchestration-execution` 676 · `orchestration-planning` 640 ·
`ast-grep-readonly` 495 · `beads-workflow` 422 · `vault-plan-persistence` 412 · `defuddle` 259

## What this says about where the context actually goes

**`CLAUDE.md` is not the problem.** The entire always-loaded set is 2,189 est. tokens — about
**0.2% of a 1M context window**. Even a perfect Claude-5-style rewrite that deleted 80% of it would
recover ~1,750 tokens per session. That is close to noise.

**The `notes` agent costs 6,896 tokens per spawn** — more than three times the whole always-loaded set —
because it preloads four Obsidian skills, one of which (`obsidian-bases`, 3,220 tokens, 498 lines) is
larger than `CLAUDE.md`, `RTK.md` and `MEMORY.md` combined. Its job is to write a note. It runs on
haiku, and telemetry records 2,637 tool calls for it.

**`orchestrator` is second at 4,728**, roughly half definition and half preloaded orchestration skills.

So the progressive-disclosure argument from the context-engineering post applies here with far more
force to **agent frontmatter `skills:` preloading** than to `CLAUDE.md`. A skill loaded on demand costs
nothing until used; a skill in `skills:` frontmatter is paid on every spawn whether or not the task
touches it.

Two questions this raises, for the fog rather than for this ticket:

- Does `notes` need all four Obsidian skills preloaded, or should it load `obsidian-bases` on demand?
- Same question for `orchestrator`'s four orchestration skills.

## Reproducing

File selection: the four always-loaded files above; every `*.md` in `~/.claude/agents/`; every skill named
in an agent's `skills:` frontmatter block, resolved from `~/.claude/skills/`, `~/.agents/skills/`, or
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills/<name>/SKILL.md`.

Note the plugin cache nests **three** levels (`<marketplace>/<plugin>/<version>`), not two — a two-level
glob silently misses `defuddle` and the three `obsidian-*` skills.

Raw per-file data: `baseline.tsv` in the session scratchpad at measurement time; the tables above are the
durable copy.
