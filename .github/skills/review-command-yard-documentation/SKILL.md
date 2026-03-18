---
name: review-command-yard-documentation
description: "Verifies YARD documentation for command classes is complete, accurate, and aligned with the Git::Commands::Base pattern. Use to audit documentation quality for commands."
---

# Review Command YARD Documentation

Verify YARD documentation for command classes is complete, accurate, and aligned with
the `Git::Commands::Base` pattern.

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Prerequisites](#prerequisites)
- [Related skills](#related-skills)
- [Input](#input)
- [Version-Aware Documentation Scope](#version-aware-documentation-scope)
- [Required documentation model](#required-documentation-model)
  - [No `def call` override (simple commands)](#no-def-call-override-simple-commands)
  - [Explicit `def call` override](#explicit-def-call-override)
- [What to Check](#what-to-check)
  - [1. Class-level docs](#1-class-level-docs)
  - [2. Arguments docs](#2-arguments-docs)
  - [3. Return and raise tags](#3-return-and-raise-tags)
  - [4. `allow_exit_status` rationale consistency](#4-allow_exit_status-rationale-consistency)
  - [5. Formatting consistency](#5-formatting-consistency)
  - [6. Avoid internal implementation detail leakage](#6-avoid-internal-implementation-detail-leakage)
- [Common issues](#common-issues)
- [Output](#output)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with one or more
command source files whose YARD docs should be reviewed. Examples:

```text
Using the Review Command YARD Documentation skill, review
lib/git/commands/branch/delete.rb.
```

```text
Review Command YARD Documentation: lib/git/commands/stash/push.rb
lib/git/commands/stash/pop.rb
```

The invocation needs the command file(s) to review.

## Prerequisites

Before starting, you **MUST** load the following skill(s) in their entirety:

- [Write YARD Documentation](../write-yard-documentation/SKILL.md) — authoritative
  source for YARD formatting rules and writing standards;

## Related skills

- [Write YARD Documentation](../write-yard-documentation/SKILL.md) — authoritative
  source for general YARD formatting rules and writing standards
- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries
  match git CLI
- [Review Command Implementation](../review-command-implementation/SKILL.md) — class
  structure, phased rollout gates, and internal compatibility contracts
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test
  expectations for command classes

## Input

One or more command files from `lib/git/commands/` containing:

- `class < Git::Commands::Base`
- `arguments do ... end`
- optional `allow_exit_status`
- either a `# @!method call(*, **)` YARD directive (when no `def call` override) or
  YARD doc comments directly above an explicit `def call` override

## Version-Aware Documentation Scope

Before deciding whether YARD documentation is accurate or incomplete, determine
the repository's minimum supported Git version from project metadata. In this
repository, `git.gemspec` declares `git 2.28.0 or greater`.

Option names, aliases, negated forms, and accepted values documented in YARD
must be validated against the minimum supported Git version first. Use
version-matched upstream documentation as the primary source, inspect
version-matched upstream source when exact parser behavior is ambiguous, and use
local `git <command> -h` output only as a supplemental check.

Do not flag docs as missing solely because the locally installed Git advertises
newer forms that are unavailable in the minimum supported version.

## Required documentation model

The placement of `call` documentation depends on whether the command class overrides
`def call`.

### No `def call` override (simple commands)

When the class does **not** define `def call`, use the `# @!method call(*, **)` YARD
directive. This tells YARD to attach per-command docs to the inherited `call` method
without a method definition in the subclass:

```ruby
# @!method call(*, **)
#
#   @overload call(**options)
#
#     Execute the git ... command.
#
#     @param options [Hash] command options
#
#     @option options [Boolean] :force (nil) ...
#
#     @return [Git::CommandLineResult]
```

Place the directive inside the class body, after the `arguments do` block (and after
`allow_exit_status` when present). Do **not** combine `@!method` with an explicit
`def call`.

### Explicit `def call` override

When the class defines `def call` explicitly (for input validation, stdin feeding, or
non-trivial option routing), place YARD docs **directly above** the `def call`
method. Do **not** use `@!method` — YARD will read the normal doc comment on the real
method:

```ruby
# @overload call(*revision_range, **options)
#
#   Execute the `git log` command.
#
#   @param revision_range [Array<String>] zero or more revision specifiers
#
#   @param options [Hash] command options
#
#   @option options [Boolean] :all (nil) ...
#
#   @return [Git::CommandLineResult] the result of calling `git log`
#
#   @raise [ArgumentError] if conflicting options are given
#
#   @raise [Git::FailedError] if git exits with a non-zero exit status
def call(*, **kwargs)
  # custom logic …
  super
end
```

Using `@!method` when `def call` already exists causes YARD to generate duplicate or
conflicting documentation for the method.

## What to Check

### 1. Class-level docs

- [ ] one-line summary
- [ ] brief behavior description
- [ ] `@api private`
- [ ] `@see` to parent command module where applicable
- [ ] `@see` to relevant git docs

### 2. Arguments docs

- [ ] `@overload` blocks cover valid call shapes
- [ ] every positional arg has `@param`
- [ ] every applicable option has `@option`
- [ ] `@option` entries appear in the same order as the corresponding entries in the
      `arguments do` block
- [ ] `@option` types match the DSL method used to define the option:

  | DSL method | YARD type |
  | --- | --- |
  | `flag_option` | `[Boolean]` |
  | `flag_or_value_option` | `[Boolean, String]` (or the specific value type) |
  | `value_option` | `[String]` (or a more specific type where known) |
  | `operand` (repeatable) | `[Array<String>]` |
  | `operand` (single) | `[String]` |

- [ ] option defaults/types are consistent with DSL definitions
- [ ] `@option` descriptions for options that have an `allowed_values` declaration
      enumerate the accepted values in the description text, e.g.: `@option options
      [String] :cleanup (nil) Cleanup mode — one of verbatim, whitespace, or
      strip`

### 3. Return and raise tags

- [ ] `@return [Git::CommandLineResult]` with wording: "the result of calling `git
      <subcommand>`"
- [ ] `@raise [Git::FailedError]` reflects range-based behavior (outside default
      `0..0` or declared `allow_exit_status` range)

### 4. `allow_exit_status` rationale consistency

When command declares non-default exit range:

- [ ] includes short rationale comment above declaration
- [ ] YARD `@raise` text does not contradict accepted status behavior

### 5. Formatting consistency

- [ ] all general formatting rules from [Write YARD
  Documentation](../write-yard-documentation/SKILL.md) are satisfied
- [ ] tag short descriptions (the first sentence of each `@param`, `@option`,
      `@return`, `@raise`, etc.) do not end with punctuation
- [ ] multi-paragraph tag descriptions have a blank comment line (`#`) between the
      short description and each continuation paragraph
- [ ] `@option` description text starts with a capital letter (sentence case)
- [ ] consistent option wording and defaults across sibling commands
- [ ] no stale references to removed per-command implementation details

### 6. Avoid internal implementation detail leakage

Prefer interface-level wording (what callers can pass/expect), not internals.

**Common example — stdin transport mechanism:**

```ruby
# Bad: leaks implementation detail (IO pipe, threading)
# Object names are written to the process's stdin via an in-memory IO pipe;
# this avoids spawning additional processes and works with the --batch protocol.

# Good: describes caller-facing behavior
# Object names are passed to the git process's stdin using the --batch protocol.
```

- [ ] description does not mention `IO.pipe`, threads, or pipe buffer management
- [ ] description does not reference internal method names (`with_stdin`,
  `run_batch`)
- [ ] description describes what the caller passes and what they get back

## Common issues

- Using `# @!method call(*, **)` when an explicit `def call` override exists — causes
  YARD to generate duplicate or conflicting documentation; remove the `@!method`
  directive and place the `@overload` docs directly above `def call`
- Missing `# @!method call(*, **)` directive when there is no `def call` override
  (loses child-specific docs in generated YARD)
- `@option` docs out of sync with `arguments do`
- Missing/incorrect `@raise` guidance for `allow_exit_status`
- Legacy references to `ARGS` constant or command-specific `initialize`
- Description leaks internal mechanics (e.g., "written via IO pipe") instead of
  describing caller-facing behavior
- **Trailing period on `@option` short description** — the inline text after the
  type and option key must not end with a period. This is easy to miss when
  transcribing from the git man page, which ends flag descriptions with periods.
  Run `bundle exec rake yard` to catch this — YARD treats any failure as fatal.
- **Raw blank line inside a doc comment block** — a raw blank line (an empty line
  with no leading `#`) silently terminates the YARD block. Any comment lines after
  the raw blank line are dropped from generated docs. Replace every raw blank line
  inside a block with a blank comment line (`#`). This is easy to miss in
  continuation paragraphs and alias notes. Correct form:

  ```ruby
  # @option options [Boolean] :ipv4 (nil) Use IPv4 addresses only
  #
  #   Alias: :"4"
  ```

- **Multi-sentence short description without a blank comment line** — when an
  `@option` needs more than one sentence, the first sentence is the short description
  and all additional detail must go in a continuation paragraph separated by a blank
  `#` line. Writing both sentences on the same run-in line violates YARD's
  short-description rule. Correct form:

  ```ruby
  # @option options [Boolean] :update_head_ok (false) Allow updating HEAD ref
  #
  #   When true, passes --update-head-ok. By default git fetch refuses to update HEAD.
  ```

## Output

For each file, provide:

1. issue table

   | Check | Status | Issue |
   | --- | --- | --- |

2. corrected doc block snippets (only where needed)

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or push
> directly to `main` — open a pull request when changes are ready to merge.
