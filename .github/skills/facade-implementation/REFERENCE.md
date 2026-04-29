# Facade Implementation — Reference

Detailed reference for `Git::Repository::*` facade modules and methods. This file
is loaded by subagents during the [Facade Implementation](SKILL.md) workflow.

## Contents

- [Files to generate](#files-to-generate)
- [Topic module selection](#topic-module-selection)
  - [Existing modules](#existing-modules)
  - [Decision rules for adding a new module](#decision-rules-for-adding-a-new-module)
    - [One-at-a-time extraction from `Git::Base` / `Git::Lib`](#one-at-a-time-extraction-from-gitbase--gitlib)
  - [Naming a new topic module](#naming-a-new-topic-module)
- [Designing a facade method](#designing-a-facade-method)
  - [Choosing the return type](#choosing-the-return-type)
  - [Choosing the method signature](#choosing-the-method-signature)
  - [One-line delegator](#one-line-delegator)
  - [Orchestration sequence](#orchestration-sequence)
  - [Sequencing multiple commands](#sequencing-multiple-commands)
- [Topic module skeleton](#topic-module-skeleton)
- [The five facade responsibilities checklist](#the-five-facade-responsibilities-checklist)
- [Argument pre-processing patterns](#argument-pre-processing-patterns)
  - [Path normalization](#path-normalization)
  - [Option whitelisting (preventing API expansion)](#option-whitelisting-preventing-api-expansion)
  - [Deprecation handling](#deprecation-handling)
  - [Defaults and policy options](#defaults-and-policy-options)
- [Internal helpers and encapsulation](#internal-helpers-and-encapsulation)
  - [The rule](#the-rule)
  - [The pattern](#the-pattern)
  - [Why this works](#why-this-works)
  - [Naming rules](#naming-rules)
  - [Growth path](#growth-path)
  - [When a helper needs `@execution_context`](#when-a-helper-needs-execution_context)
  - [Why not `ActiveSupport::Concern`?](#why-not-activesupportconcern)
- [Parser vs. raw stdout](#parser-vs-raw-stdout)
- [Result-class factory methods](#result-class-factory-methods)
- [Common failures](#common-failures)
  - [One-line delegation when orchestration is needed](#one-line-delegation-when-orchestration-is-needed)
  - [Leaking command-class types into the public API](#leaking-command-class-types-into-the-public-api)
  - [Exposing command-DSL-shaped argv in the facade signature](#exposing-command-dsl-shaped-argv-in-the-facade-signature)
  - [Changing the legacy return type or signature on extraction](#changing-the-legacy-return-type-or-signature-on-extraction)
  - [Bypassing `@execution_context`](#bypassing-execution_context)
  - [Hardcoding policy options the caller cannot override](#hardcoding-policy-options-the-caller-cannot-override)
  - [Skipping option whitelisting on opaque opts hashes](#skipping-option-whitelisting-on-opaque-opts-hashes)
  - [Mixing facade and command responsibilities](#mixing-facade-and-command-responsibilities)
  - [Adding a new topic module for a single method](#adding-a-new-topic-module-for-a-single-method)

## Files to generate

For a facade method on `Git::Repository::<Topic>`:

- `lib/git/repository/<topic>.rb` — the topic module (created on first method,
  extended for subsequent methods)
- `spec/unit/git/repository/<topic>_spec.rb` — unit tests
- `spec/integration/git/repository/<topic>_spec.rb` — integration tests
  (omit for true one-line delegators that add no orchestration)

When the topic module is new, also update:

- `lib/git/repository.rb` — add `require 'git/repository/<topic>'` and `include
  Git::Repository::<Topic>` in alphabetical order with the existing entries.

## Topic module selection

### Existing modules

List `lib/git/repository/` to see all current topic modules. Add to one of those
modules whenever the new method fits the topic. Do not create a new module when
an existing one would do.

### Decision rules for adding a new module

Create a new topic module only when **all** of the following are true:

1. At least three related facade methods share the topic and do not fit any
   existing module. "Related methods" may be **already implemented**, **planned
   in the migration tracker** (`redesign/3_architecture_implementation.md`), or
   **identified by grepping `Git::Base` / `Git::Lib`** for siblings that will be
   extracted to the same topic.
2. The topic is recognizable to a reader familiar with git — preferably matching
   one of the categories at <https://git-scm.com/docs> (Working tree, Branching,
   History, Sharing, Patching, Inspection, Configuration, Plumbing).
3. The methods would be awkward to place in any existing module without diluting
   that module's topic.

#### One-at-a-time extraction from `Git::Base` / `Git::Lib`

When migrating a single method without a planned batch:

1. Before deciding placement, scan `Git::Base` and `Git::Lib` for sibling methods
   on the same git topic (e.g. when extracting `branches_all`, also look for
   `branch`, `branch_current`, `branch_delete`, `current_branch_state`).
2. If ≥3 siblings (including the current one) will plausibly land in the same
   topic, create the new module on this first extraction so subsequent
   extractions have a home.
3. Otherwise place the method in the closest existing module. Revisit module
   organization when a third sibling joins; promote the cluster to its own
   module in a single `refactor(repository):` commit at that point.

For a one-off method that does not fit any existing module and does not justify a
new module yet, place it in the closest existing module and revisit the
organization when more methods join it.

### Naming a new topic module

- Use a single PascalCase word matching the file name (`Branching` →
  `branching.rb`).
- Prefer the gerund/noun form used by the git documentation categories
  (`Branching`, not `Branches`; `Inspection`, not `Inspect`).
- Avoid names that overlap with existing classes (`Branch`, `Diff`, `Log`) — those
  belong to result classes, not topic modules.
- Do not use the `*Info` or `*Result` suffix — reserved for parsed result structs.

## Designing a facade method

Decide the return type and the signature first (together they are the public
contract), then choose the body shape — one-line delegator for the simplest
cases, orchestration sequence otherwise.

### Choosing the return type

Apply these rules in order:

1. **Extracting from `Git::Base` or `Git::Lib`?** The facade method **must**
   return exactly what the legacy method returned (same type, same shape, same
   nil/empty semantics). Backward compatibility for users who called
   `g.foo` / `g.lib.foo` is the public contract being preserved during
   migration; capture the legacy return in the Step 2 plan.
2. **No legacy method (greenfield facade method)?** Choose the return type from
   the public-API perspective, in this order of preference:
   1. A **domain object** (`Git::BranchInfo`, `Git::DiffResult`, …) when the
      output has structure callers will inspect.
   2. A **primitive** (`String` of chomped stdout, `Boolean`, `Integer`) when
      the output is a single value.
   3. `nil` or `self` when the method is called for its side effects.
   4. **`Git::CommandLineResult`** only when the topic module explicitly
      documents that as its contract (rare — reserved for low-level escape
      hatches). Do not return `CommandLineResult` by default just because the
      command returns it.
3. **Never return** a type from `Git::Commands::*` (e.g.
   `Git::Commands::Foo::Bar::SomeResult`). Command-internal types are not part
   of the facade's public API.

### Choosing the method signature

The Ruby signature is part of the public contract — just as binding as the
return type. Apply these rules in order:

1. **Extracting from `Git::Base` or `Git::Lib`?** The facade method **must**
   preserve the legacy signature exactly: same positional arguments in the same
   order, same defaults, same `opts = {}` vs. `**options` shape, same
   nil/sentinel semantics. Capture the legacy signature in the Step 2 plan and
   diff against it after implementation.
2. **No legacy method (greenfield facade method)?** Design the signature from
   the public-API perspective:
   1. **Positional arguments** for the natural domain identifiers the method
      operates on (paths, refs, names, messages). At most two or three.
   2. **Keyword arguments with `**options`** for option hashes. Prefer
      `**options` over `opts = {}` in greenfield code — it surfaces unknown
      keys at the call site and reads better with the [whitelist
      pattern](#option-whitelisting-preventing-api-expansion). When the body
      forwards the options unchanged (the common case), use the **anonymous**
      keyword splat (`**`) so RuboCop's `Style/ArgumentsForwarding` cop is
      satisfied; name the splat (`**options`) only when the body must inspect
      or mutate the hash before forwarding (e.g. merging a positional
      argument into it, or applying a deprecation rewrite).
   3. **Named keyword arguments** (`force: false`, `all: true`) for a small,
      fixed set of flags that are part of the documented API and unlikely to
      grow. Switch to `**options` once the set exceeds ~3 keys.
3. **Validate cross-argument constraints in the facade**, before calling the
   command. Raise `ArgumentError` with a message that names the offending
   arguments — for example, `pull` raises when `branch` is given without
   `remote`. The command class stays neutral about Ruby-level argument
   relationships.
4. **Never expose** command-DSL-shaped arguments (`*argv`, raw `Hash` of CLI
   flags) on the facade. The facade's job is to translate Ruby idioms into
   command calls; passing through opaque argv defeats the layer.

Mechanical patterns for shaping the inputs (path coercion, option whitelisting,
deprecation handling) live in [Argument pre-processing
patterns](#argument-pre-processing-patterns).

### One-line delegator

When the facade method takes no options hash, does no pre-processing, and only
a trivial post-processing step (such as `.stdout.chomp`), it is a single-line
delegation. For example, a hypothetical `Git::Repository::Inspection#current_branch`
preserving `Git::Lib#current_branch`'s `String` contract:

```ruby
# Return the name of the currently checked-out branch
#
# @example Get the current branch name
#   repo.current_branch #=> "main"
#
# @return [String] the current branch name
#
# @raise [Git::FailedError] if `git rev-parse` exits with a non-zero status
#
def current_branch
  Git::Commands::RevParse.new(@execution_context).call('--abbrev-ref', 'HEAD').stdout.chomp
end
```

Use the one-line form only when **all** of the following hold:

- The Ruby signature exactly matches the command's `#call` signature (with at most
  trivial coercion like `Array(paths)` or `*[remote, branch].compact`).
- The method takes no options hash. Any facade method that accepts options must
  whitelist them — see [Option whitelisting](#option-whitelisting-preventing-api-expansion) —
  which makes it at minimum a two-line orchestration.
- The post-processing is at most a single chained call (`.stdout`,
  `.stdout.chomp`, etc.) that produces the documented return type (see
  [Choosing the return type](#choosing-the-return-type) above).

If the documented return type requires parsing, multiple commands, validation,
deprecation, option whitelisting, or any conditional logic, the facade needs an
orchestration sequence — not a one-line delegator.

### Orchestration sequence

When the facade method needs pre-processing, multiple commands, parsing, or result
assembly, expand the body into explicit phases:

```ruby
def branches_all
  result = Git::Commands::Branch::List.new(@execution_context).call(
    all: true,
    format: Git::Parsers::Branch::FORMAT_STRING
  )
  Git::Parsers::Branch.parse_list(result.stdout)
end

def commit(message, opts = {})
  Git::Repository::Internal.assert_valid_opts!(COMMIT_ALLOWED_OPTS, **opts)
  opts = opts.merge(message: message) if message
  opts = deprecate_commit_no_gpg_sign_option(opts)
  Git::Commands::Commit.new(@execution_context).call(edit: false, **opts).stdout
end
```

Three phases — keep them in this order:

1. **Pre-process** — validate, whitelist, normalize, deprecate, default.
2. **Call** — invoke one or more `Git::Commands::*` instances, each via
   `@execution_context`.
3. **Assemble** — pass stdout/stderr/status through a parser or result-class
   factory method, or return the raw `CommandLineResult` value the topic module
   documents.

### Sequencing multiple commands

When a facade method orchestrates more than one command, sequence the calls
explicitly with intermediate results in local variables:

```ruby
def branch_status(name)
  upstream_result = Git::Commands::RevParse.new(@execution_context).call("#{name}@{upstream}")
  ahead_behind = Git::Commands::RevList.new(@execution_context).call(
    "#{name}...#{upstream_result.stdout.chomp}",
    left_right: true,
    count: true
  )
  Git::BranchStatus.from_rev_list_output(name, ahead_behind.stdout)
end
```

Do not build a generic dispatcher or a "run everything in parallel" abstraction.
Explicit sequential calls are the documented pattern.

## Topic module skeleton

The full file layout for a topic module under `lib/git/repository/`:

```ruby
# frozen_string_literal: true

require 'git/commands/<command_a>'
require 'git/commands/<command_b>'
# require 'git/parsers/<parser>' — when the module uses a parser

module Git
  class Repository
    # Short summary of the topic and the facade methods it provides
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Topic
      # YARD docs per facade-yard-documentation skill
      def method_a(...)
        # body
      end

      # YARD docs per facade-yard-documentation skill
      def method_b(...)
        # body
      end
    end
  end
end
```

Then wire into `lib/git/repository.rb`:

```ruby
require 'git/repository/topic'
# ...

class Repository
  include Git::Repository::Topic
  # ...
end
```

## The five facade responsibilities checklist

From [redesign/2_architecture_redesign.md §2.1](../../../redesign/2_architecture_redesign.md).
For each facade method, confirm whether each responsibility applies and is handled:

- [ ] **Manage execution context** — calls `Git::Commands::*.new(@execution_context)`,
  never builds CLI argv directly and never bypasses the execution context.
- [ ] **Pre-process arguments** — applies path expansion, Ruby-idiomatic defaults,
  option whitelisting, deprecations.
- [ ] **Collect data** — gathers any additional information needed before or after
  command execution to build the response (e.g., reading config, listing refs).
  Most facade methods do not need this; flag explicitly when present.
- [ ] **Call commands** — invokes one or more `Git::Commands::*` classes; multiple
  calls are sequenced explicitly with intermediate results held in local variables.
- [ ] **Build rich response objects** — passes stdout through a `Git::Parsers::*`
  class or a result-class factory method to produce the documented return type.
  Returning the raw `CommandLineResult` is acceptable only when that is the
  documented public contract for the topic module.

## Argument pre-processing patterns

### Path normalization

Accept `String` or `Array<String>` for path arguments and splat into the command:

```ruby
def add(paths = '.', **)
  Git::Repository::Internal.assert_valid_opts!(ADD_ALLOWED_OPTS, **)
  Git::Commands::Add.new(@execution_context).call(*Array(paths), **).stdout
end
```

For path arguments that must be absolute or relative to the worktree root, expand
with `File.expand_path` against `@execution_context.git_work_dir`.

### Option whitelisting (preventing API expansion)

When the facade method accepts an options hash (positional `opts = {}` *or*
keyword `**options`) and forwards it to a command, the underlying command class
typically exposes many more options than the public facade contract. Without
filtering, callers could pass options that happen to match command DSL names but
were never part of the facade's public API — silently expanding the contract.

Use a per-method whitelist constant + `Git::Repository::Internal.assert_valid_opts!`:

```ruby
PULL_ALLOWED_OPTS = %i[allow_unrelated_histories].freeze
private_constant :PULL_ALLOWED_OPTS

def pull(remote = nil, branch = nil, **)
  raise ArgumentError, 'You must specify a remote if a branch is specified' if remote.nil? && !branch.nil?

  Git::Repository::Internal.assert_valid_opts!(PULL_ALLOWED_OPTS, **)
  positional_args = [remote, branch].compact
  Git::Commands::Pull.new(@execution_context)
                     .call(*positional_args, edit: false, **)
                     .stdout
end
```

The helper's signature is `assert_valid_opts!(allowed, **opts)` — the allowed
set comes first as a positional argument so callers can re-forward the
anonymous splat (`**`) into both the assertion and the command call. Name the
splat (`**options`) only when the body must inspect or mutate the options
hash before forwarding it (see the [`commit` example](#orchestration-sequence)
above for that case).

Rules:

- Name the constant `<METHOD>_ALLOWED_OPTS` and mark it `private_constant`. It
  is implementation detail, not part of the public API.
- Place the constant immediately before the method definition.
- The whitelist must match the `@option` tags in the YARD doc exactly. Reviewers
  should verify the two lists are equal in both directions.
- `Git::Repository::Internal.assert_valid_opts!` raises
  `ArgumentError: Unknown options: <key>` for any unrecognized key. Document this
  with `@raise [ArgumentError]` on the facade method.
- Every facade method that accepts an options hash **must** have a unit test
  that passes an unknown key and expects `ArgumentError`. That test — not a
  defensive `slice` at the call site — is what guarantees the whitelist stays
  load-bearing under future refactors. Forward `**options` directly after the
  assertion; do not also `slice` it (the assertion already proves every key is
  allowed, and a second mechanism invites cargo-culting and confusion about
  which one enforces the contract).

Even when the facade uses `**options` keyword forwarding, whitelist explicitly.
Relying on the command's own `ArgumentError` couples the facade contract to the
command's argument DSL, which is exactly what this layer exists to prevent.

### Deprecation handling

Handle deprecated option keys explicitly in the facade — never let deprecation
shims leak into the command class. Pattern:

```ruby
def commit(message, opts = {})
  opts = opts.merge(message: message) if message
  opts = deprecate_commit_no_gpg_sign_option(opts)
  opts = deprecate_commit_add_all_option(opts)
  Git::Commands::Commit.new(@execution_context).call(edit: false, **opts).stdout
end

private

def deprecate_commit_no_gpg_sign_option(opts)
  return opts unless opts.key?(:no_gpg_sign)

  Git::Deprecation.warn(
    "Git::Repository#commit's :no_gpg_sign option is deprecated. " \
    'Use gpg_sign: false instead.'
  )
  opts.dup.tap do |o|
    o[:gpg_sign] = false unless o.key?(:gpg_sign)
    o.delete(:no_gpg_sign)
  end
end
```

### Defaults and policy options

The facade is where **policy defaults** are applied — options that support
non-interactive execution, control output format for parsing, or set safe
command-level defaults. The command class stays neutral; the facade makes the
defaults explicit; callers may override when needed.

| Policy option | Why facade sets it |
| --- | --- |
| `edit: false` | Subprocesses cannot launch `$EDITOR` |
| `progress: false` | Progress output goes to stderr and pollutes parsing |
| `no_color: true` | ANSI escapes interfere with parsers |
| `format: Git::Parsers::Foo::FORMAT_STRING` | Facade wants a parseable format |

Always allow callers to override by placing policy defaults **before** the
caller's options in the keyword splat:

```ruby
Git::Commands::Pull.new(@execution_context).call(*args, edit: false, **opts)
# When opts contains :edit, the caller's value wins.
```

## Internal helpers and encapsulation

Topic modules under `lib/git/repository/` often share helper logic — option
validation, path normalization, deprecation warnings, error wrapping. These
helpers must be reachable from any topic module without leaking onto the public
`Git::Repository` API surface.

### The rule

**Do not put shared helpers as private methods on `Git::Repository`** (directly
or via `include`). `include` copies private instance methods onto the host class,
so any caller with a `Git::Repository` instance can `repo.send(:helper, ...)`.
This:

1. Re-creates the `Git::Lib` god-class problem the redesign is escaping.
2. Couples every topic module silently to ambient mixin state.
3. Is not actually private and not `@api`-marked, so YARD/tooling cannot enforce it.

### The pattern

Put shared helpers in a sibling **internal module** under `lib/git/repository/`
that is **not** `include`d into `Git::Repository`. Use `module_function` so
methods are called as fully-qualified singleton methods:

```ruby
# lib/git/repository/internal.rb
module Git
  class Repository
    # Namespace for internal helpers shared across facade topic modules
    #
    # @api private
    #
    module Internal
      module_function

      def assert_valid_opts!(allowed, **options)
        unknown = options.keys - allowed
        return if unknown.empty?

        raise ArgumentError, "Unknown options: #{unknown.join(', ')}"
      end
    end
  end
end
```

Call sites use the fully-qualified name:

```ruby
# lib/git/repository/staging.rb
def add(paths = '.', **)
  Git::Repository::Internal.assert_valid_opts!(ADD_ALLOWED_OPTS, **)
  Git::Commands::Add.new(@execution_context)
                    .call(*Array(paths), **)
                    .stdout
end
```

### Why this works

- **No mixin pollution.** `Git::Repository` instances do not gain
  `assert_valid_opts!` as a method. The helper is namespaced and private-by-API.
- **Explicit dependency.** A reader of `staging.rb` sees exactly where the helper
  comes from. No magic mixin chain.
- **Stateless by contract.** Without `include`, helpers cannot access
  `@execution_context` or other instance state — they must take everything as
  arguments. This keeps them pure and trivially unit-testable.
- **`@api private` is enforceable.** YARD respects the tag; downstream tooling
  can flag external use.

### Naming rules

Modules under `lib/git/repository/` use **bare nouns**, never role-suffixes like
`*Helpers` or `*Utils`:

| Module                              | Distinguished by               |
|-------------------------------------|--------------------------------|
| `Git::Repository::Staging`          | `include`d, `@api public`      |
| `Git::Repository::Branching`        | `include`d, `@api public`      |
| `Git::Repository::Internal`         | not `include`d, `@api private` |
| `Git::Repository::OptionValidation` | not `include`d, `@api private` |

Reasons:

- The location (`lib/git/repository/`) plus the `@api` tag and absence of an
  `include` line in `lib/git/repository.rb` already convey API status. A
  `*Helpers` suffix is redundant signage.
- Symmetry with topic modules keeps the directory listing readable.
- "Helpers" invites junk-drawer dumping; responsibility-named modules invite
  cohesion. Ruby stdlib follows the same convention (`URI::DEFAULT_PARSER`,
  `ActiveSupport::Inflector`, not `*Helpers`).

### Growth path

Start with a single `Git::Repository::Internal` catch-all. Split when **either**
trigger fires:

1. `Internal` accumulates more than ~5 methods.
2. Clear sub-themes emerge (validation vs. normalization vs. error wrapping).

Then extract responsibility-named sibling modules:

```text
Git::Repository::Internal              # catch-all (initial)
        ↓ grows / develops sub-themes
Git::Repository::OptionValidation      # extracted by responsibility
Git::Repository::PathNormalization
Git::Repository::Internal              # remaining miscellany (or deleted)
```

The extraction is mechanical — call sites change from
`Git::Repository::Internal.foo(...)` to `Git::Repository::OptionValidation.foo(...)`.

### When a helper needs `@execution_context`

`module_function` helpers cannot access instance state. If a helper needs the
execution context, prefer in this order:

1. **Pass it explicitly** as a method argument — keeps the helper stateless.
2. **Extract a small PORO** under `lib/git/repository/` (e.g.
   `Git::Repository::CommitOperation.new(execution_context).call(...)`),
   marked `@api private` and not `include`d.
3. **Inline private instance method on the topic module** — last resort, only
   when the helper is truly local to one topic. Mark `@api private`.

Avoid: re-introducing instance-method mixins on `Git::Repository` for "shared"
behavior. That is the exact pattern this rule prohibits.

### Why not `ActiveSupport::Concern`?

`Concern` does not solve the include-time leak: a `Concern` `include`d into a
class still copies its private instance methods onto that class. Rails tolerates
the leak via underscore prefixes and `:nodoc:`, or extracts service objects.
This project takes the stricter approach (sibling module + `module_function`)
without depending on `activesupport`.

## Parser vs. raw stdout

| Situation | Use |
| --- | --- |
| The facade returns a `String` of git's stdout (chomped or as-is) | `.stdout` |
| The facade returns a structured object built from line-by-line parsing | A `Git::Parsers::*` class |
| The facade returns a single bool/int derived from output | Inline transformation in the facade |
| The facade returns a `Git::CommandLineResult` | Return the raw result |

If the parsing logic exceeds ~5 lines, extract it into a `Git::Parsers::*` class
and call it from the facade. The facade method remains an orchestration sequence,
not a parser.

## Result-class factory methods

When the facade returns a domain object (e.g. `BranchInfo`, `BranchDeleteResult`,
`DiffResult`), use a factory method on the result class rather than constructing
it inline:

```ruby
def branch_delete(name, force: false)
  result = Git::Commands::Branch::Delete.new(@execution_context).call(name, force: force)
  Git::BranchDeleteResult.from(name: name, command_result: result)
end
```

This keeps result-object construction in one place per type and makes parsers
reusable across facade methods.

## Common failures

### One-line delegation when orchestration is needed

If the facade method discards information the caller documented as part of the
return type (e.g. returns `result.stdout` when the caller expects a parsed Hash),
the one-line form is wrong. Expand to the orchestration sequence and call the
appropriate parser.

### Leaking command-class types into the public API

The public return type should never be `Git::Commands::Foo::Bar::SomeResult` or
any other type from `Git::Commands::*`. Returning `Git::CommandLineResult` is
acceptable when the topic module documents that as its contract, but is not the
default — see [Choosing the return type](#choosing-the-return-type). Returning
domain objects (`Git::BranchInfo`, `Git::DiffResult`, etc.) is preferred for
methods that produce structured data.

### Exposing command-DSL-shaped argv in the facade signature

The facade signature is a Ruby API, not a transcription of the git CLI. Accepting
a free-form `*args` that is forwarded straight to the command, or naming keyword
arguments after CLI flags (e.g. `no_ff:`, `set_upstream_to:`) instead of
Ruby-idiomatic names, leaks the command DSL into the public contract. Define the
signature from the caller's perspective; translate to command DSL inside the
body.

### Changing the legacy return type or signature on extraction

When a facade method is extracted from `Git::Base` / `Git::Lib`, returning a
different type, accepting a different positional/keyword shape, or changing
nil-handling silently breaks every caller. Capture the legacy contract in the
Step 2 plan and diff before/after — see
[Choosing the return type](#choosing-the-return-type) rule 1 and
[Choosing the method signature](#choosing-the-method-signature) rule 1.

### Bypassing `@execution_context`

Constructing a command with anything other than `@execution_context` (e.g.
`Git::Commands::Add.new(self)` from inside a facade method) is wrong. The facade
holds a `Git::ExecutionContext::Repository`; commands must always be constructed
with it.

### Hardcoding policy options the caller cannot override

```ruby
# ❌ Wrong — caller cannot override
Git::Commands::Pull.new(@execution_context).call(*args, **opts, edit: false)

# ✅ Correct — caller's :edit wins because opts is splatted last
Git::Commands::Pull.new(@execution_context).call(*args, edit: false, **opts)
```

Place policy defaults before the caller's `**opts` so the caller's value wins on
key collision.

### Skipping option whitelisting on opaque opts hashes

If the facade accepts an options hash (positional `opts = {}` *or* keyword
`**options`), it must call `Git::Repository::Internal.assert_valid_opts!` against
a `private_constant`-marked `<METHOD>_ALLOWED_OPTS` constant. Without it,
callers can silently pass any key the command DSL happens to accept, which is
API expansion that the facade did not commit to.

### Mixing facade and command responsibilities

The facade does not build CLI argv. The command does not pre-process Ruby
arguments or parse output. If a facade method calls `command(...)` directly
(rather than `Git::Commands::*.new(...).call(...)`) it is bypassing the command
layer; refactor by introducing or extending the appropriate command class first.

### Adding a new topic module for a single method

A topic module is justified by ≥3 related methods. Single-method modules
fragment the API surface; place the method in the closest existing module and
revisit when more methods join.
