## Review Command Tests

Verify unit and integration tests for `Git::Commands::*` classes follow project
conventions.

Command classes follow `Git::Commands::Base`: they declare `arguments do`, may
declare `allow_exit_status`, and provide a YARD shim `def call(...) = super`.
`Base#call` performs binding and execution and always passes
`raise_on_failure: false`, then validates exit status membership against the
allowed range (`0..0` by default).

### Related prompts

- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Implementation** — class structure, phased rollout gates, and
  internal compatibility contracts
- **Review YARD Documentation** — documentation completeness for command classes

### Unit tests

Unit tests verify CLI argument building and command-layer behavior for each command.

#### Cover these cases

- Base invocation (no options): verify literals and return pass-through. Store the
  `.and_return` value in an `expected_result` variable and assert
  `expect(result).to eq(expected_result)` to verify that `#call` passes through what
  `execution_context.command` returns. This assertion belongs only in the base
  invocation test — do not repeat it in every test.
- Each positional operand variation (e.g., single value, multiple values)
- Each flag option, including aliases (e.g., `:force` and `:f`)
- Flag options combined with operands where meaningful (e.g., an option that modifies
  how operands are interpreted)
- Value options with each accepted form (e.g., boolean `true` vs a string value like
  `'lines,cumulative'`)
- Pathspecs or other repeatable/separator-based options, both alone and combined with
  operands
- Execution options forwarding where applicable (e.g., `timeout:`)
- Exit-status behavior for commands using `allow_exit_status`: test that exit codes
  within the declared range return a result without raising, and that exit codes
  outside the range raise `FailedError`. For example, if the command declares
  `allow_exit_status 0..1`, test that exit codes 0 and 1 succeed, and that exit
  codes 2 and 128 raise `FailedError`.
- Input validation (`ArgumentError`) for unsupported/conflicting/missing args

#### Expectations for command invocation

Use the `expect_command` helper from `spec_helper.rb` which automatically includes `raise_on_failure: false`:

```ruby
expect_command('clone', '--', url, dir).and_return(command_result)
```

When testing execution options, include forwarded keywords:

```ruby
expect_command('clone', '--', url, dir, timeout: 30).and_return(command_result)
```

#### What not to test

Unit tests should exercise each **code path** through the command, not each possible
**input value**. Avoid these patterns:

- **`option: false` for non-negatable flags.** Passing `false` to a non-negatable
  `flag_option` produces no output — identical to the base invocation with no
  options. The "no arguments" test already covers this path. (Negatable flags like
  `single_branch` are different: `false` produces `--no-single-branch`, which is a
  distinct code path worth testing.)
- **Repeating the return value assertion.** The base invocation test asserts
  `expect(result).to eq(expected_result)` once as a contract check. Do not
  repeat this assertion in other tests — one check per file is sufficient.
- **String-variant pass-through tests.** Do not write multiple tests that pass
  different string values through the same positional argument or value option. Tests
  like "handles paths with spaces" and "handles paths with unicode" exercise the same
  code path — the command passes strings unchanged. One test per operand/option is
  sufficient.
- **Multiple format variants for the same operand.** For example, a stash command
  that accepts a stash reference does not need separate tests for `stash@{0}`,
  `stash@{2}`, and `1` — they all flow through the same positional argument.
- **Varying mocked stdout for the same invocation.** If the command has no output
  parsing, testing the same `#call` with different mocked stdout values exercises
  identical code. One test is sufficient unless the command parses or branches on
  the output.

The `Arguments` DSL has its own comprehensive spec (`arguments_spec.rb`) that tests
flag handling, value options, positionals, separators, edge cases, and error
conditions. Command specs should test that the command **uses** the DSL correctly
(i.e., the right arguments reach `execution_context.command`), not re-test the DSL's
own behavior.

#### Test grouping

Unit tests are organized under `describe '#call'` with three sections:

1. **Argument building** (the bulk) — flat `context` blocks, one per option/operand
   variation. These are always present and come first.
2. **`context 'exit code handling'`** — only for commands with `allow_exit_status`
   ranges beyond `0..0`. Uses mocked exit codes via `command_result` helper to test
   that exit codes within the allowed range return a result and exit codes outside
   the range raise `FailedError`.
3. **`context 'input validation'`** — only for commands with validation rules. Covers
   unsupported options, conflicting options, and required arguments that raise
   `ArgumentError`.

The exit code and input validation blocks are optional — include them only when the
command has those behaviors. They always appear at the end of `#call`, in that order.

Unit test descriptions should be concise and action-oriented. Use descriptions like
"includes the --cached flag", "passes both commits as operands", "combines commit
with pathspecs".

**Example with all three sections:**

```ruby
RSpec.describe Git::Commands::Branch::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    # Argument building — flat contexts
    context 'with single branch name' do
      it 'passes the branch name' do
        expected_result = command_result('Deleted branch feature.')
        expect_command('branch', '-d', 'feature').and_return(expected_result)
        result = command.call('feature')
        expect(result).to eq(expected_result)
      end
    end

    context 'with :force option' do
      # ...
    end

    # Exit code handling — only when command declares allow_exit_status
    context 'exit code handling' do
      it 'returns result for exit code 0' do
        # ... mock exit code 0, assert result returned ...
      end

      it 'returns result for exit code 1 (partial failure)' do
        # ... mock exit code 1, assert result returned ...
      end

      it 'raises FailedError for exit code > 1' do
        # ... mock exit code 128, assert FailedError raised ...
      end
    end

    # Input validation — only when command validates input
    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('branch', invalid: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
```

**Example with argument building only** (no custom exit codes, no validation):

```ruby
RSpec.describe Git::Commands::Stash::Pop do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      # ...
    end

    context 'with stash reference' do
      # ...
    end

    context 'with :index option' do
      # ...
    end
  end
end
```

### Integration tests

Integration tests are minimal smoke tests that confirm the command executes
successfully against a real git repository. They should NOT test git's output format,
parsing behavior, or specific content of stdout — those concerns belong in parser
specs and facade/end-to-end specs.

Each integration spec file tests exactly **one command class**. Do not create
multi-command workflow specs that chain commands together — that is the concern of
facade or end-to-end tests.

Integration tests should only cover:

- A smoke test: calling with valid arguments returns a `CommandLineResult` with
  expected output (e.g., non-empty for commands that produce output)
- Exit codes from real git: one test per success exit code, exercised through real
  git invocations that naturally produce each code. For example, for `git diff`:
  identical refs produce exit code 0 with empty output; differing refs produce exit
  code ≤1 with non-empty output. This confirms that real git returns the exit codes
  the command's `allow_exit_status` range expects.
- Error handling: invalid input (e.g., a nonexistent ref) raises `FailedError`.
  **Every command must have at least one error handling test.** Even commands with
  non-default `allow_exit_status` ranges can be forced to fail (e.g., by removing
  `.git` to trigger exit code 128).

**Do not** write integration tests that assert on git's output format (e.g., matching
specific line patterns, status letters, or header syntax). The command's job is to
pass the correct arguments to git and return the result — verifying git's formatting
behavior is testing git, not the command. If a particular flag needs to be tested
(e.g., `-M` for rename detection), verify the flag appears in the arguments via a
unit test.

#### Test grouping

Integration tests must be organized into two `describe` blocks under `#call`:

- `describe 'when the command succeeds'` — smoke tests, option variations, and exit
  code variants
- `describe 'when the command fails'` — error handling tests (`FailedError`)

This grouping provides a consistent structure across all command specs and makes it
immediately clear which tests cover the happy path vs. error conditions.

**Simple command example** (default exit code handling):

```ruby
RSpec.describe Git::Commands::Add, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        # ... valid invocation ...
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent path' do
        expect { command.call('nonexistent.txt') }.to raise_error(Git::FailedError)
      end
    end
  end
end
```

**Custom exit code example** (command declares `allow_exit_status`):

```ruby
RSpec.describe Git::Commands::Diff::Numstat, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns exit code 0 with no differences' do
        result = command.call('initial', 'initial')
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end

      it 'succeeds with differences found' do
        result = command.call('initial', 'after_modify')
        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError for invalid revision' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
```

### General guidelines

**No shell-outs in tests.** Never use backticks, `system()`, or `%x[]` in tests. For
git commands (including setup steps), use `execution_context.command` — it is
portable across platforms, handles paths with spaces, and uses the same mechanism the
command classes themselves use. For example: `execution_context.command('rev-parse',
'HEAD').stdout.strip`. For non-git operations (file creation, directory manipulation,
etc.), use Ruby's standard library (`FileUtils`, `File`, `Dir`) instead of shelling
out.

**Do not use other Commands classes in tests.** Each spec tests exactly one command
class. Use `execution_context.command`, `repo`, or standard library methods for setup
instead of instantiating other Commands classes. This maintains test isolation and
prevents bugs in one command from breaking another command's tests.

**Write cross-platform tests.** Avoid Unix-specific paths like `/dev/null`, `/dev/zero`,
or hardcoded `/tmp`. Use Ruby's standard library for temporary files and directories
(`Dir.mktmpdir`, `Tempfile`), and use `File.join` for path construction. When creating
failure scenarios, use portable approaches (e.g., create a regular file and try to use
it where a directory is expected) rather than platform-specific tricks.

**Version-dependent tests.** When a test's behavior varies by git version, use `skip`
inside the `it` block — not the `skip:` metadata on `it`. The metadata form evaluates
at the describe level where helpers like `repo` are not available, causing a load
error. For example:

```ruby
it 'succeeds when no merge is in progress (git 2.35+)' do
  skip 'git < 2.35' if repo.lib.compare_version_to(2, 35, 0) < 0
  expect { command.call }.not_to raise_error
end
```

**Test descriptions must match assertions.** Every `it` block should assert what its
description claims. A test described as "returns the branch name" that only asserts
`eq(command_result)` is misleading — it passes without verifying the
described behavior.

**Require only the command under test.** Each integration spec should only `require`
the command class it describes. Do not require other command classes, even if they are
not instantiated — unused requires create false coupling between specs.

**Regex patterns** in test assertions should not use Ruby's `/m` modifier unless
intentionally matching across newlines. Git output is line-based, so patterns should
match within single lines.
