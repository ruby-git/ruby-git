<!--
# @markup markdown
# @title How To Contribute
-->

# Contributing to the git gem

- [Summary](#summary)
- [How to contribute](#how-to-contribute)
- [How to report an issue or request a feature](#how-to-report-an-issue-or-request-a-feature)
- [How to submit a code or documentation change](#how-to-submit-a-code-or-documentation-change)
  - [Commit your changes to a fork of `ruby-git`](#commit-your-changes-to-a-fork-of-ruby-git)
  - [Create a pull request](#create-a-pull-request)
  - [Get your pull request reviewed](#get-your-pull-request-reviewed)
- [Branch strategy](#branch-strategy)
- [AI-assisted contributions](#ai-assisted-contributions)
- [Design philosophy](#design-philosophy)
- [Wrapping a git command](#wrapping-a-git-command)
  - [Method placement](#method-placement)
  - [Method naming](#method-naming)
  - [Parameter naming](#parameter-naming)
  - [Parameter values](#parameter-values)
    - [Options](#options)
    - [Positional arguments](#positional-arguments)
  - [Output processing](#output-processing)
  - [From design to implementation](#from-design-to-implementation)
  - [Example implementations](#example-implementations)
- [Coding standards](#coding-standards)
  - [Commit message guidelines](#commit-message-guidelines)
    - [What does this mean for contributors?](#what-does-this-mean-for-contributors)
    - [What to know about Conventional Commits](#what-to-know-about-conventional-commits)
  - [Unit tests](#unit-tests)
    - [RSpec best practices](#rspec-best-practices)
- [Building a specific version of the Git command-line](#building-a-specific-version-of-the-git-command-line)
  - [Install pre-requisites](#install-pre-requisites)
  - [Obtain Git source code](#obtain-git-source-code)
  - [Build git](#build-git)
  - [Use the new Git version](#use-the-new-git-version)
- [Licensing](#licensing)

## Summary

Thank you for your interest in contributing to the `ruby-git` project.

This document provides guidelines for contributing to the `ruby-git` project. While
these guidelines may not cover every situation, we encourage you to use your best
judgment when contributing.

If you have suggestions for improving these guidelines, please propose changes via a
pull request.

Please also review and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) when
participating in the project. Governance and maintainer expectations are described in
[GOVERNANCE.md](GOVERNANCE.md).

## How to contribute

You can contribute in the following ways:

1. [Report an issue or request a
   feature](#how-to-report-an-issue-or-request-a-feature)
2. [Submit a code or documentation
   change](#how-to-submit-a-code-or-documentation-change)

## How to report an issue or request a feature

`ruby-git` utilizes [GitHub
Issues](https://help.github.com/en/github/managing-your-work-on-github/about-issues)
for issue tracking and feature requests.

To report an issue or request a feature, please [create a `ruby-git` GitHub
issue](https://github.com/ruby-git/ruby-git/issues/new). Fill in the template as
thoroughly as possible to describe the issue or feature request.

## How to submit a code or documentation change

There is a three-step process for submitting code or documentation changes:

1. [Commit your changes to a fork of
   `ruby-git`](#commit-your-changes-to-a-fork-of-ruby-git) using [Conventional
   Commits](#commit-message-guidelines)
2. [Create a pull request](#create-a-pull-request)
3. [Get your pull request reviewed](#get-your-pull-request-reviewed)

### Commit your changes to a fork of `ruby-git`

Make your changes in a fork of the `ruby-git` repository.

### Create a pull request

If you are not familiar with GitHub Pull Requests, please refer to [this
article](https://help.github.com/articles/about-pull-requests/).

Follow the instructions in the pull request template.

### Get your pull request reviewed

Code review takes place in a GitHub pull request using the [GitHub pull request
review
feature](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-request-reviews).

Once your pull request is ready for review, request a review from at least one
[maintainer](MAINTAINERS.md) and any other contributors you deem necessary.

During the review process, you may need to make additional commits, which should be
squashed. Additionally, you will need to rebase your branch to the latest version of
the target branch (e.g., `main` or `4.x`) before merging.

At least one approval from a project maintainer is required before your pull request
can be merged. The maintainer is responsible for ensuring that the pull request meets
[the project's coding standards](#coding-standards).

## Branch strategy

This project maintains two active branches:

- **`main`**: Active development for the next major version (v5.0.0+). This branch
  may contain breaking changes.
- **`4.x`**: Maintenance branch for the v4.x release series. This branch receives bug
  fixes and backward-compatible improvements only.

**Important:** Never commit directly to `main` or `4.x`. All changes must be
submitted via pull requests from feature branches. This ensures proper code review,
CI validation, and maintains a clean commit history.

When submitting a pull request:

- **New features and breaking changes**: Target the `main` branch
- **Bug fixes**: Target `main`, and maintainers will backport to `4.x` if applicable
- **Security fixes**: Target both branches or `4.x` if the issue only affects v4.x

## AI-assisted contributions

AI-assisted contributions are welcome. Please review and apply our [AI
Policy](AI_POLICY.md) before submitting changes. You are responsible for
understanding and verifying any AI-assisted work included in PRs and ensuring it
meets our standards for quality, security, and licensing.

## Design philosophy

The `git` gem is designed as a lightweight wrapper around the `git` command-line
tool, providing Ruby developers with a simple and intuitive interface for
programmatically interacting with Git.

This gem adheres to the "principle of least surprise," ensuring that it does not
introduce unnecessary abstraction layers or modify Git's core functionality. Instead,
the gem maintains a close alignment with the existing `git` command-line interface,
avoiding extensions or alterations that could lead to unexpected behaviors.

By following this philosophy, the `git` gem allows users to leverage their existing
knowledge of Git while benefiting from the expressiveness and power of Ruby's syntax
and paradigms.

## Wrapping a git command

> **Note:** This documentation reflects **Phase 2 (Strangler Fig)** of the architectural
> redesign. It will be updated in **Phase 3** when `Git::Repository` becomes the primary
> public API and `Git::Lib` is bypassed. Currently, `Git::Base` remains the public API
> and `Git::Lib` acts as the delegation layer.

This section guides you through wrapping a git command. The first subsections focus
on **API design**: where methods belong, how to name them, and how to handle
parameters and output. These describe the public interface that gem users will see.

[From design to implementation](#from-design-to-implementation) then shows how to
structure your code using the gem's three-layer architecture. Note that while we are
transitioning to `Git::Repository`, the current public API is `Git::Base`, which
delegates to `Git::Lib`, which in turn delegates to internal command classes.

> **Note:** When adding new git command wrappers, **always use the new architecture**
> described in "From design to implementation" with `Git::Commands::*` classes and
> the Arguments DSL. The gem is being incrementally migrated from `Git::Lib` to this
> pattern. Do not add new methods directly to `Git::Lib`.

### Method placement

When implementing a git command, first determine what type of command it is. This
determines where to implement it in the Ruby API:

> **Note:** These placement guidelines define the **public API**. Always add public
> methods to `Git` module or `Git::Base` (which acts as the current facade for
> `Git::Repository`), even though the implementation will be in a `Git::Commands::*` class.

**Repository factory methods** are implemented on the `Git` module. Use these to
obtain a repository object for subsequent operations:

```ruby
repo = Git.clone('https://github.com/user/repo.git', 'local_path')
repo = Git.init('new_repo')
repo = Git.open('.')
```

**Repository-scoped commands** operate within a repository context. Implement these
`Git::Base` instance methods:

```ruby
repo.add('file.txt')
repo.commit('Add file')
repo.log
```

**Non-repository commands** do not require a repository context. Implement these as
methods on the `Git` module:

```ruby
Git.config_get('user.name', global: true)
Git.config_set('user.email', 'user@example.com', global: true)
```

Some commands, like `git config`, can operate in multiple contexts:

- **On the `Git` module**: A scope parameter (`global: true`, `system: true`) or
  `file:` parameter is required. The `local:` and `worktree:` options are not allowed
  since they require a repository.
- **On a `Git::Base` instance**: The command defaults to the repository's local
  scope. The `worktree: true` option is also available.

### Method naming

Each method corresponds directly to a `git` command. For example, the `git add`
command is implemented as `Git::Base#add`, and the `git ls-files` command is
implemented as `Git::Base#ls_files`.

When a single Git command serves multiple distinct purposes, method names should use
the git command name as a prefix, followed by a descriptive suffix indicating the
specific function. The suffix should correspond to the git option that distinguishes
the behavior.

For example, `git config` supports `--get`, `--set`, `--list`, `--unset`, and other
options. These are implemented as separate methods:

```ruby
repo.config_get('user.name')              # git config --get user.name
repo.config_set('user.name', 'Scott')     # git config user.name Scott
repo.config_list                          # git config --list
repo.config_unset('user.name')            # git config --unset user.name
repo.config_get_all('remote.origin.url')  # git config --get-all remote.origin.url
```

To enhance usability, aliases may be introduced to provide more user-friendly method
names where appropriate.

See also [Output processing](#output-processing) for when different output formats
require separate methods.

### Parameter naming

Parameters within the `git` gem methods are named after their corresponding long
command-line options, ensuring familiarity and ease of use for developers already
accustomed to Git.

For example, `git config --global` becomes `global: true`, and `git config --file`
becomes `file: '/path/to/config'`.

As a lightweight wrapper, the gem passes options directly to the git command-line.
This means git itself will validate option combinations and report errors. This
approach is preferred as long as the error messages returned by git are actionable
and understandable for users of the gem.

When multiple options are mutually exclusive (like `--global`, `--local`,
`--system`), only one may be specified. Providing more than one will raise an
`ArgumentError`.

Note that not all Git command options are supported.

### Parameter values

This section defines how git command-line options and positional arguments map to
Ruby method parameters. Contributors must follow these conventions:

#### Options

Git command-line options are passed as keyword arguments in the Ruby API. Methods
accept these via an options splat parameter (e.g., `def replace(object, replacement,
**options)`). Each option is mapped to a keyword argument as described below.

- **Boolean flags**: Git options like `--global` or `--bare` are mapped to `global:
  true` or `bare: true`. Omit the key or use `false` to leave the flag unset.
  - `git config --global` → `global: true`

- **Negated boolean flags**: Options like `--no-reflogs` are mapped to `no_reflogs:
  true`.
  - `git branch --no-reflogs` → `no_reflogs: true`

- **Value options**: Options that take a value, such as `--file <path>` or `--author
  <name>`, are mapped as `file: '/path'`, `author: 'Name'`.
  - `git config --file /tmp/config` → `file: '/tmp/config'`

- **Options with optional values**: If a git option can be used as a flag or with a
  value (e.g., `--color` or `--color=always`), use `color: true` for the flag form,
  or `color: 'always'` for the value form.
  - `git log --color` → `color: true`
  - `git log --color=always` → `color: 'always'`

- **List/array options**: Options that can be repeated or take multiple values (e.g.,
  `--exclude <pattern>`, `--pathspec-from-file <file>`) are mapped to arrays:
  `exclude: ['foo', 'bar']`.
  - `git ls-files --exclude=foo --exclude=bar` → `exclude: ['foo', 'bar']`

- **Key-value pair options**: Options like `-c key=value` are mapped as `c: { 'key'
  => 'value' }` or as an array of pairs if multiple are allowed.
  - `git -c user.name=Scott` → `c: { 'user.name' => 'Scott' }`

- **Mutually exclusive options**: If options are mutually exclusive (e.g.,
  `--global`, `--local`, `--system`), only one may be set to `true`. Setting more
  than one raises `ArgumentError`.

#### Positional arguments

Arguments that are not options (e.g., file names, branch names) are passed as method
arguments, not as keyword arguments.

- **Only single-valued positional arguments**: If a command has one or more
  single-valued positional arguments (e.g., `<arg1>` or `<arg1> <arg2>`), pass each
  as a separate method argument, in the order they appear in the official git
  documentation and CLI usage. Optional arguments (indicated by `[<arg>]`) should
  default to `nil`.
  - `git cmd <object>` → `def cmd(object)` (fictitious command)
  - `git replace <object> <replacement>` → `def replace(object, replacement)`
  - `git clone <repository> [<directory>]` → `def clone(repository, directory = nil)`

- **Single multi-valued positional argument**: If a command has a single multi-valued
  positional argument (e.g., `<pathspec>...` or `[<pathspec>...]`), use a splat
  parameter to accept zero or more values (optional) or one or more values
  (required).
  - `git add [<pathspec>...]` → `def add(*paths)`

- **Mixed single-valued and multi-valued positional arguments**: If a command has
  both single-valued and multi-valued positional arguments (e.g., `<branch>
  [<pathspec>...]`), accept the single-valued positional arguments first (with `nil`
  for omitted optionals), and use a keyword argument with an empty array default for
  the multi-valued argument. The keyword argument should accept either a single value
  or an array. If a single value is provided, wrap it in an array internally.
  - `git checkout [<branch>] [-- <pathspec>...]` → `def checkout(branch = nil,
    pathspecs: [])`

These conventions ensure the API is predictable and closely aligned with the git CLI.
If a new option type is encountered, extend this section to document the mapping.

### Output processing

The `git` gem translates the output of many Git commands into Ruby objects, making it
easier to work with programmatically.

These Ruby objects often include methods that allow for further Git operations where
useful, providing additional functionality while staying true to the underlying Git
behavior.

When a single git command can produce distinctly different output types based on its
options, implement separate methods for each output type. Follow the same naming
convention used for commands with multiple purposes: use the git command name as a
prefix, followed by a suffix that describes the specific output type or
functionality.

For example, `git diff` can produce full diffs, statistical summaries, or path status
information depending on the options used. These are implemented as separate methods:

```ruby
repo.diff_full('HEAD~1', 'HEAD')       # Full diff output (git diff -p)
repo.diff_stats('HEAD~1', 'HEAD')      # Statistical summary (git diff --numstat)
repo.diff_path_status('HEAD~1', 'HEAD') # File paths and status (git diff --name-status)
```

This approach ensures each method has a clear, predictable return type and allows for
targeted parsing logic appropriate to each output format.

### From design to implementation

> **Note:** **Use this architecture for all new commands.** The gem is being
> incrementally migrated using the "Strangler Fig" pattern:
>
> 1. **Phase 1 (completed)**: Foundation work to introduce the new command architecture
>    and prepare the codebase for incremental migration.
> 2. **Phase 2 (current)**: New `Git::Commands::*` classes are created, and `Git::Lib`
>    methods delegate to them. `Git::Lib` remains but becomes a thin wrapper.
> 3. **Phase 3 (planned)**: Public API (`Git::Base`) will be refactored to use
>    `Git::Commands::*` directly, bypassing `Git::Lib`.
> 4. **Phase 4 (planned)**: `Git::Lib` will be removed entirely.
>
> When adding new commands, create the `Git::Commands::*` class and have the
> corresponding `Git::Lib` method delegate to it (see `Git::Lib#add` for an example).
> When you encounter existing commands, you may optionally refactor them to this
> pattern following the TDD workflow.

The gem uses a three-layer architecture that separates the public API from internal
implementation:

1. **Facade layer (`Git::Base` and `Git` module)** — The current public interface.
   Methods here are thin wrappers that delegate to `Git::Lib`, which in turn
   delegates to internal command classes.

2. **Command layer (`Git::Commands::*`)** — Internal classes that implement git
   commands. Each command class handles argument building and output parsing.

3. **Execution layer (`Git::ExecutionContext`)** — Runs raw git commands. Command
   classes use this to execute git and receive output.

When wrapping a new git command:

1. **Design the public API** using the guidelines in this section (placement, naming,
   parameters, output)

2. **Create a command class** in `lib/git/commands/` that:
   - Accepts an `ExecutionContext` and any required arguments
   - Defines arguments using the Arguments DSL
   - Parses the output into Ruby objects

3. **Add the facade method** to `Git::Base` (or `Git` module) that delegates to
   `Git::Lib`.

Example structure for `git add`:

```ruby
# lib/git/commands/add.rb (internal)
module Git
  module Commands
    class Add
      # Define arguments using the Arguments DSL
      ARGS = Arguments.define do
        flag :all
        flag :force
        positional :paths, variadic: true, default: ['.'], separator: '--'
      end

      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git add command
      #
      # @overload call(*paths, all: nil, force: nil)
      #
      #   @param paths [Array<String>] files to be added
      #
      #   @param all [Boolean] Add, modify, and remove index entries to match the worktree
      #
      #   @param force [Boolean] Allow adding otherwise ignored files
      #
      # @return [String] the command output
      #
      def call(*, **)
        @execution_context.command('add', *ARGS.bind(*, **))
      end
    end
  end
end
```

**Method Signature Convention**: The `#call` signature SHOULD, if possible, use
anonymous variadic arguments for both positional and keyword arguments:

```ruby
def call(*, **)
  @execution_context.command('add', *ARGS.bind(*, **))
end
```

The `#call` method MAY assign `bound_args = ARGS.bind(*, **)` when you need to
access argument values (e.g., `bound_args.dirstat`). Note that default values
defined in the DSL (e.g., `positional :paths, default: ['.']`) are applied
automatically by `ARGS.bind`, so manual default checking is usually unnecessary.

Specific arguments MAY be extracted when the command needs to inspect or manipulate
them:

```ruby
def call(*, **)
  bound_args = ARGS.bind(*, **)
  output = @execution_context.command('diff', *bound_args).stdout
  DiffParser.parse(output, include_dirstat: !bound_args.dirstat.nil?)
end
```

Validation of supported options is handled by the `Arguments` DSL via `ARGS.bind`,
which raises `ArgumentError` for unsupported keywords. The public API in `Git::Lib`
handles the translation from single values or arrays to the splat format.

> **YARD Documentation Note:** When using anonymous keyword forwarding (`**`), YARD
> cannot infer the method signature. Use the `@overload` directive with **explicit
> keyword parameters** (e.g., `@overload call(paths, all: nil, force: nil)`) and
> document each keyword with its own `@param` tag. Do not use `@option` with
> `@overload`. See the example above for the pattern.

> **Testing Requirement:** When defining arguments with the DSL, you must write RSpec
> tests that verify each argument handles valid values correctly (booleans, strings,
> arrays) and handles invalid values appropriately. Use a separate `context` block for
> testing each option to ensure clarity and isolation. See
> `spec/git/commands/add_spec.rb` for examples of comprehensive argument testing.

```ruby
# lib/git/lib.rb (delegation)
class Git::Lib
  # Git::Lib may accept an options hash for backward compatibility
  def add(paths = '.', options = {})
    # Convert to splat + keyword arguments when calling the command class
    Git::Commands::Add.new(self).call(*Array(paths), **options)
  end
end

# lib/git/base.rb (public facade)
class Git::Base
  def add(paths = '.', **options)
    lib.add(paths, options)
  end
end
```

For factory methods and non-repository commands, the pattern is similar but differs
in how the `ExecutionContext` is obtained:

```ruby
# Factory method (Git.clone) — creates context, runs command, returns repository
module Git
  def self.clone(url, path = nil, **options)
    # logic to call Git::Commands::Clone via Git::Lib
  end
end

# Non-repository command (Git.global_config) — standalone context
module Git
  def self.global_config(name, value = nil)
    Git::Lib.new.global_config(name, value)
  end
end
```

> **Note:** The `Git::Lib` class currently acts as the execution context. In the new
> architecture, `Git::Lib` methods delegate to `Git::Commands::*` classes, passing `self`
> (the `Git::Lib` instance) as the execution context.

### Example implementations

The following command classes demonstrate patterns for implementing new commands.
See `lib/git/commands/` and `spec/git/commands/` for the full implementations:

- **Simple command**: `Git::Commands::Add` — straightforward argument building with
  the Arguments DSL
- **Command with output parsing**: `Git::Commands::Fsck` — parses git output into
  structured Ruby objects
- **Factory command**: `Git::Commands::Clone` — returns data for creating a
  repository object
- **Multiple outputs**: `Git::Commands::Diff::*` — subclasses for different output
  formats (planned)
- **Multi-context**: `Git::Commands::Config` — handles both module and instance
  variants (planned)

## Coding standards

To ensure high-quality contributions, all pull requests must meet the following
requirements:

### Commit message guidelines

To enhance our development workflow, enable automated changelog generation, and pave
the way for Continuous Delivery, the `ruby-git` project has adopted the [Conventional
Commits standard](https://www.conventionalcommits.org/en/v1.0.0/) for all commit
messages.

This structured approach to commit messages allows us to:

- **Automate versioning and releases:** Tools can now automatically determine the
  semantic version bump (patch, minor, major) based on the types of commits merged.
- **Generate accurate changelogs:** We can automatically create and update a
  `CHANGELOG.md` file, providing a clear history of changes for users and
  contributors.
- **Improve commit history readability:** A standardized format makes it easier for
  everyone to understand the nature of changes at a glance.

#### What does this mean for contributors?

Going forward, all commits to this repository **MUST** adhere to the [Conventional
Commits standard](https://www.conventionalcommits.org/en/v1.0.0/). Commits not
adhering to this standard will cause the CI build to fail. PRs will not be merged if
they include non-conventional commits.

A git pre-commit hook may be installed to validate your conventional commit messages
before pushing them to GitHub by running `bin/setup` in the project root.

#### What to know about Conventional Commits

The simplist conventional commit is in the form `type: description` where `type`
indicates the type of change and `description` is your usual commit message (with
some limitations).

- Types include: `feat`, `fix`, `docs`, `test`, `refactor`, and `chore`. See the full
  list of types supported in [.commitlintrc.yml](.commitlintrc.yml).
- The description must (1) not start with an upper case letter, (2) be no more than
  100 characters, and (3) not end with punctuation.

Examples of valid commits:

- `feat: add the --merges option to Git::Lib.log`
- `fix: exception thrown by Git::Lib.log when repo has no commits`
- `docs: add conventional commit announcement to README.md`

Commits that include breaking changes must include an exclaimation mark before the
colon:

- `feat!: removed Git::Repository#commit_force`

The commit messages will drive how the version is incremented for each release:

- a release containing a **breaking change** will do a **major** version increment
- a release containing a **new feature** will do a **minor** increment
- a release containing **neither a breaking change nor a new feature** will do a
  **patch** version increment

The full conventional commit format is:

```text
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

- `optional body` may include multiple lines of descriptive text limited to 100 chars
  each
- `optional footers` only uses `BREAKING CHANGE: <description>` where description
  should describe the nature of the backward incompatibility.

Use of the `BREAKING CHANGE:` footer flags a backward incompatible change even if it
is not flagged with an exclaimation mark after the `type`. Other footers are allowed
by not acted upon.

See [the Conventional Commits
specification](https://www.conventionalcommits.org/en/v1.0.0/) for more details.

### Unit tests

- All changes must be accompanied by new or modified unit tests.
- The entire test suite must pass when `bundle exec rake default` is run from the
  project's local working copy.

This project uses two test frameworks:

- **RSpec** (`spec/`) - **Primary framework for all new tests.**
- **Test::Unit** (`tests/units/`) - **Legacy test suite.** Maintained for existing
  coverage but should not be extended for new features unless absolutely necessary.

#### RSpec best practices

- **Public methods**: Use a separate `describe '#method_name'` block for each public
  method.
- **Contexts**: Use separate `context` blocks for different scenarios.
- **Options**: For methods accepting options (like commands), use a separate
  `context` for each option to ensure isolation and comprehensiveness.
- **One assertion per test**: Each test should verify one specific aspect of
  behavior. Exceptions include: (a) testing that an object has expected attributes
  after creation (e.g., verifying multiple fields of a returned object), (b)
  verifying expected side effects of a single operation (e.g., a method that both
  returns a value and modifies state), (c) testing that multiple related
  assertions hold for the same setup (e.g., boundary conditions).

#### Unit tests vs Integration tests

This project uses two types of RSpec tests, organized by directory:

- **Unit tests** (`spec/unit/`) - Test individual classes and methods with mocked
  execution context. These verify that the gem builds correct git command arguments
  and properly handles git output. Unit tests should mock `@execution_context` to
  avoid calling real git commands.

- **Integration tests** (`spec/integration/`) - Test the gem's behavior against real
  git repositories. These verify that mocked assumptions in unit tests match actual
  git behavior. Integration tests create temporary repositories using `Dir.mktmpdir`
  and run real git commands through the gem's public API.

**Purpose of integration tests**: Integration tests validate that the gem correctly
interacts with git, not that git itself works correctly. They should verify:
- That the gem's mocked command expectations match real git output format
- That the gem correctly handles real git behavior (e.g., unicode in branch names)
- That command options produce expected git behavior
- Edge cases that are difficult to mock reliably

**Integration test guidelines**:
- Keep tests **minimal and purposeful** - only create what's needed for the test
- Focus on **key behaviors** that unit tests can't verify
- Don't test git's functionality - test the gem's interaction with git
- Use the shared context `'in an empty repository'` for temporary repo setup
- Use `Git::IntegrationTestHelpers` methods for file operations
- Each test should verify one specific git interaction pattern

**Example**: An integration test for branch listing should verify that the gem
correctly parses git's branch list format, not that git can create branches.

While working on specific features, you can run tests using:

```bash
# Run all tests (TestUnit + RSpec):
$ bundle exec rake test_all

# Run only TestUnit integration tests:
$ bundle exec rake test

# Run only RSpec tests (unit + integration):
$ bundle exec rake spec

# Run only RSpec unit tests:
$ bundle exec rake spec:unit

# Run only RSpec integration tests:
$ bundle exec rake spec:integration

# Run a single TestUnit file (from tests/units):
$ bin/test test_object

# Run multiple TestUnit files:
$ bin/test test_object test_archive

# Run a specific RSpec file:
$ bundle exec rspec spec/git/commands/add_spec.rb

# Run TestUnit tests with a different version of the git command line:
$ GIT_PATH=/Users/james/Downloads/git-2.30.2/bin-wrappers bin/test
```

New and updated public-facing features should be documented in the project's
[README.md](README.md).

## Building a specific version of the Git command-line

To test with a specific version of the Git command-line, you may need to build that
version from source code. The following instructions are adapted from Atlassian’s
[How to install Git](https://www.atlassian.com/git/tutorials/install-git) page for
building Git on macOS.

### Install pre-requisites

Prerequisites only need to be installed if they are not already present.

From your terminal, install Xcode’s Command Line Tools:

```shell
xcode-select --install
```

Install [Homebrew](http://brew.sh/) by following the instructions on the Homebrew
page.

Using Homebrew, install OpenSSL:

```shell
brew install openssl
```

### Obtain Git source code

Download and extract the source tarball for the desired Git version from [this source
code mirror](https://mirrors.edge.kernel.org/pub/software/scm/git/).

### Build git

From your terminal, change to the root directory of the extracted source code and run
the build with following command:

```shell
NO_GETTEXT=1 make CFLAGS="-I/usr/local/opt/openssl/include" LDFLAGS="-L/usr/local/opt/openssl/lib"
```

The build script will place the newly compiled Git executables in the `bin-wrappers`
directory (e.g., `bin-wrappers/git`).

### Use the new Git version

To configure programs that use the Git gem to utilize the newly built version, do the
following:

```ruby
require 'git'

# Set the binary path
Git.configure { |c| c.binary_path = '/Users/james/Downloads/git-2.30.2/bin-wrappers/git' }

# Validate the version (if desired)
assert_equal([2, 30, 2], Git.binary_version)
```

Tests can be run using the newly built Git version as follows:

```shell
GIT_PATH=/Users/james/Downloads/git-2.30.2/bin-wrappers bin/test
```

Note: `GIT_PATH` refers to the directory containing the `git` executable.

## Licensing

`ruby-git` uses [the MIT license](https://choosealicense.com/licenses/mit/) as
declared in the [LICENSE](LICENSE) file.

Licensing is critical to open-source projects as it ensures the software remains
available under the terms desired by the author.
