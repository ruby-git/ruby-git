## New Command Scaffolding for `Git::Commands::*`

### Goal

Given a git subcommand and its options, generate a complete, production-ready command class with ARGS definition, unit tests, integration tests, and YARD documentation that follows established project patterns exactly.

### Input

You will be given:
1. The git subcommand to implement (e.g., `git log`, `git stash list`)
2. The specific flags and options to support
3. The parent module name (e.g., `Git::Commands::Log`)
4. The calling conventions (what combinations of positional arguments and options are valid)
5. The exit code behavior (which exit codes are errors vs. normal)

### File Structure to Generate

For a command `Git::Commands::Foo::Bar`, generate:

```
lib/git/commands/foo/bar.rb          # Command class
spec/unit/git/commands/foo/bar_spec.rb        # Unit tests
spec/integration/git/commands/foo/bar_spec.rb # Integration tests
```

If this is the first command in its module, also generate:

```
lib/git/commands/foo.rb              # Parent module with usage examples
```

### Command Class Template

Follow this exact structure:

```ruby
# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Foo
      # <One-line summary of what this command does>
      #
      # <Brief description of the output format/content>
      #
      # @see Git::Commands::Foo Git::Commands::Foo for usage examples
      #
      # @see https://git-scm.com/docs/git-<subcommand> git-<subcommand> documentation
      #
      # @api private
      #
      class Bar
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          # ... see ARGS section below
        end.freeze

        # Creates a new Bar command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # <Short description>
        #
        # <@overload blocks — see YARD docs section>
        #
        # @return [Git::CommandLineResult] the result of calling `git <subcommand>`
        #
        # @raise [Git::FailedError] if git returns exit code >= <threshold> (actual error)
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)

          @execution_context.command(*bound_args, raise_on_failure: false).tap do |result|
            raise Git::FailedError, result if result.status.exitstatus >= <threshold>
          end
        end
      end
    end
  end
end
```

### ARGS Definition Rules

The `Arguments.define` block must follow this ordering convention:

1. **Literals** — the subcommand and fixed flags, in the order they should appear on the CLI
2. **Flag options** — boolean flags the caller can toggle
3. **Flag-or-value options** — flags that accept an optional value (e.g., `--dirstat` or `--dirstat=lines`)
4. **Operands** — positional arguments (commits, paths, etc.)
5. **Value options** — options with values, especially pathspecs at the end

**Prefer aliases over `args:` for long/short flag pairs:**
When git has both a long and short form (e.g., `-f`/`--force`, `-r`/`--remotes`, `-a`/`--all`), define an alias like `%i[force f]` instead of using `args: '--force'` or `args: '-f'`. **The long option name must always be first** in the alias array — the first name is canonical and determines the generated flag. A single-char first name would generate `-x` instead of the intended `--long-name` (e.g., `%i[f force]` would incorrectly generate `-f`). Only use `args:` when no Ruby symbol name maps to the correct git flag (e.g., `-C` for copy detection).

#### DSL Reference

| DSL method | Use for | Example |
|------------|---------|---------|
| `literal 'flag'` | Fixed flags always passed | `literal '--numstat'` |
| `flag_option :name` | Boolean on/off flags | `flag_option :cached` |
| `flag_option :name, args: '-X'` | Flag where no symbol maps to the git flag | `flag_option :find_copies, args: '-C'` |
| `flag_option %i[name1 name2]` | Aliases (both map to first name's flag) | `flag_option %i[cached staged]` |
| `flag_option %i[long_name x]` | Long/short alias (generates `--long-name`, callers use `long_name:` or `x:`) | `flag_option %i[force f]` |
| `flag_or_value_option :name, inline: true` | Flag that optionally takes a value (`--flag` or `--flag=value`) | `flag_or_value_option :dirstat, inline: true` |
| `operand :name` | Positional argument | `operand :commit1` |
| `value_option :name, as_operand: true, separator: '--', repeatable: true` | Value after `--` separator, can repeat | `value_option :pathspecs, as_operand: true, separator: '--', repeatable: true` |

### Exit Code Handling

Different git subcommands use different exit code conventions:

| Pattern | Threshold | Git subcommands |
|---------|-----------|-----------------|
| 0 = success, 1+ = error | `>= 1` | Most commands (`log`, `commit`, `push`, etc.) |
| 0 = no diff, 1 = diff found, 2+ = error | `>= 2` | `diff`, `diff-tree`, `diff-files` |

Use the correct threshold for the subcommand. Add a comment explaining the convention:

```ruby
# git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
```

### Unit Test Template

Unit tests mock `execution_context` and verify the correct CLI arguments are passed. Use the `command_result` helper from `spec_helper.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/foo/bar'

RSpec.describe Git::Commands::Foo::Bar do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  let(:sample_output) do
    <<~OUTPUT
      <realistic sample output for this command>
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments' do
      it '<describes what flags are passed>' do
        expect(execution_context).to receive(:command)
          .with('subcommand', '--flag1', '--flag2', raise_on_failure: false)
          .and_return(command_result(sample_output))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq(sample_output)
      end
    end

    # One context block per ARGS option / calling convention:
    # - Each flag_option gets its own context
    # - Each flag_or_value_option gets a context with tests for boolean true AND string value
    # - Operand combinations get contexts (single commit, two commits, etc.)
    # - Pathspecs get a context with tests for standalone AND combined with operands
    # - Aliases (like :staged for :cached) get their own `it` within the option's context

    describe 'exit code handling' do
      it 'returns successfully with exit code 0' do
        # ...
      end

      # If threshold is >= 2, also test exit code 1 succeeds:
      it 'returns successfully with exit code 1 when differences found' do
        # ...
      end

      it 'raises FailedError with exit code <threshold>' do
        # ...
      end

      it 'raises FailedError with exit code 128 (git error)' do
        # ...
      end
    end
  end
end
```

#### Unit Test Rules

1. **One test per ARGS entry** — every `flag_option`, `flag_or_value_option`, `value_option`, and operand combination must have at least one test
2. **Verify exact argument order** — use `.with(...)` expectations that match the full argument list including `raise_on_failure: false`
3. **Use `let(:static_args)` for long literal lists** — if the command has many fixed flags, extract them to a `let` block to reduce repetition (see Patch spec for example)
4. **Test descriptions should describe behavior**, not implementation — e.g., "includes the --cached flag" not "adds --cached flag and returns CommandLineResult"
5. **Flag-or-value options need two tests** — one for `option: true` (bare flag) and one for `option: 'value'` (inline value)
6. **Aliases need a test** — e.g., if `:staged` is an alias for `:cached`, test that `staged: true` produces `--cached`

### Integration Test Template

Integration tests are minimal — they verify the command executes against a real git repository. They do NOT test output format, parsing, or git behavior.

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/foo/bar'

RSpec.describe Git::Commands::Foo::Bar, :integration do
  include_context '<appropriate shared context>'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    it 'returns a CommandLineResult with output' do
      result = command.call(<args that produce output>)

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.stdout).not_to be_empty
    end

    describe 'exit code handling' do
      it 'returns exit code 0 with <no-output condition>' do
        result = command.call(<args that produce no output>)

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end

      # Only for commands where exit code 1 is non-error (e.g., diff):
      it 'succeeds with differences found' do
        result = command.call(<args that produce output>)

        expect(result.status.exitstatus).to be <= 1
        expect(result.stdout).not_to be_empty
      end

      it 'raises FailedError for invalid revision' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
```

#### Integration Test Rules

1. **Maximum 4-5 tests** — smoke test + exit code handling only
2. **Never assert on output format** — don't match regex patterns against git output (that's testing git, not the command)
3. **Never test option effects** — e.g., don't verify that `cached: true` changes the output differently than without it (unit tests verify the flag is passed; git's behavior is git's responsibility)
4. **Use shared contexts** for repository setup — never create git repositories inline in tests

### Parent Module Template (if needed)

```ruby
# frozen_string_literal: true

module Git
  module Commands
    # <One-line description of this command group>
    #
    # This module contains command classes for <purpose>:
    # - {Foo::Bar} - <brief description>
    # - {Foo::Baz} - <brief description>
    #
    # @see https://git-scm.com/docs/git-<subcommand> git-<subcommand> documentation
    #
    # Examples use {Foo::Bar}, but the same patterns apply to all <foo> commands.
    # `ctx` is the execution context used to run git commands.
    #
    # @example <calling convention 1>
    #   # git <subcommand> [flags]
    #   Bar.new(ctx).call
    #
    # <one @example per calling convention>
    #
    module Foo
    end
  end
end
```

### YARD Documentation

Follow the YARD Documentation Review Guidelines prompt to ensure all `@overload`, `@param`, `@option`, `@return`, and `@raise` tags are complete. Key reminders:

- Every option in ARGS must appear as `@option` in every overload where it's valid
- Blank comment line before every YARD tag
- Blank comment line before any new paragraph within a tag description (e.g., before `Alias: :f`)
- Consistent default values and descriptions across sibling commands
- Avoid implementation details (no flag names, output formats, or parsing behavior)

### Checklist Before Submitting

- [ ] ARGS literals match the git CLI in correct order
- [ ] ARGS options use the correct DSL method (`flag_option` vs `flag_or_value_option` vs `value_option`)
- [ ] Exit code threshold matches the git subcommand's convention
- [ ] Unit test exists for every ARGS entry
- [ ] Unit test descriptions are behavior-focused
- [ ] Integration tests are smoke-only (no output format assertions)
- [ ] YARD `@overload` exists for every valid calling convention
- [ ] Every `@option` appears in every applicable overload
- [ ] `@return` and `@raise` tags are present with standard wording
- [ ] Documentation avoids implementation details (no git flags, output formats, or parsing behavior)
- [ ] Formatting is consistent with sibling commands
