---
name: scaffold-new-command
description: "Generates a production-ready Git::Commands::* class with unit tests, integration tests, and YARD docs using the Base architecture. Use when creating a new command from scratch."
---

# Scaffold New Command

Generate a production-ready command class, unit tests, integration tests, and YARD
docs using the `Git::Commands::Base` architecture.

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Prerequisites and required reviews](#prerequisites-and-required-reviews)
- [Files to generate](#files-to-generate)
- [Single class vs. sub-command namespace](#single-class-vs-sub-command-namespace)
  - [When to use sub-commands](#when-to-use-sub-commands)
  - [Do NOT split by output format / output mode](#do-not-split-by-output-format--output-mode)
  - [When to keep a single class](#when-to-keep-a-single-class)
  - [Naming sub-command classes](#naming-sub-command-classes)
  - [Namespace module template](#namespace-module-template)
- [Command template (Base pattern)](#command-template-base-pattern)
  - [Overriding `call` — inline example](#overriding-call--inline-example)
    - [When to use `skip_cli` on `operand`](#when-to-use-skip_cli-on-operand)
- [Options completeness — consult the man page first](#options-completeness--consult-the-man-page-first)
- [Execution-model conflicts are intentionally omitted](#execution-model-conflicts-are-intentionally-omitted)
- [Exit status guidance](#exit-status-guidance)
- [Required review steps](#required-review-steps)
  - [Step 1 — Review Arguments DSL](#step-1--review-arguments-dsl)
  - [Step 2 — Review Command Tests](#step-2--review-command-tests)
  - [Step 3 — Review Command YARD Documentation](#step-3--review-command-yard-documentation)
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

## Prerequisites and required reviews

Before starting, you **MUST** load the following skill(s) in their entirety:

- [Write YARD Documentation](../write-yard-documentation/SKILL.md) — authoritative
  source for YARD formatting rules and writing standards

After scaffolding, you **MUST** run the following reviews in order before
committing:

1. [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verify every DSL
   entry is correct and complete; run this **before** writing tests or YARD docs,
   because DSL changes ripple into both
2. [Review Command Tests](../review-command-tests/SKILL.md) — verify unit and
   integration test coverage and structure
3. [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md)
   — verify documentation completeness and formatting

Additional references (load when needed):

- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline RSpec rules all generated unit specs must comply with
- [Review Command Implementation](../review-command-implementation/SKILL.md) — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts

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

For each option, make one of two decisions:

| Decision | Reason | Action |
|---|---|---|
| **Include** | All behavioral options — including output-format flags (`--pretty=`, `--patch`, `--numstat`, `--name-only`, etc.) and filtering/selection flags | Add to `arguments do` |
| **Exclude (execution-model conflict)** | Requires TTY input, opens an external editor, or otherwise makes the command incompatible with non-interactive subprocess execution | Omit — see "Execution-model conflicts are intentionally omitted" below |

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

## Execution-model conflicts are intentionally omitted

Include **all** git options in the DSL by default — including output-format flags
such as `--patch`, `--numstat`, `--raw`, `--format=…`, `--pretty=…`, `--no-color`,
etc. The facade passes these explicitly when a parser requires a specific format;
excluding them from the DSL would force callers to re-read the man page.

The **only** options to exclude are those that conflict with non-interactive
subprocess execution:

- `--interactive` / `-i` — opens an interactive menu; requires a TTY
- `--edit` / `-e` — opens `$EDITOR`; incompatible with subprocess execution
- `--patch` (interactive form, e.g. `git add -p`) — requires TTY prompts
- Any option whose git implementation requires stdin/TTY interaction the
  library cannot provide

> **Note on `--patch`:** it appears in both include and exclude categories
> depending on the command. In `git add -p` it opens an interactive session
> (exclude). In `git diff --patch` it selects a non-interactive output format
> (include). Evaluate per-command, not globally.

**`--verbose`/`-v` and `--quiet`/`-q`:** include these unless their git
implementation requires interactive I/O.

**The `--no-edit` edge case:** `--no-edit` suppresses editor opening — it is the
opposite of an execution-model conflict. Use `flag_option :no_edit`; do **not**
hardcode it as `literal '--no-edit'`, which prevents callers from omitting it.

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

## Required review steps

After generating all files, run these three reviews **in order** before
committing. Load each skill in full and apply every checklist item — do not
rely on the summaries in this file.

### Step 1 — Review Arguments DSL

Load and apply **[Review Arguments DSL](../review-arguments-dsl/SKILL.md)**
(and its [CHECKLIST.md](../review-arguments-dsl/CHECKLIST.md)) against the
newly written `arguments do` block. Fix all issues before proceeding.

Run this step **first** — DSL corrections change the CLI arguments that tests
and YARD docs must reflect, so reviewing DSL after writing tests creates
rework.

### Step 2 — Review Command Tests

Load and apply **[Review Command Tests](../review-command-tests/SKILL.md)**
against the unit and integration spec files. Fix all issues before proceeding.

### Step 3 — Review Command YARD Documentation

Load and apply **[Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md)**
against the command class. Fix all issues before proceeding.

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
