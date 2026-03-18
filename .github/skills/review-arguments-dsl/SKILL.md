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
- [Version-Aware Verification Sources](#version-aware-verification-sources)
- [Architecture Context (Base Pattern)](#architecture-context-base-pattern)
- [How Arguments Work](#how-arguments-work)
- [What to Check](#what-to-check)
- [Verification Chain](#verification-chain)
- [Output](#output)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with one or more
command source files and the relevant version-matched git documentation. Examples:

```text
Using the Review Arguments DSL skill, review
lib/git/commands/diff/numstat.rb against `git diff --numstat` docs.
```

```text
Review Arguments DSL: lib/git/commands/stash/push.rb
```

The invocation needs the command file(s) to review. Providing version-matched
git documentation helps verify flag accuracy.

## Related skills

- [Review Command Implementation](../review-command-implementation/SKILL.md) — class structure, phased rollout gates, and
  internal compatibility contracts
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test expectations for command classes
- [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md) — documentation completeness for command classes

## Input

Required:
1. One or more command source files containing a `class < Git::Commands::Base` and an
   `arguments do` block
2. Version-matched git documentation for the subcommand

## Version-Aware Verification Sources

Before auditing any DSL entry, determine the project's minimum supported Git
version from the repository metadata. In this repository, that version is
declared in `git.gemspec` (`git 2.28.0 or greater`).

Use sources in this order:

1. **Version-matched upstream documentation** for the minimum supported Git
  version. Prefer the tagged upstream documentation or versioned man page for
  that exact release.
2. **Version-matched upstream source** for the same release when the docs are
  ambiguous or abbreviated and exact parser behavior matters (for example:
  long-option spelling, short aliases, negation support, optional values, or
  `--option[=<value>]` forms).
3. **Local `git <command> -h` output** only as a supplemental check for the
  installed Git version on the current machine.

Do **not** rely exclusively on local help output. The installed Git may be
newer than the repository's minimum supported version and can advertise options
or flag forms that are not safe to model in the DSL for older supported Git
releases.

When local help disagrees with the minimum-supported-version sources, prefer the
minimum-supported-version behavior for the DSL and call out the newer-version
difference explicitly in the review output.

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
- **`skip_cli` operand behavior** — `operand ..., skip_cli: true` binds and validates
  like any other operand and remains accessible on `Bound`, but is intentionally
  excluded from argv emission
- **Operand naming** — use the parameter name from the version-matched git
  documentation, in
  singular form (e.g., `<file>` → `:file`, `<tag>` → `:tag`). The `repeatable: true`
  modifier already communicates that multiple values are accepted; pluralising the
  name is unnecessary and diverges from the docs.

## What to Check

See [CHECKLIST.md](CHECKLIST.md) for the complete review checklist covering:

1. Correct DSL method per option type
2. Correct alias and `as:` usage
3. Correct ordering
4. Correct modifiers
5. Completeness
6. Exit-status declaration consistency

**Validation delegation policy:** Command classes generally do **not** declare
cross-argument constraint methods (`conflicts`, `requires`, `requires_one_of`,
`requires_exactly_one_of`, `forbid_values`, `allowed_values`). Git is the single
source of truth for its own option semantics. There are two narrow exceptions:

1. **`skip_cli: true` arguments** — the argument never appears in git's argv, so
   git cannot detect incompatibilities and Ruby must enforce them. Example:
   `cat-file --batch` declares `conflicts :objects, :batch_all_objects` and
   `requires_one_of :objects, :batch_all_objects` because `:objects` is
   `skip_cli: true` and never reaches git's argv.
2. **Git-visible arguments that cause silent data loss** — if a combination of
   git-visible arguments causes git to silently discard data (no error, wrong
   result), a `conflicts` declaration MAY be added with: a code comment explaining
   why, a reference to the git version(s) where the behavior was verified, and a
   test. As of this writing, no such case has been identified.

See `redesign/3_architecture_implementation.md` Insight 6 for the full policy.

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
