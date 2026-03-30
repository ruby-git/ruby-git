---
name: review-command-implementation
description: "Verifies a command class follows the Git::Commands::Base architecture contract and contains no duplicated execution behavior. Use after implementing or modifying a command class."
---

# Review Command Implementation

Verify a command class follows the current `Git::Commands::Base` architecture and
contains no duplicated execution behavior.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Prerequisites](#prerequisites)
- [Related skills](#related-skills)
- [Input](#input)
- [Version-Aware Review Scope](#version-aware-review-scope)
- [Architecture Contract (Current)](#architecture-contract-current)
- [What to Check](#what-to-check)
  - [1. Class shape](#1-class-shape)
  - [2. `#call` implementation](#2-call-implementation)
  - [3. Exit-status configuration](#3-exit-status-configuration)
  - [4. Arguments DSL quality](#4-arguments-dsl-quality)
  - [5. Internal compatibility contract](#5-internal-compatibility-contract)
  - [6. Phased rollout / rollback requirements](#6-phased-rollout-rollback-requirements)
- [Common Failures](#common-failures)
- [Output](#output)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with one or more
command source files to review. Examples:

```text
Using the Review Command Implementation skill, review
lib/git/commands/branch/delete.rb.
```

```text
Review Command Implementation: lib/git/commands/diff/patch.rb
lib/git/commands/diff/numstat.rb
```

The invocation needs the command file(s) to review.

## Prerequisites

Before starting, you **MUST** load the following skill(s) in their entirety:

- [YARD Documentation](../yard-documentation/SKILL.md) — authoritative
  source for YARD formatting rules and writing standards;

## Related skills

- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries match git CLI
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test expectations for command classes
- [Command YARD Documentation](../command-yard-documentation/SKILL.md) — documentation completeness for command classes
- [Review Cross-Command Consistency](../review-cross-command-consistency/SKILL.md) — sibling consistency within a command family

## Input

Required: one or more command source files from `lib/git/commands/`.

## Version-Aware Review Scope

Before judging whether a command implementation or its DSL surface is correct,
determine the repository's minimum supported Git version from project metadata.
In this repository, `git.gemspec` declares `git 2.28.0 or greater`.

For compatibility-sensitive conclusions, use sources in this order:

1. Version-matched upstream documentation for the minimum supported Git version
2. Version-matched upstream source when parser behavior is ambiguous in docs
3. Local `git <command> -h` output only as a supplemental check for the installed Git

Do not fail or require implementation changes solely because the locally
installed Git advertises newer options or flag forms that are not confirmed for
the minimum supported version.

## Architecture Contract (Current)

For migrated commands, the expected structure is:

```ruby
require 'git/commands/base'

class SomeCommand < Git::Commands::Base
  arguments do
    ...
  end

  # optional for non-zero successful exits
  # reason comment
  allow_exit_status 0..1

  # @!method call(*, **)
  #
  #   @overload call(**options)
  #
  #     YARD docs for this command's call signature.
  #
  #     @return [Git::CommandLineResult]
end
```

The `@!method` directive is the correct YARD form when the class contains **no
explicit `def call`** — YARD uses it to render per-command docs on the inherited
`call` method. When the class **does** define `def call` explicitly, place YARD
docs directly above `def call` and omit the `@!method` directive.

Shared behavior lives in `Base`:

- binds arguments
- calls `@execution_context.command_capturing(*args, **args.execution_options, raise_on_failure: false)`
- raises `Git::FailedError` unless exit status is in allowed range (`0..0` default)

## What to Check

### 1. Class shape

- [ ] Class inherits from `Git::Commands::Base`
- [ ] Requires `git/commands/base` (not `git/commands/arguments`)
- [ ] Has exactly one `arguments do` declaration
- [ ] Does not define command-specific `initialize` that only assigns
      `@execution_context`

### 2. `#call` implementation

**Simple commands** (no pre-call logic needed):
- [ ] Uses `# @!method call(*, **)` YARD directive with nested `@overload` blocks as documentation shim
- [ ] Contains no custom bind/execute/exit-status logic
- [ ] Does not parse output in command class

**Commands with legitimate `call` overrides** (input validation, stdin protocol, non-trivial option routing):
- [ ] YARD docs are placed **directly above** `def call` (no `@!method` directive)
- [ ] Override calls `args_definition.bind(...)` directly — does *not* duplicate `Base#call` logic
- [ ] Exit-status validation delegates to `validate_exit_status!` (not reimplemented inline)
- [ ] Stdin-feeding commands use `Base#with_stdin` (not a manual `IO.pipe` inline)
- [ ] Any `ArgumentError` raised manually or via DSL constraint covers only what
      git cannot validate: per-argument failures and constraints on `skip_cli: true`
      arguments. Cross-argument constraint methods are **not** declared for
      git-visible arguments — the narrow exception is arguments git cannot observe
      in its argv (e.g., `skip_cli: true` operands: `conflicts :objects,
      :batch_all_objects` and `requires_one_of :objects, :batch_all_objects`).
      See the validation delegation policy in
      `redesign/3_architecture_implementation.md` Insight 6.
- [ ] Bulk of override is extracted into a private helper (`run_batch`, etc.) to satisfy Rubocop `Metrics` thresholds
- [ ] Does not parse output in command class

#### `#call` override guidance

Most commands use only a `# @!method call(*, **)` YARD directive with no
explicit `def call` — the inherited `Base#call` handles binding, execution,
and exit-status validation automatically. Do **not** add `def call(*, **) = super`
or `def call(*, **) / super / end` for commands that need no custom logic; it
adds no behavior and conflicts with the `@!method` directive.

**Override `call` only when the command needs:**

1. **Input validation the DSL cannot express** — per-argument validation parameters
  (`required:`, `type:`, `allow_nil:`, etc.) and operand format validation belong
  in `arguments do`. Cross-argument constraint methods are generally **not** declared;
  git validates its own option semantics. The narrow exception is **arguments git
  cannot observe in its argv**: if an argument is `skip_cli: true` and never
  reaches git's argv, git cannot detect incompatibilities — use `conflicts` and/or
  `requires_one_of` in the DSL (e.g., `cat-file --batch` uses both because
  `:objects` is `skip_cli: true`). Do not raise `ArgumentError` manually for things
  the DSL can express via a constraint declaration.
2. **stdin feeding** — batch protocols (`--batch`, `--batch-check`) via
   `Base#with_stdin`
3. **Non-trivial option routing** — build different argument sets based on
   which options are present
4. **Action-option-with-optional-value** — when the command's primary action is
   expressed as an option with an optional value (man-page notation:
   `--flag[=<value>]`). The DSL entry uses `flag_or_value_option :name, inline:
   true, type: [TrueClass, String]` and the override maps a positional `call` API
   onto the keyword:

   ```ruby
   def call(value = true, *, **)
     super(*, **, option_name: value)
   end
   ```

   See [Action-option-with-optional-value commands](../scaffold-new-command/SKILL.md#action-option-with-optional-value-commands)
   for the full pattern and rationale.

**When overriding:**

- Bind arguments via `args_definition.bind(...)` — do not reimplement binding
- Delegate exit-status handling to `validate_exit_status!` — do not reimplement
- Do not call `super` after manual binding; use `@execution_context.command_capturing` directly

**`Base#with_stdin(content)` mechanics:**

`Base#with_stdin(content)` opens an `IO.pipe`, spawns a background `Thread` that
writes `content` to the write end (then closes it), and yields the read end as
`in:` to the execution context. The threaded write prevents deadlocks when
`content` exceeds the OS pipe buffer — the subprocess can drain the pipe
concurrently. The thread also rescues `Errno::EPIPE` / `IOError` so it exits
cleanly if the subprocess closes stdin early.

Use `with_stdin` instead of manual pipe management. `StringIO` cannot be used
because `Process.spawn` requires a real file descriptor.

Example — batch stdin protocol (as used by `git cat-file --batch`):

```ruby
def call(*, **)
  bound = args_definition.bind(*, **)
  with_stdin(Array(bound.objects).map { |object| "#{object}\n" }.join) do |stdin_r|
    run_batch(bound, stdin_r)
  end
end
```

**DSL defaults:**

Defaults defined in the DSL (e.g., `operand :paths, default: ['.']`) are applied
automatically during `args_definition.bind(...)` — do not set defaults manually in
`call`.

### 3. Exit-status configuration

- [ ] Commands with non-zero successful exits declare `allow_exit_status <range>`
- [ ] Declaration includes a short rationale comment explaining git semantics
- [ ] Range values match expected command behavior

### 4. Arguments DSL quality

- [ ] DSL entries accurately describe subcommand interface
- [ ] Option aliases and modifiers are used correctly
- [ ] Ordering produces expected CLI argument order
- [ ] No `literal` entries for output-control, editor-suppression, or progress flags
      (e.g. `--no-edit`, `--verbose`, `--no-progress`, `--no-color`). Command classes
      are neutral, faithful representations of the git CLI — these must be
      `flag_option` / `value_option` so the facade can control them. See
      "Command-layer neutrality" in CONTRIBUTING.md.
- [ ] `operand ... skip_cli: true` is used only for domain inputs that must bind/validate
  but must not emit to argv (for example, stdin-fed object lists)
- [ ] `execution_option` is used for execution kwargs (`timeout:`, `chdir:`), not `skip_cli`
- [ ] `execution_option` is **not** used for kwargs whose value must be unconditionally
      fixed regardless of caller input. If a kwarg always has a specific required value
      (e.g. `chomp: false` for commands returning raw content where trailing newlines are
      data), hardcode it in a `def call` override instead — exposing it via
      `execution_option` would allow callers to override a value that must never change.

### 5. Internal compatibility contract

This is the canonical location for the internal compatibility contract. Other
skills reference this section rather than duplicating it.

Ensure refactors preserve these contract expectations:

- [ ] constructor shape remains `initialize(execution_context)` (inherited from `Base`)
- [ ] command entrypoint remains `call(*, **)` at runtime (via `Base#call`)
- [ ] argument-definition metadata remains available via `args_definition`

If an intentional deviation exists, require migration notes/changelog documentation.

### 6. Phased rollout / rollback requirements

This is the canonical location for phased rollout requirements. Other skills
reference this section rather than duplicating the full checklist.

For migration PRs, verify process constraints:

- [ ] changes are on a feature branch — **never commit or push directly to `main`**
- [ ] migration slice is scoped (pilot or one family), not all commands at once
- [ ] each slice is independently revertible
- [ ] refactor-only changes are not mixed with unrelated behavior changes
- [ ] quality gates pass for the slice (`bundle exec rspec`, `bundle exec rake test`,
      `bundle exec rubocop`, `bundle exec rake yard`)

## Common Failures

### Policy/output-control flag hardcoded as `literal` (neutrality violation)

`literal` entries for output-control, editor-suppression, progress, or verbose
flags inside a command class violate the neutrality principle. The command class
must model the git CLI faithfully; the facade sets safe defaults and callers may
override them.

Symptom: the command class contains one or more of:

```ruby
# ❌ Any of these are neutrality violations
literal '--no-edit'
literal '--verbose'
literal '--no-progress'
literal '--no-color'
literal '--porcelain'
```

Fix: convert each to a DSL option and pass the policy value from the facade:

```ruby
# ✅ In the command class — neutral DSL declaration
flag_option :edit, negatable: true
flag_option :progress, negatable: true
flag_option :verbose
value_option :format

# ✅ In Git::Lib — facade passes the policy value explicitly
Git::Commands::Pull.new(self).call(edit: false, progress: false)
Git::Commands::Mv.new(self).call(*args, verbose: true)
Git::Commands::Fsck.new(self).call(progress: false)
```

See "Command-layer neutrality" in CONTRIBUTING.md for the full policy.

### Other common failures

- lingering `ARGS = Arguments.define` constant and custom `#call`
- command-specific duplicated exit-status checks instead of `allow_exit_status`
- missing rationale comment for `allow_exit_status`
- missing YARD directive (`# @!method call(*, **)`)
- `call` override that reimplements `Base#call` logic instead of delegating to `validate_exit_status!`
- using a manual `IO.pipe` inline instead of `Base#with_stdin` for stdin-feeding commands
- migration PR scope too broad (not phased)

## Output

For each file, produce:

| Check | Status | Issue |
| --- | --- | --- |
| Base inheritance | Pass/Fail | ... |
| arguments DSL | Pass/Fail | ... |
| call shim | Pass/Fail | ... |
| allow_exit_status usage | Pass/Fail | ... |
| output parsing absent | Pass/Fail | ... |
| compatibility contract | Pass/Fail | ... |

Then list required fixes and indicate whether the migration slice is safe to merge
under phased-rollout rules.
