---
name: command-test-conventions
description: "Conventions for writing and reviewing unit and integration tests for Git::Commands::* classes. Use when scaffolding new command tests or auditing existing ones."
---

# Command Test Conventions

Conventions for writing and reviewing unit and integration tests for
`Git::Commands::*` classes.

## Related skills

- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline
  RSpec rules that govern all unit test structure, naming, setup, stubbing, and
  coverage; this skill adds command-specific conventions on top
- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries
  match git CLI
- [Command Implementation](../command-implementation/SKILL.md) — class
  structure, phased rollout gates, and internal compatibility contracts
- [Command YARD Documentation](../command-yard-documentation/SKILL.md)
  — documentation completeness for command classes

## Input

The invocation needs the unit and/or integration spec file(s) to review. Including
the corresponding command source file provides useful context for verifying argument
coverage.

**Prerequisite:** Read the **entire** [RSpec Unit Testing
Standards](../rspec-unit-testing-standards/SKILL.md) skill (line 1 through EOF)
before beginning. It defines the baseline Rules 1–28 that this skill extends. Without
it, MUST-level structural, naming, stubbing, and coverage checks will not be applied.

### Version-aware test scope

Before deciding that test coverage is missing for an option, alias, or flag
form, determine the repository's minimum supported Git version from project
metadata. In this repository, `git.gemspec` declares `git 2.28.0 or greater`.

Coverage expectations for CLI forms must be based on the minimum supported Git
version, not only on the locally installed Git. Use version-matched upstream
documentation first, version-matched upstream source when needed, and local
`git <command> -h` output only as a supplemental check.

Do not require tests for newer-version-only forms that are not supported by the
minimum supported Git version. Symmetrically, if the local Git omits or
abbreviates a form that is supported in the minimum version, tests should still
cover the minimum-version behavior.

## Reference

### Unit tests

Unit tests verify CLI argument building and command-layer behavior for each command.

#### Cover these cases

- Base invocation (no options): verify literals and return pass-through. Store the
  `.and_return` value in an `expected_result` variable and assert `expect(result).to
  eq(expected_result)` to verify that `#call` passes through what
  `execution_context.command_capturing` returns. This assertion belongs only in the
  base invocation test — do not repeat it in every test.
- Each positional operand variation (e.g., single value, multiple values)
- Each flag option, including aliases (e.g., `:force` and `:f`)
- `max_times:` flag options: test with `true` (emits once) and the maximum integer
  (emits N times), plus each alias with `true`
- Flag options combined with operands where meaningful (e.g., an option that modifies
  how operands are interpreted)
- Value options with each accepted form (e.g., boolean `true` vs a string value like
  `'lines,cumulative'`)
- Pathspecs or other repeatable/`end_of_options`-based operands, both alone and
  combined with preceding operands
- Execution options forwarding where applicable (e.g., `timeout:`)
- Exit-status behavior for commands using `allow_exit_status` with a non-default
  range: test that exit codes within the declared range return a result without
  raising, and that exit codes outside the range raise `FailedError`. For example, if
  the command declares `allow_exit_status 0..1`, test that exit codes 0 and 1
  succeed, and that exit codes 2 and 128 raise `FailedError`. Commands that only
  succeed at exit code 0 (the default) do not need a unit-level exit code test — the
  integration error-handling test covers that path.
- Input validation (`ArgumentError`) for per-argument validation failures: unknown
  options, `required:` violations, `type:` mismatches, etc. Command classes generally
  do **not** declare cross-argument constraint methods (`conflicts`, `requires`,
  `requires_one_of`, `requires_exactly_one_of`, `forbid_values`, `allowed_values`,
  etc.) — git validates its own option semantics. The narrow exception is **arguments
  git cannot observe in its argv**: if an argument is `skip_cli: true`, it never
  reaches git's argv and git cannot detect incompatibilities — constraint
  declarations are appropriate and the resulting `ArgumentError` should be tested.
  See the validation delegation policy in `redesign/3_architecture_implementation.md`
  Insight 6.

#### Expectations for command invocation

Use the `expect_command_capturing` helper from `spec_helper.rb` (or
`expect_command_streaming` for streaming commands) which automatically includes
`raise_on_failure: false`:

```ruby
expect_command_capturing('clone', '--', url, dir).and_return(command_result)
```

When testing execution options, include forwarded keywords:

```ruby
expect_command_capturing('clone', '--', url, dir, timeout: 30).and_return(command_result)
```

These helpers expand to `expect(execution_context).to receive(:command_capturing)...`
— `expect` rather than `allow` because the call itself (the correct arguments
reaching git) is the behavior under test. See **Rule 19** in the [RSpec Unit Testing
Standards](../rspec-unit-testing-standards/SKILL.md).

##### Expectations for stdin-feeding commands

Commands that use `Base#with_stdin` pass an `IO` pipe read end as `in:` to
`execution_context.command_capturing`. Unit tests must capture that IO object and
assert its content. Use a block form on the `expect` to intercept keyword arguments:

```ruby
# Helper defined in the spec file:
def expect_batch_command(*extra_args, stdin_content: nil, **extra_opts) # rubocop:disable Metrics/AbcSize
  expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
    expect(args).to eq(['cat-file', '--batch-check', *extra_args])
    expect(kwargs).to include(raise_on_failure: false, **extra_opts)
    expect(kwargs[:in].read).to eq(stdin_content) if stdin_content
    command_result
  end
end

# Usage:
it 'passes the object via stdin and runs --batch-check' do
  expect_batch_command(stdin_content: "HEAD\n")
  command.call('HEAD')
end

it 'writes each object on its own line to stdin' do
  expect_batch_command(stdin_content: "HEAD\nv1.0\nabc123\n")
  command.call('HEAD', 'v1.0', 'abc123')
end

it 'includes --batch-all-objects and writes nothing to stdin' do
  expect_batch_command('--batch-all-objects', stdin_content: '')
  command.call(batch_all_objects: true)
end

# git-invisible argument exception: :objects is skip_cli: true, so git never sees
# it in argv and cannot detect these incompatibilities. Ruby must enforce them.
# conflicts: can't pass objects AND bypass stdin; requires_one_of: must choose one.
it 'raises when mutually exclusive DSL inputs are combined' do
  expect { command.call('HEAD', batch_all_objects: true) }
    .to raise_error(ArgumentError, /cannot specify :objects and :batch_all_objects/)
end
```

`kwargs[:in].read` works because `Base#with_stdin` writes to stdin on a background
thread and yields the read end immediately; the `read` call blocks until the writer
thread closes the pipe and EOF is reached, so the full content is returned. Test
`stdin_content: ''` explicitly for the no-input case (e.g. `--batch-all-objects`) to
confirm nothing is written.

##### What not to test

Unit tests should exercise each **code path** through the command, not each possible
**input value**. Avoid these patterns:

- **`option: false` for non-negatable flags.** Passing `false` to a non-negatable
  `flag_option` produces no output — identical to the base invocation with no
  options. The "no arguments" test already covers this path. (Negatable flags like
  `single_branch` are different: `false` produces `--no-single-branch`, which is a
  distinct code path worth testing.)
- **Repeating the return value assertion.** The base invocation test asserts
  `expect(result).to eq(expected_result)` once as a contract check. Do not repeat
  this assertion in other tests — one check per file is sufficient.
- **Intermediate integers for `max_times:` flags.** When a flag declares
  `max_times: N`, test only `true` and the max integer N. Do not test intermediate
  values (e.g. `force: 1` when `max_times: 2`) — the DSL handles all valid integers
  uniformly and intermediate values exercise the same code path.
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
  identical code. One test is sufficient unless the command parses or branches on the
  output.

The `Arguments` DSL has its own comprehensive spec (`arguments_spec.rb`) that tests
flag handling, value options, positionals, `end_of_options`, edge cases, and error
conditions. Command specs should test that the command **uses** the DSL correctly
(i.e., the right arguments reach `execution_context.command_capturing`), not re-test
the DSL's own behavior.

**Policy vs. interface testing:** Command classes are neutral, faithful
representations of the git CLI. Their unit tests verify CLI argument building (the
neutral interface), not policy enforcement. Tests should **not** hardcode policy
assumptions — for example, a command spec should not always pass `edit: false` or
expect `--no-edit` unless the test is specifically exercising that option.

> **Anti-pattern:** every `it` block in a command spec passes `edit: false`,
> `progress: false`, or `no_color: true` — this tests the facade's policy, not
> the command's interface.
>
> **Correct pattern:** test each option independently (`it 'passes --no-edit
> when edit is false'`); test the default (no option passed) separately. Policy
> enforcement (which options the facade passes and why) is tested at the facade
> layer (`lib_command_spec.rb`).

**Where to test policy enforcement:** Policy tests belong in the facade layer,
not in command specs. When a `Git::Lib` method sets policy defaults like
`edit: false` or `progress: false`, the corresponding `lib_command_spec.rb`
(or `lib_spec.rb`) test should verify those defaults reach the command:

```ruby
# spec/unit/git/lib_command_spec.rb — facade policy-default test
describe '#pull' do
  it 'defaults to edit: false for non-interactive execution' do
    expect_any_instance_of(Git::Commands::Pull)
      .to receive(:call).with(anything, edit: false).and_call_original
    lib.pull('origin', 'main')
  end
end
```

This separation ensures:
- Command specs verify the **neutral interface** (every option works correctly)
- Facade specs verify the **policy** (the right options are passed and why)
- An AI sees exactly where each concern is tested and does not conflate them

See "Command-layer neutrality" in CONTRIBUTING.md.

#### `#initialize` — omit from command specs

**Do not write a `describe '#initialize'` block in command specs.** This is a
deliberate exception to Rule 2's SHOULD guidance for concrete subclasses. The full
reasoning chain:

1. **Rule 2's `have_attributes` form requires public attributes.** `Base#initialize`
   stores `@execution_context` as a private instance variable with no `attr_reader`,
   so there is nothing to pass to `have_attributes`. The form that Rule 2 uses cannot
   be applied.

2. **The only fallback is `not_to raise_error`, which is a Rule 24 violation.**
   Asserting that `described_class.new(execution_context)` does not raise merely
   confirms the code runs — it is not an observable behavioral assertion.

3. **Both Rule 2 purposes are already satisfied by other means:**
   - *Documentation:* the `let(:command) { described_class.new(execution_context) }`
     declaration at the top of every spec documents the constructor signature
     as clearly as a dedicated block would.
   - *Accidental-override guard:* `let(:command)` is evaluated before every example.
     If a subclass accidentally introduced a `def initialize` with a different
     signature, every test in the file would immediately raise `ArgumentError` —
     providing the same protection a dedicated block would.

4. **`Base#initialize` is covered by `base_spec.rb`.** Command subclasses that do
   not override `#initialize` gain nothing from repeating it.

**Required fix if found:** Remove any `describe '#initialize'` block that contains
only `expect { described_class.new(execution_context) }.not_to raise_error` — it is
a Rule 24 violation and provides no coverage value.

#### Unit test grouping

Unit tests are organized under `describe '#call'` with three sections:

1. **Argument building** (the bulk) — flat `context` blocks, one per option/operand
   variation. These are always present and come first.
2. **`context 'exit code handling'`** — only for commands with `allow_exit_status`
   ranges beyond `0..0`. Uses mocked exit codes via `command_result` helper to test
   that exit codes within the allowed range return a result and exit codes outside
   the range raise `FailedError`.
3. **`context 'input validation'`** — only for commands with validation rules. Covers
   unsupported options and required arguments that raise `ArgumentError`.
   Cross-argument constraints for git-visible arguments are not tested because
   command classes do not declare them. The exception is constraints on `skip_cli:
   true` arguments (e.g., `conflicts :objects, :batch_all_objects` and
   `requires_one_of :objects, :batch_all_objects`), which should be tested.

The exit code and input validation blocks are optional — include them only when the
command has those behaviors. They always appear at the end of `#call`, in that order.

**Required fix if found:** The section names `'exit code handling'` and `'input
validation'` are exact string literals — do not paraphrase. A context named
`'with an unsupported option'` or `'when the option is invalid'` instead of
`'input validation'` MUST be renamed. These names are load-bearing identifiers: they
signal to reviewers at a glance which structural section they are looking at and what
it may or may not contain.

Unit test descriptions should be concise and action-oriented. Use descriptions like
"includes the --cached flag", "passes both commits as operands", "combines commit
with pathspecs".

> **Exception to RSpec Unit Testing Standards Rules 11–12 (subject and let
> ordering):** Command unit tests intentionally omit `subject` within `describe
> '#call'`. Because each test exercises a different argument combination, there is no
> single fixed call expressible as a shared `subject`. Use `let(:command)` at the
> `RSpec.describe` level and call `command.call(...)` directly inside each `it`
> block, overriding `let` inputs per `context` block as needed.

**Example with all three sections:**

```ruby
RSpec.describe Git::Commands::Branch::Delete do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    # Argument building — flat contexts
    context 'with single branch name' do
      it 'passes the branch name' do
        expected_result = command_result('Deleted branch feature.')
        expect_command_capturing('branch', '-d', 'feature').and_return(expected_result)
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
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
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

> **Branch workflow:** Implement any new or updated tests on a feature branch. Never
> commit or push directly to `main` — open a pull request when changes are ready to
> merge.

#### Integration test grouping

Integration tests must be organized into two `context` blocks under `#call`:

- `context 'when the command succeeds'` — smoke tests, option variations, and exit
  code variants
- `context 'when the command fails'` — error handling tests (`FailedError`)

This grouping provides a consistent structure across all command specs and makes it
immediately clear which tests cover the happy path vs. error conditions.

**Simple command example** (default exit code handling):

```ruby
RSpec.describe Git::Commands::Add, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        # ... valid invocation ...
      end
    end

    context 'when the command fails' do
      it 'raises FailedError with a nonexistent path' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent.txt') }
          .to raise_error(Git::FailedError, /nonexistent\.txt/)
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
    context 'when the command succeeds' do
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

    context 'when the command fails' do
      it 'raises FailedError for invalid revision' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent-ref') }
          .to raise_error(Git::FailedError, /nonexistent-ref/)
      end
    end
  end
end
```

#### Additional integration conventions

**Always specify `initial_branch: 'main'` when calling `Git.init` in test setup.**
The `in an empty repository` shared context already does this for the primary repo,
but tests that create *additional* repositories in a `before` block (e.g., a bare
remote, a second clone target) must pass `initial_branch: 'main'` explicitly to
`Git.init`. Without it, the repo's `HEAD` points to whatever `init.defaultBranch`
is set to on the CI runner or developer's machine, making the test non-deterministic:

```ruby
# ❌ Fragile — HEAD points to the system default branch name
Git.init(bare_dir, bare: true)

# ✅ Correct — HEAD always points to 'main'
Git.init(bare_dir, bare: true, initial_branch: 'main')
```

**No shell-outs in tests.** Never use backticks, `system()`, or `%x[]` in tests. For
git commands (including setup steps), use `execution_context.command_capturing` — it
is portable across platforms, handles paths with spaces, and uses the same mechanism
the command classes themselves use. For example:
`execution_context.command_capturing('rev-parse', 'HEAD').stdout.strip`. For non-git
operations (file creation, directory manipulation, etc.), use Ruby's standard library
(`FileUtils`, `File`, `Dir`) instead of shelling out.

**Write cross-platform tests.** Avoid Unix-specific paths like `/dev/null`,
`/dev/zero`, or hardcoded `/tmp`. Use Ruby's standard library for temporary files and
directories (`Dir.mktmpdir`, `Tempfile`), and use `File.join` for path construction.
When creating failure scenarios, use portable approaches (e.g., create a regular file
and try to use it where a directory is expected) rather than platform-specific
tricks.

### Shared conventions

**Do not use other Commands classes in tests.** Each spec tests exactly one command
class. Use `execution_context.command_capturing`, `repo`, or standard library methods
for setup instead of instantiating other Commands classes. This maintains test
isolation and prevents bugs in one command from breaking another command's tests.

**Require only the command under test.** See [Rule
5](../rspec-unit-testing-standards/SKILL.md#rule-5-must-require-spec_helper-and-only-the-files-under-test)
in RSpec Unit Testing Standards (MUST). For command specs specifically: do not
require other command classes even if they are not instantiated — unused requires
create false coupling between specs.

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

**Test descriptions must match assertions.** See [Rule
9](../rspec-unit-testing-standards/SKILL.md#rule-9-must-it-blocks-assert-one-concept-and-the-description-must-match-the-assertion)
in RSpec Unit Testing Standards (MUST). This applies equally to command specs: a test
described as "includes the --force flag" must assert that the flag appears in the
arguments, not merely that `#call` returns a result.

**Regex patterns** in test assertions should not use Ruby's `/m` modifier unless
intentionally matching across newlines. Git output is line-based, so patterns should
match within single lines.

## Workflow

1. Load the [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md)
   skill (line 1 through EOF)
2. Read the spec file(s) under review and the corresponding command source file
3. Determine the minimum supported Git version
   (see [Version-aware test scope](#version-aware-test-scope))
4. Audit each spec against the rules in [Reference](#reference), checking unit and
   integration tests separately
5. Produce the [Output](#output)

## Output

Report only anomalies — skip items that comply. For each issue found, provide:

- **Rule or guideline violated** — cite by name and source skill (e.g., "Rule 22,
  RSpec Unit Testing Standards" or "What not to test, Command Test Conventions")
- **Location** — spec file and block path (e.g., `describe '#call' > context 'with
  :force option' > it '...'`)
- **Issue** — one sentence describing what is wrong
- **Fix** — the minimal change needed

Group findings under two headings:

**Required fixes** — MUST-level violations from either skill

**Suggested improvements** — SHOULD-level deviations, ordered by impact

If no issues are found, say so in one sentence and stop.
