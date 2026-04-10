# Command Implementation — Reference

Detailed reference for `Git::Commands::Base` command classes. This file is loaded
by subagents during the [Command Implementation](SKILL.md) workflow.

## Contents

- [Contents](#contents)
- [Files to generate](#files-to-generate)
- [Single class vs. sub-command namespace](#single-class-vs-sub-command-namespace)
  - [When to use sub-commands](#when-to-use-sub-commands)
  - [Do NOT split by output format / output mode](#do-not-split-by-output-format--output-mode)
  - [When to keep a single class](#when-to-keep-a-single-class)
  - [Naming sub-command classes](#naming-sub-command-classes)
  - [Namespace module template](#namespace-module-template)
- [Architecture contract](#architecture-contract)
- [Command template (Base pattern)](#command-template-base-pattern)
- [`#call` override guidance](#call-override-guidance)
  - [Overriding `call` — inline example](#overriding-call--inline-example)
  - [Action-option-with-optional-value commands](#action-option-with-optional-value-commands)
  - [When to use `skip_cli` on `operand`](#when-to-use-skip_cli-on-operand)
- [`Base#with_stdin` mechanics](#basewith_stdin-mechanics)
- [Options completeness — consult the latest-version docs first](#options-completeness--consult-the-latest-version-docs-first)
  - [`requires_git_version` convention](#requires_git_version-convention)
  - [Execution-model conflicts](#execution-model-conflicts)
- [`end_of_options` placement](#end_of_options-placement)
  - [Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS](#rule-1--synopsis-shows----mirror-the-synopsis)
  - [Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation](#rule-2--synopsis-does-not-show----protect-operands-from-flag-misinterpretation)
- [Exit status guidance](#exit-status-guidance)
- [Facade delegation and policy options](#facade-delegation-and-policy-options)
- [Internal compatibility contract](#internal-compatibility-contract)
- [Phased rollout requirements](#phased-rollout-requirements)
- [Common failures](#common-failures)
  - [Policy/output-control flag hardcoded as `literal` (neutrality violation)](#policyoutput-control-flag-hardcoded-as-literal-neutrality-violation)
  - [Unnecessary `def call` override](#unnecessary-def-call-override)
  - [`execution_option` for fixed kwargs](#execution_option-for-fixed-kwargs)
  - [Other common failures](#other-common-failures)

## Files to generate

For `Git::Commands::Foo::Bar`, **all three files are required and must be created**:

- `lib/git/commands/foo/bar.rb` — the command class
- `spec/unit/git/commands/foo/bar_spec.rb` — unit tests
- `spec/integration/git/commands/foo/bar_spec.rb` — integration tests (mandatory, not
  optional)

Optional (first command in module):

- `lib/git/commands/foo.rb`

## Single class vs. sub-command namespace

Most git commands map to a single class. Split into a namespace module with multiple
sub-command classes when the git command surfaces **meaningfully different
operations** that have distinct call shapes or protocols.

### When to use sub-commands

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

### Do NOT split by output format / output mode

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

### When to keep a single class

- Different output modes (`--patch`, `--numstat`, `--raw`): **always** use a single
  class; expose modes as DSL options.
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

- **Never name a sub-command class `Object`** — it shadows Ruby's `::Object` base
  class anywhere that constant is looked up inside the namespace.
- **Never use the `*Info` or `*Result` suffix** on command classes — those suffixes
  are reserved for parsed result structs (`BranchInfo`, `TagInfo`,
  `BranchDeleteResult`) which live in the top-level `Git::` namespace, not in
  `Git::Commands::*`. A reader seeing `CommandFoo::BarInfo` expects a data struct,
  not a class that runs a subprocess.

### Namespace module template

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

## Architecture contract

For migrated commands, the expected structure is:

```ruby
require 'git/commands/base'

class SomeCommand < Git::Commands::Base
  arguments do
    ...
  end

  # optional — only when introduced after Git::MINIMUM_GIT_VERSION
  requires_git_version '2.29.0'

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

Structural requirements:

- Class inherits from `Git::Commands::Base`
- File requires `git/commands/base` (not `git/commands/arguments`)
- Has exactly one `arguments do` declaration
- Does not define command-specific `initialize` that only assigns
  `@execution_context`

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

## `#call` override guidance

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

**When overriding:**

- Bind arguments via `args_definition.bind(...)` — do not reimplement binding
- Delegate exit-status handling to `validate_exit_status!` — do not reimplement
- Do not call `super` after manual binding; use `@execution_context.command_capturing` directly

**DSL defaults:**

Defaults defined in the DSL (e.g., `operand :paths, default: ['.']`) are applied
automatically during `args_definition.bind(...)` — do not set defaults manually in
`call`.

When the command requires an explicit `def call` override, place YARD doc comments
**directly above** `def call` — do **not** use `# @!method call(*, **)` alongside
an explicit override.

### Overriding `call` — inline example

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

### Action-option-with-optional-value commands

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

### When to use `skip_cli` on `operand`

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

## `Base#with_stdin` mechanics

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

## Options completeness — consult the latest-version docs first

**Before writing any DSL entries**, use the documentation fetched during the
[Input](SKILL.md#git-documentation-for-the-git-command) phase and enumerate every
option the latest-version docs describe.

### `requires_git_version` convention

`requires_git_version` is a **class-level** declaration only. Individual options do
**not** carry version annotations. The declaration must use a `'major.minor.patch'`
string (e.g., `'2.29.0'`), not a `Gem::Version` or `Range` — pre-release versions
are not supported.

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

### Execution-model conflicts

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

## `end_of_options` placement

Determine placement based on whether the SYNOPSIS explicitly shows `--`. See the
Review Arguments DSL checklist for the full decision tree.

### Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS

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

### Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation

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

## Facade delegation and policy options

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

## Internal compatibility contract

This is the canonical location for the internal compatibility contract. Other
skills reference this section rather than duplicating it.

Ensure refactors preserve these contract expectations:

- constructor shape remains `initialize(execution_context)` (inherited from `Base`)
- command entrypoint remains `call(*, **)` at runtime (via `Base#call`)
- argument-definition metadata remains available via `args_definition`

If an intentional deviation exists, require migration notes/changelog documentation.

## Phased rollout requirements

This is the canonical location for phased rollout requirements. Other skills
reference this section rather than duplicating the full checklist.

For migration PRs, verify process constraints:

- changes are on a feature branch — **never commit or push directly to `main`**
- migration slice is scoped (pilot or one family), not all commands at once
- each slice is independently revertible
- refactor-only changes are not mixed with unrelated behavior changes
- quality gates pass for the slice — discover tasks via
  `bundle exec ruby -e "require 'rake'; load 'Rakefile'; puts Rake::Task['default:parallel'].prerequisites"`
  and run each individually via `bundle exec rake <task>`, fixing failures before
  advancing

## Common failures

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

### Unnecessary `def call` override

Do **not** add `def call(*, **) = super` or `def call(*, **) / super / end` for
commands that need no custom logic; it adds no behavior and conflicts with the
`@!method` directive.

### `execution_option` for fixed kwargs

`execution_option` must **not** be used for kwargs whose value must be
unconditionally fixed regardless of caller input. If a kwarg always has a specific
required value (e.g. `chomp: false` for commands returning raw content where trailing
newlines are data), hardcode it in a `def call` override instead — exposing it via
`execution_option` would allow callers to override a value that must never change.

### Other common failures

- lingering `ARGS = Arguments.define` constant and custom `#call`
- command-specific duplicated exit-status checks instead of `allow_exit_status`
- missing rationale comment for `allow_exit_status`
- missing YARD directive (`# @!method call(*, **)`)
- `call` override that reimplements `Base#call` logic instead of delegating to `validate_exit_status!`
- using a manual `IO.pipe` inline instead of `Base#with_stdin` for stdin-feeding commands
- migration PR scope too broad (not phased)
