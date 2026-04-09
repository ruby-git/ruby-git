---
name: scaffold-new-command
description: "Generates a production-ready Git::Commands::* class with unit tests, integration tests, and YARD docs using the Base architecture. Use when creating a new command from scratch."
---

# Scaffold New Command

Generate a production-ready command class, unit tests, integration tests, and YARD
docs using the `Git::Commands::Base` architecture.

## Contents

- [Contents](#contents)
- [Related skills](#related-skills)
- [Input](#input)
  - [Git documentation for the git command](#git-documentation-for-the-git-command)
- [Reference](#reference)
  - [Files to generate](#files-to-generate)
  - [Single class vs. sub-command namespace](#single-class-vs-sub-command-namespace)
    - [When to use sub-commands](#when-to-use-sub-commands)
    - [Do NOT split by output format / output mode](#do-not-split-by-output-format--output-mode)
    - [When to keep a single class](#when-to-keep-a-single-class)
    - [Naming sub-command classes](#naming-sub-command-classes)
    - [Namespace module template](#namespace-module-template)
  - [Command template (Base pattern)](#command-template-base-pattern)
    - [Overriding `call` — inline example](#overriding-call--inline-example)
  - [Options completeness — consult the latest-version docs first](#options-completeness--consult-the-latest-version-docs-first)
    - [`requires_git_version` convention](#requires_git_version-convention)
    - [Execution-model conflicts](#execution-model-conflicts)
  - [`end_of_options` placement](#end_of_options-placement)
    - [Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS](#rule-1--synopsis-shows----mirror-the-synopsis)
    - [Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation](#rule-2--synopsis-does-not-show----protect-operands-from-flag-misinterpretation)
  - [Exit status guidance](#exit-status-guidance)
  - [Facade delegation and policy options](#facade-delegation-and-policy-options)
  - [Phased rollout, compatibility, and quality gates](#phased-rollout-compatibility-and-quality-gates)
- [Workflow](#workflow)
- [Output](#output)

## Related skills

- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verify every DSL entry
  is correct and complete
- [YARD Documentation](../yard-documentation/SKILL.md) — authoritative source for
  YARD formatting rules and writing standards (load before starting)
- [Command YARD Documentation](../command-yard-documentation/SKILL.md) — verify
  documentation completeness and formatting
- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline
  RSpec rules all generated unit specs must comply with
- [Command Test Conventions](../command-test-conventions/SKILL.md) — conventions for
  writing and reviewing unit and integration tests for command classes
- [Review Command Implementation](../review-command-implementation/SKILL.md) —
  canonical class-shape checklist, phased rollout gates, and internal compatibility
  contracts

## Input

The user provides the target `Git::Commands::*` class name and the git subcommand (or
subcommand + sub-action) it wraps. The agent gathers the following.

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

Do **not** scaffold from local `git <command> -h` output — the installed Git
version is unknown and may differ from the latest supported version.

## Reference

### Files to generate

For `Git::Commands::Foo::Bar`, **all three files are required and must be created**:

- `lib/git/commands/foo/bar.rb` — the command class
- `spec/unit/git/commands/foo/bar_spec.rb` — unit tests
- `spec/integration/git/commands/foo/bar_spec.rb` — integration tests (mandatory, not
  optional)

Optional (first command in module):

- `lib/git/commands/foo.rb`

### Single class vs. sub-command namespace

Most git commands map to a single class. Split into a namespace module with multiple
sub-command classes when the git command surfaces **meaningfully different
operations** that have distinct call shapes or protocols.

#### When to use sub-commands

**Split by operation** — when the git command has named sub-actions whose option sets
have little overlap (each sub-action would have mostly dead options if they shared
one class):

```
git stash push / pop / apply / drop / list / show
git tag --create / --delete / --list
git worktree add / list / remove / move
```

**Split by stdin protocol** — when one variant reads from stdin and another does not
(even if the git command is the same). The stdin variant needs a `call` override that
uses `Base#with_stdin`; mixing that with a no-stdin path in one class produces an
awkward interface.

#### Do NOT split by output format / output mode

**Output-mode flags are NOT a reason to create separate subclasses.** When a git
command supports multiple output formats via flags (`--patch`, `--numstat`, `--raw`,
`--format=…`, etc.), express them as `flag_option` or `value_option` entries in a
**single class**. The facade passes the desired format flags explicitly at call time:

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

The same applies for `--format=<string>`, `--pretty=<fmt>`, `--no-color`, and all
other parser-contract options. Declare them in the DSL; the facade passes them.

Remember: **`literal` entries are only for operation selectors** — fixed flags that
define which git sub-operation the class represents (e.g., `literal 'stash'`,
`literal 'show'`, `literal '--delete'`). Output-format flags are not operation
selectors.

#### When to keep a single class

- Different output modes (`--patch`, `--numstat`, `--raw`): **always** use a single
  class; expose modes as DSL options.
- Minor option variations that share the same argument set.
- When the "special mode" is just 1–2 flags — use `flag_option`/`value_option`.
- When callers would always need multiple modes together (the facade composes them).

#### Naming sub-command classes

Prefer **user-oriented names** (what the caller gets back) over flag names
(implementation detail the caller shouldn't need to know):

```
# Avoid — leaks implementation detail
CatFile::BatchCheck / CatFile::Batch

# Prefer — describes the result from the caller's perspective
CatFile::ObjectMeta / CatFile::ObjectContent
```

Two hard constraints:

- **Never name a sub-command class `Object`** — it shadows Ruby's `::Object` base
  class anywhere that constant is looked up inside the namespace.
- **Never use the `*Info` or `*Result` suffix** on command classes — those suffixes
  are reserved for parsed result structs (`BranchInfo`, `TagInfo`,
  `BranchDeleteResult`) which live in the top-level `Git::` namespace, not in
  `Git::Commands::*`. A reader seeing `CommandFoo::BarInfo` expects a data struct,
  not a class that runs a subprocess.

#### Namespace module template

When splitting, create a bare namespace module file (`foo.rb`) — no class — matching
the pattern of `diff.rb` and `cat_file.rb`:

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

Each sub-command file adds `@see Git::Commands::Foo` to link back to the parent
module's overview.

### Command template (Base pattern)

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
        #     @option options [Boolean, Integer] :force (nil) Short description without period
        #
        #       When an integer is given, the flag is repeated that many times (up to the
        #       configured `max_times:` limit).
        #
        #       Alias: :f
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

This template uses no explicit `def call` — the `@!method` YARD directive attaches
per-command docs to the inherited `call` method. Use this form for simple commands
where no pre-call logic is needed.

YARD tag formatting rules (short descriptions, continuation paragraphs, punctuation)
are defined in the [YARD Documentation](../yard-documentation/SKILL.md) skill. The
template above demonstrates the correct form.

When the command requires an explicit `def call` override (input validation, stdin
feeding, non-trivial option routing), place YARD docs **directly above** `def call`
instead of using `@!method`. See the [`#call` override
guidance](../review-command-implementation/SKILL.md#call-override-guidance) in the
Review Command Implementation skill.

#### Overriding `call` — inline example

When `def call(...) = super` is not enough, override `call` explicitly. Place YARD
doc comments **directly above** `def call` — do **not** use `# @!method call(*, **)`
alongside an explicit override:

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

##### Action-option-with-optional-value commands

When a git command's primary action is an option with an optional value (man-page
notation: `--flag[=<value>]`, e.g. `git am --show-current-patch[=(diff|raw)]`), use
this pattern:

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
- `value = true` — positional default; `true` emits `--flag`; a String emits
  `--flag=value`
- `*` — forwards positional operands declared in the DSL (omit when the command has
  none)
- `**` — forwards keyword options to the DSL binder; unknown keywords raise
  `ArgumentError`
- `option_name: value` placed last so the positional arg always takes precedence

The `type: [TrueClass, String]` on the DSL entry rejects `false` at bind time,
removing the need for manual validation in the override.

##### When to use `skip_cli` on `operand`

Use `operand ..., skip_cli: true` when all of the following are true:

- The value is part of the Ruby `#call` interface and should be bound/validated by
  the DSL
- The value should remain accessible on `bound` (for cross-field constraints, helper
  methods, and documentation)
- The value must **not** be emitted into CLI argv (for example, it is sent via stdin
  protocol)

Do **not** use `skip_cli` for execution-engine kwargs (`timeout:`, `chdir:`, etc.) —
those belong to `execution_option`.

Key points:

- **`in:` requires a real IO object.** `Process.spawn` only accepts objects with a
  file descriptor; `StringIO` does not work. `Base#with_stdin` handles this by
  opening an `IO.pipe` and spawning a background `Thread` that writes the content to
  the write end (then closes it). The threaded write prevents deadlocks when content
  exceeds the OS pipe buffer — the subprocess can drain the pipe concurrently. The
  thread rescues `Errno::EPIPE` / `IOError` so it exits cleanly if the subprocess
  closes stdin early. Pass an empty string when the process should receive no input
  (e.g. when a `--batch-all-objects`-style flag makes git enumerate objects itself).
- **Extract helpers** like `run_batch` to stay within Rubocop `Metrics/MethodLength`
  and `Metrics/AbcSize` thresholds. Aim to keep `call` under ~10 lines.

### Options completeness — consult the latest-version docs first

**Before writing any DSL entries**, use the documentation fetched during the
[Input](#git-documentation-for-the-git-command) phase and enumerate every option the
latest-version docs describe.

#### `requires_git_version` convention

`requires_git_version` is a **class-level** declaration only. Individual options do
**not** carry version annotations.

| Scenario | Action |
|---|---|
| Command exists in `Git::MINIMUM_GIT_VERSION` | Do **not** add `requires_git_version` |
| Command was introduced after `Git::MINIMUM_GIT_VERSION` | Add `requires_git_version '<version>'` at the version the command was introduced |

Options that were added to a command after `Git::MINIMUM_GIT_VERSION` are still
scaffolded in the DSL — they are **not** omitted. When a caller passes such an option
on an older git installation, git itself will produce its native "unknown option"
error. This is acceptable and expected; the ruby-git library does not gate individual
options by version.

For each option, make one of two decisions:

| Decision | Reason | Action |
|---|---|---|
| **Include** | All behavioral options — including output-format flags (`--pretty=`, `--patch`, `--numstat`, `--name-only`, etc.) and filtering/selection flags | Add to `arguments do` |
| **Exclude (execution-model conflict)** | Requires TTY input or otherwise makes the command incompatible with non-interactive subprocess execution | Omit — see [Execution-model conflicts](#execution-model-conflicts) below |

Group related options with a comment in the DSL (e.g. `# Ref inclusion`, `# Date
filtering`, `# Commit ordering`). Follow the section groupings from the
latest-version documentation — this makes it easy for a reviewer to cross-check
against the docs.

**Pairs and opposites:** when the latest-version docs document `--foo` / `--no-foo`
as explicit flags, model them as a single `flag_option :foo, negatable: true` rather
than two separate entries. This prevents contradictory combinations and makes the
three-state semantics (`true` / `false` / `nil`) explicit.

**Short-flag aliases — cross-check the latest-version docs/source:** before adding
any short-flag alias (e.g. `%i[dry_run n]`), verify the alias character appears on
the same option heading in the documentation or parser for the latest supported
version (`-n, --dry-run`). Do **not** invent an alias that the latest-version sources
do not document — in this DSL, short aliases are Ruby-keyword aliases for ergonomics
and documentation parity, while CLI emission still follows the primary option name's
flag spec. Symmetrically, every option the latest-version docs document with a short
form **must** have an alias in the DSL (long name first: `%i[dry_run n]`).

**`as:` is an escape hatch, not a default tool:** treat `as:` as suspicious by
default and use it only when the required argv cannot be expressed by the normal DSL
mapping plus existing modifiers (`negatable:`, `inline:`, `as_operand:`,
`max_times:`, etc.). If a plain symbol, alias, or first-class modifier can express
the same behavior, prefer that. In particular, do not use `as:` to encode repeated
flags now that `max_times:` exists.

**`inline: true` for `=<value>` options:** when the latest-version docs show
`--option=<value>` (with an `=`), the DSL entry must include `inline: true`
regardless of whether the DSL method is `value_option` or `flag_or_value_option`.
Without it, the value is emitted as a separate token (`--option value`) instead of
the expected inline form (`--option=value`). Check every `value_option` and
`flag_or_value_option` entry against the latest-version signature.

**Constraint declarations are generally not used in command classes.** Do not add
`conflicts`, `requires`, `requires_one_of`, `requires_exactly_one_of`,
`forbid_values`, or `allowed_values` declarations to command classes. Git is the
single source of truth for its own option semantics. There are two narrow exceptions:

1. **`skip_cli: true` arguments** — the argument never reaches git's argv, so git
   cannot detect incompatibilities and constraint declarations are appropriate (see
   the `cat-file --batch` example above: `:objects` is `skip_cli: true`, so git never
   sees it and cannot detect the conflict or the absent-both case).
2. **Git-visible arguments that cause silent data loss** — if a combination of
   git-visible arguments causes git to silently discard data (no error, wrong
   result), a `conflicts` declaration MAY be added with: a code comment explaining
   why, a reference to the git version(s) where the behavior was verified, and a
   test. As of this writing, no such case has been identified.

See `redesign/3_architecture_implementation.md` Insight 6 for the full policy.

This step is required. A command class that only exposes the options that happen to
be used today in `Git::Lib` is incomplete — callers of the future API should not need
to re-open the docs just because the scaffold only covered current usage.

#### Execution-model conflicts

Command classes are neutral — they never hardcode policy choices. Policy defaults
(`edit: false`, `progress: false`, etc.) belong to the facade (`Git::Lib`).

> **Anti-pattern:** `literal '--no-edit'` inside a command class.
>
> **Correct pattern:** `flag_option :edit, negatable: true` in the command; `edit:
> false` passed from the facade call site.

The **only** options to exclude from the DSL are those that conflict with
non-interactive subprocess execution:

- `--interactive` / `-i` — requires a TTY
- `--patch` (interactive form, e.g. `git add -p`) — requires TTY prompts
- Any option requiring stdin/TTY interaction the library cannot provide

> **Note on `--patch`:** In `git add -p` it opens an interactive session (exclude).
> In `git diff --patch` it selects a non-interactive output format (include).
> Evaluate per-command, not globally.

**`--edit` / `--no-edit`:** Model as `flag_option :edit, negatable: true`. Do
**not** hardcode `literal '--no-edit'`. See "Command-layer neutrality" in
CONTRIBUTING.md.

**`--verbose`/`-v` and `--quiet`/`-q`:** include these unless their git
implementation requires interactive I/O.

### `end_of_options` placement

Determine placement based on whether the SYNOPSIS explicitly shows `--`. See the
Review Arguments DSL checklist for the full decision tree.

#### Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS

When the SYNOPSIS explicitly shows `--` between operand groups (e.g., `[<tree-ish>]
[--] [<pathspec>...]`), place `end_of_options` in the same position the SYNOPSIS
shows it — after the pre-`--` operands, before the post-`--` group. See the Review
Arguments DSL checklist ("Choosing the correct pathspec form") for how to model the
post-`--` group (`value_option ... as_operand: true`).

**Do not apply Rule 2** when Rule 1 applies.

```ruby
# git diff [<tree-ish>] [--] [<pathspec>...]
operand :tree_ish                                             # BEFORE end_of_options
end_of_options                                                # mirrors SYNOPSIS position
value_option :pathspec, as_operand: true, repeatable: true    # AFTER end_of_options
```

#### Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation

Insert `end_of_options` immediately before the first `operand` whenever any
`flag_option`, `value_option`, `flag_or_value_option`, `key_value_option`, or
`custom_option` appears earlier in the `arguments do` block. This prevents operands
from being misinterpreted as flags when a caller passes a value that starts with `-`.

`literal` entries are **never** the trigger — regardless of whether their value is
option-style (e.g. `literal '--delete'`) or a plain subcommand word (e.g. `literal
'remove'`). Only the five DSL option methods above matter.

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
  operand :name, required: true  # no DSL option methods → not required
end
```

`end_of_options` is always safe to add even when not strictly required. Omit it by
convention when neither rule applies: it adds no defensive value and produces
unnecessarily verbose command lines (e.g. `git remote remove -- origin` instead of
`git remote remove origin`). When in doubt, add it — the Review Arguments DSL skill
flags a missing `end_of_options` as an error when options appear before operands.

### Exit status guidance

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

### Facade delegation and policy options

The command class is only half the story. After scaffolding the command, you must
also write (or update) the `Git::Lib` method that **delegates** to it. The facade
sets safe policy defaults at each call site — `edit: false`, `verbose: true`,
`progress: false`, etc. — not as `literal` entries inside the command class. Callers
may override these defaults when needed. See "Command-layer neutrality" in
CONTRIBUTING.md.

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
  Place them before `**opts` so the caller can override when needed. Add a comment
  explaining *why* (e.g., `# non-interactive default`).
- **Return the legacy type** — typically `.stdout` or a parsed struct, not
  `CommandLineResult`.

See [Extract Command from Lib](../extract-command-from-lib/SKILL.md) for the complete
delegation workflow and additional patterns (stdout passthrough, parsed return
values, opts-hash normalization).

### Phased rollout, compatibility, and quality gates

See [Review Command Implementation](../review-command-implementation/SKILL.md) for
the canonical phased rollout checklist, internal compatibility contract, and quality
gate commands. In summary:

- **always work on a feature branch** — never commit or push directly to `main`;
  create a branch before starting (`git checkout -b <feature-branch-name>`) and open
  a pull request when the slice is ready
- migrate in small slices (pilot or family), not all commands at once
- keep each slice independently revertible
- pass per-slice gates: `bundle exec rspec`, `bundle exec rake test`, `bundle exec
  rubocop`, `bundle exec rake yard`

## Workflow

1. **Gather input** — collect the target class name and git subcommand from
   the [Input](#input), then fetch the latest-version and minimum-version
   git documentation per [Git documentation for the git
   command](#git-documentation-for-the-git-command).

2. **Determine class structure** — decide between a single class and a sub-command
   namespace per [Single class vs. sub-command
   namespace](#single-class-vs-sub-command-namespace).

3. **For each command / sub-command class**, repeat steps 3a–3f:

   a. **Scaffold the command class (subagent)** — delegate to a subagent: load
      the [YARD Documentation](../yard-documentation/SKILL.md) skill, then
      generate `lib/git/commands/{command}.rb` using the [Command
      template](#command-template-base-pattern). Populate the `arguments do`
      block with all options from the latest-version docs per [Options
      completeness](#options-completeness--consult-the-latest-version-docs-first),
      applying the [Execution-model conflicts](#execution-model-conflicts),
      [`end_of_options` placement](#end_of_options-placement), and [Exit status
      guidance](#exit-status-guidance) rules. Pass the fetched git documentation
      to the subagent.

   Steps 3b and 3c may run **in parallel** (they produce independent files).

   b. **Scaffold unit tests (subagent)** — delegate to a subagent: load
      **[Command Test Conventions](../command-test-conventions/SKILL.md)** (which loads
      [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md)),
      then generate `spec/unit/git/commands/{command}_spec.rb` following the
      unit test conventions. Fix all findings, then re-run the review until clean.

   c. **Scaffold integration tests (subagent)** — delegate to a subagent: load
      **[Command Test Conventions](../command-test-conventions/SKILL.md)**, then generate
      `spec/integration/git/commands/{command}_spec.rb` following the integration
      test conventions. Fix all findings, then re-run the review until clean.

   d. **Review Arguments DSL (subagent)** — delegate to a subagent: load and
      apply **[Review Arguments DSL](../review-arguments-dsl/SKILL.md)** (and its
      [CHECKLIST.md](../review-arguments-dsl/CHECKLIST.md)) against the
      `arguments do` block. Fix all findings, then re-run the review until clean.
      **Complete this step before starting steps 3e–3f** — DSL corrections change
      the CLI arguments that tests and YARD docs must reflect.

   Steps 3e and 3f may run **in parallel** (they review independent file sets).

   e. **Review Command Tests (subagent)** — delegate to a subagent: load and
      apply **[Command Test Conventions](../command-test-conventions/SKILL.md)** against
      the unit and integration spec files. Fix all findings, then re-run the
      review until clean.

   f. **Review YARD Documentation (subagent)** — delegate to a subagent: load
      and apply **[Command YARD Documentation](../command-yard-documentation/SKILL.md)**
      against the command class. Fix all findings, then re-run the review until
      clean.

4. **Scaffold facade delegation** — write or update the `Git::Lib` method per [Facade
   delegation and policy options](#facade-delegation-and-policy-options).

5. **Run quality gates** — pass per-slice gates: `bundle exec rspec`, `bundle exec
   rake test`, `bundle exec rubocop`, `bundle exec rake yard`.

## Output

Produce:

1. **Command class** — `lib/git/commands/{command}.rb` (and optionally the namespace
   module file for the first command in a namespace)
2. **Unit tests** — `spec/unit/git/commands/{command}_spec.rb`
3. **Integration tests** — `spec/integration/git/commands/{command}_spec.rb`
4. **Facade delegation** — updated `Git::Lib` method in `lib/git/lib.rb`
5. **All quality gates pass** — rspec, minitest, rubocop, and yard all green
