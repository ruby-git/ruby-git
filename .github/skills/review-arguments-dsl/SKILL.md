---
name: review-arguments-dsl
description: "Audits a command class's arguments DSL definition to verify it accurately maps Ruby call arguments to git CLI arguments in the correct order with correct DSL methods and modifiers."
---

# Review Arguments DSL

Verify that a command class's `arguments do ... end` definition accurately maps Ruby
call arguments to git CLI arguments, in the correct order, with the correct DSL
methods and modifiers.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Input](#input)
- [Architecture Context (Base Pattern)](#architecture-context-base-pattern)
- [How Arguments Work](#how-arguments-work)
- [What to Check](#what-to-check)
- [Verification Chain](#verification-chain)
- [Output](#output)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with one or more
command source files and the relevant git man page or documentation. Examples:

```text
Using the Review Arguments DSL skill, review
lib/git/commands/diff/numstat.rb against `git diff --numstat` docs.
```

```text
Review Arguments DSL: lib/git/commands/stash/push.rb
```

The invocation needs the command file(s) to review. Providing the git man page
or CLI documentation helps verify flag accuracy.

## Related skills

- [Review Command Implementation](../review-command-implementation/SKILL.md) — class structure, phased rollout gates, and
  internal compatibility contracts
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test expectations for command classes
- [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md) — documentation completeness for command classes

## Input

Required:
1. One or more command source files containing a `class < Git::Commands::Base` and an
   `arguments do` block
2. The git man page or documentation for the subcommand

## Architecture Context (Base Pattern)

Command classes now follow this structure:

- `class < Git::Commands::Base`
- class-level `arguments do ... end`
- optional `allow_exit_status <range>` for commands where non-zero exits are valid
- YARD directive: `# @!method call(*, **)` with nested `@overload` blocks

The CLI argument mapping is still defined exclusively by the Arguments DSL. The
`Base` class handles binding and execution.

## How Arguments Work

Key behaviors:

- **Output order matches definition order** — bound arguments are emitted in the
  order entries appear in `arguments do`
- **Name-to-flag mapping** — underscores become hyphens, single-char names map to
  `-x`, multi-char names map to `--name`. **Case is preserved**: `:A` → `-A`,
  `:N` → `-N`. Uppercase short flags do not require `as:`.
- **`as:` override** — an escape hatch that emits the given string (or array of
  strings) verbatim instead of deriving a flag from the symbol name. Because it
  bypasses the DSL's automatic mapping it removes the guarantee that the flag can
  be verified just by reading the symbol name, adding a manual audit burden. Use
  it only when the DSL genuinely cannot produce the required output — see
  section 2 for the three acceptable cases. Uppercase single-char symbols never
  need `as:`.
- **Aliases** — first alias is canonical and determines generated flag (long name
  first: `%i[force f]`, not `%i[f force]`)
- **Operand naming** — use the parameter name from the git-scm.com man page, in
  singular form (e.g., `<file>` → `:file`, `<tag>` → `:tag`). The `repeatable: true`
  modifier already communicates that multiple values are accepted; pluralising the
  name is unnecessary and diverges from the docs.

## What to Check

See [CHECKLIST.md](CHECKLIST.md) for the complete 8-point review checklist covering:

1. Correct DSL method per option type
2. Correct alias and `as:` usage
3. Correct ordering
4. Correct modifiers
5. Completeness
6. Conflicts
7. Conditional and unconditional argument requirements
8. Exit-status declaration consistency

## Verification Chain

For each DSL entry, verify:

`Ruby call -> bound argument output -> expected git CLI`

## Output

Produce:

1. A per-entry table:

   | # | DSL method | Definition | CLI output | Correct? | Issue |
   | --- | --- | --- | --- | --- | --- |

2. A list of missing options/modifier/order/conflict issues
3. Any `allow_exit_status` mismatches or missing rationale comments

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
