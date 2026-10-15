---
name: rspec-integration-testing-standards
description: 'Rules for RSpec integration specs in ruby-git, on top of the rspec-base-standards skill: when a seam earns one, one spec per class or module, asserting against real git without asserting on its formatting, owning temporary repositories and pinning their git config, starting git only through the gem, portability, and git version guards. Use when writing, reviewing, or auditing RSpec specs under spec/integration/, or deciding whether a behavior needs an integration spec or a unit spec.'
---

# RSpec integration testing standards

The rules for integration specs live in the `rspec-integration-testing-standards`
skill of the `jcouball-testing` plugin, which loads its `rspec-base-standards` skill
first. This file holds only what is specific to ruby-git, so fixes to the rules land
once, in the plugin, instead of drifting between two full copies. ruby-git's changes
to the conventions every spec follows are in its
[RSpec base standards](../rspec-base-standards/SKILL.md) file.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Changes and additions for ruby-git](#changes-and-additions-for-ruby-git)
- [Related skills](#related-skills)

## How to use this skill

Invoke `/jcouball-testing:rspec-integration-testing-standards` and apply the changes
below throughout its workflow. If you arrived here because that skill told you to read
this file, do not invoke it again — its rules are already in context; apply the
changes below and continue.

If the plugin is not installed, install it first:

```bash
claude plugin marketplace add jcouball/agent-plugins
claude plugin install jcouball-testing@jcouball
```

In an agent that cannot install or invoke Claude Code plugins, read
[the integration skill](https://github.com/jcouball/agent-plugins/blob/testing-v0.2.1/plugins/testing/skills/rspec-integration-testing-standards/SKILL.md)
and [the base skill](https://github.com/jcouball/agent-plugins/blob/testing-v0.2.1/plugins/testing/skills/rspec-base-standards/SKILL.md)
directly from the plugin source and apply the same changes on top, with the
[RSpec base standards](../rspec-base-standards/SKILL.md) file's changes applied to the
base skill. In Copilot Chat, attach this file, that base standards file, and the two
plugin sources to your context and proceed the same way.

These changes were written against version 0.2.1 of the `jcouball-testing` plugin,
which the links above point to. When the plugin is upgraded, check each change below
against the new rules, then move the links to the new version.

## Changes and additions for ruby-git

- **Class families.** Specs under `spec/integration/git/commands/` also follow the
  [Command test conventions](../command-test-conventions/SKILL.md), and specs under
  `spec/integration/git/repository/` follow the
  [Facade test conventions](../facade-test-conventions/SKILL.md). Each says how its
  specs group their examples: a command spec puts
  `context 'when the command succeeds'` and `context 'when the command fails'` under
  `describe '#call'`, and a facade spec has no failure context. Where a convention
  departs from a plugin rule, the convention wins, in either direction. It may
  prescribe what a plugin rule forbids, such as the command smoke test that asserts
  `be_a(Git::CommandLine::Result)` and non-empty stdout. It may also forbid what a
  plugin rule permits, such as the facade conventions' list of methods that get no
  integration spec even where the rule on seams would allow one. A review of such a
  spec produces the plugin's per-rule table first, then the class-family skill's own
  output for its conventions.
- **Which spec drives git to fail.** The rule that at least one example drives the
  dependency to fail is met by the command spec, which owns the error wrapping. A
  facade or parser spec adds no failure example.
- **Parser specs.** A spec under `spec/integration/git/parsers/` produces the raw output
  with `execution_context.command_capturing`, passing the arguments the gem passes to
  git when it produces that output, whether a facade or a command class supplies them,
  and never runs a command class itself. Where the parser defines its format string,
  pass it from the constant, as in `"--format=#{described_class::FORMAT_STRING}"` for
  `Git::Parsers::Tag`, or `described_class::STASH_FORMAT` for `Git::Parsers::Stash`,
  which `Git::Commands::Stash::List` passes. Older parser specs that run command classes
  are listed under known deviations in the rule on starting git. The spec asserts the
  parsed result as an exact value, including field values git chose, such as a mode or
  an object type. That is an exception to the rule against asserting on the dependency's
  formatting: confirming the parser's belief about git's output, per the rule on one
  example per return shape, is what a parser spec is for.
- **Specs with no single source file.** `Git.export` in `lib/git.rb` and the factories
  in `lib/git/factories.rb` map to `spec/integration/git/git_spec.rb`, and
  `lib/git/configuring.rb`, whose `Git::Configuring` module gives `Git` its `config_*`
  methods, maps to `spec/integration/git/git_configure_spec.rb`. A spec that covers no
  single source file, such as thread safety or loading the gem under `-w`, lives
  directly under `spec/integration/git/` and opens with a comment, after the requires,
  saying what it covers and why it belongs to no one file; `thread_safety_spec.rb` is
  the model. One whose subject is not a constant, such as `load_spec.rb`, names it
  with a string in `RSpec.describe`.
- **Requires and metadata.** `spec/spec_helper.rb` loads the gem, `tmpdir`, `English`,
  and every file under `spec/support/`, which holds the shared contexts and helpers. A
  spec requires `spec_helper`, may require the file under test, and otherwise requires
  only the standard library its own body uses, such as `securerandom` or `open3`. The
  spec helper tags every spec under `spec/integration/` with `:integration`; most
  specs also pass the tag to `RSpec.describe`, and a new spec does the same.
- **Temporary repositories.** Build them with the `'in an empty repository'` shared
  context, which makes `repo_dir` with `Dir.mktmpdir`, removes it in an `after` hook,
  and provides `repo` and `execution_context`. Write files with the
  `Git::IntegrationTestHelpers` methods it includes, such as `write_file` and
  `create_directory`. An additional repository, such as a bare remote, gets its own
  `Dir.mktmpdir` and `after` hook, unless it lives inside `repo_dir`, as an embedded
  repository does, where the context's hook removes it. The
  `'in a diff test repository'` context breaks the rule that every example owns its
  state, by sharing one repository across a group through `before(:all)`;
  [issue 1898](https://github.com/ruby-git/ruby-git/issues/1898) tracks the fix, and a
  new shared context does not copy it.
- **No `sleep`.** An example that needs one event to happen before another makes the
  order explicit, with a `Queue` barrier or a commit date passed to the command, and
  never sleeps to wait for it.
- **Pinning git.** In the rule on passing on every platform, the machine defaults to
  pin are git's. The gem already passes `-c` options on every call that pin
  `core.quotePath`, the editor, and color, so a spec need not pin those. The rest are
  the spec's:
  - Every `Git.init` passes `initial_branch:`, including bare repositories and those
    built in a `before`, unless the example asserts the default branch, which it then
    says in its description.
  - Every repository an example commits in or checks out from goes through
    `init_test_repo` or `pin_test_repo_config`, which set `user.email`, `user.name`,
    `commit.gpgsign`, `core.editor`, and `core.autocrlf`. A bare repository that only
    receives pushes or serves fetches and clones needs only `initial_branch:`.
  - A spec that needs a config value sets it on the test repository. When global scope
    is the subject, as in `git_configure_spec.rb`, point `GIT_CONFIG_GLOBAL` at a
    temporary file, under the exception in the rule on process-wide state for code
    that exists to read that state.

  CI runs the suite on Windows, JRuby, TruffleRuby, and under a non-English locale.
  Use `File::NULL` for a null device, and make a path invalid by putting a regular
  file where a directory is expected, not by naming a path that exists on no platform.
- **Starting git.** The library's own execution path is the facade on `repo` when it has
  a method for the setup, and `execution_context.command_capturing` otherwise; never a
  sibling command class. Prefer the facade: `command_capturing` skips the environment
  changes a command class makes, such as the worktree commands unsetting
  `GIT_INDEX_FILE`. When the gem has no command for the setup, such as
  `git submodule add`, use `command_capturing`, which accepts leading `-c` options, and
  name the missing command in a comment. A call that must run in a directory takes the
  `chdir:` option of `command_capturing`, never `Dir.chdir`. The exception is a subject
  that resolves a relative path against the process working directory: that example
  changes directory in an `around` hook, under the plugin's exception for code that
  reads process-wide state, with a comment saying why. The model is the relative-path
  context in `repository/worktree_operations_spec.rb`. Older specs that break this rule,
  or run command classes in a parser spec, are listed in [issue
  1901](https://github.com/ruby-git/ruby-git/issues/1901), and a new spec does not copy
  them. The rule against starting a process outside the library has three exceptions in
  ruby-git, each with an inline comment saying why:
  - A spec that compares the gem against what git itself does, with no repository to
    route the call through, runs
    `system(Git.config.binary_path, ..., exception: true)`, so it runs the same binary
    the gem does. `url_spec.rb`, which checks `Git::URL.clone_to` against the
    directory a real `git clone` creates, is the one such spec. It still calls a bare
    `'git'` and uses `Dir.chdir`;
    [issue 1899](https://github.com/ruby-git/ruby-git/issues/1899) tracks the fix.
  - A non-git tool the setup needs, such as `ssh-keygen`, runs through
    `system(..., exception: true)`, and its example carries
    `skip: unless_command('ssh-keygen', ...)`.
  - A subject that needs a fresh interpreter, such as `load_spec.rb` loading the gem
    under `-w`, starts one with `Open3`.
- **Stubs.** Beyond the plugin's double at the outermost edge, an integration spec may
  stub only to force a failure that real git or the real filesystem cannot produce
  portably, with an inline comment saying why a real setup does not work. The model is
  the `FileUtils.rm_r` stub in `git_spec.rb`, which replaces a `chmod` setup that
  behaves differently on Windows and when the suite runs as root.
- **Exact values.** In the rule on asserting on values the test controls, assert the
  exact value wherever the test knows it: the branches it created, the file it wrote,
  the message it committed, with `eq`, `contain_exactly`, `have_attributes`, or
  `include` with a specific element. `be_a`, `not_to be_empty`, and `respond_to` show
  only that git returned something, and belong only in the command smoke test. A SHA
  that exists before the call is read back from git, such as with `repo.rev_parse` or
  from the output of the setup call that created it, and asserted exactly, never with
  a hex pattern. A SHA the call creates has no exact value: assert its shape, then a
  second property that ties it to the setup, such as its tree or message read back
  through `repo.object`. Text git composes, such as a worktree's prune reason, gets
  the loosest pattern that tells it apart, never `not_to be_empty`.
- **Error patterns.** A `Git::FailedError` message starts with the git command line, so
  a pattern on the message that names the example's input or the subcommand matches any
  failure of that call and checks nothing. Check the input against the text git wrote,
  in the block form of `raise_error`:

  ```ruby
  expect { command.call('nonexistent.txt') }
    .to raise_error(Git::FailedError) { |error| expect(error.result.stderr).to include('nonexistent.txt') }
  ```

  Git names the bad input in its error for the failure the example forces, and leaves it
  out of a failure that happens before git reads the input, such as an unknown option or
  a wrong mode. This departs from two plugin rules: the base rule that error assertions
  name the class and a message pattern, which says the block form does not replace the
  message check, and the rule against asserting on the dependency's formatting, which
  says to anchor the pattern on the input and never drop it. Both assume the message
  tells one failure from another. Here the input is always in the message, so the block
  check is the anchor those rules ask for, and the example has no message pattern. Some
  commands print the input in more than one failure. Only when the example could hit
  such a second failure does it also check the part of git's wording that differs, under
  the same departure as the `/git repository/` pattern below. A call with `merge: true`
  sends git's stderr to stdout, which leaves the message's stderr part empty, so its
  example checks `error.result.stdout`. A failure forced by removing `.git` has no input
  to anchor on. It checks `/git repository/`, which every supported git version prints
  and the command line never contains: on the message, or on `error.result.stdout` in
  the block form for a `merge: true` call. That departs from the rule against asserting
  on the dependency's formatting, because it is the only text that tells this failure
  from another. Older specs that assert only the class, or match their input against the
  message, are listed in [issue 1900](https://github.com/ruby-git/ruby-git/issues/1900),
  and a new spec does not copy them.
- **Version guards.** The minimum is `Git::MINIMUM_GIT_VERSION` in `lib/git.rb`, 2.43.0.
  `unless_git(version, feature)` is defined at the top level of `spec/spec_helper.rb`,
  so it works as `skip:` metadata on an `it` or a group. The [Command test
  conventions](../command-test-conventions/SKILL.md) say how command specs choose the
  version a guard names. `unless_pcre(feature)`, defined next to it, guards on how git
  was built rather than its version: it skips an example that passes `--perl-regexp`
  when the installed git lacks PCRE support. It follows the same rule as a version
  guard, as `skip:` metadata with the feature named.
- **Coverage.** ruby-git has no framework-bound code, so the Rails section, its coverage
  run, and the framework-bound coverage check in the plugin's Verification section do
  not apply.
- **The commands.** In the Verification block, run the file as
  `COVERAGE=false bundle exec rspec spec/integration/git/<path>_spec.rb`.
  `rake spec:integration` sets `COVERAGE=false` itself; a direct `rspec` run does not,
  and without it the run prints a coverage report for the code under test whose gaps are
  unit work. The parallel run the plugin's Verification section asks for is
  `bundle exec rake spec:integration`, which runs through `parallel_rspec` on MRI unless
  `PARALLEL_TESTS=false` is set, and serially on JRuby and TruffleRuby. The shared
  contexts make their directories with `Dir.mktmpdir`, which honors `TMPDIR`, so the
  block's leak check sees them.

## Related skills

- [RSpec base standards](../rspec-base-standards/SKILL.md) — ruby-git's changes to the
  conventions every spec follows
- [RSpec unit testing standards](../rspec-unit-testing-standards/SKILL.md) — the
  rules for specs under `spec/unit/`, where every conditional path is covered
- [Command test conventions](../command-test-conventions/SKILL.md) and
  [Facade test conventions](../facade-test-conventions/SKILL.md) — the class-family
  conventions built on these rules
- [Test debugging](../test-debugging/SKILL.md) — a failing or flaky integration spec
- [Testing guide](../testing-guide/SKILL.md) — the vocabulary these rules are written
  in and the reasoning behind them
