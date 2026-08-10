# What Frank corrects by hand after an agent reports "done"

Evidence base: `~/.claude/history.jsonl` (8,007 typed prompts, 2025-10-14 → 2026-08-09), 350 Claude Code
session transcripts (2,203 human turns), 616 Codex rollout files (844 human turns), `cass` lexical search.
Every claim below is tagged `[verified]` / `[inferred]` / `[unverified]`.

**Important framing note** `[verified]`: the four hypotheses under test come from one prompt Frank typed
on 2026-08-09 — `~/.claude/history.jsonl:8006`:

> "8 I keep correcting mistakes that are put in place through skills, I keep asking to remove comments,
> I keep asking to adhere solid principles, I keep asking to verify either in browser or through other means."

That line is the *source* of the hypotheses, not evidence for them. It is excluded from all counts below.

---

## Ranked table

| # | Pattern | Occurrences | Distinct repos/worktrees | Confidence |
|---|---------|-------------|--------------------------|------------|
| 1 | **Work reported done that does not actually run** (H3 — runtime verification) | 81 runtime-failure reports; 28 of them explicitly *"still"* broken after a fix; 41 requests to drive a browser | 15 (runtime), 11 (still-broken), 7 (browser) | High `[verified]` |
| 2 | **The "done" report is not trusted — Frank routinely runs a second adversarial review pass** (NEW — 5th pattern) | 55 in Claude Code + 11 in Codex = **66** | ~20 | High `[verified]` |
| 3 | **Skills produce or permit the wrong pattern — or are silently not followed** (H4) | 14 direct instances (+2 escalations to Confluence/bead epics) | 4 (`hfs`, `hfs/main`, `claude-skills-marketplace`, `loom`) | High `[verified]` |
| 4 | **i18n/translation keys missed, invented instead of reused, or left un-wired** (NEW — 5th pattern, concrete/code-level) | 15 (18 incl. adjacent) | 6 HFS worktrees | High `[verified]` |
| 5 | **Not reusing what already exists / duplicating code** (the real shape of the "SOLID" complaint) | 16 | 9 | Medium-High `[verified]` |
| 6 | **Comments that should not have been written** (H1) | 7 | 5 | Medium `[verified]` — real but low-frequency, and contradicted twice |
| 7 | **SOLID / design-principle violations** (H2) | 4, and *none* are post-hoc corrections | 4 | Low `[verified]` — see "Refuted" |

---

## 1. Work reported done that does not actually run (H3 — confirmed, strongest)

`[verified]` This is the highest-volume pattern by a wide margin, and the sub-slice that matters most is
the **"still"** slice: Frank applied the change, ran it himself, and it was still broken.

Counts (regexes in "Method"):
- 81 prompts reporting a runtime failure (`doesn't work` / `not working` / `is broken` / `I get this error`) across **15** projects.
- **28** of those are explicit post-fix regressions (`still doesn't work`, `still broken`, `still nothing`) across **11** projects.
- 41 prompts asking an agent to *drive the browser* (`agent-browser`, `open Chrome`, `check the browser`, `screenshot`) across **7** projects.

Verbatim, directly accusing the agent of not verifying:

> "You havent tested it turly. Because pnpm storybook ends up with a broken build"
> — `~/.claude/history.jsonl:3999` (`code/hfs`, 2026-03-06)

> "Did you run the tests at the RED phase?"
> — `~/.claude/history.jsonl:3560` (`code/hfs`)

> "First run the tests and verify THEN fix the code"
> — `~/.claude/history.jsonl:4469` (`code/hfs`)

> "Could we validate that the fix as implemented does not work?"
> — `~/.claude/history.jsonl:1900` (`code/hfs`)

Post-fix regressions:

> "It still doesn't work for the postal address. It doesn't get populated by the registration address values."
> — `~/.claude/history.jsonl:2033` (`code/hfs`)

> "it still doesn't work, check the lsp log again"
> — `~/.claude/history.jsonl:3311` (`.config/nvim`)

> "Still broken. Fetch relevant documentation on storybook 8 and angular 18"
> — `~/.claude/history.jsonl:4006` (`code/hfs`)

> "Dockers are up, but still nothing I think."
> — `~/.claude/history.jsonl:7529` (`code/hfs/feature-II-8121`)

Frank pushing verification into the browser explicitly:

> "verify it in the browser after restart. Research why the logo is now huge and blocks everything else from the view"
> — `~/.claude/history.jsonl:3145` (`code/hfs/striive-portals`)

> "The dockers are running, could you run the frontend (dev mode) and check if it works in chrome with the agent-browser skill?"
> — `~/.claude/history.jsonl:4718` (`code/hfs`)

> "Could you debug why it doesn't work in the browser?"
> — `~/.claude/history.jsonl:7388` (`code/hfs/feature-II-8120`)

**Spread** `[verified]`: not confined to one repo — `code/hfs` and its worktrees, `.config`, `.config/nvim`,
`.dotfiles/nvim`, `code/loom`, `code/claude-skills-marketplace`, `Sync` (Minecraft datapacks). This is a
general behaviour, not an Angular quirk.

---

## 2. The "done" report is not trusted — a second adversarial review is the ritual (NEW)

`[verified]` **This is the pattern nobody named, and by raw count it is the second largest.** Frank almost
never writes "you were wrong". Instead he *routes the finished work to another reviewer* — a subagent,
`pr-review`, `codex-reviewer`, or a fresh Codex session — with an instruction to assume the work is bad.

Counts: 55 prompts in `history.jsonl` matching `be critical` / `critically review` / `assume mistakes` /
`be sceptic` / `adversarial`, plus 11 in the Codex corpus. **66 total**, spanning the full 10-month window
and ~20 projects.

The Codex side is the sharpest evidence, because Codex is where Claude's output goes to be checked:

> "Look at the changes this feature branch introduces. Look at them with a critical and skeptical mind.
> Assume mistakes were made, anti-p[atterns]…"
> — `~/.codex/sessions/2026/06/04/rollout-2026-06-04T20-50-51-019e93f9-…jsonl:7`, and again verbatim at
> `~/.codex/sessions/2026/06/05/rollout-2026-06-05T13-37-22-019e9792-…jsonl:7` and `:15`

> "Could you read this analysis and verify what's true or not?"
> — `~/.codex/sessions/2026/06/15/rollout-2026-06-15T15-04-34-019ecb62-…jsonl:7`

> "Could you thoroughly & critically review the current implementation. Assume gaps, mistakes and anti-patterns."
> — `~/.codex/sessions/2026/05/21/rollout-2026-05-21T09-40-51-019e497a-…jsonl:7`

On the Claude Code side it shows up as a standing habit of spawning a second opinion:

> "Yes please do. Then let a subagent review it again and be very critical"
> — `~/.claude/history.jsonl:1803` (`code/hfs`)

> "Could you let a subagent review the unit tests? Let it be very critical"
> — `~/.claude/history.jsonl:1876` (`code/hfs`)

> "Let a subagent review the unit tests, let it be critical. Watch out for improper mocks. Are we testing the real implementation?"
> — `~/.claude/history.jsonl:2048` (`code/hfs`)

> "Could you use codex-reviewer to verify these findings?"
> — `~/.claude/history.jsonl:5265` (`code/hfs/II-7310`)

> "Could you review the PR comments … and validate them first BEFORE attempting to resolve them?"
> — `~/.claude/history.jsonl:7969` (`code/hfs/feature-II-8348`)

And the meta-version, where Frank asks *why* a completed agent report was wrong:

> "Why did the explore subagent come up with the wrong information? Could you analyse that?"
> — `~/.claude/history.jsonl:5956` (`code/hfs/II-6182-hubspot-hackathon`)

> "Why was the response from the API service wrong? Was this missed in the plan? Or was it missed in the context file?"
> — `~/.claude/history.jsonl:4987` (`code/hfs`)

`[inferred]` Interpretation: patterns 1 and 2 are the same underlying failure seen from two sides. The agent
reports completion on the strength of *having written the code*, not on the strength of *having observed it
work*. Frank's compensating ritual — a mandatory second adversarial pass — costs him a full extra review
cycle on essentially every non-trivial task. His own most recent notes point the same way:
`~/.claude/history.jsonl:8007` — *"10 evidence over guidance, 11 verification loops…"*.

---

## 3. Skills produce or permit the wrong pattern (H4 — confirmed)

`[verified]` 14 direct instances. Two distinct failure modes, and Frank hits both:

**(a) The skill encodes a wrong or missing rule.**

> "The angular-component skill should have mentioned that we dont want custom css but prefer primeflex classes for styling"
> — `~/.claude/history.jsonl:5913` (`code/hfs/main`)

> "I actually don't want to use effect() and untracked with forms, does the skill mention it should be built that way>"
> — `~/.claude/history.jsonl:4434` (`code/claude-skills-marketplace`)

> "I've submitted feedback on the formControlName which should be [formControl]"
> — `~/.claude/history.jsonl:4430` (`code/claude-skills-marketplace`)

> "I see that the team-pr-dashboard skill doesn't filter the PR's upfront but it just retrieves ALL open PR's"
> — `~/.claude/history.jsonl:3813` (`code/hfs`)

**(b) The skill was right and the agent ignored it** — this is the sharper half:

> "I saw that … recruiter-edit.form.ts doesn't use the … form-type-helper.ts. I thought the /angular-form skill mentioned to use those."
> — `~/.claude/history.jsonl:7114` (`code/hfs/main`)

> "I want you to go over each angular skill used by the subagents, read the reference material and verify the
> outcome of the migration. Which instructions were NOT followed?"
> — `~/.claude/history.jsonl:7117` and `:7118` (`code/hfs/main`, asked twice)

> "Any reason why the subagents didn't use the proper skill when working on the angularjs migration?"
> — `~/.codex/sessions/2026/04/02/rollout-2026-04-02T09-46-17-019d4d28-…jsonl:2830`

> "Could you look in today's session logs if the subagents tried to invoke Skill but failed when migrating an angularjs page?"
> — same file, `:2795`

Escalations — the cost is large enough that Frank has institutionalised the fix:

> "Could you write down what went wrong when we tried to use the angularjs-migration-context skill?"
> — `~/.claude/history.jsonl:4664`

> "Could you create an epic bead per angular skill and research if the skill has any contradictions, use of
> anti-patterns, lacking reference material for the agent to follow, lack of clear instructions?"
> — `~/.claude/history.jsonl:7176` (`code/claude-skills-marketplace`)

> "…AngularJS to Angular migration skill feedback from the app professionals QE batch" (Confluence page Frank
> asked to be mined for skill fixes) — `~/.claude/history.jsonl:7720`

**Spread** `[verified]`: heavily concentrated in the HFS Angular-migration skill family
(`angular-component`, `angular-form`, `angularjs-migrate-context`, `angularjs-migrate-plan`) plus
`team-pr-dashboard` and `loom`. It is **not** a general-purpose-skill problem; it is a *this-team's-skills*
problem.

---

## 4. i18n / translation keys — missed, invented, or left un-wired (NEW, 5th pattern, code-level)

`[verified]` 15 correction-intent prompts (18 including adjacent phrasings) across **6 distinct HFS
worktrees**, spanning 2025-11-07 → 2026-08-02. This is the single most consistent *code-level* thing Frank
fixes after the agent says done, and it did not appear on anyone's list.

Three sub-modes:

**Missing entirely:**
> "There's a missing translation. The noABN. It's missing in the portals I believe"
> — `~/.claude/history.jsonl:6399` (`code/hfs`)

> "The translations are missing of the vat options"
> — `~/.claude/history.jsonl:3651` (`code/hfs`)

> "I see that there's no translations in the action list. So something might be wrong:
> `<span … class="flex-1 font-bold text-center">offer.actions.profile</span>`"
> — `~/.claude/history.jsonl:7499` (`code/hfs/feature-II-8120`)

> "The baseline translation.json wasnt updated, could you do that?"
> — `~/.claude/history.jsonl:6810` (`code/hfs/II-7783`)

**New key invented instead of reusing the canonical one:**
> "I see registrationv2.zipCodeLabel. Why not use the default zip code (or postal code) translation from common.form.address ?"
> — `~/.claude/history.jsonl:7837` (`code/hfs/feature-II-8444`)

> "Use the same translation key the address form uses"
> — `~/.claude/history.jsonl:7838` (same worktree, next prompt)

> "Try to use the translation keys already present. Most of the [m are] in common.form"
> — `~/.claude/history.jsonl:3645` (`code/hfs`)

> "You found duplicated translation keys correct? Could you change the code from Micks PR … to use our translation keys?"
> — `~/.claude/history.jsonl:7901` (`code/hfs/feature-II-8444/striive-portals`)

**Wired but broken at runtime** (overlaps pattern 1):
> "The translations stopped working for the status value: status-widget.state.SILVER"
> — `~/.claude/history.jsonl:6760` (`code/hfs/main`)

> "the translation key is: common.form.phoneNumber.error.combinationInvalid — But the translations are not
> nested in that way. In the JSON's its common.form.error.phoneNumber"
> — `~/.claude/history.jsonl:4205` (`code/hfs`)

**Spread** `[verified]`: `code/hfs`, `code/hfs/main`, `code/hfs/II-7783`, `code/hfs/feature-II-8120`,
`code/hfs/feature-II-8444`, `code/hfs/feature-II-8444/striive-portals`. Confined to the HFS monorepo — but
that is where nearly all Frank's production feature work happens, and it recurs across six independent
worktrees and nine months, so it is a systemic gap rather than one bad ticket.

---

## 5. Not reusing what already exists (the real shape of the "SOLID" complaint)

`[verified]` 16 prompts across **9 projects**. Frank's design complaints are almost never abstract
principle citations — they are concrete "we already have this" pointers.

> "This code … Should not become methods inside the component. These should be made into pure pipes to reuse elsewhere"
> — `~/.claude/history.jsonl:3654` (`code/hfs`)

> "There's a problem with this. It should use the … models/company/marketplace.ts and the template should use
> the … components/form/marketplace/marketplace.component.ts"
> — `~/.claude/history.jsonl:3414` (`code/hfs`)

> "You should not modify the addressInputComponent but use the new address selectors. I believe its already used for super-striive"
> — `~/.claude/history.jsonl:1953` (`code/hfs`)

> "I see that we have AfasCountries which fill in a p-dropdown with the countries. However, we should just use
> app-country-select and we shouldn't fetch AfasCountries since that should be deprecated"
> — `~/.claude/history.jsonl:3658` (`code/hfs`)

> "Did we re-use the share assignment button/popup? Or is it a new button in the menu?"
> — `~/.claude/history.jsonl:7649` (`code/hfs/feature-II-7992`)

> "We already have Tree-sitter parsing, so I would love to use that instead of custom regex."
> — `~/.claude/history.jsonl:378` (`.config`)

`[inferred]` This is what Frank experiences as "SOLID violations": the agent writes a fresh local
implementation instead of finding and using the shared one. The abstract principle language appears only
when he is *asking for a review*; the actual hand-corrections are always concrete reuse pointers.

---

## 6. Comments that should not have been written (H1 — confirmed, but smaller than remembered)

`[verified]` **7** correction instances across 5 repos/worktrees, 2025-12-22 → 2026-07-26. Real, recurring,
but roughly one instance every six weeks — not a per-session tax.

> "remove comments from the unit tests & dont use \"as Type\""
> — `~/.claude/history.jsonl:1765` (`code/hfs/striive-portals`)

> "Could you remove the comments of the spec files?"
> — `~/.claude/history.jsonl:1883` (`code/hfs`)

> "And ditch the comments in the sql migration files, both"
> — `~/.claude/history.jsonl:6728` (`code/hfs/main`)

> "Could you also drastically reduce the amount of comments? I saw that the PR has +2,389 LOC?"
> — `~/.claude/history.jsonl:6949` (`code/hfs/II-7887`)
>
> `[verified]` This one is unambiguously post-completion. The immediately preceding assistant turn was
> *"Done — committed and pushed. … Commit: 7a39b478 … working tree clean, up to date with origin"* —
> `~/.claude/projects/-Users-Frank-vanEldijk-code-hfs-II-7887/d3f26c5c-311b-4a65-97f4-19f9d773b021.jsonl:74`

> "yes that html change is mine. Please remove all comments from the java files and then commit it."
> — `~/.claude/history.jsonl:7733`, following a completion-and-handoff summary at
> `~/.claude/projects/-Users-Frank-vanEldijk-code-hfs-feature-II-8285-signals-api-badge/e165316c-dea2-4860-8ca2-d4c32a16b2dc.jsonl:709`

`[verified]` Frank also tried to fix this at the source once:
> "The skill should mention that the agent should avoid writing comments unless its absolutely required
> because of the complexitiy" — `~/.claude/history.jsonl:2625` (`code/loom`)

**Counter-evidence, stated for honesty** `[verified]`: Frank has asked *for* comments twice, in a different
context — `~/Frank.vanEldijk/ds/analysis` (R/Shiny):
> "Could you use comments per block to explain the what, why and how? For instance the saveRDS, the server
> function, the ggplot, etx" — `~/.claude/history.jsonl:7395`; and `:7403`.
Also `:4860` ("put a comment on it that links to the jira ticket"). So the rule is not "never comment" —
it is "no comments in production Java/TS/spec/SQL code; comments are fine in analysis scripts and as
ticket-linking markers."

---

## Refuted or weaker than assumed

### H2 — "SOLID / design-principle violations" is **not a correction pattern** `[verified]`

Searched `history.jsonl` for `solid|single responsibility|separation of concern|dry principle|open.closed|
dependency inversion|design principle|clean code|god class` and the Codex corpus for the same. Total: **4**
hits in `history.jsonl` plus 2 in Codex (excluding the self-report at `:8006`). **All of them are Frank
asking for a review against SOLID up front — none is a correction of a specific violation after work was
reported done:**

- `:3127` "Review the current changes and be critical. Check for KISS, DRY, YAGNI and SOLID" (`hfs/striive-portals`)
- `:4194` "Spawn the reviewer subagent … What parts should be refactored to follow the SOLID principles?" (`hfs`)
- `:6064` "Could you review the current changes/implementation? look for mistakes, gaps, not following SOLID principles or using bad patterns." (`hfs/main`)
- `:7274` "The index.tsx is far too long, it needs a good archistructal refactoring…" (`code/hooked`)
- `:2623` (`loom`) — asking that a *skill* mention DRY/YAGNI, i.e. a policy edit, not a correction
- `~/.codex/…019dc4c5-…jsonl:353` "Does it also apply S[OLID]…" — a review question

`[verified]` **Zero** instances of Frank naming a SOLID principle to correct code an agent had just
finished. The felt experience of "I keep asking to adhere to SOLID principles" is real, but what he
actually types is pattern 5 (reuse) and pattern 2 (send it to a critical reviewer). Reframing the ask from
"follow SOLID" to "find and use the existing shared implementation" would match the evidence.

### H1 — comments: confirmed but **an order of magnitude smaller than H3/H2's felt weight** `[verified]`

7 instances in 10 months, vs 81 runtime-failure reports. It is also context-dependent (see counter-evidence
above), so a blanket "never write comments" rule would be wrong.

### Accusatory phrasing is essentially absent `[verified]`

Searched for `you didn't` / `you did not` / `I said` / `that's not what I asked` / `please stop` /
`don't add` across all 8,007 prompts: **0 matches** for the first four, near-zero for the rest. Frank
corrects by re-stating the desired end state ("Could you…", "It should…", "Lets…"), never by blaming.
`[inferred]` Consequence for anyone mining this data: keyword lists built around blame language will
return nothing. The signal lives in `still …`, `it doesn't work`, `Could you also …`, and `I see that …`.

### Things checked that did **not** turn out to be patterns `[verified]`

- **Scope creep / touching unrelated files** — 16 raw hits, but on inspection nearly all are Frank *scoping
  work up front* ("out of scope for now", "keep it minimal"), not correcting overreach. `revert` appears 17
  times, but the majority are Frank reverting his own experiments or asking for a clean restart
  (`:304`, `:1276`, `:967`), not undoing agent overreach. **Not supported.**
- **Hardcoded values / magic numbers** — 5 hits total. **Not supported.**
- **`any` type / weak typing** — 10 hits, of which one is emphatic
  (`:6810` "`any` was used … The any type is non-negotionable, that's not allowed") and one is
  `:1765` ("dont use \"as Type\""). Real but too thin to rank. **Weak.**
- **Committing/pushing forgotten** — the `process` bucket (76 transcript hits) is dominated by Frank
  *directing* the session-close protocol, not correcting a missed one. **Not supported as a correction.**

---

## Method and coverage

### What was searched

| Source | Volume | Coverage |
|---|---|---|
| `~/.claude/history.jsonl` | 8,007 prompts, 2025-10-14 → 2026-08-09 | **Complete.** This is every prompt Frank typed into Claude Code. Primary counting corpus. |
| `~/.claude/projects/**/*.jsonl` (top-level, non-subagent) | 350 files → 2,203 human turns, 3,185 assistant→human pairs | **Partial** (~27% of history prompts). Used only for *adjacency* — proving a correction directly followed a completion claim. |
| `~/.codex/sessions/**/*.jsonl` | 616 files → 844 human turns | **Complete** for Codex, but mixes Frank's own prompts with prompts written by the `codex-rescue` subagent. Filtered by hand when quoting. |
| `cass` | lexical mode only | **Degraded** — see limitations. |

### How

1. `jq` flattened `history.jsonl` to `prompts.tsv` (line, timestamp, project, text) — line numbers in every
   citation are `history.jsonl` line numbers, so `jq 'select(input_line_number==N)'` reproduces any quote.
2. A Python pass (`pairs.py`) walked each transcript, tracked the last assistant text block, and emitted
   (assistant-tail → next real human message) pairs, filtering out tool results, `<task-notification>`,
   `<local-command-*>`, `<system-reminder>` and hook output.
3. `classify.py` bucketed those pairs against 14 hand-written regexes and flagged which followed a
   completion claim (`done` / `committed and pushed` / `all tests pass` / `✅` / …).
4. Every bucket was then read manually and re-counted with a tightened regex; the counts in the ranked
   table are the **manually validated** ones, not the raw regex hits. Raw vs validated differs a lot —
   e.g. "comment" matches 62 prompts but only 7 are comment-removal requests; the rest are Bitbucket/GitHub
   *PR comments*.

Working files (reproducible): `/private/tmp/claude-501/-Users-Frank-vanEldijk/c8949d7a-8cf8-47a7-b82c-25552a0985f5/scratchpad/`
— `prompts.tsv`, `codex_user.tsv`, `pairs.tsv`, `pairs.py`, `classify.py`, `afterdone.py`.

### What could **not** be covered

- `[unverified]` **`cass` semantic search was unavailable** — `cass status` reports
  `Semantic: missing / consent required for model download`. All `cass` use was `--mode lexical`.
- `[unverified]` **The `cass` index was mid-rebuild** — `189/9037 conversations committed, 8848 sessions
  awaiting indexing`. A full rebuild would not finish inside this task's budget, so `cass` was used only
  for spot checks and to locate the Codex store; it was **not** used for any count. Counts came from direct
  `jq`/Python passes over the raw files, which is strictly more complete than the stale index.
- `[verified]` **Transcript coverage is recency-biased.** Only 350 top-level session files survive
  (2,203 human turns) against 8,007 typed prompts, and the surviving files skew heavily to 2026 worktrees
  (`feature-II-8120`, `feature-II-8444`, `main`). So the *adjacency* evidence ("this correction directly
  followed a done claim") is strong for recent work and absent for late-2025 work. The *counts* are
  unaffected — they come from `history.jsonl`, which is complete.
- `[unverified]` **Corrections Frank made silently are invisible.** Anything he fixed in his editor without
  telling the agent leaves no trace in any of these sources. Given that patterns 1 and 6 both surface only
  when Frank bothers to mention them, **all counts here are lower bounds.** He says as much himself at
  `~/.claude/history.jsonl:7876`: *"I've changed the translation for the label to not use the get function.
  using a get function in an angular template is an anti-pattern performance wise."* — a hand-fix reported
  only after the fact.
- `[unverified]` **Other agents/tools not covered** — Cursor, Copilot, Aider or web-Claude sessions, if used,
  are not in any of these three stores.
