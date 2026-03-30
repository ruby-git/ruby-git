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
    - [Action-option-with-optional-value commands](#action-option-with-optional-value-commands)
    - [When to use `skip_cli` on `operand`](#when-to-use-skip_cli-on-operand)
- [Options completeness — consult the man page first](#options-completeness--consult-the-man-page-first)
- [Execution-model conflicts are intentionally omitted](#execution-model-conflicts-are-intentionally-omitted)
- [`end_of_options` placement](#end_of_options-placement)
- [Exit status guidance](#exit-status-guidance)
- [Common test generation mistakes](#common-test-generation-mistakes)
  - [Unit tests](#unit-tests)
  - [Integration tests](#integration-tests)
- [Required review steps](#required-review-steps)
  - [Step 1 — Review Arguments DSL](#step-1--review-arguments-dsl)
  - [Step 2 — Review Command Tests](#step-2--review-command-tests)
  - [Step 3 — Command YARD Documentation](#step-3--command-yard-documentation)
- [Facade delegation and policy options](#facade-delegation-and-policy-options)
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

- [YARD Documentation](../yard-documentation/SKILL.md) — authoritative
  source for YARD formatting rules and writing standards

After scaffolding, you **MUST** run the following reviews in order before
committing:

1. [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verify every DSL
   entry is correct and complete; run this **before** writing tests or YARD docs,
   because DSL changes ripple into both
2. [Review Command Tests](../review-command-tests/SKILL.md) — verify unit and
   integration test coverage and structure
3. [Command YARD Documentation](../command-yard-documentation/SKILL.md)
   — verify documentation completeness and formatting

Additional references (load when needed):

- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline RSpec rules all generated unit specs must comply with
- [Review Command Implementation](../review-command-implementation/SKILL.md) — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts

## Files to generate

For `Git::Commands::Foo::Bar`, **all three files are required and must be created**:

- `lib/git/commands/foo/bar.rb` — the command class
- `spec/unit/git/commands/foo/bar_spec.rb` — unit tests
- `spec/integration/git/commands/foo/bar_spec.rb` — integration tests (mandatory, not optional)

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
        #   @overload call(operand = nil, *rest, **options)
        #
        #     Execute the git ... command.
        #
        #     @param operand [String, nil] (nil) Short description without trailing period
        #
        #       Continuation paragraph separated by a blank comment line. Only needed
        #       when the short description alone is insufficient.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :simple_flag (nil) One-sentence description without period
        #
        #     @option options [Boolean, String, nil] :complex_flag (nil) Short description without period
        #
        #       Continuation: explain the `true`/`false`/string forms here, each separated by
        #       a blank comment line from the short description above.
        #
        #       Alias: :f
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

**YARD tag formatting rules enforced by the review step:**

- Short description (the inline text after the type and option key) must be a
  **single sentence** and must **not end with punctuation** (no trailing period).
- If more detail is needed, put it in a **continuation paragraph** separated from
  the short description by a blank comment line (`#`).
- This applies to every `@param`, `@option`, `@return`, and `@raise` tag.

```ruby
# ✅ Correct — no period on short desc; blank line before continuation
# @option options [Boolean, String, nil] :recurse_submodules (nil) Control whether
#   submodule commits are fetched
#
#   When `true`, uses `--recurse-submodules`. When a string (`'yes'`,
#   `'on-demand'`, `'no'`), passes that value. When `false`, emits
#   `--no-recurse-submodules`.

# ❌ Incorrect — trailing period; continuation run in without blank line
# @option options [Boolean, String, nil] :recurse_submodules (nil) Control whether
#   submodule commits are fetched. When true, uses --recurse-submodules. When a
#   string, passes that value.
```

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

#### Action-option-with-optional-value commands

When a git command's primary action is an option with an optional value (man-page
notation: `--flag[=<value>]`, e.g. `git am --show-current-patch[=(diff|raw)]`),
use this pattern:

**DSL:**
```ruby
arguments do
  literal 'am'
  flag_or_value_option :show_current_patch, inline: true, type: [TrueClass, String]
end
```

**`#call` override** — required to give callers a natural positional API:
```ruby
# Show the patch currently being applied by `git am`
#
# @param value [true, String] When +true+ (default), emits +--show-current-patch+
#   (git's default behavior). Pass +"diff"+ or +"raw"+ to emit
#   +--show-current-patch=diff+ / +--show-current-patch=raw+.
#
# @return [Git::CommandLineResult] the result of the command
#
# @raise [Git::FailedError] if no am session is in progress
#
def call(value = true, *, **)
  super(*, **, option_name: value)
end
```

Where:
- `value = true` — positional default; `true` emits `--flag`; a String emits `--flag=value`
- `*` — forwards positional operands declared in the DSL (omit when the command has none)
- `**` — forwards keyword options to the DSL binder; unknown keywords raise `ArgumentError`
- `option_name: value` placed last so the positional arg always takes precedence

The `type: [TrueClass, String]` on the DSL entry rejects `false` at bind time,
removing the need for manual validation in the override.

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

## Options completeness — consult version-matched docs first

**Before writing any DSL entries**, determine the project's minimum supported
Git version from the repository metadata, then fetch documentation for that
exact version of the subcommand and enumerate every option it documents.

For this repository, the minimum supported Git version is declared in
`git.gemspec` (`git 2.28.0 or greater`).

Use sources in this order:

1. **Version-matched upstream documentation** for the minimum supported Git
  version.
2. **Version-matched upstream source** for that same release when exact parser
  behavior is ambiguous in the docs.
3. **Local `git <command> -h` output** only as a supplemental check for the
  installed Git version.

Do **not** scaffold from local help output alone. The installed Git may be
newer than the minimum supported version and may expose flags, negated forms,
or aliases that are unavailable in older supported releases.

Useful documentation URLs often look like:

```text
https://git-scm.com/docs/git-<subcommand>
https://git-scm.com/docs/git-<subcommand>/<version>
https://raw.githubusercontent.com/git/git/v<version>/Documentation/git-<subcommand>.txt
```

For each option, make one of two decisions:

| Decision | Reason | Action |
|---|---|---|
| **Include** | All behavioral options — including output-format flags (`--pretty=`, `--patch`, `--numstat`, `--name-only`, etc.) and filtering/selection flags | Add to `arguments do` |
| **Exclude (execution-model conflict)** | Requires TTY input or otherwise makes the command incompatible with non-interactive subprocess execution | Omit — see "Execution-model conflicts are intentionally omitted" below |

Group related options with a comment in the DSL (e.g. `# Ref inclusion`, `# Date
filtering`, `# Commit ordering`). Follow the section groupings from the
version-matched documentation —
this makes it easy for a reviewer to cross-check against the docs.

**Pairs and opposites:** when the version-matched docs document `--foo` /
`--no-foo` as
explicit flags, model them as a single `flag_option :foo, negatable: true` rather
than two separate entries. This prevents contradictory combinations and makes the
three-state semantics (`true` / `false` / `nil`) explicit.

**Short-flag aliases — cross-check the version-matched docs/source:** before adding any short-flag
alias (e.g. `%i[dry_run n]`), verify the alias character appears on the same option
heading in the documentation or parser for the minimum supported version
(`-n, --dry-run`). Do **not** invent an alias that the minimum-version sources do
not document — it will generate an unknown flag that older supported git may reject.
Symmetrically, every option the version-matched docs document with a short form
**must** have an
alias in the DSL (long name first: `%i[dry_run n]`).

**`inline: true` for `=<value>` options:** when the version-matched docs show `--option=<value>`
(with an `=`), the DSL entry must include `inline: true` regardless of whether the
DSL method is `value_option` or `flag_or_value_option`. Without it, the value is
emitted as a separate token (`--option value`) instead of the expected inline form
(`--option=value`). Check every `value_option` and `flag_or_value_option` entry
against the minimum-version signature.

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
not need to re-open the docs just because the scaffold only covered current
usage. If local help output shows more options than the minimum-version sources,
do not scaffold those newer forms into the DSL unless the repository's minimum
supported Git version has also been raised.

## Execution-model conflicts are intentionally omitted

Command classes are neutral — they never hardcode policy choices (output-control,
editor suppression, progress, verbose). Those belong to the facade (`Git::Lib`).

> **Anti-pattern:** `literal '--no-edit'`, `literal '--verbose'`,
> `literal '--no-progress'` inside a command class.
>
> **Correct pattern:** `flag_option :edit, negatable: true` in the command;
> `edit: false` passed from the facade call site.

Include **all** git options in the DSL by default — including output-format flags
such as `--patch`, `--numstat`, `--raw`, `--format=…`, `--pretty=…`, `--no-color`,
etc. The facade passes these explicitly when a parser requires a specific format;
excluding them from the DSL would force callers to re-read the man page.

The **only** options to exclude are those that conflict with non-interactive
subprocess execution:

- `--interactive` / `-i` — opens an interactive menu; requires a TTY
- `--patch` (interactive form, e.g. `git add -p`) — requires TTY prompts
- Any option whose git implementation requires stdin/TTY interaction the
  library cannot provide

> **Note on `--patch`:** it appears in both include and exclude categories
> depending on the command. In `git add -p` it opens an interactive session
> (exclude). In `git diff --patch` it selects a non-interactive output format
> (include). Evaluate per-command, not globally.

**`--edit` / `--no-edit`:** Model as `flag_option :edit, negatable: true`. The
command class is neutral; the facade passes `edit: false` at each call site. Do
**not** hardcode `literal '--no-edit'`. See "Command-layer neutrality" in
CONTRIBUTING.md.

**`--verbose`/`-v` and `--quiet`/`-q`:** include these unless their git
implementation requires interactive I/O.

## `end_of_options` placement

Determine placement based on whether the version-matched SYNOPSIS explicitly shows `--`.
See the Review Arguments DSL checklist for the full decision tree.

### Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS

When the version-matched SYNOPSIS explicitly shows `--` between operand groups
(e.g., `[<tree-ish>] [--] [<pathspec>...]`), place `end_of_options` in the same
position the SYNOPSIS shows it — after the pre-`--` operands, before the post-`--`
group. See the Review Arguments DSL checklist ("Choosing the correct pathspec form")
for how to model the post-`--` group (`value_option ... as_operand: true`).

**Do not apply Rule 2** when Rule 1 applies.

```ruby
# git diff [<tree-ish>] [--] [<pathspec>...]
operand :tree_ish                                             # BEFORE end_of_options
end_of_options                                                # mirrors SYNOPSIS position
value_option :pathspec, as_operand: true, repeatable: true    # AFTER end_of_options
```

### Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation

Insert `end_of_options` immediately before the first `operand` whenever any
`flag_option`, `value_option`, or `flag_or_value_option` appears earlier in the
`arguments do` block. This prevents operands from being misinterpreted as flags when
a caller passes a value that starts with `-`.

`literal` entries are **never** the trigger — regardless of whether their value is
option-style (e.g. `literal '--delete'`) or a plain subcommand word
(e.g. `literal 'remove'`). Only the three DSL option-flag methods above matter.

```ruby
# ✅ Correct — flag_option triggers Rule 2; end_of_options inserted before first operand
arguments do
  literal 'remote'
  literal 'rename'
  flag_option :progress, negatable: true   # ← this triggers Rule 2

  end_of_options

  operand :old, required: true
  operand :new, required: true
end

# ✅ Not needed — only literal entries precede the operand; no DSL option-flag methods
arguments do
  literal 'remote'
  literal 'remove'
  operand :name, required: true  # no flag_option/value_option/flag_or_value_option → not required
end
```

`end_of_options` is always safe to add even when not strictly required. Omit it by
convention when neither rule applies: it adds no defensive value and produces
unnecessarily verbose command lines (e.g. `git remote remove -- origin` instead of
`git remote remove origin`). When in doubt, add it — the Review Arguments DSL skill
flags a missing `end_of_options` as an error when options appear before operands.

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

## Common test generation mistakes

Apply these checks immediately after writing tests, before running the review skills.
These are recurring mistakes that the review step should catch — but catching them at
generation time avoids a rework loop.

### Unit tests

**Do not write string-variant pass-through tests for operands.** If the command
accepts a positional operand (e.g. `tree_ish`, `stash_ref`, `commit`), write exactly
one base-invocation test with a representative value (e.g. `'HEAD'`). Do not add a
second test passing a different string (e.g. a SHA, a tag name, or a branch name) — it
exercises the same code path as the base test. The DSL passes strings unchanged; there
is nothing new to cover.

**Put all validation cases in a single `context 'input validation'` block.** This
means both required-argument violations and unsupported-option errors. Do **not** use
a separate `context 'when X is missing'` block outside of `context 'input validation'`
— it produces the same structure split across two places.

```ruby
# Correct — one 'input validation' block with all validation examples
context 'input validation' do
  it 'raises ArgumentError when tree_ish is missing' do
    expect { command.call }.to raise_error(ArgumentError, /tree_ish/)
  end

  it 'raises ArgumentError for unsupported options' do
    expect { command.call('HEAD', unknown: true) }
      .to raise_error(ArgumentError, /Unsupported options/)
  end
end
```

**Test both `true` and `false` for every negatable option.** A `flag_option :foo,
negatable: true` or `flag_or_value_option :foo, negatable: true` has two distinct
code paths: `true` emits `--foo` and `false` emits `--no-foo`. Both must be tested —
omitting the `false` case is a Rule 21 branch coverage failure. When the option also
accepts a String, test that form too (see `force_with_lease`, `signed`,
`recurse_submodules` for examples).

```ruby
context 'with the :verify option' do
  it 'adds --verify when true' do
    expect_command_capturing('push', '--verify').and_return(command_result)
    command.call(verify: true)
  end

  it 'adds --no-verify when false' do
    expect_command_capturing('push', '--no-verify').and_return(command_result)
    command.call(verify: false)
  end
end
```

**Test every DSL alias.** When a DSL entry groups keys in an array
(`flag_option %i[dry_run n]`, `value_option %i[receive_pack exec]`), every alias
beyond the primary key must have its own `it` block verifying the canonical flag is
emitted. Do not assume the primary-key test covers the alias — the DSL wires them
independently and an alias misconfiguration would go undetected.

```ruby
# DSL: flag_option %i[dry_run n]
# ✅ Both tested:
it 'adds --dry-run to the command line' do
  expect_command_capturing('push', '--dry-run').and_return(command_result)
  command.call(dry_run: true)
end

it 'supports the :n alias' do
  expect_command_capturing('push', '--dry-run').and_return(command_result)
  command.call(n: true)
end
```

**Do not test `option: false` for non-negatable flags.** Passing `false` to a
`flag_option` declared without `negatable: true` produces no CLI output — the same
code path as the base invocation with no options. The "no arguments" test already
covers this path. Do not write `command.call(prune: false)` or similar for flags
that have no `--no-<flag>` form.

### Integration tests

**Creating the integration test file is mandatory.** Every new command MUST have a
corresponding file at `spec/integration/git/commands/<path>_spec.rb`. Do not skip
this file — it is listed in [Files to generate](#files-to-generate) for a reason.

**Integration test template** — copy and adapt this for every new command:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/foo'  # adjust path to match the command file

RSpec.describe Git::Commands::Foo, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Set up a minimal repository state that the command needs.
    # Use the helpers from the shared context: write_file, repo.add, repo.commit, etc.
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('HEAD')  # use the simplest valid invocation

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid argument' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent-ref') }
          .to raise_error(Git::FailedError, /nonexistent-ref/)
      end
    end
  end
end
```

Adapt the `before` block and the call arguments to the specific command. Add extra
`context` blocks inside `'when the command succeeds'` only for genuinely distinct
execution paths (e.g. a flag that changes how git parses the request), not for
different string values passed to the same operand.

If the `before` block creates additional git repositories beyond the shared context's
primary repo (e.g., a bare remote, a second clone target), always pass
`initial_branch: 'main'` to `Git.init`. Without it, `HEAD` defaults to the system's
`init.defaultBranch`, which differs across CI runners and developer machines and
causes non-deterministic test failures:

```ruby
# ❌ Fragile — HEAD points to the system default branch name
Git.init(bare_dir, bare: true)

# ✅ Correct — HEAD always points to 'main'
Git.init(bare_dir, bare: true, initial_branch: 'main')
```

**Do not assert on git's output content.** Integration tests confirm that the command
executes against a real git repository — they are smoke tests, not output validators.
Testing specific file names, SHA patterns, line counts, or any stdout content asserts
git's formatting behavior, not the command's behavior. Every integration test in
`context 'when the command succeeds'` should look like this:

```ruby
it 'returns a CommandLineResult' do
  result = command.call('HEAD')
  expect(result).to be_a(Git::CommandLineResult)
end
```

When verifying that a command produces *some* output (e.g. for a listing command), it
is acceptable to assert `expect(result.stdout).not_to be_empty` — but do not go
further and assert what the content contains.

**Always include a message pattern on `FailedError` assertions.** Rule 22 requires
both an error class and a message pattern — the version-variance exception never
permits omitting the pattern entirely; it only permits using a loose regexp. Use the
stable input value you passed (e.g., `'nonexistent-ref'`) as the anchor:

```ruby
# ✅ Correct — anchors on the stable input value, tolerates phrasing differences
it 'raises FailedError for a nonexistent ref' do
  # git's error message phrasing varies by version — anchor on the stable input value
  expect { command.call('nonexistent-ref') }
    .to raise_error(Git::FailedError, /nonexistent-ref/)
end

# ❌ Wrong — omits the message pattern; passes for any FailedError regardless of cause
it 'raises FailedError for a nonexistent ref' do
  expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
end
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

### Step 3 — Command YARD Documentation

Load and apply **[Command YARD Documentation](../command-yard-documentation/SKILL.md)**
against the command class. Fix all issues before proceeding.

## Facade delegation and policy options

The command class is only half the story. After scaffolding the command, you must
also write (or update) the `Git::Lib` method that **delegates** to it. The facade
sets safe policy defaults at each call site — `edit: false`, `verbose: true`,
`progress: false`, etc. — not as `literal` entries inside the command class.
Callers may override these defaults when needed.
See "Command-layer neutrality" in CONTRIBUTING.md.

```ruby
# lib/git/lib.rb — facade method for `git pull`

PULL_ALLOWED_OPTS = %i[allow_unrelated_histories].freeze

def pull(remote = nil, branch = nil, opts = {})
  raise ArgumentError, 'You must specify a remote if a branch is specified' if remote.nil? && !branch.nil?

  assert_valid_opts(opts, PULL_ALLOWED_OPTS)
  allowed_opts = opts.slice(*PULL_ALLOWED_OPTS)
  positional_args = [remote, branch].compact
  # edit: false is the non-interactive default (see CONTRIBUTING.md)
  Git::Commands::Pull.new(self).call(*positional_args, edit: false, **allowed_opts).stdout
end
```

Key points for the facade method:

- **Filter options** — declare an `ALLOWED_OPTS` constant listing only the options
  the public API accepted at v4.3.0. Use `assert_valid_opts` + `opts.slice` to
  prevent accidental API expansion.
- **Pass policy options as safe defaults** — `edit: false`, `progress: false`, etc.
  Place them before `**opts` so the caller can override when needed.
  Add a comment explaining *why* (e.g., `# non-interactive default`).
- **Return the legacy type** — typically `.stdout` or a parsed struct, not
  `CommandLineResult`.

See [Extract Command from Lib](../extract-command-from-lib/SKILL.md) for the
complete delegation workflow and additional patterns (stdout passthrough,
parsed return values, opts-hash normalization).

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
