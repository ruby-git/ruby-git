---
name: review-command-implementation
description: "Verifies a command class follows the Git::Commands::Base architecture contract and contains no duplicated execution behavior. Use after implementing or modifying a command class."
---

# Review Command Implementation

Verify a command class follows the current `Git::Commands::Base` architecture and
contains no duplicated execution behavior.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Input](#input)
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

## Related skills

- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries match git CLI
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test expectations for command classes
- [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md) — documentation completeness for command classes
- [Review Cross-Command Consistency](../review-cross-command-consistency/SKILL.md) — sibling consistency within a command family

## Input

Required: one or more command source files from `lib/git/commands/`.

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

Shared behavior lives in `Base`:

- binds arguments
- calls `@execution_context.command(*args, **args.execution_options, raise_on_failure: false)`
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
- [ ] Override calls `args_definition.bind(...)` directly — does *not* duplicate `Base#call` logic
- [ ] Exit-status validation delegates to `validate_exit_status!` (not reimplemented inline)
- [ ] Stdin-feeding commands use `Base#with_stdin` (not a manual `IO.pipe` inline)
- [ ] Bulk of override is extracted into a private helper (`run_batch`, etc.) to satisfy Rubocop `Metrics` thresholds
- [ ] Does not parse output in command class

#### `#call` override guidance

Most commands use `def call(...) = super`, which forwards all arguments to
`Base#call` for binding, execution, and exit-status validation.

**Override `call` only when the command needs:**

1. **Input validation** — raise `ArgumentError` for invalid option combinations
   the DSL cannot express (e.g., mutually exclusive modes)
2. **stdin feeding** — batch protocols (`--batch`, `--batch-check`) via
   `Base#with_stdin`
3. **Non-trivial option routing** — build different argument sets based on
   which options are present

**When overriding:**

- Bind arguments via `args_definition.bind(...)` — do not reimplement binding
- Delegate exit-status handling to `validate_exit_status!` — do not reimplement
- Do not call `super` after manual binding; use `@execution_context.command` directly

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
def call(object_names:, **kwargs)
  with_stdin(object_names.join("\n")) do |stdin_r|
    run_batch(stdin_r, **kwargs)
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
