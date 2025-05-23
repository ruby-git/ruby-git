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
- [Design philosophy](#design-philosophy)
  - [Direct mapping to git commands](#direct-mapping-to-git-commands)
  - [Parameter naming](#parameter-naming)
  - [Output processing](#output-processing)
- [Coding standards](#coding-standards)
  - [Commit message guidelines](#commit-message-guidelines)
    - [What does this mean for contributors?](#what-does-this-mean-for-contributors)
    - [What to know about Conventional Commits](#what-to-know-about-conventional-commits)
  - [Unit tests](#unit-tests)
  - [Continuous integration](#continuous-integration)
  - [Documentation](#documentation)
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
squashed. Additionally, you may need to rebase your branch to the latest `master`
branch if other changes have been merged.

At least one approval from a project maintainer is required before your pull request
can be merged. The maintainer is responsible for ensuring that the pull request meets
[the project's coding standards](#coding-standards).

## Design philosophy

*Note: As of v2.x of the `git` gem, this design philosophy is aspirational. Future
versions may include interface changes to fully align with these principles.*

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

### Direct mapping to git commands

Git commands are implemented within the `Git::Base` class, with each method directly
corresponding to a `git` command. When a `Git::Base` object is instantiated via
`Git.open`, `Git.clone`, or `Git.init`, the user can invoke these methods to interact
with the underlying Git repository.

For example, the `git add` command is implemented as `Git::Base#add`, and the `git
ls-files` command is implemented as `Git::Base#ls_files`.

When a single Git command serves multiple distinct purposes, method names within the
`Git::Base` class should use the `git` command name as a prefix, followed by a
descriptive suffix to indicate the specific function.

For instance, `#ls_files_untracked` and `#ls_files_staged` could be used to execute
the `git ls-files` command and return untracked and staged files, respectively.

To enhance usability, aliases may be introduced to provide more user-friendly method
names where appropriate.

### Parameter naming

Parameters within the `git` gem methods are named after their corresponding long
command-line options, ensuring familiarity and ease of use for developers already
accustomed to Git. Note that not all Git command options are supported.

### Output processing

The `git` gem translates the output of many Git commands into Ruby objects, making it
easier to work with programmatically.

These Ruby objects often include methods that allow for further Git operations where
useful, providing additional functionality while staying true to the underlying Git
behavior.

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

- `feat!: removed Git::Base.commit_force`

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

While working on specific features, you can run individual test files or a group of
tests using `bin/test`:

```bash
# run a single file (from tests/units):
$ bin/test test_object

# run multiple files:
$ bin/test test_object test_archive

# run all unit tests:
$ bin/test

# run unit tests with a different version of the git command line:
$ GIT_PATH=/Users/james/Downloads/git-2.30.2/bin-wrappers bin/test
```

### Continuous integration

All tests must pass in the project's [GitHub Continuous Integration
build](https://github.com/ruby-git/ruby-git/actions?query=workflow%3ACI) before the
pull request will be merged.

The [Continuous Integration
workflow](https://github.com/ruby-git/ruby-git/blob/master/.github/workflows/continuous_integration.yml)
runs both `bundle exec rake default` and `bundle exec rake test:gem` from the
project's [Rakefile](https://github.com/ruby-git/ruby-git/blob/master/Rakefile).

### Documentation

New and updated public methods must include [YARD](https://yardoc.org/)
documentation.

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
