<!--
# @markup markdown
# @title README
-->

# The Git Gem

[![Gem Version](https://badge.fury.io/rb/git.svg)](https://badge.fury.io/rb/git)
[![Build Status](https://github.com/ruby-git/ruby-git/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/ruby-git/ruby-git/actions/workflows/continuous_integration.yml)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/git/)
[![Change
Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/git/file/CHANGELOG.md)
[![Conventional
Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![AI Policy](https://img.shields.io/badge/AI%20Policy-Doc-blue)](AI_POLICY.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **v5.0.0 is here.** This is a major release with a redesigned internal
> architecture, but most v4.x code runs unchanged thanks to compatibility
> shims. See [UPGRADING.md](UPGRADING.md) for the migration guide and
> [CHANGELOG.md](CHANGELOG.md) for full release notes.

- [Summary](#summary)
- [Install](#install)
- [Quick Start](#quick-start)
- [Examples](#examples)
  - [Gem Configuration](#gem-configuration)
  - [Git Configuration](#git-configuration)
  - [Full API](#full-api)
- [Errors Raised by This Gem](#errors-raised-by-this-gem)
- [Specifying and Handling Timeouts](#specifying-and-handling-timeouts)
- [Deprecations](#deprecations)
- [Platform Limitations](#platform-limitations)
  - [Regex Metacharacters on Git for Windows](#regex-metacharacters-on-git-for-windows)
- [Project Policies](#project-policies)
  - [Ruby Version Support Policy](#ruby-version-support-policy)
  - [Git Version Support Policy](#git-version-support-policy)
- [Project Announcements](#project-announcements)
  - [2026-07-28: v5.0.0 Released](#2026-07-28-v500-released)
  - [2026-01-07: AI Policy Introduced](#2026-01-07-ai-policy-introduced)
  - [2025-07-09: Architectural Redesign](#2025-07-09-architectural-redesign)
  - [2025-07-07: We Now Use RuboCop](#2025-07-07-we-now-use-rubocop)
  - [2025-06-06: Default Branch Rename](#2025-06-06-default-branch-rename)
  - [2025-05-15: We've Switched to Conventional Commits](#2025-05-15-weve-switched-to-conventional-commits)

## Summary

The [git gem](https://rubygems.org/gems/git) provides a Ruby interface to the `git`
command line.

Get started by obtaining a repository object by:

- opening an existing working copy with
  [Git.open](https://rubydoc.info/gems/git/Git#open-class_method)
- initializing a new repository with
  [Git.init](https://rubydoc.info/gems/git/Git#init-class_method)
- cloning a repository with
  [Git.clone](https://rubydoc.info/gems/git/Git#clone-class_method)

Methods that can be called on a repository object are documented in
[Git::Repository](https://rubydoc.info/gems/git/Git/Repository)

## Install

This gem is a wrapper around the `git` command line, so a `git` executable (version
2.28.0 or greater) must be installed and on your `PATH`. See the [Git Version Support
Policy](#git-version-support-policy) for details.

Install the gem and add to the application's Gemfile by executing:

```shell
bundle add git
```

If bundler is not being used to manage dependencies, install the gem by executing:

```shell
gem install git
```

## Quick Start

All functionality for this gem starts with the top-level
[`Git`](https://rubydoc.info/gems/git/Git) module. This module can be used to run
non-repo scoped `git` commands such as `config`.

The `Git` module also has factory methods such as `open`, `clone`, and `init` which
return a [`Git::Repository`](https://rubydoc.info/gems/git/Git/Repository) object. The
`Git::Repository` object is used to run repo-specific `git` commands such as `add`,
`commit`, `push`, and `log`.

Clone, read status, and log:

```ruby
require 'git'

repo = Git.clone('https://github.com/ruby-git/ruby-git.git', 'ruby-git')
repo.status.changed.each { |f| puts "changed: #{f.path}" }
repo.log(5).execute.each { |c| puts c.message }
```

Open an existing repo and commit:

```ruby
require 'git'

repo = Git.open('/path/to/repo')
repo.add(all: true)
repo.commit('chore: update files')
repo.push
```

Initialize a new repo and make the first commit:

```ruby
require 'git'

repo = Git.init('my_project')
repo.add(all: true)
repo.commit('initial commit')
```

## Examples

These examples cover configuring the gem and git itself. For the full set of
repository operations, see [Full API](#full-api) below.

### Gem Configuration

Configure the git gem:

```ruby
Git.configure do |config|
  config.binary_path = '/usr/local/bin/git'
  config.git_ssh = 'ssh -i ~/.ssh/id_rsa'
end

# or

Git.config.binary_path = '/usr/local/bin/git'
Git.config.git_ssh = 'ssh -i ~/.ssh/id_rsa'
```

**How SSH configuration is determined:**

- If `git_ssh` is not specified in the API call, the global config (`Git.configure {
  |c| c.git_ssh = ... }`) is used.
- If `git_ssh: nil` is specified, SSH is disabled for that instance (no SSH key or
  script will be used).
- If `git_ssh` is a non-empty string, it is used for that instance (overriding the
  global config).

You can also specify a custom SSH script on a per-repository basis:

```ruby
# Use a specific SSH key for a single repository
git = Git.open('/path/to/repo', git_ssh: 'ssh -i /path/to/private_key')

# Or when cloning
git = Git.clone('git@github.com:user/repo.git', 'local-dir',
                git_ssh: 'ssh -i /path/to/private_key')

# Or when initializing
git = Git.init('new-repo', git_ssh: 'ssh -i /path/to/private_key')
```

This is especially useful in multi-threaded applications where different repositories
require different SSH credentials.

### Git Configuration

Read and set `git` configuration values (via `git config`):

```ruby
# Global config (in ~/.gitconfig)
entries = Git.config_list(global: true)         # returns Array<Git::ConfigEntryInfo>
entry   = Git.config_get('user.email', global: true) # returns Git::ConfigEntryInfo or nil
email    = entry&.value                          # => "user@example.com" or nil
Git.config_set('user.email', 'user@example.com', global: true)

# Repository config
repo = Git.open('path/to/repo')
entries  = repo.config_list                     # returns Array<Git::ConfigEntryInfo>
entry    = repo.config_get('user.email')        # returns Git::ConfigEntryInfo or nil
email    = entry&.value                         # => "anotheruser@example.com" or nil
repo.config_set('user.email', 'anotheruser@example.com')
```

### Full API

Quick Start and the configuration sections above cover the most common setup. For
the complete set of operations — reading history, diffs, branches, remotes,
worktrees, staging, and low-level index and tree work — see the
[`Git::Repository`](https://rubydoc.info/gems/git/Git/Repository) reference. It
documents every method along with the object types each one returns (such as
`Git::Log`, `Git::Object::Commit`, `Git::Diff`, `Git::Branch`, and `Git::Worktree`),
so you can follow the links from a method to the full API of its result.

## Errors Raised by This Gem

The git gem will only raise an `ArgumentError` or an error that is a subclass of
`Git::Error`. It does not explicitly raise any other types of errors.

It is recommended to rescue `Git::Error` to catch any runtime error raised by this
gem unless you need more specific error handling.

```ruby
begin
  # some git operation
rescue Git::Error => e
  puts "An error occurred: #{e.message}"
end
```

See [`Git::Error`](https://rubydoc.info/gems/git/Git/Error) for more information.

## Specifying and Handling Timeouts

A timeout for git command line operations can be set either globally or for specific
method calls that accept a `:timeout` parameter.

The timeout value must be a real, non-negative `Numeric` value that specifies a
number of seconds a `git` command will be given to complete before being sent a KILL
signal. This library may hang if the `git` command does not terminate after receiving
the KILL signal.

When a command times out, it is killed by sending it the `SIGKILL` signal and a
`Git::TimeoutError` is raised. This error derives from the `Git::SignaledError` and
`Git::Error`.

If the timeout value is `0` or `nil`, no timeout will be enforced.

If a method accepts a `:timeout` parameter and a receives a non-nil value, the value
of this parameter will override the global timeout value. In this context, a value of
`nil` (which is usually the default) will use the global timeout value and a value of
`0` will turn off timeout enforcement for that method call no matter what the global
value is.

To set a global timeout, use the `Git.config` object:

```ruby
Git.config.timeout = nil # a value of nil or 0 means no timeout is enforced
Git.config.timeout = 1.5 # can be any real, non-negative Numeric interpreted as number of seconds
```

The global timeout can be overridden for a specific method if the method accepts a
`:timeout` parameter:

```ruby
repo_url = 'https://github.com/ruby-git/ruby-git.git'
Git.clone(repo_url) # Use the global timeout value
Git.clone(repo_url, timeout: nil) # Also uses the global timeout value
Git.clone(repo_url, timeout: 0) # Do not enforce a timeout
Git.clone(repo_url, timeout: 10.5)  # Timeout after 10.5 seconds raising Git::TimeoutError
```

If the command takes too long, a `Git::TimeoutError` will be raised:

```ruby
begin
  Git.clone(repo_url, timeout: 10)
rescue Git::TimeoutError => e
  e.result.tap do |r|
    r.class #=> Git::CommandLineResult
    r.status #=> #<Process::Status: pid 62173 SIGKILL (signal 9)>
    r.status.timeout? #=> true
    r.git_cmd # The git command ran as an array of strings
    r.stdout # The command's output to stdout until it was terminated
    r.stderr # The command's output to stderr until it was terminated
  end
end
```

## Deprecations

This gem uses ActiveSupport's deprecation mechanism to report deprecation warnings.

You can silence deprecation warnings by adding this line to your source code:

```ruby
Git::Deprecation.behavior = :silence
```

Or by setting this environment variable before loading the gem:

```sh
GIT_DEPRECATION_BEHAVIOR=silence
```

Accepted environment variable values are the behavior names supported by your
installed ActiveSupport version.

If `GIT_DEPRECATION_BEHAVIOR` is set to an unsupported value, loading the gem
raises `ArgumentError` with the accepted behavior names.

See [the Active Support Deprecation
documentation](https://api.rubyonrails.org/classes/ActiveSupport/Deprecation.html)
for more details.

If deprecation warnings are silenced, you should reenable them before upgrading the
git gem to the next major version. This will make it easier to identify changes
needed for the upgrade.

For the full list of deprecated methods and their replacements, see
[UPGRADING.md](UPGRADING.md).

## Platform Limitations

### Regex Metacharacters on Git for Windows

On Git for Windows, git's regex engine matches **bytes** rather than characters. A
metacharacter such as `.`, or a POSIX character class such as `[[:alpha:]]`, therefore
never matches a whole multi-byte character. The same call matches on Linux and macOS.

The failure is silent — nothing raises, and the result is indistinguishable from a
pattern that genuinely does not occur:

```ruby
# File content, commit message, and config value are all 'ÄPFEL sind gut'.
# 'Ä' is two bytes in UTF-8 (C3 84), so '.' has to match both to match the character.

repo.grep('^.PFEL')                              # => {} on Windows, matches elsewhere
repo.log.grep('^.PFEL').execute.size             # =>  0 on Windows, 1 elsewhere
repo.config_get_all('test.desc', '^.PFEL')       # => [] on Windows, matches elsewhere
```

This is a property of the regex engine git bundles on that platform, not something the
gem sets. It is unaffected by the locale: the behavior is identical under `en_US.UTF-8`,
`C.UTF-8`, `C`, and with no `LC_ALL` set at all. Literal (metacharacter-free) patterns
and case-insensitive matching are unaffected on every platform.

**Workaround.** Perl-compatible regular expressions do match characters on Git for
Windows, so the surfaces that can reach a PCRE engine accept an opt-in selector:

```ruby
repo.grep('^.PFEL', nil, perl_regexp: true)      # matches on every platform
repo.log.perl_regexp.grep('^.PFEL').execute      # matches on every platform
repo.full_log_commits(grep: '^.PFEL', perl_regexp: true)
```

Two caveats:

- **PCRE is a different dialect** than git's default POSIX basic/extended regular
  expressions. Selecting it is a deliberate choice by the caller, so the gem does not
  substitute it automatically based on the host.
- **PCRE must be compiled in.** Git for Windows and the mainstream Linux and macOS
  packages ship it, but git built without `USE_LIBPCRE` fails with `cannot use
  Perl-compatible regexes...`.

**There is no workaround for `git config` value patterns.** They are POSIX extended
regular expressions with no PCRE mode, so `config_get`, `config_get_all`,
`config_get_regexp`, `config_replace_all`, `config_unset`, and `config_unset_all` cannot
match a metacharacter against a non-ASCII character on Git for Windows. Match on ASCII
text or an exact value instead.

`config_replace_all` deserves particular care, because there the failure is not merely an
empty result. When the value pattern selects nothing, `git config --replace-all` *adds*
the new value as an additional entry rather than replacing one, and exits zero:

```ruby
# Existing value of test.desc is 'ÄPFEL sind gut'
repo.config_replace_all('test.desc', 'NEW', '^.PFEL')

repo.config_get_all('test.desc').map(&:value)
# => ["NEW"]                     elsewhere — replaced, as intended
# => ["ÄPFEL sind gut", "NEW"]   on Windows — original kept, duplicate added
```

So a replace can silently leave the original value in place and add a second entry beside
it. Confirm with `config_get_all` when the key must end up single-valued.

## Project Policies

These documents set expectations for behavior, contribution workflows, AI-assisted
changes, decision making, maintainer roles, and licensing. Please review them before
opening issues or pull requests.

| Document | Description |
| -------- | ----------- |
| [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md) | We follow the Ruby community Code of Conduct; expect respectful, harassment-free participation and report concerns to maintainers. |
| [CONTRIBUTING](CONTRIBUTING.md) | How to report issues, submit PRs with Conventional Commits, meet coding/testing standards, and follow the Code of Conduct. |
| [AI_POLICY](AI_POLICY.md) | AI-assisted contributions are welcome. Contributors are expected to read and apply the AI Policy, and ensure any AI-assisted work meets our quality, security, and licensing standards. |
| [Ruby version support policy](#ruby-version-support-policy) | Supported Ruby runtimes and platforms; bump decisions and CI coverage expectations. |
| [Git version support policy](#git-version-support-policy) | Minimum supported git version and how version bumps are communicated and enforced. |
| [GOVERNANCE](GOVERNANCE.md) | Principles-first governance defining maintainer/project lead roles, least-privilege access, consensus/majority decisions, and nomination/emeritus steps. |
| [MAINTAINERS](MAINTAINERS.md) | Lists active maintainers (Project Lead noted) and emeritus alumni with links; see governance for role scope. |
| [LICENSE](LICENSE) | MIT License terms for using, modifying, and redistributing this project. |

### Ruby Version Support Policy

This gem is expected to function correctly on:

- All [non-EOL versions](https://www.ruby-lang.org/en/downloads/branches/) of the MRI
  Ruby on Mac, Linux, and Windows
- The latest version of JRuby 9.4+ on Linux
- The latest version of TruffleRuby 24+ on Linux

It is this project's intent to support the latest version of JRuby on Windows once
the [process_executer](https://github.com/main-branch/process_executer) gem properly
supports subprocess status reporting on JRuby for Windows (see
[main-branch/process_executer#156](https://github.com/main-branch/process_executer/issues/156)).

### Git Version Support Policy

This gem requires git version 2.28.0 or greater as specified in the gemspec. This
requirement reflects:

- The minimum git version necessary to support all features provided by this gem
- A reasonable balance between supporting older systems and leveraging modern git
  capabilities
- The practical limitations of testing across multiple git versions in CI

Git 2.28.0 was released on July 27, 2020. While this gem may work with earlier
versions of git, compatibility with versions prior to 2.28.0 is not tested or
guaranteed. Users on older git versions should upgrade to at least 2.28.0.

The supported git version may be increased in future major or minor releases of this
gem as new git features are adopted or as maintaining backward compatibility becomes
impractical. Such changes will be clearly documented in the CHANGELOG and release
notes.

## Project Announcements

### 2026-07-28: v5.0.0 Released

We have published [`git v5.0.0`](https://rubygems.org/gems/git/versions/5.0.0) —
the first stable release of the v5.x series, after five public beta releases
spanning June–July 2026.

**v5.0.0 is a major release with breaking changes.** See
[UPGRADING.md](UPGRADING.md) for the complete migration guide.

To install:

```ruby
gem 'git', '~> 5.0'
```

Or:

```sh
gem install git
```

Most v4.x code requires **no changes** — compatibility shims keep the old API
working while emitting deprecation warnings that tell you what to migrate before
v6.0.0.

### 2026-01-07: AI Policy Introduced

We have adopted a formal [AI Policy](AI_POLICY.md) to clarify expectations for
AI-assisted contributions. Please review it before opening a PR to ensure your
changes are fully understood, meet our quality bar, and respect licensing
requirements.

We chose a principles-based policy to respect contributors’ time and expertise. It’s
quick to read, easy to remember, and avoids unnecessary policy overhead while still
setting clear expectations.

### 2025-07-09: Architectural Redesign

On this date we announced a significant architectural redesign of the git gem. The
architecture at the time had several design challenges that made it difficult to
maintain and evolve; the redesign replaced it with a clearer, more testable
three-layer structure of commands, parsers, and a `Git::Repository` facade.

**The redesign shipped in v5.0.0 and is complete.** `Git::Base` and `Git::Lib` are
gone, along with the `g.lib` accessor. See [UPGRADING.md](UPGRADING.md) for what
changed and how to migrate.

The three documents written to plan it are kept as a historical record in
[`archive/v5-redesign/`](archive/v5-redesign/). They describe the state of the code
before and during the migration and are **not** current policy — the standards that
apply to new code live in [`.github/skills/`](.github/skills/).

1. [Analysis of the Current Architecture](archive/v5-redesign/1_architecture_existing.md):
   a breakdown of the v4.x design and its challenges.
2. [The Proposed Redesign](archive/v5-redesign/2_architecture_redesign.md): an overview
   of the three-layer architecture.
3. [Implementation Plan](archive/v5-redesign/3_architecture_implementation.md): the
   step-by-step plan that was followed.

### 2025-07-07: We Now Use RuboCop

To improve code consistency and maintainability, the `ruby-git` project has now
adopted [RuboCop](https://rubocop.org/) as our static code analyzer and formatter.

This integration is a key part of our ongoing commitment to making `ruby-git` a
high-quality, stable, and easy-to-contribute-to project. All new contributions will
be expected to adhere to the style guidelines enforced by our RuboCop configuration.

 RuboCop can be run from the project's Rakefile:

```shell
rake rubocop
```

RuboCop is also run  as part of the default rake task (by running `rake`) that is run
in our Continuous Integration workflow.

Going forward, any PRs that have any Robocop offenses will not be merged. In certain
rare cases, it might be acceptable to disable a  RuboCop check for the most limited
scope possible.

If you have a problem fixing a  RuboCop offense, don't be afraid to ask a
contributor.

### 2025-06-06: Default Branch Rename

On June 6th, 2025, the default branch was renamed from 'master' to 'main'.

Instructions for renaming your local or forked branch to match can be found in the
gist [Default Branch Name
Change](https://gist.github.com/jcouball/580a10e395f7fdfaaa4297bbe816cc7d).

### 2025-05-15: We've Switched to Conventional Commits

To enhance our development workflow, enable automated changelog generation, and pave
the way for Continuous Delivery, the `ruby-git` project has adopted the [Conventional
Commits standard](https://www.conventionalcommits.org/en/v1.0.0/) for all commit
messages.

Going forward, all commits to this repository **MUST** adhere to the Conventional
Commits standard. Commits not adhering to this standard will cause the CI build to
fail. PRs will not be merged if they include non-conventional commits.

A git pre-commit hook may be installed to validate your conventional commit messages
before pushing them to GitHub by running `bin/setup` in the project root.

Read more about this change in the [Commit Message Guidelines section of
CONTRIBUTING.md](CONTRIBUTING.md#commit-message-guidelines)
