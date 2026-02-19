## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with the git
subcommand name and the Ruby module path for the new class. Examples:

```text
Using the Scaffold New Command prompt, scaffold Git::Commands::Worktree::Add
for `git worktree add`.
```

```text
Scaffold New Command: Git::Commands::LsTree for `git ls-tree`.
```

The invocation needs the target `Git::Commands::*` class name and the git
subcommand (or subcommand + sub-action) it wraps.

---

## Scaffold New Command

Generate a production-ready command class, unit tests, integration tests, and YARD
docs using the `Git::Commands::Base` architecture.

### Related prompts

- **Review Command Implementation** — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts
- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review YARD Documentation** — documentation completeness for command classes

### Files to generate

For `Git::Commands::Foo::Bar`:

- `lib/git/commands/foo/bar.rb`
- `spec/unit/git/commands/foo/bar_spec.rb`
- `spec/integration/git/commands/foo/bar_spec.rb`

Optional (first command in module):

- `lib/git/commands/foo.rb`

### Single class vs. sub-command namespace

Most git commands map to a single class. Split into a namespace module with
multiple sub-command classes when the git command surfaces **meaningfully
different concerns** that have distinct call shapes, output formats, or
protocols.

#### When to use sub-commands

**Split by operation** — when the git command has named sub-actions whose
option sets have little overlap (each sub-action would have mostly dead options
if they shared one class):

```
git stash push / pop / apply / drop / list / show
git tag --create / --delete / --list
git worktree add / list / remove / move
```

**Split by output type / protocol** — when the same underlying git command
produces structurally different output depending on a mode flag, and callers
will always use one mode or the other (never both):

```
git diff --numstat  → Diff::Numstat   (integer line counts per file)
git diff --raw      → Diff::Raw       (file metadata, modes, status codes)
git diff            → Diff::Patch     (full unified patch text)

git cat-file --batch-check → CatFile::ObjectMeta    (sha + type + size per object)
git cat-file --batch       → CatFile::ObjectContent (sha + type + size + raw content)
```

**Split by stdin protocol** — when one variant reads from stdin and another
does not (even if the git command is the same). The stdin variant needs a
`call` override that uses `Base#with_stdin`; mixing that with a no-stdin path
in one class produces an awkward interface.

#### When to keep a single class

- Minor option variations that share the same output format and argument set.
- When the "different modes" are just 1–2 flags that can be `@overload`-documented
  naturally and all callers supply the same operands.
- When callers would always need both modes together (rare: consider a facade
  instead).

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

- **Never name a sub-command class `Object`** — it shadows Ruby's `::Object`
  base class anywhere that constant is looked up inside the namespace.
- **Never use the `*Info` or `*Result` suffix** on command classes — those
  suffixes are reserved for parsed result structs (`BranchInfo`, `TagInfo`,
  `BranchDeleteResult`) which live in the top-level `Git::` namespace, not
  in `Git::Commands::*`. A reader seeing `CommandFoo::BarInfo` expects a data
  struct, not a class that runs a subprocess.

#### Namespace module template

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
      class Bar < Base
        arguments do
          # literals/options/operands
        end

        # Optional: for commands where non-zero exits are valid
        # rationale comment
        # allow_exit_status 0..1

        # Execute the git ... command
        #
        # @overload ...
        # @return [Git::CommandLineResult] the result of calling `git ...`
        # @raise [Git::FailedError] if git exits outside allowed status range
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
```

### Overriding `call` — when `def call(...) = super` is not enough

Use `def call(...) = super` for simple commands where `Base#call` handles
everything (argument binding, forwarding, exit status validation).

Override `call` explicitly when the command needs custom pre-call logic:

- **Input validation** — guard `ArgumentError` for invalid option combinations
  (e.g., empty operands without a compensating flag)
- **stdin via IO pipe** — the `--batch` / `--batch-check` protocol requires
  feeding object names to the process's stdin; use `Base#with_stdin`
- **Non-trivial option routing** — when multiple call shapes need different
  argument sets built separately

When overriding, call `args_definition.bind(**options)` directly rather than
`super`, and invoke `@execution_context.command` yourself:

```ruby
def call(*objects, **options)
  raise ArgumentError, '...' if objects.empty? && !options[:flag]

  bound = args_definition.bind(**options)
  with_stdin(objects.map { |o| "#{o}\n" }.join) do |reader|
    run_batch(bound, reader)
  end
end

private

def run_batch(bound, reader)
  result = @execution_context.command(*bound, in: reader, **bound.execution_options, raise_on_failure: false)
  validate_exit_status!(result)
  result
end
```

Extract helpers like `run_batch` to stay within Rubocop `Metrics/MethodLength`
and `Metrics/AbcSize` thresholds. Aim to keep `call` under ~10 lines.

**`in:` requires a real IO object.** `Process.spawn` only accepts objects with
a file descriptor; `StringIO` does not work. `Base#with_stdin` handles this by
opening an `IO.pipe`, writing the content, and yielding the read end. Pass an
empty string when the process should receive no input (e.g. when a
`--batch-all-objects`-style flag makes git enumerate objects itself).

### DSL ordering convention

1. literals
2. flag options
3. flag-or-value options
4. operands
5. as-operand value options (e.g., pathspecs)

Use aliases for long/short forms (`%i[force f]`), with long name first.
Use `args:` only when symbol mapping cannot produce the desired flag.

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

### Unit tests

Command unit tests should verify:

- exact arguments passed to `execution_context.command`
- inclusion of `raise_on_failure: false` (from `Base` behavior)
- execution-option forwarding where relevant (`timeout:`, etc.)
- allow-exit-status behavior where declared
- input validation (`ArgumentError`)

### Integration tests

Minimal structure:

- `describe 'when the command succeeds'`
- `describe 'when the command fails'`

Include at least one failure case per command.

### YARD requirements

- for simple commands, keep `def call(...) = super # rubocop:disable Lint/UselessMethodDefinition` as the YARD documentation anchor
- for commands with a `call` override, the override itself is the YARD anchor — no shim needed
- add `@overload` blocks for valid call shapes
- keep tags aligned with `arguments do` and `allow_exit_status` behavior

Note: The rubocop disable comment suppresses the Lint/UselessMethodDefinition warning.
The method appears "useless" to the linter but is required for YARD to render
per-command documentation.

### Phased rollout, compatibility, and quality gates

See **Review Command Implementation** for the canonical phased rollout checklist,
internal compatibility contract, and quality gate commands. In summary:

- **always work on a feature branch** — never commit or push directly to `main`;
  create a branch before starting (`git checkout -b <feature-branch-name>`) and
  open a pull request when the slice is ready
- migrate in small slices (pilot or family), not all commands at once
- keep each slice independently revertible
- pass per-slice gates: `bundle exec rspec`, `bundle exec rake test`,
  `bundle exec rubocop`, `bundle exec yard`
