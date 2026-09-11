# Agent guidelines

- Inspect relevant files and state before acting; this prevents assumptions from becoming edits.
- Make the smallest change that fulfills the request and preserve unrelated work; this prevents scope creep and lost user changes.
- Surface material uncertainty and tradeoffs; this prevents guesses from being reported as facts.
- Verify outcomes with proportionate checks before claiming success; this prevents untested conclusions.
- Use non-interactive command flags where prompts are possible; this prevents unattended commands from hanging.

## Language

Write all prose in Simplified Technical English (the ASD-STE100 rules). The full rules are in `~/.claude/output-styles/ste.md`.

- Reproduce code, paths, commands, error text, and `file:line` citations exactly; this prevents a rewritten message from passing as evidence.
- For steps, plans, and prompts, use the imperative, one instruction per sentence, and 20 words per sentence at most; this prevents one instruction from carrying two actions.
- For explanations and findings, use the active voice and 25 words per sentence at most; this keeps a tradeoff readable.
- Use one term for one concept and never vary it for style; this prevents a reader from taking two words as two demands.
- Use the simple tenses, keep articles, and avoid `-ing` forms that are not established technical names; this keeps sentences parsable.
- Write "must", "can", and "will not" instead of "shall", "should", and "may"; this prevents an ambiguous requirement.
- State a fact, or mark it `UNVERIFIED` and name the blocker; never hedge; this prevents a guess from reading as a result.

## Herdr

When `HERDR_ENV=1` and terminal or agent orchestration is needed, load the Herdr skill and treat the installed CLI help as authoritative; this prevents stale syntax from controlling the wrong target.

- Target `--current` or explicit IDs, parse returned IDs, and use `--no-focus` for background work; this avoids hijacking the user's pane.
- Put long-running services in dedicated, reusable panes or tabs and verify readiness through the service or port; this avoids blocked agent panes, duplicate services, and false readiness.
- Do not close or restart panes, tabs, or services you did not create unless asked; this avoids interrupting other work.

Before finishing, run relevant quality gates, inspect the final diff and status, update the Beads issue, and follow the repository's commit and push policy.

@~/.claude/RTK.md
