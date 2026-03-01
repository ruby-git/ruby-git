---
name: review-command-yard-documentation
description: "Verifies YARD documentation for command classes is complete, accurate, and aligned with the Git::Commands::Base pattern. Use to audit documentation quality for commands."
---

# Review Command YARD Documentation

Verify YARD documentation for command classes is complete, accurate, and aligned
with the `Git::Commands::Base` pattern.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Input](#input)
- [Required documentation model](#required-documentation-model)
- [What to Check](#what-to-check)
  - [1. Class-level docs](#1-class-level-docs)
  - [2. Arguments docs](#2-arguments-docs)
  - [3. Return and raise tags](#3-return-and-raise-tags)
  - [4. `allow_exit_status` rationale consistency](#4-allow-exit-status-rationale-consistency)
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

## Related skills

- [Write YARD Documentation](../write-yard-documentation/SKILL.md) — authoritative source for general YARD formatting rules and writing standards
- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries match git CLI
- [Review Command Implementation](../review-command-implementation/SKILL.md) — class structure, phased rollout gates, and
  internal compatibility contracts
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test expectations for command classes

## Input

One or more command files from `lib/git/commands/` containing:

- `class < Git::Commands::Base`
- `arguments do ... end`
- optional `allow_exit_status`
- `# @!method call(*, **)` YARD directive with nested `@overload` blocks

## Required documentation model

Each command must use the `@!method` YARD directive to attach per-command
documentation to the inherited `call` method:

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

This directive is documentation scaffolding — YARD uses it to render per-command
docs on the inherited `call` method without requiring a method definition in the
subclass.

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
- [ ] `@option` entries appear in the same order as the corresponding entries in
      the `arguments do` block
- [ ] `@option` types match the DSL method used to define the option:

  | DSL method | YARD type |
  |---|---|
  | `flag_option` | `[Boolean]` |
  | `flag_or_value_option` | `[Boolean, String]` (or the specific value type) |
  | `value_option` | `[String]` (or a more specific type where known) |
  | `operand` (repeatable) | `[Array<String>]` |
  | `operand` (single) | `[String]` |

- [ ] option defaults/types are consistent with DSL definitions
- [ ] `@option` descriptions for options that have an `allowed_values` declaration
      enumerate the accepted values in the description text, e.g.:
      `@option options [String] :cleanup (nil) Cleanup mode — one of `verbatim`, `whitespace`, `strip``

### 3. Return and raise tags

- [ ] `@return [Git::CommandLineResult]` with wording:
      `the result of calling \`git <subcommand>\``
- [ ] `@raise [Git::FailedError]` reflects range-based behavior
      (outside default `0..0` or declared `allow_exit_status` range)

### 4. `allow_exit_status` rationale consistency

When command declares non-default exit range:

- [ ] includes short rationale comment above declaration
- [ ] YARD `@raise` text does not contradict accepted status behavior

### 5. Formatting consistency

- [ ] all general formatting rules from [Write YARD Documentation](../write-yard-documentation/SKILL.md) are satisfied
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
- [ ] description does not reference internal method names (`with_stdin`, `run_batch`)
- [ ] description describes what the caller passes and what they get back

## Common issues

- Missing `# @!method call(*, **)` directive (loses child-specific docs in generated YARD)
- `@option` docs out of sync with `arguments do`
- Missing/incorrect `@raise` guidance for `allow_exit_status`
- Legacy references to `ARGS` constant or command-specific `initialize`
- Description leaks internal mechanics (e.g., "written via IO pipe") instead of describing caller-facing behavior

## Output

For each file, provide:

1. issue table

   | Check | Status | Issue |
   | --- | --- | --- |

2. corrected doc block snippets (only where needed)

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
