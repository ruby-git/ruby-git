## Refactoring Command to Return CommandLineResult

### Goal

Migrate a `Git::Commands::Branch::*` class from returning a parsed domain object (e.g., `Git::DiffResult`) to returning a raw `Git::CommandLineResult`. This moves parsing responsibility out of the command layer and into parsers or facades, keeping commands as thin wrappers around git execution.

### When to Use

Use this prompt when a command's `#call` method currently:
- Calls a parser on the command output (e.g., `Parsers::Diff::Numstat.parse(result.stdout)`)
- Returns a domain object (e.g., `Git::DiffResult`, `Git::LogResult`)
- Contains any output transformation logic

### Target `#call` Patterns

There are two patterns depending on the git subcommand's exit code behavior:

#### Standard exit codes (most commands)

When exit code 0 = success and any non-zero = error (e.g., `log`, `commit`, `push`, `checkout`, `branch`, `tag`, `add`, `rm`, `reset`, `show`, etc.), use the simplified two-liner. The default `raise_on_failure: true` handles errors automatically — no `.tap`, no exit code check, no comment needed:

```ruby
def call(*, **)
  bound_args = ARGS.bind(*, **)

  @execution_context.command(*bound_args)
end
```

#### Non-standard exit codes (diff, grep, etc.)

When some non-zero exit codes are normal (e.g., `diff` where 0 = no diff, 1 = diff found, 2+ = error), use the `.tap` pattern with `raise_on_failure: false` and a manual threshold check:

```ruby
def call(*, **)
  bound_args = ARGS.bind(*, **)

  # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
  @execution_context.command(*bound_args, raise_on_failure: false).tap do |result|
    raise Git::FailedError, result if result.status.exitstatus >= 2
  end
end
```

### Before / After Examples

**Before** (command parses output, non-standard exit codes):
```ruby
# @return [Git::DiffResult] diff result with per-file and total statistics
def call(*, **)
  bound_args = ARGS.bind(*, **)

  # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
  result = @execution_context.command(*bound_args, raise_on_failure: false)
  raise Git::FailedError, result if result.status.exitstatus >= 2

  Parsers::Diff::Numstat.parse(result.stdout, include_dirstat: !bound_args.dirstat.nil?)
end
```

**After** (non-standard exit codes):
```ruby
# @return [Git::CommandLineResult] the result of calling `git diff --numstat`
def call(*, **)
  bound_args = ARGS.bind(*, **)

  # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
  @execution_context.command(*bound_args, raise_on_failure: false).tap do |result|
    raise Git::FailedError, result if result.status.exitstatus >= 2
  end
end
```

**Before** (command parses output, standard exit codes):
```ruby
# @return [Git::LogResult] parsed log entries
def call(*, **)
  bound_args = ARGS.bind(*, **)

  result = @execution_context.command(*bound_args)

  Parsers::Log.parse(result.stdout)
end
```

**After** (standard exit codes):
```ruby
# @return [Git::CommandLineResult] the result of calling `git log`
def call(*, **)
  bound_args = ARGS.bind(*, **)

  @execution_context.command(*bound_args)
end
```

### Step-by-Step Migration

#### Step 1: Modify `#call` — Remove parsing, apply correct pattern

| Change | Details |
|--------|---------|
| Remove parser call | Delete the line that calls `Parsers::*::*.parse(...)` |
| Apply correct pattern | Use the simplified two-liner for standard exit codes, or the `.tap` pattern for non-standard |
| Remove local variable | For non-standard: replace `result = @execution_context.command(...)` with `@execution_context.command(...).tap do \|result\|`. For standard: just return the command call directly |
| Keep everything else | ARGS definition, exit code threshold, comment — all stay the same (for non-standard pattern) |

**Do NOT change:**
- The ARGS definition
- The `raise_on_failure: false` parameter (for non-standard exit codes)
- The exit code threshold (for non-standard exit codes)
- The error class (`Git::FailedError`)
- The exit code comment (for non-standard exit codes)

**Do remove:**
- Any `require` for parsers that are no longer called (e.g., `require 'git/parsers/diff'`) — but only if nothing else in the file uses it
- Any logic that inspects `bound_args` to pass options to the parser (e.g., `include_dirstat: !bound_args.dirstat.nil?`)
- For standard exit code commands: remove `raise_on_failure: false`, the manual exit code check, and the exit code comment entirely

#### Step 2: Update YARD `@return` tag

| Before | After |
|--------|-------|
| `@return [Git::DiffResult] diff result with per-file and total statistics` | `@return [Git::CommandLineResult] the result of calling \`git diff --numstat\`` |

Use the standard wording: `the result of calling \`git <subcommand>\``

#### Step 3: Update unit tests — Assert on CLI args and return type

**Before** (tests assert on parsed domain objects):
```ruby
it 'calls git diff --numstat --shortstat -M' do
  expect(execution_context).to receive(:command)
    .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
    .and_return(command_result(numstat_output))

  command.call
end

it 'returns DiffResult with stats' do
  allow(execution_context).to receive(:command)
    .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
    .and_return(command_result(numstat_output))

  result = command.call

  expect(result).to be_a(Git::DiffResult)
  expect(result.files_changed).to eq(2)
  expect(result.total_insertions).to eq(8)
end
```

**After** (tests assert on CLI args and `CommandLineResult`):
```ruby
it 'runs diff with --numstat, --shortstat, and -M flags' do
  expect(execution_context).to receive(:command)
    .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
    .and_return(command_result(numstat_output))

  result = command.call

  expect(result).to be_a(Git::CommandLineResult)
  expect(result.stdout).to eq(numstat_output)
end
```

**Migration rules for unit tests:**
- **Merge split tests** — if there were separate tests for "calls command" and "returns parsed result", merge into one test that verifies both CLI args (via `expect(...).to receive(:command).with(...)`) and return type (via `expect(result).to be_a(Git::CommandLineResult)`)
- **Remove parsed-result assertions** — delete all `expect(result.files)`, `expect(result.total_insertions)`, etc.
- **Add return type assertion** — every test should `expect(result).to be_a(Git::CommandLineResult)`
- **Keep the first test's stdout assertion** — the "no arguments" test should also verify `expect(result.stdout).to eq(sample_output)` to confirm output flows through
- **Keep all CLI args tests** — every test that verifies which flags are passed to `execution_context.command` should remain
- **Keep all exit code tests** — the exit code handling tests stay unchanged
- **Update test descriptions** — remove "and returns DiffResult/CommandLineResult" suffixes; focus on what the test verifies about CLI args

#### Step 4: Update integration tests — Reduce to smoke tests

**Before** (integration tests verify parsed output and git behavior):
```ruby
it 'includes numstat format in output' do
  result = command.call('initial', 'after_modify')
  expect(result.stdout).to match(/^\d+\t\d+\t.+$/)
end

it 'shows renamed files with arrow syntax in output' do
  result = command.call('after_modify', 'after_rename')
  expect(result.stdout).to match(/.*=>.*$/)
end

it 'includes directory statistics when requested' do
  result = command.call('initial', 'after_multi', dirstat: true)
  expect(result.stdout).to match(%r{\d+\.\d+% .+/})
end
```

**After** (integration tests are smoke + exit code only):
```ruby
it 'returns a CommandLineResult with output' do
  result = command.call('initial', 'after_modify')

  expect(result).to be_a(Git::CommandLineResult)
  expect(result.stdout).not_to be_empty
end

describe 'exit code handling' do
  it 'returns exit code 0 with no differences' do
    result = command.call('initial', 'initial')

    expect(result.status.exitstatus).to eq(0)
    expect(result.stdout).to be_empty
  end

  it 'succeeds with differences found' do
    result = command.call('initial', 'after_modify')

    expect(result.status.exitstatus).to be <= 1
    expect(result.stdout).not_to be_empty
  end

  it 'raises FailedError for invalid revision' do
    expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
  end
end
```

**Migration rules for integration tests:**
- **Remove all output format assertions** — regex matches on git output format (numstat lines, raw status letters, patch headers, rename syntax) are testing git's behavior, not the command's
- **Remove all option-effect tests** — tests that verify `:dirstat` changes the output, or `:cached` produces different results, are testing git's behavior
- **Remove all parsing-related tests** — tests for binary handling, rename detection, multiple files, etc. belong in parser specs
- **Keep exactly 4 tests** — one smoke test and three exit code tests (see template above)
- **Do not assert on output content** — only assert `not_to be_empty` or `to be_empty`, never match specific format

#### Step 5: Verify callers (facades)

If any facade or higher-level class calls this command and depends on the parsed return type, it must be updated to call the parser itself:

**Before** (facade relies on parsed return):
```ruby
def diff_numstat(...)
  result = diff_numstat_command.call(...)
  # result is already a DiffResult
  result
end
```

**After** (facade parses the raw result):
```ruby
def diff_numstat(...)
  result = diff_numstat_command.call(...)
  Parsers::Diff::Numstat.parse(result.stdout, include_dirstat: ...)
end
```

**Check:**
- [ ] Search for all callers of the command's `#call` method
- [ ] Verify each caller handles `CommandLineResult` instead of the old domain object
- [ ] If a caller was parsing-aware, move parsing into the caller
- [ ] Update caller tests to mock the command returning `CommandLineResult` instead of the domain object

#### Step 6: Clean up requires

If the command file required parser modules only for the `#call` method, those requires may no longer be needed:

```ruby
# Remove if no longer used in this file:
require 'git/parsers/diff'
```

**Check before removing:** Ensure nothing else in the file references the parser module.

### Checklist

- [ ] `#call` uses correct pattern — simplified two-liner for standard exit codes, `.tap` pattern for non-standard
- [ ] No `raise_on_failure: false` for standard exit code commands
- [ ] `@return` tag updated to `[Git::CommandLineResult]`
- [ ] Parser `require` removed (if no longer needed)
- [ ] Unit tests assert `Git::CommandLineResult` not old domain object
- [ ] Unit tests removed all parsed-result assertions (`result.files`, `result.total_insertions`, etc.)
- [ ] Unit tests kept all CLI argument verification
- [ ] Unit tests kept all exit code handling tests
- [ ] Integration tests reduced to smoke + exit code (4 tests max)
- [ ] Integration tests have zero output format assertions (no regex matching on git output)
- [ ] All callers updated to handle `CommandLineResult`
- [ ] All tests pass
- [ ] YARD docs reviewed for completeness (apply YARD Documentation Review prompt)
