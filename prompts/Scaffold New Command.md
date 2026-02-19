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

### DSL ordering convention

1. literals
2. flag options
3. flag-or-value options
4. operands
5. as-operand value options (e.g., pathspecs)

Use aliases for long/short forms (`%i[force f]`), with long name first.
Use `as:` only when symbol mapping cannot produce the desired flag.

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

- keep `def call(...) = super # rubocop:disable Lint/UselessMethodDefinition` for per-command docs
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
