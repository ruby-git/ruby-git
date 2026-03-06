---
name: rspec-unit-testing-standards
description: "Defines RSpec unit testing rules for this project covering structure, naming, setup patterns, stubbing, doubles, coverage, and test reliability. Use when writing, reviewing, or auditing RSpec specs under spec/unit/."
---

# RSpec Unit Testing Standards

These rules govern the structure, organization, and quality of all RSpec unit tests
in this project. Apply them when writing new tests, reviewing existing ones, or
auditing test quality.

## Priority Levels

Use RFC-style priority words to reduce ambiguity for AI behavior:

- **MUST**: mandatory; do not violate without a documented exception
- **SHOULD**: preferred default; may be overridden when a clearer test requires it

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Structure](#structure)
  - [Rule 1 (MUST): One top-level `RSpec.describe` block per class](#rule-1-must-one-top-level-rspecdescribe-block-per-class)
  - [Rule 2 (MUST): One `describe` block per public method](#rule-2-must-one-describe-block-per-public-method)
  - [Rule 3 (SHOULD): Add `# frozen_string_literal: true` at the top of every spec file](#rule-3-should-add--frozen_string_literal-true-at-the-top-of-every-spec-file)
  - [Rule 4 (MUST): Spec file location must mirror source file location](#rule-4-must-spec-file-location-must-mirror-source-file-location)
  - [Rule 5 (MUST): `require 'spec_helper'` and only the file(s) under test](#rule-5-must-require-spec_helper-and-only-the-files-under-test)
  - [Rule 6 (MUST): Test only through the public interface](#rule-6-must-test-only-through-the-public-interface)
- [Naming and Organization](#naming-and-organization)
  - [Rule 7 (SHOULD): Use `described_class`](#rule-7-should-use-described_class)
  - [Rule 8 (MUST): `context` blocks describe conditions](#rule-8-must-context-blocks-describe-conditions)
  - [Rule 9 (MUST): `it` blocks assert one concept, and the description must match the assertion](#rule-9-must-it-blocks-assert-one-concept-and-the-description-must-match-the-assertion)
  - [Rule 10 (SHOULD): Use the standard nesting pattern](#rule-10-should-use-the-standard-nesting-pattern)
- [Setup and Subject](#setup-and-subject)
  - [Rule 11 (SHOULD): Use a named `subject` at the top of each `describe #method` block](#rule-11-should-use-a-named-subject-at-the-top-of-each-describe-method-block)
  - [Rule 12 (SHOULD): Immediately follow `subject` with `let` defaults](#rule-12-should-immediately-follow-subject-with-let-defaults)
  - [Rule 13 (SHOULD): Define `let(:described_instance)` at the top level when multiple `describe` blocks share the same instance](#rule-13-should-define-letdescribed_instance-at-the-top-level-when-multiple-describe-blocks-share-the-same-instance)
  - [Rule 14 (SHOULD): Prefer `subject` to represent the method call result](#rule-14-should-prefer-subject-to-represent-the-method-call-result)
  - [Rule 15 (SHOULD): Do not use `subject` when testing side effects](#rule-15-should-do-not-use-subject-when-testing-side-effects)
  - [Rule 16 (MUST): Use `let`/`let!` for inputs and shared setup; use `before` only for side effects](#rule-16-must-use-letlet-for-inputs-and-shared-setup-use-before-only-for-side-effects)
  - [Rule 17 (SHOULD): Keep test setup local; extract only for substantial cross-file reuse](#rule-17-should-keep-test-setup-local-extract-only-for-substantial-cross-file-reuse)
- [Doubles and Stubbing](#doubles-and-stubbing)
  - [Rule 18 (MUST): Stub calls to non-trivial external objects](#rule-18-must-stub-calls-to-non-trivial-external-objects)
  - [Rule 19 (MUST): Use `allow` for incidental stubs; use `expect` for behavioral assertions](#rule-19-must-use-allow-for-incidental-stubs-use-expect-for-behavioral-assertions)
  - [Rule 20 (MUST): Use verifying doubles](#rule-20-must-use-verifying-doubles)
- [Coverage](#coverage)
  - [Rule 21 (MUST): Achieve 100% branch-level coverage](#rule-21-must-achieve-100-branch-level-coverage)
  - [Rule 22 (MUST): Error assertions must specify both the error class and a message pattern](#rule-22-must-error-assertions-must-specify-both-the-error-class-and-a-message-pattern)
  - [Rule 23 (MUST): Test edge cases within the relevant `context` block](#rule-23-must-test-edge-cases-within-the-relevant-context-block)
  - [Rule 24 (MUST): Assert observable behavior, not implementation details](#rule-24-must-assert-observable-behavior-not-implementation-details)
    - [Anti-pattern: structural identity and constant-existence tests](#anti-pattern-structural-identity-and-constant-existence-tests)
- [Test Reliability](#test-reliability)
  - [Rule 25 (MUST): Keep unit tests deterministic](#rule-25-must-keep-unit-tests-deterministic)
  - [Rule 26 (MUST): Isolate and restore global/process state](#rule-26-must-isolate-and-restore-globalprocess-state)
  - [Rule 27 (MUST): Tests must be order-independent](#rule-27-must-tests-must-be-order-independent)
  - [Rule 28 (MUST): Avoid `allow_any_instance_of` and `receive_message_chain`](#rule-28-must-avoid-allow_any_instance_of-and-receive_message_chain)
- [Verification](#verification)
- [Output](#output)

## How to use this skill

These rules apply to all RSpec unit specs under `spec/unit/`. Extend this baseline
with domain-specific rules from related skills as needed.

Adoption and enforcement notes:

- Apply these rules as hard requirements for new and modified unit specs.
- Legacy specs may violate some rules; treat those as incremental cleanup work.
- Branch and line coverage are both reported by SimpleCov in this repository.
- `coverage_threshold: 100` is configured, but `fail_on_low_coverage` is currently
  `false`; enforce Rule 21 during review by checking the coverage report until
  strict failure is enabled.

## Related skills

- [Review Command Tests](../review-command-tests/SKILL.md) — additional conventions
  for `Git::Commands::*` unit and integration specs, built on top of these rules
- [Development Workflow](../development-workflow/SKILL.md) — TDD process that governs
  when and how tests are written
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — final quality gate that
  verifies test compliance before opening a pull request
- [Pull Request Review](../pull-request-review/SKILL.md) — PR review process that
  checks test quality against these standards

## Structure

### Rule 1 (MUST): One top-level `RSpec.describe` block per class

Use the class constant directly:

```ruby
RSpec.describe Git::CommandLine::Capturing do
```

Never use a string in place of the constant, even for backward-compat aliases:

```ruby
# Bad — string describe; described_class is unavailable, coverage tooling may not
# map the spec to the source file, and typos go undetected at load time.
RSpec.describe 'Git::CommandLineResult' do
```

If the constant is a backward-compat alias (e.g. `Git::CommandLineResult =
Git::CommandLine::Result`), use the alias constant itself as the describe argument —
the alias is a real Ruby constant and loads without issue. The test content should
verify that the alias points to the correct target using object identity (`be`),
which would not be caught implicitly by a `NameError` on the canonical constant:

```ruby
RSpec.describe Git::CommandLineResult do
  it 'is a backward-compatible alias for Git::CommandLine::Result' do
    expect(described_class).to be(Git::CommandLine::Result)
  end
end
```

Do not test `#initialize` or other behavior here — that is already covered by the spec for the canonical class.

### Rule 2 (MUST): One `describe` block per public method

Use `#method_name` for instance methods and `.method_name` for class methods.
Include `#initialize`:

```ruby
describe '#call' do ...
describe '.build' do ...
describe '#initialize' do ...
```

**Inherited `#initialize` in concrete subclasses (SHOULD):** If a class is
directly instantiated by callers but does not override `#initialize`, its spec
SHOULD still include a `describe '#initialize'` block using the minimal
`have_attributes` form (see Rule 13). This serves two purposes:

1. The spec is self-contained documentation of the constructor signature — a reader
   does not need to consult the ancestor's spec to know what arguments the class
   accepts or what attributes it exposes.
2. It guards against an accidental `def initialize` override in the subclass that
   silently drops or misroutes an argument, which the ancestor's spec would not
   catch.

Omit the inherited `#initialize` block only for abstract or internal classes that
callers never instantiate directly — those are sufficiently covered by the
ancestor's spec alone.

### Rule 3 (SHOULD): Add `# frozen_string_literal: true` at the top of every spec file

Matches project-wide convention and catches accidental string mutation.

### Rule 4 (MUST): Spec file location must mirror source file location

`lib/git/foo/bar.rb` maps to `spec/unit/git/foo/bar_spec.rb`. Deviating from this
makes specs hard to find and breaks coverage mapping.

### Rule 5 (MUST): `require 'spec_helper'` and only the file(s) under test

Every unit spec MUST start with `require 'spec_helper'`, then require only the
Ruby file(s) it directly tests. Avoid requiring unrelated libraries or classes —
doing so creates false coupling where a rename or move breaks specs that don't even
test that class.

### Rule 6 (MUST): Test only through the public interface

Never call private methods directly in tests. If private logic is hard to reach
through the public interface, stop and propose one of these remedies to the user:

- **Extract a class** — move the logic to a new class with its own public interface.
- **Make the method public** — promote it if it is genuinely part of the contract.
- **Redesign the public API** — split the public method into smaller public steps.

Never use `send`, `instance_variable_get`, or `__send__` to reach private state.

## Naming and Organization

### Rule 7 (SHOULD): Use `described_class`

Use `described_class` instead of repeating the class name inside the describe block:

```ruby
subject(:result) { described_class.new(args).call }
```

### Rule 8 (MUST): `context` blocks describe conditions

Use prefixes "when", "with", or "without". Nest them under the relevant `describe`
block for different option combinations, input states, or environmental conditions:

```ruby
context 'when the command fails' do ...
context 'with the :force option' do ...
context 'without a timeout' do ...
```

### Rule 9 (MUST): `it` blocks assert one concept, and the description must match the assertion

Each example tests a single logical behavior. A test described as "raises
ArgumentError when options conflict" must verify both the error class and a message
pattern — not just that any error was raised. Multiple `expect` calls are acceptable
if they all verify the same behavior — that is, a single application code change
would cause them all to fail together. For example, asserting the type, status, and
contents of a single return value is one concept ("the result carries the right
data"), not five separate behaviors:

```ruby
# Good — all assertions verify one concept: the returned result is correct
it 'returns a result with the failure details' do
  result = described_instance.run('status', raise_on_failure: false)
  expect(result).to be_a(Git::CommandLineResult)
  expect(result.status.success?).to be false
  expect(result.status.exitstatus).to eq(1)
  expect(result.stdout).to eq("modified: foo.rb\n")
  expect(result.stderr).to eq('fatal: not a git repository')
end
```

### Rule 10 (SHOULD): Use the standard nesting pattern

```
describe #method
  context "when X"
    context "with Y option"
      it "does Z"
```

> **Exception:** Simple methods with a single execution path and no meaningful input
> variations do not need `context` blocks. A `describe #method` block containing
> `it` directly is fine when there are no conditions worth naming.

## Setup and Subject

### Rule 11 (SHOULD): Use a named `subject` at the top of each `describe #method` block

Name the subject after what is returned. For simple cases, inline construction is
fine:

```ruby
subject(:result) { described_class.new(command, options).call }
```

When construction is complex or shared across multiple `describe` blocks, separate
construction into a `let` and reference it from `subject` (see Rule 14). Naming
the subject allows both `is_expected.to` one-liners and `expect(result).to` in
more descriptive examples. Do not override `subject` in nested `context` blocks
— vary behavior by overriding `let` inputs instead.

### Rule 12 (SHOULD): Immediately follow `subject` with `let` defaults

`subject` must be the first declaration in a `describe` block. Do not place `let`
declarations above `subject` — doing so buries the call under test and inverts the
natural reading order (what is being tested → what inputs it receives).

Define `let` defaults for all inputs and arguments immediately after `subject`.
Nested `context` blocks override only the `let` values relevant to that scenario —
leave everything else at its default:

```ruby
# Good — subject first, then let defaults
describe '#call' do
  subject(:result) { described_class.new(command, options).call }

  let(:command) { ['git', 'status'] }
  let(:options) { {} }

  context 'when options include timeout' do
    let(:options) { { timeout: 10 } }
    it { is_expected.to ... }
  end
end

# Bad — let declarations above subject obscure what is under test
describe '#call' do
  let(:command) { ['git', 'status'] }
  let(:options) { {} }
  subject(:result) { described_class.new(command, options).call }
end
```

### Rule 13 (SHOULD): Define `let(:described_instance)` at the top level when multiple `describe` blocks share the same instance

When two or more `describe #method` blocks instantiate the class identically, define
a single `let(:described_instance)` at the top of the `RSpec.describe` block instead
of repeating construction in every `subject`. Each `describe` block then defines
`subject` as the method call result, referencing `described_instance`:

```ruby
RSpec.describe Git::CommandLine do
  let(:command)            { ['git', 'status'] }
  let(:options)            { {} }
  let(:described_instance) { described_class.new(command, options) }

  describe '#call' do
    subject(:result) { described_instance.call }
    ...
  end

  describe '#to_s' do
    subject(:result) { described_instance.to_s }
    ...
  end
end
```

Guidelines:

- **Use `let`, not `subject`** — avoids making it the implicit assertion target.
- **Reference only `let`-defined arguments** — no inline literals; nested contexts
  must be able to override individual inputs.
- **Omit when construction is trivial** or varies between methods.
- For `#initialize`, alias it: `subject(:instance) { described_instance }`.
- **When `#initialize` only stores arguments via `attr_reader`, use a single
  `have_attributes` example** — separate `it` blocks for each attribute add noise
  without isolation benefit when there is no conditional logic to branch on:

  ```ruby
  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments' do
      expect(instance).to have_attributes(
        env: env,
        binary_path: binary_path,
        global_opts: global_opts,
        logger: logger
      )
    end
  end
  ```

  Use separate `it` blocks only when `#initialize` performs validation or
  conditional logic — each branch then deserves its own example.

### Rule 14 (SHOULD): Prefer `subject` to represent the method call result

Prefer `subject` as the return value of the public method under test. For simple
cases, inline construction is fine (see Rule 11). When construction is complex or
reused across multiple `describe` blocks, separate construction into a `let` so
that nested `context` blocks can override individual inputs without duplicating
the whole call:

```ruby
# Good — complex construction is separated so inputs can be overridden
let(:instance) { described_class.new(complex, args, here) }
subject(:result) { instance.call }

# Avoid when construction is complex — nested contexts cannot vary individual args
subject(:result) { described_class.new(complex, args, here).call }
```

> **Exception:** `#initialize` tests — the constructed object *is* the return value,
> so `subject` should be the instance (see Rule 13 aliasing guideline).

### Rule 15 (SHOULD): Do not use `subject` when testing side effects

Use `change` and `raise_error` matchers instead of manual before/after assertions:

```ruby
# Good
expect { action }.to change(collection, :size).by(1)
expect { action }.to change(obj, :attr).from('old').to('new')

# Bad
before_count = collection.size
action
expect(collection.size).to eq(before_count + 1)
```

### Rule 16 (MUST): Use `let`/`let!` for inputs and shared setup; use `before` only for side effects

Use `let` for values that are referenced directly in examples. Use `let!` when a
value must exist before the example runs but is not referenced directly (e.g., a
precondition that other code depends on). Use `before` only for imperative side
effects (e.g., creating files, setting env vars). Avoid instance variables set in
`before` blocks.

### Rule 17 (SHOULD): Keep test setup local; extract only for substantial cross-file reuse

`shared_context` is appropriate when identical multi-step environment setup must be
shared across multiple spec files and duplicating it inline would be substantial.
Do not use `shared_context` within a single spec file — use the `let` hierarchy
instead. A unit test that needs a `shared_context` to run is almost certainly an
integration test; move it to `spec/integration/`.

The same restraint applies to shared helper methods. Do not extract a helper to a
support file solely because two spec files contain methods with similar structure.
If the helpers construct different doubles, mock different classes, or carry
different default attributes, the similarity is incidental — not meaningful
duplication. Each spec file should be self-contained and readable without jumping
to external helpers. Extract only when the helpers are truly identical and used
across three or more spec files.

Defining shared contexts:

- Define in `spec/support/contexts/`, named after the context string.
- Use only `let`, `let!`, and `before`/`after` — no `subject`, doubles, or
  `described_instance`.
- Reference only `let`-defined values; never inline literals.

Consuming: always use explicit `include_context 'name'` — never metadata-based
auto-inclusion.

## Doubles and Stubbing

### Rule 18 (MUST): Stub calls to non-trivial external objects

Stub anything whose real involvement would make the test cross a unit boundary
(e.g., `ProcessExecuter`, file system, network). Do not stub simple value types
like `String`, `Integer`, or `Array`. The guiding question: would running the real
thing make this test not a unit test?

> **Exception:** Simple value objects with no IO (e.g., `Git::CommandLineResult`)
> can be used directly if doing so keeps the test a unit test.

### Rule 19 (MUST): Use `allow` for incidental stubs; use `expect` for behavioral assertions

Reserve `expect(...).to receive(...)` for cases where the call itself is the
behavior under test. Use `allow` for everything else — overusing `expect` stubs
creates over-specified tests that break on irrelevant refactors:

```ruby
# Good — incidental stub; test verifies the return value
allow(executer).to receive(:run).and_return(result)
expect(subject).to eq(expected)

# Good — the call itself is what's being verified
expect(executer).to receive(:run).with('git', 'status')
subject

# Good — the call is behavioral and arguments require destructuring;
# use a block with nested expects when .with() cannot cleanly express
# the assertion (e.g., complex kwargs mixed with positional args)
expect(executer).to receive(:run) do |*args, **opts|
  expect(opts[:timeout_after]).to eq(5)
  mock_result
end
subject
```

### Rule 20 (MUST): Use verifying doubles

Use `instance_double` / `class_double` rather than plain `double`:

```ruby
# Good — ProcessExecuter.run is a class method; use class_double
let(:process_executer) { class_double(ProcessExecuter) }

# Bad
let(:process_executer) { double('ProcessExecuter') }
```

> **Exceptions:**
>
> - Plain `double` is acceptable when the class being stubbed cannot be
>   loaded in the test environment (e.g., a C extension or optional dependency
>   not available in CI).
> - Plain `double` is acceptable for duck-type collaborators where there is no
>   single concrete class to verify against (e.g., `execution_context` in
>   command specs implements a duck-type interface, not one specific class).
> - Plain `double` is acceptable when the class delegates methods via
>   `SimpleDelegator`, `Delegator`, or `method_missing`.  `instance_double`
>   only verifies methods that `method_defined?` returns `true` for, so
>   delegated methods (e.g., `signaled?`, `exitstatus` forwarded from
>   `Process::Status`) would be incorrectly rejected.
>
> In all cases, document the reason with an inline comment so the use of
> `double` is not mistaken for carelessness:
>
> ```ruby
> # Duck-type collaborator: command specs depend on the #command_capturing
> # interface, not a single concrete ExecutionContext class.
> let(:execution_context) { double('ExecutionContext') }
>
> # Plain double: ProcessExecuter result classes delegate to Process::Status
> # via SimpleDelegator/method_missing, so instance_double cannot verify the
> # delegated interface (signaled?, exitstatus, etc.).
> double('ProcessExecuter::ResultWithCapture', success?: true, signaled?: false)
> ```

## Coverage

### Rule 21 (MUST): Achieve 100% branch-level coverage

Every conditional path through the public interface must be exercised by at least
one example. If a branch cannot be reached through the public interface, that is a
design smell.

> **Exception:** Defensive guards that require breaking OS-level invariants to reach
> (e.g., `raise "unreachable"` that would require triggering out-of-memory) may be
> excluded. Mark them explicitly with `# :nocov:` and a brief comment explaining why
> — never leave branches silently uncovered.

### Rule 22 (MUST): Error assertions must specify both the error class and a message pattern

`raise_error(ErrorClass)` alone is underspecified — any instance of that class
satisfies it regardless of cause. This applies equally when using the block form
to verify properties of the raised error object: the block does not substitute for
a message check, and RSpec allows both together.

```ruby
# Good — class + message pattern only
expect { action }.to raise_error(ArgumentError, /cannot combine :force and :dry_run/)

# Good — class + message pattern + block to verify error properties
expect { action }.to raise_error(Git::FailedError, /git.*status/) do |error|
  expect(error.result.status.exitstatus).to eq(1)
end

# Bad — passes for any ArgumentError, even unrelated ones
expect { action }.to raise_error(ArgumentError)

# Bad — block form is not an exception to the message requirement;
# still passes for any Git::FailedError regardless of cause
expect { action }.to raise_error(Git::FailedError) do |error|
  expect(error.result.status.exitstatus).to eq(1)
end
```

> **Exception:** When the error message is produced by an external library or by git
> itself and is likely to vary by version, use the loosest pattern that still
> distinguishes this error from unrelated ones (e.g., `/invalid ref/i`). Never omit
> the message check entirely.

### Rule 23 (MUST): Test edge cases within the relevant `context` block

`nil`, empty collections, and boundary values belong alongside the normal cases for
the same method and condition — not in a separate "edge cases" block at the bottom.

### Rule 24 (MUST): Assert observable behavior, not implementation details

Every `expect` must verify a meaningful outcome — a return value, a raised error,
a state change, or a message sent to a collaborator. Do not write assertions that
merely confirm the code runs without error or that mirror the implementation:

```ruby
# Good — asserts the meaningful return value
expect(subject).to eq('v2.43.0')

# Bad — passes for any non-nil return, verifies nothing useful
expect(subject).not_to be_nil
```

**Decision test — independent failure mode:** Before writing or approving an
assertion, ask: "What application code change would cause *only this test* to fail?"
If the answer is "nothing — every other test would also fail first," the assertion
is redundant and should be removed.

#### Anti-pattern: structural identity and constant-existence tests

Do not write tests that only verify a constant exists, that a `require` loaded
successfully, or that a namespace is a `Module` vs a `Class`:

```ruby
# Bad — proves nothing about behavior; any real test that uses the class
# would fail with NameError first if the constant were missing
it 'exposes Capturing' do
  expect(Git::CommandLine::Capturing).to be_a(Class)
end

# Bad — structural choice, not observable behavior from a caller's perspective
it 'is a module (not a class)' do
  expect(described_class).to be_a(Module)
end
```

Constant presence is proven implicitly by every test that instantiates or calls
the class. These tests add no coverage of behavior and should not be written or
approved in review.

## Test Reliability

### Rule 25 (MUST): Keep unit tests deterministic

Do not depend on real time, randomness, sleep-based timing, or external process
timing. Stub or freeze `Time.now`, `Process.clock_gettime`, `SecureRandom`, and
`rand` so results are repeatable. Never use `sleep` in unit tests.

### Rule 26 (MUST): Isolate and restore global/process state

Unit tests must not leak state across examples. If a test modifies process or global
state (for example `ENV`, current working directory, locale, or global config),
restore that state before the example ends.

### Rule 27 (MUST): Tests must be order-independent

Every unit test must pass when run alone and when run in randomized order. Do not
rely on side effects from other examples, files, or execution order.

### Rule 28 (MUST): Avoid `allow_any_instance_of` and `receive_message_chain`

Do not use `allow_any_instance_of` or `receive_message_chain` in unit tests. They
hide object boundaries and create brittle tests.

> **Exception:** Allowed only when there is no practical seam and refactoring is out
> of scope for the current change. If used, add an inline comment explaining why and
> prefer introducing a seam in a follow-up change.

## Verification

After writing or modifying tests, verify compliance before finishing:

1. **Run the specs:** `bundle exec rspec spec/unit/path/to_spec.rb`
2. **Check branch coverage** meets 100% (Rule 21) — open `coverage/index.html` and
   confirm no uncovered branches in the class under test.
3. **Re-check MUST rules.** Scan the spec against every MUST rule. Fix violations.
4. **Run in random order** (Rule 27): `bundle exec rspec spec/unit/path/to_spec.rb --order rand`

Repeat until all checks pass.

## Output

**When writing new tests**, produce the spec file and run through the Verification
checklist above. No additional structured output is required.

**When reviewing or auditing** existing tests, produce the following:

1. A per-rule compliance table:

   | Rule | Status | Issue |
   |------|--------|-------|

   Use **Pass**, **Fail**, or **N/A** for each rule.

2. A summary of required fixes (MUST-level violations).

3. A list of suggested improvements (SHOULD-level deviations), ordered by impact.
