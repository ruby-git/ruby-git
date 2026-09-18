---
name: rspec-integration-testing-standards
description: "Defines RSpec integration testing rules for this project covering structure, real git execution, determinism, error assertions, setup commands, portability, and spec location. Use when writing, reviewing, or auditing RSpec specs under spec/integration/, including command, facade, parser, and cross-cutting specs."
---

# RSpec Integration Testing Standards

These rules govern every spec file under `spec/integration/`: command specs
(`spec/integration/git/commands/`), facade specs
(`spec/integration/git/repository/`), parser specs
(`spec/integration/git/parsers/`), and the specs directly under
`spec/integration/git/`. That last group holds specs for top-level source files
(`git_spec.rb`, `command_line_spec.rb`, `git_configure_spec.rb`, `url_spec.rb`)
and the cross-cutting specs with no single source counterpart (`load_spec.rb`,
`non_ascii_regex_matching_spec.rb`, `thread_safety_spec.rb`). Apply them when
writing new integration specs, reviewing existing ones, or auditing test quality.

This skill is standalone. It does not extend the
[RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md); load this
file alone when working in `spec/integration/`. The rules in
[Rules shared with unit specs](#rules-shared-with-unit-specs) restate the unit
skill's structure, naming, and reliability rules in integration terms; where an
integration spec needs an exception, the rule says so. The rule numbers are
independent of the unit skill's numbers; do not translate between them.

## Priority Levels

Use RFC-style priority words to reduce ambiguity for AI behavior:

- **MUST**: mandatory; do not violate without a documented exception
- **SHOULD**: preferred default; may be overridden when a clearer test requires it

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Rules shared with unit specs](#rules-shared-with-unit-specs)
  - [Rule 1 (MUST): One top-level `RSpec.describe` block per class](#rule-1-must-one-top-level-rspecdescribe-block-per-class)
  - [Rule 2 (MUST): One `describe` block per public method; `context` blocks describe conditions](#rule-2-must-one-describe-block-per-public-method-context-blocks-describe-conditions)
  - [Rule 3 (SHOULD): Add `# frozen_string_literal: true` at the top of every spec file](#rule-3-should-add--frozen_string_literal-true-at-the-top-of-every-spec-file)
  - [Rule 4 (MUST): `require 'spec_helper'`, then only the stdlib the spec itself uses](#rule-4-must-require-spec_helper-then-only-the-stdlib-the-spec-itself-uses)
  - [Rule 5 (SHOULD): Use `described_class`](#rule-5-should-use-described_class)
  - [Rule 6 (SHOULD): Named `subject` first, then `let` defaults; never override `subject` in a nested `context`](#rule-6-should-named-subject-first-then-let-defaults-never-override-subject-in-a-nested-context)
  - [Rule 7 (MUST): Use `let` for values and `before` for side effects](#rule-7-must-use-let-for-values-and-before-for-side-effects)
  - [Rule 8 (MUST): `it` blocks assert one concept, and the description must match the assertion](#rule-8-must-it-blocks-assert-one-concept-and-the-description-must-match-the-assertion)
  - [Rule 9 (MUST): Error assertions must specify both the error class and a message pattern](#rule-9-must-error-assertions-must-specify-both-the-error-class-and-a-message-pattern)
  - [Rule 10 (MUST): No assertions that only prove the code ran](#rule-10-must-no-assertions-that-only-prove-the-code-ran)
  - [Rule 11 (SHOULD): Use `change` matchers instead of manual before/after assertions](#rule-11-should-use-change-matchers-instead-of-manual-beforeafter-assertions)
  - [Rule 12 (MUST): Avoid `allow_any_instance_of` and `receive_message_chain`](#rule-12-must-avoid-allow_any_instance_of-and-receive_message_chain)
- [Rules specific to integration specs](#rules-specific-to-integration-specs)
  - [Rule 13 (MUST): Run real git; do not stub collaborators](#rule-13-must-run-real-git-do-not-stub-collaborators)
  - [Rule 14 (MUST): Be independent of the host machine](#rule-14-must-be-independent-of-the-host-machine)
  - [Rule 15 (MUST): Anchor error message patterns on something the test controls](#rule-15-must-anchor-error-message-patterns-on-something-the-test-controls)
  - [Rule 16 (MUST): Assert the value the test set up, not the shape of git's output](#rule-16-must-assert-the-value-the-test-set-up-not-the-shape-of-gits-output)
  - [Rule 17 (MUST): Each example proves one assumption about real git](#rule-17-must-each-example-proves-one-assumption-about-real-git)
  - [Rule 18 (MUST): Run setup git commands through `execution_context.command_capturing` or `repo`](#rule-18-must-run-setup-git-commands-through-execution_contextcommand_capturing-or-repo)
  - [Rule 19 (MUST): Build paths cross-platform](#rule-19-must-build-paths-cross-platform)
  - [Rule 20 (MUST): Scope or restore global state](#rule-20-must-scope-or-restore-global-state)
  - [Rule 21 (MUST): Spec location mirrors the source file; cross-cutting specs carry a header comment](#rule-21-must-spec-location-mirrors-the-source-file-cross-cutting-specs-carry-a-header-comment)
- [Directory-specific rules](#directory-specific-rules)
- [Verification](#verification)
- [Output](#output)

## How to use this skill

These rules apply to every RSpec spec under `spec/integration/`. Load this file
alone for the baseline; load the command or facade convention skill on top of it
only for the directory it covers (see
[Directory-specific rules](#directory-specific-rules)).

Adoption and enforcement notes:

- Apply these rules as hard requirements for new and modified integration specs.
- Legacy specs may violate some rules; treat those as incremental cleanup work.
- Coverage is not measured for integration specs (`rake spec:integration` runs with
  SimpleCov disabled). No rule here is a build gate; all are review checks.

## Related skills

- [Command Test Conventions](../command-test-conventions/SKILL.md) — grouping,
  the one-error-test-per-command requirement, and `unless_git` guards for
  `spec/integration/git/commands/`
- [Facade Test Conventions](../facade-test-conventions/SKILL.md) — when a facade
  method gets an integration spec at all, and grouping for
  `spec/integration/git/repository/`
- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — the
  sibling skill for `spec/unit/`; Rules 1–12 below restate its shared rules
- [Development Workflow](../development-workflow/SKILL.md) — TDD process that
  governs when and how tests are written
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — final quality gate that
  verifies test compliance before opening a pull request
- [Pull Request Review](../pull-request-review/SKILL.md) — PR review process that
  checks test quality against these standards

## Rules shared with unit specs

These rules are the same for unit and integration specs. They are stated here in
full so that this file is the only one an integration spec needs.

### Rule 1 (MUST): One top-level `RSpec.describe` block per class

Use the class or module constant directly, never a string:

```ruby
RSpec.describe Git::Commands::Add, :integration do
```

> **Exception:** A cross-cutting spec whose subject is not a constant (for example
> `load_spec.rb`, which loads the gem in a child process) may describe a string.
> It still needs the header comment Rule 21 requires, stating what the spec covers.

### Rule 2 (MUST): One `describe` block per public method; `context` blocks describe conditions

Use `#method_name` for instance methods and `.method_name` for class methods.
Nest `context` blocks under the relevant `describe`, prefixed with "when", "with",
or "without":

```ruby
describe '#call' do
  context 'when the command succeeds' do ...
  context 'with the :force option' do ...
  context 'without a remote' do ...
```

Do not use `describe` for a condition. `describe 'when the command succeeds'` is
a `context`.

### Rule 3 (SHOULD): Add `# frozen_string_literal: true` at the top of every spec file

Matches project-wide convention and catches accidental string mutation.

### Rule 4 (MUST): `require 'spec_helper'`, then only the stdlib the spec itself uses

Every spec starts with `require 'spec_helper'`. The helper loads the whole gem
(`require 'git'`) together with `tmpdir`, `fileutils`, and `English`, so nothing
under `lib/` needs a further require. A `require 'git/...'` line for the file
under test is permitted as documentation and has no load effect. Requiring any
other gem file is a violation; `Git::ExecutionContext::Global`, which a
repository-less command such as clone or init builds, is already loaded.

Any other stdlib the spec body uses (`securerandom`, `tempfile`, `open3`,
`rbconfig`, `zlib`) is required by the spec itself, after `spec_helper`. A spec
never relies on another spec or support file having loaded it.

### Rule 5 (SHOULD): Use `described_class`

Use `described_class` instead of repeating the class name inside the describe
block:

```ruby
subject(:command) { described_class.new(execution_context) }
```

Facade specs are the exception. The described constant is a mixin
(`Git::Repository::Branching`) that cannot be instantiated, so a facade spec
builds its receiver as
`let(:described_instance) { Git::Repository.new(execution_context: execution_context) }`
and uses that name throughout. Do not flag it.

### Rule 6 (SHOULD): Named `subject` first, then `let` defaults; never override `subject` in a nested `context`

`subject` is the first declaration in a `describe #method` block, named after
what it returns. `let` defaults for every input follow immediately. Nested
`context` blocks vary behavior by overriding `let` values, never by redefining
`subject`.

### Rule 7 (MUST): Use `let` for values and `before` for side effects

Use `let` for values examples reference directly, `let!` for a value that must
exist before the example runs but is not referenced, and `before` only for
imperative side effects (writing files, committing, setting env vars). Do not use
`before(:all)` or instance variables in spec files.

### Rule 8 (MUST): `it` blocks assert one concept, and the description must match the assertion

Each example tests a single logical behavior. Multiple `expect` calls are
acceptable when a single application code change would cause them all to fail
together. A test described as "raises FailedError for a nonexistent ref" verifies
both the error class and a message pattern, not just that something was raised.

### Rule 9 (MUST): Error assertions must specify both the error class and a message pattern

`raise_error(ErrorClass)` alone is underspecified: any instance of that class
satisfies it regardless of cause. The block form does not substitute for the
message check; RSpec allows both together.

```ruby
# Good
expect { command.call('nonexistent-ref') }
  .to raise_error(Git::FailedError, /nonexistent-ref/)

# Bad — passes for any Git::FailedError regardless of cause
expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)

# Bad — the block does not replace the message pattern
expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError) do |error|
  expect(error.result.status.exitstatus).to eq(128)
end
```

Rule 15 says what the pattern anchors on.

### Rule 10 (MUST): No assertions that only prove the code ran

When the expected value is known, assert it. `be_a`, `not_to be_nil`,
`not_to be_empty`, `respond_to`, and `not_to raise_error` pass for almost any
implementation and verify nothing about behavior.

```ruby
# Good
expect(repo.current_branch).to eq('main')

# Bad — passes for any string
expect(repo.current_branch).to be_a(String)
```

**Decision test:** "What application code change would cause *only this test* to
fail?" If the answer is "nothing", remove the assertion.

Command smoke tests are the one exception: `be_a(Git::CommandLine::Result)` and
`not_to be_empty` on stdout are what the command conventions require there. Rule
16 has the details. Do not flag them in a command spec.

### Rule 11 (SHOULD): Use `change` matchers instead of manual before/after assertions

```ruby
# Good
expect { repo.add('file.txt') }.to change { repo.status_info.added?('file.txt') }.from(false).to(true)

# Bad
before_count = repo.status_info.added.size
repo.add('file.txt')
expect(repo.status_info.added.size).to eq(before_count + 1)
```

### Rule 12 (MUST): Avoid `allow_any_instance_of` and `receive_message_chain`

They hide object boundaries and create brittle tests. In an integration spec they
are doubly suspect because Rule 13 forbids the stub they would set up.

## Rules specific to integration specs

### Rule 13 (MUST): Run real git; do not stub collaborators

Real git is the point of an integration spec. Commands, parsers, the execution
context, and the file system are all real. A spec that stubs `Git::Commands::*`,
`Git::Parsers::*`, `ProcessExecuter`, or the execution context is a unit spec in
the wrong directory; move it to `spec/unit/`.

A stub is allowed only to force a failure that real git or the real file system
cannot produce portably. The stub needs an inline comment saying why a real setup
does not work. The model is the `FileUtils.rm_r` stub in `git_spec.rb`:

```ruby
# The removal is stubbed rather than blocked with chmod: a permission-based
# setup behaves differently on Windows and silently no-ops when the suite
# runs as root. Only the export's own call is stubbed; the cleanup in the
# `after` hook goes through FileUtils.rm_rf, which calls rm_r with keywords.
context 'when the .git directory cannot be removed' do
  before do
    allow(FileUtils).to receive(:rm_r).and_call_original
    allow(FileUtils).to receive(:rm_r).with(end_with('.git')).and_raise(Errno::EACCES, 'objects/pack')
  end
```

A subject that sits below git may run a real non-git subprocess when git cannot
produce the condition. `command_line_spec.rb` runs the fixture script
`spec/support/fixtures/command_line_test` to produce a timeout, a signal death,
and merged stdout and stderr; `load_spec.rb` spawns a child Ruby under `-w`
because warnings are only observable in a fresh interpreter. A real process runs
in both, so neither is a stub. The spec says in a comment why git cannot serve.

### Rule 14 (MUST): Be independent of the host machine

Determinism for an integration spec means the outcome does not depend on the
machine's git configuration, its default branch name, or timing. Freezing time is
not the concern; pinning git is.

- **Every `Git.init` passes `initial_branch:`.** Without it, `HEAD` points at
  whatever `init.defaultBranch` the runner has. This includes bare repositories and
  repositories created inside a `before` block. When the factory call is itself
  the subject (the `.init` and `.clone` examples in `git_spec.rb`, the racing
  `Git.init` in `thread_safety_spec.rb`), pass `initial_branch:` unless the
  example asserts the default; an example that asserts the default says so in its
  description.
- **Every repository the spec commits in or checks out from goes through
  `init_test_repo` or `pin_test_repo_config`.** These set `user.email`,
  `user.name`, `commit.gpgsign`, `core.editor`, and `core.autocrlf` so a commit
  succeeds without a global identity, never opens an editor, never signs, and
  never rewrites line endings on Windows. The `'in an empty repository'` shared
  context pins `repo`; any additional repository the spec commits in (a clone
  target, a submodule source) needs the same. A bare repository that only
  receives pushes or serves fetches and clones does not need pinning, since none
  of those keys affects it; it still passes `initial_branch:`, which sets the
  `HEAD` that `clone` and `ls-remote` read. A repository whose `.git` is removed
  before any git command runs needs neither.

  ```ruby
  # Good
  let(:remote) { init_test_repo(remote_dir) }
  let(:bare)   { Git.init(bare_dir, bare: true, initial_branch: 'main') }

  # Bad — depends on the host's init.defaultBranch, user.name, and core.autocrlf
  let(:remote) { Git.init(remote_dir) }
  ```

- **No `sleep`.** A spec that needs ordering makes the order explicit (a `Queue`
  barrier, a commit date passed to the command), never waits for it.
- **No dependence on the machine's global git config.** A spec that needs a config
  value sets it on the test repository. When global or system scope is itself the
  subject (`git_configure_spec.rb`), redirect `GIT_CONFIG_GLOBAL` to a temp file
  for the example's duration and restore it under Rule 20.

### Rule 15 (MUST): Anchor error message patterns on something the test controls

Git's phrasing changes between versions; the input the test passed does not. The
message pattern in a `raise_error` assertion anchors on the input value, the ref
name, the path, or the subcommand name, not on git's wording:

```ruby
# Good — the ref name is the test's own input
expect { command.call('nonexistent-ref') }
  .to raise_error(Git::FailedError, /nonexistent-ref/)

# Good — the path is the test's own input
expect { repo.add('missing.txt') }
  .to raise_error(Git::FailedError, /missing\.txt/)

# Bad — git's phrasing, which has changed across versions
expect { command.call('nonexistent-ref') }
  .to raise_error(Git::FailedError, /fatal: bad revision/)
```

**Version variance loosens the pattern; it never removes it.** When no stable
anchor exists in the message, use the loosest regexp that still distinguishes this
failure from an unrelated one (the subcommand name, a keyword present in every
supported git version). `raise_error(Git::FailedError)` with a comment citing
version variance is a Rule 9 violation, not an exception to it.

The removed-`.git` failure is the common case with no input anchor: the test
controls nothing that appears in git's message. Anchor it on `/git repository/`,
which every supported version prints:

```ruby
# Good — the accepted anchor for a removed .git directory
FileUtils.rm_rf(File.join(repo_dir, '.git'))
expect { command.call }.to raise_error(Git::FailedError, /git repository/)
```

### Rule 16 (MUST): Assert the value the test set up, not the shape of git's output

The test created the branch, wrote the file, or made the commit, so it knows the
exact value to expect. Assert that value with `eq`, `contain_exactly`,
`have_attributes`, `match_array`, or `include` with a specific element:

```ruby
# Good — asserts the branches the test created
expect(repo.branch_list.map(&:refname)).to contain_exactly('refs/heads/main', 'refs/heads/feature')

# Good — asserts the attributes the test set up
expect(repo.object('HEAD')).to have_attributes(message: 'Initial commit', author: have_attributes(name: 'Test User'))

# Bad — proves git returned a list of the right type
expect(repo.branch_list).to all(be_a(Git::BranchInfo))
```

Command smoke tests are the exception. Per the
[command conventions](../command-test-conventions/SKILL.md#integration-tests), a
command spec confirms that `#call` returns a `Git::CommandLine::Result` with the
expected exit status and, for commands that produce output, non-empty stdout:

```ruby
# Good — a command smoke test, per the command conventions
expect(result).to be_a(Git::CommandLine::Result)
expect(result.status.exitstatus).to eq(0)
expect(result.stdout).not_to be_empty

# Bad — a facade spec that only proves git printed something
expect(repo.branch_list).not_to be_empty
```

Command specs stop there; output format and content belong to parser and facade
specs. Everywhere else, when the test knows what the output contains, assert it.

Do not assert on git's formatting (line layout, status letters, header syntax).
That tests git, not the gem. Parser integration specs are the exception: their
purpose is to prove the parser's format assumptions hold against real git, so
they assert the parsed result of real output, still as an exact value.

A value that does not exist before the call (the SHA of a commit the call
creates, a path the facade generates) has no exact value to assert. Assert its
shape, then a second property that ties it to the setup: resolve the SHA with
`repo.rev_parse` or `repo.object` and compare the tree or message; check that
the generated path holds the expected content. The SHA of an object that exists
before the call is knowable through `repo.rev_parse` and is asserted exactly,
never with a 40-hex regexp:

```ruby
# Good — the SHA exists before the call
expect(info.head).to eq(repo.rev_parse('HEAD'))

# Good — the SHA is created by the call; shape plus a tying property
expect(sha).to match(/\A\h{40}\z/)
expect(repo.object(sha).tree.sha).to eq(tree_sha)

# Bad — the exact value was available
expect(info.head).to match(/\A[0-9a-f]{40}\z/)
```

A value that is git's own prose (a worktree `prune_reason`, a message git
composed) follows Rule 15: the loosest regexp that distinguishes it, never
`not_to be_empty`.

### Rule 17 (MUST): Each example proves one assumption about real git

An integration example exists because real git, the file system, or the
operating system could behave differently from what a unit spec assumed. Each
example proves one such assumption. Anything a unit spec can prove with a stubbed
execution context stays in `spec/unit/`: argument mapping, option forwarding,
argument pre-processing (path normalization, deprecated-key rewrites), and
exception wrapping. Real git adds no signal to those.

Do not re-prove at one layer what another layer's integration spec already
proves. A command spec proves the command runs and returns the exit codes its
`allow_exit_status` range expects; a parser spec proves the parser's format
assumptions hold against real output; a facade spec proves only the behavior the
facade adds on top of its commands. A facade or parser example that repeats a
command's smoke test, or a command example that asserts what a parser spec
asserts, is redundant. Error-path examples (`raise_error(Git::FailedError)`)
belong to the command spec, which owns the error wrapping; a facade or parser
spec does not add one.

Coverage is not measured for integration specs. If the only reason for an example
is that a line or branch would otherwise be unexercised, it belongs in
`spec/unit/`, or nowhere.

### Rule 18 (MUST): Run setup git commands through `execution_context.command_capturing` or `repo`

Setup that needs git (creating a commit, a tag, a second branch) goes through the
public facade on `repo` when a facade method exists, and through
`execution_context.command_capturing` otherwise. Prefer the facade:
`command_capturing` bypasses the environment adjustments a command class makes
(the worktree commands unset `GIT_INDEX_FILE`), so setup through it may need to
repeat them by hand. Setup never goes through a sibling command class, `system`,
backticks, or `%x`:

```ruby
# Good
repo.add('README.md')
repo.commit('Initial commit')
sha = execution_context.command_capturing('rev-parse', 'HEAD').stdout.strip

# Bad — couples this spec to another command class's contract
Git::Commands::Commit.new(execution_context).call(message: 'Initial commit')

# Bad — not portable, and bypasses the env the gem pins
`git -C #{repo_dir} commit -m 'Initial commit'`
system('git', 'commit', '-m', 'Initial commit', chdir: repo_dir)
```

A raw git call is allowed only when the spec exists to compare the gem against
what git itself does and there is no `repo` or `execution_context` to route the
call through. The call needs an inline comment saying why, as with the Rule 13
stub exception. The model is `url_spec.rb`, which predicts the directory
`git clone` creates and then runs real `git clone` from a cwd with no repository
to check the prediction:

```ruby
# Git::URL.clone_to predicts the directory `git clone` will create without
# actually cloning. These examples verify that prediction against the
# directory real git produces, which is the assumption clone_to is built on.
it 'predicts the directory git creates' do
  predicted = described_class.clone_to(source_url)
  system('git', 'clone', '--quiet', source_url, exception: true)
  expect(File).to be_directory(predicted)
end
```

When the gem has no command for the setup at all (`git submodule add`), route
it through `execution_context.command_capturing` all the same; the call accepts
leading `-c` options. Add a comment naming the missing command.

A compare-against-git call invokes git through `Git.config.binary_path`, not a
bare `'git'`, so the comparison runs the same binary the gem does.

Non-git setup (files, directories) uses `Git::IntegrationTestHelpers`
(`write_file`, `create_directory`) or Ruby's standard library. A non-git
external tool the setup needs (`ssh-keygen` to produce a signing key) is outside
this rule: run it with `system(..., exception: true)`, add an inline comment
naming its role, and guard the example with `skip: unless_command(...)` so a
host without the tool skips it.

### Rule 19 (MUST): Build paths cross-platform

The suite runs on Windows. Build every path with `File.join`, `Dir.mktmpdir`, or
`Dir.tmpdir`; never with a literal `/tmp`, `/dev/null`, or `/nonexistent/...`.
Use `File::NULL` where a null device is needed. To make a path invalid, create a
regular file where a directory is expected, rather than naming a path that does
not exist on one platform.

### Rule 20 (MUST): Scope or restore global state

`ENV`, the current directory, and process-wide git settings are shared across
examples. Scope a change to a block (`Dir.chdir(dir) { ... }`), save it in a
`let` and restore it in `after`, or wrap the example in an `around` hook whose
`ensure` restores it. An example never leaves the process in a different state
than it found it.

### Rule 21 (MUST): Spec location mirrors the source file; cross-cutting specs carry a header comment

`lib/git/commands/add.rb` maps to `spec/integration/git/commands/add_spec.rb`,
`lib/git/repository/staging.rb` to
`spec/integration/git/repository/staging_spec.rb`, and `lib/git/parsers/branch.rb`
to `spec/integration/git/parsers/branch_spec.rb`.

A top-level source file maps to a spec directly under `spec/integration/git/`:
`lib/git/url.rb` to `url_spec.rb`, `lib/git/command_line.rb` to
`command_line_spec.rb`, and `lib/git/configuring.rb` to `git_configure_spec.rb`.
`Git.export` in `lib/git.rb` and the factories in `lib/git/factories.rb`
(`Git.open`, `Git.init`, `Git.clone`, `Git.bare`) map to `git_spec.rb` in the
same directory. These specs mirror a source file, so they need no header
comment; one is permitted.

A spec with no single source counterpart (thread safety, locale handling, loading
the gem under `-w`) also lives directly under `spec/integration/git/` and opens
with a comment, after the requires, stating what it covers and why it does not
belong to one source file. `thread_safety_spec.rb` and
`non_ascii_regex_matching_spec.rb` are the models.

## Directory-specific rules

These stay in the convention skill for their directory. Load that skill on top of
this one when working there.

- **Command specs** (`spec/integration/git/commands/`), from
  [Command Test Conventions](../command-test-conventions/SKILL.md#integration-tests):
  one command class per file; `context 'when the command succeeds'` and
  `context 'when the command fails'` under `describe '#call'`; at least one error
  test per command; `skip: unless_git(...)` guards for options newer than the
  minimum supported git.
- **Facade specs** (`spec/integration/git/repository/`), from
  [Facade Test Conventions](../facade-test-conventions/SKILL.md#integration-tests):
  single-command delegators do not get integration specs; only multi-command
  orchestration and facade-owned post-processing do; no
  `'when the command fails'` context.
- **Parser specs** (`spec/integration/git/parsers/`): produce the raw output the
  parser is fed with `execution_context.command_capturing` and the parser's own
  format constant (`"--format=#{described_class::FORMAT_STRING}"`), never by
  instantiating a command class. That is what proves the format assumption holds
  against real git.
- **Cross-cutting specs** have no further conventions beyond Rules 1–21.

## Verification

After writing or modifying an integration spec, verify compliance before finishing:

1. **Run the spec:** `bundle exec rspec spec/integration/path/to_spec.rb`
2. **Run in random order:** `bundle exec rspec spec/integration/path/to_spec.rb --order rand`
3. **Re-check MUST rules.** Scan the spec against every MUST rule. Fix violations.
4. **Grep the file for the recurring deviations:** `raise_error(Git::FailedError)`
   with no pattern (Rules 9 and 15), `describe 'when` (Rule 2), `Git.init(` without
   `initial_branch:` (Rule 14), `be_a(String)` / `not_to be_empty` / `respond_to`
   (Rule 10, except in a command smoke test), `system(` / backticks / `%x`
   invoking git (Rule 18, unless commented as a compare-against-git exception),
   `'/tmp'` / `'/dev/null'` (Rule 19), `sleep` (Rule 14).

Repeat until all checks pass.

## Output

**When writing new specs**, produce the spec file and run through the Verification
checklist above. No additional structured output is required.

**When reviewing or auditing** existing specs, produce the following:

1. A per-rule compliance table:

   | Rule | Status | Issue |
   | ---- | ------ | ----- |

   Use **Pass**, **Fail**, or **N/A** for each rule.

2. A summary of required fixes (MUST-level violations).

3. A list of suggested improvements (SHOULD-level deviations), ordered by impact.
