# Scoped verification

Run the smallest command that proves the change. A full suite is a fallback, not a default.

The goal is the least number of test files, not the least effort to choose them. Find the
related tests. Do not run every test of an app because you changed one component.

## Build the file list

- Collect the changed source files with `git status --porcelain` and `git diff --name-only`.
- Map a changed `.html` or `.scss` file to its sibling `.ts` file. A test runner resolves a
  template path to zero tests, because the transform inlines the template.
- Treat a file with no sibling `.ts` file as uncovered. A translation `.json` file, a shared
  stylesheet, and an asset have no import edge. Find their consumers by content search.
- Pass source files to the runner. Never pass a bare pattern, because a bare positional
  argument is a regex on the test path, not a file path.
- Pass the spec file itself when the change is only in a spec, a fixture, or a new test.

## Widen the list by import reachability

A related-tests run does not cross the project boundary. Measured on `date-helper.ts`, it
returned 103 specs and all 103 were inside the same project. Treat this as measured behaviour
for a shared library, and verify it for the file you changed.

1. Search for every file that imports the changed module, directly or through a barrel file.
2. Search for the old name too when you renamed or removed a symbol. A removed symbol has no
   importer under its new name.
3. Search the provider registration and the module declaration sites. A dependency injection
   edge is not always an import edge.
4. Add every file the search returns to the same command.

Do not judge whether the behaviour changed for a consumer. Import reachability decides the
list, not a prediction about impact.

Measured in `striive-portals`: the command for `date-helper.ts` alone returned 103 specs.
The same command with one consumer file added returned 104 specs, and the extra spec was in
`super-striive`. Widen by file. Do not widen by suite.

## Check each file for zero coverage before you run

Run this for each changed file, one file per command:

```
pnpm jest --listTests --findRelatedTests <one-changed-source-file>
```

- Treat an empty result as an uncovered file. Report that file by name.
- Do this per file. A combined command hides an uncovered file. Measured in `striive-portals`:
  `index.ts` alone returned 0 specs, `date-helper.ts` alone returned 103 specs, and the two
  files in one command returned 103 specs with exit code 0. The zero left no trace.

## Run the tests

Run from the `striive-portals` directory and use the root config:

```
pnpm jest --findRelatedTests <changed-source-file> [<more-source-files>...]
```

- Do not add `--config apps/<app>/jest.config.ts`. That flag drops the other 5 projects.
- Do not run `test-all`, `test-super-striive`, or another whole-app script for a local change.
- Use `--watch` only when the user asks for a watch loop.
- Add `--maxWorkers=6` when the run covers more than about 50 specs. Jest defaults to one
  worker per core minus one, which is 13 workers on this 14-core machine.

## A run of 0 tests is a failure

- Treat a run of 0 tests as a failure. The runner exits 0 when it finds no related test.
- Report the exact file that produced 0 tests, and name the reason.
- Do not add `--passWithNoTests` to convert the result into a pass.
- Do not report "the tests pass" from a run that executed no test.

## Cases that need a whole suite

Run the whole project suite in these 4 cases only:

- The change touches a shared test setup, a Jest config, a tsconfig path, or a global
  provider. Those files have no import edge to the tests they break.
- The change is in a barrel file, and the import search cannot enumerate the consumers.
- A mutation test or a coverage measurement needs its configured scope. Stryker and a
  `COVERAGE=true` run are exempt from this rule.
- The user asks for a full run.

Always add `--maxWorkers=6` to a whole-suite run. Measured on 2026-09-10 in
`~/code/hfs/II-8993/striive-portals`: an unbounded `jest --silent` reached 505.9% CPU and
9207296 KB resident within 23 seconds. It drove the load average to 13.96 on 14 cores, filled
memory to `35G used, 227M unused`, and triggered a Microsoft Defender and Spotlight scan of
the fresh `node_modules`. The machine was unusable until the run ended.

Let CI run the full suite. Do not reproduce the CI scope on every local change.

## Other tools

This rule covers the test runner only. Do not extend it to the linter or the build.

For the formatter and the linter, follow `formatting-and-linting.md`. That rule makes the
repository configuration the authoritative gate, and it forbids a tool or a scope that the
configuration does not list. The configured lint command in `striive-portals` is `ng lint`,
and it has no changed-file variant. Do not invent one.

This rule carries no verified command for the Java build.

## Override

An explicit request from the user beats this rule. A task that names a full-suite run as the
deliverable beats this rule. State the override once, then comply.
