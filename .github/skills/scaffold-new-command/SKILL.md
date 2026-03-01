---
name: scaffold-new-command
description: "Generates a production-ready Git::Commands::* class with unit tests, integration tests, and YARD docs using the Base architecture. Use when creating a new command from scratch."
---

# Scaffold New Command

Generate a production-ready command class, unit tests, integration tests, and YARD
docs using the `Git::Commands::Base` architecture.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Files to generate](#files-to-generate)
- [Command template (Base pattern)](#command-template-base-pattern)
- [Output-format options are intentionally omitted](#output-format-options-are-intentionally-omitted)
- [DSL ordering convention](#dsl-ordering-convention)
- [Exit status guidance](#exit-status-guidance)
- [Unit tests](#unit-tests)
- [Integration tests](#integration-tests)
- [YARD requirements](#yard-requirements)
- [Phased rollout, compatibility, and quality gates](#phased-rollout-compatibility-and-quality-gates)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the git
subcommand name and the Ruby module path for the new class. Examples:

```text
Using the Scaffold New Command skill, scaffold Git::Commands::Worktree::Add
for `git worktree add`.
```

```text
Scaffold New Command: Git::Commands::LsTree for `git ls-tree`.
```

The invocation needs the target `Git::Commands::*` class name and the git
subcommand (or subcommand + sub-action) it wraps.

## Related skills

- [Review Command Implementation](../review-command-implementation/SKILL.md) — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts
- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries match git CLI
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test expectations for command classes
- [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md) — documentation completeness for command classes

## Files to generate

For `Git::Commands::Foo::Bar`:

- `lib/git/commands/foo/bar.rb`
- `spec/unit/git/commands/foo/bar_spec.rb`
- `spec/integration/git/commands/foo/bar_spec.rb`

Optional (first command in module):

- `lib/git/commands/foo.rb`

## Command template (Base pattern)

```ruby
# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Foo
      # Summary...
      #
      # @api private
      class Bar < Git::Commands::Base
        arguments do
          # literals/options/operands
        end

        # Optional: for commands where non-zero exits are valid
        # rationale comment
        # allow_exit_status 0..1

        # @!method call(*, **)
        #
        #   @overload ...
        #
        #     Execute the git ... command.
        #
        #     @return [Git::CommandLineResult] the result of calling `git ...`
        #
        #     @raise [Git::FailedError] if git exits outside allowed status range
      end
    end
  end
end
```

The template above uses the default `def call(...) = super` implicitly — no explicit
`call` definition is needed in the common case. For commands that require input
validation, stdin feeding (`Base#with_stdin`), or non-trivial option routing, see
the [`#call` override guidance](../review-command-implementation/SKILL.md#2-call-implementation)
in the Review Command Implementation skill.

## Output-format options are intentionally omitted

The library requires **deterministic, parseable output** from each command class.
For this reason, options that change the **structure or format** of a command's
primary output are **deliberately excluded** from the DSL.

Do **not** add options such as `--format=`, `--pretty=`, `--porcelain`,
`--patch`, `--stat`, `--numstat`, `--shortstat`, `--raw`, `--name-only`, or
`--name-status`. Including them would allow callers to produce output that a
parser cannot handle.

**Do** include options that do not affect stdout — for example `--dry-run`/`-n`,
`--force`, `--ignore-errors`, etc.

The test for any option, including `--verbose`/`-v` and `--quiet`/`-q`: run the
command with and without the option and diff stdout. If stdout changes → exclude
it. Do not assume verbosity flags are safe sidechannel options; verify first.

## DSL ordering and argument conventions

For the full DSL reference including ordering rules, correct DSL methods per option
type, alias conventions, `as:` usage, modifier rules, constraint declarations
(`conflicts`, `forbid_values`, `requires_exactly_one_of`, `requires_one_of`,
`requires`), and pathspec conventions, see the
[Arguments DSL Checklist](../review-arguments-dsl/CHECKLIST.md).

**Key principles (summary):**

- Define arguments in the order they appear in the git-scm.com SYNOPSIS
- Within unordered groups: literals → flag options → flag-or-value options → value
  options → operands → pathspecs → constraint declarations
- Use aliases for long/short forms (`%i[force f]`), long name first
- When the git SYNOPSIS has `[<tree-ish>] [--] [<pathspec>...]`, use keyword form
  (`value_option :pathspec, as_operand: true, separator: '--'`) for the post-`--`
  group
- When the SYNOPSIS has pure nesting (`[<a> [<b>]]`), use plain `operand` entries
- Avoid `as:` unless it's a Ruby keyword conflict, combined short flag, or
  multi-token flag

## Exit status guidance

- Default: no declaration needed (`0..0` from `Base`)
- Non-default: declare `allow_exit_status <range>` and add rationale comment

Examples:

```ruby
# git diff exits 1 when differences are found (not an error)
allow_exit_status 0..1
```

```ruby
# fsck uses exit codes 0-7 as bit flags for findings
allow_exit_status 0..7
```

## Unit tests

Command unit tests should verify:

- exact arguments passed to `execution_context.command`
- inclusion of `raise_on_failure: false` (from `Base` behavior)
- execution-option forwarding where relevant (`timeout:`, etc.)
- allow-exit-status behavior where declared
- input validation (`ArgumentError`)

## Integration tests

Minimal structure:

- `describe 'when the command succeeds'`
- `describe 'when the command fails'`

Include at least one failure case per command.

## YARD requirements

- use `# @!method call(*, **)` YARD directive with nested `@overload` blocks for per-command docs
- add `@overload` blocks for valid call shapes, indented under `@!method`
- keep tags aligned with `arguments do` and `allow_exit_status` behavior

## Phased rollout, compatibility, and quality gates

See [Review Command Implementation](../review-command-implementation/SKILL.md) for the canonical phased rollout checklist,
internal compatibility contract, and quality gate commands. In summary:

- **always work on a feature branch** — never commit or push directly to `main`;
  create a branch before starting (`git checkout -b <feature-branch-name>`) and
  open a pull request when the slice is ready
- migrate in small slices (pilot or family), not all commands at once
- keep each slice independently revertible
- pass per-slice gates: `bundle exec rspec`, `bundle exec rake test`,
  `bundle exec rubocop`, `bundle exec rake yard`
