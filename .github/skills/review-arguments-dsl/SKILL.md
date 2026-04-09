---
name: review-arguments-dsl
description: "Audits a command class's arguments DSL definition to verify it accurately maps Ruby call arguments to git CLI arguments in the correct order with correct DSL methods and modifiers."
---

# Review Arguments DSL

Verify that a command class's `arguments do ... end` definition accurately maps Ruby
call arguments to git CLI arguments, in the correct order, with the correct DSL
methods and modifiers.

## Contents

- [Contents](#contents)
- [Related skills](#related-skills)
- [Input](#input)
  - [Command source code](#command-source-code)
  - [Command test code](#command-test-code)
  - [Git documentation for the git command](#git-documentation-for-the-git-command)
- [Reference](#reference)
  - [Architecture Context (Base Pattern)](#architecture-context-base-pattern)
  - [DSL to CLI Mapping](#dsl-to-cli-mapping)
- [Workflow](#workflow)
- [Output](#output)

## Related skills

- [Review Command Implementation](../review-command-implementation/SKILL.md) — class structure, phased rollout gates, and
  internal compatibility contracts
- [Command Test Conventions](../command-test-conventions/SKILL.md) — unit/integration test conventions for command classes
- [Command YARD Documentation](../command-yard-documentation/SKILL.md) — documentation completeness for command classes

## Input

What the agent requires to run this skill and where to get it.

### Command source code

Read the command class from `lib/git/commands/{command}.rb` or, for subcommands,
`lib/git/commands/{command}/{subcommand}.rb`. For subcommands, also read the
namespace module at `lib/git/commands/{command}.rb` which should list all sibling
subcommands and provide the module-level documentation.

### Command test code

Read unit tests matching `spec/unit/git/commands/{command}/**/*_spec.rb`. Use these as
supplemental evidence when tracing the verification chain (Ruby call → bound
argument → expected git CLI). Coverage completeness is assessed by the
[Command Test Conventions](../command-test-conventions/SKILL.md) skill.

### Git documentation for the git command

- **Latest-version online command documentation**

  Determine the latest released git version by running `bin/latest-git-version`
  (it prints a version string such as `2.49.0`). Then read the **entire** official
  git documentation online man page for that version from the URL
  `https://git-scm.com/docs/git-{command}/{version}` (e.g.,
  `https://git-scm.com/docs/git-push/2.49.0`). This version will be used as the
  primary authority for DSL completeness, including the options to include in the
  DSL, argument names, aliases, ordering, etc.

- **Minimum-version online command documentation**

  Read the **entire** official git documentation online man page for the command for
  the `Git::MINIMUM_GIT_VERSION` version of git. This will be used only for
  command-introduction and `requires_git_version` decisions. Fetch this version from
  URL `https://git-scm.com/docs/git-{command}/{version}`.

Do **not** scaffold from local `git <command> -h` output alone — the installed Git
version is unknown and may differ from the latest supported version. Local help may
be used as a supplemental check only.

## Reference

### Architecture Context (Base Pattern)

Command classes follow this structure:

- `class < Git::Commands::Base`
- class-level `arguments do ... end`
- optional class-level macros such as `allow_exit_status <range>` and
  `requires_git_version <version>`
- YARD documentation with `@overload` blocks containing `@param`, `@option`,
  `@return`, and `@raise` tags, in one of two forms:
  - **when `#call` is overridden:** standard YARD comments directly above `def call`
  - **when `#call` is not overridden:** a `# @!method call(*, **)` directive with
    nested standard YARD comments

The CLI argument mapping is still defined exclusively by the Arguments DSL. The
`Base` class handles binding and execution.

### DSL to CLI Mapping

<!--
Purpose: gives the agent the mental model for predicting CLI output from a
DSL definition — the mapping rules needed to execute the verification chain
(Ruby call → bound argument → expected git CLI).

CHECKLIST.md works in the reverse direction: given git man-page behavior,
which DSL method and modifiers to use.
-->

The Arguments DSL (`arguments do ... end`) declares how Ruby keyword and positional
arguments map to git CLI flags, options, and operands. See [CHECKLIST.md §
Verify DSL method per option type](CHECKLIST.md#2-verify-dsl-method-per-option-type)
for the full DSL method mapping table.

Key behaviors:

- **Basic emit** — `flag_option :verbose` → `--verbose`; `value_option :message` →
  `--message <value>`; `operand :commit` → bare `<value>` in positional slot.
- **`flag_or_value_option`** — hybrid: `true` → `--flag`; string → `--flag value`
  (or `--flag=value` with `inline:`); `false`/`nil` → nothing. Supports `negatable:`.
- **`key_value_option`** — accepts a Hash or Array of pairs; emits `--flag key=value`
  per pair. `key_separator:` overrides `=`; `inline:` joins as `--flag=key=value`.
- **`custom_option`** — block receives the raw value and returns CLI strings; String
  is appended, Array is concatenated, `nil`/empty emits nothing.
- **nil / false suppression** — when a non-negatable option receives `nil` or
  `false`, nothing is emitted.
- **Output order matches definition order** — bound arguments are emitted in the
  order entries appear in `arguments do`.
- **Name-to-flag mapping** — underscores become hyphens, single-char names map to
  `-x`, multi-char names map to `--name`. **Case is preserved**: `:A` → `-A`, `:N` →
  `-N`. Uppercase short flags do not require `as:`.
- **`as:` override** — emits a verbatim string instead of deriving the flag from the
  symbol name. See [CHECKLIST.md § The `as:` escape
  hatch](CHECKLIST.md#the-as-escape-hatch) for when use is justified.
- **Aliases** — first alias is canonical and determines the generated flag; remaining
  aliases are accepted as caller-side synonyms. Long name first:
  `%i[force f]`, not `%i[f force]`.
- **`negatable:`** — `flag_option :edit, negatable: true` emits `--edit` for `true`,
  `--no-edit` for `false`, nothing for `nil`.
- **`inline:`** — `value_option :format, inline: true` emits `--format=value` as one
  token; without it, `--format value` as two tokens.
- **`max_times:`** — `flag_option :force, max_times: 2` with `force: 2` emits
  `--force --force`.
- **`repeatable:`** — accepts an array; emits the flag once per value
  (e.g., `--include a --include b`).
- **`as_operand:`** — `value_option :pathspec, as_operand: true` is passed as a
  keyword but emitted in the operand position after `end_of_options`.
- **`literal`** — always emits its string unconditionally; the caller has no control.
- **`execution_option`** — never emits anything to argv; forwarded as Ruby kwargs to
  the subprocess runner.
- **`skip_cli:` on operands** — `operand ..., skip_cli: true` binds and validates
  like any other operand and remains accessible on `Bound`, but is excluded from argv
  emission.
- **`end_of_options`** — signals end of options in the emitted argv; only operands
  may follow (though operands may also appear before it). Emits `--` by default.
  Override with `as:` when the command uses a different token. See [CHECKLIST.md §
  Choosing the `as:` token](CHECKLIST.md#choosing-the-as-token) for the decision
  rule.

## Workflow

1. **Determine scope and exclusions** — using the git documentation loaded during
   [Input](#input), identify which options are in scope for the DSL. See
   [CHECKLIST.md §1](CHECKLIST.md#1-determine-scope-and-exclusions).

2. **Audit each DSL entry** — for each entry in `arguments do`, walk through
   [CHECKLIST.md](CHECKLIST.md) §2–§5:
   1. Verify DSL method per option type
   2. Verify alias and `as:` usage
   3. Verify ordering
   4. Verify modifiers

   For each entry, also trace the verification chain — confirm the full mapping:

   `Ruby call → bound argument → expected git CLI`

   Compare the expected CLI output against the git man-page documentation.

3. **Check completeness** — verify the DSL as a whole against the git man page per
   [CHECKLIST.md §6](CHECKLIST.md#6-check-completeness): YARD↔DSL parity, missing
   options, repeatable flags, operand naming, and per-argument validation.

4. **Check class-level declarations** — verify `allow_exit_status` and
   `requires_git_version` per
   [CHECKLIST.md §7](CHECKLIST.md#7-check-class-level-declarations).

5. **Check the validation delegation policy** — verify that cross-argument
   constraint methods (`conflicts`, `requires`, etc.) are used only when
   justified. See the constraint policy in
   [CHECKLIST.md §6 Per-argument validation completeness](CHECKLIST.md#per-argument-validation-completeness).

6. **Collect issues** — record all findings for the [Output](#output).

## Output

Produce:

1. A per-entry table:

   | # | DSL method | Definition | CLI output | Correct? | Issue |
   | --- | --- | --- | --- | --- | --- |

2. A list of missing options/modifier/order/conflict issues
3. Any class-level declaration mismatches: `allow_exit_status` not present with
   a `Range` and rationale comment when the command has non-zero successful
   exits; `requires_git_version` not present only when the command was
   introduced after `Git::MINIMUM_GIT_VERSION`
