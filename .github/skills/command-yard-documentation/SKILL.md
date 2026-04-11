---
name: command-yard-documentation
description: "Command-specific YARD documentation rules for Git::Commands::Base subclasses, overriding and extending the general yard-documentation skill. Use when writing or reviewing YARD docs for command classes."
---

# Command YARD Documentation

Write and verify YARD documentation for command classes aligned with
the `Git::Commands::Base` pattern. Use this skill when writing or reviewing
YARD docs on command classes — it overrides and extends the general
[YARD Documentation](../yard-documentation/SKILL.md) skill with
command-specific rules.

This skill verifies that YARD docs accurately mirror the `arguments do` block
as-implemented. It does not re-adjudicate which options belong based on Git
version — version gating is the domain of the DSL and the
[Command Implementation](../command-implementation/SKILL.md) skill, not YARD review.

## Contents

- [Contents](#contents)
- [Related skills](#related-skills)
- [Input](#input)
- [Reference](#reference)
  - [Required documentation model](#required-documentation-model)
    - [No `def call` override (simple commands)](#no-def-call-override-simple-commands)
    - [Explicit `def call` override](#explicit-def-call-override)
  - [DSL-to-YARD type mapping](#dsl-to-yard-type-mapping)
  - [Common issues](#common-issues)
- [Workflow](#workflow)
  - [1. Class-level docs](#1-class-level-docs)
  - [2. Arguments docs](#2-arguments-docs)
  - [3. Return and raise tags](#3-return-and-raise-tags)
  - [4. `allow_exit_status` rationale consistency](#4-allow_exit_status-rationale-consistency)
  - [5. Formatting consistency](#5-formatting-consistency)
  - [6. Avoid internal implementation detail leakage](#6-avoid-internal-implementation-detail-leakage)
- [Output](#output)
  - [When writing new YARD docs](#when-writing-new-yard-docs)
  - [When reviewing existing YARD docs](#when-reviewing-existing-yard-docs)

## Related skills

- [YARD Documentation](../yard-documentation/SKILL.md) — authoritative
  source for general YARD formatting rules and writing standards
- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries
  match git CLI
- [Command Implementation](../command-implementation/SKILL.md) — class
  structure, phased rollout gates, and internal compatibility contracts
- [Command Test Conventions](../command-test-conventions/SKILL.md) — unit/integration
  test conventions for command classes

## Input

Before starting, you **MUST** load the following skill(s) in their entirety:

- [YARD Documentation](../yard-documentation/SKILL.md) — authoritative
  source for YARD formatting rules and writing standards

Then gather the following for each command under review:

1. **Command source** — one or more files from `lib/git/commands/` containing:
   - `class < Git::Commands::Base`
   - `arguments do ... end`
   - optional `allow_exit_status`
   - either a `# @!method call(*, **)` YARD directive (when no `def call` override)
     or YARD doc comments directly above an explicit `def call` override

2. **Git documentation for the git command**

   - **Latest-version online command documentation**

     Read the **entire** official git documentation online man page for the command
     for the latest version of git. This version will be used as the primary
     authority for verifying option names, aliases, descriptions, and ordering.
     Fetch this version from the URL `https://git-scm.com/docs/git-{command}`
     (this URL always serves the latest release).

   - **Minimum-version online command documentation**

     Read the **entire** official git documentation online man page for the command
     for the `Git::MINIMUM_GIT_VERSION` version of git. This will be used to
     confirm whether the command/class is gated by `requires_git_version` and,
     when it is, that the YARD docs include a continuation paragraph noting the
     minimum version requirement. Fetch this version from the URL
     `https://git-scm.com/docs/git-{command}/{version}`.

   Do **not** rely on local `git <command> -h` output — the installed Git version
   is unknown and may differ from the minimum or latest supported version.

## Reference

### Required documentation model

The placement of `call` documentation depends on whether the command class overrides
`def call`.

#### No `def call` override (simple commands)

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

Note the placement rules:

- The `@overload` description text **must appear inside the `@overload` block** (indented
  one extra level, as in the template above). Do **not** place the description between
  the `@!method` line and the `@overload` tag — that level belongs to any `@!method`-scope
  prose that is not part of any overload, which is rarely needed.
- Place the directive inside the class body, after the `arguments do` block (and after
  `allow_exit_status` when present). Do **not** combine `@!method` with an explicit
  `def call`.

#### Explicit `def call` override

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

### DSL-to-YARD type mapping

| DSL method | YARD type |
| --- | --- |
| `flag_option` | `[Boolean]` |
| `flag_option ..., max_times: N` | `[Boolean, Integer]` |
| `flag_option ..., negatable: true` | `[Boolean]` — document both `true` (→ `--flag`) and `false` (→ `--no-flag`) forms |
| `flag_or_value_option` | `[Boolean, String]` (or the specific value type) |
| `flag_or_value_option ..., negatable: true` | `[Boolean, String]` — document `true` (→ `--flag`), string (→ `--flag=value`), and `false` (→ `--no-flag`) forms |
| `value_option` | `[String]` (or a more specific type where known) |
| `operand` (repeatable) | `[Array<String>]` |
| `operand` (single) | `[String]` |

### Common issues

- Using `# @!method call(*, **)` when an explicit `def call` override exists — causes
  YARD to generate duplicate or conflicting documentation; remove the `@!method`
  directive and place the `@overload` docs directly above `def call`
- Missing `# @!method call(*, **)` directive when there is no `def call` override
  (loses child-specific docs in generated YARD)
- `@option` docs out of sync with `arguments do`
- **Missing negated form for `negatable:` options** — when the DSL declares
  `flag_option :foo, negatable: true` or `flag_or_value_option :foo, negatable: true`,
  the `@option` prose must document both `false` → `--no-foo` and `true` → `--foo`.
  Documenting only the positive form misleads callers who pass `false`.

  ```ruby
  # ❌ Missing negated form
  # @option options [Boolean] :create_reflog (nil)
  #   create the branch's reflog

  # ✅ Documents both forms
  # @option options [Boolean] :create_reflog (nil)
  #   create the branch's reflog
  #
  #   Pass `true` for `--create-reflog`, `false` for `--no-create-reflog`.
  ```
- Missing/incorrect `@raise` guidance for `allow_exit_status`
- **Overly specific `@raise [Git::FailedError]` description** — do not enumerate
  specific failure causes (e.g., "if the branch doesn't exist", "if the target
  already exists"). Git can fail for many reasons beyond any list (invalid ref name,
  not a git repository, permission error, etc.). Use the generic range-based form:

  ```ruby
  # ❌ Overly specific — does not cover all failure cases
  # @raise [Git::FailedError] if the branch doesn't exist or target exists (without force)

  # ✅ Correct — generic, matches sibling commands, accurate for all failure causes
  # @raise [Git::FailedError] if git exits with a non-zero exit status
  ```

  For commands with a non-default range (e.g. `allow_exit_status 0..1`):

  ```ruby
  # ✅ Correct for allow_exit_status 0..1
  # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
  ```
- Legacy references to `ARGS` constant or command-specific `initialize`
- **`@option` description references a short flag instead of the emitted long flag** —
  `@option` prose must describe behavior using the emitted CLI form (the long flag),
  not the git man-page synopsis short notation. The DSL emits the primary (long) flag
  regardless of which alias the caller uses.

  ```ruby
  # ❌ Wrong — describes -v as if it is emitted
  # @option options [Boolean, Integer] :verbose (nil) ...
  #   Pass `true` for `-v`; pass `2` for `-v -v`.

  # ✅ Correct — describes the actually emitted flag
  # @option options [Boolean, Integer] :verbose (nil) ...
  #   Pass `true` for `--verbose`; pass `2` for `--verbose --verbose`.
  ```

- Description leaks internal mechanics (e.g., "written via IO pipe") instead of
  describing caller-facing behavior
- **Uppercase first letter or trailing period on tag short descriptions** — the
  summary text of every `@option`, `@param`, `@return`, and `@raise` tag must start
  with a **lowercase** letter and must not end with punctuation (`.`, `,`, `;`, `:`).
  Git man pages start descriptions with uppercase and end them with periods; both
  mistakes are easy to copy verbatim. Run `bundle exec rake yard` to catch trailing
  periods — YARD treats any failure as fatal. Correct form:

  ```ruby
  # ❌ Copied verbatim from the git man page
  # @option options [Boolean] :force (nil) Allow renaming even if target already exists.

  # ✅ Correct — lowercase start, no trailing period
  # @option options [Boolean] :force (nil) allow renaming even if target already exists
  ```
- **Raw blank line inside a doc comment block** — a raw blank line (an empty line
  with no leading `#`) silently terminates the YARD block. Any comment lines after
  the raw blank line are dropped from generated docs. Replace every raw blank line
  inside a block with a blank comment line (`#`). This is easy to miss in
  continuation paragraphs and alias notes. Correct form:

  ```ruby
  # @option options [Boolean] :ipv4 (nil) use IPv4 addresses only
  #
  #   Alias: :"4"
  ```

- **Multi-sentence short description without a blank comment line** — when an
  `@option` needs more than one sentence, the first sentence is the short description
  and all additional detail must go in a continuation paragraph separated by a blank
  `#` line. Writing both sentences on the same run-in line violates YARD's
  short-description rule. Correct form:

  ```ruby
  # @option options [Boolean] :update_head_ok (false) allow updating HEAD ref
  #
  #   When true, passes --update-head-ok. By default git fetch refuses to update HEAD.
  ```

## Workflow

For each command file, run through these checks in order:

### 1. Class-level docs

- [ ] one-line summary
- [ ] brief behavior description
- [ ] `@example` blocks with representative usage
- [ ] ``@note `arguments` block audited against https://git-scm.com/docs/git-{command}/<version>`` —
      present and recording the latest git version at the time of the last DSL audit.
      Flag as an error if missing or if the version in the URL does not match the
      current latest git version (run `bin/latest-git-version` from the repo root to
      check; a stale version means the DSL may be missing options added in later releases)
- [ ] `@see` to parent command module where applicable
- [ ] `@see` to the full documentation URL (e.g., `@see https://git-scm.com/docs/git-show-ref`)
- [ ] `@api private`

### 2. Arguments docs

- [ ] `@overload` blocks cover valid call shapes
- [ ] every positional arg has `@param`
- [ ] every applicable option has `@option`
- [ ] `@option` entries appear in the same order as the corresponding entries in the
      `arguments do` block
- [ ] `@option` types match the DSL method (see
      [DSL-to-YARD type mapping](#dsl-to-yard-type-mapping))
- [ ] option defaults/types are consistent with DSL definitions
- [ ] `@option` descriptions for options that have an `allowed_values` declaration
      enumerate the accepted values in the description text, e.g.: `@option options
      [String] :cleanup (nil) Cleanup mode — one of verbatim, whitespace, or
      strip`

### 3. Return and raise tags

- [ ] `@return [Git::CommandLineResult]` with wording: "the result of calling `git
      <subcommand>`"
- [ ] `@raise [Git::FailedError]` uses the canonical generic wording — **never**
      enumerate specific failure causes; use the form that matches the command's
      declared exit-status range:

  | `allow_exit_status` | Canonical `@raise` wording |
  |---|---|
  | none declared (default `0..0`) | `if git exits with a non-zero exit status` |
  | `allow_exit_status 0..1` | `if git exits outside the allowed range (exit code > 1)` |
  | `allow_exit_status 0..N` | `if git exits outside the allowed range (exit code > N)` |

### 4. `allow_exit_status` rationale consistency

When command declares non-default exit range:

- [ ] includes short rationale comment above declaration
- [ ] YARD `@raise` text does not contradict accepted status behavior

### 5. Formatting consistency

- [ ] every YARD tag (`@param`, `@option`, `@return`, `@raise`, `@overload`,
      `@see`, `@api`, etc.) is preceded by a blank comment line (`#`)
- [ ] no raw blank lines (lines with no leading `#`) appear inside any doc block —
      a raw blank line silently terminates the block and drops everything after it
- [ ] tag short descriptions (the first sentence of each `@param`, `@option`,
      `@return`, `@raise`, etc.) do not end with punctuation (no `.`, `,`, `;`, `:`)
- [ ] multi-paragraph tag descriptions have a blank comment line (`#`) between the
      short description and each continuation paragraph
- [ ] `@option`, `@param`, `@return`, and `@raise` short descriptions all start with a
      **lowercase** letter (e.g. `show the HEAD ref even when filtered`, `the path to the
      repository`, `the result of calling \`git show-ref\``, `if git exits with a non-zero
      status`)
- [ ] consistent option wording and defaults across sibling commands
- [ ] `max_times:` flags use `[Boolean, Integer]` type, not just `[Boolean]`, and
      include a continuation paragraph explaining integer semantics (e.g. "When an
      integer is given, the flag is repeated that many times")
- [ ] no stale references to removed per-command implementation details
- [ ] all other general formatting rules from [YARD
  Documentation](../yard-documentation/SKILL.md) are satisfied

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

## Output

### When writing new YARD docs

Produce the complete YARD doc block(s) for the command class, then self-verify
by running every checklist item from [Workflow](#workflow) against your output.
If any issues are found, fix and re-verify until all checks pass.

### When reviewing existing YARD docs

For each file, provide:

1. issue table

   | Check | Status | Issue |
   | --- | --- | --- |

2. corrected doc block snippets (only where needed)

3. **Self-verify before concluding** — after writing corrected snippets, re-run
   every checklist item from [Workflow](#workflow) against your proposed
   snippets. If any new issues are found, update the snippets and repeat until all
   checks pass. Only then write the final issue table marking everything as passing.

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or push
> directly to `main` — open a pull request when changes are ready to merge.
