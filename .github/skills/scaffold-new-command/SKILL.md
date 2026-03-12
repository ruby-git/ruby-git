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
- [Single class vs. sub-command namespace](#single-class-vs-sub-command-namespace)
- [Command template (Base pattern)](#command-template-base-pattern)
- [Options completeness — consult the man page first](#options-completeness--consult-the-man-page-first)
- [Output-format options are intentionally omitted](#output-format-options-are-intentionally-omitted)
- [DSL ordering and argument conventions](#dsl-ordering-and-argument-conventions)
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

- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline RSpec rules all generated unit specs must comply with
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

## Single class vs. sub-command namespace

Most git commands map to a single class. Split into a namespace module with
multiple sub-command classes when the git command surfaces **meaningfully
different operations** that have distinct call shapes or protocols.

### When to use sub-commands

**Split by operation** — when the git command has named sub-actions whose
option sets have little overlap (each sub-action would have mostly dead options
if they shared one class):

```
git stash push / pop / apply / drop / list / show
git tag --create / --delete / --list
git worktree add / list / remove / move
```

**Split by stdin protocol** — when one variant reads from stdin and another
does not (even if the git command is the same). The stdin variant needs a
`call` override that uses `Base#with_stdin`; mixing that with a no-stdin path
in one class produces an awkward interface.

### Do NOT split by output format / output mode

**Output-mode flags are NOT a reason to create separate subclasses.** When a
git command supports multiple output formats via flags (`--patch`, `--numstat`,
`--raw`, `--format=…`, etc.), express them as `flag_option` or `value_option`
entries in a **single class**. The facade passes the desired format flags
explicitly at call time:

```ruby
# ❌ Anti-pattern: one class per output format
class Diff::Patch < Git::Commands::Base; end    # literal '--patch'
class Diff::Numstat < Git::Commands::Base; end  # literal '--numstat'
class Diff::Raw < Git::Commands::Base; end      # literal '--raw'

# ✅ Correct: one class, output mode as options
class Diff < Git::Commands::Base
  arguments do
    literal 'diff'
    flag_option :patch    # facade passes patch: true when it needs patch output
    flag_option :numstat  # facade passes numstat: true for stats
    flag_option :raw      # facade passes raw: true for raw output
    ...
  end
end

# lib/git/lib.rb — parser contract is visible and auditable:
Git::Commands::Diff.new(self).call(patch: true, numstat: true, ...)
```

The same applies for `--format=<string>`, `--pretty=<fmt>`, `--no-color`, and
all other parser-contract options. Declare them in the DSL; the facade passes them.

Remember: **`literal` entries are only for operation selectors** — fixed flags
that define which git sub-operation the class represents (e.g., `literal 'stash'`,
`literal 'show'`, `literal '--delete'`). Output-format flags are not operation
selectors.

### When to keep a single class

- Different output modes (`--patch`, `--numstat`, `--raw`): **always** use a
  single class; expose modes as DSL options.
- Minor option variations that share the same argument set.
- When the "special mode" is just 1–2 flags — use `flag_option`/`value_option`.
- When callers would always need multiple modes together (the facade composes them).

### Naming sub-command classes

Prefer **user-oriented names** (what the caller gets back) over flag names
(implementation detail the caller shouldn't need to know):

```
# Avoid — leaks implementation detail
CatFile::BatchCheck / CatFile::Batch

# Prefer — describes the result from the caller's perspective
CatFile::ObjectMeta / CatFile::ObjectContent
```

Two hard constraints:

- **Never name a sub-command class `Object`** — it shadows Ruby's `::Object`
  base class anywhere that constant is looked up inside the namespace.
- **Never use the `*Info` or `*Result` suffix** on command classes — those
  suffixes are reserved for parsed result structs (`BranchInfo`, `TagInfo`,
  `BranchDeleteResult`) which live in the top-level `Git::` namespace, not
  in `Git::Commands::*`. A reader seeing `CommandFoo::BarInfo` expects a data
  struct, not a class that runs a subprocess.

### Namespace module template

When splitting, create a bare namespace module file (`foo.rb`) — no class —
matching the pattern of `diff.rb` and `cat_file.rb`:

```ruby
# frozen_string_literal: true

module Git
  module Commands
    # One-line summary of what the git command does.
    #
    # This module contains command classes for [reason for split]:
    # - {Foo::Bar} – what Bar does
    # - {Foo::Baz} – what Baz does
    #
    # @api private
    # @see https://git-scm.com/docs/git-foo git-foo documentation
    #
    module Foo
    end
  end
end
```

Each sub-command file adds `@see Git::Commands::Foo` to link back to the
parent module's overview.

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
      class Bar < Git::Commands::Base  # never name the class Object
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

This template uses no explicit `def call` — the `@!method` YARD directive
attaches per-command docs to the inherited `call` method. Use this form for
simple commands where no pre-call logic is needed.

When the command requires an explicit `def call` override (input validation,
stdin feeding, non-trivial option routing), place YARD docs **directly above**
`def call` instead of using `@!method`. See the
[`#call` override guidance](../review-command-implementation/SKILL.md#2-call-implementation)
in the Review Command Implementation skill.

### Overriding `call` — inline example

When `def call(...) = super` is not enough, override `call` explicitly. Place
YARD doc comments **directly above** `def call` — do **not** use
`# @!method call(*, **)` alongside an explicit override:

```ruby
# @overload call(*objects, **options)
#
#   Execute the `git cat-file --batch` command.
#
#   @param objects [Array<String>] one or more object names
#
#   @param options [Hash] command options
#
#   @option options [Boolean] :unordered (false) Unordered output
#
#   @return [Git::CommandLineResult] the result of calling `git cat-file --batch`
#
#   @raise [Git::FailedError] if git exits with a non-zero status
def call(*objects, **options)
  bound = args_definition.bind(*objects, **options)
  with_stdin(Array(bound.objects).map { |o| "#{o}\n" }.join) do |reader|
    run_batch(bound, reader)
  end
end

private

def run_batch(bound, reader)
  result = @execution_context.command_capturing(*bound, in: reader, **bound.execution_options, raise_on_failure: false)
  validate_exit_status!(result)
  result
end
```

For stdin-driven commands where objects are domain inputs but not CLI argv, prefer
modeling that contract in the DSL:

```ruby
arguments do
  literal 'cat-file'
  literal '--batch-check'
  flag_option :batch_all_objects
  operand :objects, repeatable: true, skip_cli: true

  conflicts :objects, :batch_all_objects
  requires_one_of :objects, :batch_all_objects
end
```

#### When to use `skip_cli` on `operand`

Use `operand ..., skip_cli: true` when all of the following are true:

- The value is part of the Ruby `#call` interface and should be bound/validated
  by the DSL
- The value should remain accessible on `bound` (for cross-field constraints,
  helper methods, and documentation)
- The value must **not** be emitted into CLI argv (for example, it is sent via
  stdin protocol)

Do **not** use `skip_cli` for execution-engine kwargs (`timeout:`, `chdir:`,
etc.) — those belong to `execution_option`.

Key points:

- **`in:` requires a real IO object.** `Process.spawn` only accepts objects with
  a file descriptor; `StringIO` does not work. `Base#with_stdin` handles this by
  opening an `IO.pipe` and spawning a background `Thread` that writes the content
  to the write end (then closes it). The threaded write prevents deadlocks when
  content exceeds the OS pipe buffer — the subprocess can drain the pipe
  concurrently. The thread rescues `Errno::EPIPE` / `IOError` so it exits cleanly
  if the subprocess closes stdin early. Pass an empty string when the process
  should receive no input (e.g. when a `--batch-all-objects`-style flag makes git
  enumerate objects itself).
- **Extract helpers** like `run_batch` to stay within Rubocop `Metrics/MethodLength`
  and `Metrics/AbcSize` thresholds. Aim to keep `call` under ~10 lines.

## Options completeness — consult the man page first

**Before writing any DSL entries**, fetch the git-scm.com man page for the
subcommand and enumerate every option it documents:

```text
https://git-scm.com/docs/git-<subcommand>
```

For each option, make one of three decisions:

| Decision | Reason | Action |
|---|---|---|
| **Include** | Behavioral — controls which objects are operated on or how the operation runs; does **not** affect stdout format | Add to `arguments do` |
| **Exclude (format)** | Changes the structure or content of stdout (e.g. `--pretty=`, `--stat`, `--patch`, `--name-only`) | Omit — see "Output-format options are intentionally omitted" below |
| **Exclude (inappropriate)** | Stdin/stdout redirection, scripting-only plumbing, or too niche to be useful via the Ruby API | Omit with a brief comment if the reasoning isn't obvious |

Group related options with a comment in the DSL (e.g. `# Ref inclusion`, `# Date
filtering`, `# Commit ordering`). Follow the section groupings from the man page —
this makes it easy for a reviewer to cross-check against the docs.

**Pairs and opposites:** when the man page documents `--foo` / `--no-foo` as
explicit flags, model them as a single `flag_option :foo, negatable: true` rather
than two separate entries. This prevents contradictory combinations and makes the
three-state semantics (`true` / `false` / `nil`) explicit.

**Constraint declarations are generally not used in command classes.** Do not add
`conflicts`, `requires`, `requires_one_of`, `requires_exactly_one_of`,
`forbid_values`, or `allowed_values` declarations to command classes. Git is the
single source of truth for its own option semantics. There are two narrow exceptions:

1. **`skip_cli: true` arguments** — the argument never reaches git's argv, so git
   cannot detect incompatibilities and constraint declarations are appropriate (see
   the `cat-file --batch` example above: `:objects` is `skip_cli: true`, so git
   never sees it and cannot detect the conflict or the absent-both case).
2. **Git-visible arguments that cause silent data loss** — if a combination of
   git-visible arguments causes git to silently discard data (no error, wrong
   result), a `conflicts` declaration MAY be added with: a code comment explaining
   why, a reference to the git version(s) where the behavior was verified, and a
   test. As of this writing, no such case has been identified.

See `redesign/3_architecture_implementation.md` Insight 6 for the full policy.

This step is required. A command class that only exposes the options that happen
to be used today in `Git::Lib` is incomplete — callers of the future API should
not need to re-open the man page just because the scaffold only covered current
usage.

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
type, alias conventions, `as:` usage, modifier rules, and pathspec conventions, see the
[Arguments DSL Checklist](../review-arguments-dsl/CHECKLIST.md).

**Key principles (summary):**

- Fetch the git-scm.com man page and enumerate all options before writing DSL entries
  (see "Options completeness" above)
- Define arguments in the order they appear in the git-scm.com SYNOPSIS
- Within unordered groups: literals → flag options → flag-or-value options → value
  options → operands → pathspecs
- Use aliases for long/short forms (`%i[force f]`), long name first
- When the git SYNOPSIS has `[<tree-ish>] [--] [<pathspec>...]`, use
  `end_of_options` + `value_option :pathspec, as_operand: true` for the post-`--`
  group
- When the SYNOPSIS has pure nesting (`[<a> [<b>]]`), use plain `operand` entries
- For each operand, derive `required:` and `repeatable:` directly from the SYNOPSIS
  notation — `[<arg>]` → optional (default), `<arg>` → `required: true`,
  `[<arg>…]` → `repeatable: true`, `<arg>…` → `required: true, repeatable: true`.
  See [CHECKLIST.md section 4](../review-arguments-dsl/CHECKLIST.md#4-correct-modifiers)
  for the complete table.
- For each option and operand, actively evaluate whether per-argument validation
  parameters apply:
  - `required: true` — does the command fail outright if this argument is absent?
  - `allow_nil: false` — when required, does passing `nil` make no sense?
  - `type: <Class>` — is there a single expected Ruby type that catching early
    would produce a clearer error than git's own output?
  - `validator:` — is there a simple predicate (not a cross-argument rule) that
    git cannot express clearly in its error output?
  Omit these only if there is no meaningful per-argument constraint to express;
  don't leave them out by default.
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

- exact arguments passed to `execution_context.command_capturing`
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
- tag short descriptions must not end with punctuation (no trailing period, comma,
  or colon)
- multi-paragraph tag descriptions must have a blank comment line (`#`) between the
  short description and each continuation paragraph

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
