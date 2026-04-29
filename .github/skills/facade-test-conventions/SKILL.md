---
name: facade-test-conventions
description: "Conventions for writing and reviewing unit and integration tests for Git::Repository facade methods (modules under lib/git/repository/). Use when scaffolding new facade tests or auditing existing ones in spec/unit/git/repository/ and spec/integration/git/repository/."
---

# Facade Test Conventions

Conventions for writing and reviewing unit and integration tests for facade
methods on `Git::Repository::*` modules.

## Contents

- [Related skills](#related-skills)
- [Input](#input)
- [Reference](#reference)
  - [Unit tests](#unit-tests)
    - [Setup pattern](#setup-pattern)
    - [Cover these cases](#cover-these-cases)
    - [Expectations for command invocation](#expectations-for-command-invocation)
    - [What not to test](#what-not-to-test)
    - [Unit test grouping](#unit-test-grouping)
  - [Integration tests](#integration-tests)
    - [When to write integration tests](#when-to-write-integration-tests)
    - [When to skip integration tests](#when-to-skip-integration-tests)
    - [Integration test grouping](#integration-test-grouping)
    - [What integration tests assert](#what-integration-tests-assert)
    - [What integration tests do not assert](#what-integration-tests-do-not-assert)
- [Workflow](#workflow)
- [Output](#output)
  - [When writing new facade tests](#when-writing-new-facade-tests)
  - [When reviewing existing facade tests](#when-reviewing-existing-facade-tests)

## Related skills

- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline
  RSpec rules that govern all unit test structure, naming, setup, stubbing, and
  coverage; this skill adds facade-specific conventions on top
- [Facade Implementation](../facade-implementation/SKILL.md) — facade module
  structure and orchestration patterns
- [Facade YARD Documentation](../facade-yard-documentation/SKILL.md) — YARD docs
  for facade modules and methods
- [Command Test Conventions](../command-test-conventions/SKILL.md) — sibling skill
  that tests the underlying `Git::Commands::*` classes the facade calls

## Input

The invocation needs the unit and/or integration spec file(s) to review. Including
the corresponding facade module file (`lib/git/repository/<topic>.rb`) provides
useful context for verifying delegation contracts and option forwarding.

**Prerequisite:** Read the **entire** [RSpec Unit Testing
Standards](../rspec-unit-testing-standards/SKILL.md) skill (line 1 through EOF)
before beginning. It defines the baseline Rules 1–28 that this skill extends.

## Reference

### Unit tests

Facade unit tests verify the **orchestration contract** between the facade method
and the components it calls (`Git::Commands::*`, `Git::Parsers::*`,
`Git::ExecutionContext::Repository`). They do not run real git.

The collaborators (commands, parsers) are stubbed via `instance_double`. The unit
test asserts:

1. The facade constructs each command class with the injected
   `@execution_context`.
2. Each command's `#call` is invoked with the expected positional and keyword
   arguments (verifying argument pre-processing).
3. For multi-command sequences, the calls happen in the documented order.
4. The parser/result-class is invoked with the command's stdout (when applicable).
5. The facade returns the value its public contract documents.

#### Setup pattern

```ruby
RSpec.describe Git::Repository::Staging do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }
  let(:command_result) { instance_double(Git::CommandLineResult, stdout: '') }
  let(:add_command) { instance_double(Git::Commands::Add) }
  let(:add_result) { command_result }

  before do
    allow(Git::Commands::Add).to receive(:new).with(execution_context).and_return(add_command)
  end

  describe '#add' do
    # ...
  end
end
```

The shared `command_result` `let` provides a default empty-stdout result; each
per-command alias (`add_result`, `branch_list_result`, ...) lets individual
tests override stdout in isolation — e.g.
`let(:add_result) { instance_double(Git::CommandLineResult, stdout: 'fixture output') }`
in a nested `context` — without affecting other tests in the file.

Three rules:

- The subject is an instance of `Git::Repository`, **not** the module itself.
  Modules are mixed into the class; tests must exercise the class to reflect
  real call sites.
- `execution_context` is an `instance_double(Git::ExecutionContext::Repository)`
  — never a `double('ExecutionContext')` and never a real context.
- Each command class is stubbed with `allow(Klass).to receive(:new).with(execution_context).and_return(...)`
  so the facade's command construction (with the right execution context) is
  verified by the stub.

#### Cover these cases

- **Default invocation** — facade called with no arguments (or only required
  positional args) delegates with the documented defaults. Assert the return
  value once per facade method to verify pass-through.
- **Each positional argument variation** — single value, array, nil where
  applicable.
- **Each option the facade exposes** — including aliases, deprecated keys, and
  policy defaults the facade applies (`edit: false`, etc.).
- **Multi-command sequences** — when the facade calls more than one command,
  use `expect ... receive(:call).with(...).ordered` to assert ordering and
  intermediate-result wiring.
- **Parser invocation** — when the facade uses a `Git::Parsers::*` class,
  stub the parser and assert it is called with the command's stdout. Assert the
  facade returns what the parser returned.
- **Raw `CommandLineResult` return** — when the facade's contract is to
  return the command's `Git::CommandLineResult` directly (not `.stdout` and
  not a parser output), assert `eq(<command>_result)` to verify pass-through.
- **Option whitelisting** — when the facade defines a `<METHOD>_ALLOWED_OPTS`
  constant and calls `Git::Repository::Internal.assert_valid_opts!`, test that
  an unknown key raises `ArgumentError` and a known key is forwarded.
- **Deprecation handling** — when the facade rewrites or warns on deprecated
  keys, test that the deprecation warning is emitted and the new key is
  forwarded.

#### Expectations for command invocation

Use the standard rspec-mocks form (no command-specific helper exists for the
facade layer):

```ruby
it 'delegates to Git::Commands::Add#call with the given path' do
  expect(add_command).to receive(:call).with('path/to/file.rb').and_return(add_result)
  described_instance.add('path/to/file.rb')
end
```

For command + parser orchestration (single command whose stdout is fed to a
parser), use `.ordered` to assert the call sequence:

```ruby
it 'lists branches then parses the output' do
  expect(branch_list_command).to(
    receive(:call)
        .with(all: true, format: Git::Parsers::Branch::FORMAT_STRING)
        .and_return(branch_list_result)
        .ordered
  )

  expect(Git::Parsers::Branch).to(
    receive(:parse_list)
        .with(branch_list_result.stdout)
        .and_return(parsed_branches)
        .ordered
  )

  expect(described_instance.branches_all).to eq(parsed_branches)
end
```

For genuinely multi-command orchestration (the facade calls more than one
command), chain `.ordered` across each command's `#call`, wiring intermediate
results through as needed:

```ruby
it 'saves the stash then lists stashes' do
  expect(stash_save_command).to(
    receive(:call).with(message: 'wip').and_return(stash_save_result).ordered
  )

  expect(stash_list_command).to(
    receive(:call).and_return(stash_list_result).ordered
  )

  expect(described_instance.stash_save_and_list(message: 'wip')).to eq(parsed_stashes)
end
```

#### What not to test

- **Command argv building.** That is the command class's contract and is covered
  by `spec/unit/git/commands/<command>_spec.rb`. The facade unit test should
  stub `#call` and assert the keyword arguments the facade passes — not assert
  on the CLI tokens that reach git.
- **Parser internals.** Stub the parser class method and assert the facade calls
  it with the right input. Parser parsing is covered by `spec/unit/git/parsers/`.
- **Real command execution.** Facade unit tests must not exercise
  `Git::ExecutionContext::Repository` for real. Use `instance_double`.
- **Multiple input strings exercising the same code path** — one test per
  argument type is sufficient (string vs. array vs. nil), not one per value.
- **`#initialize` of the facade module.** The module is mixed into
  `Git::Repository`; constructor coverage belongs to `repository_spec.rb`.

#### Unit test grouping

One `describe '#<method_name>'` block per facade method. Inside, use flat
`context` blocks per argument variation. Optional sections at the end (in order)
when present:

- `context 'option whitelisting'` —
  `Git::Repository::Internal.assert_valid_opts!` raises on unknown keys and
  forwards known keys unchanged (no `slice` — the assertion is the only
  enforcement mechanism)
- `context 'deprecation handling'` — `Git::Deprecation.warn` assertions and
  key-rewrite tests
- `context 'input validation'` — `ArgumentError` raised by the facade itself
  (not by the command)

The exit code section that command specs use does **not** apply to facade specs
— exit-status handling is the command's concern; the facade's tests assume the
command either returns a result or raises.

### Integration tests

Facade integration tests run real git in a temp repository and verify the
**end-to-end Ruby return value** of the facade method.

Each integration spec file tests **one facade module** (one
`spec/integration/git/repository/<topic>_spec.rb`). Inside, group by facade
method.

#### When to write integration tests

Facade integration tests are the **exception, not the default**. Most facade
behavior is already covered end-to-end by the underlying command's own
integration tests; re-running real git through the facade re-exercises the
same code path without adding signal.

Write a facade integration test only when the facade adds behavior that is
**not** exercised by any single command's integration tests:

- **Multi-command orchestration** — the facade calls more than one command
  and the integration test confirms the documented end-to-end value emerges
  from the sequence against real git.
- **Facade-owned post-processing of real git output** — the facade itself
  (not the command) parses, aggregates, or transforms raw command output
  before returning. A real git invocation proves the post-processing handles
  actual output rather than a mocked string.

#### When to skip integration tests

Skip for everything else, including:

- **One-line delegators** that pass arguments through to a single command
  with no pre/post-processing (e.g. `Git::Repository::Staging#add`,
  `#reset`).
- **Single-command facade methods that delegate parsing to a parser or
  result-class factory** — the command's own integration test already
  exercises that command + parser against real git.
- **Argument pre-processing** (path normalization, deprecation key rewrites,
  option whitelisting) — these are pure-Ruby transforms with no git
  involvement; unit tests prove them and real git adds no signal.
- **Error-path assertions** (`raise_error(Git::FailedError)`) — these test
  the command's error wrapping, not the facade.

When skipping, document why with a code comment in the spec file or a `#`
header in `spec/integration/git/repository/<topic>_spec.rb` explaining which
methods are covered exclusively by command integration tests.

#### Integration test grouping

Mirror the [Command Test Conventions](../command-test-conventions/SKILL.md)
integration grouping. Use a multi-command or post-processing facade method —
single-command delegators do not warrant integration tests (see [When to skip
integration tests](#when-to-skip-integration-tests)):

The shared context (e.g. `'in an empty repository'`) provides `repo` and
`repo_dir` helpers. Facade integration specs must override `execution_context`
to a `Git::ExecutionContext::Repository` (the shared context's default is
`repo.lib`, a `Git::Lib`). Stage any required repository state in a `before`
block inside the spec itself.

```ruby
RSpec.describe Git::Repository::Stashing, :integration do
  include_context 'in an empty repository' # provides repo and repo_dir helpers

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', 'initial')
    repo.add('README.md')
    repo.commit('Initial commit')
    write_file('README.md', 'work in progress')
    repo.add('README.md')
  end

  describe '#stash_save_and_list' do
    it 'returns the new stash entry after saving' do
      result = described_instance.stash_save_and_list(message: 'wip')
      expect(result).to all(be_a(Git::Stash))
      expect(result.first.message).to include('wip')
    end
  end
end
```

One `context 'when the command succeeds'` block (or just `it` blocks directly
under `describe`) per facade method, with one or more variations that exercise
the orchestration sequence or post-processing. Do **not** add a `context 'when
the command fails'` block — error wrapping is the command's concern and is
covered by command integration tests.

#### What integration tests assert

- The Ruby return value's **structure and key fields** (e.g., classes,
  required attributes, presence of expected entries).
- Multi-command orchestration produces the documented end-to-end value, not
  intermediate command results.

#### What integration tests do not assert

- Specific CLI tokens reaching git (covered by command unit tests).
- Specific git output formatting (testing git, not the facade).
- Edge cases that vary between git versions in immaterial ways. Anchor
  assertions on stable inputs (paths, ref names) the test controls — not on git
  message phrasing.

## Workflow

1. Load the [RSpec Unit Testing
   Standards](../rspec-unit-testing-standards/SKILL.md) skill (line 1 through
   EOF).
2. Read the spec file(s) under review and the corresponding facade module
   (`lib/git/repository/<topic>.rb`) plus the underlying `Git::Commands::*` and
   `Git::Parsers::*` files the facade calls.
3. Audit each spec against the rules in [Reference](#reference), checking unit
   and integration tests separately.
4. Produce the [Output](#output).

## Output

### When writing new facade tests

Produce the unit and (when applicable) integration spec files following the
patterns above. Then self-verify by running every checklist item in the
[Reference](#reference) section against your output.

### When reviewing existing facade tests

Provide:

1. issue table

   | Check | Status | Issue |
   | --- | --- | --- |

2. corrected snippets for failing checks

3. **Self-verify before concluding** — re-run the reference against your proposed
   snippets until all checks pass.

> **Branch workflow:** Implement any new or updated tests on a feature branch.
> Never commit or push directly to `main` — open a pull request when changes are
> ready to merge.
