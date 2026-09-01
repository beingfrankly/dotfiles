# No code comments

Do not write comments in code. Put the explanation in a durable artifact instead.

- Forbidden: human-readable comments at any scope in an in-scope file, which includes file, module, class, symbol, and function scope, plus `TODO` and `FIXME` markers and commented-out code.
- Permitted: a comment whose exact form a compiler, linter, formatter, code generator, or license requires, such as `eslint-disable`, `@ts-expect-error`, `noqa`, `@SuppressWarnings`, and a license header. Attach no prose to it.
- Permitted: a docstring on an exported or public function, method, class, interface, or type alias. It states a contract that the signature cannot state, such as a precondition, a thrown error, a unit, or an ownership rule.
- Forbidden: a docstring on a field, a property, a parameter, an enum member, a constant, or a component input or output. The name and the type are the contract. Rename the symbol or narrow the type instead.
- Forbidden: a docstring that repeats the name, describes the implementation, or gives a reason. Send the reason down the ladder.
- In scope: source code, shell scripts, and SQL. Markdown and configuration files are out of scope.
- Generated code is in scope. Do not hand-edit a generated file. Change its generator or template.
- Keep existing comments in the files you edit. Comment removal is a separate task that the user requests.

## Destination ladder

Test each rung in this order. Take the first rung whose condition holds.

1. Rename or extract code until the reason is self-evident.
2. Name the behaviour in a test name.
3. Write an ADR in `docs/adr/NNNN-slug.md` when the reason records a repository decision that is hard to reverse, surprising without context, and the result of a real trade-off.
4. Write a repository doc when the reason is an external reference fact, such as a vendor API defect, and not a repository decision. Use this rung also when a consumer of a published API needs usage guidance.
5. Write the reason in the commit message. This rung is the fallback and always holds.

State the rung you used in your response, in one line.
For deferred work, run `bd create` without asking, then report the issue ID.

This code breaks the rule:

```typescript
// the API returns 204 with no body for an empty list, so guard here
if (!response.body) return [];
```

Write `if (isEmptyListResponse(response)) return [];` instead, and send the API detail down the ladder.

This code also breaks the rule:

```typescript
/** Renders `(Optioneel)` after the label while the control carries no required validator. */
public readonly showOptional = input(false);

/**
 * `stacked` renders the label above the control. `inline` renders the control first, then the
 * label beside it, which is the order a checkbox or a toggle needs.
 */
public readonly layout = input<'stacked' | 'inline'>('stacked');
```

Delete both docstrings. The name and the type carry the contract.
Name the rendering behaviour in a test name, and put the call-site guidance in the component documentation.

This rule beats a skill checklist that asks for comments, such as `pr-review`. An explicit request from the user beats this rule. State the override once, then comply.
